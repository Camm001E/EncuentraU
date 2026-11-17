import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:encuentra_u/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:encuentra_u/features/authentication/domain/exceptions/auth_exception.dart';
import 'package:encuentra_u/features/authentication/domain/repositories/email_verifier.dart';
import 'package:encuentra_u/features/authentication/presentation/pages/verify_email_page.dart';

class FakeVerifier implements EmailVerifier {
  int requests = 0;
  String? confirmed;
  @override
  Future<VerificationRequestResult> requestCode(
      {required String email, required String password}) async {
    requests++;
    return const VerificationRequestResult(
        alreadyVerified: false, retryAfter: 60);
  }

  @override
  Future<void> confirmCode(
      {required String email,
      required String password,
      required String code}) async {
    confirmed = code;
  }
}

void main() {
  test('verification required is distinct from inactive account', () async {
    final source = AuthRemoteDataSource(
        client: MockClient((_) async => http.Response(
            '{"code":"email_verification_required","detail":"verify"}', 403)));
    await expectLater(
        source.login(email: 'test@example.com', password: 'password'),
        throwsA(isA<AuthException>()
            .having((e) => e.failure, 'failure', AuthFailure.emailUnverified)));
  });
  test('codes travel in request bodies and rate limit keeps retry time',
      () async {
    final source = AuthRemoteDataSource(client: MockClient((request) async {
      expect(request.url.query, isEmpty);
      expect(jsonDecode(request.body)['password'], 'password');
      return http.Response('{}', 429, headers: {'retry-after': '90'});
    }));
    await expectLater(
        source.requestCode(email: 'test@example.com', password: 'password'),
        throwsA(isA<AuthException>().having((e) => e.retryAfter, 'retry', 90)));
  });
  test('confirmation requires verified response', () async {
    final source = AuthRemoteDataSource(
        client:
            MockClient((_) async => http.Response('{"status":"sent"}', 200)));
    await expectLater(
        source.confirmCode(
            email: 'test@example.com', password: 'password', code: '12345678'),
        throwsA(isA<AuthException>()
            .having((e) => e.failure, 'failure', AuthFailure.invalidResponse)));
  });
  testWidgets(
      'request, cooldown and verification success clear sensitive fields',
      (tester) async {
    final verifier = FakeVerifier();
    await tester.pumpWidget(MaterialApp(
        home: VerifyEmailPage(
            verifier: verifier, initialEmail: 'test@example.com')));
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.ensureVisible(find.text('Enviar código'));
    await tester.tap(find.text('Enviar código'));
    await tester.pump();
    expect(verifier.requests, 1);
    expect(find.text('Reenviar en 60 s'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(2), '12345678');
    await tester.ensureVisible(find.text('Confirmar correo'));
    await tester.tap(find.text('Confirmar correo'));
    await tester.pumpAndSettle();
    expect(verifier.confirmed, '12345678');
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
