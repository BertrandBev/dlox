import 'package:demo/rich_text_controller.dart';
import 'package:flutter/material.dart';

class CodeEditor extends StatefulWidget {
  @override
  _CodeEditorState createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    //_richTextFieldState.currentState?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Dummy Editor"),
        ),
        body: Container(
          height: 300.0,
          margin: EdgeInsets.all(24.0),
          padding: EdgeInsets.all(24.0),
          decoration:
              new BoxDecoration(border: new Border.all(color: Colors.grey)),
          child: MyStatefulWidget(),
        ));
  }
}

/// This is the stateful widget that the main application instantiates.
class MyStatefulWidget extends StatefulWidget {
  MyStatefulWidget({Key key}) : super(key: key);

  @override
  _MyStatefulWidgetState createState() => _MyStatefulWidgetState();
}

/// This is the private State class that goes with MyStatefulWidget.
class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  RichTextController _controller;

  void initState() {
    super.initState();
    _controller = RichTextController({
      //
      //* Returns every Hashtag with red color
      //
      RegExp(r"\B#[a-zA-Z0-9]+\b"): TextStyle(color: Colors.red),
      //
      //* Returns every Mention with blue color and bold style.
      //
      RegExp(r"\B@[a-zA-Z0-9]+\b"): TextStyle(
        fontWeight: FontWeight.w800,
        color: Colors.blue,
      ),
      //
      //* Returns every word after '!' with yellow color and italic style.
      //
      RegExp(r"\B![a-zA-Z0-9]+\b"):
          TextStyle(color: Colors.yellow, fontStyle: FontStyle.italic),
      // add as many expressions as you need!
    }, onMatch: (List<String> matches) {
      // Do something
    });
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(6),
        child: TextFormField(
          controller: _controller,
          decoration: InputDecoration(border: OutlineInputBorder()),
        ),
      ),
    );
  }
}
