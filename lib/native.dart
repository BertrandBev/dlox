class NativeError {
  String format;
  List<Object> args;

  NativeError(this.format, [this.args]);
}

enum ArgType { Bool, Number, String, List, Map, Object }

final ARG_STR = {
  ArgType.Bool: 'Bool',
  ArgType.Number: 'Number',
  ArgType.String: 'String',
  ArgType.List: 'List',
  ArgType.Map: 'Map',
  ArgType.Object: 'Object'
};

ArgType valueType(Object object) {
  if (object is bool) {
    return ArgType.Bool;
  } else if (object is double) {
    return ArgType.Number;
  } else if (object is String) {
    return ArgType.String;
  } else if (object is List) {
    return ArgType.List;
  } else if (object is Map) {
    return ArgType.Map;
  }
  return ArgType.Object;
}

void argCountError(int expected, int received) {
  throw NativeError('Expected %d arguments, but got %d', [expected, received]);
}

void argTypeError(int index, ArgType expected, ArgType received) {
  throw NativeError(
      'Invalid argument %d type, expected <%s>, but received <%s>',
      [index + 1, ARG_STR[expected], ARG_STR[received]]);
}

// Native functions

double clockNative(List<Object> stack, int argIdx, int argCount) {
  if (argCount != 0) argCountError(0, argCount);
  return DateTime.now().millisecondsSinceEpoch.toDouble();
}

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
  if (argCount != 2) argCountError(2, argCount);
  final arg_0 = stack[argIdx];
  if (!(arg_0 is double)) argTypeError(0, ArgType.Number, valueType(arg_0));
  final arg_1 = stack[argIdx + 1];
  final idx = (arg_0 as double).toInt();
  if (idx < 0 || idx > list.length) {
    throw NativeError('Index %d out of bounds [0, %d]', [idx, list.length]);
  }
  list.insert(idx, arg_1);
}

Object listRemove(List list, List<Object> stack, int argIdx, int argCount) {
  if (argCount != 1) argCountError(1, argCount);
  final arg_0 = stack[argIdx];
  if (!(arg_0 is double)) argTypeError(0, ArgType.Number, valueType(arg_0));
  final idx = (arg_0 as double).toInt();
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
