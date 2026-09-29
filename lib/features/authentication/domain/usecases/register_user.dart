import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class RegisterUser {
  const RegisterUser(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String fullName,
    required String email,
    required String studentCode,
    required String password,
  }) {
    return _repository.register(
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      studentCode: studentCode.trim(),
      password: password,
    );
  }
}
