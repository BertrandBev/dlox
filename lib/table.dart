class Table {
  final data = <String, Object>{};

  Object getVal(String key) {
    return data[key];
  }

  bool setVal(String key, Object val) {
    final hadKey = data.containsKey(key);
    data[key] = val;
    return !hadKey;
  }

  void delete(String key) {
    data.remove(key);
  }

  void addAll(Table other) {
    data.addAll(other.data);
  }

  Object findString(String str) {
    // TODO: key on hashKeys
    return data[str];
  }
}
