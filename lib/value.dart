import 'dart:io';
import 'package:dlox/object.dart';
import 'package:sprintf/sprintf.dart';

class Nil {}

void printValue(Object value) {
  if (value is bool) {
    stdout.write(value ? 'true' : 'false');
  } else if (value == Nil) {
    stdout.write('nil');
  } else if (value is double) {
    stdout.write(sprintf('%g', [value]));
  } else if (value is String) {
    stdout.write(value);
  } else if (value is List) {
    stdout.write('[');
    for (var k = 0; k < value.length; k++) {
      if (k > 0) stdout.write(', ');
      printValue(value[k]);
    }
    stdout.write(']');
  } else if (value is Map) {
    stdout.write('[');
    final entries = value.entries.toList();
    for (var k = 0; k < entries.length; k++) {
      if (k > 0) stdout.write(', ');
      printValue(entries[k].key);
      stdout.write(': ');
      printValue(entries[k].value);
    }
    stdout.write(']');
  } else {
    printObject(value);
  }
}

bool valuesEqual(Object a, Object b) {
  return a == b;
}
