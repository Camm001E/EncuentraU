import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:encuentra_u/app/dependency_container.dart';
import 'package:encuentra_u/core/constants/api_constants.dart';
import 'package:encuentra_u/core/constants/app_strings.dart';
import 'package:encuentra_u/features/matching/data/models/object_match_model.dart';
import 'package:encuentra_u/features/matching/presentation/pages/matches_page.dart';
import 'package:encuentra_u/features/matching/presentation/widgets/match_card.dart';
import 'package:encuentra_u/features/objects/domain/entities/object_report.dart';
import 'package:encuentra_u/features/objects/domain/entities/report_image.dart';
import 'package:encuentra_u/features/objects/presentation/pages/home_page.dart';
import 'package:encuentra_u/features/objects/presentation/pages/register_object_page.dart';
import 'package:encuentra_u/features/objects/presentation/widgets/report_image_scope.dart';
import 'package:encuentra_u/features/objects/presentation/widgets/report_photo.dart';
import 'package:encuentra_u/features/objects/presentation/widgets/report_photo_editor.dart';
import '../remote/support.dart';
import '../remote/widgets_test.dart' as remote;
import 'support.dart';
import 'package:http/http.dart' as http;

void main() {
  testWidgets(
      'vista previa corrupta muestra placeholder sin romper el formulario',
      (tester) async {
    final deps =
        await remote.start(tester, (_) async => jsonResponse(pageJson([])));
    Navigator.of(tester.element(find.byType(HomePage))).push(MaterialPageRoute(
        builder: (_) => RegisterObjectPage(
            type: ReportType.lost,
            controller: deps.objectController,
            analysisController: deps.objectAnalysisController,
            matchController: deps.matchController,
            pickImage: () async => const ReportImageUpload(
                bytes: [1, 2, 3],
                filename: 'corrupt.png',
                contentType: 'image/png'))));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.selectPhoto));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.byType(RegisterObjectPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('reporte antiguo usa placeholder sin descargar', (tester) async {
    final repo = ImageRepositoryStub();
    final controller = imageController(repo);
    addTearDown(controller.dispose);
    await tester.pumpWidget(ReportImageScope(
        controller: controller,
        child:
            const MaterialApp(home: Scaffold(body: ReportPhoto(image: null)))));
    expect(find.text(AppStrings.noReportPhoto), findsOneWidget);
    expect(repo.downloads, 0);
  });
  testWidgets('dos widgets comparten descarga autenticada y muestran imagen',
      (tester) async {
    final repo = ImageRepositoryStub();
    final controller = imageController(repo);
    addTearDown(controller.dispose);
    await tester.pumpWidget(ReportImageScope(
        controller: controller,
        child: MaterialApp(
            home: Scaffold(
                body: Column(children: [
          ReportPhoto(image: imageReference()),
          ReportPhoto(image: imageReference())
        ])))));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNWidgets(2));
    expect(repo.downloads, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('detalle de coincidencia muestra ambas fotos sin alterar 91%',
      (tester) async {
    final repo = ImageRepositoryStub();
    final controller = imageController(repo);
    addTearDown(controller.dispose);
    final json = matchJson();
    json['my_report']['image'] = imageJson();
    json['candidate_report']['image'] =
        imageJson(reportId: json['candidate_report']['id']);
    await tester.pumpWidget(ReportImageScope(
        controller: controller,
        child: MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
                    child: MatchCard(
                        match: ObjectMatchModel.fromJson(json),
                        detail: true))))));
    await tester.pumpAndSettle();
    expect(find.byType(ReportPhoto), findsNWidgets(2));
    expect(find.text('91%'), findsOneWidget);
  });
  testWidgets(
      'fallo de fotografía conserva reporte y bytes; reintento sube sin otro POST reports',
      (tester) async {
    var creates = 0, uploads = 0, generates = 0;
    final order = <String>[];
    final id = reportJson()['id'] as String;
    late DependencyContainer deps;
    deps = await remote.start(tester, (request) async {
      if (request.url.path == ApiConstants.reportsPath &&
          request.method == 'POST') {
        creates++;
        order.add('create');
        return jsonResponse(reportJson(), 201);
      }
      if (request.url.path == ApiConstants.myReportsPath)
        return jsonResponse(pageJson(creates == 0
            ? []
            : [reportJson()..['image'] = uploads > 1 ? imageJson() : null]));
      if (request.url.path == ApiConstants.reportImagePath(id) &&
          request.method == 'PUT') {
        uploads++;
        order.add('upload');
        return uploads == 1
            ? http.Response('', 503)
            : jsonResponse(imageJson());
      }
      if (request.url.path == ApiConstants.generateMatchesPath(id)) {
        generates++;
        order.add('generate');
        return jsonResponse({'report_id': id, 'total': 0, 'items': []});
      }
      if (request.url.path == ApiConstants.myMatchesPath)
        return jsonResponse(pageJson([]));
      if (request.url.path.endsWith('/content'))
        return http.Response.bytes(png, 200,
            headers: {'content-type': 'image/png'});
      return jsonResponse(reportJson());
    });
    Navigator.of(tester.element(find.byType(HomePage))).push(MaterialPageRoute(
        builder: (_) => RegisterObjectPage(
            type: ReportType.lost,
            controller: deps.objectController,
            analysisController: deps.objectAnalysisController,
            matchController: deps.matchController,
            pickImage: () async => uploadInput())));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.selectPhoto));
    await tester.pumpAndSettle();
    await remote.fillReport(tester);
    await tester.tap(find.text(AppStrings.registerReport));
    await tester.pumpAndSettle();
    expect(creates, 1);
    expect(uploads, 1);
    expect(generates, 0);
    expect(find.byType(RegisterObjectPage), findsOneWidget);
    expect(find.text(AppStrings.reportSavedPhotoFailed), findsWidgets);
    final retry = find.text(AppStrings.retryPhotoUpload);
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(creates, 1);
    expect(uploads, 2);
    expect(generates, 1);
    expect(order, ['create', 'upload', 'upload', 'generate']);
    expect(find.byType(MatchesPage), findsOneWidget);
  });
  testWidgets('editor conserva foto fallida, reintenta y confirma eliminación',
      (tester) async {
    final repo = ImageRepositoryStub();
    final controller = imageController(repo);
    addTearDown(controller.dispose);
    var changes = 0;
    await tester.pumpWidget(ReportImageScope(
        controller: controller,
        child: MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
                    child: ReportPhotoEditor(
                        reportId: imageReference().reportId,
                        image: imageReference(),
                        enabled: true,
                        onChanged: () async {
                          changes++;
                        },
                        pickImage: () async => uploadInput()))))));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.replaceReportPhoto));
    await tester.pumpAndSettle();
    expect(repo.uploads, 1);
    expect(changes, 1);
    await tester.tap(find.text(AppStrings.deleteReportPhoto));
    await tester.pumpAndSettle();
    expect(repo.deletes, 0);
    await tester.tap(find.text(AppStrings.confirm));
    await tester.pumpAndSettle();
    expect(repo.deletes, 1);
    expect(changes, 2);
  });
}
