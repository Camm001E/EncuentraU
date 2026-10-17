import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../domain/page.dart';
import 'api_message.dart';

enum LoadStatus { initial, loading, empty, ready, error }

abstract class PagedController<T> extends ChangeNotifier {
  List<T> _items = const [];
  int total = 0;
  int _nextOffset = 0;
  int _epoch = 0;
  int _request = 0;
  bool _disposed = false;
  LoadStatus status = LoadStatus.initial;
  String? message;
  bool isLoadingMore = false;
  List<T> get items => List<T>.unmodifiable(_items);
  bool get hasMore => _nextOffset < total;
  int get generation => _epoch;
  bool isCurrent(int epoch) => !_disposed && epoch == _epoch;
  String itemId(T item);
  Future<Page<T>> fetchPage(int limit, int offset);
  void notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> ensureLoaded() async {
    if (status == LoadStatus.initial) await refresh();
  }

  Future<void> refresh() => _load(append: false);
  Future<void> loadMore() => _load(append: true);
  Future<void> _load({required bool append}) async {
    if (append && (isLoadingMore || status == LoadStatus.loading || !hasMore))
      return;
    final epoch = _epoch;
    final request = ++_request;
    if (append) {
      isLoadingMore = true;
    } else {
      status = LoadStatus.loading;
      isLoadingMore = false;
      _items = const [];
      total = 0;
      _nextOffset = 0;
    }
    message = null;
    notify();
    try {
      final page = await fetchPage(
          ApiConstants.defaultPageSize, append ? _nextOffset : 0);
      if (!isCurrent(epoch) || request != _request) return;
      final combined = <String, T>{
        if (append)
          for (final item in _items) itemId(item): item,
        for (final item in page.items) itemId(item): item
      };
      _items = List<T>.unmodifiable(combined.values);
      total = page.total;
      _nextOffset =
          page.items.isEmpty ? total : page.offset + page.items.length;
      status = _items.isEmpty ? LoadStatus.empty : LoadStatus.ready;
    } catch (error) {
      if (!isCurrent(epoch) || request != _request) return;
      status = LoadStatus.error;
      message = apiMessage(error);
    } finally {
      if (isCurrent(epoch) && request == _request) {
        isLoadingMore = false;
        notify();
      }
    }
  }

  void clear() {
    _epoch++;
    _request++;
    _items = const [];
    total = 0;
    _nextOffset = 0;
    isLoadingMore = false;
    status = LoadStatus.initial;
    message = null;
    notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
