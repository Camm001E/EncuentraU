import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:encuentra_u/app/app.dart';
import 'package:encuentra_u/app/app_shell.dart';
import 'package:encuentra_u/app/dependency_container.dart';
import 'package:encuentra_u/core/constants/api_constants.dart';
import 'package:encuentra_u/core/constants/app_strings.dart';
import 'package:encuentra_u/core/errors/api_exception.dart';
import 'package:encuentra_u/core/presentation/paged_controller.dart';
import 'package:encuentra_u/features/authentication/presentation/pages/login_page.dart';
import 'package:encuentra_u/features/authentication/presentation/pages/profile_page.dart';
import 'package:encuentra_u/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:encuentra_u/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:encuentra_u/features/dashboard/domain/usecases/get_dashboard_summary.dart';
import 'package:encuentra_u/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:encuentra_u/features/objects/presentation/pages/objects_page.dart';
import 'package:encuentra_u/features/matching/presentation/pages/matches_page.dart';
import '../authentication/auth_test_support.dart';
import '../remote/support.dart';
import '../remote/widgets_test.dart' as remote;

class ControlledDashboard implements DashboardRepository {
  late Future<DashboardSummary> Function() read;
  @override
  Future<DashboardSummary> getSummary() => read();
}

void main() {
  test(
      'dashboard muestra error, reintenta y descarta respuestas tras cerrar sesión',
      () async {
    final repo = ControlledDashboard()
      ..read = () => Future.error(const ApiException(ApiFailure.server));
    final controller = DashboardController(GetDashboardSummary(repo));
    addTearDown(controller.dispose);
    await controller.refresh();
    expect(controller.status, LoadStatus.error);
    final pending = Completer<DashboardSummary>();
    repo.read = () => pending.future;
    final task = controller.refresh();
    expect(controller.status, LoadStatus.loading);
    controller.clear();
    pending.complete(const DashboardSummary(
        activeReports: 99, lostReports: 99, foundReports: 99, matches: 99));
    await task;
    expect(controller.summary, isNull);
    expect(controller.status, LoadStatus.initial);
    repo.read = () async => const DashboardSummary(
        activeReports: 3, lostReports: 2, foundReports: 1, matches: 4);
    await controller.refresh();
    expect(controller.status, LoadStatus.ready);
    expect(controller.summary!.matches, 4);
  });
  testWidgets('Inicio usa totales HTTP, incluso si solo se descarga una fila',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final queries = <Map<String, String>>[];
    final client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer $testToken');
      if (request.url.path == ApiConstants.authMePath)
        return jsonResponse(userJson);
      final query = request.url.queryParameters;
      if (request.url.path == ApiConstants.myDeliveriesPath)
        return jsonResponse({...pageJson([]), 'limit': 1});
      if (query['limit'] == '1') {
        queries.add(query);
        final total = request.url.path == ApiConstants.myMatchesPath
            ? 47
            : query['status'] == 'active'
                ? 31
                : query['report_type'] == 'lost'
                    ? 22
                    : 19;
        return jsonResponse({...pageJson([]), 'total': total, 'limit': 1});
      }
      return jsonResponse(pageJson([]));
    });
    final deps = DependencyContainer.create(
        client: client, tokenStorage: MemoryTokenStorage(testToken));
    addTearDown(client.close);
    addTearDown(deps.dispose);
    await tester.pumpWidget(EncuentraUApp(dependencies: deps));
    await tester.pumpAndSettle();
    expect(queries, hasLength(4));
    expect(find.text(AppStrings.greeting(testUser.fullName)), findsOneWidget);
    for (final count in ['31', '22', '19', '47'])
      expect(find.text(count), findsOneWidget);
  });
  testWidgets('cuatro pestañas móviles, perfil real y logout sin historial',
      (tester) async {
    final deps = await remote.start(
        tester, (_) async => jsonResponse(pageJson([])),
        size: const Size(390, 1100));
    expect(find.byType(NavigationBar), findsOneWidget);
    for (final target in [
      (1, ObjectsPage),
      (2, MatchesPage),
      (3, ProfilePage)
    ]) {
      await tester.tap(find.byType(NavigationDestination).at(target.$1));
      await tester.pumpAndSettle();
      expect(tester.state<AppShellState>(find.byType(AppShell)).selectedIndex,
          target.$1);
      expect(find.byType(target.$2), findsOneWidget);
    }
    expect(find.text(testUser.email), findsOneWidget);
    expect(find.text(testUser.studentCode), findsOneWidget);
    await tester.tap(find.text(AppStrings.signOut));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(deps.dashboardController.summary, isNull);
    expect(
        Navigator.of(tester.element(find.byType(LoginPage))).canPop(), isFalse);
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets(
        'horizontal con texto $scale mantiene navegación y perfil accesibles',
        (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await remote.start(tester, (_) async => jsonResponse(pageJson([])),
          size: const Size(844, 390));
      expect(find.byType(NavigationRail), findsOneWidget);
      tester.state<AppShellState>(find.byType(AppShell)).selectTab(3);
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final width in [360.0, 390.0, 768.0, 1280.0]) {
    testWidgets('shell adaptativo y texto ampliado a $width', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await remote.start(tester, (_) async => jsonResponse(pageJson([])),
          size: Size(width, 1200));
      expect(find.byType(width >= 760 ? NavigationRail : NavigationBar),
          findsOneWidget);
      tester.state<AppShellState>(find.byType(AppShell)).selectTab(3);
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
