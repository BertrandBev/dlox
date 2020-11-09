import 'dart:io';

import 'package:dlox/chunk.dart';
import 'package:dlox/object.dart';
import 'package:dlox/value.dart';
import 'package:sprintf/sprintf.dart';


void disassembleChunk(Chunk chunk, String name) {
  stdout.write(sprintf('== %s ==\n', [name]));

  for (var offset = 0; offset < chunk.code.length;) {
    offset = disassembleInstruction(chunk, offset);
  }
}

int constantInstruction(String name, Chunk chunk, int offset) {
  final constant = chunk.code[offset + 1];
  stdout.write(sprintf('%-16s %4d \'', [name, constant]));
  printValue(chunk.constants[constant]);
  stdout.write('\'\n');
  return offset + 2;
}

int invokeInstruction(String name, Chunk chunk, int offset) {
  final constant = chunk.code[offset + 1];
  final argCount = chunk.code[offset + 2];
  stdout.write(sprintf('%-16s (%d args) %4d \'', [name, argCount, constant]));
  printValue(chunk.constants[constant]);
  stdout.write('\'\n');
  return offset + 3;
}

int simpleInstruction(String name, int offset) {
  stdout.write(sprintf('%s\n', [name]));
  return offset + 1;
}

int byteInstruction(String name, Chunk chunk, int offset) {
  final slot = chunk.code[offset + 1];
  stdout.write(sprintf('%-16s %4d\n', [name, slot]));
  return offset + 2; // [debug]
}

int jumpInstruction(String name, int sign, Chunk chunk, int offset) {
  var jump = chunk.code[offset + 1] << 8;
  jump |= chunk.code[offset + 2];
  stdout.write(
      sprintf('%-16s %4d -> %d\n', [name, offset, offset + 3 + sign * jump]));
  return offset + 3;
}

int disassembleInstruction(Chunk chunk, int offset) {
  stdout.write(sprintf('%04d ', [offset]));
  if (offset > 0 && chunk.lines[offset] == chunk.lines[offset - 1]) {
    stdout.write('   | ');
  } else {
    stdout.write(sprintf('%4d ', [chunk.lines[offset]]));
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
        stdout.write(sprintf('%-16s %4d ', ['OP_CLOSURE', constant]));
        printValue(chunk.constants[constant]);
        stdout.write('\n');
        final function = chunk.constants[constant] as ObjFunction;
        for (var j = 0; j < function.upvalueCount; j++) {
          final isLocal = chunk.code[offset++] == 1;
          final index = chunk.code[offset++];
          stdout.write(sprintf('%04d      |                     %s %d\n',
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
    default:
      print('Unknown opcode $instruction');
      return offset + 1;
  }
}
