import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../features/authentication/presentation/pages/login_page.dart';
import '../features/authentication/presentation/pages/register_page.dart';
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
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.register: (_) => RegisterPage(
              controller: dependencies.authController,
            ),
        AppRoutes.home: (_) => HomePage(
              controller: dependencies.objectController,
            ),
        AppRoutes.registerLost: (_) => RegisterObjectPage(
              type: ReportType.lost,
              controller: dependencies.objectController,
              analysisController: dependencies.objectAnalysisController,
            ),
        AppRoutes.registerFound: (_) => RegisterObjectPage(
              type: ReportType.found,
              controller: dependencies.objectController,
              analysisController: dependencies.objectAnalysisController,
            ),
        AppRoutes.objects: (_) => ObjectsPage(
              controller: dependencies.objectController,
            ),
        AppRoutes.matches: (_) => MatchesPage(
              controller: dependencies.objectController,
              findMatches: dependencies.findMatches,
            ),
      },
    );
  }
}
