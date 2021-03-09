import 'package:demo/constants.dart';
import 'package:demo/runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:provider/provider.dart';

class Monitor extends StatefulWidget {
  final List<String> lines;
  final IconData icon;
  final String title;
  final bool autoScroll;

  Monitor({
    Key key,
    this.lines,
    this.icon,
    this.title,
    this.autoScroll = true,
  }) : super(key: key);

  @override
  MonitorState createState() => MonitorState();
}

class MonitorState extends State<Monitor> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    context.watch<Runtime>();
    final lv = ListView.builder(
      shrinkWrap: true,
      controller: _scrollController,
      padding: EdgeInsets.all(8.0),
      itemCount: widget.lines.length,
      reverse: widget.autoScroll,
      itemBuilder: (context, k) {
        final idx = widget.autoScroll ? widget.lines.length - k - 1 : k;
        final parsed = ParsedText(
          text: widget.lines[idx],
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
    final col = Column(children: [
      Flexible(child: lv),
    ]);
    final placeholder = Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.icon,
            color: Colors.grey.shade300,
          ),
          SizedBox(width: 20.0),
          Text(
            widget.title,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
    return Container(
      color: ColorTheme.terminal,
      child: widget.lines.isEmpty ? placeholder : col,
    );
  }
}
