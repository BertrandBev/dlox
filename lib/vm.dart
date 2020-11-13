import 'dart:ffi';
import 'dart:io';

import 'package:dlox/chunk.dart';
import 'package:dlox/common.dart';
import 'package:dlox/compiler.dart';
import 'package:dlox/debug.dart';
import 'package:dlox/object.dart';
import 'package:dlox/table.dart';
import 'package:dlox/value.dart';
import 'package:sprintf/sprintf.dart';

const int UINT8_COUNT = 256;
const int FRAMES_MAX = 64;
const int STACK_MAX = (FRAMES_MAX * UINT8_COUNT);

class CallFrame {
  ObjClosure closure;
  int ip;
  Chunk chunk; // Additionnal reference
  int slotsIdx; // Index in stack of the frame slot
}

enum InterpretResult { OK, COMPILE_ERROR, RUNTIME_ERROR }

double clockNative(List<Object> stack, int argIdx, int argCount) {
  return DateTime.now().millisecondsSinceEpoch.toDouble();
}

class VM {
  List<CallFrame> frames = List<CallFrame>(FRAMES_MAX);
  int frameCount;
  List<Object> stack = List<Object>(STACK_MAX);
  int stackTop = 0;
  Table globals = Table();
  Table strings = Table();
  String initString;
  ObjUpvalue openUpvalues;
  Object objects;

  VM() {
    resetStack();
    objects = null;
    initString = 'init';
    defineNative('clock', clockNative);
    for (var k = 0; k < frames.length; k++) {
      frames[k] = CallFrame();
    }
  }

  void resetStack() {
    stackTop = 0;
    frameCount = 0;
    openUpvalues = null;
  }

  void defineNative(String name, NativeFunction function) {
    globals.setVal(name, ObjNative(name, function));
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
      runtimeError('Expected %d arguments but got %d.',
          [closure.function.arity, argCount]);
      return false;
    }

