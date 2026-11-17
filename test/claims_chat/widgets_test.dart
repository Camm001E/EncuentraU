import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:encuentra_u/app/app.dart';
import 'package:encuentra_u/app/admin_app_shell.dart';
import 'package:encuentra_u/app/app_shell.dart';
import 'package:encuentra_u/app/dependency_container.dart';
import 'package:encuentra_u/app/routes.dart';
import 'package:encuentra_u/core/constants/api_constants.dart';
import 'package:encuentra_u/core/constants/app_strings.dart';
import 'package:encuentra_u/core/domain/page.dart';
import 'package:encuentra_u/core/errors/api_exception.dart';
import 'package:encuentra_u/core/theme/app_theme.dart';
import 'package:encuentra_u/features/authentication/domain/entities/app_user.dart';
import 'package:encuentra_u/features/authentication/presentation/pages/login_page.dart';
import 'package:encuentra_u/features/claims/data/models/claim_model.dart';
import 'package:encuentra_u/features/claims/domain/entities/ownership_claim.dart';
import 'package:encuentra_u/features/claims/presentation/pages/claim_form_page.dart';
import 'package:encuentra_u/features/claims/presentation/pages/claim_detail_page.dart';
import 'package:encuentra_u/features/claims/presentation/pages/admin_claim_detail_page.dart';
import 'package:encuentra_u/features/claims/presentation/widgets/claim_widgets.dart';
import 'package:encuentra_u/features/claims/presentation/widgets/review_decision_dialog.dart';
import 'package:encuentra_u/features/messaging/presentation/pages/chat_page.dart';
import 'package:encuentra_u/features/messaging/presentation/pages/conversations_page.dart';
import 'package:encuentra_u/features/messaging/presentation/controllers/conversations_controller.dart';
import 'package:encuentra_u/features/messaging/domain/entities/conversation.dart';
import 'package:encuentra_u/features/messaging/domain/usecases/conversations.dart';
import 'package:encuentra_u/features/messaging/presentation/widgets/message_bubble.dart';
import '../authentication/auth_test_support.dart';
import '../premium/support.dart';
import '../remote/support.dart';
import 'support.dart';

Widget themed(Widget child, {Map<String, WidgetBuilder> routes = const {}}) =>
    MaterialApp(theme: AppTheme.light, home: child, routes: routes);
