import 'package:demo/constants.dart';
import 'package:demo/progress_button.dart';
import 'package:demo/runtime.dart';
import 'package:demo/toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:provider/provider.dart';

class Toolbar extends StatefulWidget {
  final Layout layout;
  final Function onClear;

  const Toolbar({Key key, this.layout, this.onClear}) : super(key: key);

  @override
  _ToolbarState createState() => _ToolbarState();
}

class _ToolbarState extends State<Toolbar> {
  Widget buildRunBtn(BuildContext context) {
    final runtime = context.watch<Runtime>();
    final running = runtime.running;
    final isDone = runtime.done;
    IconData icon = MaterialIcons.play_arrow;
    if (running)
      icon = MaterialIcons.stop;
    else if (isDone) icon = MaterialCommunityIcons.refresh;
    return ProgressButton(
      icon: icon,
      loading: running,
      onTap: () {
        if (running)
          runtime.stop();
        else if (isDone)
          runtime.reset();
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
    final _step = () => runtime.step();
    final _clear = widget.onClear;

    final stepBtn = IconButton(
      icon: Icon(MaterialCommunityIcons.debug_step_over),
      color: color,
      onPressed: runtime.running || runtime.done ? null : _step,
      disabledColor: disabledColor,
    );

    final clearBtn = IconButton(
      icon: Icon(MaterialCommunityIcons.close),
      color: color,
      onPressed: runtime.running ? null : _clear,
      disabledColor: disabledColor,
    );

    final runBtn = buildRunBtn(context);

    final toggleBtn = ToggleButton(
      leftIcon: MaterialCommunityIcons.monitor,
      leftEnabled: widget.layout.showStdout,
      leftToggle: widget.layout.toggleStdout,
      rightIcon: MaterialCommunityIcons.magnify,
      rightEnabled: widget.layout.showVm,
      rightToggle: widget.layout.toggleVm,
    );

    final row = Row(
      children: [
        // compileBtn,
        stepBtn,
        runBtn,
        clearBtn,
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

class Layout {
  final Function onUpdate;
  bool smallScreen = false;
  bool showEditor = true;
  bool showCompiler = true;
  bool showStdout = true;
  bool showVm = true;

  Layout(this.onUpdate);

  void setScreenSize(Size size) {
    bool smallScreen = size.width < 900;
    bool update = this.smallScreen != smallScreen;
    this.smallScreen = smallScreen;
    if (update) {
      showEditor = true;
      showStdout = true;
      showCompiler = !smallScreen;
      showVm = !smallScreen;
      onUpdate();
    }
  }

  void toggleEditor() {
    if (!showEditor) {
      showEditor = true;
      showCompiler &= !smallScreen;
    } else if (showCompiler) {
      showEditor = false;
    }
    onUpdate();
  }

  void toggleCompiler() {
    if (!showCompiler) {
      showCompiler = true;
      showEditor &= !smallScreen;
    } else if (showEditor) {
      showCompiler = false;
    }
    onUpdate();
  }

  void toggleStdout() {
    if (!showStdout) {
      showStdout = true;
      showVm &= !smallScreen;
    } else if (showVm) {
      showStdout = false;
    }
    onUpdate();
  }

  void toggleVm() {
    if (!showVm) {
      showVm = true;
      showStdout &= !smallScreen;
    } else if (showStdout) {
      showVm = false;
    }
    onUpdate();
  }
}
