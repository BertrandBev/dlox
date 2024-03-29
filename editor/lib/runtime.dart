import 'dart:async';
import 'dart:math';

import 'package:dlox/compiler.dart';
import 'package:dlox/error.dart';
import 'package:dlox/scanner.dart';
import 'package:dlox/vm.dart';
import 'package:flutter/material.dart';

class Runtime extends ChangeNotifier {
  // State hooks
  String source;
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
  bool vmTraceEnabled = true;

  // Performance tracking
  int timeStartedMs;
  double averageIps = 0;

  // Buffers variables
  final stdout = <String>[];
  final vmOut = <String>[];
  final compilerOut = <String>[];

  Runtime({
    this.onCompilerResult,
    this.onInterpreterResult,
  }) {
    vm = VM(silent: true);
    vm.traceExecution = true;
  }

  void _populateBuffer(List<String> buf, String str) {
    if (str == null) return;
    str.trim().split("\n").where((line) => line.isNotEmpty).forEach((line) {
      buf.add(line);
    });
    notifyListeners();
  }

  void _processErrors(List<LangError> errors) {
    if (errors == null) return;
    errors.forEach((err) {
      _populateBuffer(stdout, err.toString());
    });
    notifyListeners();
  }

  void toggleVmTrace() {
    vmTraceEnabled = !vmTraceEnabled;
    vm.traceExecution = vmTraceEnabled;
    if (!vmTraceEnabled) vmOut.clear();
    notifyListeners();
  }

  void clearOutput() {
    stdout.clear();
    vmOut.clear();
    notifyListeners();
  }

  void dispose() {
    if (compileTimer != null) compileTimer.cancel();
    super.dispose();
  }

  void setSource(String source) {
    this.source = source;
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
    if (source == null || (compiledSource == source && compilerResult != null))
      return;
    // Clear interpeter output
    interpreterResult = null;
    onInterpreterResult(interpreterResult);
    // Clear monitors
    compilerOut.clear();
    clearOutput();
    // Compile
    final tokens = Scanner.scan(source);
    compilerResult = Compiler.compile(
      tokens,
      silent: true,
      traceBytecode: true,
    );
    compiledSource = source;
    // Populate result
    final str = compilerResult.debug.buf.toString();
    _populateBuffer(compilerOut, str);
    _processErrors(compilerResult.errors);
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
    }
    return true;
  }

  void _onInterpreterResult() {
    _populateBuffer(stdout, vm.stdout.clear());
    _populateBuffer(vmOut, vm.traceDebug.clear());
    _processErrors(interpreterResult?.errors);
    onInterpreterResult(interpreterResult);
    notifyListeners();
  }

  bool step() {
    if (!_initCode() || done) return false;
    vm.stepCode = true;
    interpreterResult = vm.stepBatch();
    _onInterpreterResult();
    return true;
  }

  Future<bool> run() async {
    if (!_initCode()) return false;
    stopFlag = false;
    running = true;
    notifyListeners();
    vm.stepCode = false;
    timeStartedMs = DateTime.now().millisecondsSinceEpoch;

    while (!done && !stopFlag) {
      interpreterResult = vm.stepBatch(
        // Cope with expensive tracing
        batchCount: vm.traceExecution ? 100 : 500000,
      );
      // Update Ips counter
      final dt = DateTime.now().millisecondsSinceEpoch - timeStartedMs;
      averageIps = vm.stepCount / max(dt, 1) * 1000;
      _onInterpreterResult();
      await Future.delayed(Duration(seconds: 0));
    }

    stopFlag = false;
    running = false;
    notifyListeners();
    return true;
  }

  void reset() {
    if (compilerResult == null) return;
    if (compilerResult.errors.isNotEmpty) return;
    // Clear output
    clearOutput();
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
