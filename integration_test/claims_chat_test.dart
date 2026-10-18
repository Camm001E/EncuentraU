// Opt-in real API/device workflow. Credentials arrive in a disposable private
// device cache, are deleted immediately, and are never printed or versioned.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:encuentra_u/app/app.dart';
import 'package:encuentra_u/app/admin_app_shell.dart';
import 'package:encuentra_u/app/dependency_container.dart';
import 'package:encuentra_u/app/routes.dart';
import 'package:encuentra_u/core/constants/api_constants.dart';
import 'package:encuentra_u/core/constants/app_strings.dart';
import 'package:encuentra_u/core/presentation/paged_controller.dart';
import 'package:encuentra_u/features/authentication/domain/entities/app_user.dart';
import 'package:encuentra_u/features/authentication/presentation/pages/login_page.dart';
import 'package:encuentra_u/features/claims/domain/entities/ownership_claim.dart';
import 'package:encuentra_u/features/claims/presentation/pages/claim_detail_page.dart';
import 'package:encuentra_u/features/claims/presentation/pages/claim_form_page.dart';
import 'package:encuentra_u/features/messaging/presentation/pages/chat_page.dart';
import 'package:encuentra_u/features/matching/presentation/widgets/score_ring.dart';
import 'package:encuentra_u/features/objects/domain/entities/object_report.dart';
import 'package:encuentra_u/features/objects/domain/entities/report_image.dart';
import 'persistent_images_test.dart' as previous;

