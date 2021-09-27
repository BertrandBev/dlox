import 'dart:math';

import 'package:dlox/chunk.dart';
import 'package:dlox/compiler.dart';
import 'package:dlox/debug.dart';
import 'package:dlox/error.dart';
import 'package:dlox/native.dart';
import 'package:dlox/object.dart';
import 'package:dlox/table.dart';
import 'package:dlox/value.dart';
import 'package:sprintf/sprintf.dart';

import 'native_classes.dart';

const int UINT8_COUNT = 256;
const int FRAMES_MAX = 64;
const int STACK_MAX = (FRAMES_MAX * UINT8_COUNT);
const BATCH_COUNT = 1000000; // Must be fast enough

class CallFrame {
  ObjClosure closure;
  int ip;
  Chunk chunk; // Additionnal reference
  int slotsIdx; // Index in stack of the frame slot
}

class InterpreterResult {
  final List<LangError> errors;
  final int lastLine;
  final int stepCount;
  final Object returnValue;

  bool get done {
    return errors.isNotEmpty || returnValue != null;
  }

  InterpreterResult(
    List<LangError> errors,
    this.lastLine,
    this.stepCount,
    this.returnValue,
  ) : errors = List<LangError>.from(errors);
}

class FunctionParams {
  final String function;
  final List<Object> args;
  final Map<String, Object> globals;

  FunctionParams({this.function, this.args, this.globals});
}

class VM {
  static const INIT_STRING = 'init';
  final List<CallFrame> frames = List<CallFrame>.filled(FRAMES_MAX, null);
  final List<Object> stack = List<Object>.filled(STACK_MAX, null);
  // VM state
  final List<RuntimeError> errors = [];
  final Table globals = Table();
  final Table strings = Table();
  CompilerResult compilerResult;
  int frameCount = 0;
  int stackTop = 0;
  ObjUpvalue openUpvalues;
  // Debug variables
  int stepCount = 0;
  int line = -1;
  // int skipLine = -1;
  bool hasOp = false;
  // Debug API
  bool traceExecution = false;
  bool stepCode = false;
  Debug errDebug;
  Debug traceDebug;
  Debug stdout;

  VM({bool silent = false}) {
    errDebug = Debug(silent);
    traceDebug = Debug(silent);
    stdout = Debug(silent);
    _reset();
    for (var k = 0; k < frames.length; k++) {
      frames[k] = CallFrame();
    }
  }

  RuntimeError addError(String msg, {RuntimeError link, int line}) {
    // int line = -1;
    // if (frameCount > 0) {
    //   final frame = frames[frameCount - 1];
    //   final lines = frame.chunk.lines;
    //   if (frame.ip < lines.length) line = lines[frame.ip];
    // }
    final err = RuntimeError(line ?? this.line, msg, link: link);
    errors.add(err);
    err.dump(errDebug);
    return err;
  }

  InterpreterResult getResult(int line, {Object returnValue}) {
    return InterpreterResult(
      errors,
      line,
      stepCount,
      returnValue,
    );
  }

  InterpreterResult get result {
    return getResult(line);
  }

  InterpreterResult withError(String msg) {
    addError(msg);
    return result;
  }

  void _reset() {
    // Reset data
    errors.clear();
    globals.data.clear();
    strings.data.clear();
    stackTop = 0;
    frameCount = 0;
    openUpvalues = null;
    // Reset debug values
    stepCount = 0;
    line = -1;
    hasOp = false;
    stdout.clear();
    errDebug.clear();
    traceDebug.clear();
    // Reset flags
    stepCode = false;
    // Define natives
    defineNatives();
  }

