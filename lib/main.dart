import 'dart:convert';
import 'dart:io';
import 'package:dlox/scanner.dart';
import 'package:dlox/vm.dart';
import 'compiler.dart';
import 'debug.dart';

void repl() {
  final vm = SyncVM();
  while (true) {
    stdwrite('> ');
    final line = stdin.readLineSync(encoding: Encoding.getByName('utf-8'));
    if (line == null) break;
    final tokens = Scanner.scan(line + '\n', );
    vm.compile(tokens);
    vm.run();
  }
}

String readFile(String path) {
  return File(path).readAsStringSync();
}

void runFile(String path) {
  CompilerResult result;
  final vm = SyncVM();
  final source = readFile(path);
  final tokens = Scanner.scan(source, );
  result = vm.compile(tokens);
  if (result.errors.isNotEmpty) exit(65);
  vm.setFunctionParams(result, FunctionParams());
  final res = vm.run();
  if (res.errors.isNotEmpty) exit(70);
}

void main(List<String> args) async {
  final path =
      '/Users/bbevillard/Documents/Bev/Code/Flutter/paradigm/lib/lang/examples/';
  args = [path + 'easy.txt'];
  if (args.isEmpty) {
    repl();
  } else if (args.length == 1) {
    runFile(args[0]);
  } else {
    stdwriteln('Usage: clox [path]');
    exit(64);
  }
}
