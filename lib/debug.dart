import 'package:dlox/chunk.dart';
import 'package:dlox/object.dart';
import 'package:dlox/value.dart';
import 'package:sprintf/sprintf.dart';

class Debug {
  final bool silent;
  final buf = StringBuffer();

  Debug(this.silent);

  String clear() {
    final str = buf.toString();
    buf.clear();
    return str;
  }

  void stdwrite(String string) {
    buf.write(string);
    if (!silent) {
      // Print buffer
      final str = clear();
      final split = str.split('\n');
      while (split.length > 1) {
        print(split[0]);
        split.removeAt(0);
      }
      buf.write(split.join(''));
    }
  }

  void stdwriteln([String string]) {
    return stdwrite((string ?? '') + '\n');
  }

  void printValue(Object value) {
    stdwrite(valueToString(value));
  }

  void disassembleChunk(Chunk chunk, String name) {
    stdwrite(sprintf('== %s ==\n', [name]));

    var prevLine = -1;
    for (var offset = 0; offset < chunk.code.length;) {
      offset = disassembleInstruction(prevLine, chunk, offset);
      final prevLoc = offset > 0 ? chunk.trace[offset - 1].token.loc : null;
      prevLine = prevLoc.i;
    }
  }

  int constantInstruction(String name, Chunk chunk, int offset) {
    final constant = chunk.code[offset + 1];
    stdwrite(sprintf('%-16s %4d \'', [name, constant]));
    printValue(chunk.constants[constant]);
    stdwrite('\'\n');
    return offset + 2;
  }

  int initializerListInstruction(String name, Chunk chunk, int offset) {
    final nArgs = chunk.code[offset + 1];
    stdwriteln(sprintf('%-16s %4d', [name, nArgs]));
    return offset + 2;
  }

  int invokeInstruction(String name, Chunk chunk, int offset) {
    final constant = chunk.code[offset + 1];
    final argCount = chunk.code[offset + 2];
    stdwrite(sprintf('%-16s (%d args) %4d \'', [name, argCount, constant]));
    printValue(chunk.constants[constant]);
    stdwrite('\'\n');
    return offset + 3;
  }

  int simpleInstruction(String name, int offset) {
    stdwrite(sprintf('%s\n', [name]));
    return offset + 1;
  }

  int byteInstruction(String name, Chunk chunk, int offset) {
    final slot = chunk.code[offset + 1];
    stdwrite(sprintf('%-16s %4d\n', [name, slot]));
    return offset + 2; // [debug]
  }

  int jumpInstruction(String name, int sign, Chunk chunk, int offset) {
    var jump = chunk.code[offset + 1] << 8;
    jump |= chunk.code[offset + 2];
    stdwrite(
        sprintf('%-16s %4d -> %d\n', [name, offset, offset + 3 + sign * jump]));
    return offset + 3;
  }

