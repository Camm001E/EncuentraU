import '../features/objects/presentation/widgets/report_image_scope.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../features/authentication/presentation/pages/login_page.dart';
import '../features/authentication/presentation/pages/register_page.dart';
import '../features/authentication/presentation/pages/session_page.dart';
import '../features/objects/domain/entities/object_report.dart';
import '../features/objects/presentation/pages/register_object_page.dart';
import '../features/objects/presentation/pages/report_detail_page.dart';
import '../features/objects/presentation/pages/edit_report_page.dart';
import '../features/matching/presentation/pages/match_detail_page.dart';
import 'dependency_container.dart';
import 'routes.dart';
import 'app_shell.dart';
import 'admin_app_shell.dart';
import '../features/authentication/domain/entities/app_user.dart';
import '../core/presentation/widgets/load_feedback.dart';
import '../features/claims/presentation/pages/claims_page.dart';
import '../features/claims/presentation/pages/claim_form_page.dart';
import '../features/claims/presentation/pages/claim_detail_page.dart';
import '../features/claims/presentation/pages/admin_claims_page.dart';
import '../features/claims/presentation/pages/admin_claim_detail_page.dart';
import '../features/messaging/presentation/pages/conversations_page.dart';
import '../features/messaging/presentation/pages/chat_page.dart';

class EncuentraUApp extends StatefulWidget {
  const EncuentraUApp({required this.dependencies, super.key});
  final DependencyContainer dependencies;
  @override
  State<EncuentraUApp> createState() => _EncuentraUAppState();
}

class _EncuentraUAppState extends State<EncuentraUApp> {
  final _navigator = GlobalKey<NavigatorState>();
  final _routeObserver = RouteObserver<ModalRoute<dynamic>>();
  bool _hadSession = false;
  DependencyContainer get dependencies => widget.dependencies;
  @override
  void initState() {
    super.initState();
    _hadSession = dependencies.authController.isAuthenticated;
    dependencies.authController.addListener(_authChanged);
  }

  void _authChanged() {
    final authenticated = dependencies.authController.isAuthenticated;
    if (_hadSession && !authenticated)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !dependencies.authController.isAuthenticated)
          _navigator.currentState
              ?.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
      });
    _hadSession = authenticated;
  }

  @override
  void dispose() {
    dependencies.authController.removeListener(_authChanged);
    super.dispose();
  }

  Widget protected(Widget Function() builder) => AnimatedBuilder(
      animation: dependencies.authController,
      builder: (_, __) => dependencies.authController.isAuthenticated
          ? builder()
          : LoginPage(controller: dependencies.authController));
  bool get isAdmin =>
      dependencies.authController.currentUser?.role == UserRole.admin;
  Widget adminProtected(Widget Function() builder) => protected(() => isAdmin
      ? builder()
      : const Scaffold(
          body: LoadFeedback(message: AppStrings.permissionDenied)));
  Widget shell(int index) => isAdmin
      ? AdminAppShell(
          auth: dependencies.authController,
          claims: dependencies.adminClaimsController,
          summary: dependencies.adminSummaryController,
          initialIndex: index == 3 ? 2 : 0)
      : AppShell(
          objects: dependencies.objectController,
          auth: dependencies.authController,
          matches: dependencies.matchController,
          dashboard: dependencies.dashboardController,
          conversations: dependencies.conversationsController,
          initialIndex: index);
  Widget withId(BuildContext context, Widget Function(String) builder) {
    final id = ModalRoute.of(context)?.settings.arguments;
    return id is String && id.isNotEmpty
        ? builder(id)
        : const Scaffold(body: Center(child: Text(AppStrings.apiNotFound)));
  }

  @override
  Widget build(BuildContext context) => ReportImageScope(
      controller: dependencies.reportImageController,
      child: MaterialApp(
          navigatorKey: _navigator,
          navigatorObservers: [_routeObserver],
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          initialRoute: AppRoutes.session,
          routes: {
            AppRoutes.session: (_) =>
                SessionPage(controller: dependencies.authController),
            AppRoutes.login: (_) =>
                LoginPage(controller: dependencies.authController),
            AppRoutes.register: (_) =>
                RegisterPage(controller: dependencies.authController),
            AppRoutes.home: (_) => protected(() => shell(0)),
            AppRoutes.objects: (_) => protected(() => shell(1)),
            AppRoutes.profile: (_) => protected(() => shell(3)),
            AppRoutes.registerLost: (_) => protected(() => RegisterObjectPage(
                type: ReportType.lost,
                controller: dependencies.objectController,
                analysisController: dependencies.objectAnalysisController,
                matchController: dependencies.matchController)),
            AppRoutes.registerFound: (_) => protected(() => RegisterObjectPage(
                type: ReportType.found,
                controller: dependencies.objectController,
                analysisController: dependencies.objectAnalysisController,
                matchController: dependencies.matchController)),
            AppRoutes.reportDetail: (context) => protected(() => withId(
                context,
                (id) => ReportDetailPage(
                    reportId: id,
                    controller: dependencies.objectController,
                    matchController: dependencies.matchController))),
            AppRoutes.editReport: (context) => protected(() => withId(
                context,
                (id) => EditReportPage(
                    reportId: id, controller: dependencies.objectController))),
            AppRoutes.matches: (_) => protected(() => shell(2)),
            AppRoutes.matchDetail: (context) => protected(() => withId(
                context,
                (id) => MatchDetailPage(
                    matchId: id,
                    controller: dependencies.matchController,
                    claimsController: dependencies.claimsController))),
            AppRoutes.claims: (_) => protected(
                () => ClaimsPage(controller: dependencies.claimsController)),
            AppRoutes.submitClaim: (context) => protected(() => withId(
                context,
                (id) => ClaimFormPage(
                    matchId: id, controller: dependencies.claimsController))),
            AppRoutes.claimDetail: (context) => protected(() => withId(
                context,
                (id) => ClaimDetailPage(
                    claimId: id, controller: dependencies.claimsController))),
            AppRoutes.adminClaims: (_) => adminProtected(() => AdminClaimsPage(
                controller: dependencies.adminClaimsController)),
            AppRoutes.adminClaimDetail: (context) => adminProtected(() =>
                withId(
                    context,
                    (id) => AdminClaimDetailPage(
                        claimId: id,
                        controller: dependencies.adminClaimsController))),
            AppRoutes.conversations: (_) => protected(() => ConversationsPage(
                controller: dependencies.conversationsController,
                observer: _routeObserver)),
            AppRoutes.conversation: (context) => protected(() => withId(
                context,
                (id) => ChatPage(
                    conversationId: id,
                    createController: dependencies.createChatController,
                    releaseController: dependencies.releaseChatController,
                    observer: _routeObserver))),
          }));
}
