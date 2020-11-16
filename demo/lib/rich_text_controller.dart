library rich_text_controller;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class RichTextController extends TextEditingController {
  final Map<RegExp, TextStyle> patternMap;
  final Function(List<String> match) onMatch;
  RichTextController(this.patternMap, {this.onMatch})
      : assert(patternMap != null);

  @override
  TextSpan buildTextSpan({TextStyle style, bool withComposing}) {
    List<InlineSpan> children = [];
    if (text.contains('-')) {
      children.add(TextSpan(
          style: TextStyle(color: Colors.redAccent),
          text: text.substring(0, text.indexOf('-'))));
      children.add(TextSpan(text: text.substring(text.indexOf('-'))));
    } else {
      children
          .add(TextSpan(style: TextStyle(color: Colors.redAccent), text: text));
    }
    return TextSpan(style: style, children: children);
  }

  // @override
  TextSpan buildTextSpans({TextStyle style, bool withComposing}) {
    List<TextSpan> children = [];
    List<String> matches = [];
    RegExp allRegex;
    allRegex = RegExp(patternMap.keys.map((e) => e.pattern).join('|'));

    text.splitMapJoin(
      allRegex,
      onMatch: (Match m) {
        RegExp k = patternMap.entries.singleWhere((element) {
          return element.key.allMatches(m[0]).isNotEmpty;
        }).key;
        children.add(
          TextSpan(
            text: m[0],
            style: patternMap[k],
          ),
        );
        // if (!matches.contains(m[0])) {
        //   matches.add(m[0]);
        //   return this.onMatch(matches);
        // }
        return m[0];
      },
      onNonMatch: (String span) {
        style = style.copyWith(color: Colors.red);
        children.add(TextSpan(text: span, style: style));
        return span.toString();
      },
    );
    print("children: $children");
    return TextSpan(style: style, children: children);
  }
}
