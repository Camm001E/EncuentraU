import 'dart:async';
import 'package:encuentra_u/app/dependency_container.dart';
import 'package:http/testing.dart';
import '../authentication/auth_test_support.dart';
import '../premium/support.dart';
import '../remote/support.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:encuentra_u/core/errors/api_exception.dart';
import 'package:encuentra_u/core/presentation/paged_controller.dart';
import 'package:encuentra_u/features/deliveries/domain/entities/delivery.dart';
import 'package:encuentra_u/features/deliveries/domain/usecases/deliveries.dart';
import 'support.dart';

void main() {
  test('logout y 401 limpian ambas vistas de entrega en la composición real',
      () async {
    final repo = TestDeliveries();
    final client = MockClient((_) async => jsonResponse({}, 401));
    final auth = FakeAuthRepository()..onRestore = () async => testUser;
    final deps = DependencyContainer.create(
        client: client,
        tokenStorage: MemoryTokenStorage(testToken),
        authRepository: auth,
        dashboardRepository: TestDashboardRepository(),
        deliveryRepository: repo);
    addTearDown(deps.dispose);
    addTearDown(client.close);
    await deps.authController.restoreSession();
    await deps.deliveryController.loadDetail('conversation-1');
    await deps.adminDeliveryController.loadDetail('delivery-1');
    expect(deps.deliveryController.detail, isNotNull);
    expect(deps.adminDeliveryController.detail, isNotNull);
    await deps.authController.logout();
    expect(deps.deliveryController.detail, isNull);
    expect(deps.adminDeliveryController.detail, isNull);
    await deps.authController.restoreSession();
    await deps.deliveryController.loadDetail('conversation-1');
    await deps.adminDeliveryController.loadDetail('delivery-1');
    await deps.matchController.refresh();
    await Future<void>.delayed(Duration.zero);
    expect(deps.deliveryController.detail, isNull);
    expect(deps.adminDeliveryController.detail, isNull);
    expect(deps.deliveryController.totals, isNull);
  });
  test('carga, filtros, detalle, error y reintento', () async {
    final r = TestDeliveries(), c = deliveryController(TestDeliveries());
    addTearDown(c.dispose);
    await c.refresh();
    expect(c.status, LoadStatus.ready);
    await c.setStatus(DeliveryStatus.completed);
    expect(c.status, LoadStatus.empty);
    final other = deliveryController(r);
    addTearDown(other.dispose);
    r.error = const ApiException(ApiFailure.server);
    await other.refresh();
    expect(other.status, LoadStatus.error);
    r.error = null;
    await other.refresh();
    expect(other.status, LoadStatus.ready);
  });
  test('confirmación bloquea doble toque y conserva ID', () async {
    final r = TestDeliveries(), pending = Completer<Delivery>();
    final c = deliveryController(r);
    addTearDown(c.dispose);
    await c.loadDetail('conversation-1');
    r.onConfirm = () => pending.future;
    final work = c.confirm();
    expect(c.isActing, isTrue);
    expect(await c.confirm(), isFalse);
    pending.complete(r.value);
    expect(await work, isTrue);
    expect(r.confirmations, 1);
    expect(c.detail!.id, 'delivery-1');
  });
  test('logout descarta respuestas tardías y datos privados', () async {
    final r = TestDeliveries(), pending = Completer<Delivery>();
    r.onGet = () => pending.future;
    final c = deliveryController(r);
    addTearDown(c.dispose);
    final work = c.loadDetail('c');
    c.clear();
    pending.complete(r.value);
    await work;
    expect(c.detail, isNull);
    expect(c.totals, isNull);
    expect(c.status, LoadStatus.initial);
  });
  test('disputa y reapertura validan longitud antes de llamar al servidor',
      () async {
    final r = TestDeliveries();
    await expectLater(Future.sync(() => OpenDeliveryDispute(r)('d', 'corto')),
        throwsFormatException);
    await expectLater(
        Future.sync(() => ReopenDelivery(r)('d', ' ')), throwsFormatException);
    expect(r.disputes, 0);
    expect(r.reopens, 0);
  });
  test('admin consulta, completa, reabre y actualiza totales reales', () async {
    final r = TestDeliveries(),
        c = deliveryController(TestDeliveries(), admin: true);
    addTearDown(c.dispose);
    final a = deliveryController(r, admin: true);
    addTearDown(a.dispose);
    await a.loadDetail('d');
    expect(a.detail, isA<AdminDelivery>());
    expect(await a.complete(note: 'Entrega revisada'), isTrue);
    expect(await a.reopen('Recoordinar entrega'), isTrue);
    expect(r.completions, 1);
    expect(r.reopens, 1);
    expect(a.totals!.length, 5);
    a.clear();
    expect(a.detail, isNull);
    expect(a.totals, isNull);
  });
}
