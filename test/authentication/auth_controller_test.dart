import 'dart:async';

import 'package:encuentra_u/core/constants/app_strings.dart';
import 'package:encuentra_u/features/authentication/domain/entities/app_user.dart';
import 'package:encuentra_u/features/authentication/domain/exceptions/auth_exception.dart';
import 'package:encuentra_u/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';

void main() {
  late FakeAuthRepository repo;
  late AuthController controller;
  setUp(() {
    repo = FakeAuthRepository();
    controller = makeAuthController(repo);
  });
  tearDown(() => controller.dispose());

  test('login refleja loading y authenticated y bloquea dobles envíos',
      () async {
    final pending = Completer<AppUser>();
    repo.onLogin = () => pending.future;
    final statuses = <AuthStatus>[];
    controller.addListener(() => statuses.add(controller.status));
    expect(controller.status, AuthStatus.initial);
    final request = controller.login(
        email: ' TEST@EXAMPLE.COM ', password: ' $testPassword ');
    expect(controller.isLoggingIn, isTrue);
    expect(
        await controller.login(email: testUser.email, password: testPassword),
        isFalse);
    expect(repo.loginCalls, 1);
    pending.complete(testUser);
    expect(await request, isTrue);
    expect(statuses, [AuthStatus.loading, AuthStatus.authenticated]);
    expect(controller.currentUser, testUser);
    expect(repo.email, testUser.email);
    expect(repo.password, ' $testPassword ');
  });

  test('registro exitoso vuelve a unauthenticated sin autoiniciar sesión',
      () async {
    expect(
        await controller.register(
            fullName: ' Usuario   Prueba ',
            email: ' TEST@EXAMPLE.COM ',
            studentCode: ' test-001 ',
            password: testPassword),
        isTrue);
    expect(controller.status, AuthStatus.unauthenticated);
    expect(controller.currentUser, isNull);
    expect(repo.loginCalls, 0);
    expect(repo.fullName, 'Usuario Prueba');
    expect(repo.studentCode, 'TEST-001');
  });

  test('error usa AppStrings, deja sesión cerrada y puede limpiarse', () async {
    repo.onLogin =
        () async => throw const AuthException(AuthFailure.invalidCredentials);
    expect(
        await controller.login(email: testUser.email, password: testPassword),
        isFalse);
    expect(controller.status, AuthStatus.error);
    expect(controller.currentUser, isNull);
    expect(controller.errorMessage, AppStrings.invalidCredentials);
    controller.clearError();
    expect(controller.errorMessage, isNull);
    expect(controller.status, AuthStatus.unauthenticated);
  });

  test('restauración abre sesión con usuario válido', () async {
    repo.onRestore = () async => testUser;
    await controller.restoreSession();
    expect(controller.status, AuthStatus.authenticated);
    expect(controller.currentUser, testUser);
  });

  test('restauración sin token deja sesión cerrada', () async {
    await controller.restoreSession();
    expect(controller.status, AuthStatus.unauthenticated);
    expect(controller.isAuthenticated, isFalse);
  });

  test('logout limpia estado incluso si almacenamiento falla', () async {
    await controller.login(email: testUser.email, password: testPassword);
    repo.onLogout = () async => throw const AuthException(AuthFailure.storage);
    await controller.logout();
    expect(repo.logoutCalls, 1);
    expect(controller.status, AuthStatus.unauthenticated);
    expect(controller.currentUser, isNull);
    expect(controller.errorMessage, AppStrings.secureStorageError);
  });
}
