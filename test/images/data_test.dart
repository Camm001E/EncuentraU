import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:encuentra_u/core/cache/image_byte_cache.dart';
import 'package:encuentra_u/core/constants/api_constants.dart';
import 'package:encuentra_u/core/errors/api_exception.dart';
import 'package:encuentra_u/core/network/authenticated_api_client.dart';
import 'package:encuentra_u/core/session/session_manager.dart';
import 'package:encuentra_u/features/objects/data/datasources/report_image_remote_data_source.dart';
import 'package:encuentra_u/features/objects/data/models/object_report_model.dart';
import 'package:encuentra_u/features/objects/data/models/report_image_model.dart';
import 'package:encuentra_u/features/objects/data/repositories/report_image_repository_impl.dart';
import 'package:encuentra_u/features/objects/domain/usecases/report_images.dart';
import 'package:encuentra_u/features/matching/data/models/object_match_model.dart';
import '../authentication/auth_test_support.dart';
import '../remote/support.dart';
import 'support.dart';

void main() {
  test('referencia y respuestas con y sin imagen conservan privacidad', () {
    final json = imageJson()
      ..addAll(
          {'storage_key': 'internal', 'original_filename': 'private-name.png'});
    final image = ReportImageModel.fromJson(json);
    expect(image.reportId, reportJson()['id']);
    expect(image.width, 3);
    expect(image.version, contains(image.sha256));
    expect(ObjectReportModel.fromJson(reportJson()..['image'] = json).image?.id,
        image.id);
    expect(ObjectReportModel.fromJson(reportJson()).image, isNull);
    final match = matchJson();
    match['candidate_report']['image'] =
        imageJson(reportId: match['candidate_report']['id']);
    expect(ObjectMatchModel.fromJson(match).candidateReport.image?.sha256,
        image.sha256);
    expect(ObjectMatchModel.fromJson(match).percentage, 91);
  });
  for (final bad in [
    {'sha256': 'bad'},
    {'width': 0},
    {'size_bytes': -1},
    {'content_type': 'text/html'}
  ]) {
    test('rechaza metadatos inválidos: ${bad.keys.first}', () {
      expect(() => ReportImageModel.fromJson(imageJson()..addAll(bad)),
          throwsFormatException);
    });
  }
  test('multipart, metadata, bytes y DELETE usan Bearer y rutas centralizadas',
      () async {
    final storage = MemoryTokenStorage(testToken);
    final session = SessionManager(storage);
    addTearDown(session.dispose);
    final seen = <String>[];
    final client = MockClient((request) async {
      expect(request.headers[ApiConstants.authorizationHeader],
          'Bearer $testToken');
      seen.add(request.method);
      if (request.method == 'PUT') {
        expect(
            request.url.path, ApiConstants.reportImagePath(reportJson()['id']));
        expect(request.headers['content-type'],
            startsWith('multipart/form-data; boundary='));
        final multipart = latin1.decode(request.bodyBytes);
        expect(multipart, contains('name="image"; filename="unit.png"'));
        expect(multipart, contains('content-type: image/png'));
        expect(multipart, isNot(contains('private_feature')));
        return jsonResponse(imageJson());
      }
      if (request.method == 'DELETE') return http.Response('', 204);
      if (request.url.path.endsWith('/content'))
        return http.Response.bytes(png, 200,
            headers: {'content-type': 'image/png'});
      return jsonResponse(imageJson());
    });
    addTearDown(client.close);
    final repo = ReportImageRepositoryImpl(ReportImageRemoteDataSource(
        AuthenticatedApiClient(client: client, session: session)));
    final id = imageReference().reportId;
    expect((await UploadReportImage(repo)(id, uploadInput())).id, 'image-id');
    expect((await GetReportImage(repo)(id)).contentType, 'image/png');
    expect(await DownloadReportImage(repo)(id), png);
    await DeleteReportImage(repo)(id);
    expect(seen, ['PUT', 'GET', 'GET', 'DELETE']);
  });
  for (final entry in {
    401: ApiFailure.unauthorized,
    403: ApiFailure.forbidden,
    404: ApiFailure.notFound,
    409: ApiFailure.conflict,
    413: ApiFailure.imageTooLarge,
    415: ApiFailure.unsupportedImage,
    422: ApiFailure.invalidData,
    500: ApiFailure.server
  }.entries) {
    test('transferencias mapean HTTP ${entry.key} sin exponer cuerpo',
        () async {
      final storage = MemoryTokenStorage(testToken);
      final session = SessionManager(storage);
      final client = MockClient(
          (_) async => http.Response('internal private error', entry.key));
      addTearDown(session.dispose);
      addTearDown(client.close);
      final api = AuthenticatedApiClient(client: client, session: session);
      await expectLater(
          api.downloadImage('/photo'),
          throwsA(isA<ApiException>()
              .having((e) => e.failure, 'failure', entry.value)));
      if (entry.key == 401 || entry.key == 403) expect(storage.token, isNull);
    });
  }
  test('token ausente no envía multipart', () async {
    final session = SessionManager(MemoryTokenStorage());
    addTearDown(session.dispose);
    final client = MockClient((_) => throw StateError('must not call server'));
    addTearDown(client.close);
    await expectLater(
        AuthenticatedApiClient(client: client, session: session)
            .uploadImage('/photo', png, 'unit.png', 'image/png'),
        throwsA(isA<ApiException>()));
  });
  test('descarga rechaza HTML y respeta timeout', () async {
    final session = SessionManager(MemoryTokenStorage(testToken));
    addTearDown(session.dispose);
    final html = MockClient((_) async => http.Response('html', 200));
    final waiting = Completer<http.Response>();
    final slow = MockClient((_) => waiting.future);
    addTearDown(html.close);
    addTearDown(slow.close);
    await expectLater(
        AuthenticatedApiClient(client: html, session: session)
            .downloadImage('/photo'),
        throwsA(isA<ApiException>()
            .having((e) => e.failure, 'failure', ApiFailure.invalidResponse)));
    await expectLater(
        AuthenticatedApiClient(
                client: slow,
                session: session,
                transferTimeout: const Duration(milliseconds: 1))
            .downloadImage('/photo'),
        throwsA(isA<ApiException>()
            .having((e) => e.failure, 'failure', ApiFailure.timeout)));
    waiting.complete(http.Response.bytes(png, 200));
  });
  test('caché LRU limita bytes y entradas, copia datos y limpia por reporte',
      () {
    final cache = ImageByteCache(maxBytes: 4, maxEntries: 2);
    final bytes = Uint8List.fromList([1, 2]);
    cache.put('a:one', bytes);
    bytes[0] = 9;
    cache.put('b:one', Uint8List.fromList([3, 4]));
    expect(cache.get('a:one'), [1, 2]);
    cache.put('c:one', Uint8List.fromList([5, 6]));
    expect(cache.get('b:one'), isNull);
    expect(cache.bytes, 4);
    cache.removeReport('a');
    expect(cache.bytes, 2);
    cache.put('too-big', Uint8List(5));
    expect(cache.length, 1);
    cache.clear();
    expect(cache.bytes, 0);
  });
}
