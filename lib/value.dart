import 'dart:io';
import 'package:dlox/object.dart';
import 'package:sprintf/sprintf.dart';

void printValue(Object value) {
  if (value is bool) {
    stdout.write(value ? 'true' : 'false');
  } else if (value == null) {
    stdout.write('nil');
  } else if (value is double) {
    stdout.write(sprintf('%g', [value]));
  } else {
    printObject(value);
  }
}

bool valuesEqual(Object a, Object b) {
  return a == b;
}
