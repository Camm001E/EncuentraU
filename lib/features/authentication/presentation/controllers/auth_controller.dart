import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/logout_user.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/usecases/restore_session.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

enum AuthOperation { register, login, restore, logout }

class AuthController extends ChangeNotifier {
  AuthController({
    required RegisterUser registerUser,
    required LoginUser loginUser,
    required RestoreSession restoreSession,
    required LogoutUser logoutUser,
  })  : _registerUser = registerUser,
        _loginUser = loginUser,
        _restoreSession = restoreSession,
        _logoutUser = logoutUser;

  final RegisterUser _registerUser;
  final LoginUser _loginUser;
  final RestoreSession _restoreSession;
  final LogoutUser _logoutUser;
  AuthStatus _status = AuthStatus.initial;
  AuthOperation? _operation;
  AppUser? _currentUser;
  String? _errorMessage;
  bool _disposed = false;
  int _generation = 0;

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isBusy => _status == AuthStatus.loading;
  bool get isRegistering => isBusy && _operation == AuthOperation.register;
  bool get isLoggingIn => isBusy && _operation == AuthOperation.login;

  Future<bool> register({
    required String fullName,
    required String email,
    required String studentCode,
    required String password,
  }) =>
      _run(AuthOperation.register, () async {
        await _registerUser(
            fullName: fullName,
            email: email,
            studentCode: studentCode,
            password: password);
        // Registration never opens a session.
        return null;
      });

  Future<bool> login({required String email, required String password}) => _run(
      AuthOperation.login, () => _loginUser(email: email, password: password));

  Future<void> restoreSession() async {
    await _run(AuthOperation.restore, _restoreSession.call);
  }

  Future<void> logout() async {
    if (isBusy) return;
    _generation++;
    _currentUser = null;
    _begin(AuthOperation.logout);
    try {
      await _logoutUser();
    } on AuthException catch (error) {
      _errorMessage = _message(error.failure);
    } catch (_) {
      _errorMessage = AppStrings.secureStorageError;
    } finally {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _operation = null;
      _notify();
    }
  }

  Future<bool> _run(
      AuthOperation operation, Future<AppUser?> Function() work) async {
    if (isBusy) return false;
    final generation = ++_generation;
    _currentUser = null;
    _begin(operation);
    try {
      final user = await work();
      if (_disposed || generation != _generation) return false;
      _currentUser = user;
      _status = isAuthenticated
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      return true;
    } on AuthException catch (error) {
      if (_disposed || generation != _generation) return false;
      _errorMessage = _message(error.failure);
      _status = AuthStatus.error;
      return false;
    } catch (_) {
      if (_disposed || generation != _generation) return false;
      _errorMessage = AppStrings.unexpectedError;
      _status = AuthStatus.error;
      return false;
    } finally {
      if (!_disposed && generation == _generation) {
        _operation = null;
        _notify();
      }
    }
  }

  void _begin(AuthOperation operation) {
    _operation = operation;
    _status = AuthStatus.loading;
    _errorMessage = null;
    _notify();
  }

  String _message(AuthFailure failure) => switch (failure) {
        AuthFailure.invalidCredentials => AppStrings.invalidCredentials,
        AuthFailure.sessionExpired => AppStrings.sessionExpired,
        AuthFailure.inactiveAccount => AppStrings.inactiveAccount,
        AuthFailure.duplicateAccount => AppStrings.accountAlreadyRegistered,
        AuthFailure.invalidData => AppStrings.invalidAuthData,
        AuthFailure.server => AppStrings.authServerError,
        AuthFailure.connection => AppStrings.authConnectionError,
        AuthFailure.invalidResponse => AppStrings.invalidAuthResponse,
        AuthFailure.storage => AppStrings.secureStorageError,
        AuthFailure.unexpected => AppStrings.unexpectedError,
      };

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    if (_status == AuthStatus.error) _status = AuthStatus.unauthenticated;
    _notify();
  }

  void expireSession({bool inactive = false}) {
    _generation++;
    _currentUser = null;
    _operation = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage =
        inactive ? AppStrings.inactiveAccount : AppStrings.sessionExpired;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _generation++;
    _disposed = true;
    super.dispose();
  }
}
