import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../features/authentication/presentation/pages/login_page.dart';
import '../features/authentication/presentation/pages/register_page.dart';
import '../features/authentication/presentation/pages/session_page.dart';
import '../features/matching/presentation/pages/matches_page.dart';
import '../features/objects/domain/entities/object_report.dart';
import '../features/objects/presentation/pages/home_page.dart';
import '../features/objects/presentation/pages/objects_page.dart';
import '../features/objects/presentation/pages/register_object_page.dart';
import 'dependency_container.dart';
import 'routes.dart';

class EncuentraUApp extends StatelessWidget {
  const EncuentraUApp({
    required this.dependencies,
    super.key,
  });

  final DependencyContainer dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.session,
      routes: {
        AppRoutes.session: (_) =>
            SessionPage(controller: dependencies.authController),
        AppRoutes.login: (_) =>
            LoginPage(controller: dependencies.authController),
        AppRoutes.register: (_) => RegisterPage(
              controller: dependencies.authController,
            ),
        AppRoutes.home: (_) => _protected(() => HomePage(
              controller: dependencies.objectController,
              authController: dependencies.authController,
            )),
        AppRoutes.registerLost: (_) => _protected(() => RegisterObjectPage(
              type: ReportType.lost,
              controller: dependencies.objectController,
              analysisController: dependencies.objectAnalysisController,
            )),
        AppRoutes.registerFound: (_) => _protected(() => RegisterObjectPage(
              type: ReportType.found,
              controller: dependencies.objectController,
              analysisController: dependencies.objectAnalysisController,
            )),
        AppRoutes.objects: (_) => _protected(() => ObjectsPage(
              controller: dependencies.objectController,
            )),
        AppRoutes.matches: (_) => _protected(() => MatchesPage(
              controller: dependencies.objectController,
              findMatches: dependencies.findMatches,
            )),
      },
    );
  }

  Widget _protected(Widget Function() builder) => AnimatedBuilder(
        animation: dependencies.authController,
        builder: (_, __) => dependencies.authController.isAuthenticated
            ? builder()
            : LoginPage(controller: dependencies.authController),
      );
}
