import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/usecases/register_user.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._registerUser);

  final RegisterUser _registerUser;

  bool _isRegistering = false;
  String? _errorMessage;
  AppUser? _currentUser;

  bool get isRegistering => _isRegistering;
  String? get errorMessage => _errorMessage;
  AppUser? get currentUser => _currentUser;

  Future<bool> register({
    required String fullName,
    required String email,
    required String studentCode,
    required String password,
  }) async {
    _isRegistering = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _registerUser(
        fullName: fullName,
        email: email,
        studentCode: studentCode,
        password: password,
      );

      return true;
    } on EmailAlreadyRegisteredException {
      _errorMessage = AppStrings.emailAlreadyRegistered;
      return false;
    } on WeakPasswordException {
      _errorMessage = AppStrings.passwordMinLength;
      return false;
    } catch (_) {
      _errorMessage = AppStrings.unexpectedError;
      return false;
    } finally {
      _isRegistering = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }
}
