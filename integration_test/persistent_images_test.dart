// Opt-in device test. Real photos are supplied on the device, never committed.
// All auth/report/image/match traffic goes to the real API. Prior Gemini output
// is replayed through its domain port to avoid new provider calls.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:encuentra_u/app/app.dart';
import 'package:encuentra_u/app/dependency_container.dart';
import 'package:encuentra_u/app/routes.dart';
import 'package:encuentra_u/core/constants/api_constants.dart';
import 'package:encuentra_u/core/constants/app_strings.dart';
import 'package:encuentra_u/core/presentation/paged_controller.dart';
import 'package:encuentra_u/features/authentication/presentation/pages/login_page.dart';
import 'package:encuentra_u/features/objects/domain/entities/object_image_analysis.dart';
import 'package:encuentra_u/features/objects/domain/entities/object_image_input.dart';
import 'package:encuentra_u/features/objects/domain/entities/object_report.dart';
import 'package:encuentra_u/features/objects/domain/entities/report_image.dart';
import 'package:encuentra_u/features/objects/domain/repositories/object_analysis_repository.dart';
import 'package:encuentra_u/features/objects/presentation/pages/home_page.dart';
import 'package:encuentra_u/features/objects/presentation/pages/register_object_page.dart';
import 'package:encuentra_u/features/objects/presentation/pages/edit_report_page.dart';
import 'package:encuentra_u/features/objects/presentation/pages/report_detail_page.dart';
import 'package:encuentra_u/features/matching/presentation/pages/matches_page.dart';
import 'package:encuentra_u/features/matching/presentation/pages/match_detail_page.dart';

const imageAPath = String.fromEnvironment('E2E_IMAGE_A');
const imageBPath = String.fromEnvironment('E2E_IMAGE_B');
const fixtureRun = String.fromEnvironment('E2E_FIXTURE_RUN');

class SavedGeminiAnalysis implements ObjectAnalysisRepository {
  @override
  Future<ObjectImageAnalysis> analyzeImage(ObjectImageInput input) async =>
      const ObjectImageAnalysis(
          objectDetected: true,
          objectType: 'audífonos de diadema',
          category: 'electronica',
          primaryColor: 'negro',
          secondaryColors: ['azul'],
          brand: null,
          shape: 'diadema arqueada',
          visibleFeatures: ['almohadillas acolchadas', 'detalles azules'],
          visibleText: [],
          imageQuality: 'buena',
          confidence: 'alta',
          requiresAnotherPhoto: false,
          warnings: []);
}

void privateResponseCheck(Object? value) {
  if (value is Map) {
    const blocked = {
      'storage_key',
      'original_filename',
      'private_feature',
      'user_id',
      'email',
      'student_code',
      'password_hash',
      'extracted_data',
      'access_token'
    };
    if (value.keys.any(blocked.contains))
      throw StateError('Private response field exposed');
    for (final child in value.values) {
      privateResponseCheck(child);
    }
  } else if (value is List) {
    for (final child in value) {
      privateResponseCheck(child);
    }
  }
}

class DeviceApiClient extends http.BaseClient {
  final inner = http.Client();
  final requests = <Map<String, Object>>[];
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.path == ApiConstants.analyzeObjectImagePath)
      throw StateError('Unexpected new Gemini call');
    final response = await http.Response.fromStream(await inner.send(request));
    requests.add({
      'method': request.method,
      'path': request.url.path,
      'status': response.statusCode
    });
    if (request.url.path.contains('/matches') && response.statusCode == 200 ||
        request.url.path.endsWith('/image') && response.statusCode == 200) {
      privateResponseCheck(jsonDecode(response.body));
    }
    return http.StreamedResponse(
        Stream.value(response.bodyBytes), response.statusCode,
        headers: response.headers, request: request);
  }

  @override
  void close() => inner.close();
}

