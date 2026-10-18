import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:encuentra_u/core/constants/api_constants.dart';
import 'package:encuentra_u/core/errors/api_exception.dart';
import 'package:encuentra_u/core/network/authenticated_api_client.dart';
import 'package:encuentra_u/core/session/session_manager.dart';
import 'package:encuentra_u/features/claims/data/datasources/claim_remote_data_source.dart';
import 'package:encuentra_u/features/claims/data/models/claim_model.dart';
import 'package:encuentra_u/features/claims/data/repositories/claim_repository_impl.dart';
import 'package:encuentra_u/features/claims/domain/entities/ownership_claim.dart';
import 'package:encuentra_u/features/messaging/data/datasources/conversation_remote_data_source.dart';
import 'package:encuentra_u/features/messaging/data/models/conversation_model.dart';
import '../authentication/auth_test_support.dart';
import '../remote/support.dart';
import 'support.dart';

void main() {
  for (final status in ClaimStatus.values) {
    test('contrato ${status.name}, nueve factores y fechas UTC', () {
      final claim = ClaimModel.fromJson(claimJson(status: status.name));
      expect(claim.status, status);
      expect(claim.match.factors, hasLength(9));
      expect(claim.createdAt.isUtc, isTrue);
      expect(claim.ownershipEvidence, isNotNull);
      expect(claim.conversationId,
          status == ClaimStatus.approved ? isNotNull : isNull);
    });
  }
  test('custodio descarta evidencia privada incluso si el JSON la incluye', () {
    final claim = ClaimModel.fromJson(claimJson(relationship: 'custodian'));
    expect(claim.ownershipEvidence, isNull);
    expect(claim.relationship, ClaimRelationship.custodian);
  });
  test('vista administrativa separada conserva evidencia y dos características',
      () {
    final admin = ClaimModel.admin(claimJson());
    expect(admin.lostPrivateFeature, isNotNull);
    expect(admin.foundPrivateFeature, isNotNull);
    final queue = ClaimModel.admin({...claimJson()}..removeWhere((k, _) => {
          'ownership_evidence',
          'lost_private_feature',
          'found_private_feature',
          'admin_note'
        }.contains(k)));
    expect(queue.ownershipEvidence, isNull);
  });
  test('conversación y mensajes: identidad segura y texto literal', () {
    final c = ConversationModel.fromJson(conversationJson());
    expect(c.unreadCount, 1);
    expect(c.otherDisplayName, 'Persona');
    final m = ConversationModel.message(
        {...messageJson(), 'body': '<b>texto literal</b>'});
    expect(m.body, '<b>texto literal</b>');
    expect(
        () => ConversationModel.fromJson({
              ...conversationJson(),
              'other_display_name': 'private@example.com'
            }),
        throwsFormatException);
    expect(
        () => ConversationModel.fromJson(
            {...conversationJson(), 'unread_count': -1}),
        throwsFormatException);
  });
  test('todas las rutas de reclamaciones usan Bearer y cuerpos allowlist',
      () async {
    final requests = <http.Request>[];
    final session = SessionManager(MemoryTokenStorage(testToken));
    addTearDown(session.dispose);
    final client = MockClient((r) async {
      requests.add(r);
      expect(r.headers['authorization'], 'Bearer $testToken');
      if (r.url.path.endsWith('/me') ||
          r.url.path == ApiConstants.adminClaimsPath)
        return jsonResponse(pageJson([claimJson()]));
      return jsonResponse(claimJson(),
          r.method == 'POST' && r.url.path.endsWith('/claims') ? 201 : 200);
    });
    addTearDown(client.close);
    final repo = ClaimRepositoryImpl(ClaimRemoteDataSource(
        AuthenticatedApiClient(client: client, session: session)));
    await repo.submit('m', const ClaimDraft('  Detalle privado del objeto.  '));
    expect(jsonDecode(requests.last.body),
        {'ownership_evidence': 'Detalle privado del objeto.'});
    await repo.getMyClaims(limit: 5, offset: 10, status: ClaimStatus.rejected);
    expect(requests.last.url.queryParameters,
        {'limit': '5', 'offset': '10', 'status': 'rejected'});
    await repo.getClaim('c');
    await repo.getMatchClaim('m');
    await repo.getAdminClaims(limit: 1, offset: 0, status: ClaimStatus.pending);
    await repo.getAdminClaim('c');
    await repo.approve('c', note: '  Revisado  ');
    expect(jsonDecode(requests.last.body), {'admin_note': 'Revisado'});
    await repo.reject('c', reason: '  No coincide  ');
    expect(jsonDecode(requests.last.body), {'rejection_reason': 'No coincide'});
    final totals = await repo.getTotals();
    expect(totals.pending, 1);
    expect(requests.length, 11);
  });
  test('cursor estable, idempotencia y lectura 204 en datasource de mensajes',
      () async {
    final requests = <http.Request>[];
    final session = SessionManager(MemoryTokenStorage(testToken));
    addTearDown(session.dispose);
    final client = MockClient((r) async {
      requests.add(r);
      expect(r.headers['authorization'], 'Bearer $testToken');
      if (r.url.path.endsWith('/read')) return http.Response('', 204);
      if (r.url.path.endsWith('/messages'))
        return r.method == 'POST'
            ? jsonResponse(messageJson(), 201)
            : jsonResponse({
                'items': [messageJson()],
                'limit': 2,
                'next_cursor': 'stable-cursor'
              });
      return r.url.path.endsWith('/me')
          ? jsonResponse(pageJson([conversationJson()]))
          : jsonResponse(conversationJson());
    });
    addTearDown(client.close);
    final remote = ConversationRemoteDataSource(
        AuthenticatedApiClient(client: client, session: session));
    await remote.list(limit: 2, offset: 1);
    await remote.get('c');
    final page = await remote.messages('c', limit: 2, before: 'cursor/+');
    expect(page.nextCursor, 'stable-cursor');
    expect(requests.last.url.queryParameters['before'], 'cursor/+');
    await remote.send('c', '  Hola  ', 'unique-id');
    expect(jsonDecode(requests.last.body),
        {'body': 'Hola', 'client_message_id': 'unique-id'});
    await remote.read('c', 'message-1');
    expect(jsonDecode(requests.last.body), {'last_message_id': 'message-1'});
  });
  for (final code in [401, 403, 404, 409, 422, 500]) {
    test('error HTTP $code no filtra detalles ni crea datos locales', () async {
      final storage = MemoryTokenStorage(testToken),
          client = MockClient((_) async => jsonResponse({
                'detail': 'internal-secret',
                'code': code == 403 ? 'permission_denied' : 'workflow_error'
              }, code));
      final session = SessionManager(storage);
      addTearDown(session.dispose);
      addTearDown(client.close);
      final repo = ClaimRepositoryImpl(ClaimRemoteDataSource(
          AuthenticatedApiClient(client: client, session: session)));
      await expectLater(repo.getClaim('c'), throwsA(isA<ApiException>()));
      expect(session.active, code != 401);
      expect(storage.token, code == 401 ? isNull : testToken);
    });
  }
  test('404 de reclamación por pareja es ausencia; 500 sigue siendo error',
      () async {
    var status = 404;
    final session = SessionManager(MemoryTokenStorage(testToken));
    addTearDown(session.dispose);
    final client = MockClient((_) async => jsonResponse({}, status));
    addTearDown(client.close);
    final repo = ClaimRepositoryImpl(ClaimRemoteDataSource(
        AuthenticatedApiClient(client: client, session: session)));
    expect(await repo.getMatchClaim('m'), isNull);
    status = 500;
    await expectLater(repo.getMatchClaim('m'), throwsA(isA<ApiException>()));
  });
  test('JSON incompleto se convierte en error de dominio controlado', () async {
    final session = SessionManager(MemoryTokenStorage(testToken));
    addTearDown(session.dispose);
    final client = MockClient((_) async => jsonResponse({'id': 'c'}));
    addTearDown(client.close);
    final repo = ClaimRepositoryImpl(ClaimRemoteDataSource(
        AuthenticatedApiClient(client: client, session: session)));
    await expectLater(
        repo.getClaim('c'),
        throwsA(isA<ApiException>()
            .having((e) => e.failure, 'failure', ApiFailure.invalidResponse)));
  });
}
