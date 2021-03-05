import 'package:demo/rich_controller.dart';
import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

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
        fontFamily: 'SourceCode',
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: RichTextControllerDemo(),
    );
  }
}

class RichTextControllerDemo extends StatefulWidget {
  @override
  _RichTextControllerDemoState createState() => _RichTextControllerDemoState();
}

class _RichTextControllerDemoState extends State<RichTextControllerDemo> {
// Add a controller
  LinkedScrollControllerGroup _controllers;
  ScrollController _numberScroll;
  ScrollController _codeScroll;
  RichTextController _codeController;
  TextEditingController _numberController;
  //
  String lines;

  @override
  void initState() {
    super.initState();
    _controllers = LinkedScrollControllerGroup();
    _numberScroll = _controllers.addAndGet();
    _codeScroll = _controllers.addAndGet();
    _numberController = TextEditingController();
    _codeController = RichTextController(
      patternMap: {
        RegExp(r"\B#[a-zA-Z0-9]+\b"): TextStyle(color: Colors.red),
        RegExp(r"\B@[a-zA-Z0-9]+\b"): TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.blue,
        ),
        RegExp(r"\B![a-zA-Z0-9]+\b"):
            TextStyle(color: Colors.yellow, fontStyle: FontStyle.italic),
      },
      // Now you have the option to add string Matching!
      // stringMap: {
      //   "String1": TextStyle(color: Colors.red),
      //   "String2": TextStyle(color: Colors.yellow),
      // },
      onMatch: (List<String> matches) {
        // Do something with matches.
        //! P.S
        // as long as you're typing, the controller will keep updating the list.
      },
    );
    _codeController.addListener(() {
      final str = _codeController.text.split("\n");
      final buf = <String>[];
      for (var k = 0; k < str.length; k++) {
        buf.add(k.toString());
      }
      _numberController.text = buf.join("\n");
    });
  }

  @override
  void dispose() {
    _numberScroll.dispose();
    _codeScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            width: 32.0,
            color: Colors.grey.shade900,
            child: TextField(
                style: TextStyle(
                  color: Colors.grey.shade200,
                ),
                controller: _numberController,
                enabled: false,
                maxLines: 10,
                scrollController: _numberScroll,
                decoration: InputDecoration(
                  disabledBorder: InputBorder.none,
                ),
                textAlign: TextAlign.right),
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: TextField(
              controller: _codeController,
              maxLines: 10,
              scrollController: _codeScroll,
              decoration: InputDecoration(
                disabledBorder: InputBorder.none,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