  int disassembleInstruction(int prevLine, Chunk chunk, int offset) {
    stdwrite(sprintf('%04d ', [offset]));
    final loc = chunk.trace[offset].token.loc;
    // stdwrite("${chunk.trace[offset].token.info} "); // temp
    // final prevLoc = offset > 0 ? chunk.trace[offset - 1].token.loc : null;
    if (offset > 0 && loc.i == prevLine) {
      stdwrite('   | ');
    } else {
      stdwrite(sprintf('%4d ', [loc.i]));
    }

    final instruction = chunk.code[offset];
    switch (OpCode.values[instruction]) {
      case OpCode.CONSTANT:
        return constantInstruction('OP_CONSTANT', chunk, offset);
      case OpCode.NIL:
        return simpleInstruction('OP_NIL', offset);
      case OpCode.TRUE:
        return simpleInstruction('OP_TRUE', offset);
      case OpCode.FALSE:
        return simpleInstruction('OP_FALSE', offset);
      case OpCode.POP:
        return simpleInstruction('OP_POP', offset);
      case OpCode.GET_LOCAL:
        return byteInstruction('OP_GET_LOCAL', chunk, offset);
      case OpCode.TRACER_DEFINE_LOCAL:
        return byteInstruction('TRACER_DEFINE_LOCAL', chunk, offset);
      case OpCode.SET_LOCAL:
        return byteInstruction('OP_SET_LOCAL', chunk, offset);
      case OpCode.GET_GLOBAL:
        return constantInstruction('OP_GET_GLOBAL', chunk, offset);
      case OpCode.DEFINE_GLOBAL:
        return constantInstruction('OP_DEFINE_GLOBAL', chunk, offset);
      case OpCode.SET_GLOBAL:
        return constantInstruction('OP_SET_GLOBAL', chunk, offset);
      case OpCode.GET_UPVALUE:
        return byteInstruction('OP_GET_UPVALUE', chunk, offset);
      case OpCode.SET_UPVALUE:
        return byteInstruction('OP_SET_UPVALUE', chunk, offset);
      case OpCode.GET_PROPERTY:
        return constantInstruction('OP_GET_PROPERTY', chunk, offset);
      case OpCode.SET_PROPERTY:
        return constantInstruction('OP_SET_PROPERTY', chunk, offset);
      case OpCode.GET_SUPER:
        return constantInstruction('OP_GET_SUPER', chunk, offset);
      case OpCode.EQUAL:
        return simpleInstruction('OP_EQUAL', offset);
      case OpCode.GREATER:
        return simpleInstruction('OP_GREATER', offset);
      case OpCode.LESS:
        return simpleInstruction('OP_LESS', offset);
      case OpCode.ADD:
        return simpleInstruction('OP_ADD', offset);
      case OpCode.SUBTRACT:
        return simpleInstruction('OP_SUBTRACT', offset);
      case OpCode.MULTIPLY:
        return simpleInstruction('OP_MULTIPLY', offset);
      case OpCode.DIVIDE:
        return simpleInstruction('OP_DIVIDE', offset);
      case OpCode.POW:
        return simpleInstruction('OP_POW', offset);
      case OpCode.NOT:
        return simpleInstruction('OP_NOT', offset);
      case OpCode.NEGATE:
        return simpleInstruction('OP_NEGATE', offset);
      case OpCode.PRINT:
        return simpleInstruction('OP_PRINT', offset);
      case OpCode.JUMP:
        return jumpInstruction('OP_JUMP', 1, chunk, offset);
      case OpCode.JUMP_IF_FALSE:
        return jumpInstruction('OP_JUMP_IF_FALSE', 1, chunk, offset);
      case OpCode.LOOP:
        return jumpInstruction('OP_LOOP', -1, chunk, offset);
      case OpCode.CALL:
        return byteInstruction('OP_CALL', chunk, offset);
      case OpCode.INVOKE:
        return invokeInstruction('OP_INVOKE', chunk, offset);
      case OpCode.SUPER_INVOKE:
        return invokeInstruction('OP_SUPER_INVOKE', chunk, offset);
      case OpCode.CLOSURE:
        {
          offset++;
          final constant = chunk.code[offset++];
          stdwrite(sprintf('%-16s %4d ', ['OP_CLOSURE', constant]));
          printValue(chunk.constants[constant]);
          stdwrite('\n');
          final function = chunk.constants[constant] as ObjFunction;
          for (var j = 0; j < function.upvalueCount; j++) {
            final isLocal = chunk.code[offset++] == 1;
            final index = chunk.code[offset++];
            stdwrite(sprintf('%04d      |                     %s %d\n',
                [offset - 2, isLocal ? 'local' : 'upvalue', index]));
          }

          return offset;
        }
      case OpCode.CLOSE_UPVALUE:
        return simpleInstruction('OP_CLOSE_UPVALUE', offset);
      case OpCode.RETURN:
        return simpleInstruction('OP_RETURN', offset);
      case OpCode.CLASS:
        return constantInstruction('OP_CLASS', chunk, offset);
      case OpCode.INHERIT:
        return simpleInstruction('OP_INHERIT', offset);
      case OpCode.METHOD:
        return constantInstruction('OP_METHOD', chunk, offset);
      case OpCode.LIST_INIT:
        return initializerListInstruction('OP_LIST_INIT', chunk, offset);
      case OpCode.LIST_INIT_RANGE:
        return simpleInstruction('LIST_INIT_RANGE', offset);
      case OpCode.MAP_INIT:
        return initializerListInstruction('OP_MAP_INIT', chunk, offset);
      case OpCode.CONTAINER_GET:
        return simpleInstruction('OP_CONTAINER_GET', offset);
      case OpCode.CONTAINER_SET:
        return simpleInstruction('OP_CONTAINER_SET', offset);
      case OpCode.CONTAINER_GET_RANGE:
        return simpleInstruction('CONTAINER_GET_RANGE', offset);
      case OpCode.CONTAINER_ITERATE:
        return simpleInstruction('CONTAINER_ITERATE', offset);
      default:
        throw Exception('Unknown opcode $instruction');
    }
  }
}
