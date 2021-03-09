import 'dart:async';

import 'package:dlox/compiler.dart';
import 'package:dlox/error.dart';
import 'package:dlox/scanner.dart';
import 'package:dlox/vm.dart';
import 'package:flutter/foundation.dart';

class Runtime extends ChangeNotifier {
  // State hooks
  final String Function() getSource;
  final Function(String) onStdout;
  final Function(String) onDebugOut;
  final Function(CompilerResult) onCompilerResult;
  final Function(InterpreterResult) onInterpreterResult;

  // Compiler timer
  Timer compileTimer;

  // Code variables
  VM vm;
  String compiledSource;
  CompilerResult compilerResult;
  InterpreterResult interpreterResult;
  bool running = false;
  bool stopFlag = false;

  Runtime({
    this.getSource,
    this.onStdout,
    this.onDebugOut,
    this.onCompilerResult,
    this.onInterpreterResult,
  }) {
    vm = VM(silent: true);
    vm.traceExecution = true;
  }

  void dispose() {
    if (compileTimer != null) compileTimer.cancel();
    super.dispose();
  }

  void codeChanged() {
    if (compileTimer != null) compileTimer.cancel();
    compileTimer = Timer(Duration(milliseconds: 500), () {
      compileTimer = null;
      compile();
    });
  }

  void setTracer(bool enabled) {
    vm.traceExecution = enabled;
  }

  void compile() {
    final source = getSource();
    if (source == null || (compiledSource == source && compilerResult != null))
      return;
    final tokens = Scanner.scan(source);
    compilerResult = Compiler.compile(tokens, silent: true);
    compiledSource = source;
    onCompilerResult(compilerResult);
  }

  bool get done {
    return interpreterResult?.done ?? false;
  }

  bool _initCode() {
    // Compile if needed
    compile();
    if (compilerResult == null || compilerResult.errors.isNotEmpty)
      return false;
    if (vm.compilerResult != compilerResult) {
      vm.setFunction(compilerResult, FunctionParams());
      interpreterResult = null;
      onCompilerResult(compilerResult);
    }
    return true;
  }

  bool step() {
    if (!_initCode() || done) return false;
    vm.stepCode = true;
    interpreterResult = vm.stepBatch();
    onStdout(vm.stdout.clear());
    onDebugOut(vm.traceDebug.clear());
    onInterpreterResult(interpreterResult);
    notifyListeners();
    return true;
  }

  Future<bool> run() async {
    if (!_initCode()) return false;
    stopFlag = false;
    running = true;
    notifyListeners();
    vm.stepCode = false;

    while (!done && !stopFlag) {
      interpreterResult = vm.stepBatch(
        // Cope with expensive tracing
        batchCount: vm.traceExecution ? 100 : 100000,
      );
      onStdout(vm.stdout.clear());
      onDebugOut(vm.traceDebug.clear());
      await Future.delayed(Duration(seconds: 0));
    }

    onInterpreterResult(interpreterResult);
    stopFlag = false;
    running = false;
    notifyListeners();
    return true;
  }

  void reset() {
    if (compilerResult == null) return;
    if (compilerResult.errors.isNotEmpty) return;
    // Clear output
    onCompilerResult(compilerResult);
    // Set interpreter
    vm.setFunction(compilerResult, FunctionParams());
    interpreterResult = null;
    onInterpreterResult(interpreterResult);
    notifyListeners();
  }

  void stop() {
    if (running) stopFlag = true;
  }
}
