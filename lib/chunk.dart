import 'package:dlox/scanner.dart';

enum OpCode {
  CONSTANT,
  NIL,
  TRUE,
  FALSE,
  POP,
  GET_LOCAL,
  SET_LOCAL,
  GET_GLOBAL,
  DEFINE_GLOBAL,
  SET_GLOBAL,
  GET_UPVALUE,
  SET_UPVALUE,
  GET_PROPERTY,
  SET_PROPERTY,
  GET_SUPER,
  EQUAL,
  GREATER,
  LESS,
  ADD,
  SUBTRACT,
  MULTIPLY,
  DIVIDE,
  POW,
  MOD,
  NOT,
  NEGATE,
  PRINT,
  JUMP,
  JUMP_IF_FALSE,
  LOOP,
  CALL,
  INVOKE,
  SUPER_INVOKE,
  CLOSURE,
  CLOSE_UPVALUE,
  RETURN,
  CLASS,
  INHERIT,
  METHOD,
  LIST_INIT,
  LIST_INIT_RANGE,
  MAP_INIT,
  CONTAINER_GET,
  CONTAINER_SET,
  CONTAINER_GET_RANGE,
  CONTAINER_ITERATE,
}

class Chunk {
  final List<int> code = [];
  final List<Object> constants = [];
  final _constantMap = <Object, int>{};
  // Trace information
  final List<int> lines = [];

  Chunk();

  int get count => code.length;

  void write(int byte, Token token) {
    code.add(byte);
    lines.add(token.loc.i);
  }

  int addConstant(Object value) {
    final idx = _constantMap[value];
    if (idx != null) return idx;
    // Add entry
    constants.add(value);
    _constantMap[value] = constants.length - 1;
    return constants.length - 1;
  }
}
