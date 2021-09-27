import 'package:flutter/material.dart';

class ToggleButton extends StatelessWidget {
  final Function leftToggle;
  final Function rightToggle;
  final bool leftEnabled;
  final bool rightEnabled;
  final IconData leftIcon;
  final IconData rightIcon;

  const ToggleButton({
    Key key,
    this.leftToggle,
    this.rightToggle,
    this.leftEnabled,
    this.rightEnabled,
    this.leftIcon,
    this.rightIcon,
  }) : super(key: key);

  Widget _buildBtn(bool left) {
    final enabled = left ? leftEnabled : rightEnabled;
    final action = left ? leftToggle : rightToggle;
    final icon = left ? leftIcon : rightIcon;
    final color = enabled ? Colors.grey.shade800 : Colors.transparent;
    final iconColor = enabled ? Colors.white : Colors.grey;
    return RawMaterialButton(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      onPressed: action,
      constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      child: Icon(icon, color: iconColor),
      fillColor: color,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade800),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(left ? 8.0 : 0.0),
          bottomLeft: Radius.circular(left ? 8.0 : 0.0),
          topRight: Radius.circular(!left ? 8.0 : 0.0),
          bottomRight: Radius.circular(!left ? 8.0 : 0.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(children: [
        _buildBtn(true),
        // VerticalDivider(width: 0.5),
        _buildBtn(false),
      ]),
    );
  }
}