  void setFunction(CompilerResult compilerResult, FunctionParams params) {
    _reset();
    // Set compiler result
    if (compilerResult == null) throw Exception('Null compiler result');
    if (compilerResult.errors.isNotEmpty) {
      throw Exception('Compiler result had errors');
    }
    this.compilerResult = compilerResult;
    // Set function
    var fun = compilerResult.function;
    if (params.function != null) {
      fun = compilerResult.function.chunk.constants.firstWhere((obj) {
        return obj is ObjFunction && obj.name == params.function;
      });
      if (fun == null) throw Exception('Function not found ${params.function}');
    }
    // Set globals
    if (params.globals != null) globals.data.addAll(params.globals);
    // Init VM
    final closure = ObjClosure(fun);
    push(closure);
    if (params.args != null) {
      for (var arg in params.args) {
        push(arg);
      }
    }
    callValue(closure, params.args?.length ?? 0);
  }

  void defineNatives() {
    for (var function in NATIVE_FUNCTIONS) {
      globals.setVal(function.name, function);
    }
    NATIVE_VALUES.forEach((key, value) {
      globals.setVal(key, value);
    });
    NATIVE_CLASSES.forEach((key, value) {
      globals.setVal(key, value);
    });
  }

  void push(Object value) {
    stack[stackTop++] = value;
  }

  Object pop() {
    return stack[--stackTop];
  }

  Object peek(int distance) {
    return stack[stackTop - distance - 1];
  }

  bool call(ObjClosure closure, int argCount) {
    if (argCount != closure.function.arity) {
      runtimeError('Expected %d arguments but got %d',
          [closure.function.arity, argCount]);
      return false;
    }

    if (frameCount == FRAMES_MAX) {
      runtimeError('Stack overflow');
      return false;
    }

    final frame = frames[frameCount++];
    frame.closure = closure;
    frame.chunk = closure.function.chunk;
    frame.ip = 0;

    frame.slotsIdx = stackTop - argCount - 1;
    return true;
  }

  bool callValue(Object callee, int argCount) {
    if (callee is ObjBoundMethod) {
      stack[stackTop - argCount - 1] = callee.receiver;
      return call(callee.method, argCount);
    } else if (callee is ObjClass) {
      stack[stackTop - argCount - 1] = ObjInstance(klass: callee);
      final initializer = callee.methods.getVal(INIT_STRING);
      if (initializer != null) {
        return call(initializer as ObjClosure, argCount);
      } else if (argCount != 0) {
        runtimeError('Expected 0 arguments but got %d', [argCount]);
        return false;
      }
      return true;
    } else if (callee is ObjClosure) {
      return call(callee, argCount);
    } else if (callee is ObjNative) {
      final res = callee.fn(stack, stackTop - argCount, argCount);
      stackTop -= argCount + 1;
      push(res);
      return true;
    } else if (callee is NativeClassCreator) {
      try {
        final res = callee(stack, stackTop - argCount, argCount);
        stackTop -= argCount + 1;
        push(res);
      } on NativeError catch (e) {
        runtimeError(e.format, e.args);
        return false;
      }
      return true;
    } else {
      runtimeError('Can only call functions and classes');
      return false;
    }
  }

  bool invokeFromClass(ObjClass klass, String name, int argCount) {
    final method = klass.methods.getVal(name);
    if (method == null) {
      runtimeError("Undefined property '%s'", [name]);
      return false;
    }
    return call(method as ObjClosure, argCount);
  }

  bool invokeMap(Map map, String name, int argCount) {
    if (!MAP_NATIVE_FUNCTIONS.containsKey(name)) {
      runtimeError('Unknown method for map');
      return false;
    }
    final function = MAP_NATIVE_FUNCTIONS[name];
    try {
      final rtn = function(map, stack, stackTop - argCount, argCount);
      stackTop -= argCount + 1;
      push(rtn);
      return true;
    } on NativeError catch (e) {
      runtimeError(e.format, e.args);
      return false;
    }
  }

  bool invokeList(List list, String name, int argCount) {
    if (!LIST_NATIVE_FUNCTIONS.containsKey(name)) {
      runtimeError('Unknown method for list');
      return false;
    }
    final function = LIST_NATIVE_FUNCTIONS[name];
    try {
      final rtn = function(list, stack, stackTop - argCount, argCount);
      stackTop -= argCount + 1;
      push(rtn);
      return true;
    } on NativeError catch (e) {
      runtimeError(e.format, e.args);
      return false;
    }
  }

