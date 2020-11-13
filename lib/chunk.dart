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
  CONTAINER_GET,
  CONTAINER_SET,
  MAP_INIT,
}

class Chunk {
  List<int> code = <int>[];
  List<int> lines = <int>[];
  List<Object> constants = <Object>[];

  Chunk();

  int get count => code.length;

  void write(int byte, int line) {
    code.add(byte);
    lines.add(line);
  }

  int addConstant(Object value) {
    constants.add(value);
    return constants.length - 1;
  }
}
