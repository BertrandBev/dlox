import 'package:demo/monitor.dart';
import 'package:demo/runtime.dart';
import 'package:demo/runtime_toolbar.dart';
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
  Layout layout;
  Runtime runtime;

  @override
  void initState() {
    super.initState();
    runtime = Runtime(
      getSource: () => editorKey.currentState?.source,
      onCompilerResult: (res) {
        runtime.clearOutput();
        editorKey.currentState?.setCompilerResult(res);
      },
      onInterpreterResult: (res) {
        editorKey.currentState?.setInterpreterResult(res);
      },
    );
    layout = Layout(() {
      Future.microtask(() => setState(() {}));
    });
  }

  @override
  void dispose() {
    runtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queryData = MediaQuery.of(context);
    layout.setScreenSize(queryData.size);

    final codeEditor = CodeEditor(
        key: editorKey,
        onCodeChange: () {
          runtime.codeChanged();
        });
    final stdoutMonitor = Monitor(runtime.stdout, key: stdoutKey);
    final compilerMonitor = Monitor(runtime.compilerOut, key: compilerKey);
    final vmMonitor = Monitor(runtime.vmOut, key: vmKey);
    final toolbar = Toolbar(
      layout: layout,
      onClear: () => runtime.clearOutput(),
    );

    final topRow = Row(children: [
      if (layout.showEditor) Expanded(child: codeEditor),
      if (layout.showEditor && layout.showCompiler)
        VerticalDivider(width: 0.5, color: Colors.grey.shade900),
      if (layout.showCompiler) Expanded(child: compilerMonitor),
    ]);

    final bottomRow = Row(children: [
      if (layout.showStdout) Expanded(child: stdoutMonitor),
      if (layout.showStdout && layout.showVm)
        VerticalDivider(width: 0.5, color: Colors.grey.shade900),
      if (layout.showVm) Expanded(child: vmMonitor),
    ]);

    final body = Column(children: [
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
        child: body,
      ),
    );
  }
}
