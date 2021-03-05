import 'dart:collection';

import 'package:dlox/native.dart';
import 'package:dlox/value.dart';

abstract class ObjNativeClass {
  final String name;
  final properties = <String, Object>{};
  final Map<String, Type> propertiesTypes;
  final List<String> initArgKeys;

  ObjNativeClass({
    this.name,
    this.propertiesTypes,
    this.initArgKeys,
    List<Object> stack,
    int argIdx,
    int argCount,
  }) {
    if (argCount != initArgKeys.length) {
      argCountError(initArgKeys.length, argCount);
    }
    for (var k = 0; k < initArgKeys.length; k++) {
      final expected = propertiesTypes[initArgKeys[k]];
      if (expected != Object && stack[argIdx + k].runtimeType != expected) {
        argTypeError(0, expected, stack[argIdx + k].runtimeType);
      }
      properties[initArgKeys[k]] = stack[argIdx + k];
    }
  }

  Object call(String key, List<Object> stack, int argIdx, int argCount) {
    throw NativeError('Undefined function $key');
  }

  void setVal(String key, Object value) {
    if (!propertiesTypes.containsKey(key)) {
      throw NativeError('Undefined property $key');
    }
    if (value.runtimeType != propertiesTypes[key]) {
      throw NativeError(
          'Invalid object type, expected <%s>, but received <%s>', [
        typeToString(propertiesTypes[key]),
        typeToString(value.runtimeType)
      ]);
    }
    properties[key] = value;
  }

  Object getVal(String key) {
    if (!properties.containsKey(key)) {
      throw NativeError('Undefined property $key');
    }
    return properties[key] ?? Nil;
  }

  String stringRepr({int maxChars = 100});
}

class ListNode extends ObjNativeClass {
  ListNode(List<Object> stack, int argIdx, int argCount)
      : super(
          name: 'ListNode',
          propertiesTypes: {'val': Object, 'next': ListNode},
          initArgKeys: ['val'],
          stack: stack,
          argIdx: argIdx,
          argCount: argCount,
        );

  Object get val => properties['val'];

  ListNode get next => properties['next'];

  List<ListNode> linkToList({int maxLength = 100}) {
    // ignore: prefer_collection_literals
    final visited = LinkedHashSet<ListNode>();
    var node = this;
    while (node != null &&
        !visited.contains(node) &&
        visited.length <= maxLength) {
      visited.add(node);
      node = node.next;
    }
    // Mark list as infinite
    if (node == this) visited.add(null);
    return visited.toList();
  }

  @override
  String stringRepr({int maxChars = 100}) {
    final str = StringBuffer('[');
    final list = linkToList(maxLength: maxChars ~/ 2);
    for (var k = 0; k < list.length; k++) {
      final val = list[k].val;
      if (k > 0) str.write(' → '); // TODO: find utf-16 arrow →; test on iOS
      str.write(val == null
          ? '⮐'
          : valueToString(val, maxChars: maxChars - str.length));
      if (str.length > maxChars) {
        str.write('...');
        break;
      }
    }
    str.write(']');
    return str.toString();
  }
}

typedef NativeClassCreator = ObjNativeClass Function(
    List<Object> stack, int argIdx, int argCount);

ListNode listNode(List<Object> stack, int argIdx, int argCount) {
  return ListNode(stack, argIdx, argCount);
}

const NATIVE_CLASSES = <String, NativeClassCreator>{
  'ListNode': listNode,
};
