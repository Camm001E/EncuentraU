import 'dart:collection';
import 'dart:typed_data';
import '../constants/api_constants.dart';

class ImageByteCache {
  ImageByteCache(
      {this.maxBytes = ApiConstants.imageCacheMaxBytes,
      this.maxEntries = ApiConstants.imageCacheMaxEntries});
  final int maxBytes, maxEntries;
  final _entries = LinkedHashMap<String, Uint8List>();
  int _bytes = 0;
  int get bytes => _bytes;
  int get length => _entries.length;
  Uint8List? get(String key) {
    final value = _entries.remove(key);
    if (value != null) _entries[key] = value;
    return value;
  }

  void put(String key, Uint8List value) {
    final old = _entries.remove(key);
    if (old != null) _bytes -= old.length;
    if (value.length > maxBytes || maxEntries <= 0) return;
    final owned = Uint8List.fromList(value).asUnmodifiableView();
    _entries[key] = owned;
    _bytes += owned.length;
    while (_bytes > maxBytes || _entries.length > maxEntries) {
      _bytes -= _entries.remove(_entries.keys.first)!.length;
    }
  }

  void removeReport(String id) {
    for (final key
        in _entries.keys.where((k) => k.startsWith('$id:')).toList()) {
      _bytes -= _entries.remove(key)!.length;
    }
  }

  void clear() {
    _entries.clear();
    _bytes = 0;
  }
}
