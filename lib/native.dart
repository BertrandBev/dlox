import 'dart:math';

import 'package:dlox/object.dart';

class NativeError {
  String format;
  List<Object> args;

  NativeError(this.format, [this.args]);
}

String typeToString(Type type) {
  if (type == double) return 'Number';
  return type.toString();
}

void argCountError(int expected, int received) {
  throw NativeError('Expected %d arguments, but got %d', [expected, received]);
}

void argTypeError(int index, Type expected, Type received) {
  throw NativeError(
      'Invalid argument %d type, expected <%s>, but received <%s>',
      [index + 1, typeToString(expected), typeToString(received)]);
}

void assertTypes(
    List<Object> stack, int argIdx, int argCount, List<Type> types) {
  if (argCount != types.length) argCountError(types.length, argCount);
  for (var k = 0; k < types.length; k++) {
    if (types[k] != Object && stack[argIdx + k].runtimeType != types[k]) {
      argTypeError(0, double, stack[argIdx + k]);
    }
  }
}

double assert1double(List<Object> stack, int argIdx, int argCount) {
  assertTypes(stack, argIdx, argCount, <Type>[double]);
  return stack[argIdx] as double;
}

void assert2doubles(List<Object> stack, int argIdx, int argCount) {
  assertTypes(stack, argIdx, argCount, <Type>[double, double]);
}

// Native functions
typedef NativeFunction = Object Function(
    List<Object> stack, int argIdx, int argCount);

double clockNative(List<Object> stack, int argIdx, int argCount) {
  if (argCount != 0) argCountError(0, argCount);
  return DateTime.now().millisecondsSinceEpoch.toDouble();
}

double minNative(List<Object> stack, int argIdx, int argCount) {
  assert2doubles(stack, argIdx, argCount);
  return min(stack[argIdx], stack[argIdx + 1]);
}

double maxNative(List<Object> stack, int argIdx, int argCount) {
  assert2doubles(stack, argIdx, argCount);
  return max(stack[argIdx], stack[argIdx + 1]);
}

double floorNative(List<Object> stack, int argIdx, int argCount) {
  final arg_0 = assert1double(stack, argIdx, argCount);
  return arg_0.floorToDouble();
}

double ceilNative(List<Object> stack, int argIdx, int argCount) {
  final arg_0 = assert1double(stack, argIdx, argCount);
  return arg_0.ceilToDouble();
}

double absNative(List<Object> stack, int argIdx, int argCount) {
  final arg_0 = assert1double(stack, argIdx, argCount);
  return arg_0.abs();
}

double roundNative(List<Object> stack, int argIdx, int argCount) {
  final arg_0 = assert1double(stack, argIdx, argCount);
  return arg_0.roundToDouble();
}

double sqrtNative(List<Object> stack, int argIdx, int argCount) {
  final arg_0 = assert1double(stack, argIdx, argCount);
  return sqrt(arg_0);
}

double signNative(List<Object> stack, int argIdx, int argCount) {
  final arg_0 = assert1double(stack, argIdx, argCount);
  return arg_0.sign;
}

double expNative(List<Object> stack, int argIdx, int argCount) {
  final arg_0 = assert1double(stack, argIdx, argCount);
  return exp(arg_0);
}

double logNative(List<Object> stack, int argIdx, int argCount) {
  final arg_0 = assert1double(stack, argIdx, argCount);
  return log(arg_0);
}

double sinNative(List<Object> stack, int argIdx, int argCount) {
  final arg_0 = assert1double(stack, argIdx, argCount);
  return sin(arg_0);
}

double asinNative(List<Object> stack, int argIdx, int argCount) {
  final arg_0 = assert1double(stack, argIdx, argCount);
  return asin(arg_0);
}

double cosNative(List<Object> stack, int argIdx, int argCount) {
  final arg_0 = assert1double(stack, argIdx, argCount);
  return cos(arg_0);
}

double acosNative(List<Object> stack, int argIdx, int argCount) {
  final arg_0 = assert1double(stack, argIdx, argCount);
  return acos(arg_0);
}

double tanNative(List<Object> stack, int argIdx, int argCount) {
  final arg_0 = assert1double(stack, argIdx, argCount);
  return tan(arg_0);
}

double atanNative(List<Object> stack, int argIdx, int argCount) {
  final arg_0 = assert1double(stack, argIdx, argCount);
  return atan(arg_0);
}

