import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../features/authentication/presentation/pages/login_page.dart';
import '../features/authentication/presentation/pages/register_page.dart';
import '../features/authentication/presentation/pages/session_page.dart';
import '../features/objects/domain/entities/object_report.dart';
import '../features/objects/presentation/pages/home_page.dart';
import '../features/objects/presentation/pages/objects_page.dart';
import '../features/objects/presentation/pages/register_object_page.dart';
import '../features/objects/presentation/pages/report_detail_page.dart';
import '../features/objects/presentation/pages/edit_report_page.dart';
import '../features/matching/presentation/pages/matches_page.dart';
import '../features/matching/presentation/pages/match_detail_page.dart';
import 'dependency_container.dart';
import 'routes.dart';

class EncuentraUApp extends StatefulWidget {
  const EncuentraUApp({required this.dependencies, super.key});
  final DependencyContainer dependencies;
  @override
  State<EncuentraUApp> createState() => _EncuentraUAppState();
}

class _EncuentraUAppState extends State<EncuentraUApp> {
  final _navigator = GlobalKey<NavigatorState>();
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
  Widget withId(BuildContext context, Widget Function(String) builder) {
    final id = ModalRoute.of(context)?.settings.arguments;
    return id is String && id.isNotEmpty
        ? builder(id)
        : const Scaffold(body: Center(child: Text(AppStrings.apiNotFound)));
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
          navigatorKey: _navigator,
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
            AppRoutes.home: (_) => protected(() => HomePage(
                controller: dependencies.objectController,
                authController: dependencies.authController)),
            AppRoutes.objects: (_) => protected(
                () => ObjectsPage(controller: dependencies.objectController)),
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
            AppRoutes.matches: (_) => protected(
                () => MatchesPage(controller: dependencies.matchController)),
            AppRoutes.matchDetail: (context) => protected(() => withId(
                context,
                (id) => MatchDetailPage(
                    matchId: id, controller: dependencies.matchController))),
          });
}
