import 'dart:convert';
import 'dart:io';
import 'package:dlox/scanner.dart';
import 'package:dlox/vm.dart';
import 'compiler.dart';

void repl() {
  final vm = VM();
  while (true) {
    stdout.write('> ');
    final line = stdin.readLineSync(encoding: Encoding.getByName('utf-8'));
    if (line == null) break;
    final tokens = Scanner.scan(line + '\n');
    final compilerResult = Compiler.compile(tokens);
    if (compilerResult.errors.isNotEmpty) continue;
    final globals = Map.fromEntries(vm.globals.data.entries);
    vm.setFunction(compilerResult, FunctionParams(globals: globals));
    vm.run();
  }
}

String readFile(String path) {
  return File(path).readAsStringSync();
}

void runFile(String path) {
  final vm = VM();
  final source = readFile(path);
  final tokens = Scanner.scan(
    source,
  );
  final compilerResult = Compiler.compile(tokens);
  if (compilerResult.errors.isNotEmpty) exit(65);
  vm.setFunction(compilerResult, FunctionParams());
  final intepreterResult = vm.run();
  if (intepreterResult.errors.isNotEmpty) exit(70);
}

void main(List<String> args) async {
  final path =
      '/Users/bbevillard/Documents/Bev/Code/Dart/dlox/examples/';
  args = [path + 'closure.lox'];
  if (args.isEmpty) {
    repl();
  } else if (args.length == 1) {
    runFile(args[0]);
  } else {
    print('Usage: dart main.dart [path]');
    exit(64);
  }
}
