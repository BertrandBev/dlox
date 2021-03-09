import 'package:demo/constants.dart';
import 'package:demo/progress_button.dart';
import 'package:demo/runtime.dart';
import 'package:demo/runtime_toolbar.dart';
import 'package:demo/toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:provider/provider.dart';

class EditorToolbar extends StatefulWidget {
  final Layout layout;
  final Function onClear;

  const EditorToolbar({Key key, this.layout, this.onClear}) : super(key: key);

  @override
  _EditorToolbarState createState() => _EditorToolbarState();
}

class _EditorToolbarState extends State<EditorToolbar> {
  @override
  Widget build(BuildContext context) {
    final color = Colors.white;
    final disabledColor = Colors.grey;

    final toggleBtn = ToggleButton(
      leftIcon: MaterialCommunityIcons.code_tags,
      leftEnabled: widget.layout.showEditor,
      leftToggle: widget.layout.toggleEditor,
      rightIcon: MaterialCommunityIcons.matrix,
      rightEnabled: widget.layout.showCompiler,
      rightToggle: widget.layout.toggleCompiler,
    );

    final row = Row(
      children: [
        Spacer(),
        toggleBtn,
      ],
    );
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(
          vertical: BorderSide(color: Colors.grey.shade700, width: 0.5),
        ),
        color: ColorTheme.sidebar,
      ),
      child: row,
    );
  }
}
