import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:encuentra_u/app/dependency_container.dart';
import 'package:encuentra_u/core/constants/api_constants.dart';
import 'package:encuentra_u/core/errors/api_exception.dart';
import 'package:encuentra_u/features/objects/domain/entities/report_image.dart';
import '../authentication/auth_test_support.dart';
import '../remote/support.dart';
import 'support.dart';

void main() {
  test('descargas concurrentes se agrupan y reutilizan caché', () async {
    final wait = Completer<Uint8List>();
    final repo = ImageRepositoryStub()..onDownload = () => wait.future;
    final controller = imageController(repo);
    addTearDown(controller.dispose);
    final one = controller.content(imageReference());
    final two = controller.content(imageReference());
    expect(repo.downloads, 1);
    wait.complete(png);
    expect(await one, png);
    expect(await two, png);
    expect(await controller.content(imageReference()), png);
    expect(repo.downloads, 1);
    expect(controller.cache.bytes, png.length);
  });
  test('subida evita dobles envíos, invalida caché y permite reintento',
      () async {
    final waiting = Completer<ReportImageReference>();
    final repo = ImageRepositoryStub()..onUpload = () => waiting.future;
    final controller = imageController(repo);
    addTearDown(controller.dispose);
    final id = imageReference().reportId;
    await controller.content(imageReference());
    final first = controller.upload(id, uploadInput());
    expect(controller.isBusy(id), true);
    expect(await controller.upload(id, uploadInput()), isNull);
    waiting.completeError(const ApiException(ApiFailure.server));
    expect(await first, isNull);
    expect(controller.message(id), isNotNull);
    expect(controller.isBusy(id), false);
    repo.onUpload = () async => imageReference();
    expect(await controller.upload(id, uploadInput()), isNotNull);
    expect(repo.uploads, 2);
    expect(controller.cache.bytes, 0);
    expect(controller.message(id), isNull);
    expect(await controller.metadata(id), isNotNull);
    expect(await controller.delete(id), true);
    expect(repo.deletes, 1);
  });
  test('cerrar sesión descarta descarga tardía y no repuebla caché', () async {
    final waiting = Completer<Uint8List>();
    final repo = ImageRepositoryStub()..onDownload = () => waiting.future;
    final controller = imageController(repo);
    addTearDown(controller.dispose);
    final pending = controller.content(imageReference());
    final rejected = expectLater(pending, throwsA(isA<ApiException>()));
    controller.clear();
    waiting.complete(png);
    await rejected;
    expect(controller.cache.bytes, 0);
    await expectLater(
        controller.content(imageReference()), throwsA(isA<ApiException>()));
    controller.activate();
    repo.onDownload = () async => png;
    expect(await controller.content(imageReference()), png);
  });
  for (final expiry in [false, true]) {
    test(
        'composición limpia fotografías al ${expiry ? 'recibir 401' : 'cerrar sesión'}',
        () async {
      var rejected = false;
      final client = MockClient((request) async {
        if (request.url.path == ApiConstants.authMePath)
          return jsonResponse(userJson);
        if (rejected) return http.Response('', 401);
        return http.Response.bytes(png, 200,
            headers: {'content-type': 'image/png'});
      });
      final storage = MemoryTokenStorage(testToken);
      final deps =
          DependencyContainer.create(client: client, tokenStorage: storage);
      addTearDown(deps.dispose);
      addTearDown(client.close);
      await deps.authController.restoreSession();
      await deps.reportImageController.content(imageReference());
      expect(deps.reportImageController.cache.length, 1);
      if (expiry) {
        deps.reportImageController.invalidate(imageReference().reportId);
        rejected = true;
        await expectLater(deps.reportImageController.content(imageReference()),
            throwsA(isA<ApiException>()));
      } else {
        await deps.authController.logout();
      }
      expect(deps.reportImageController.cache.bytes, 0);
      expect(deps.authController.isAuthenticated, false);
      expect(storage.token, isNull);
    });
  }
}
