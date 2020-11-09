class Table {
  final data = <String, Object>{};

  Object getVal(String key) {
    return data[key];
  }

  void setVal(String key, Object val) {
    data[key] = val;
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
