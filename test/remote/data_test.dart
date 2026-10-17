import 'dart:convert';
import 'package:encuentra_u/core/constants/api_constants.dart';
import 'package:encuentra_u/core/errors/api_exception.dart';
import 'package:encuentra_u/core/network/authenticated_api_client.dart';
import 'package:encuentra_u/core/session/session_manager.dart';
import 'package:encuentra_u/features/objects/data/models/object_report_model.dart';
import 'package:encuentra_u/features/objects/data/datasources/object_report_remote_data_source.dart';
import 'package:encuentra_u/features/objects/data/repositories/object_repository_impl.dart';
import 'package:encuentra_u/features/objects/domain/entities/object_report.dart';
import 'package:encuentra_u/features/matching/data/models/object_match_model.dart';
import 'package:encuentra_u/features/matching/data/datasources/match_remote_data_source.dart';
import 'package:encuentra_u/features/matching/data/repositories/match_repository_impl.dart';
import 'package:encuentra_u/features/matching/domain/entities/object_match.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../authentication/auth_test_support.dart';
import 'support.dart';

AuthenticatedApiClient api(http.Client client) {
  final session = SessionManager(MemoryTokenStorage(testToken));
  addTearDown(client.close);
  addTearDown(session.dispose);
  return AuthenticatedApiClient(client: client, session: session);
}