  bool invokeString(String str, String name, int argCount) {
    if (!STRING_NATIVE_FUNCTIONS.containsKey(name)) {
      runtimeError('Unknown method for string');
      return false;
    }
    final function = STRING_NATIVE_FUNCTIONS[name];
    try {
      final rtn = function(str, stack, stackTop - argCount, argCount);
      stackTop -= argCount + 1;
      push(rtn);
      return true;
    } on NativeError catch (e) {
      runtimeError(e.format, e.args);
      return false;
    }
  }

  bool invokeNativeClass(ObjNativeClass klass, String name, int argCount) {
    try {
      final rtn = klass.call(name, stack, stackTop - argCount, argCount);
      stackTop -= argCount + 1;
      push(rtn);
      return true;
    } on NativeError catch (e) {
      runtimeError(e.format, e.args);
      return false;
    }
  }

  bool invoke(String name, int argCount) {
    final receiver = peek(argCount);
    if (receiver is List) return invokeList(receiver, name, argCount);
    if (receiver is Map) return invokeMap(receiver, name, argCount);
    if (receiver is String) return invokeString(receiver, name, argCount);
    if (receiver is ObjNativeClass) {
      return invokeNativeClass(receiver, name, argCount);
    }
    if (receiver is! ObjInstance) {
      runtimeError('Only instances have methods');
      return false;
    }
    final instance = receiver as ObjInstance;
    final value = instance.fields.getVal(name);
    if (value != null) {
      stack[stackTop - argCount - 1] = value;
      return callValue(value, argCount);
    }
    if (instance.klass == null) {
      final klass = globals.getVal(instance.klassName);
      if (klass is! ObjClass) {
        runtimeError('Class ${instance.klassName} not found');
        return false;
      }
      instance.klass = klass as ObjClass;
    }
    return invokeFromClass(instance.klass, name, argCount);
  }

  bool bindMethod(ObjClass klass, String name) {
    final method = klass.methods.getVal(name);
    if (method == null) {
      runtimeError("Undefined property '%s'", [name]);
      return false;
    }
    final bound = ObjBoundMethod(peek(0), method as ObjClosure);
    pop();
    push(bound);
    return true;
  }

  ObjUpvalue captureUpvalue(int localIdx) {
    ObjUpvalue prevUpvalue;
    var upvalue = openUpvalues;

    while (upvalue != null && upvalue.location > localIdx) {
      prevUpvalue = upvalue;
      upvalue = upvalue.next;
    }

    if (upvalue != null && upvalue.location == localIdx) {
      return upvalue;
    }

    final createdUpvalue = ObjUpvalue(localIdx);
    createdUpvalue.next = upvalue;

    if (prevUpvalue == null) {
      openUpvalues = createdUpvalue;
    } else {
      prevUpvalue.next = createdUpvalue;
    }

    return createdUpvalue;
  }

  void closeUpvalues(int lastIdx) {
    while (openUpvalues != null && openUpvalues.location >= lastIdx) {
      var upvalue = openUpvalues;
      upvalue.closed = stack[upvalue.location];
      upvalue.location = null;
      openUpvalues = upvalue.next;
    }
  }

  void defineMethod(String name) {
    var method = peek(0);
    ObjClass klass = peek(1);
    klass.methods.setVal(name, method);
    pop();
  }

  bool isFalsey(Object value) {
    return value == Nil || (value is bool && !value);
  }

  // Repace macros (slower -> try inlining)
  int readByte(CallFrame frame) {
    return frame.chunk.code[frame.ip++];
  }

  int readShort(CallFrame frame) {
    // TODO: Optimisation - remove
    frame.ip += 2;
    return frame.chunk.code[frame.ip - 2] << 8 | frame.chunk.code[frame.ip - 1];
  }

  Object readConstant(CallFrame frame) {
    return frame.closure.function.chunk.constants[readByte(frame)];
  }

  String readString(CallFrame frame) {
    return readConstant(frame) as String;
  }

