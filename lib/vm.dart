import 'package:dlox/compiler.dart';

enum InterpretResult {
  INTERPRET_OK,
  INTERPRET_COMPILE_ERROR,
  INTERPRET_RUNTIME_ERROR
}

InterpretResult interpret(String source) {
  final function = Compiler.compile(source);
  if (function == null) return InterpretResult.INTERPRET_COMPILE_ERROR;
  return InterpretResult.INTERPRET_OK;
}