void main() {
  test('deserializa el caso E2E de 91% y nueve factores sin calcular valores',
      () {
    final match = ObjectMatchModel.fromJson(matchJson());
    expect(match.percentage, 91);
    expect(match.level, MatchLevel.high);
    expect(match.compatible, isTrue);
    expect(match.identityPercentage, 88.27);
    expect(match.contextPercentage, 100);
    expect(match.evidenceCoverage, 92);
    expect(match.status, MatchStatus.pending);
    expect(match.factors, hasLength(9));
    expect(match.factors.map((f) => f.name).toSet(), {
      'object_type',
      'category',
      'color',
      'brand',
      'shape',
      'visual_features',
      'description',
      'location',
      'date'
    });
    expect(match.factors.where((f) => f.group == MatchFactorGroup.context),
        hasLength(2));
    expect(match.factors.singleWhere((f) => f.name == 'brand').status,
        MatchFactorStatus.unknown);
    expect(match.myReport.reportType, ReportType.lost);
    expect(match.candidateReport.reportType, ReportType.found);
    expect(match.updatedAt.isAfter(match.createdAt), isTrue);
  });
  for (final withAnalysis in [false, true]) {
    test(
        'creación serializa exclusivamente campos permitidos, análisis=$withAnalysis',
        () {
      final body = ReportCreateModel.toJson(draft(analysis: withAnalysis));
      expect(body.keys.toSet(), {
        'report_type',
        'object_type',
        'category',
        'primary_color',
        'secondary_colors',
        'brand',
        'shape',
        'description',
        'location',
        'event_date',
        'private_feature',
        if (withAnalysis) 'analysis'
      });
      expect(body['event_date'], '2026-10-17');
      expect(body['brand'], isNull);
      expect(body['secondary_colors'], ['azul']);
      if (withAnalysis)
        expect(body['analysis'],
            {'extracted_data': analysisJson, 'confidence': 'alta'});
      const forbidden = {
        'bytes',
        'base64',
        'file_name',
        'fileName',
        'path',
        'XFile',
        'token',
        'access_token',
        'user_id',
        'id',
        'status',
        'provider',
        'model'
      };
      void checkKeys(dynamic value) {
        if (value is Map) {
          expect(value.keys.toSet().intersection(forbidden), isEmpty);
          value.values.forEach(checkKeys);
        }
        if (value is List) value.forEach(checkKeys);
      }

      checkKeys(body);
    });
  }
  test('edición distingue omitir de borrar y no acepta campos inmutables', () {
    expect(
        ReportUpdateModel.toJson(const ObjectReportUpdate(
            description: ' Actualizada ', brand: FieldUpdate(null))),
        {'description': 'Actualizada', 'brand': null});
    expect(ReportUpdateModel.toJson(const ObjectReportUpdate()), isEmpty);
  });
  for (final state in ReportStatus.values) {
    test('deserializa estado ${state.name} con atributos y análisis propios',
        () {
      final report = ObjectReportModel.fromJson(
          reportJson(status: state.name, analysis: true));
      expect(report.status, state);
      expect(report.reportType, ReportType.lost);
      expect(report.objectType, 'audífonos de diadema');
      expect(report.category, 'electronica');
      expect(report.primaryColor, 'negro');
      expect(report.secondaryColors, ['azul']);
      expect(report.brand, isNull);
      expect(report.shape, 'arqueada');
      expect(report.privateFeature, 'Detalle privado de prueba');
      expect(report.imageAnalysis!.extractedData, analysisJson);
      expect(report.imageAnalysis!.provider, 'gemini');
      expect(report.createdAt.isUtc, isTrue);
    });
  }
  for (final field in [
    'status',
    'report_type',
    'event_date',
    'secondary_colors',
    'object_type'
  ]) {
    test('reporte rechaza tipo inválido en $field', () {
      final json = reportJson();
      json[field] = 123;
      expect(() => ObjectReportModel.fromJson(json), throwsFormatException);
    });
  }
  test(
      'resúmenes de coincidencia ignoran datos privados ajenos incluso si el servidor los agrega',
      () {
    final json = matchJson();
    (json['candidate_report'] as Map<String, dynamic>).addAll({
      'user_id': 'foreign-id',
      'email': 'foreign@example.com',
      'student_code': 'PRIVATE',
      'private_feature': 'hidden',
      'password_hash': 'hidden',
      'extracted_data': {'secret': true}
    });
    final match = ObjectMatchModel.fromJson(json);
    expect(match.candidateReport.id, (json['candidate_report'] as Map)['id']);
    expect(match.candidateReport.toString(), isNot(contains('hidden')));
    expect(() => (match.candidateReport as dynamic).privateFeature,
        throwsNoSuchMethodError);
    expect(() => (match.candidateReport as dynamic).userId,
        throwsNoSuchMethodError);
    expect(() => (match as dynamic).extractedData, throwsNoSuchMethodError);
    expect(() => (match as dynamic).accessToken, throwsNoSuchMethodError);
  });
  for (final field in [
    'percentage',
    'identity_percentage',
    'context_percentage',
    'evidence_coverage',
    'level',
    'compatible'
  ]) {
    test('no corrige ni calcula métricas inválidas en $field', () {
      final json = matchJson();
      json[field] = field == 'level'
          ? 'invented'
          : field == 'compatible'
              ? 1
              : 101;
      expect(() => ObjectMatchModel.fromJson(json), throwsFormatException);
    });
  }
  test('CRUD usa Bearer, JSON, filtros, detalle, PATCH parcial y DELETE 204',
      () async {
    final seen = <http.Request>[];
    final remote = ObjectRepositoryImpl(
        ObjectReportRemoteDataSource(api(MockClient((request) async {
      seen.add(request);
      expect(request.headers['authorization'], 'Bearer $testToken');
      if (request.method == 'DELETE') return http.Response('', 204);
      if (request.url.path == ApiConstants.myReportsPath)
        return jsonResponse(
            pageJson([reportJson()], total: 3, limit: 1, offset: 1));
      return jsonResponse(reportJson(), request.method == 'POST' ? 201 : 200);
    }))));
    final created = await remote.createReport(draft(analysis: true));
    expect(jsonDecode(seen.last.body),
        ReportCreateModel.toJson(draft(analysis: true)));
    final page = await remote.getMyReports(
        limit: 1,
        offset: 1,
        reportType: ReportType.lost,
        status: ReportStatus.active);
    expect(page.total, 3);
    expect(page.limit, 1);
    expect(page.offset, 1);
    expect(page.items, hasLength(1));
    expect(seen.last.url.queryParameters, {
      'limit': '1',
      'offset': '1',
      'report_type': 'lost',
      'status': 'active'
    });
    expect((await remote.getMyReport(created.id)).id, created.id);
    await remote.updateReport(
        created.id, const ObjectReportUpdate(brand: FieldUpdate(null)));
    expect(jsonDecode(seen.last.body), {'brand': null});
    await remote.cancelReport(created.id);
    expect(
        seen.map((r) => r.method), ['POST', 'GET', 'GET', 'PATCH', 'DELETE']);
    expect(seen.first.url.path, ApiConstants.reportsPath);
    expect(seen.last.url.path, ApiConstants.reportPath(created.id));
  });
  test(
      'coincidencias usa Bearer, generación, filtros, página y detalle remotos',
      () async {
    final seen = <http.Request>[];
    final fixture = matchJson();
    final id = fixture['id'] as String;
    final reportId = (fixture['my_report'] as Map)['id'] as String;
    final remote = MatchRepositoryImpl(
        MatchRemoteDataSource(api(MockClient((request) async {
      seen.add(request);
      expect(request.headers['authorization'], 'Bearer $testToken');
      if (request.method == 'POST')
        return jsonResponse({
          'report_id': reportId,
          'total': 1,
          'items': [fixture]
        });
      if (request.url.path == ApiConstants.myMatchesPath)
        return jsonResponse(pageJson([fixture], total: 4, limit: 1, offset: 2));
      return jsonResponse(fixture);
    }))));
    expect(
        (await remote.generateReportMatches(reportId)).items.single.percentage,
        91);
    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, ApiConstants.generateMatchesPath(reportId));
    expect(seen.last.body, isEmpty);
    final page = await remote.getMyMatches(
        limit: 1,
        offset: 2,
        level: MatchLevel.high,
        status: MatchStatus.pending);
    expect(page.total, 4);
    expect(page.offset, 2);
    expect(seen.last.url.queryParameters,
        {'limit': '1', 'offset': '2', 'level': 'high', 'status': 'pending'});
    expect((await remote.getMyMatch(id)).id, id);
    expect(seen.last.url.path, ApiConstants.matchPath(id));
  });
  test('generar cero coincidencias es éxito', () async {
    final remote = MatchRepositoryImpl(MatchRemoteDataSource(api(MockClient(
        (_) async => jsonResponse(
            {'report_id': 'report-test', 'total': 0, 'items': []})))));
    expect((await remote.generateReportMatches('report-test')).items, isEmpty);
  });
  test(
      'contrato JSON incorrecto en repositorio se convierte en error controlado',
      () async {
    final remote = ObjectRepositoryImpl(ObjectReportRemoteDataSource(
        api(MockClient((_) async => jsonResponse({})))));
    await expectLater(
        remote.getMyReport('report-test'),
        throwsA(isA<ApiException>()
            .having((e) => e.failure, 'failure', ApiFailure.invalidResponse)));
  });
}
