import 'package:editor/editor_toolbar.dart';
import 'package:editor/widgets/monitor.dart';
import 'package:editor/runtime.dart';
import 'package:editor/runtime_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:provider/provider.dart';

import 'code_editor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'dlox',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

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
      onCompilerResult: (res) {
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
      runtime: runtime,
    );

    final stdoutMonitor = Monitor(
      key: stdoutKey,
      lines: runtime.stdout,
      icon: MaterialCommunityIcons.monitor,
      title: 'Terminal',
    );
    final compilerMonitor = Monitor(
      autoScroll: false,
      key: compilerKey,
      lines: runtime.compilerOut,
      icon: MaterialCommunityIcons.matrix,
      title: 'Bytecode',
    );
    var monitorTitle = 'VM trace';
    final vmMonitor = Monitor(
      key: vmKey,
      lines: runtime.vmOut,
      icon: MaterialCommunityIcons.magnify,
      placeholderBuilder: (widget) {
        if (!runtime.vmTraceEnabled) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget,
              const SizedBox(height: 4.0),
              const Text('disabled for performance',
                  style: TextStyle(fontSize: 16.0, color: Colors.grey)),
            ],
          );
        }
        return widget;
      },
      title: monitorTitle,
    );
    final runtimeToolbar = RuntimeToolbar(
      layout: layout,
      onClear: () => runtime.clearOutput(),
    );
    final editorToolbar = EditorToolbar(
      layout: layout,
      onSnippet: (source) {
        editorKey.currentState?.setSource(source);
        runtime.reset();
      },
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
      editorToolbar,
      Expanded(flex: 2, child: topRow),
      runtimeToolbar,
      Expanded(flex: 1, child: bottomRow),
    ]);

    return Scaffold(
      body: MultiProvider(
        providers: [ListenableProvider.value(value: runtime)],
        child: body,
      ),
    );
  }
}
