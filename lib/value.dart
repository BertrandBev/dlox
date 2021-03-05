import 'package:dlox/object.dart';
import 'package:sprintf/sprintf.dart';

class Nil {}

Object valueCloneDeep(Object value) {
  if (value is Map) {
    return Map.fromEntries(value.entries.map((e) => valueCloneDeep(e)));
  } else if (value is List) {
    return value.map((e) => valueCloneDeep(e)).toList();
  } else {
    // TODO: clone object instances
    return value;
  }
}

String listToString(List list, {int maxChars = 100}) {
  final buf = StringBuffer('[');
  for (var k = 0; k < list.length; k++) {
    if (k > 0) buf.write(',');
    buf.write(valueToString(list[k], maxChars: maxChars - buf.length));
    if (buf.length > maxChars) {
      buf.write('...');
      break;
    }
  }
  buf.write(']');
  return buf.toString();
}

String mapToString(Map map, {int maxChars = 100}) {
  final buf = StringBuffer('{');
  final entries = map.entries.toList();
  for (var k = 0; k < entries.length; k++) {
    if (k > 0) buf.write(',');
    buf.write(valueToString(entries[k].key, maxChars: maxChars - buf.length));
    buf.write(':');
    buf.write(valueToString(
      entries[k].value,
      maxChars: maxChars - buf.length,
    ));
    if (buf.length > maxChars) {
      buf.write('...');
      break;
    }
  }
  buf.write('}');
  return buf.toString();
}

String valueToString(Object value, {int maxChars = 100}) {
  if (value is bool) {
    return value ? 'true' : 'false';
  } else if (value == Nil) {
    return 'nil';
  } else if (value is double) {
    if (value.isInfinite) {
      return '∞';
    } else if (value.isNaN) return 'NaN';
    return sprintf('%g', [value]);
  } else if (value is String) {
    return value.trim().isEmpty ? '\'$value\'' : value;
  } else if (value is List) {
    return listToString(value, maxChars: maxChars);
  } else if (value is Map) {
    return mapToString(value, maxChars: maxChars);
  } else {
    return objectToString(value, maxChars: maxChars);
  }
}

// Copied from foundation.dart
bool listEquals<T>(List<T> a, List<T> b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  if (identical(a, b)) return true;
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) return false;
  }
  return true;
}

bool mapEquals<T, U>(Map<T, U> a, Map<T, U> b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  if (identical(a, b)) return true;
  for (final key in a.keys) {
    if (!b.containsKey(key) || b[key] != a[key]) return false;
  }
  return true;
}

bool valuesEqual(Object a, Object b) {
  // TODO: confirm behavior (especially for deep equality)
  // Equality relied on this function, but not hashmap indexing
  // It might trigger strange cases where two equal lists don't have the same hashcode
  if (a is List && b is List) {
    return listEquals(a, b);
  } else if (a is Map && b is Map) {
    return mapEquals(a, b);
  } else {
    return a == b;
  }
}
