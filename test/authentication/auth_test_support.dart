import 'package:encuentra_u/features/authentication/data/datasources/token_storage.dart';
import 'package:encuentra_u/features/authentication/domain/entities/app_user.dart';
import 'package:encuentra_u/features/authentication/domain/repositories/auth_repository.dart';
import 'package:encuentra_u/features/authentication/domain/usecases/login_user.dart';
import 'package:encuentra_u/features/authentication/domain/usecases/logout_user.dart';
import 'package:encuentra_u/features/authentication/domain/usecases/register_user.dart';
import 'package:encuentra_u/features/authentication/domain/usecases/restore_session.dart';
import 'package:encuentra_u/features/authentication/presentation/controllers/auth_controller.dart';

const testToken = 'not-a-real-token-test-only';
const testPassword = 'test-password-123';
const userJson = {
  'id': '11111111-1111-4111-8111-111111111111',
  'full_name': 'Usuario Prueba',
  'email': 'test@example.com',
  'student_code': 'TEST-001',
  'role': 'student',
  'is_active': true,
};
const sessionJson = {
  'access_token': testToken,
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': userJson,
};
const testUser = AppUser(
  id: '11111111-1111-4111-8111-111111111111',
  fullName: 'Usuario Prueba',
  email: 'test@example.com',
  studentCode: 'TEST-001',
  role: UserRole.student,
  isActive: true,
);

class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage([this.token]);
  String? token;
  int writes = 0;
  int reads = 0;
  int deletes = 0;
  int deleteFailures = 0;
  bool failWrite = false;
  bool failRead = false;

  @override
  Future<String?> readToken() async {
    reads++;
    if (failRead) throw StateError('test storage failure');
    return token;
  }

  @override
  Future<void> writeToken(String value) async {
    writes++;
    token = value;
    if (failWrite) throw StateError('test storage failure');
  }

  @override
  Future<void> deleteToken() async {
    deletes++;
    if (deleteFailures > 0) {
      deleteFailures--;
      throw StateError('test storage failure');
    }
    token = null;
  }
}

class FakeAuthRepository implements AuthRepository {
  Future<AppUser> Function()? onLogin;
  Future<AppUser?> Function()? onRestore;
  Future<void> Function()? onLogout;
  int loginCalls = 0;
  int registerCalls = 0;
  int logoutCalls = 0;
  String? email;
  String? studentCode;
  String? fullName;
  String? password;

  @override
  Future<AppUser> register(
      {required String fullName,
      required String email,
      required String studentCode,
      required String password}) async {
    registerCalls++;
    this.fullName = fullName;
    this.email = email;
    this.studentCode = studentCode;
    this.password = password;
    return testUser;
  }

  @override
  Future<AppUser> login(
      {required String email, required String password}) async {
    loginCalls++;
    this.email = email;
    this.password = password;
    return onLogin != null ? await onLogin!() : testUser;
  }

  @override
  Future<AppUser?> restoreSession() async =>
      onRestore != null ? await onRestore!() : null;

  @override
  Future<void> logout() async {
    logoutCalls++;
    await onLogout?.call();
  }
}

AuthController makeAuthController(AuthRepository repository) => AuthController(
      registerUser: RegisterUser(repository),
      loginUser: LoginUser(repository),
      restoreSession: RestoreSession(repository),
      logoutUser: LogoutUser(repository),
    );
