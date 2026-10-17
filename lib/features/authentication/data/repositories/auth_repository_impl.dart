import '../../domain/entities/app_user.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/token_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote, this._tokens);
  final AuthRemoteDataSource _remote;
  final TokenStorage _tokens;

  @override
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String studentCode,
    required String password,
  }) =>
      _parse(() => _remote.register(
            fullName: fullName,
            email: email,
            studentCode: studentCode,
            password: password,
          ));

  @override
  Future<AppUser> login(
      {required String email, required String password}) async {
    final session =
        await _parse(() => _remote.login(email: email, password: password));
    if (!session.user.isActive)
      throw const AuthException(AuthFailure.inactiveAccount);
    final user =
        await _parse(() => _remote.getCurrentUser(session.accessToken));
    if (!user.isActive) throw const AuthException(AuthFailure.inactiveAccount);
    try {
      await _tokens.writeToken(session.accessToken);
    } catch (_) {
      // A failed write may have partially persisted the token.
      await _deleteToken();
      throw const AuthException(AuthFailure.storage);
    }
    return user;
  }

  @override
  Future<AppUser?> restoreSession() async {
    final String? token;
    try {
      token = await _tokens.readToken();
    } catch (_) {
      throw const AuthException(AuthFailure.storage);
    }
    if (token == null) return null;
    if (token.trim().isEmpty) {
      await _deleteToken();
      return null;
    }
    try {
      final user = await _parse(() => _remote.getCurrentUser(token!));
      if (!user.isActive)
        throw const AuthException(AuthFailure.inactiveAccount);
      return user;
    } on AuthException catch (error) {
      if (error.failure == AuthFailure.sessionExpired ||
          error.failure == AuthFailure.inactiveAccount) {
        await _deleteToken();
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() => _deleteToken();

  Future<void> _deleteToken() async {
    try {
      await _tokens.deleteToken();
    } catch (_) {
      // Retry a transient plugin error; never silently claim successful deletion.
      try {
        await _tokens.deleteToken();
      } catch (_) {
        throw const AuthException(AuthFailure.storage);
      }
    }
  }

  Future<T> _parse<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FormatException {
      throw const AuthException(AuthFailure.invalidResponse);
    }
  }
}
