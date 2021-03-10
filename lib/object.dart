import 'dart:math';

import 'package:dlox/chunk.dart';
import 'package:dlox/error.dart';
import 'package:dlox/scanner.dart';
import 'package:dlox/table.dart';
import 'package:dlox/value.dart';

import 'native.dart';
import 'native_classes.dart';

class Tracer {
  // Map of global tokens
  final Map<String, Token> _globalRoots = {};
  final Map<Token, Token> _localRoots = {};
  // Map from root variables to token sets
  final Map<String, Set<Token>> _globalSets = {};
  final Map<Token, Set<Token>> _localSets = {};
  final Map<Token, Set<Token>> _variableSets = {}; // Union of the two previous
  // Function map
  final Map<String, int> _nativeArityMap = {};
  final Map<Token, int> _functionArityMap = {};
  final Map<Token, int> _functionCallMap = {};
  // Scope map
  final List<int> _lineScopeDepth = [];

  Tracer() {
    // Build native function arity map
    NATIVE_FUNCTIONS.forEach((fun) {
      _nativeArityMap[fun.name] = fun.arity;
    });
  }

  // Function called at least once per token
  void onToken(Token token, int scopeDepth) {
    int line = token.loc.i;
    // final prevScope = _lineScopeDepth.isEmpty ? 0 : _lineScopeDepth.last;
    while (_lineScopeDepth.length < line) {
      _lineScopeDepth.add(scopeDepth);
    }
    if (_lineScopeDepth.length == line) _lineScopeDepth.add(scopeDepth);
  }

  void linkLocal(Token rootVariable, Token variable) {
    if (!_localSets.containsKey(rootVariable)) _localSets[rootVariable] = {};
    _localSets[rootVariable].add(variable);
    _localRoots[variable] = rootVariable;
  }

  void linkGlobal(String rootName, Token variable) {
    if (!_globalSets.containsKey(rootName)) _globalSets[rootName] = {};
    _globalSets[rootName].add(variable);
  }

  void defineVariable(Token variable, bool isLocal) {
    if (isLocal) {
      linkLocal(variable, variable);
    } else {
      linkGlobal(variable.str, variable);
    }
    if (!isLocal) _globalRoots[variable.str] = variable;
  }

  void functionCall(Token name, int argCount) {
    _functionCallMap[name] = argCount;
  }

  void defineFunction(Token name, int argCount) {
    _functionArityMap[name] = argCount;
  }

  // Control linking & populate functions
  List<CompilerError> finalize(bool throwError) {
    final errors = <CompilerError>[];
    // Build variable set map
    _globalSets.forEach((key, varSet) {
      if (!_globalRoots.containsKey(key) && !_nativeArityMap.containsKey(key)) {
        varSet.forEach((child) {
          if (throwError) {
            errors.add(CompilerError(child, 'Undefined variable'));
          }
        });
      } else {
        _variableSets[_globalRoots[key]] = varSet;
      }
    });
    _variableSets.addAll(_localSets);
    // Analyse functions
    _functionCallMap.forEach((key, value) {
      final root = getVariableRoot(key);
      var expected;
      if (_functionArityMap.containsKey(root)) {
        expected = _functionArityMap[root];
      } else if (_globalSets.containsKey(key.str) &&
          _nativeArityMap.containsKey(key.str)) {
        expected = _nativeArityMap[key.str];
      }
      if (expected != null && value != expected) {
        errors.add(CompilerError(key, 'Expected $expected arguments'));
      }
    });
    return errors;
  }

  // API
  bool isLocal(Token token) {
    return _localSets.containsKey(token);
  }

  bool isGlobal(Token token) {
    return _globalSets.containsKey(token);
  }

  bool isFunction(Token token) {
    return _functionCallMap.containsKey(token) ||
        _functionArityMap.containsKey(token) ||
        _nativeArityMap.containsKey(token?.str);
  }

  Token globalToken(String name) {
    return _globalRoots[name];
  }

  Token getVariableRoot(Token token) {
    if (_localRoots.containsKey(token)) return _localRoots[token];
    return _globalRoots[token.str];
  }

  // Set<Token> getVariableSet(Token token) {
  //   final root = getVariableRoot(token);
  //   return _variableSets[root];
  // }

  Set<Token> getRootVariables() {
    return _variableSets.keys.toSet();
  }

  Set<Token> getRootsInScope(int line) {
    if (line >= _lineScopeDepth.length || line < 0) return <Token>{};
    final validLines = <int>{};
    var scopeDepth = _lineScopeDepth[line];
    while (--line >= 0) {
      final currDepth = _lineScopeDepth[line];
      scopeDepth = min(scopeDepth, currDepth);
      if (scopeDepth >= currDepth) validLines.add(line);
    }
    final rootSet = _localRoots.keys
        .where((token) => validLines.contains(token.loc.i))
        .toSet();
    rootSet.addAll(_globalRoots.values);
    return rootSet;
  }

  Set<String> getNativeFunctions() {
    return _nativeArityMap.keys.toSet();
  }
}

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
