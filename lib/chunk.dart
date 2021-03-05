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
  TRACER_DEFINE_LOCAL,
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

enum TraceEventType {
  NONE,
  VARIABLE_SET,
  VARIABLE_GET,
}

class TraceEvent {
  final Token token;
  final TraceEventType type;

  TraceEvent(this.token, {this.type = TraceEventType.NONE});
}

class Chunk {
  final List<int> code = [];
  final List<Object> constants = [];
  // Trace information
  final List<int> lines = [];
  final List<TraceEvent> trace = [];

  Chunk();

  int get count => code.length;

  void write(int byte, Token token) {
    code.add(byte);
    trace.add(TraceEvent(token));
    lines.add(token.loc.i);
  }

  int addConstant(Object value) {
    constants.add(value);
    return constants.length - 1;
  }

  void setTraceEvent(TraceEvent event) {
    trace[trace.length - 1] = event;
  }
}
