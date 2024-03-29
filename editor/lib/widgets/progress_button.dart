import 'package:flutter/material.dart';

class ProgressButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final bool loading;
  final Function onTap;
  final bool disabled;

  ProgressButton({
    this.icon,
    this.loading,
    this.onTap,
    this.disabled = false,
    this.color = Colors.white,
    this.size = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      color: color,
      disabledColor: Colors.grey.shade700,
      constraints: BoxConstraints(),
      padding: EdgeInsets.zero,
      icon: Icon(icon),
      onPressed: !disabled ? onTap : null,
    );
    final progressChild = loading
        ? CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeWidth: 2,
          )
        : SizedBox.shrink();
    final progress = SizedBox(
      width: size,
      height: size,
      child: progressChild,
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        progress,
        Container(child: button),
      ],
    );
  }
}