  bool assertNumber(a, b) {
    if (a is! double || b is! double) {
      runtimeError('Operands must be numbers');
      return false;
    }
    return true;
  }

  int checkIndex(int length, Object idxObj, {bool fromStart = true}) {
    if (idxObj == Nil) idxObj = fromStart ? 0.0 : length.toDouble();
    if (idxObj is! double) {
      runtimeError('Index must be a number');
      return null;
    }
    var idx = (idxObj as double).toInt();
    if (idx < 0) idx = length + idx;
    final max = fromStart ? length - 1 : length;
    if (idx < 0 || idx > max) {
      runtimeError('Index $idx out of bounds [0, $max]');
      return null;
    }
    return idx;
  }

  bool get done {
    return frameCount == 0;
  }

  InterpreterResult run() {
    InterpreterResult res;
    do {
      res = stepBatch();
    } while (res == null);
    return res;
  }

  InterpreterResult stepBatch({int batchCount = BATCH_COUNT}) {
    // Setup
    if (frameCount == 0) return withError('No call frame');
    var frame = frames[frameCount - 1];
    var stepCountLimit = stepCount + batchCount;
    // Main loop
    while (stepCount++ < stepCountLimit) {
      // Setup current line
      final frameLine = frame.chunk.lines[frame.ip];
      // Step code helper
      if (stepCode) {
        final instruction = frame.chunk.code[frame.ip];
        final op = OpCode.values[instruction];
        // Pause execution on demand
        if (frameLine != line && hasOp) {
          // Newline detected, return
          // No need to set line to frameLine thanks to hasOp
          hasOp = false;
          return getResult(line);
        }
        // A line is worth stopping on if it has one of those opts
        hasOp |= (op != OpCode.POP && op != OpCode.LOOP && op != OpCode.JUMP);
      }

      // Update line
      final prevLine = line;
      line = frameLine;

      // Trace execution if needed
      if (traceExecution) {
        traceDebug.stdwrite('          ');
        for (var k = 0; k < stackTop; k++) {
          traceDebug.stdwrite('[ ');
          traceDebug.printValue(stack[k]);
          traceDebug.stdwrite(' ]');
        }
        traceDebug.stdwrite('\n');
        traceDebug.disassembleInstruction(
            prevLine, frame.closure.function.chunk, frame.ip);
      }

      final instruction = readByte(frame);
      switch (OpCode.values[instruction]) {
        case OpCode.CONSTANT:
          {
            final constant = readConstant(frame);
            push(constant);
            break;
          }

        case OpCode.NIL:
          push(Nil);
          break;

        case OpCode.TRUE:
          push(true);
          break;

        case OpCode.FALSE:
          push(false);
          break;

        case OpCode.POP:
          pop();
          break;

        case OpCode.GET_LOCAL:
          {
            final slot = readByte(frame);
            push(stack[frame.slotsIdx + slot]);
            break;
          }

        case OpCode.SET_LOCAL:
          {
            final slot = readByte(frame);
            stack[frame.slotsIdx + slot] = peek(0);
            break;
          }

        case OpCode.GET_GLOBAL:
          {
            final name = readString(frame);
            final value = globals.getVal(name);
            if (value == null) {
              return runtimeError("Undefined variable '%s'", [name]);
            }
            push(value);
            break;
          }

        case OpCode.DEFINE_GLOBAL:
          {
            final name = readString(frame);
            globals.setVal(name, peek(0));
            pop();
            break;
          }

        case OpCode.SET_GLOBAL:
          {
            final name = readString(frame);
            if (globals.setVal(name, peek(0))) {
              globals.delete(name); // [delete]
              return runtimeError("Undefined variable '%s'", [name]);
            }
            break;
          }

        case OpCode.GET_UPVALUE:
          {
            final slot = readByte(frame);
            final upvalue = frame.closure.upvalues[slot];
            push(upvalue.location != null
                ? stack[upvalue.location]
                : upvalue.closed);
            break;
          }

        case OpCode.SET_UPVALUE:
          {
            final slot = readByte(frame);
            final upvalue = frame.closure.upvalues[slot];
            if (upvalue.location != null) {
              stack[upvalue.location] = peek(0);
            } else {
              upvalue.closed = peek(0);
            }
            break;
          }

        case OpCode.GET_PROPERTY:
          {
            Object value;
            if (peek(0) is ObjInstance) {
              ObjInstance instance = peek(0);
              final name = readString(frame);
              value = instance.fields.getVal(name);
              if (value == null && !bindMethod(instance.klass, name)) {
                return result;
              }
            } else if (peek(0) is ObjNativeClass) {
              ObjNativeClass instance = peek(0);
              final name = readString(frame);
              try {
                value = instance.getVal(name);
              } on NativeError catch (e) {
                return runtimeError(e.format, e.args);
              }
            } else {
              return runtimeError('Only instances have properties');
            }
            if (value != null) {
              pop(); // Instance.
              push(value);
            }
            break;
          }

        case OpCode.SET_PROPERTY:
          {
            if (peek(1) is ObjInstance) {
              ObjInstance instance = peek(1);
              instance.fields.setVal(readString(frame), peek(0));
            } else if (peek(1) is ObjNativeClass) {
              ObjNativeClass instance = peek(1);
              instance.setVal(readString(frame), peek(0));
            } else {
              return runtimeError('Only instances have fields');
            }
            final value = pop();
            pop();
            push(value);
            break;
          }

        case OpCode.GET_SUPER:
          {
            final name = readString(frame);
            ObjClass superclass = pop();
            if (!bindMethod(superclass, name)) {
              return result;
            }
            break;
          }

        case OpCode.EQUAL:
          {
            final b = pop();
            final a = pop();
            push(valuesEqual(a, b));
            break;
          }

        // Optimisation create greater_or_equal
        case OpCode.GREATER:
          {
            final b = pop();
            final a = pop();
            if (a is String && b is String) {
              push(a.compareTo(b));
            } else if (a is double && b is double) {
              push(a > b);
            } else {
              return runtimeError('Operands must be numbers or strings');
            }
            break;
          }

        // Optimisation create less_or_equal
        case OpCode.LESS:
          {
            final b = pop();
            final a = pop();
            if (a is String && b is String) {
              push(b.compareTo(a));
            } else if (a is double && b is double) {
              push(a < b);
            } else {
              return runtimeError('Operands must be numbers or strings');
            }
            break;
          }

        case OpCode.ADD:
          {
            final b = pop();
            final a = pop();
            if ((a is double) && (b is double)) {
              push(a + b);
            } else if ((a is String) && (b is String)) {
              push(a + b);
            } else if ((a is List) && (b is List)) {
              push(a + b);
            } else if ((a is Map) && (b is Map)) {
              Map res;
              res.addAll(a);
              res.addAll(b);
              push(res);
            } else if ((a is String) || (b is String)) {
              push(valueToString(a, quoteEmpty: false) +
                  valueToString(b, quoteEmpty: false));
            } else {
              return runtimeError(
                  'Operands must numbers, strings, lists or maps');
            }
            break;
          }

        case OpCode.SUBTRACT:
          {
            final b = pop();
            final a = pop();
            if (!assertNumber(a, b)) return result;
            push((a as double) - (b as double));
            break;
          }

        case OpCode.MULTIPLY:
          {
            final b = pop();
            final a = pop();
            if (!assertNumber(a, b)) return result;
            push((a as double) * (b as double));
            break;
          }

        case OpCode.DIVIDE:
          {
            final b = pop();
            final a = pop();
            if (!assertNumber(a, b)) return result;
            push((a as double) / (b as double));
            break;
          }

        case OpCode.POW:
          {
            final b = pop();
            final a = pop();
            if (!assertNumber(a, b)) return result;
            push(pow(a as double, b as double));
            break;
          }

        case OpCode.MOD:
          {
            final b = pop();
            final a = pop();
            if (!assertNumber(a, b)) return result;
            push((a as double) % (b as double));
            break;
          }

        case OpCode.NOT:
          push(isFalsey(pop()));
          break;

        case OpCode.NEGATE:
          if (peek(0) is! double) {
            return runtimeError('Operand must be a number');
          }
          push(-(pop() as double));
          break;

        case OpCode.PRINT:
          {
            final val = valueToString(pop());
            stdout.stdwriteln(val);
            break;
          }

        case OpCode.JUMP:
          {
            final offset = readShort(frame);
            frame.ip += offset;
            break;
          }

        case OpCode.JUMP_IF_FALSE:
          {
            final offset = readShort(frame);
            if (isFalsey(peek(0))) frame.ip += offset;
            break;
          }

        case OpCode.LOOP:
          {
            final offset = readShort(frame);
            frame.ip -= offset;
            break;
          }

        case OpCode.CALL:
          {
            final argCount = readByte(frame);
            if (!callValue(peek(argCount), argCount)) {
              return result;
            }
            frame = frames[frameCount - 1];
            break;
          }

        case OpCode.INVOKE:
          {
            final method = readString(frame);
            final argCount = readByte(frame);
            if (!invoke(method, argCount)) {
              return result;
            }
            frame = frames[frameCount - 1];
            break;
          }

        case OpCode.SUPER_INVOKE:
          {
            final method = readString(frame);
            final argCount = readByte(frame);
            ObjClass superclass = pop();
            if (!invokeFromClass(superclass, method, argCount)) {
              return result;
            }
            frame = frames[frameCount - 1];
            break;
          }

        case OpCode.CLOSURE:
          {
            ObjFunction function = readConstant(frame);
            final closure = ObjClosure(function);
            push(closure);
            for (var i = 0; i < closure.upvalueCount; i++) {
              final isLocal = readByte(frame);
              final index = readByte(frame);
              if (isLocal == 1) {
                closure.upvalues[i] = captureUpvalue(frame.slotsIdx + index);
              } else {
                closure.upvalues[i] = frame.closure.upvalues[index];
              }
            }
            break;
          }

        case OpCode.CLOSE_UPVALUE:
          closeUpvalues(stackTop - 1);
          pop();
          break;

        case OpCode.RETURN:
          {
            final res = pop();
            closeUpvalues(frame.slotsIdx);
            frameCount--;
            if (frameCount == 0) {
              pop();
              return getResult(line, returnValue: res);
            }
            stackTop = frame.slotsIdx;
            push(res);
            frame = frames[frameCount - 1];
            break;
          }

        case OpCode.CLASS:
          push(ObjClass(readString(frame)));
          break;

        case OpCode.INHERIT:
          {
            final sup = peek(1);
            if (sup is! ObjClass) {
              return runtimeError('Superclass must be a class');
            }
            ObjClass superclass = sup;
            ObjClass subclass = peek(0);
            subclass.methods.addAll(superclass.methods);
            pop(); // Subclass.
            break;
          }

        case OpCode.METHOD:
          defineMethod(readString(frame));
          break;

        case OpCode.LIST_INIT:
          final valCount = readByte(frame);
          final arr = [];
          for (var k = 0; k < valCount; k++) {
            arr.add(peek(valCount - k - 1));
          }
          stackTop -= valCount;
          push(arr);
          break;

        case OpCode.LIST_INIT_RANGE:
          if (peek(0) is! double || peek(1) is! double) {
            return runtimeError('List initializer bounds must be number');
          }
          final start = peek(1) as double;
          final end = peek(0) as double;
          if (end - start == double.infinity) {
            return runtimeError('Invalid list initializer');
          }
          final arr = [];
          for (var k = start; k < end; k++) {
            arr.add(k);
          }
          stackTop -= 2;
          push(arr);
          break;

        case OpCode.MAP_INIT:
          final valCount = readByte(frame);
          final map = {};
          for (var k = 0; k < valCount; k++) {
            map[peek((valCount - k - 1) * 2 + 1)] =
                peek((valCount - k - 1) * 2);
          }
          stackTop -= 2 * valCount;
          push(map);
          break;

        case OpCode.CONTAINER_GET:
          {
            final idxObj = pop();
            final container = pop();
            if (container is List) {
              final idx = checkIndex(container.length, idxObj);
              if (idx == null) return result;
              push(container[idx]);
            } else if (container is Map) {
              push(container[idxObj]);
            } else if (container is String) {
              final idx = checkIndex(container.length, idxObj);
              if (idx == null) return result;
              push(container[idx]);
            } else {
              return runtimeError(
                'Indexing targets must be Strings, Lists or Maps',
              );
            }
            break;
          }

        case OpCode.CONTAINER_SET:
          {
            final val = pop();
            final idxObj = pop();
            final container = pop();
            if (container is List) {
              final idx = checkIndex(container.length, idxObj);
              if (idx == null) return result;
              container[idx] = val;
            } else if (container is Map) {
              container[idxObj] = val;
            } else {
              return runtimeError('Indexing targets must be Lists or Maps');
            }
            push(val);
            break;
          }

        case OpCode.CONTAINER_GET_RANGE:
          {
            var bIdx = pop();
            var aIdx = pop();
            final container = pop();
            var length = 0;
            if (container is List) {
              length = container.length;
            } else if (container is String) {
              length = container.length;
            } else {
              return runtimeError(
                  'Range indexing targets must be Lists or Strings');
            }
            aIdx = checkIndex(length, aIdx);
            bIdx = checkIndex(length, bIdx, fromStart: false);
            if (aIdx == null || bIdx == null) return result;
            if (container is List) {
              push(container.sublist(aIdx, bIdx));
            } else if (container is String) {
              push(container.substring(aIdx, bIdx));
            }
            break;
          }

        case OpCode.CONTAINER_ITERATE:
          {
            // Init stack indexes
            var valIdx = readByte(frame);
            var keyIdx = valIdx + 1;
            final idxIdx = valIdx + 2;
            final iterableIdx = valIdx + 3;
            final containerIdx = valIdx + 4;
            // Retreive data
            var idxObj = stack[frame.slotsIdx + idxIdx];
            // Initialize
            if (idxObj == Nil) {
              final container = stack[frame.slotsIdx + containerIdx];
              idxObj = 0.0;
              if (container is String) {
                stack[frame.slotsIdx + iterableIdx] = container.split('');
              } else if (container is List) {
                stack[frame.slotsIdx + iterableIdx] = container;
              } else if (container is Map) {
                stack[frame.slotsIdx + iterableIdx] =
                    container.entries.toList();
              } else {
                return runtimeError('Iterable must be Strings, Lists or Maps');
              }
              // Pop container from stack
              pop();
            }
            // Iterate
            double idx = idxObj;
            final iterable = stack[frame.slotsIdx + iterableIdx] as List;
            if (idx >= iterable.length) {
              // Return early
              push(false);
              break;
            }
            // Populate key & value
            final item = iterable[idx.toInt()];
            if (item is MapEntry) {
              stack[frame.slotsIdx + keyIdx] = item.key;
              stack[frame.slotsIdx + valIdx] = item.value;
            } else {
              stack[frame.slotsIdx + keyIdx] = idx;
              stack[frame.slotsIdx + valIdx] = item;
            }
            // Increment index
            stack[frame.slotsIdx + idxIdx] = idx + 1;
            push(true);
            break;
          }
      }
    }
    return null;
  }

  InterpreterResult runtimeError(String format, [List<Object> args]) {
    var error = addError(sprintf(format, args ?? []));
    for (var i = frameCount - 2; i >= 0; i--) {
      final frame = frames[i];
      final function = frame.closure.function;
      // frame.ip is sitting on the next instruction
      final line = function.chunk.lines[frame.ip - 1];
      final fun = function.name == null ? '<script>' : '<${function.name}>';
      final msg = 'during $fun execution';
      error = addError(msg, line: line, link: error);
    }
    return result;
  }
}
