import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_mock_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource);

  final AuthMockDataSource _dataSource;

  @override
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String studentCode,
    required String password,
  }) {
    return _dataSource.register(
      fullName: fullName,
      email: email,
      studentCode: studentCode,
      password: password,
    );
  }
}
