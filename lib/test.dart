import 'dart:async';
import 'dart:io';
import 'package:dlox/scanner.dart';
import 'package:dlox/vm.dart';
import 'package:path/path.dart';

import 'compiler.dart';

void main() async {
  Test.run();
}

class Test {
  final vm = VM(silent: true);

  static void run() {
    Test._();
  }

  Test._() {
    runAllDirs();
    // runFile(File("./test/constructor/return_value.lox"));
  }

  Future<List<FileSystemEntity>> dirContents(Directory dir) {
    var files = <FileSystemEntity>[];
    var completer = Completer<List<FileSystemEntity>>();
    var lister = dir.list(recursive: false);
    lister.listen((file) => files.add(file),
        // should also register onError
        onDone: () => completer.complete(files));
    return completer.future;
  }

  Future<bool> runAllDirs() async {
    // run tests
    final dirList = await dirContents(Directory('./test'));
    for (var k = 0; k < dirList.length; k++) {
      final dir = dirList[k];
      print('Running test group: ${basename(dir.path)}');
      final valid = await runAllFiles(dir);
      if (!valid) return false;
    }
    return true;
  }

  Future<bool> runAllFiles(dir) async {
    final fileList = await dirContents(dir);
    for (var k = 0; k < fileList.length; k++) {
      final file = fileList[k];
      final valid = await runFile(file);
      if (!valid) return false;
    }
    return true;
  }

  Future<bool> runFile(file) async {
    final tab = '  ';
    print('$tab Running test: ${basename(file.path)}...');
    final source = await File(file.path).readAsString();

    // Create line map
    final lineNumber = <int>[];
    for (var k = 0, line = 0; k < source.length; k++) {
      if (source[k] == '\n') line += 1;
      lineNumber.add(line);
    }

    // Extract static error reqs
    final errExp = RegExp(r'// Error at (.+):(.+)');
    final errMatches = errExp.allMatches(source);
    final errRef = errMatches.map((e) {
      final line = lineNumber[e.start];
      var msg = e.group(2).trim();
      if (msg.endsWith('.')) msg = msg.substring(0, msg.length - 1);
      return '$line:$msg';
    }).toSet();

    // Compile test
    CompilerResult result;
    final tokens = Scanner.scan(source);
    result = Compiler.compile(tokens, silent: true);
    final errList =
        result.errors.map((e) => '${e.token.loc.i}:${e.msg}').toSet();
    if (!setEq(errRef, errList)) {
      print('$tab Compile error mismatch');
      print('$tab -> expected: $errRef');
      print('$tab -> got: $errList');
      return false;
    }
    if (errList.isNotEmpty) return true;

    // Run test
    vm.stdout.clear();
    vm.setFunction(result, FunctionParams());
    vm.run();

    // Extract test reqs
    var rtnExp = RegExp(r'// expect: (.+)');
    final rtnMatches = rtnExp.allMatches(source);
    final stdoutRef = rtnMatches.map((e) => e.group(1)).toList();
    final stdout = vm.stdout
        .toString()
        .trim()
        .split('\n')
        .where((str) => str.isNotEmpty)
        .toList();
    if (!listEq(stdoutRef, stdout)) {
      print('$tab stdout mismatch');
      print('$tab -> expected: $stdoutRef');
      print('$tab -> got: $stdout');
      return false;
    }

    print('$tab OK');
    return true;
  }

  static bool setEq(Set s1, Set s2) {
    return s1.length == s2.length && s1.every(s2.contains);
  }

  static bool listEq(List l1, List l2) {
    if (l1.length != l2.length) return false;
    for (var k = 0; k < l1.length; k++) {
      if (l1[k] != l2[k]) return false;
    }
    return true;
  }
}
