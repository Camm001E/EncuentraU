import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_storage.dart';

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage(
      {FlutterSecureStorage storage = const FlutterSecureStorage()})
      : _storage = storage;
  static const _tokenKey = 'encuentrau_access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);
  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);
  @override
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}