Future<Map<String, dynamic>> api(String method, String path,
    {Map<String, dynamic>? body, String? token, int expected = 200}) async {
  final client = http.Client();
  try {
    final request = http.Request(method, ApiConstants.uri(path))
      ..headers.addAll(ApiConstants.jsonHeaders);
    if (token != null)
      request.headers[ApiConstants.authorizationHeader] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(await client.send(request));
    if (response.statusCode != expected)
      throw StateError('API $method returned HTTP ${response.statusCode}');
    return response.body.isEmpty
        ? {}
        : jsonDecode(response.body) as Map<String, dynamic>;
  } finally {
    client.close();
  }
}

Future<void> waitFor(
    WidgetTester tester, bool Function() done, String step) async {
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) throw StateError('Timeout: $step');
    await tester.pump(const Duration(milliseconds: 150));
  }
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await waitFor(tester, () => finder.first.hitTestable().evaluate().isNotEmpty,
      'visible tap target');
  await tester.tap(finder.first);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> text(WidgetTester tester, Finder finder, String value) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, value);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> home(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(Scaffold).first))
      .popUntil((r) => r.settings.name == AppRoutes.home);
  await tester.pumpAndSettle();
}

Future<void> login(WidgetTester tester, DependencyContainer deps, String email,
    String password) async {
  if (deps.authController.isAuthenticated) {
    await home(tester);
    await tap(tester, find.text(AppStrings.signOut));
  }
  await waitFor(
      tester, () => find.byType(LoginPage).evaluate().isNotEmpty, 'login page');
  await text(tester, find.byType(TextFormField).at(0), email);
  await text(tester, find.byType(TextFormField).at(1), password);
  await tap(tester, find.text(AppStrings.signIn));
  await waitFor(
      tester,
      () =>
          find.byType(HomePage).evaluate().isNotEmpty &&
          (deps.objectController.status == LoadStatus.empty ||
              deps.objectController.status == LoadStatus.ready),
      'authenticated Home');
}

Future<ObjectReport> createWithPhoto(
    WidgetTester tester,
    DependencyContainer deps,
    ReportType type,
    ReportImageUpload image,
    String location) async {
  Navigator.of(tester.element(find.byType(HomePage))).push(MaterialPageRoute(
      settings: RouteSettings(
          name: type == ReportType.lost
              ? AppRoutes.registerLost
              : AppRoutes.registerFound),
      builder: (_) => RegisterObjectPage(
          type: type,
          controller: deps.objectController,
          analysisController: deps.objectAnalysisController,
          matchController: deps.matchController,
          pickImage: () async => image)));
  await tester.pumpAndSettle();
  await tap(tester, find.text(AppStrings.selectPhoto));
  await text(tester, find.byKey(const ValueKey('report-description')),
      'Audífonos negros con detalles azules y almohadillas acolchadas.');
  await tap(tester, find.text(AppStrings.analyzeWithAi));
  await waitFor(tester, () => deps.objectAnalysisController.hasAnalysis,
      'replay saved Gemini analysis');
  for (final entry in {
    'object-type': 'audífonos de diadema',
    'category': 'electronica',
    'primary-color': 'negro',
    'secondary-colors': 'azul',
    'shape': 'diadema arqueada',
    'location': location,
    'private-feature': 'PRIVATE_${type.name}_$location'
  }.entries) {
    await text(
        tester, find.byKey(ValueKey('report-${entry.key}')), entry.value);
  }
  await tap(tester, find.text(AppStrings.registerReport));
  await waitFor(
      tester,
      () =>
          find.byType(MatchesPage).evaluate().isNotEmpty &&
          !deps.matchController.isGenerating &&
          (deps.matchController.status == LoadStatus.ready ||
              deps.matchController.status == LoadStatus.empty),
      'create upload generate');
  final report = deps.objectController.items
      .singleWhere((r) => r.location.toLowerCase() == location.toLowerCase());
  expect(report.image != null, true);
  expect(report.imageAnalysis != null, true);
  return report;
}

