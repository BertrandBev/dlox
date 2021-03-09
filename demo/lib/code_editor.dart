import 'package:demo/lox_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:code_text_field/code_field.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart'
    show monokaiSublimeTheme;

class CodeEditor extends StatefulWidget {
  CodeEditor({Key key}) : super(key: key);

  @override
  CodeEditorState createState() => CodeEditorState();
}

// A nice class
// class superclass {
//     fun print(n) {
//         print("a superclass");
//         print n;
//     }
// }

// class class < superclass {
//     fun init(val) {
//         this.val = val;
//         super.print(val);
//         this.list = [1, 2, 3, "go"];
//         this.map = {"a": 1, "b": 2}
//     }
// }

class CodeEditorState extends State<CodeEditor> {
  CodeController _codeController;

  @override
  void initState() {
    super.initState();
    final source = """// Capabilites showoff
fun fib(n) {
  if (n < 2) return n;
  return fib(n - 2) + fib(n - 1);
}
print fib(3);
""";
    // Instantiate the CodeController
    _codeController = CodeController(
      text: source,
      language: lox,
      theme: monokaiSublimeTheme,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String get source {
    return _codeController.text;
  }

  @override
  Widget build(BuildContext context) {
    return CodeField(
      controller: _codeController,
      textStyle: TextStyle(fontFamily: 'SourceCode'),
      expands: true,
    );
  }
}
