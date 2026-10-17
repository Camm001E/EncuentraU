import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:encuentra_u/core/constants/api_constants.dart';
import 'package:encuentra_u/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:encuentra_u/features/authentication/data/models/app_user_model.dart';
import 'package:encuentra_u/features/authentication/data/models/auth_session_model.dart';
import 'package:encuentra_u/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:encuentra_u/features/authentication/domain/entities/app_user.dart';
import 'package:encuentra_u/features/authentication/domain/exceptions/auth_exception.dart';
import 'package:encuentra_u/features/authentication/domain/usecases/register_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'auth_test_support.dart';

Matcher failure(AuthFailure value) =>
    isA<AuthException>().having((error) => error.failure, 'failure', value);

AuthRepositoryImpl repository(
  Future<http.Response> Function(http.Request) handler,
  MemoryTokenStorage storage,
) {
  final client = MockClient(handler);
  addTearDown(client.close);
  return AuthRepositoryImpl(AuthRemoteDataSource(client: client), storage);
}

void main() {
  test('parsea snake_case y conserva UUID, rol tipado y estado', () {
    final user = AppUserModel.fromJson(userJson);
    expect(user.id, testUser.id);
    expect(user.fullName, testUser.fullName);
    expect(user.studentCode, testUser.studentCode);
    expect(user.role, UserRole.student);
    expect(user.isActive, isTrue);
    final admin = AppUserModel.fromJson(
        {...userJson, 'role': 'admin', 'is_active': false});
    expect(admin.role, UserRole.admin);
    expect(admin.isActive, isFalse);
    expect(() => AppUserModel.fromJson({...userJson, 'role': 'superadmin'}),
        throwsFormatException);
  });

  test('parsea respuesta de login y rechaza contratos incompletos', () {
    final session = AuthSessionModel.fromJson(sessionJson);
    expect(session.accessToken, testToken);
    expect(session.user.email, testUser.email);
    for (final changes in [
      {'access_token': ''},
      {'token_type': 'basic'},
      {'expires_in': 0},
      {'user': null},
    ]) {
      expect(() => AuthSessionModel.fromJson({...sessionJson, ...changes}),
          throwsFormatException);
    }
  });

  test(
      'registro envía solo el JSON permitido y normaliza sin alterar contraseña',
      () async {
    final storage = MemoryTokenStorage();
    final repo = repository((request) async {
      expect(request.method, 'POST');
      expect(request.url, ApiConstants.authRegisterUri);
      expect(request.headers['content-type'], contains('application/json'));
      expect(jsonDecode(request.body), {
        'full_name': 'Usuario Prueba',
        'email': 'test@example.com',
        'student_code': 'TEST-001',
        'password': ' $testPassword ',
      });
      return http.Response(jsonEncode(userJson), 201);
    }, storage);
    await RegisterUser(repo)(
        fullName: ' Usuario   Prueba ',
        email: ' TEST@EXAMPLE.COM ',
        studentCode: ' test-001 ',
        password: ' $testPassword ');
    expect(storage.writes, 0);
    expect(storage.token, isNull);
  });

  test('login envía JSON y guarda únicamente el token después de un 200',
      () async {
    final storage = MemoryTokenStorage();
    final repo = repository((request) async {
      if (request.method == 'GET') {
        expect(request.url, ApiConstants.authMeUri);
        expect(request.headers['authorization'], 'Bearer $testToken');
        expect(storage.writes, 0);
        return http.Response(jsonEncode(userJson), 200);
      }
      expect(request.url, ApiConstants.authLoginUri);
      expect(request.method, 'POST');
      expect(jsonDecode(request.body),
          {'email': testUser.email, 'password': testPassword});
      return http.Response(jsonEncode(sessionJson), 200);
    }, storage);
    final user =
        await repo.login(email: testUser.email, password: testPassword);
    expect(user.id, testUser.id);
    expect(storage.writes, 1);
    expect(storage.token, testToken);
  });

  test('login fallido no escribe un token', () async {
    final storage = MemoryTokenStorage();
    final repo = repository(
        (_) async => http.Response('private internal error', 401), storage);
    await expectLater(repo.login(email: testUser.email, password: testPassword),
        throwsA(failure(AuthFailure.invalidCredentials)));
    expect(storage.writes, 0);
    expect(storage.token, isNull);
  });

  test(
      '/me envía Bearer, restaura y permite restaurar después de recrear repositorio',
      () async {
    final storage = MemoryTokenStorage(testToken);
    Future<http.Response> handler(http.Request request) async {
      expect(request.method, 'GET');
      expect(request.url, ApiConstants.authMeUri);
      expect(request.headers['authorization'], 'Bearer $testToken');
      return http.Response(jsonEncode(userJson), 200);
    }

    expect(
        (await repository(handler, storage).restoreSession())?.id, testUser.id);
    expect(
        (await repository(handler, storage).restoreSession())?.id, testUser.id);
    expect(storage.reads, 2);
  });

  test('sin token no consulta el servidor', () async {
    final repo = repository((_) async => throw StateError('unexpected request'),
        MemoryTokenStorage());
    expect(await repo.restoreSession(), isNull);
  });

  for (final status in [401, 403]) {
    test('restauración HTTP $status elimina el token rechazado', () async {
      final storage = MemoryTokenStorage(testToken);
      final repo = repository((_) async => http.Response('', status), storage);
      await expectLater(
          repo.restoreSession(),
          throwsA(failure(status == 401
              ? AuthFailure.sessionExpired
              : AuthFailure.inactiveAccount)));
      expect(storage.token, isNull);
      expect(storage.deletes, 1);
    });
  }

  test('fallo temporal al restaurar conserva el token para reintentar',
      () async {
    final storage = MemoryTokenStorage(testToken);
    final repo = repository(
        (_) async => http.Response('<html>internal details</html>', 503),
        storage);
    await expectLater(
        repo.restoreSession(), throwsA(failure(AuthFailure.server)));
    expect(storage.token, testToken);
    expect(storage.deletes, 0);
  });

  for (final entry in {
    401: AuthFailure.invalidCredentials,
    403: AuthFailure.inactiveAccount,
    409: AuthFailure.duplicateAccount,
    422: AuthFailure.invalidData,
    500: AuthFailure.server,
    503: AuthFailure.server,
    599: AuthFailure.server,
  }.entries) {
    test('HTTP ${entry.key} produce un error de dominio sin exponer cuerpo',
        () async {
      final repo = repository(
          (_) async => http.Response(
              '<html>private technical details</html>', entry.key),
          MemoryTokenStorage());
      await expectLater(
          repo.login(email: testUser.email, password: testPassword),
          throwsA(failure(entry.value)));
    });
  }

  for (final error in [
    TimeoutException('test timeout'),
    http.ClientException('test failure'),
    const SocketException('test socket failure'),
  ]) {
    test('${error.runtimeType} se convierte en error de conexión', () async {
      final repo = repository((_) async => throw error, MemoryTokenStorage());
      await expectLater(
          repo.login(email: testUser.email, password: testPassword),
          throwsA(failure(AuthFailure.connection)));
    });
  }

  for (final body in [
    '<html>bad</html>',
    '[]',
    '{}',
    '{"access_token":"test-only"}'
  ]) {
    test('respuesta inválida no se acepta como sesión: $body', () async {
      final storage = MemoryTokenStorage();
      final repo = repository((_) async => http.Response(body, 200), storage);
      await expectLater(
          repo.login(email: testUser.email, password: testPassword),
          throwsA(failure(AuthFailure.invalidResponse)));
      expect(storage.writes, 0);
    });
  }

  test('logout elimina token sin hacer ninguna petición HTTP', () async {
    final storage = MemoryTokenStorage(testToken);
    final repo = repository(
        (_) async => throw StateError('unexpected request'), storage);
    await repo.logout();
    expect(storage.token, isNull);
    expect(storage.deletes, 1);
  });

  test('logout reintenta y elimina token después de un fallo transitorio',
      () async {
    final storage = MemoryTokenStorage(testToken)..deleteFailures = 1;
    await repository(
            (_) async => throw StateError('unexpected request'), storage)
        .logout();
    expect(storage.token, isNull);
    expect(storage.deletes, 2);
  });

  test('fallo persistente de almacenamiento devuelve un error controlado',
      () async {
    final storage = MemoryTokenStorage(testToken)..deleteFailures = 2;
    final repo = repository(
        (_) async => throw StateError('unexpected request'), storage);
    await expectLater(repo.logout(), throwsA(failure(AuthFailure.storage)));
    expect(storage.deletes, 2);
  });

  test('si falla guardar token se limpia escritura parcial y no se abre sesión',
      () async {
    final storage = MemoryTokenStorage()..failWrite = true;
    final repo = repository(
        (request) async => http.Response(
            jsonEncode(request.method == 'POST' ? sessionJson : userJson), 200),
        storage);
    await expectLater(repo.login(email: testUser.email, password: testPassword),
        throwsA(failure(AuthFailure.storage)));
    expect(storage.token, isNull);
  });

  test('cuenta inactiva en respuesta 200 no se convierte en sesión', () async {
    final storage = MemoryTokenStorage();
    final repo = repository(
        (_) async => http.Response(
            jsonEncode({
              ...sessionJson,
              'user': {...userJson, 'is_active': false},
            }),
            200),
        storage);
    await expectLater(repo.login(email: testUser.email, password: testPassword),
        throwsA(failure(AuthFailure.inactiveAccount)));
    expect(storage.writes, 0);
  });
}