const fixturePath = String.fromEnvironment('E2E_CLAIMS_FIXTURE');
const fixtureRun = String.fromEnvironment('E2E_FIXTURE_RUN');
Future<void> screenshot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  print('CLAIMS_E2E_SCREENSHOT $name');
  final ack = File('${File(fixturePath).parent.path}/captured_$name');
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (!ack.existsSync()) {
    if (DateTime.now().isAfter(deadline))
      throw StateError('Screenshot capture was not acknowledged');
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void safe(Object? value, {bool admin = false, bool claimant = true}) {
  if (value is Map) {
    final blocked = {
      'password_hash',
      'access_token',
      'email',
      'student_code',
      'user_id',
      'storage_key',
      'original_filename',
      'extracted_data',
      'private_feature',
      if (!admin) ...{
        'lost_private_feature',
        'found_private_feature',
        'admin_note'
      },
      if (!admin && !claimant) 'ownership_evidence'
    };
    for (final entry in value.entries) {
      if (blocked.contains(entry.key) && entry.value != null)
        throw StateError('Private workflow field leaked');
      safe(entry.value, admin: admin, claimant: claimant);
    }
  } else if (value is List) {
    for (final child in value) {
      safe(child, admin: admin, claimant: claimant);
    }
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'reclamación, revisión y chat reales; aprobación y rechazo privados',
      (tester) async {
    final fixture = File(fixturePath),
        marker = File('${fixture.parent.path}/ready_$fixtureRun');
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    while (!fixture.existsSync() || !marker.existsSync()) {
      if (DateTime.now().isAfter(deadline))
        throw StateError('Missing private E2E fixture');
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    final admin =
        jsonDecode(await fixture.readAsString()) as Map<String, dynamic>;
    await fixture.delete();
    final images = [
      for (final name in ['front.png', 'side.png'])
        ReportImageUpload(
            bytes: await File('${fixture.parent.path}/$name').readAsBytes(),
            filename: name,
            contentType: 'image/png')
    ];
    final run = fixtureRun, random = Random.secure();
    final password =
        base64UrlEncode(List.generate(32, (_) => random.nextInt(256)));
    final emails = [
      for (final label in ['a', 'b', 'c']) 'claims.$label.$run@example.com'
    ];
    final tokens = <String>[];
    for (var i = 0; i < 3; i++) {
      await previous
          .api('POST', ApiConstants.authRegisterPath, expected: 201, body: {
        'full_name': 'Comunidad ${['Alba', 'Bruno', 'Celia'][i]}',
        'email': emails[i],
        'student_code': 'CL$i$run',
        'password': password
      });
      tokens.add((await previous.api('POST', ApiConstants.authLoginPath,
              body: {'email': emails[i], 'password': password}))['access_token']
          as String);
    }
    final clients = <previous.DeviceApiClient>[];
    DependencyContainer makeDeps() {
      final client = previous.DeviceApiClient();
      clients.add(client);
      return DependencyContainer.create(
          client: client, analysisRepository: previous.SavedGeminiAnalysis());
    }

    var deps = makeDeps();
    await tester.pumpWidget(EncuentraUApp(dependencies: deps));
    Future<void> signIn(String email, String pass,
        {bool administrative = false}) async {
      if (deps.authController.isAuthenticated)
        await deps.authController.logout();
      await previous.waitFor(
          tester, () => find.byType(LoginPage).evaluate().isNotEmpty, 'login');
      await previous.text(tester, find.byType(TextFormField).at(0), email);
      await previous.text(tester, find.byType(TextFormField).at(1), pass);
      await previous.tap(tester, find.text(AppStrings.signIn));
      await previous.waitFor(
          tester,
          () =>
              deps.authController.isAuthenticated &&
              (administrative
                  ? find.byType(AdminAppShell).evaluate().isNotEmpty
                  : deps.objectController.status == LoadStatus.ready ||
                      deps.objectController.status == LoadStatus.empty),
          'role shell');
      expect(deps.authController.currentUser?.role,
          administrative ? UserRole.admin : UserRole.student);
    }

    void route(String path, String id) {
      Navigator.of(tester.element(find.byType(Scaffold).first))
          .pushNamed(path, arguments: id);
    }

    Future<void> openClaim(String id) async {
      route(AppRoutes.claimDetail, id);
      await previous.waitFor(
          tester,
          () =>
              deps.claimsController.detail?.id == id &&
              deps.claimsController.detailStatus == LoadStatus.ready,
          'claim detail');
    }

    Future<void> openChat(String id) async {
      route(AppRoutes.conversation, id);
      await previous.waitFor(
          tester,
          () =>
              find.byType(ChatPage).evaluate().isNotEmpty &&
              find.byKey(const Key('chat-message-input')).evaluate().isNotEmpty,
          'chat ready');
    }

    await signIn(emails[1], password);
    final location = 'Cafetería central $run';
    final found = await previous.createWithPhoto(
        tester, deps, ReportType.found, images[1], location);
    await signIn(emails[0], password);
    final lost = await previous.createWithPhoto(
        tester, deps, ReportType.lost, images[0], location);
    final matches = await previous.api(
        'POST', ApiConstants.generateMatchesPath(lost.id),
        token: tokens[0]);
    safe(matches);
    final target = (matches['items'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((m) => (m['candidate_report'] as Map)['id'] == found.id);
    final matchId = target['id'] as String;
    expect(target['level'], 'high');
    await previous.openMatch(tester, deps, matchId);
    await previous.waitFor(
        tester,
        () => find.text(AppStrings.claimThisObject).evaluate().isNotEmpty,
        'lost owner claim button');
    await screenshot(tester, 'STUDENT_MATCH');
    await previous.tap(tester, find.text(AppStrings.claimThisObject));
    expect(find.byType(ClaimFormPage), findsOneWidget);
    final evidence = 'PRIVATE_lost_$location';
    await previous.text(
        tester, find.byKey(const Key('ownership-evidence')), evidence);
    await previous.tap(tester, find.text(AppStrings.submitClaim));
    await previous.tap(tester, find.text(AppStrings.confirm));
    await previous.waitFor(
        tester,
        () =>
            find.byType(ClaimDetailPage).evaluate().isNotEmpty &&
            deps.claimsController.detail?.status == ClaimStatus.pending,
        'pending claim');
    final claimId = deps.claimsController.detail!.id;
    await screenshot(tester, 'CLAIM_PENDING');
    final duplicate = await previous.api(
        'POST', ApiConstants.submitClaimPath(matchId),
        token: tokens[0],
        body: {'ownership_evidence': evidence},
        expected: 201);
    expect(duplicate['id'], claimId);
    safe(duplicate);
    for (final token in tokens.take(2)) {
      final conversations = await previous
          .api('GET', ApiConstants.myConversationsPath, token: token);
      safe(conversations);
      expect(conversations['total'], 0);
    }
    final unknown = '00000000-0000-4000-8000-000000000000';
    await previous.api('GET', ApiConstants.conversationPath(unknown),
        token: tokens[0], expected: 404);
    await previous.api('GET', ApiConstants.claimPath(claimId),
        token: tokens[2], expected: 404);
    await previous.api('GET', ApiConstants.reportImageContentPath(lost.id),
        token: tokens[2], expected: 404);
    await previous.api('GET', ApiConstants.adminClaimsPath,
        token: tokens[0], expected: 403);
    final custodian = await previous.api('GET', ApiConstants.claimPath(claimId),
        token: tokens[1]);
    safe(custodian, claimant: false);
    expect(custodian['ownership_evidence'], isNull);
    await signIn(emails[1], password);
    await openClaim(claimId);
    expect(find.textContaining(evidence), findsNothing);
    expect(find.text(AppStrings.openChat), findsNothing);
    await screenshot(tester, 'CUSTODIAN_PENDING');
    await signIn(admin['email'] as String, admin['password'] as String,
        administrative: true);
    await screenshot(tester, 'ADMIN_DASHBOARD');
    route(AppRoutes.adminClaimDetail, claimId);
    await previous.waitFor(
        tester,
        () =>
            deps.adminClaimsController.detail?.id == claimId &&
            deps.adminClaimsController.detailStatus == LoadStatus.ready,
        'admin evidence');
    expect(find.text(evidence), findsWidgets);
    expect(deps.adminClaimsController.detail?.foundPrivateFeature,
        'PRIVATE_found_$location');
    final adminToken = (await previous.api('POST', ApiConstants.authLoginPath,
        body: {
          'email': admin['email'],
          'password': admin['password']
        }))['access_token'] as String;
    final adminDetail = await previous
        .api('GET', ApiConstants.adminClaimPath(claimId), token: adminToken);
    safe(adminDetail, admin: true);
    expect((adminDetail['match'] as Map)['factors'], hasLength(9));
    await screenshot(tester, 'ADMIN_PRIVATE_EVIDENCE');
    // Build the comparison lower in the lazy list and verify both private photos.
    await tester.scrollUntilVisible(find.byType(ScoreRing), 350,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    await previous.waitFor(
        tester,
        () =>
            find
                .byWidgetPredicate((w) => w is RawImage && w.image != null)
                .evaluate()
                .length >=
            2,
        'admin photographs');
    await screenshot(tester, 'ADMIN_COMPARISON');
    await tester.scrollUntilVisible(find.text(AppStrings.approveClaim), -350,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    await previous.tap(tester, find.text(AppStrings.approveClaim));
    await previous.tap(tester, find.text(AppStrings.confirm));
    await previous.waitFor(
        tester,
        () => deps.adminClaimsController.detail?.status == ClaimStatus.approved,
        'atomic approval');
    final approved = await previous.api('GET', ApiConstants.claimPath(claimId),
        token: tokens[0]);
    safe(approved);
    final conversationId = approved['conversation_id'] as String;
    expect((approved['match'] as Map)['status'], 'accepted');
    await previous.api('POST', ApiConstants.approveClaimPath(claimId),
        token: adminToken, body: {}, expected: 409);
    await previous.api('GET', ApiConstants.conversationPath(conversationId),
        token: adminToken, expected: 404);
    await previous.api('GET', ApiConstants.conversationPath(conversationId),
        token: tokens[2], expected: 404);
    await previous.api('POST', ApiConstants.messagesPath(conversationId),
        token: tokens[2],
        body: {'body': 'blocked', 'client_message_id': unknown},
        expected: 404);
    await signIn(emails[0], password);
    await openClaim(claimId);
    await previous.tap(tester, find.text(AppStrings.openChat));
    await previous.waitFor(
        tester,
        () => find.byKey(const Key('chat-message-input')).evaluate().isNotEmpty,
        'approved chat');
    await previous.text(tester, find.byKey(const Key('chat-message-input')),
        'Coordinemos la entrega en portería.');
    await previous.tap(tester, find.byKey(const Key('send-chat-message')));
    await previous.waitFor(
        tester,
        () => find
            .text('Coordinemos la entrega en portería.')
            .evaluate()
            .isNotEmpty,
        'A message');
    final unread = await previous.api(
        'GET', ApiConstants.conversationPath(conversationId),
        token: tokens[1]);
    safe(unread);
    expect(unread['unread_count'], 1);
    await signIn(emails[1], password);
    await openChat(conversationId);
    await previous.waitFor(
        tester,
        () => find
            .text('Coordinemos la entrega en portería.')
            .evaluate()
            .isNotEmpty,
        'B receives A');
    await previous.text(tester, find.byKey(const Key('chat-message-input')),
        'De acuerdo, nos vemos allí.');
    await previous.tap(tester, find.byKey(const Key('send-chat-message')));
    await previous.waitFor(
        tester,
        () => find.text('De acuerdo, nos vemos allí.').evaluate().isNotEmpty,
        'B reply');
    await screenshot(tester, 'CHAT_CUSTODIAN');
    // A second app client sends while B remains on screen: reception must be polling.
    final clientId = '00000000-0000-4000-8000-000000000001';
    final first = await previous.api(
        'POST', ApiConstants.messagesPath(conversationId),
        token: tokens[0],
        expected: 201,
        body: {
          'body': 'Mensaje recibido por polling.',
          'client_message_id': clientId
        });
    final retry = await previous.api(
        'POST', ApiConstants.messagesPath(conversationId),
        token: tokens[0],
        expected: 201,
        body: {
          'body': 'Mensaje recibido por polling.',
          'client_message_id': clientId
        });
    expect(first['id'], retry['id']);
    await previous.waitFor(
        tester,
        () => find.text('Mensaje recibido por polling.').evaluate().isNotEmpty,
        'polling reception');
    await tester.pump(const Duration(seconds: 1));
    final read = await previous.api(
        'GET', ApiConstants.conversationPath(conversationId),
        token: tokens[1]);
    expect(read['unread_count'], 0);
    await screenshot(tester, 'CHAT_POLLING');
    await signIn(emails[0], password);
    await openChat(conversationId);
    await previous.waitFor(
        tester,
        () => find.text('De acuerdo, nos vemos allí.').evaluate().isNotEmpty,
        'A receives reply');
    // Recreate the app with its real secure token storage and fetch persisted chat.
    await tester.pumpWidget(const SizedBox());
    deps.dispose();
    deps = makeDeps();
    await tester.pumpWidget(EncuentraUApp(dependencies: deps));
    await previous.waitFor(
        tester, () => deps.authController.isAuthenticated, 'restored session');
    await openChat(conversationId);
    await previous.waitFor(
        tester,
        () => find.text('De acuerdo, nos vemos allí.').evaluate().isNotEmpty,
        'persisted messages');
    await screenshot(tester, 'CHAT_RESTORED');
    final list = await previous.api('GET', ApiConstants.myConversationsPath,
        token: tokens[0]);
    safe(list);
    expect(list['total'], 1);
    final messages = await previous.api(
        'GET', ApiConstants.messagesPath(conversationId),
        token: tokens[0]);
    safe(messages);
    expect(messages['items'], hasLength(3));
    // A distinct persistent pair proves rejection never opens a conversation.
    final reportBody = {
      'object_type': 'audífonos de diadema',
      'category': 'electronica',
      'primary_color': 'negro',
      'secondary_colors': ['azul'],
      'shape': 'diadema arqueada',
      'description': 'Audífonos negros con detalles azules.',
      'location': 'Biblioteca $run',
      'event_date': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String()
          .substring(0, 10),
      'private_feature': 'Otra característica reservada'
    };
    final secondLost = await previous.api('POST', ApiConstants.reportsPath,
        token: tokens[0],
        expected: 201,
        body: {...reportBody, 'report_type': 'lost'});
    final secondFound = await previous.api('POST', ApiConstants.reportsPath,
        token: tokens[1],
        expected: 201,
        body: {...reportBody, 'report_type': 'found'});
    final generated = await previous.api(
        'POST', ApiConstants.generateMatchesPath(secondLost['id'] as String),
        token: tokens[0]);
    final secondMatch = (generated['items'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere(
            (m) => (m['candidate_report'] as Map)['id'] == secondFound['id']);
    final secondClaim = await previous.api(
        'POST', ApiConstants.submitClaimPath(secondMatch['id'] as String),
        token: tokens[0],
        expected: 201,
        body: {
          'ownership_evidence': 'Una característica distinta para revisión.'
        });
    await signIn(admin['email'] as String, admin['password'] as String,
        administrative: true);
    route(AppRoutes.adminClaimDetail, secondClaim['id'] as String);
    await previous.waitFor(
        tester,
        () =>
            deps.adminClaimsController.detail?.id == secondClaim['id'] &&
            deps.adminClaimsController.detailStatus == LoadStatus.ready,
        'second review');
    await previous.tap(tester, find.text(AppStrings.rejectClaim));
    await previous.text(tester, find.byKey(const Key('rejection-reason')),
        'La característica indicada no coincide.');
    await previous.tap(tester, find.text(AppStrings.confirm));
    await previous.waitFor(
        tester,
        () => deps.adminClaimsController.detail?.status == ClaimStatus.rejected,
        'rejected decision');
    await screenshot(tester, 'ADMIN_REJECTED');
    await signIn(emails[0], password);
    await openClaim(secondClaim['id'] as String);
    expect(find.textContaining('La característica indicada no coincide.'),
        findsOneWidget);
    expect(find.text(AppStrings.openChat), findsNothing);
    final rejected = await previous.api(
        'GET', ApiConstants.claimPath(secondClaim['id'] as String),
        token: tokens[0]);
    safe(rejected);
    expect(rejected['conversation_id'], isNull);
    expect((rejected['match'] as Map)['status'], 'rejected');
    await screenshot(tester, 'STUDENT_REJECTED');
    await deps.authController.logout();
    await previous.waitFor(
        tester, () => find.byType(LoginPage).evaluate().isNotEmpty, 'logout');
    expect(
        await Navigator.of(tester.element(find.byType(LoginPage))).maybePop(),
        isFalse);
    expect(deps.claimsController.detail, isNull);
    expect(deps.adminClaimsController.detail, isNull);
    expect(deps.conversationsController.items, isEmpty);
    final requests = [for (final client in clients) ...client.requests];
    print('CLAIMS_E2E_RESULT ${jsonEncode({
          'passed': true,
          'match_id': matchId,
          'claim_id': claimId,
          'conversation_id': conversationId,
          'rejected_claim_id': secondClaim['id'],
          'lost_report_id': lost.id,
          'found_report_id': found.id,
          'percentage': target['percentage'],
          'messages': 3,
          'idempotent_claim': true,
          'idempotent_message': true,
          'third_party_status': 404,
          'admin_chat_status': 404,
          'polling_received': true,
          'restored': true,
          'privacy': true,
          'gemini_calls': 0,
          'requests': requests
        })}');
    binding.reportData = {'claims_chat': 'passed'};
    await tester.pumpWidget(const SizedBox());
    deps.dispose();
    for (final client in clients) {
      client.close();
    }
  },
      skip: !Platform.isAndroid || fixturePath.isEmpty,
      timeout: const Timeout(Duration(minutes: 15)));
}
