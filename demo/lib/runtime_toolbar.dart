import 'package:demo/constants.dart';
import 'package:demo/progress_button.dart';
import 'package:demo/runtime.dart';
import 'package:demo/toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:provider/provider.dart';

class RuntimeToolbar extends StatefulWidget {
  final Layout layout;
  final Function onClear;

  const RuntimeToolbar({Key key, this.layout, this.onClear}) : super(key: key);

  @override
  _RuntimeToolbarState createState() => _RuntimeToolbarState();
}

class _RuntimeToolbarState extends State<RuntimeToolbar> {
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

  Widget buildSpeedBtn(BuildContext context) {
    final runtime = context.watch<Runtime>();
    final enabled = !runtime.vmTraceEnabled;
    final color = enabled ? Colors.grey.shade800 : Colors.transparent;
    final iconColor = enabled ? Colors.white : Colors.grey;
    final btn = RawMaterialButton(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      onPressed: () => runtime.toggleVmTrace(),
      constraints: BoxConstraints(minWidth: 0, minHeight: 0),
      child: Icon(MaterialCommunityIcons.speedometer, color: iconColor),
      fillColor: color,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade800),
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
      ),
    );
    double ips = runtime.averageIps.toDouble();
    var suffix = "";
    if (ips > 1000000) {
      ips /= 1000000;
      suffix = "M";
    } else if (ips > 1000) {
      ips /= 1000;
      suffix = "k";
    }
    final ipsStr = ips.toStringAsFixed(suffix.isNotEmpty ? 2 : 0);
    return Row(children: [
      Text(
        "$ipsStr$suffix ips",
        style: TextStyle(color: Colors.white, fontSize: 16.0),
      ),
      SizedBox(width: 4.0),
      btn,
    ]);
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

    final speedBtn = buildSpeedBtn(context);

    final row = Row(
      children: [
        stepBtn,
        runBtn,
        clearBtn,
        Spacer(),
        speedBtn,
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
