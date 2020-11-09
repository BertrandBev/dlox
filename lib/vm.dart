import 'dart:ffi';
import 'dart:io';

import 'package:dlox/object.dart';
import 'package:dlox/table.dart';
import 'package:sprintf/sprintf.dart';

const int UINT8_COUNT = 256;
const int FRAMES_MAX = 64;
const int STACK_MAX = (FRAMES_MAX * UINT8_COUNT);

class  CallFrame {
  ObjClosure closure;
  int ip;
  Object slots;
}


enum InterpretResult {
  INTERPRET_OK,
  INTERPRET_COMPILE_ERROR,
  INTERPRET_RUNTIME_ERROR
}

Object clockNative(int argCount, Object args) {
  // return (double)clock() / CLOCKS_PER_SEC;
  return null;
}


class VM {
  List<CallFrame> frames = List<CallFrame>(FRAMES_MAX); // Static list for faster allocation
  int frameCount;
  List<Object> stack = List<Object>(STACK_MAX);
  int stackTop = 0;
  // Object stackTop;
  Table globals = Table();
  Table strings = Table();
  ObjString initString;
  ObjUpvalue openUpvalues;

  // TODO: remove?
  int bytesAllocated;
  int nextGC;

  Object objects;


  void resetStack() {
    stackTop = 0;
    frameCount = 0;
    openUpvalues = null;
  }


  void defineNative(String name, NativeFunction function) {
    globals.setVal(name, function);
  }