Future<void> surface(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> click(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f.first);
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      '401 borra reclamaciones, evidencia administrativa y mensajes abiertos',
      (tester) async {
    await surface(tester, const Size(1000, 1100));
    final auth = FakeAuthRepository()..onRestore = () async => testUser;
    final claims = TestClaims(), convos = TestConversations();
    var expired = false;
    final client = MockClient((_) async =>
        jsonResponse(expired ? {} : pageJson([]), expired ? 401 : 200));
    addTearDown(client.close);
    final deps = DependencyContainer.create(
        client: client,
        tokenStorage: MemoryTokenStorage(testToken),
        authRepository: auth,
        dashboardRepository: TestDashboardRepository(),
        claimRepository: claims,
        adminClaimRepository: claims,
        conversationRepository: convos);
    addTearDown(deps.dispose);
    await tester.pumpWidget(EncuentraUApp(dependencies: deps));
    await tester.pumpAndSettle();
    await deps.claimsController.loadDetail('claim-1');
    await deps.adminClaimsController.loadDetail('claim-1');
    final chat = deps.createChatController();
    await chat.open('conversation-1');
    chat.setVisible(true);
    await tester.pump();
    expect(chat.messages, isNotEmpty);
    expired = true;
    await deps.objectController.refresh();
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(deps.claimsController.detail, isNull);
    expect(deps.adminClaimsController.detail, isNull);
    expect(chat.messages, isEmpty);
    expect(chat.isPolling, isFalse);
    expect(deps.conversationsController.items, isEmpty);
    deps.releaseChatController(chat);
  });
  testWidgets(
      'conversaciones vacías, error y reintento muestran datos del servidor',
      (tester) async {
    final repo = TestConversations()
      ..onInbox = () async =>
          const Page<Conversation>(items: [], total: 0, limit: 20, offset: 0);
    final c = ConversationsController(ListConversations(repo));
    addTearDown(c.dispose);
    final observer = RouteObserver<ModalRoute<dynamic>>();
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        navigatorObservers: [observer],
        home: ConversationsPage(controller: c, observer: observer)));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.noConversations), findsOneWidget);
    repo.error = const ApiException(ApiFailure.server);
    await c.refresh();
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.retry), findsOneWidget);
    repo.error = null;
    repo.onInbox = null;
    await click(tester, find.text(AppStrings.retry));
    expect(find.text('Persona'), findsOneWidget);
    expect(find.text(AppStrings.unreadMessages(1)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('chat móvil horizontal con texto ampliado y teclado no desborda',
      (tester) async {
    await surface(tester, const Size(768, 360));
    final repo = TestConversations(), c = chatController(repo);
    addTearDown(c.dispose);
    final observer = RouteObserver<ModalRoute<dynamic>>();
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        navigatorObservers: [observer],
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(2),
                viewInsets: const EdgeInsets.only(bottom: 180)),
            child: child!),
        home: ChatPage(
            conversationId: 'conversation-1',
            createController: () => c,
            releaseController: (_) {},
            observer: observer)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-message-input')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'formulario valida, confirma y abre la reclamación real sin doble envío',
      (tester) async {
    await surface(tester, const Size(390, 844));
    final repo = TestClaims();
    final controller = claimsController(repo);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
        themed(ClaimFormPage(matchId: 'm', controller: controller), routes: {
      AppRoutes.claimDetail: (_) =>
          const Scaffold(body: Text('detail-destination'))
    }));
    await click(tester, find.text(AppStrings.submitClaim));
    expect(find.text(AppStrings.evidenceValidation), findsOneWidget);
    expect(repo.submitted, 0);
    final input = find.byKey(const Key('ownership-evidence'));
    await tester.ensureVisible(input);
    await tester.enterText(input, 'Una marca blanca en la copa izquierda.');
    await click(tester, find.text(AppStrings.submitClaim));
    expect(find.text(AppStrings.submitClaimConfirmation), findsOneWidget);
    expect(repo.submitted, 0);
    await click(tester, find.text(AppStrings.confirm));
    expect(repo.submitted, 1);
    expect(find.text('detail-destination'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('custodio ve pendiente y nunca la respuesta privada',
      (tester) async {
    final repo = TestClaims()
      ..value = ClaimModel.fromJson(claimJson(relationship: 'custodian'));
    final c = claimsController(repo);
    addTearDown(c.dispose);
    await tester
        .pumpWidget(themed(ClaimDetailPage(claimId: 'claim-1', controller: c)));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.custodianPending), findsOneWidget);
    expect(find.textContaining('Una marca blanca'), findsNothing);
    expect(find.text(AppStrings.openChat), findsNothing);
    expect(find.text(AppStrings.approveClaim), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final status in ClaimStatus.values) {
    testWidgets('panel ${status.name} habilita chat únicamente aprobado',
        (tester) async {
      await tester.pumpWidget(themed(Scaffold(
          body: ClaimStatePanel(
              claim: ClaimModel.fromJson(claimJson(status: status.name))))));
      expect(find.text(AppStrings.openChat),
          status == ClaimStatus.approved ? findsOneWidget : findsNothing);
      if (status == ClaimStatus.rejected)
        expect(find.textContaining('El detalle no coincide.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('rechazar exige motivo y devuelve nota interna por separado',
      (tester) async {
    await surface(tester, const Size(390, 844));
    ReviewDecision? result;
    await tester.pumpWidget(themed(Scaffold(
        body: Builder(
            builder: (context) => FilledButton(
                onPressed: () async {
                  result = await showDialog<ReviewDecision>(
                      context: context,
                      builder: (_) =>
                          const ReviewDecisionDialog(approve: false));
                },
                child: const Text('open'))))));
    await click(tester, find.text('open'));
    await click(tester, find.text(AppStrings.confirm));
    expect(find.text(AppStrings.reviewReasonValidation), findsOneWidget);
    expect(result, isNull);
    await tester.enterText(
        find.byKey(const Key('rejection-reason')), 'La marca no coincide.');
    FocusManager.instance.primaryFocus?.unfocus();
    await click(tester, find.text(AppStrings.confirm));
    expect(result?.reason, 'La marca no coincide.');
    expect(result?.note, isNull);
  });
  testWidgets(
      'revisión administrativa muestra evidencia y decisión transaccional',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await surface(tester, const Size(768, 1200));
    final repo = TestClaims();
    final controller = adminController(repo);
    addTearDown(controller.dispose);
    await tester.pumpWidget(themed(
        AdminClaimDetailPage(claimId: 'claim-1', controller: controller)));
    await tester.pumpAndSettle();
    expect(find.text('Detalle privado perdido'), findsOneWidget);
    expect(find.text('Detalle privado encontrado'), findsOneWidget);
    expect(
        find.bySemanticsLabel(AppStrings.privateEvidenceSemantics(
            AppStrings.claimantAnswer, repo.admin.ownershipEvidence!)),
        findsOneWidget);
    await click(tester, find.text(AppStrings.approveClaim));
    await click(tester, find.text(AppStrings.confirm));
    expect(repo.approved, 1);
    expect(controller.detail?.status, ClaimStatus.approved);
    expect(find.text(AppStrings.openChat), findsNothing);
    semantics.dispose();
  });
  for (final width in [360.0, 390.0, 768.0, 1200.0]) {
    testWidgets(
        'tarjeta y burbuja accesibles ancho $width, texto ampliado y movimiento reducido',
        (tester) async {
      await surface(tester, Size(width, 1000));
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
              data: MediaQueryData(
                  size: Size(width, 1000),
                  textScaler: TextScaler.linear(2),
                  disableAnimations: true),
              child: Scaffold(
                  body: SingleChildScrollView(
                      child: Column(children: [
                ClaimCard(claim: ClaimModel.fromJson(claimJson())),
                MessageBubble(
                    message: ConversationModelForTest.message(),
                    otherName: 'Persona')
              ]))))));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.noReportPhoto), findsOneWidget);
      expect(find.byType(MessageBubble), findsOneWidget);
      expect(tester.takeException(), isNull);
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel(RegExp('.*Mensaje.*')), findsWidgets);
      semantics.dispose();
    });
  }
  testWidgets(
      'chat detiene polling cuando otra ruta lo cubre y en segundo plano',
      (tester) async {
    await surface(tester, const Size(390, 844));
    final repo = TestConversations(), c = chatController(repo);
    addTearDown(c.dispose);
    final observer = RouteObserver<ModalRoute<dynamic>>();
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        navigatorObservers: [observer],
        home: ChatPage(
            conversationId: 'conversation-1',
            createController: () => c,
            releaseController: (_) {},
            observer: observer)));
    await tester.pumpAndSettle();
    expect(c.isPolling, isTrue);
    expect(find.byType(MessageBubble), findsOneWidget);
    Navigator.of(tester.element(find.byType(ChatPage))).push(MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('covered'))));
    await tester.pumpAndSettle();
    expect(c.isPolling, isFalse);
    Navigator.of(tester.element(find.text('covered'))).pop();
    await tester.pumpAndSettle();
    expect(c.isPolling, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(c.isPolling, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(c.isPolling, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(c.isPolling, isFalse);
  });
  for (final admin in [false, true]) {
    testWidgets(
        'RBAC ${admin ? 'admin' : 'student'} y limpieza global del chat por logout',
        (tester) async {
      await surface(tester, const Size(1200, 1100));
      final user = AppUser(
          id: testUser.id,
          fullName: testUser.fullName,
          email: testUser.email,
          studentCode: testUser.studentCode,
          role: admin ? UserRole.admin : UserRole.student,
          isActive: true);
      final auth = FakeAuthRepository()..onRestore = () async => user;
      final claims = TestClaims(), convos = TestConversations();
      var adminCalls = 0;
      final client = MockClient((r) async {
        if (r.url.path.startsWith(ApiConstants.adminClaimsPath)) adminCalls++;
        return jsonResponse(pageJson([]));
      });
      addTearDown(client.close);
      final deps = DependencyContainer.create(
          client: client,
          tokenStorage: MemoryTokenStorage(testToken),
          authRepository: auth,
          dashboardRepository: TestDashboardRepository(),
          claimRepository: claims,
          adminClaimRepository: claims,
          conversationRepository: convos);
      addTearDown(deps.dispose);
      await tester.pumpWidget(EncuentraUApp(dependencies: deps));
      await tester.pumpAndSettle();
      expect(find.byType(AdminAppShell), admin ? findsOneWidget : findsNothing);
      expect(find.byType(AppShell), admin ? findsNothing : findsOneWidget);
      if (!admin) {
        Navigator.of(tester.element(find.byType(AppShell)))
            .pushNamed(AppRoutes.adminClaims);
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.permissionDenied), findsOneWidget);
        expect(adminCalls, 0);
      }
      final chat = deps.createChatController();
      await chat.open('conversation-1');
      chat.setVisible(true);
      await tester.pump();
      expect(chat.messages, isNotEmpty);
      await deps.authController.logout();
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      expect(chat.messages, isEmpty);
      expect(chat.isPolling, isFalse);
      expect(deps.claimsController.items, isEmpty);
      expect(deps.adminClaimsController.detail, isNull);
      expect(deps.conversationsController.items, isEmpty);
      deps.releaseChatController(chat);
      expect(tester.takeException(), isNull);
    });
  }
}

// Keep a long plain-text body in layout tests; HTML is never interpreted.
abstract final class ConversationModelForTest {
  static dynamic message() => TestConversations().items.single;
}