Future<void> openMatch(
    WidgetTester tester, DependencyContainer deps, String id) async {
  await home(tester);
  Navigator.of(tester.element(find.byType(HomePage)))
      .pushNamed(AppRoutes.matchDetail, arguments: id);
  await waitFor(
      tester,
      () =>
          find.byType(MatchDetailPage).evaluate().isNotEmpty &&
          deps.matchController.detail?.id == id,
      'match detail');
  await waitFor(
      tester,
      () =>
          find
              .byWidgetPredicate((w) => w is RawImage && w.image != null)
              .evaluate()
              .length >=
          2,
      'both real photographs rendered');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'fotografías persistentes Android: A/B autorizados, C aislado y reemplazo',
      (tester) async {
    final fixtureDeadline = DateTime.now().add(const Duration(seconds: 45));
    final marker = File('${File(imageAPath).parent.path}/ready_$fixtureRun');
    while (!marker.existsSync() ||
        !File(imageAPath).existsSync() ||
        !File(imageBPath).existsSync()) {
      if (DateTime.now().isAfter(fixtureDeadline))
        throw StateError('Private device photo fixtures were not supplied');
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    final imageA = ReportImageUpload(
        bytes: await File(imageAPath).readAsBytes(),
        filename: 'front.png',
        contentType: 'image/png');
    final imageB = ReportImageUpload(
        bytes: await File(imageBPath).readAsBytes(),
        filename: 'side.png',
        contentType: 'image/png');
    final random = Random.secure();
    final run = DateTime.now().microsecondsSinceEpoch.toString();
    final password =
        base64UrlEncode(List.generate(32, (_) => random.nextInt(256)));
    final emails = [
      for (final label in ['a', 'b', 'c']) 'images.$label.$run@example.com'
    ];
    final tokens = <String>[];
    for (var i = 0; i < 3; i++) {
      await api('POST', ApiConstants.authRegisterPath, expected: 201, body: {
        'full_name': 'Image E2E ${i + 1}',
        'email': emails[i],
        'student_code': 'IMG$i$run',
        'password': password
      });
      tokens.add((await api('POST', ApiConstants.authLoginPath,
              body: {'email': emails[i], 'password': password}))['access_token']
          as String);
    }
    final clients = <DeviceApiClient>[];
    DependencyContainer makeDeps() {
      final client = DeviceApiClient();
      clients.add(client);
      return DependencyContainer.create(
          client: client, analysisRepository: SavedGeminiAnalysis());
    }

    var deps = makeDeps();
    await tester.pumpWidget(EncuentraUApp(dependencies: deps));
    await waitFor(
        tester,
        () =>
            find.byType(LoginPage).evaluate().isNotEmpty ||
            find.byType(HomePage).evaluate().isNotEmpty,
        'startup');
    await login(tester, deps, emails[0], password);
    final lost = await createWithPhoto(
        tester, deps, ReportType.lost, imageA, 'Cafetería imágenes $run');
    print('IMAGE_E2E_STEP A_SAVED');
    await login(tester, deps, emails[1], password);
    final found = await createWithPhoto(
        tester, deps, ReportType.found, imageB, 'Cafetería imágenes $run');
    final match = deps.matchController.items
        .firstWhere((m) => m.candidateReport.id == lost.id);
    expect(match.compatible, true);
    expect(match.percentage >= 85, true);
    final matchId = match.id;
    await openMatch(tester, deps, matchId);
    print('IMAGE_E2E_SCREENSHOT B_both_photos');
    await tester.pump(const Duration(seconds: 2));
    await login(tester, deps, emails[0], password);
    await openMatch(tester, deps, matchId);
    final initial = deps.matchController.detail!;
    expect(
        initial.myReport.image != null && initial.candidateReport.image != null,
        true);
    final oldSha = initial.myReport.image!.sha256;
    print('IMAGE_E2E_STEP A_B_BOTH_AUTHORIZED');
    await tester.pumpWidget(const SizedBox());
    deps.dispose();
    deps = makeDeps();
    await tester.pumpWidget(EncuentraUApp(dependencies: deps));
    await waitFor(
        tester,
        () =>
            find.byType(HomePage).evaluate().isNotEmpty &&
            deps.objectController.status == LoadStatus.ready,
        'restore from Android secure storage');
    await openMatch(tester, deps, matchId);
    print('IMAGE_E2E_SCREENSHOT A_after_reload');
    await tester.pump(const Duration(seconds: 2));
    for (final id in [lost.id, found.id]) {
      await api('GET', ApiConstants.reportImagePath(id),
          token: tokens[2], expected: 404);
      await api('GET', ApiConstants.reportImageContentPath(id),
          token: tokens[2], expected: 404);
    }
    print('IMAGE_E2E_STEP THIRD_USER_404');
    await home(tester);
    Navigator.of(tester.element(find.byType(HomePage))).push(MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.editReport),
        builder: (_) => EditReportPage(
            reportId: lost.id,
            controller: deps.objectController,
            pickImage: () async => imageB)));
    await waitFor(
        tester,
        () =>
            find.byType(EditReportPage).evaluate().isNotEmpty &&
            deps.objectController.detail?.id == lost.id,
        'edit photo');
    await tap(tester, find.text(AppStrings.replaceReportPhoto));
    await waitFor(
        tester,
        () =>
            !deps.reportImageController.isBusy(lost.id) &&
            deps.objectController.detail?.image?.sha256 != oldSha &&
            deps.objectController.detail?.image != null,
        'replacement persisted');
    final newSha = deps.objectController.detail!.image!.sha256;
    expect(newSha == found.image!.sha256, true);
    final again = await api('POST', ApiConstants.generateMatchesPath(lost.id),
        token: tokens[0]);
    final pair = (again['items'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((m) => m['candidate_report']['id'] == found.id);
    privateResponseCheck(pair);
    expect(pair['id'] == matchId, true);
    await openMatch(tester, deps, matchId);
    expect(deps.matchController.detail!.myReport.image!.sha256, newSha);
    print('IMAGE_E2E_SCREENSHOT A_replaced');
    await tester.pump(const Duration(seconds: 2));
    // An old-style report has no image row and still opens normally.
    final old = await api('POST', ApiConstants.reportsPath,
        token: tokens[0],
        expected: 201,
        body: {
          'report_type': 'lost',
          'object_type': 'llaves',
          'category': 'llaves',
          'description': 'Reporte anterior sin fotografía',
          'location': 'Biblioteca $run',
          'event_date': DateTime.now().toIso8601String().substring(0, 10)
        });
    await home(tester);
    Navigator.of(tester.element(find.byType(HomePage)))
        .pushNamed(AppRoutes.reportDetail, arguments: old['id']);
    await waitFor(
        tester,
        () =>
            find.byType(ReportDetailPage).evaluate().isNotEmpty &&
            deps.objectController.detail?.id == old['id'],
        'legacy report');
    expect(find.text(AppStrings.noReportPhoto).evaluate().isNotEmpty, true);
    final requests = [for (final client in clients) ...client.requests];
    expect(
        requests
            .where((r) =>
                r['method'] == 'POST' && r['path'] == ApiConstants.reportsPath)
            .length,
        2);
    expect(requests.where((r) => r['method'] == 'PUT').length, 3);
    print('IMAGE_E2E_RESULT ${jsonEncode({
          'passed': true,
          'lost_report_id': lost.id,
          'found_report_id': found.id,
          'legacy_report_id': old['id'],
          'match_id': matchId,
          'percentage': match.percentage,
          'old_sha256': oldSha,
          'new_sha256': newSha,
          'gemini_calls': 0,
          'third_user_status': 404,
          'requests': requests
        })}');
    await home(tester);
    await tap(tester, find.text(AppStrings.signOut));
    await waitFor(
        tester, () => find.byType(LoginPage).evaluate().length == 1, 'logout');
    expect(deps.reportImageController.cache.bytes, 0);
    binding.reportData = {
      'persistent_images': 'passed',
      'photos_private': true
    };
    await tester.pumpWidget(const SizedBox());
    deps.dispose();
    for (final client in clients) {
      client.close();
    }
  },
      skip: !Platform.isAndroid || imageAPath.isEmpty || imageBPath.isEmpty,
      timeout: const Timeout(Duration(minutes: 10)));
}