  void initVM() {
    resetStack();
    objects = null;
    bytesAllocated = 0;
    nextGC = 1024 * 1024;
    initString = 'init';
    defineNative('clock', clockNative);
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

    CallFrame frame = &frames[frameCount++];
    frame.closure = closure;
    frame.ip = closure.function.chunk.code;

    frame.slots = stackTop - argCount - 1;
    return true;
  }
  bool callObject(Object callee, int argCount) {
    if (IS_OBJ(callee)) {
      switch (OBJ_TYPE(callee)) {
        case OBJ_BOUND_METHOD: {
          ObjBoundMethod bound = AS_BOUND_METHOD(callee);
          stackTop[-argCount - 1] = bound.receiver;
          return call(bound.method, argCount);
        }

        case OBJ_CLASS: {
          ObjClass klass = AS_CLASS(callee);
          stackTop[-argCount - 1] = OBJ_VAL(newInstance(klass));
          Object initializer;
          if (tableGet(&klass.methods, initString,
                      &initializer)) {
            return call(AS_CLOSURE(initializer), argCount);
          } else if (argCount != 0) {
            runtimeError('Expected 0 arguments but got %d.', [argCount]);
            return false;
          }

          return true;
        }
        case OBJ_CLOSURE:
          return call(AS_CLOSURE(callee), argCount);
          
        case OBJ_NATIVE: {
          NativeFn native = AS_NATIVE(callee);
          Object result = native(argCount, stackTop - argCount);
          stackTop -= argCount + 1;
          push(result);
          return true;
        }

        default:
          // Non-callable object type.
          break;
      }
    }

    runtimeError('Can only call functions and classes.');
    return false;
  }
  bool invokeFromClass(ObjClass klass, ObjString name,
                              int argCount) {
    Object method;
    if (!tableGet(&klass.methods, name, &method)) {
      runtimeError("Undefined property '%s'.", name.chars);
      return false;
    }

    return call(AS_CLOSURE(method), argCount);
  }
  bool invoke(ObjString name, int argCount) {
    Object receiver = peek(argCount);

    if (!IS_INSTANCE(receiver)) {
      runtimeError('Only instances have methods.');
      return false;
    }

    ObjInstance instance = AS_INSTANCE(receiver);

    Object value;
    if (tableGet(&instance.fields, name, &value)) {
      stackTop[-argCount - 1] = value;
      return callObject(value, argCount);
    }

    return invokeFromClass(instance.klass, name, argCount);
  }
  bool bindMethod(ObjClass klass, ObjString name) {
    Object method;
    if (!tableGet(&klass.methods, name, &method)) {
      runtimeError("Undefined property '%s'.", name.chars);
      return false;
    }

    ObjBoundMethod bound = newBoundMethod(peek(0),
                                          AS_CLOSURE(method));
    pop();
    push(OBJ_VAL(bound));
    return true;
  }
  ObjUpvalue captureUpvalue(Object local) {
    ObjUpvalue prevUpvalue = null;
    ObjUpvalue upvalue = openUpvalues;

    while (upvalue != null && upvalue.location > local) {
      prevUpvalue = upvalue;
      upvalue = upvalue.next;
    }

    if (upvalue != null && upvalue.location == local) {
      return upvalue;
    }

    ObjUpvalue createdUpvalue = newUpvalue(local);
    createdUpvalue.next = upvalue;

    if (prevUpvalue == null) {
      openUpvalues = createdUpvalue;
    } else {
      prevUpvalue.next = createdUpvalue;
    }

    return createdUpvalue;
  }
  void closeUpvalues(Object last) {
    while (openUpvalues != null &&
          openUpvalues.location >= last) {
      ObjUpvalue upvalue = openUpvalues;
      upvalue.closed = *upvalue.location;
      upvalue.location = &upvalue.closed;
      openUpvalues = upvalue.next;
    }
  }
  void defineMethod(ObjString name) {
    Object method = peek(0);
    ObjClass klass = AS_CLASS(peek(1));
    tableSet(&klass.methods, name, method);
    pop();
  }
  bool isFalsey(Object value) {
    return IS_NIL(value) || (IS_BOOL(value) && !AS_BOOL(value));
  }
  void concatenate() {
    ObjString b = AS_STRING(peek(0));
    ObjString a = AS_STRING(peek(1));

    int length = a.length + b.length;
    char chars = ALLOCATE(char, length + 1);
    memcpy(chars, a.chars, a.length);
    memcpy(chars + a.length, b.chars, b.length);
    chars[length] = '\0';

    ObjString result = takeString(chars, length);
    pop();
    pop();
    push(OBJ_VAL(result));
  }
  InterpretResult run() {
    CallFrame frame = &frames[frameCount - 1];

  #define READ_BYTE() (*frame.ip++)
  #define READ_SHORT() \
      (frame.ip += 2, \
      (uint16_t)((frame.ip[-2] << 8) | frame.ip[-1]))
  #define READ_CONSTANT() \
      (frame.closure.function.chunk.constants.values[READ_BYTE()])
  #define READ_STRING() AS_STRING(READ_CONSTANT())

  #define BINARY_OP(valueType, op) \
      do { \
        if (!IS_NUMBER(peek(0)) || !IS_NUMBER(peek(1))) { \
          runtimeError('Operands must be numbers.'); \
          return INTERPRET_RUNTIME_ERROR; \
        } \
        double b = AS_NUMBER(pop()); \
        double a = AS_NUMBER(pop()); \
        push(valueType(a op b)); \
      } while (false)

    for (;;) {
  #ifdef DEBUG_TRACE_EXECUTION
      printf('          ');
      for (Object slot = stack; slot < stackTop; slot++) {
        printf('[ ');
        printObject(*slot);
        printf(' ]');
      }
      printf('\n');
      disassembleInstruction(&frame.closure.function.chunk,
          (int)(frame.ip - frame.closure.function.chunk.code));
  #endif

      uint8_t instruction;
      switch (instruction = READ_BYTE()) {
        case OP_CONSTANT: {
          Object constant = READ_CONSTANT();
          push(constant);
          break;
        }
        case OP_NIL: push(NIL_VAL); break;
        case OP_TRUE: push(BOOL_VAL(true)); break;
        case OP_FALSE: push(BOOL_VAL(false)); break;
        case OP_POP: pop(); break;

        case OP_GET_LOCAL: {
          uint8_t slot = READ_BYTE();
          push(frame.slots[slot]);
          break;
        }

        case OP_SET_LOCAL: {
          uint8_t slot = READ_BYTE();
          frame.slots[slot] = peek(0);
          break;
        }

        case OP_GET_GLOBAL: {
          ObjString name = READ_STRING();
          Object value;
          if (!tableGet(&globals, name, &value)) {
            runtimeError("Undefined variable '%s'.", name.chars);
            return INTERPRET_RUNTIME_ERROR;
          }
          push(value);
          break;
        }

        case OP_DEFINE_GLOBAL: {
          ObjString name = READ_STRING();
          tableSet(&globals, name, peek(0));
          pop();
          break;
        }

        case OP_SET_GLOBAL: {
          ObjString name = READ_STRING();
          if (tableSet(&globals, name, peek(0))) {
            tableDelete(&globals, name); // [delete]
            runtimeError("Undefined variable '%s'.", name.chars);
            return INTERPRET_RUNTIME_ERROR;
          }
          break;
        }

        case OP_GET_UPVALUE: {
          uint8_t slot = READ_BYTE();
          push(*frame.closure.upvalues[slot].location);
          break;
        }

        case OP_SET_UPVALUE: {
          uint8_t slot = READ_BYTE();
          *frame.closure.upvalues[slot].location = peek(0);
          break;
        }

        case OP_GET_PROPERTY: {
          if (!IS_INSTANCE(peek(0))) {
            runtimeError('Only instances have properties.');
            return INTERPRET_RUNTIME_ERROR;
          }

          ObjInstance instance = AS_INSTANCE(peek(0));
          ObjString name = READ_STRING();
          
          Object value;
          if (tableGet(&instance.fields, name, &value)) {
            pop(); // Instance.
            push(value);
            break;
          }

          if (!bindMethod(instance.klass, name)) {
            return INTERPRET_RUNTIME_ERROR;
          }
          break;
        }

        case OP_SET_PROPERTY: {
          if (!IS_INSTANCE(peek(1))) {
            runtimeError('Only instances have fields.');
            return INTERPRET_RUNTIME_ERROR;
          }

          ObjInstance instance = AS_INSTANCE(peek(1));
          tableSet(&instance.fields, READ_STRING(), peek(0));
          
          Object value = pop();
          pop();
          push(value);
          break;
        }

        case OP_GET_SUPER: {
          ObjString name = READ_STRING();
          ObjClass superclass = AS_CLASS(pop());
          if (!bindMethod(superclass, name)) {
            return INTERPRET_RUNTIME_ERROR;
          }
          break;
        }

        case OP_EQUAL: {
          Object b = pop();
          Object a = pop();
          push(BOOL_VAL(valuesEqual(a, b)));
          break;
        }

        case OP_GREATER:  BINARY_OP(BOOL_VAL, >); break;
        case OP_LESS:     BINARY_OP(BOOL_VAL, <); break;
        case OP_ADD: {
          if (IS_STRING(peek(0)) && IS_STRING(peek(1))) {
            concatenate();
          } else if (IS_NUMBER(peek(0)) && IS_NUMBER(peek(1))) {
            double b = AS_NUMBER(pop());
            double a = AS_NUMBER(pop());
            push(NUMBER_VAL(a + b));
          } else {
            runtimeError(
                'Operands must be two numbers or two strings.');
            return INTERPRET_RUNTIME_ERROR;
          }
          break;
        }
        case OP_SUBTRACT: BINARY_OP(NUMBER_VAL, -); break;
        case OP_MULTIPLY: BINARY_OP(NUMBER_VAL, *); break;
        case OP_DIVIDE:   BINARY_OP(NUMBER_VAL, /); break;
        case OP_NOT:
          push(BOOL_VAL(isFalsey(pop())));
          break;
        case OP_NEGATE:
          if (!IS_NUMBER(peek(0))) {
            runtimeError('Operand must be a number.');
            return INTERPRET_RUNTIME_ERROR;
          }

          push(NUMBER_VAL(-AS_NUMBER(pop())));
          break;

        case OP_PRINT: {
          printObject(pop());
          printf('\n');
          break;
        }

        case OP_JUMP: {
          uint16_t offset = READ_SHORT();
          frame.ip += offset;
          break;
        }

        case OP_JUMP_IF_FALSE: {
          uint16_t offset = READ_SHORT();
          if (isFalsey(peek(0))) frame.ip += offset;
          break;
        }

        case OP_LOOP: {
          uint16_t offset = READ_SHORT();
          frame.ip -= offset;
          break;
        }

        case OP_CALL: {
          int argCount = READ_BYTE();
          if (!callObject(peek(argCount), argCount)) {
            return INTERPRET_RUNTIME_ERROR;
          }
          frame = &frames[frameCount - 1];
          break;
        }

        case OP_INVOKE: {
          ObjString method = READ_STRING();
          int argCount = READ_BYTE();
          if (!invoke(method, argCount)) {
            return INTERPRET_RUNTIME_ERROR;
          }
          frame = &frames[frameCount - 1];
          break;
        }
        
        case OP_SUPER_INVOKE: {
          ObjString method = READ_STRING();
          int argCount = READ_BYTE();
          ObjClass superclass = AS_CLASS(pop());
          if (!invokeFromClass(superclass, method, argCount)) {
            return INTERPRET_RUNTIME_ERROR;
          }
          frame = &frames[frameCount - 1];
          break;
        }

        case OP_CLOSURE: {
          ObjFunction function = AS_FUNCTION(READ_CONSTANT());
          ObjClosure closure = newClosure(function);
          push(OBJ_VAL(closure));
          for (int i = 0; i < closure.upvalueCount; i++) {
            uint8_t isLocal = READ_BYTE();
            uint8_t index = READ_BYTE();
            if (isLocal) {
              closure.upvalues[i] =
                  captureUpvalue(frame.slots + index);
            } else {
              closure.upvalues[i] = frame.closure.upvalues[index];
            }
          }
          break;
        }

        case OP_CLOSE_UPVALUE:
          closeUpvalues(stackTop - 1);
          pop();
          break;

        case OP_RETURN: {
          Object result = pop();

          closeUpvalues(frame.slots);

          frameCount--;
          if (frameCount == 0) {
            pop();
            return INTERPRET_OK;
          }

          stackTop = frame.slots;
          push(result);

          frame = &frames[frameCount - 1];
          break;
        }

        case OP_CLASS:
          push(OBJ_VAL(newClass(READ_STRING())));
          break;

        case OP_INHERIT: {
          Object superclass = peek(1);
          if (!IS_CLASS(superclass)) {
            runtimeError('Superclass must be a class.');
            return INTERPRET_RUNTIME_ERROR;
          }

          ObjClass subclass = AS_CLASS(peek(0));
          tableAddAll(&AS_CLASS(superclass).methods,
                      &subclass.methods);
          pop(); // Subclass.
          break;
        }

        case OP_METHOD:
          defineMethod(READ_STRING());
          break;
      }
    }

  #undef READ_BYTE
  #undef READ_SHORT
  #undef READ_CONSTANT
  #undef READ_STRING
  #undef BINARY_OP
  }
  void hack(bool b) {
    // Hack to avoid unused function error. run() is not used in the
    // scanning chapter.
    run();
    if (b) hack(false);
  }
  InterpretResult interpret(String source) {
    ObjFunction function = compile(source);
    if (function == null) return INTERPRET_COMPILE_ERROR;

    // TEMP
    return INTERPRET_OK;
    push(OBJ_VAL(function));
    ObjClosure closure = newClosure(function);
    pop();
    push(OBJ_VAL(closure));
    callObject(OBJ_VAL(closure), 0);

    return run();
  }



  void runtimeError(String format,[ List<Object> args]) {
    stderr.writeln(sprintf(format, args ?? []));

    for (var i = frameCount - 1; i >= 0; i--) {
      final frame = frames[i];
      final function = frame.closure.function;
      // -1 because the IP is sitting on the next instruction to be
      // executed.
      // int instruction = frame.ip - function.chunk.code - 1;
      final instruction = frame.ip - 1; // TODL: check?
      stderr.write('[line ${function.chunk.lines[instruction]}] in ');
      if (function.name == null) {
        stderr.writeln('script');
      } else {
        stderr.writeln('${function.name}()', );
      }
    }
    resetStack();
  }
}
