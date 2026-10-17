import 'dart:async';
import 'package:encuentra_u/core/constants/app_strings.dart';
import 'package:encuentra_u/features/objects/data/datasources/object_analysis_remote_datasource.dart';
import 'package:encuentra_u/features/objects/data/repositories/object_analysis_repository_impl.dart';
import 'package:encuentra_u/features/objects/domain/entities/object_image_input.dart';
import 'package:encuentra_u/features/objects/domain/usecases/analyze_object_image.dart';
import 'package:encuentra_u/features/objects/presentation/controllers/object_analysis_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'support.dart';

const input = ObjectImageInput(
    bytes: [1, 2, 3],
    fileName: 'fixture-only.png',
    mimeType: 'image/png',
    description: 'Audífonos negros');
void main() {
  test('análisis de imagen conserva multipart, contrato y sugerencias',
      () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.headers['content-type'], contains('multipart/form-data'));
      expect(request.body, contains('fixture-only.png'));
      expect(request.body, contains('description'));
      return jsonResponse(analysisJson);
    });
    addTearDown(client.close);
    final controller = ObjectAnalysisController(AnalyzeObjectImage(
        ObjectAnalysisRepositoryImpl(
            ObjectAnalysisRemoteDataSource(client: client))));
    addTearDown(controller.dispose);
    expect(await controller.analyze(input), isTrue);
    expect(controller.analysis!.secondaryColors, ['azul']);
    expect(controller.analysis!.brand, isNull);
    expect(controller.status, ObjectAnalysisStatus.success);
  });
  for (final status in [413, 415, 500]) {
    test('análisis HTTP $status no expone el cuerpo técnico', () async {
      final client = MockClient((_) async => jsonResponse(
          {'detail': '<html>private-internal-details</html>'}, status));
      addTearDown(client.close);
      final controller = ObjectAnalysisController(AnalyzeObjectImage(
          ObjectAnalysisRepositoryImpl(
              ObjectAnalysisRemoteDataSource(client: client))));
      addTearDown(controller.dispose);
      expect(await controller.analyze(input), isFalse);
      expect(
          controller.message,
          {
            413: AppStrings.imageTooLarge,
            415: AppStrings.unsupportedImage,
            500: AppStrings.analysisUnavailable
          }[status]);
      expect(controller.message, isNot(contains('private-internal-details')));
    });
  }
  test('reset descarta un análisis tardío de la sesión anterior', () async {
    final pending = Completer<http.Response>();
    final client = MockClient((_) => pending.future);
    addTearDown(client.close);
    final controller = ObjectAnalysisController(AnalyzeObjectImage(
        ObjectAnalysisRepositoryImpl(
            ObjectAnalysisRemoteDataSource(client: client))));
    addTearDown(controller.dispose);
    final work = controller.analyze(input);
    controller.reset();
    pending.complete(jsonResponse(analysisJson));
    expect(await work, isFalse);
    expect(controller.analysis, isNull);
    expect(controller.status, ObjectAnalysisStatus.initial);
  });
}
