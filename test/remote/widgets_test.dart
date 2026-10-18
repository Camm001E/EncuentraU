import '../premium/support.dart';
import 'dart:async';
import 'dart:convert';
import 'package:encuentra_u/app/app.dart';
import 'package:encuentra_u/app/dependency_container.dart';
import 'package:encuentra_u/app/routes.dart';
import 'package:encuentra_u/core/constants/api_constants.dart';
import 'package:encuentra_u/core/constants/app_strings.dart';
import 'package:encuentra_u/features/authentication/presentation/pages/login_page.dart';
import 'package:encuentra_u/features/objects/presentation/pages/home_page.dart';
import 'package:encuentra_u/features/objects/presentation/pages/register_object_page.dart';
import 'package:encuentra_u/features/objects/presentation/pages/report_detail_page.dart';
import 'package:encuentra_u/features/matching/presentation/pages/matches_page.dart';
import 'package:encuentra_u/features/matching/presentation/widgets/match_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../authentication/auth_test_support.dart';
import 'support.dart';
import 'package:encuentra_u/features/matching/data/models/object_match_model.dart';

Future<DependencyContainer> start(
    WidgetTester tester, Future<http.Response> Function(http.Request) handler,
    {Size size = const Size(1000, 1200)}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final client = MockClient((request) async {
    if (request.url.path == ApiConstants.authMePath)
      return jsonResponse(userJson);
    return handler(request);
  });
  final deps = DependencyContainer.create(
      dashboardRepository: TestDashboardRepository(),
      client: client,
      tokenStorage: MemoryTokenStorage(testToken));
  addTearDown(client.close);
  addTearDown(deps.dispose);
  await tester.pumpWidget(EncuentraUApp(dependencies: deps));
  await tester.pumpAndSettle();
  return deps;
}

void navigate(WidgetTester tester, String route, {Object? arguments}) {
  Navigator.of(tester.element(find.byType(HomePage)))
      .pushNamed(route, arguments: arguments);
}

