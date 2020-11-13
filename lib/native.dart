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

double clockNative(List<Object> stack, int argIdx, int argCount) {
  if (argCount != 0) argCountError(0, argCount);
  return DateTime.now().millisecondsSinceEpoch.toDouble();
}

typedef ListNativeFunction = Object Function(
    List list, List<Object> stack, int argIdx, int argCount);

class ListNative {
  static void add(List list, List<Object> stack, int argIdx, int argCount) {
    if (argCount != 1) argCountError(1, argCount);
    final arg_0 = stack[argIdx];
    list.add(arg_0);
  }

  static void insert(List list, List<Object> stack, int argIdx, int argCount) {
    if (argCount != 2) argCountError(2, argCount);
    final arg_0 = stack[argIdx];
    if (!(arg_0 is double)) argTypeError(0, ArgType.Number, valueType(arg_0));
    final arg_1 = stack[argIdx + 1];
    list.insert((arg_0 as double).toInt(), arg_1);
  }

  static Object remove(
      List list, List<Object> stack, int argIdx, int argCount) {
    if (argCount != 1) argCountError(1, argCount);
    final arg_0 = stack[argIdx];
    if (!(arg_0 is double)) argTypeError(0, ArgType.Number, valueType(arg_0));
    return list.removeAt((arg_0 as double).toInt());
  }

  static void clear(List list, List<Object> stack, int argIdx, int argCount) {
    if (argCount != 0) argCountError(0, argCount);
    list.clear();
  }
}

const LIST_NATIVE_FUNCTIONS = <String, ListNativeFunction>{
  'add': ListNative.add,
  'insert': ListNative.insert,
  'remove': ListNative.remove,
  'clear': ListNative.clear,
};
