import 'dart:typed_data';

int millis() {
  return DateTime.now().millisecondsSinceEpoch;
}

void fixedArrayTest() {
  // Run benchmark
  const COUNT = 1000000;

  var time = millis();
  final list = List(COUNT);
  // Fill up list
  for (var k = 0; k < COUNT; k++) {
    list[k] = k;
  }
  // Access elements
  var acc = 0;
  for (var i = 0; i < COUNT; i++) {
    acc += list[i];
  }
  // Access elements
  print('List dt: ${millis() - time}ms');

  time = millis();
  final list2 = Uint16List(COUNT);
  // Fill up list
  for (var k = 0; k < COUNT; k++) {
    list2[k] = k;
  }
  // Access elements
  acc = 0;
  for (var i = 0; i < COUNT; i++) {
    acc += list2[i];
  }
  // Access elements
  print('List2 dt: ${millis() - time}ms');
}

enum ValueType { NUMBER, STRING, BOOL }

class Value {
  ValueType type;
  double number;
  String string;
  bool bl;

  Value({this.number, this.string, this.bl}) {
    if (number != null) {
      type = ValueType.NUMBER;
    } else if (string != null) {
      type = ValueType.STRING;
    }
  }
}

void typeTest() {
  // Run benchmark
  const COUNT = 10000000;

  final list = [];
  // Fill up list
  for (var k = 0; k < COUNT; k++) {
    list.add(k % 2 == 0 ? 1.2 : 'test');
  }
  var time = millis();
  // Access elements
  var acc = 0;
  for (var i = 0; i < COUNT; i++) {
    final el = list[i];
    if (el is double) {
      acc += el.toInt();
    } else if (el is String) {
      acc += el.length;
    }
  }
  print('List dt: ${millis() - time}ms');

  final list2 = <Value>[];
  // Fill up list
  for (var k = 0; k < COUNT; k++) {
    list2.add(k % 2 == 0 ? Value(number: 1.2) : Value(string: 'test'));
  }
  time = millis();
  // Access elements
  acc = 0;
  for (var i = 0; i < COUNT; i++) {
    final el = list2[i];
    if (el.type == ValueType.NUMBER) {
      acc += el.number.toInt();
    } else if (el.type == ValueType.STRING) {
      acc += el.string.length;
    }
  }
  // Access elements
  print('List2 dt: ${millis() - time}ms');
}

class StrWrap {
  String str;

  StrWrap(this.str);
}

void stringTest() {
  // Run benchmark
  const COUNT = 10000000;

  final list = <String>[];
  // Fill up list
  for (var k = 0; k < COUNT; k++) {
    list.add('test');
  }
  var time = millis();
  // Access elements
  var acc = 0;
  for (var i = 0; i < COUNT; i++) {
    final el = list[i];
    acc += el.length;
  }
  print('List dt: ${millis() - time}ms');

  final list2 = <StrWrap>[];
  // Fill up list
  for (var k = 0; k < COUNT; k++) {
    list2.add(StrWrap('test'));
  }
  time = millis();
  // Access elements
  acc = 0;
  for (var i = 0; i < COUNT; i++) {
    final el = list2[i];
    acc += el.str.length;
    // if (el.type == ValueType.NUMBER) {
    //   // acc += el.number.toInt();
    // } else if (el.type == ValueType.STRING) {
    //   // acc += el.string.length;
    // }
  }
  // Access elements
  print('List2 dt: ${millis() - time}ms');
}
