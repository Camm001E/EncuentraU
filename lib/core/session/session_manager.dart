import 'dart:async';

import '../errors/api_exception.dart';
import '../storage/token_storage.dart';

/// Serializes token operations so a delayed expiry cannot delete a new login.
class SessionManager implements TokenStorage {
  SessionManager(this._storage, {bool active = true}) : _active = active;
  final TokenStorage _storage;
  final _events = StreamController<ApiFailure>.broadcast(sync: true);
  Future<void> _tail = Future<void>.value();
  int _generation = 0;
  bool _active;

  int get generation => _generation;
  bool get active => _active;
  Stream<ApiFailure> get expired => _events.stream;

  void changeSession({required bool active}) {
    _generation++;
    _active = active;
  }

  Future<T> _enqueue<T>(Future<T> Function() work) {
    final result = _tail.then((_) => work());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  @override
  Future<String?> readToken() => _enqueue(_storage.readToken);
  @override
  Future<void> writeToken(String token) =>
      _enqueue(() => _storage.writeToken(token));
  @override
  Future<void> deleteToken() => _enqueue(_storage.deleteToken);

  Future<void> invalidate(int requestGeneration, ApiFailure reason) async {
    if (requestGeneration != _generation) return;
    final deletion = _enqueue(() async {
      try {
        await _storage.deleteToken();
      } catch (_) {
        await _storage.deleteToken();
      }
    });
    _generation++;
    _active = false;
    _events.add(reason);
    try {
      await deletion;
    } catch (_) {/* Session stays closed even if storage fails. */}
  }

  Future<void> dispose() => _events.close();
}