// ignore: non_constant_identifier_names
final NATIVE_FUNCTIONS = <ObjNative>[
  ObjNative('clock', 0, clockNative),
  ObjNative('min', 2, minNative),
  ObjNative('max', 2, maxNative),
  ObjNative('floor', 1, floorNative),
  ObjNative('ceil', 1, ceilNative),
  ObjNative('abs', 1, absNative),
  ObjNative('round', 1, roundNative),
  ObjNative('sqrt', 1, sqrtNative),
  ObjNative('sign', 1, signNative),
  ObjNative('exp', 1, expNative),
  ObjNative('log', 1, logNative),
  ObjNative('sin', 1, sinNative),
  ObjNative('asin', 1, asinNative),
  ObjNative('cos', 1, cosNative),
  ObjNative('acos', 1, acosNative),
  ObjNative('tan', 1, tanNative),
  ObjNative('atan', 1, atanNative),
];

const NATIVE_VALUES = <String, Object>{
  'π': pi,
  '𝘦': e,
  '∞': double.infinity,
};

// List native functions
double listLength(List list, List<Object> stack, int argIdx, int argCount) {
  if (argCount != 0) argCountError(0, argCount);
  return list.length.toDouble();
}

void listAdd(List list, List<Object> stack, int argIdx, int argCount) {
  if (argCount != 1) argCountError(1, argCount);
  final arg_0 = stack[argIdx];
  list.add(arg_0);
}

void listInsert(List list, List<Object> stack, int argIdx, int argCount) {
  assertTypes(stack, argIdx, argCount, [double, Object]);
  final idx = (stack[argIdx] as double).toInt();
  if (idx < 0 || idx > list.length) {
    throw NativeError('Index %d out of bounds [0, %d]', [idx, list.length]);
  }
  list.insert(idx, stack[argIdx + 1]);
}

Object listRemove(List list, List<Object> stack, int argIdx, int argCount) {
  assertTypes(stack, argIdx, argCount, [double]);
  final idx = (stack[argIdx] as double).toInt();
  if (idx < 0 || idx > list.length) {
    throw NativeError('Index %d out of bounds [0, %d]', [idx, list.length]);
  }
  return list.removeAt(idx);
}

Object listPop(List list, List<Object> stack, int argIdx, int argCount) {
  if (argCount != 0) argCountError(0, argCount);
  return list.removeLast();
}

void listClear(List list, List<Object> stack, int argIdx, int argCount) {
  if (argCount != 0) argCountError(0, argCount);
  list.clear();
}

typedef ListNativeFunction = Object Function(
    List list, List<Object> stack, int argIdx, int argCount);

const LIST_NATIVE_FUNCTIONS = <String, ListNativeFunction>{
  'length': listLength,
  'add': listAdd,
  'insert': listInsert,
  'remove': listRemove,
  'pop': listPop,
  'clear': listClear,
};

// Map native functions
double mapLength(Map map, List<Object> stack, int argIdx, int argCount) {
  if (argCount != 0) argCountError(0, argCount);
  return map.length.toDouble();
}

List mapKeys(Map map, List<Object> stack, int argIdx, int argCount) {
  if (argCount != 0) argCountError(0, argCount);
  return map.keys.toList();
}

List mapValues(Map map, List<Object> stack, int argIdx, int argCount) {
  if (argCount != 0) argCountError(0, argCount);
  return map.values.toList();
}

bool mapHas(Map map, List<Object> stack, int argIdx, int argCount) {
  if (argCount != 1) argCountError(1, argCount);
  final arg_0 = stack[argIdx];
  return map.containsKey(arg_0);
}

typedef MapNativeFunction = Object Function(
    Map list, List<Object> stack, int argIdx, int argCount);

const MAP_NATIVE_FUNCTIONS = <String, MapNativeFunction>{
  'length': mapLength,
  'keys': mapKeys,
  'values': mapValues,
  'has': mapHas,
};

// String native functions
double strLength(String str, List<Object> stack, int argIdx, int argCount) {
  if (argCount != 0) argCountError(0, argCount);
  return str.length.toDouble();
}

typedef StringNativeFunction = Object Function(
    String list, List<Object> stack, int argIdx, int argCount);

const STRING_NATIVE_FUNCTIONS = <String, StringNativeFunction>{
  'length': strLength,
};