Future<void> fillReport(WidgetTester tester) async {
  for (final entry in {
    'object-type': 'Audífonos de diadema',
    'category': 'electronica',
    'description': 'Audífonos negros con detalles azules',
    'primary-color': 'negro',
    'secondary-colors': 'azul',
    'shape': 'arqueada',
    'location': 'Cafetería central'
  }.entries) {
    final field = find.byKey(ValueKey('report-${entry.key}'));
    await tester.ensureVisible(field);
    await tester.enterText(field, entry.value);
  }
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(AppStrings.registerReport));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'Home no carga antes de autenticar y muestra reportes del servidor después',
      (tester) async {
    final pending = Completer<http.Response>();
    var reportCalls = 0;
    final client = MockClient((request) async {
      if (request.url.path == ApiConstants.authMePath) return pending.future;
      reportCalls++;
      expect(request.url.path, ApiConstants.myReportsPath);
      return jsonResponse(pageJson([reportJson()]));
    });
    final deps = DependencyContainer.create(
        dashboardRepository: TestDashboardRepository(),
        client: client,
        tokenStorage: MemoryTokenStorage(testToken));
    addTearDown(client.close);
    addTearDown(deps.dispose);
    await tester.pumpWidget(EncuentraUApp(dependencies: deps));
    await tester.pump();
    expect(reportCalls, 0);
    expect(find.text(AppStrings.restoringSession), findsOneWidget);
    pending.complete(jsonResponse(userJson));
    await tester.pumpAndSettle();
    expect(reportCalls, 1);
    await tester.scrollUntilVisible(find.text('audífonos de diadema'), 300,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('audífonos de diadema'), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);
  });
  testWidgets(
      'reporte guardado se conserva si falla generate y el reintento no repite POST reports',
      (tester) async {
    var reports = 0, generations = 0;
    final id = reportJson()['id'] as String;
    final deps = await start(tester, (request) async {
      if (request.url.path == ApiConstants.reportsPath &&
          request.method == 'POST') {
        reports++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['object_type'], 'Audífonos de diadema');
        expect(body['category'], 'electronica');
        expect(body['brand'], isNull);
        expect(body['secondary_colors'], ['azul']);
        expect(body['shape'], 'arqueada');
        expect(body.containsKey('id'), isFalse);
        expect(body.containsKey('image'), isFalse);
        expect(body.containsKey('analysis'), isFalse);
        expect(body['event_date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
        return jsonResponse(reportJson(), 201);
      }
      if (request.url.path == ApiConstants.myReportsPath)
        return jsonResponse(pageJson(reports == 0 ? [] : [reportJson()]));
      if (request.url.path == ApiConstants.generateMatchesPath(id)) {
        generations++;
        if (generations == 1) return jsonResponse({'detail': 'internal'}, 503);
        return jsonResponse({'report_id': id, 'total': 0, 'items': []});
      }
      if (request.url.path == ApiConstants.myMatchesPath)
        return jsonResponse(pageJson([]));
      return jsonResponse(reportJson());
    });
    navigate(tester, AppRoutes.registerLost);
    await tester.pumpAndSettle();
    expect(find.byType(RegisterObjectPage), findsOneWidget);
    await fillReport(tester);
    await tester.tap(find.text(AppStrings.registerReport));
    await tester.pumpAndSettle();
    expect(reports, 1);
    expect(generations, 1);
    expect(deps.objectController.detail!.id, id);
    expect(find.byType(ReportDetailPage), findsOneWidget);
    expect(find.text(AppStrings.reportSavedMatchesFailed), findsOneWidget);
    final retry = find.text(AppStrings.searchMatches);
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(reports, 1);
    expect(generations, 2);
    expect(find.byType(MatchesPage), findsOneWidget);
    expect(find.text(AppStrings.noMatches), findsOneWidget);
  });
  testWidgets('registro exitoso abre Coincidencias que consulta GET matches me',
      (tester) async {
    var created = 0, generated = 0, listed = 0;
    final fixture = matchJson();
    final id = reportJson()['id'] as String;
    await start(tester, (request) async {
      if (request.url.path == ApiConstants.reportsPath) {
        created++;
        return jsonResponse(reportJson(), 201);
      }
      if (request.url.path == ApiConstants.myReportsPath)
        return jsonResponse(pageJson([]));
      if (request.url.path == ApiConstants.generateMatchesPath(id)) {
        generated++;
        return jsonResponse({
          'report_id': id,
          'total': 1,
          'items': [fixture]
        });
      }
      expect(request.url.path, ApiConstants.myMatchesPath);
      expect(request.method, 'GET');
      listed++;
      return jsonResponse(pageJson([fixture]));
    });
    navigate(tester, AppRoutes.registerFound);
    await tester.pumpAndSettle();
    await fillReport(tester);
    await tester.tap(find.text(AppStrings.registerReport));
    await tester.pumpAndSettle();
    expect(created, 1);
    expect(generated, 1);
    expect(listed, 1);
    expect(find.byType(MatchesPage), findsOneWidget);
    expect(find.text('91%'), findsOneWidget);
    expect(
        find.text(
            '${AppStrings.evidenceCoverage}: ${fixture['evidence_coverage']}%'),
        findsOneWidget);
  });
  testWidgets('coincidencias muestra error, reintenta y admite resultado vacío',
      (tester) async {
    var fail = true;
    await start(tester, (request) async {
      if (request.url.path == ApiConstants.myReportsPath)
        return jsonResponse(pageJson([]));
      expect(request.url.path, ApiConstants.myMatchesPath);
      return fail
          ? jsonResponse({'detail': 'internal'}, 500)
          : jsonResponse(pageJson([]));
    });
    navigate(tester, AppRoutes.matches);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.authServerError), findsOneWidget);
    fail = false;
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.noMatches), findsOneWidget);
  });
  for (final state in ['resolved', 'cancelled']) {
    testWidgets('reporte $state deshabilita editar, cancelar y generar',
        (tester) async {
      await start(
          tester,
          (request) async => request.url.path == ApiConstants.myReportsPath
              ? jsonResponse(pageJson([]))
              : jsonResponse(reportJson(status: state)));
      navigate(tester, AppRoutes.reportDetail, arguments: reportJson()['id']);
      await tester.pumpAndSettle();
      for (final label in [
        AppStrings.editReport,
        AppStrings.cancelReport,
        AppStrings.searchMatches
      ]) {
        final button = find
            .ancestor(
                of: find.text(label),
                matching: find
                    .byWidgetPredicate((widget) => widget is ButtonStyleButton))
            .first;
        expect(tester.widget<ButtonStyleButton>(button).onPressed, isNull);
      }
      expect(find.text(AppStrings.reportReadOnly), findsOneWidget);
    });
  }
  testWidgets('cancelar solicita confirmación y recarga estado del servidor',
      (tester) async {
    var cancelled = false, deletes = 0;
    await start(tester, (request) async {
      if (request.method == 'DELETE') {
        deletes++;
        cancelled = true;
        return http.Response('', 204);
      }
      if (request.url.path == ApiConstants.myReportsPath)
        return jsonResponse(
            pageJson([reportJson(status: cancelled ? 'cancelled' : 'active')]));
      return jsonResponse(
          reportJson(status: cancelled ? 'cancelled' : 'active'));
    });
    navigate(tester, AppRoutes.reportDetail, arguments: reportJson()['id']);
    await tester.pumpAndSettle();
    final cancel = find.text(AppStrings.cancelReport);
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(deletes, 0);
    expect(find.text(AppStrings.cancelConfirmation), findsOneWidget);
    await tester.tap(find.text(AppStrings.confirm));
    await tester.pumpAndSettle();
    expect(deletes, 1);
    expect(find.text(AppStrings.cancelled), findsOneWidget);
    expect(find.text(AppStrings.reportReadOnly), findsOneWidget);
  });
  testWidgets(
      '401 en una pantalla protegida borra datos y navegación autenticada',
      (tester) async {
    final deps = await start(
        tester,
        (request) async => request.url.path == ApiConstants.myReportsPath
            ? jsonResponse(pageJson([reportJson()]))
            : jsonResponse({}, 401));
    expect(deps.objectController.items, isNotEmpty);
    navigate(tester, AppRoutes.matches);
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    expect(find.byType(MatchesPage), findsNothing);
    expect(deps.objectController.items, isEmpty);
    expect(deps.matchController.items, isEmpty);
    expect(
        Navigator.of(tester.element(find.byType(LoginPage))).canPop(), isFalse);
    expect(find.text(AppStrings.sessionExpired), findsOneWidget);
  });

  testWidgets(
      'edición usa PATCH y vuelve al detalle con el resultado persistido',
      (tester) async {
    var patches = 0;
    var description = reportJson()['description'] as String;
    await start(tester, (request) async {
      if (request.method == 'PATCH') {
        patches++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('id'), isFalse);
        expect(body.containsKey('report_type'), isFalse);
        expect(body.containsKey('analysis'), isFalse);
        expect(body['brand'], isNull);
        description = body['description'] as String;
      }
      final report = {...reportJson(), 'description': description};
      return request.url.path == ApiConstants.myReportsPath
          ? jsonResponse(pageJson([report]))
          : jsonResponse(report);
    });
    navigate(tester, AppRoutes.reportDetail, arguments: reportJson()['id']);
    await tester.pumpAndSettle();
    final edit = find.text(AppStrings.editReport);
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('report-description'));
    await tester.ensureVisible(field);
    await tester.enterText(field, 'Descripción editada desde Flutter');
    final save = find.text(AppStrings.saveChanges);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(patches, 1);
    expect(find.byType(ReportDetailPage), findsOneWidget);
    expect(find.text('Descripción editada desde Flutter'), findsOneWidget);
  });

  testWidgets('detalle móvil muestra métricas remotas y expande nueve factores',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: MatchCard(
                    match: ObjectMatchModel.fromJson(matchJson()),
                    detail: true)))));
    expect(find.text('91%'), findsOneWidget);
    expect(find.text(AppStrings.highMatch), findsOneWidget);
    final expand = find.text(AppStrings.evidenceFactors);
    await tester.ensureVisible(expand);
    await tester.tap(expand);
    await tester.pumpAndSettle();
    expect(find.byType(ExpansionTile), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
