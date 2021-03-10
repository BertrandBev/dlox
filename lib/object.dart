
import 'package:dlox/chunk.dart';
import 'package:dlox/table.dart';
import 'package:dlox/value.dart';
import 'native.dart';
import 'native_classes.dart';

class ObjNative {
  String name;
  int arity;
  NativeFunction fn;

  ObjNative(this.name, this.arity, this.fn);
}

class ObjFunction {
  final Chunk chunk = Chunk();
  int arity = 0;
  int upvalueCount = 0;
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
  String klassName; // For dynamic class lookup
  ObjClass klass;
  Table fields = Table();

  ObjInstance({this.klass, this.klassName});
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

String functionToString(ObjFunction function) {
  if (function.name == null) {
    return '<script>';
  }
  return '<fn ${function.name}>';
}

void printObject(Object value) {
  print(objectToString(value));
}

String objectToString(Object value, {int maxChars = 100}) {
  if (value is ObjClass) {
    return value.name;
  } else if (value is ObjBoundMethod) {
    return functionToString(value.method.function);
  } else if (value is ObjClosure) {
    return functionToString(value.function);
  } else if (value is ObjFunction) {
    return functionToString(value);
  } else if (value is ObjInstance) {
    return '${value.klass.name} instance';
    // return instanceToString(value, maxChars: maxChars);
  } else if (value is ObjNative) {
    return '<native fn>';
  } else if (value is ObjUpvalue) {
    return 'upvalue';
  } else if (value is ObjNativeClass) {
    return value.stringRepr(maxChars: maxChars);
  } else if (value is NativeClassCreator) {
    return '<native class>';
  } 
  return value.toString();
}
