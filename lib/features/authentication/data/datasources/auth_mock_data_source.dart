import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_validation.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/exceptions/auth_exception.dart';

class AuthMockDataSource {
  final List<AppUser> _users = [];

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String studentCode,
    required String password,
  }) async {
    await Future<void>.delayed(AppDurations.mockRequest);

    final normalizedEmail = email.trim().toLowerCase();

    final emailAlreadyExists = _users.any(
      (user) => user.email.toLowerCase() == normalizedEmail,
    );

    if (emailAlreadyExists) {
      throw const EmailAlreadyRegisteredException();
    }

    if (password.length < AppValidation.minimumPasswordLength) {
      throw const WeakPasswordException();
    }

    final user = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: fullName.trim(),
      email: normalizedEmail,
      studentCode: studentCode.trim(),
    );

    _users.add(user);

    return user;
  }
}
