import 'dart:async';
import 'package:encuentra_u/app/dependency_container.dart';
import 'package:encuentra_u/core/constants/api_constants.dart';
import 'package:encuentra_u/core/constants/app_strings.dart';
import 'package:encuentra_u/core/errors/api_exception.dart';
import 'package:encuentra_u/core/presentation/paged_controller.dart';
import 'package:encuentra_u/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:encuentra_u/features/objects/data/models/object_report_model.dart';
import 'package:encuentra_u/features/objects/domain/entities/object_report.dart';
import 'package:encuentra_u/features/objects/domain/entities/object_image_input.dart';
import 'package:encuentra_u/features/objects/domain/entities/report_page.dart';
import 'package:encuentra_u/features/objects/presentation/widgets/report_form_fields.dart';
import 'package:encuentra_u/features/objects/presentation/controllers/object_analysis_controller.dart';
import 'package:encuentra_u/features/matching/data/models/object_match_model.dart';
import 'package:encuentra_u/features/matching/domain/entities/match_page.dart';
import 'package:encuentra_u/features/matching/domain/entities/object_match.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import '../authentication/auth_test_support.dart';
import 'controller_support.dart';
import 'support.dart';

void main() {
  test('reportes reflejan loading, ready, empty, error y retry', () async {
    final repo = ReportRepositoryStub();
    final controller = objectController(repo);
    addTearDown(controller.dispose);
    final pending = Completer<ReportPage>();
    repo.onList = (_, __) => pending.future;
    final work = controller.refresh();
    expect(controller.status, LoadStatus.loading);
    pending.complete(ReportPage(
        items: [ObjectReportModel.fromJson(reportJson())],
        total: 1,
        limit: 20,
        offset: 0));
    await work;
    expect(controller.status, LoadStatus.ready);
    expect(controller.items, hasLength(1));
    repo.onList = (_, __) async => throw const ApiException(ApiFailure.server);
    await controller.refresh();
    expect(controller.status, LoadStatus.error);
    expect(controller.message, AppStrings.authServerError);
    repo.onList = (_, __) async =>
        const ReportPage(items: [], total: 0, limit: 20, offset: 0);
    await controller.refresh();
    expect(controller.status, LoadStatus.empty);
    expect(controller.items, isEmpty);
    expect(controller.message, isNull);
  });
  test('paginación agrega páginas y refresh reinicia offset', () async {
    final offsets = <int>[];
    final repo = ReportRepositoryStub();
    repo.onList = (limit, offset) async {
      offsets.add(offset);
      return ReportPage(
          items: [ObjectReportModel.fromJson(reportJson(id: 'report-$offset'))],
          total: 2,
          limit: limit,
          offset: offset);
    };
    final controller = objectController(repo);
    addTearDown(controller.dispose);
    await controller.refresh();
    expect(controller.hasMore, isTrue);
    await controller.loadMore();
    expect(controller.items, hasLength(2));
    expect(controller.hasMore, isFalse);
    await controller.refresh();
    expect(controller.items, hasLength(1));
    expect(offsets, [0, 1, 0]);
  });
  test(
      'crear devuelve UUID del servidor, editar conserva resultado y cancelar recarga detalle y lista',
      () async {
    final repo = ReportRepositoryStub();
    final controller = objectController(repo);
    addTearDown(controller.dispose);
    final created = await controller.register(draft());
    expect(created, isNotNull);
    expect(repo.creates, 1);
    expect(controller.items.single.id, created!.id);
    expect(controller.isSaving, isFalse);
    expect(
        await controller.update(created.id,
            const ObjectReportUpdate(description: 'Nueva descripción')),
        isTrue);
    expect(controller.detail!.description, 'Nueva descripción');
    expect(repo.updates, 1);
    expect(await controller.cancel(created.id), isTrue);
    expect(repo.cancels, 1);
    expect(controller.detail!.status, ReportStatus.cancelled);
    expect(controller.items.single.status, ReportStatus.cancelled);
  });
  test('detalle controla 404 y permite reintentar', () async {
    final repo = ReportRepositoryStub()
      ..onGet = (_) async => throw const ApiException(ApiFailure.notFound);
    final controller = objectController(repo);
    addTearDown(controller.dispose);
    await controller.loadDetail('report-test');
    expect(controller.detailStatus, LoadStatus.error);
    expect(controller.detailMessage, AppStrings.apiNotFound);
    repo.onGet = null;
    await controller.loadDetail('report-test');
    expect(controller.detailStatus, LoadStatus.ready);
    expect(controller.detail!.id, 'report-test');
  });
  test('una respuesta tardía no repuebla reportes después de limpiar sesión',
      () async {
    final pending = Completer<ReportPage>();
    final repo = ReportRepositoryStub()..onList = (_, __) => pending.future;
    final controller = objectController(repo);
    addTearDown(controller.dispose);
    final work = controller.refresh();
    controller.clear();
    pending.complete(ReportPage(
        items: [ObjectReportModel.fromJson(reportJson())],
        total: 1,
        limit: 20,
        offset: 0));
    await work;
    expect(controller.items, isEmpty);
    expect(controller.status, LoadStatus.initial);
    expect(controller.detail, isNull);
  });
  test('una búsqueda vieja no reemplaza filtros y resultados nuevos', () async {
    final pending = Completer<ReportPage>();
    final repo = ReportRepositoryStub()..onList = (_, __) => pending.future;
    final controller = objectController(repo);
    addTearDown(controller.dispose);
    final old = controller.refresh();
    repo.onList = (_, __) async =>
        const ReportPage(items: [], total: 0, limit: 20, offset: 0);
    await controller.setFilters(
        reportType: ReportType.found, status: ReportStatus.cancelled);
    pending.complete(ReportPage(
        items: [ObjectReportModel.fromJson(reportJson())],
        total: 1,
        limit: 20,
        offset: 0));
    await old;
    expect(controller.items, isEmpty);
    expect(controller.reportTypeFilter, ReportType.found);
    expect(controller.statusFilter, ReportStatus.cancelled);
  });
  test('coincidencias: loading, error, retry, filtros y generación cero válida',
      () async {
    final repo = MatchRepositoryStub();
    final controller = matchController(repo);
    addTearDown(controller.dispose);
    final pending = Completer<MatchPage>();
    repo.onList = (_, __) => pending.future;
    final work = controller.refresh();
    expect(controller.status, LoadStatus.loading);
    pending.complete(MatchPage(
        items: [ObjectMatchModel.fromJson(matchJson())],
        total: 1,
        limit: 20,
        offset: 0));
    await work;
    expect(controller.status, LoadStatus.ready);
    expect(controller.items.single.percentage, 91);
    repo.onList =
        (_, __) async => throw const ApiException(ApiFailure.connection);
    await controller.refresh();
    expect(controller.status, LoadStatus.error);
    repo.onList = (_, __) async =>
        const MatchPage(items: [], total: 0, limit: 20, offset: 0);
    await controller.setFilters(
        level: MatchLevel.possible, status: MatchStatus.pending);
    expect(controller.status, LoadStatus.empty);
    expect(controller.levelFilter, MatchLevel.possible);
    expect(controller.statusFilter, MatchStatus.pending);
    repo.onGenerate = (id) async => GeneratedMatches(reportId: id, items: []);
    final result = await controller.generate('report-test');
    expect(result, isNotNull);
    expect(result!.items, isEmpty);
    expect(controller.generationMessage, isNull);
    await controller.loadDetail(matchJson()['id'] as String);
    expect(controller.detail!.percentage, 91);
    controller.clear();
    expect(controller.items, isEmpty);
    expect(controller.detail, isNull);
    expect(controller.levelFilter, isNull);
  });
  test(
      'páginas y respuestas tardías de coincidencias respetan el cierre de sesión',
      () async {
    final pending = Completer<MatchPage>();
    final repo = MatchRepositoryStub()..onList = (_, __) => pending.future;
    final controller = matchController(repo);
    addTearDown(controller.dispose);
    final work = controller.refresh();
    controller.clear();
    pending.complete(MatchPage(
        items: [ObjectMatchModel.fromJson(matchJson())],
        total: 1,
        limit: 20,
        offset: 0));
    await work;
    expect(controller.items, isEmpty);
    expect(controller.status, LoadStatus.initial);
  });
  test(
      'los datos sugeridos se conservan y permiten corrección manual sin marca inventada',
      () {
    final form = ReportFormData();
    addTearDown(form.dispose);
    final value = draft(analysis: true).imageAnalysis!;
    form.applyAnalysis(value);
    expect(form.objectType.text, value.objectType);
    expect(form.category.text, 'electronica');
    expect(form.secondaryColors.text, 'azul');
    expect(form.shape.text, 'arqueada');
    form.objectType.text = 'Auriculares corregidos';
    final body = ReportCreateModel.toJson(form.draft(ReportType.lost, value));
    expect(body['object_type'], 'Auriculares corregidos');
    expect(body['brand'], isNull);
    expect(body['secondary_colors'], ['azul']);
  });
  for (final operation in ['logout', '401']) {
    test(
        '$operation limpia reportes, coincidencias, detalles y análisis de imagen',
        () async {
      var reject = false;
      final client = MockClient((request) async {
        if (request.url.path == ApiConstants.authMePath)
          return jsonResponse(userJson);
        if (request.url.path == ApiConstants.analyzeObjectImagePath)
          return jsonResponse(analysisJson);
        if (reject) return jsonResponse({'detail': 'not displayed'}, 401);
        if (request.url.path == ApiConstants.myReportsPath)
          return jsonResponse(pageJson([reportJson()]));
        if (request.url.path == ApiConstants.myMatchesPath)
          return jsonResponse(pageJson([matchJson()]));
        if (request.url.path.startsWith(ApiConstants.matchesPath))
          return jsonResponse(matchJson());
        return jsonResponse(reportJson());
      });
      final storage = MemoryTokenStorage(testToken);
      final deps =
          DependencyContainer.create(client: client, tokenStorage: storage);
      addTearDown(client.close);
      addTearDown(deps.dispose);
      await deps.authController.restoreSession();
      await deps.objectController.refresh();
      await deps.matchController.refresh();
      await deps.objectController.loadDetail(reportJson()['id'] as String);
      await deps.matchController.loadDetail(matchJson()['id'] as String);
      await deps.objectAnalysisController.analyze(const ObjectImageInput(
          bytes: [1, 2, 3],
          fileName: 'test-only.png',
          mimeType: 'image/png',
          description: 'Audífonos'));
      expect(deps.objectController.items, isNotEmpty);
      expect(deps.matchController.items, isNotEmpty);
      expect(deps.objectAnalysisController.hasAnalysis, isTrue);
      if (operation == 'logout') {
        await deps.authController.logout();
      } else {
        reject = true;
        await deps.objectController.loadDetail('rejected');
      }
      expect(deps.authController.status, AuthStatus.unauthenticated);
      expect(storage.token, isNull);
      expect(deps.objectController.items, isEmpty);
      expect(deps.objectController.detail, isNull);
      expect(deps.matchController.items, isEmpty);
      expect(deps.matchController.detail, isNull);
      expect(deps.objectAnalysisController.analysis, isNull);
      expect(
          deps.objectAnalysisController.status, ObjectAnalysisStatus.initial);
      expect(deps.objectController.status, LoadStatus.initial);
      expect(deps.matchController.status, LoadStatus.initial);
    });
  }
}
