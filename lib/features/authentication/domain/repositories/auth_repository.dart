import '../entities/app_user.dart';

abstract interface class AuthRepository {
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String studentCode,
    required String password,
  });
}
