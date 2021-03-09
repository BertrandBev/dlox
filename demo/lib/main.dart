import 'package:demo/monitor.dart';
import 'package:demo/runtime.dart';
import 'package:demo/toolbar.dart';
import 'package:dlox/error.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'code_editor.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: HomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final editorKey = GlobalKey<CodeEditorState>();
  final stdoutKey = GlobalKey<MonitorState>();
  final compilerKey = GlobalKey<MonitorState>();
  final vmKey = GlobalKey<MonitorState>();
  Runtime runtime;

  @override
  void initState() {
    super.initState();
    runtime = Runtime(
      getSource: () => editorKey.currentState?.source,
      onStdout: (lines) => stdoutKey.currentState?.addLines(lines),
      onDebugOut: (lines) => vmKey.currentState?.addLines(lines),
      onCompilerResult: (res) {
        _clearOutput();
        // Set compiler output
        final compilerOut = res?.debug?.buf?.toString();
        compilerKey.currentState?.clear();
        compilerKey.currentState?.addLines(compilerOut);
        editorKey.currentState?.setCompilerResult(res);
        _processErrors(res?.errors);
      },
      onInterpreterResult: (res) {
        editorKey.currentState?.setInterpreterResult(res);
        _processErrors(res?.errors);
      },
    );
  }

  @override
  void dispose() {
    runtime.dispose();
    super.dispose();
  }

  void _clearOutput() {
    stdoutKey.currentState?.clear();
    vmKey.currentState?.clear();
  }

  void _processErrors(List<LangError> errors) {
    if (errors == null) return;
    errors.forEach((err) {
      stdoutKey.currentState?.addLines(err.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    final codeEditor = CodeEditor(
        key: editorKey,
        onCodeChange: () {
          runtime.codeChanged();
        });
    final stdoutMonitor = Monitor(key: stdoutKey);
    final compilerMonitor = Monitor(key: compilerKey);
    final vmMonitor = Monitor(key: vmKey);
    final toolbar = Toolbar(onClear: _clearOutput);

    final topRow = Row(children: [
      Expanded(child: codeEditor),
      VerticalDivider(width: 1, color: Colors.grey.shade900),
      Expanded(child: compilerMonitor),
    ]);

    final bottomRow = Row(children: [
      Expanded(child: stdoutMonitor),
      VerticalDivider(width: 1, color: Colors.grey.shade900),
      Expanded(child: vmMonitor),
    ]);

    final layout = Column(children: [
      Expanded(flex: 2, child: topRow),
      toolbar,
      Expanded(flex: 1, child: bottomRow),
    ]);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: MultiProvider(
        providers: [ListenableProvider.value(value: runtime)],
        child: layout,
      ),
    );
  }
}