    if (frameCount == FRAMES_MAX) {
      runtimeError('Stack overflow.');
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
      stack[stackTop - argCount - 1] = ObjInstance(callee);
      final initializer = callee.methods.getVal(initString);
      if (initializer != null) {
        return call(initializer as ObjClosure, argCount);
      } else if (argCount != 0) {
        runtimeError('Expected 0 arguments but got %d.', [argCount]);
        return false;
      }
      return true;
    } else if (callee is ObjClosure) {
      return call(callee, argCount);
    } else if (callee is ObjNative) {
      final result = callee.fn(stack, stackTop - argCount, argCount);
      stackTop -= argCount + 1;
      push(result);
      return true;
    } else {
      runtimeError('Can only call functions and classes.');
      return false;
    }
  }

  bool invokeFromClass(ObjClass klass, String name, int argCount) {
    final method = klass.methods.getVal(name);
    if (method == null) {
      runtimeError("Undefined property '%s'.", [name]);
      return false;
    }
    return call(method as ObjClosure, argCount);
  }

  bool invoke(String name, int argCount) {
    final receiver = peek(argCount);
    if (!(receiver is ObjInstance)) {
      runtimeError('Only instances have methods.');
      return false;
    }
    final instance = receiver as ObjInstance;
    final value = instance.fields.getVal(name);
    if (value != null) {
      stack[stackTop - argCount - 1] = value;
      return callValue(value, argCount);
    }
    return invokeFromClass(instance.klass, name, argCount);
  }

  bool bindMethod(ObjClass klass, String name) {
    final method = klass.methods.getVal(name);
    if (method == null) {
      runtimeError("Undefined property '%s'.", [name]);
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
    if (!(a is double) || !(b is double)) {
      runtimeError('Operands must be numbers.');
      return false;
    }
    return true;
  }

  int checkIndex(List arr, Object idxObj) {
    if (!(idxObj is double)) {
      runtimeError('Array index must be a number.');
      return null;
    }
    final idx = (idxObj as double).toInt();
    if (idx < 0 || idx >= arr.length) {
      runtimeError('Array index out of bounds.');
      return null;
    }
    return idx;
  }

  InterpretResult run() {
    var frame = frames[frameCount - 1];
    for (;;) {
      if (DEBUG_TRACE_EXECUTION) {
        stdout.write('          ');
        for (var k = 0; k < stackTop; k++) {
          stdout.write('[ ');
          printValue(stack[k]);
          stdout.write(' ]');
        }
        stdout.write('\n');
        disassembleInstruction(frame.closure.function.chunk, frame.ip);
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
              runtimeError("Undefined variable '%s'.", [name]);
              return InterpretResult.RUNTIME_ERROR;
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
              runtimeError("Undefined variable '%s'.", [name]);
              return InterpretResult.RUNTIME_ERROR;
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
            if (!(peek(0) is ObjInstance)) {
              runtimeError('Only instances have properties.');
              return InterpretResult.RUNTIME_ERROR;
            }

            ObjInstance instance = peek(0);
            final name = readString(frame);
            final value = instance.fields.getVal(name);
            if (value != null) {
              pop(); // Instance.
              push(value);
              break;
            }

            if (!bindMethod(instance.klass, name)) {
              return InterpretResult.RUNTIME_ERROR;
            }
            break;
          }

        case OpCode.SET_PROPERTY:
          {
            if (!(peek(1) is ObjInstance)) {
              runtimeError('Only instances have fields.');
              return InterpretResult.RUNTIME_ERROR;
            }
            ObjInstance instance = peek(1);
            instance.fields.setVal(readString(frame), peek(0));
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
              return InterpretResult.RUNTIME_ERROR;
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

        case OpCode.GREATER:
          {
            final b = pop();
            final a = pop();
            if (!assertNumber(a, b)) return InterpretResult.RUNTIME_ERROR;
            push((a as double) > (b as double));
            break;
          }

        case OpCode.LESS:
          {
            final b = pop();
            final a = pop();
            if (!assertNumber(a, b)) return InterpretResult.RUNTIME_ERROR;
            push((a as double) < (b as double));
            break;
          }

        case OpCode.ADD:
          {
            final b = pop();
            final a = pop();
            if ((a is double) && (b is double)) {
              // String concatenation
              push(a + b);
            } else if ((a is String) && (b is String)) {
              push(a + b);
            } else if ((a is List) && (b is List)) {
              push(a + b);
            } else {
              runtimeError('Operands must numbers, strings or arrays.');
              return InterpretResult.RUNTIME_ERROR;
            }
            break;
          }

        case OpCode.SUBTRACT:
          {
            final b = pop();
            final a = pop();
            if (!assertNumber(a, b)) return InterpretResult.RUNTIME_ERROR;
            push((a as double) - (b as double));
            break;
          }

        case OpCode.MULTIPLY:
          {
            final b = pop();
            final a = pop();
            if (!assertNumber(a, b)) return InterpretResult.RUNTIME_ERROR;
            push((a as double) * (b as double));
            break;
          }

        case OpCode.DIVIDE:
          {
            final b = pop();
            final a = pop();
            if (!assertNumber(a, b)) return InterpretResult.RUNTIME_ERROR;
            push((a as double) / (b as double));
            break;
          }

        case OpCode.NOT:
          push(isFalsey(pop()));
          break;

        case OpCode.NEGATE:
          if (!(peek(0) is double)) {
            runtimeError('Operand must be a number.');
            return InterpretResult.RUNTIME_ERROR;
          }
          push(-(pop() as double));
          break;

        case OpCode.PRINT:
          {
            printValue(pop());
            stdout.writeln();
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
              return InterpretResult.RUNTIME_ERROR;
            }
            frame = frames[frameCount - 1];
            break;
          }

        case OpCode.INVOKE:
          {
            final method = readString(frame);
            final argCount = readByte(frame);
            if (!invoke(method, argCount)) {
              return InterpretResult.RUNTIME_ERROR;
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
              return InterpretResult.RUNTIME_ERROR;
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
            final result = pop();
            closeUpvalues(frame.slotsIdx);
            frameCount--;
            if (frameCount == 0) {
              pop();
              return InterpretResult.OK;
            }
            stackTop = frame.slotsIdx;
            push(result);
            frame = frames[frameCount - 1];
            break;
          }

        case OpCode.CLASS:
          push(ObjClass(readString(frame)));
          break;

        case OpCode.INHERIT:
          {
            final sup = peek(1);
            if (!(sup is ObjClass)) {
              runtimeError('Superclass must be a class.');
              return InterpretResult.RUNTIME_ERROR;
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

        case OpCode.ARRAY_INIT:
          final valCount = readByte(frame);
          final arr = [];
          for (var k = 0; k < valCount; k++) {
            arr.add(peek(valCount - k - 1));
          }
          stackTop -= valCount;
          push(arr);
          break;

        case OpCode.ARRAY_GET:
          {
            final idxObj = pop();
            final arr = pop() as List;
            final idx = checkIndex(arr, idxObj);
            push(arr[idx]);
            break;
          }

        case OpCode.ARRAY_SET:
          {
            final val = pop();
            final idxObj = pop();
            final arr = pop() as List;
            final idx = checkIndex(arr, idxObj);
            arr[idx] = val;
            push(val);
            break;
          }
      }
    }
  }

  InterpretResult interpret(String source) {
    final function = Compiler.compile(source);
    if (function == null) return InterpretResult.COMPILE_ERROR;
    push(function);
    final closure = ObjClosure(function);
    pop();
    push(closure);
    callValue(closure, 0);
    return run();
  }

  void runtimeError(String format, [List<Object> args]) {
    stderr.writeln(sprintf(format, args ?? []));

    for (var i = frameCount - 1; i >= 0; i--) {
      final frame = frames[i];
      final function = frame.closure.function;
      // -1 because the IP is sitting on the next instruction to be
      // executed.
      // int instruction = frame.ip - function.chunk.code - 1;
      final instruction = frame.ip - 1;
      stderr.write('[line ${function.chunk.lines[instruction]}] in ');
      if (function.name == null) {
        stderr.writeln('script');
      } else {
        stderr.writeln(
          '${function.name}()',
        );
      }
    }
    resetStack();
  }

  // void hack(bool b) {
  //   // Hack to avoid unused function error. run() is not used in the
  //   // scanning chapter.
  //   run();
  //   if (b) hack(false);
  // }
}
