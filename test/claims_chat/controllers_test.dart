import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:encuentra_u/core/errors/api_exception.dart';
import 'package:encuentra_u/core/presentation/paged_controller.dart';
import 'package:encuentra_u/core/identifiers/client_message_id.dart';
import 'package:encuentra_u/features/claims/domain/entities/ownership_claim.dart';
import 'package:encuentra_u/features/claims/domain/usecases/claims.dart';
import 'package:encuentra_u/features/claims/presentation/controllers/admin_claims_controller.dart';
import 'package:encuentra_u/features/messaging/domain/entities/conversation.dart';
import 'package:encuentra_u/features/messaging/data/models/conversation_model.dart';
import 'support.dart';

void main() {
  test(
      'reclamación valida evidencia, bloquea doble envío y conserva ID del backend',
      () async {
    final repo = TestClaims();
    final c = claimsController(repo);
    addTearDown(c.dispose);
    expect(await c.submit('m', const ClaimDraft('corta')), isNull);
    expect(repo.submitted, 0);
    final pending = Completer<OwnershipClaim>();
    repo.onSubmit = () => pending.future;
    final result =
        c.submit('m', const ClaimDraft('Detalle privado suficiente.'));
    expect(c.isSubmitting, isTrue);
    expect(await c.submit('m', const ClaimDraft('Detalle privado suficiente.')),
        isNull);
    pending.complete(repo.value);
    expect((await result)?.id, repo.value.id);
    expect(repo.submitted, 1);
    expect(c.isSubmitting, isFalse);
    expect(c.claimFor(repo.value.matchId)?.id, repo.value.id);
  });
  test('listado filtra, pagina y limpia evidencia al cerrar sesión', () async {
    final repo = TestClaims();
    final controller = claimsController(repo);
    addTearDown(controller.dispose);
    await controller.setStatus(ClaimStatus.pending);
    expect(repo.filter, ClaimStatus.pending);
    expect(controller.hasMore, isTrue);
    await controller.loadMore();
    expect(repo.offset, 1);
    await controller.loadDetail('claim-1');
    expect(controller.detail?.ownershipEvidence, isNotNull);
    controller.clear();
    expect(controller.detail, isNull);
    expect(controller.items, isEmpty);
    expect(controller.status, LoadStatus.initial);
  });
  test('respuesta tardía no restaura evidencia después de logout', () async {
    final repo = TestClaims(), pending = Completer<OwnershipClaim>();
    repo.onSubmit = () => pending.future;
    final c = claimsController(repo);
    addTearDown(c.dispose);
    final request =
        c.submit('m', const ClaimDraft('Detalle privado suficiente.'));
    c.clear();
    pending.complete(repo.value);
    expect(await request, isNull);
    expect(c.detail, isNull);
    expect(c.items, isEmpty);
  });
  test('error de reclamaciones permite reintentar', () async {
    final repo = TestClaims()..error = const ApiException(ApiFailure.server);
    final c = claimsController(repo);
    addTearDown(c.dispose);
    await c.refresh();
    expect(c.status, LoadStatus.error);
    repo.error = null;
    await c.refresh();
    expect(c.status, LoadStatus.ready);
  });
  test('administrador carga totales reales y conserva error sin inventar ceros',
      () async {
    final repo = TestClaims();
    final controller = AdminSummaryController(GetAdminClaimTotals(repo));
    addTearDown(controller.dispose);
    await controller.refresh();
    expect(controller.totals?.pending, 12);
    expect(controller.totals?.approved, 7);
    repo.error = const ApiException(ApiFailure.server);
    await controller.refresh();
    expect(controller.status, LoadStatus.error);
    expect(controller.totals, isNull);
  });
  test(
      'aprobar bloquea decisión duplicada mientras espera y después de resolver',
      () async {
    final repo = TestClaims(), pending = Completer<AdminClaim>();
    repo.onApprove = () => pending.future;
    final c = adminController(repo);
    addTearDown(c.dispose);
    await c.loadDetail('claim-1');
    final request = c.approve('claim-1');
    expect(c.isReviewing, isTrue);
    expect(await c.approve('claim-1'), isFalse);
    repo.onApprove = null;
    final approved = await repo.approve('claim-1');
    pending.complete(approved);
    expect(await request, isTrue);
    expect(c.detail?.status, ClaimStatus.approved);
    expect(await c.reject('claim-1', reason: 'No coincide'), isFalse);
  });
  test('rechazo exige motivo y conserva decisión del servidor', () async {
    final repo = TestClaims();
    final controller = adminController(repo);
    addTearDown(controller.dispose);
    await controller.loadDetail('claim-1');
    expect(await controller.reject('claim-1', reason: ' '), isFalse);
    expect(repo.rejected, 0);
    expect(
        await controller.reject('claim-1', reason: 'El detalle no coincide.'),
        isTrue);
    expect(controller.detail?.status, ClaimStatus.rejected);
  });
  test('UUID de mensaje es versión 4 y no se repite', () {
    final ids = List.generate(100, (_) => newClientMessageId());
    expect(ids.toSet(), hasLength(100));
    for (final id in ids) {
      expect(
          id,
          matches(RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    }
  });
  test('validación de texto normalizado y límite de 2000 caracteres', () {
    expect(MessageDraft.isValid(' \n '), isFalse);
    expect(MessageDraft.isValid('a' * 2000), isTrue);
    expect(MessageDraft.isValid('a' * 2001), isFalse);
    expect(MessageDraft.normalize('  hola\r\nmundo  '), 'hola\nmundo');
  });
  testWidgets(
      'polling solo visible, detiene al salir y limpia mensajes por logout',
      (tester) async {
    final repo = TestConversations();
    final controller = chatController(repo);
    addTearDown(controller.dispose);
    await controller.open('conversation-1');
    expect(controller.isPolling, isFalse);
    expect(repo.reads, 0);
    controller.setVisible(true);
    await tester.pump();
    expect(controller.isPolling, isTrue);
    expect(repo.readIds.last, 'message-1');
    final calls = repo.lists;
    await tester.pump(const Duration(seconds: 4));
    expect(repo.lists, greaterThan(calls));
    controller.setVisible(false);
    final stopped = repo.lists;
    await tester.pump(const Duration(seconds: 9));
    expect(repo.lists, stopped);
    controller.clear();
    expect(controller.messages, isEmpty);
    expect(controller.isPolling, isFalse);
    expect(controller.conversation, isNull);
  });
  test('reintento conserva client_message_id; otro texto recibe UUID nuevo',
      () async {
    final repo = TestConversations();
    final controller = chatController(repo);
    addTearDown(controller.dispose);
    await controller.open('conversation-1');
    repo.error = const ApiException(ApiFailure.connection);
    expect(await controller.send('Hola'), isFalse);
    repo.error = null;
    expect(await controller.send('Hola'), isTrue);
    expect(repo.sentIds[0], repo.sentIds[1]);
    expect(await controller.send('Otro mensaje'), isTrue);
    expect(repo.sentIds.last, isNot(repo.sentIds.first));
    expect(controller.messages.where((m) => m.id == 'sent'), hasLength(1));
  });
  test('doble envío y texto vacío no publican dos mensajes', () async {
    final repo = TestConversations(), pending = Completer<ChatMessage>();
    repo.onSend = () => pending.future;
    final c = chatController(repo);
    addTearDown(c.dispose);
    await c.open('conversation-1');
    expect(await c.send(' '), isFalse);
    final result = c.send('Hola');
    expect(await c.send('Hola'), isFalse);
    expect(repo.sends, 1);
    pending.complete(ConversationModel.message(messageJson(mine: true)));
    expect(await result, isTrue);
  });
  test('paginación deduplica y ordena cronológicamente mensajes inmutables',
      () async {
    final repo = TestConversations();
    repo.onMessages = (cursor) async => MessagePage(items: [
          ConversationModel.message(messageJson(
              id: cursor == null ? 'new' : 'old',
              second: cursor == null ? 9 : 1))
        ], limit: 1, nextCursor: cursor == null ? 'older' : null);
    final c = chatController(repo);
    addTearDown(c.dispose);
    await c.open('conversation-1');
    await c.loadOlder();
    await c.refresh();
    expect(c.messages.map((m) => m.id), ['old', 'new']);
    expect(c.nextCursor, isNull);
  });
  test('acceso revocado elimina mensajes visibles y detiene polling', () async {
    final repo = TestConversations();
    final controller = chatController(repo);
    addTearDown(controller.dispose);
    await controller.open('conversation-1');
    expect(controller.messages, isNotEmpty);
    repo.error = const ApiException(ApiFailure.notFound);
    await controller.refresh();
    expect(controller.status, LoadStatus.error);
    expect(controller.messages, isEmpty);
    expect(controller.isPolling, isFalse);
  });
  test(
      'ventana perdida durante suspensión puede recuperar toda la historia por cursor',
      () async {
    final repo = TestConversations();
    final c = chatController(repo);
    addTearDown(c.dispose);
    await c.open('conversation-1');
    repo.onMessages = (cursor) async => MessagePage(items: [
          ConversationModel.message(messageJson(
              id: cursor == null ? 'recent' : 'gap',
              second: cursor == null ? 9 : 5))
        ], limit: 1, nextCursor: cursor == null ? 'recover-gap' : null);
    await c.refresh();
    expect(c.nextCursor, 'recover-gap');
    expect(c.messages.map((m) => m.id), ['recent']);
    await c.loadOlder();
    expect(c.messages.map((m) => m.id), ['gap', 'recent']);
  });
}
