import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:encuentra_u/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:encuentra_u/features/authentication/domain/exceptions/auth_exception.dart';
import 'package:encuentra_u/features/authentication/domain/repositories/password_recoverer.dart';
import 'package:encuentra_u/features/authentication/presentation/pages/recover_password_page.dart';

class Recovery implements PasswordRecoverer {
  int requests = 0, confirmations = 0;
  bool fail = false;
  @override
  Future<int> requestPasswordRecovery({required String email}) async {
    requests++;
    return 60;
  }

  @override
  Future<void> confirmPasswordRecovery(
      {required String email,
      required String code,
      required String password}) async {
    if (fail) throw const AuthException(AuthFailure.verificationCode);
    confirmations++;
  }
}

void main() {
  test(
      'recovery request sends only normalized email and accepts generic result',
      () async {
    final source = AuthRemoteDataSource(client: MockClient((request) async {
      expect(request.url.path, '/api/v1/auth/password/request');
      expect(request.url.query, isEmpty);
      expect(jsonDecode(request.body), {'email': 'test@example.com'});
      return http.Response('{"status":"accepted","retry_after":60}', 200);
    }));
    expect(
        await source.requestPasswordRecovery(email: ' Test@Example.com '), 60);
  });
  test('code and password use POST body; malformed success is rejected',
      () async {
    final source = AuthRemoteDataSource(client: MockClient((request) async {
      expect(request.url.query, isEmpty);
      expect(jsonDecode(request.body), {
        'email': 'test@example.com',
        'code': '12345678',
        'new_password': 'new-password'
      });
      return http.Response('{"status":"accepted"}', 200);
    }));
    await expectLater(
        source.confirmPasswordRecovery(
            email: 'test@example.com',
            code: '12345678',
            password: 'new-password'),
        throwsA(isA<AuthException>()
            .having((e) => e.failure, 'failure', AuthFailure.invalidResponse)));
  });
  testWidgets('request, mismatched passwords, invalid code and success',
      (tester) async {
    final recovery = Recovery();
    await tester.pumpWidget(MaterialApp(
        home: RecoverPasswordPage(
            recoverer: recovery, initialEmail: 'test@example.com')));
    await tester.tap(find.text('Enviar código de recuperación'));
    await tester.pump();
    expect(recovery.requests, 1);
    expect(find.text('Reenviar en 60 s'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), '12345678');
    await tester.enterText(find.byType(TextFormField).at(2), 'new-password');
    await tester.enterText(find.byType(TextFormField).at(3), 'different');
    await tester.ensureVisible(find.text('Guardar nueva contraseña'));
    await tester.tap(find.text('Guardar nueva contraseña'));
    await tester.pump();
    expect(recovery.confirmations, 0);
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(3), 'new-password');
    recovery.fail = true;
    await tester.ensureVisible(find.text('Guardar nueva contraseña'));
    await tester.tap(find.text('Guardar nueva contraseña'));
    await tester.pumpAndSettle();
    expect(recovery.confirmations, 0);
    expect(find.byType(TextFormField), findsNWidgets(4));
    recovery.fail = false;
    await tester.ensureVisible(find.text('Guardar nueva contraseña'));
    await tester.tap(find.text('Guardar nueva contraseña'));
    await tester.pumpAndSettle();
    expect(recovery.confirmations, 1);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.textContaining('Contraseña actualizada.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('changing account clears secrets and keeps cooldown',
      (tester) async {
    final recovery = Recovery();
    await tester.pumpWidget(MaterialApp(
        home: RecoverPasswordPage(
            recoverer: recovery, initialEmail: 'test@example.com')));
    await tester.tap(find.text('Enviar código de recuperación'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(1), '12345678');
    await tester.tap(find.text('Usar otro correo'));
    await tester.pump();
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('12345678'), findsNothing);
    expect(find.text('Reenviar en 60 s'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
