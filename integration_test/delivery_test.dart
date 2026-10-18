// Opt-in device E2E. Credentials exist only in memory/private disposable cache.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:integration_test/integration_test.dart';
import 'package:encuentra_u/app/app.dart';
import 'package:encuentra_u/app/admin_app_shell.dart';
import 'package:encuentra_u/app/dependency_container.dart';
import 'package:encuentra_u/app/routes.dart';
import 'package:encuentra_u/core/constants/api_constants.dart';
import 'package:encuentra_u/core/constants/app_strings.dart';
import 'package:encuentra_u/core/identifiers/client_message_id.dart';
import 'package:encuentra_u/core/presentation/paged_controller.dart';
import 'package:encuentra_u/features/authentication/presentation/pages/login_page.dart';
import 'package:encuentra_u/features/deliveries/domain/entities/delivery.dart';
import 'package:encuentra_u/features/deliveries/presentation/pages/delivery_detail_page.dart';
import 'package:encuentra_u/features/messaging/presentation/pages/chat_page.dart';
import 'persistent_images_test.dart' as previous;
import 'claims_chat_test.dart' as privacy;

const fixturePath = String.fromEnvironment('E2E_DELIVERY_FIXTURE');
const fixtureRun = String.fromEnvironment('E2E_FIXTURE_RUN');
Future<void> screenshot(WidgetTester t, String name) async {
  await t.pumpAndSettle();
  print('DELIVERY_E2E_SCREENSHOT $name');
  final ack = File('${File(fixturePath).parent.path}/captured_$name');
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (!ack.existsSync()) {
    if (DateTime.now().isAfter(deadline))
      throw StateError('Screenshot not acknowledged');
    await t.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('entrega física, confirmación doble, disputa y cierre reales',
      (t) async {
    final fixture = File(fixturePath),
        marker = File('${File(fixturePath).parent.path}/ready_$fixtureRun');
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    while (!fixture.existsSync() || !marker.existsSync()) {
      if (DateTime.now().isAfter(deadline))
        throw StateError('Missing private delivery fixture');
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    final admin =
        jsonDecode(await fixture.readAsString()) as Map<String, dynamic>;
    await fixture.delete();
    final password =
        base64UrlEncode(List.generate(32, (_) => Random.secure().nextInt(256)));
    final emails = [
      for (final name in ['a', 'b', 'c'])
        'delivery.$name.$fixtureRun@example.com'
    ];
    final tokens = <String>[];
    for (var i = 0; i < 3; i++) {
      await previous
          .api('POST', ApiConstants.authRegisterPath, expected: 201, body: {
        'full_name': 'Comunidad ${['Alba', 'Bruno', 'Celia'][i]}',
        'email': emails[i],
        'student_code': 'DL$i$fixtureRun',
        'password': password
      });
      tokens.add((await previous.api('POST', ApiConstants.authLoginPath,
              body: {'email': emails[i], 'password': password}))['access_token']
          as String);
    }
    final adminToken = (await previous.api('POST', ApiConstants.authLoginPath,
        body: {
          'email': admin['email'],
          'password': admin['password']
        }))['access_token'] as String;
    Future<Map<String, dynamic>> seed(int n) async {
      final ids = <String>[];
      final date = DateTime.now().subtract(const Duration(days: 2));
      for (var i = 0; i < 2; i++) {
        final report = await previous.api('POST', ApiConstants.reportsPath,
            token: tokens[i],
            expected: 201,
            body: {
              'report_type': i == 0 ? 'lost' : 'found',
              'object_type': 'audífonos de diadema',
              'category': 'electronica',
              'primary_color': 'negro',
              'secondary_colors': ['azul'],
              'brand': null,
              'shape': 'diadema acolchada',
              'description':
                  'Audífonos negros con aros azules y almohadillas redondas.',
              'location': 'Comunidad $fixtureRun caso $n',
              'event_date':
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              'private_feature': 'Marca blanca debajo de la copa izquierda $n',
            });
        ids.add(report['id'] as String);
        final request = http.MultipartRequest(
            'PUT', ApiConstants.uri(ApiConstants.reportImagePath(ids.last)))
          ..headers[ApiConstants.authorizationHeader] = 'Bearer ${tokens[i]}'
          ..files.add(await http.MultipartFile.fromPath('image',
              '${fixture.parent.path}/${i == 0 ? 'front' : 'side'}.png',
              contentType: MediaType('image', 'png')));
        final response = await request.send();
        expect(response.statusCode, 200);
        await response.stream.drain<void>();
      }
      final generated = await previous.api(
          'POST', ApiConstants.generateMatchesPath(ids[0]),
          token: tokens[0]);
      final match = (generated['items'] as List)
          .cast<Map<String, dynamic>>()
          .singleWhere((m) => (m['candidate_report'] as Map)['id'] == ids[1]);
      expect(match['level'], 'high');
      privacy.safe(match);
      final claim = await previous.api(
          'POST', ApiConstants.submitClaimPath(match['id']),
          token: tokens[0],
          expected: 201,
          body: {
            'ownership_evidence': 'Marca blanca debajo de la copa izquierda $n'
          });
      final reviewed = await previous.api(
          'POST', ApiConstants.approveClaimPath(claim['id']),
          token: adminToken);
      final delivery = await previous.api('GET',
          ApiConstants.conversationDeliveryPath(reviewed['conversation_id']),
          token: tokens[0]);
      privacy.safe(delivery);
      return {
        'delivery': delivery['id'],
        'conversation': reviewed['conversation_id'],
        'claim': claim['id'],
        'match': match['id'],
        'lost': ids[0],
        'found': ids[1]
      };
    }

    final normal = await seed(1), dispute = await seed(2);
    await previous.api(
        'POST', ApiConstants.messagesPath(normal['conversation']),
        token: tokens[0],
        expected: 201,
        body: {
          'body': 'Coordinación de entrega $fixtureRun',
          'client_message_id': newClientMessageId()
        });
    final clients = <previous.DeviceApiClient>[];
    DependencyContainer makeDeps() {
      final c = previous.DeviceApiClient();
      clients.add(c);
      return DependencyContainer.create(
          client: c, analysisRepository: previous.SavedGeminiAnalysis());
    }

    var deps = makeDeps();
    await t.pumpWidget(EncuentraUApp(dependencies: deps));
    Future<void> signIn(String email, String pass,
        {bool administrative = false}) async {
      if (deps.authController.isAuthenticated)
        await deps.authController.logout();
      await previous.waitFor(
          t, () => find.byType(LoginPage).evaluate().isNotEmpty, 'login');
      await previous.text(t, find.byType(TextFormField).at(0), email);
      await previous.text(t, find.byType(TextFormField).at(1), pass);
      await previous.tap(t, find.text(AppStrings.signIn));
      await previous.waitFor(
          t,
          () =>
              deps.authController.isAuthenticated &&
              (administrative
                  ? find.byType(AdminAppShell).evaluate().isNotEmpty
                  : deps.objectController.status == LoadStatus.ready),
          'authenticated shell');
    }

    void route(String name, String id) =>
        Navigator.of(t.element(find.byType(Scaffold).first))
            .pushNamed(name, arguments: id);
    Future<void> openDelivery(Map<String, dynamic> c,
        {bool administrative = false}) async {
      route(
          administrative
              ? AppRoutes.adminDeliveryDetail
              : AppRoutes.deliveryDetail,
          administrative ? c['delivery'] : c['conversation']);
      final controller = administrative
          ? deps.adminDeliveryController
          : deps.deliveryController;
      await previous.waitFor(
          t,
          () =>
              find.byType(DeliveryDetailPage).evaluate().isNotEmpty &&
              controller.detail?.id == c['delivery'] &&
              controller.detailStatus == LoadStatus.ready,
          'delivery detail');
    }

    Future<void> action(String label, {String? text}) async {
      final button = find.widgetWithText(FilledButton, label);
      await t.scrollUntilVisible(button.first, 300,
          scrollable: find.byType(Scrollable).last);
      await previous.tap(t, button.first);
      if (text != null)
        await previous.text(t, find.byType(TextFormField).last, text);
      await previous.tap(
          t,
          find
              .descendant(
                  of: find.byType(AlertDialog),
                  matching: find.byType(FilledButton))
              .first);
      await previous.waitFor(
          t,
          () =>
              !deps.deliveryController.isActing &&
              !deps.adminDeliveryController.isActing,
          'delivery action');
    }

    await signIn(emails[1], password);
    route(AppRoutes.conversation, normal['conversation']);
    await previous.waitFor(
        t,
        () =>
            find.byType(ChatPage).evaluate().isNotEmpty &&
            deps.deliveryController.detail?.id == normal['delivery'],
        'chat delivery panel');
    expect(find.byKey(const Key('chat-delivery-panel')), findsOneWidget);
    await screenshot(t, 'CHAT_COORDINATING');
    await openDelivery(normal);
    await action(AppStrings.confirmCustodianDelivery);
    expect(deps.deliveryController.detail!.status,
        DeliveryStatus.awaitingConfirmations);
    await screenshot(t, 'CUSTODIAN_CONFIRMED');
    final repeat = await previous.api(
        'POST', ApiConstants.confirmDeliveryPath(normal['delivery']),
        token: tokens[1]);
    expect((repeat['events'] as List).length, 2);
    await signIn(emails[0], password);
    await openDelivery(normal);
    await action(AppStrings.confirmClaimantDelivery);
    expect(
        deps.deliveryController.detail!.status, DeliveryStatus.awaitingAdmin);
    await screenshot(t, 'AWAITING_ADMIN');
    await signIn(admin['email'], admin['password'], administrative: true);
    route(AppRoutes.adminDeliveries, '');
    await previous.waitFor(
        t,
        () => deps.adminDeliveryController.status == LoadStatus.ready,
        'admin delivery queue');
    await screenshot(t, 'ADMIN_QUEUE');
    await openDelivery(normal, administrative: true);
    expect((deps.adminDeliveryController.detail! as AdminDelivery).messageCount,
        1);
    await action(AppStrings.completeDelivery);
    expect(
        deps.adminDeliveryController.detail!.status, DeliveryStatus.completed);
    await screenshot(t, 'ADMIN_COMPLETED');
    for (final id in [normal['lost'], normal['found']]) {
      final result = await previous.api('GET', ApiConstants.reportPath(id),
          token: tokens[id == normal['lost'] ? 0 : 1]);
      expect(result['status'], 'resolved');
    }
    await previous.api(
        'POST', ApiConstants.messagesPath(normal['conversation']),
        token: tokens[0],
        expected: 409,
        body: {
          'body': 'Bloqueado después del cierre',
          'client_message_id': newClientMessageId()
        });
    await previous.api(
        'GET', ApiConstants.conversationDeliveryPath(normal['conversation']),
        token: tokens[2], expected: 404);
    await previous.api('GET', ApiConstants.messagesPath(normal['conversation']),
        token: adminToken, expected: 404);
    await previous.api(
        'GET', ApiConstants.reportImageContentPath(normal['lost']),
        token: tokens[2], expected: 404);
    await signIn(emails[0], password);
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpAndSettle();
    deps.dispose();
    deps = makeDeps();
    await t.pumpWidget(EncuentraUApp(dependencies: deps));
    await previous.waitFor(
        t,
        () =>
            deps.authController.isAuthenticated &&
            deps.objectController.status == LoadStatus.ready,
        'restored authenticated app');
    route(AppRoutes.conversation, normal['conversation']);
    await previous.waitFor(
        t,
        () => find.text(AppStrings.chatReadOnly).evaluate().isNotEmpty,
        'closed conversation restored');
    expect(
        t
            .widget<IconButton>(find.byKey(const Key('send-chat-message')))
            .onPressed,
        isNull);
    await screenshot(t, 'CHAT_READ_ONLY');
    await openDelivery(dispute);
    await action(AppStrings.confirmClaimantDelivery);
    await signIn(emails[1], password);
    await openDelivery(dispute);
    final problem =
        find.widgetWithText(OutlinedButton, AppStrings.reportDeliveryProblem);
    await t.scrollUntilVisible(problem, 300,
        scrollable: find.byType(Scrollable).last);
    await previous.tap(t, problem);
    await previous.text(t, find.byType(TextFormField).last,
        'El objeto no corresponde al reporte y debemos coordinar de nuevo.');
    await previous.tap(
        t,
        find.descendant(
            of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
    await previous.waitFor(
        t,
        () => deps.deliveryController.detail?.status == DeliveryStatus.disputed,
        'disputed');
    await screenshot(t, 'DELIVERY_DISPUTED');
    final oldEvents = (deps.deliveryController.detail! as Delivery)
        .events
        .map((e) => e.id)
        .toSet();
    await signIn(admin['email'], admin['password'], administrative: true);
    route(AppRoutes.adminDeliveries, '');
    await previous.waitFor(
        t,
        () => deps.adminDeliveryController.status == LoadStatus.ready,
        'priority queue');
    expect(deps.adminDeliveryController.items.first.id, dispute['delivery']);
    await openDelivery(dispute, administrative: true);
    final reopen =
        find.widgetWithText(OutlinedButton, AppStrings.reopenDelivery);
    await t.scrollUntilVisible(reopen, 300,
        scrollable: find.byType(Scrollable).last);
    await previous.tap(t, reopen);
    await previous.text(t, find.byType(TextFormField).last,
        'Se requiere coordinar nuevamente la entrega.');
    await previous.tap(
        t,
        find.descendant(
            of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
    await previous.waitFor(
        t,
        () =>
            deps.adminDeliveryController.detail?.status ==
            DeliveryStatus.coordinating,
        'reopened');
    final reopened = deps.adminDeliveryController.detail! as AdminDelivery;
    expect(reopened.claimantConfirmedAt, isNull);
    expect(reopened.custodianConfirmedAt, isNull);
    expect(reopened.events.map((e) => e.id).toSet().containsAll(oldEvents),
        isTrue);
    await screenshot(t, 'ADMIN_REOPENED');
    for (final token in tokens.take(2)) {
      await previous.api(
          'POST', ApiConstants.confirmDeliveryPath(dispute['delivery']),
          token: token);
    }
    await deps.adminDeliveryController.refreshDetail();
    await t.pumpAndSettle();
    await action(AppStrings.completeDelivery);
    expect(
        deps.adminDeliveryController.detail!.status, DeliveryStatus.completed);
    await screenshot(t, 'DISPUTE_COMPLETED');
    for (final c in [normal, dispute]) {
      final student = await previous.api(
          'GET', ApiConstants.conversationDeliveryPath(c['conversation']),
          token: tokens[0]);
      privacy.safe(student);
      expect(student['status'], 'completed');
      final metadata = await previous.api(
          'GET', ApiConstants.adminDeliveryPath(c['delivery']),
          token: adminToken);
      privacy.safe(metadata, admin: true);
      expect(metadata.containsKey('messages'), isFalse);
    }
    expect(
        clients.every((c) =>
            c.requests.every((r) => !r['path'].toString().contains('/ai/'))),
        isTrue);
    print('DELIVERY_E2E_RESULT ${jsonEncode({
          'passed': true,
          'normal': normal,
          'dispute': dispute,
          'privacy': true,
          'app_recreated': true,
          'gemini_calls': 0
        })}');
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpAndSettle();
    deps.dispose();
    for (final c in clients) c.close();
  }, timeout: const Timeout(Duration(minutes: 20)));
}
