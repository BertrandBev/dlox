import 'package:demo/constants.dart';
import 'package:demo/progress_button.dart';
import 'package:demo/runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:provider/provider.dart';

class Toolbar extends StatefulWidget {
  @override
  _ToolbarState createState() => _ToolbarState();
}

class _ToolbarState extends State<Toolbar> {
  Widget buildRunBtn(BuildContext context) {
    final runtime = context.watch<Runtime>();
    final running = runtime.running;
    IconData icon = MaterialIcons.play_arrow;
    if (running) icon = MaterialIcons.stop;
    return ProgressButton(
      icon: icon,
      loading: running,
      onTap: () {
        if (running)
          runtime.stop();
        else
          runtime.run();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Colors.white;
    final disabledColor = Colors.grey;
    final runtime = context.watch<Runtime>();
    final _compile = () => runtime.compile();
    final _step = () => runtime.step();
    final _reset = () => runtime.reset();

    final compileBtn = IconButton(
      icon: Icon(MaterialCommunityIcons.cogs),
      color: color,
      onPressed: runtime.running ? null : _compile,
      disabledColor: disabledColor,
    );

    final stepBtn = IconButton(
      icon: Icon(MaterialCommunityIcons.debug_step_over),
      color: color,
      onPressed: runtime.running ? null : _step,
      disabledColor: disabledColor,
    );

    final resetBtn = IconButton(
      icon: Icon(MaterialCommunityIcons.close),
      color: color,
      onPressed: runtime.running ? null : _reset,
      disabledColor: disabledColor,
    );

    final runBtn = buildRunBtn(context);

    final row = Row(
      children: [
        compileBtn,
        stepBtn,
        runBtn,
        resetBtn,
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
