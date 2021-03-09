import 'package:demo/constants.dart';
import 'package:demo/runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:provider/provider.dart';

class Monitor extends StatefulWidget {
  final List<String> lines;

  Monitor(this.lines, {Key key}) : super(key: key);

  @override
  MonitorState createState() => MonitorState();
}

class MonitorState extends State<Monitor> {
  final ScrollController _scrollController = ScrollController();

  void autoScroll() async {
    await Future.delayed(Duration(milliseconds: 50));
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<Runtime>();
    autoScroll();
    final lv = ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(8.0),
      itemCount: widget.lines.length,
      itemBuilder: (context, k) {
        final parsed = ParsedText(
          text: widget.lines[k],
          style: TextStyle(
            color: Colors.grey.shade200,
            fontSize: 16.0,
            fontFamily: 'SourceCode',
          ),
          parse: <MatchText>[
            MatchText(
              pattern: r"-?\d+(?:\.\d+)?",
              style: TextStyle(
                color: Colors.red,
              ),
            ),
            MatchText(
              pattern: r"OP_[A-Z_]+",
              style: TextStyle(
                color: Colors.green,
              ),
            ),
            MatchText(
              pattern: r"==.+==",
              style: TextStyle(color: Colors.blue),
            ),
            MatchText(
              pattern: r"'.+'",
              style: TextStyle(color: Colors.yellow),
            ),
            MatchText(
              pattern: r"true|false",
              style: TextStyle(color: Colors.red),
            ),
          ],
        );
        return Padding(
          padding: EdgeInsets.all(4.0),
          child: parsed,
        );
      },
    );
    return Container(
      color: ColorTheme.terminal,
      child: lv,
    );
  }
}
