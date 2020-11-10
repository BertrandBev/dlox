import 'dart:convert';
import 'dart:io';

import 'package:dlox/vm.dart';

VM vm = VM();

void repl() {
  while (true) {
    stdout.write('> ');
    final line = stdin.readLineSync(encoding: Encoding.getByName('utf-8'));
    if (line == null) break;
    vm.interpret(line + '\n');
  }
}

String readFile(String path) {
  return File(path).readAsStringSync();
}

void runFile(String path) {
  final source = readFile(path);
  final result = vm.interpret(source);
  if (result == InterpretResult.COMPILE_ERROR) exit(65);
  if (result == InterpretResult.RUNTIME_ERROR) exit(70);
}

void main(List<String> args) {
  // initVM();
  args = ['examples/binary_trees.lox'];

  if (args.isEmpty) {
    repl();
  } else if (args.length == 1) {
    runFile(args[0]);
  } else {
    stderr.writeln('Usage: clox [path]');
    exit(64);
  }
}
