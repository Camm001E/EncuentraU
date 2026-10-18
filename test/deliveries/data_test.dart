import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:encuentra_u/core/constants/api_constants.dart';
import 'package:encuentra_u/core/network/authenticated_api_client.dart';
import 'package:encuentra_u/core/session/session_manager.dart';
import 'package:encuentra_u/core/errors/api_exception.dart';
import 'package:encuentra_u/features/deliveries/data/models/delivery_model.dart';
import 'package:encuentra_u/features/deliveries/data/datasources/delivery_remote_data_source.dart';
import 'package:encuentra_u/features/deliveries/data/repositories/delivery_repository_impl.dart';
import 'package:encuentra_u/features/deliveries/domain/entities/delivery.dart';
import '../authentication/auth_test_support.dart';
import '../remote/support.dart';
import 'support.dart';

void main() {
  for (final status in DeliveryStatus.values)
    test('contrato ${status.wireName}, permisos, fechas e historial', () {
      final d = DeliveryModel.fromJson(deliveryJson(status: status));
      expect(d.status, status);
      expect(d.events.length, 6);
      expect(d.createdAt.isUtc, isTrue);
      expect(
          d.canDispute,
          !{DeliveryStatus.disputed, DeliveryStatus.completed}
              .contains(status));
      expect(d is AdminDelivery, isFalse);
    });
  test('vista admin separada conserva factores sin almacenar mensajes', () {
    final d = DeliveryModel.admin(deliveryJson());
    expect(d.claim!.match.factors.length, 9);
    expect(d.messageCount, 3);
    expect(d.adminNote, isNotNull);
  });
  test('estado o rol desconocidos se rechazan', () {
    expect(() => DeliveryModel.fromJson({...deliveryJson(), 'status': 'other'}),
        throwsFormatException);
    expect(
        () => DeliveryModel.fromJson(
            {...deliveryJson(), 'relationship': 'admin'}),
        throwsFormatException);
  });
  test('vista estudiantil descarta notas administrativas incluso si llegan',
      () {
    final json = deliveryJson();
    (json['events'] as List).last['note'] = 'Nota solo para revisión';
    final d = DeliveryModel.fromJson(json);
    expect(d.events.last.note, isNull);
  });
  test('todas las rutas usan Bearer, JSON explícito y filtros snake_case',
      () async {
    final seen = <String>[];
    final client = MockClient((r) async {
      expect(r.headers['Authorization'], 'Bearer $testToken');
      seen.add('${r.method} ${r.url.path}');
      if (r.url.path.endsWith('/me') ||
          r.url.path == ApiConstants.adminDeliveriesPath) {
        expect(r.url.queryParameters['limit'], '1');
        return jsonResponse(pageJson([deliveryJson()]));
      }
      if (r.url.path.endsWith('/confirm')) expect(r.body, isEmpty);
      if (r.url.path.endsWith('/dispute'))
        expect(
            jsonDecode(r.body), {'reason': 'Motivo suficientemente detallado'});
      if (r.url.path.endsWith('/reopen'))
        expect(jsonDecode(r.body), {'admin_note': 'Revisar coordinación'});
      return jsonResponse(deliveryJson());
    });
    final session = SessionManager(MemoryTokenStorage(testToken));
    addTearDown(session.dispose);
    addTearDown(client.close);
    final r = DeliveryRepositoryImpl(DeliveryRemoteDataSource(
        AuthenticatedApiClient(client: client, session: session)));
    await r.getForConversation('c');
    await r.confirm('d');
    await r.dispute('d', 'Motivo suficientemente detallado');
    await r.listMine(limit: 1, offset: 0, status: DeliveryStatus.awaitingAdmin);
    await r.listAdmin(limit: 1, offset: 0, status: DeliveryStatus.disputed);
    await r.getAdmin('d');
    await r.complete('d', note: 'Entrega validada');
    await r.reopen('d', 'Revisar coordinación');
    expect(seen.length, 8);
  });
  test('JSON inválido se convierte a error controlado', () async {
    final client = MockClient((_) async => jsonResponse({'invalid': true}));
    final s = SessionManager(MemoryTokenStorage(testToken));
    addTearDown(client.close);
    addTearDown(s.dispose);
    final r = DeliveryRepositoryImpl(DeliveryRemoteDataSource(
        AuthenticatedApiClient(client: client, session: s)));
    await expectLater(
        r.getForConversation('c'),
        throwsA(isA<ApiException>()
            .having((e) => e.failure, 'failure', ApiFailure.invalidResponse)));
  });
  for (final code in [401, 403, 404, 409, 422, 500])
    test('HTTP $code conserva mapeo seguro y expiración', () async {
      final storage = MemoryTokenStorage(testToken),
          client = MockClient((_) async => jsonResponse({}, code));
      final s = SessionManager(storage);
      addTearDown(s.dispose);
      addTearDown(client.close);
      final r = DeliveryRepositoryImpl(DeliveryRemoteDataSource(
          AuthenticatedApiClient(client: client, session: s)));
      await expectLater(r.confirm('d'), throwsA(isA<ApiException>()));
      if (code == 401) expect(await storage.readToken(), isNull);
    });
}
