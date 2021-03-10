import 'package:flutter/material.dart';

enum FlushbarType {
  INFO,
  WARNING,
}

class Flushbar {
  static void show(
    BuildContext context,
    String msg, {
    FlushbarType type = FlushbarType.INFO,
  }) {
    final icon = type == FlushbarType.INFO ? Icons.info_outline : Icons.error_outline;
    final color = type == FlushbarType.INFO ? Colors.blueAccent : Colors.redAccent;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          margin: EdgeInsets.all(0.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              SizedBox(width: 8.0),
              Text(msg, style: TextStyle(fontSize: 16.0)),
            ],
          ),
        ),
        width: 600,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        // padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
    );
  }
}
