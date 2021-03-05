import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rich_code_editor/exports.dart';

/// This is a dummy implementation for Syntax highlighter.
/// Ideally, you would implement the `SyntaxHighlighterBase` interface as per your need of highlighting rules.
class DummySyntaxHighlighter implements SyntaxHighlighterBase {
  @override
  TextEditingValue addTextRemotely(TextEditingValue oldValue, String newText) {
    return null;
  }

  @override
  TextEditingValue onBackSpacePress(
      TextEditingValue oldValue, TextSpan currentSpan) {
    return null;
  }

  @override
  TextEditingValue onEnterPress(TextEditingValue oldValue) {
    var padding = "    ";
    var newText = oldValue.text + padding;
    var newValue = oldValue.copyWith(
      text: newText,
      composing: TextRange(start: -1, end: -1),
      selection: TextSelection.fromPosition(TextPosition(
          affinity: TextAffinity.upstream, offset: newText.length)),
    );

    return newValue;
  }

  @override
  List<TextSpan> parseText(TextEditingValue tev) {
    var texts = tev.text.split(' ');

    var lsSpans = List<TextSpan>();
    texts.forEach((text) {
      if (text == 'class') {
        lsSpans
            .add(TextSpan(text: text, style: TextStyle(color: Colors.green)));
      } else if (text == 'if' || text == 'else') {
        lsSpans.add(TextSpan(text: text, style: TextStyle(color: Colors.blue)));
      } else if (text == 'return') {
        lsSpans.add(TextSpan(text: text, style: TextStyle(color: Colors.red)));
      } else {
        lsSpans
            .add(TextSpan(text: text, style: TextStyle(color: Colors.black)));
      }
      lsSpans.add(TextSpan(text: ' ', style: TextStyle(color: Colors.black)));
    });
    return lsSpans;
  }
}

class DemoCodeEditor extends StatefulWidget {
  @override
  _DemoCodeEditorState createState() => _DemoCodeEditorState();
}

class _DemoCodeEditorState extends State<DemoCodeEditor> {
  RichCodeEditingController _rec;
  SyntaxHighlighterBase _syntaxHighlighterBase;

  @override
  void initState() {
    super.initState();
    _syntaxHighlighterBase = DummySyntaxHighlighter();
    _rec = RichCodeEditingController(_syntaxHighlighterBase);
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
          child: RichCodeField(
            autofocus: true,
            controller: _rec,
            textCapitalization: TextCapitalization.none,
            decoration: null,
            syntaxHighlighter: _syntaxHighlighterBase,
            maxLines: null,
            onChanged: (String s) {},
            onBackSpacePress: (TextEditingValue oldValue) {},
            onEnterPress: (TextEditingValue oldValue) {
              var result = _syntaxHighlighterBase.onEnterPress(oldValue);
              if (result != null) {
                _rec.value = result;
              }
            },
          )),
    );
  }
}
