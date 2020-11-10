import 'dart:io';

import 'package:dlox/chunk.dart';
import 'package:dlox/table.dart';
import 'package:dlox/value.dart';

typedef NativeFunction = Object Function(
    List<Object> stack, int argIdx, int argCount);

class ObjNative {
  String name;
  NativeFunction fn;

  ObjNative(this.name, this.fn);
}

class ObjFunction {
  int arity = 0;
  int upvalueCount = 0;
  Chunk chunk = Chunk();
  String name;

  ObjFunction();
}

class ObjUpvalue {
  int location;
  Object closed = Nil;
  ObjUpvalue next;

  ObjUpvalue(this.location);
}

class ObjClosure {
  ObjFunction function;
  List<ObjUpvalue> upvalues;
  int upvalueCount;

  ObjClosure(this.function) {
    upvalues = List<ObjUpvalue>(function.upvalueCount);
    upvalueCount = function.upvalueCount;
  }
}

class ObjClass {
  String name;
  Table methods = Table();

  ObjClass(this.name);
}

class ObjInstance {
  ObjClass klass;
  Table fields = Table();

  ObjInstance(this.klass);
}

class ObjBoundMethod {
  Object receiver;
  ObjClosure method;

  ObjBoundMethod(this.receiver, this.method);
}

int hashString(String key) {
  var hash = 2166136261;
  for (var i = 0; i < key.length; i++) {
    hash ^= key.codeUnitAt(i);
    hash *= 16777619;
  }
  return hash;
}

void printFunction(ObjFunction function) {
  if (function.name == null) {
    stdout.write('<script>');
    return;
  }
  stdout.write('<fn ${function.name}>');
}

void printObject(Object value) {
  if (value is ObjClass) {
    stdout.write(value.name);
  } else if (value is ObjBoundMethod) {
    printFunction(value.method.function);
  } else if (value is ObjClosure) {
    printFunction(value.function);
  } else if (value is ObjFunction) {
    printFunction(value);
  } else if (value is ObjInstance) {
    stdout.write('${value.klass.name} instance');
  } else if (value is ObjNative) {
    stdout.write('<native fn>');
  } else if (value is String) {
    stdout.write(value);
  } else if (value is ObjUpvalue) {
    stdout.write('upvalue');
  } else {
    stderr.writeln('Unsupported object type: $value');
  }
}
