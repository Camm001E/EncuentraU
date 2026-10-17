import 'dart:async';
import 'dart:io';
import 'package:encuentra_u/core/constants/api_constants.dart';
import 'package:encuentra_u/core/errors/api_exception.dart';
import 'package:encuentra_u/core/network/authenticated_api_client.dart';
import 'package:encuentra_u/core/session/session_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../authentication/auth_test_support.dart';

Matcher failure(ApiFailure failure) =>
    throwsA(isA<ApiException>().having((e) => e.failure, 'failure', failure));
void main() {
  for (final entry in {
    400: ApiFailure.invalidData,
    401: ApiFailure.unauthorized,
    403: ApiFailure.forbidden,
    404: ApiFailure.notFound,
    409: ApiFailure.conflict,
    422: ApiFailure.invalidData,
    500: ApiFailure.server,
    503: ApiFailure.server,
    599: ApiFailure.server
  }.entries) {
    test('HTTP ${entry.key} se mapea sin exponer el cuerpo', () async {
      final storage = MemoryTokenStorage(testToken);
      final session = SessionManager(storage);
      final events = <ApiFailure>[];
      session.expired.listen(events.add);
      final client = MockClient((_) async =>
          http.Response('<html>technical-detail-private</html>', entry.key));
      addTearDown(client.close);
      addTearDown(session.dispose);
      final api = AuthenticatedApiClient(client: client, session: session);
      await expectLater(
          api.request('GET', ApiConstants.myReportsPath), failure(entry.value));
      final closed = entry.key == 401 || entry.key == 403;
      expect(storage.token, closed ? null : testToken);
      expect(events, closed ? [entry.value] : isEmpty);
      expect(session.active, !closed);
    });
  }
  test('sin token no hace HTTP y comunica cierre de sesión', () async {
    final storage = MemoryTokenStorage();
    final session = SessionManager(storage);
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return http.Response('{}', 200);
    });
    addTearDown(client.close);
    addTearDown(session.dispose);
    await expectLater(
        AuthenticatedApiClient(client: client, session: session)
            .request('GET', ApiConstants.myMatchesPath),
        failure(ApiFailure.unauthorized));
    expect(calls, 0);
    expect(storage.deletes, 1);
    expect(session.active, isFalse);
  });
  for (final body in ['<html>broken</html>', '[]', '{']) {
    test('JSON inválido se controla: $body', () async {
      final session = SessionManager(MemoryTokenStorage(testToken));
      final client = MockClient((_) async => http.Response(body, 200));
      addTearDown(client.close);
      addTearDown(session.dispose);
      await expectLater(
          AuthenticatedApiClient(client: client, session: session)
              .request('GET', ApiConstants.myReportsPath),
          failure(ApiFailure.invalidResponse));
    });
  }
  for (final error in [
    http.ClientException('private-detail'),
    const SocketException('private-detail')
  ]) {
    test('${error.runtimeType} se convierte en conexión', () async {
      final session = SessionManager(MemoryTokenStorage(testToken));
      final client = MockClient((_) async => throw error);
      addTearDown(client.close);
      addTearDown(session.dispose);
      await expectLater(
          AuthenticatedApiClient(client: client, session: session)
              .request('GET', ApiConstants.myReportsPath),
          failure(ApiFailure.connection));
    });
  }
  test('timeout cubre toda la respuesta HTTP', () async {
    final pending = Completer<http.Response>();
    final session = SessionManager(MemoryTokenStorage(testToken));
    final client = MockClient((_) => pending.future);
    addTearDown(client.close);
    addTearDown(session.dispose);
    await expectLater(
        AuthenticatedApiClient(
                client: client,
                session: session,
                timeout: const Duration(milliseconds: 10))
            .request('GET', ApiConstants.myMatchesPath),
        failure(ApiFailure.timeout));
    pending.complete(http.Response('{}', 200));
  });
  test('almacenamiento fallido se controla sin hacer HTTP', () async {
    final storage = MemoryTokenStorage(testToken)..failRead = true;
    final session = SessionManager(storage);
    final client = MockClient((_) async => throw StateError('No HTTP'));
    addTearDown(client.close);
    addTearDown(session.dispose);
    await expectLater(
        AuthenticatedApiClient(client: client, session: session)
            .request('GET', ApiConstants.myMatchesPath),
        failure(ApiFailure.storage));
  });
  test('401 tardío de otro usuario no elimina el token nuevo', () async {
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    final storage = MemoryTokenStorage(testToken);
    final session = SessionManager(storage);
    final client = MockClient((_) {
      started.complete();
      return pending.future;
    });
    addTearDown(client.close);
    addTearDown(session.dispose);
    final request = AuthenticatedApiClient(client: client, session: session)
        .request('GET', ApiConstants.myReportsPath);
    final assertion = expectLater(request, failure(ApiFailure.unauthorized));
    await started.future;
    session.changeSession(active: false);
    await session.writeToken('replacement-test-token');
    session.changeSession(active: true);
    pending.complete(http.Response('{}', 401));
    await assertion;
    expect(storage.token, 'replacement-test-token');
    expect(storage.deletes, 0);
    expect(session.active, isTrue);
  });
  test('401 simultáneos invalidan una sola vez', () async {
    final storage = MemoryTokenStorage(testToken);
    final session = SessionManager(storage);
    var events = 0;
    session.expired.listen((_) => events++);
    final client = MockClient((_) async => http.Response('{}', 401));
    addTearDown(client.close);
    addTearDown(session.dispose);
    final api = AuthenticatedApiClient(client: client, session: session);
    await Future.wait([
      expectLater(api.request('GET', ApiConstants.myReportsPath),
          failure(ApiFailure.unauthorized)),
      expectLater(api.request('GET', ApiConstants.myMatchesPath),
          failure(ApiFailure.unauthorized))
    ]);
    expect(events, 1);
    expect(storage.deletes, 1);
  });
}
