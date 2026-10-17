import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class LoginUser {
  const LoginUser(this._repository);
  final AuthRepository _repository;

  Future<AppUser> call({required String email, required String password}) =>
      _repository.login(email: email.trim().toLowerCase(), password: password);
}
