import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:encuentra_u/core/constants/app_strings.dart';
import 'package:encuentra_u/core/theme/app_theme.dart';
import 'package:encuentra_u/features/matching/data/models/object_match_model.dart';
import 'package:encuentra_u/features/matching/presentation/widgets/match_card.dart';
import 'package:encuentra_u/features/matching/presentation/widgets/match_evidence.dart';
import 'package:encuentra_u/features/matching/presentation/widgets/score_ring.dart';
import 'package:encuentra_u/features/matching/presentation/widgets/match_comparison_scene.dart';
import '../remote/support.dart';

Widget application(Widget child, {bool reduced = false, double scale = 1}) =>
    MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
            data: MediaQueryData(
                disableAnimations: reduced,
                textScaler: TextScaler.linear(scale)),
            child: Scaffold(
                body: SingleChildScrollView(
                    child: Padding(
                        padding: const EdgeInsets.all(16), child: child)))));
ScoreRingPainter painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.painter)
    .whereType<ScoreRingPainter>()
    .single;

void main() {
  testWidgets(
      'cambiar orientación no reinicia el anillo al terminar la entrada',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(application(MatchCard(
        match: ObjectMatchModel.fromJson(matchJson()), detail: true)));
    await tester.pumpAndSettle();
    expect(painter(tester).progress, .91);
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    await tester.pump();
    expect(painter(tester).progress, .91);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'escaneo se omite con movimiento reducido y termina en modo normal',
      (tester) async {
    final match = ObjectMatchModel.fromJson(matchJson());
    await tester.pumpWidget(
        application(MatchComparisonScene(match: match), reduced: true));
    expect(
        tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .where((p) => p.painter is PhotoScanPainter),
        isEmpty);
    await tester.pumpWidget(application(MatchComparisonScene(match: match)));
    await tester.pumpAndSettle();
    final scan = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .whereType<PhotoScanPainter>()
        .single;
    expect(scan.progress, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
  for (final score in [0, 29, 83, 100]) {
    testWidgets(
        'anillo muestra $score del servidor, animación finita y Semantics',
        (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(application(ScoreRing(percentage: score)));
      expect(find.text('$score%'), findsOneWidget);
      expect(find.bySemanticsLabel(AppStrings.scoreSemantics(score)),
          findsOneWidget);
      expect(painter(tester).progress, 0);
      await tester.pumpAndSettle();
      expect(painter(tester).progress, score / 100);
      await tester.pumpWidget(application(ScoreRing(percentage: score)));
      expect(painter(tester).progress, score / 100);
      semantics.dispose();
    });
  }
  testWidgets('reducir movimiento presenta puntuación final inmediatamente',
      (tester) async {
    await tester.pumpWidget(
        application(const ScoreRing(percentage: 83), reduced: true));
    expect(painter(tester).progress, .83);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
  testWidgets('lista concisa conserva 91 y no muestra factores completos',
      (tester) async {
    await tester.pumpWidget(
        application(MatchCard(match: ObjectMatchModel.fromJson(matchJson()))));
    await tester.pumpAndSettle();
    expect(find.text('91%'), findsOneWidget);
    expect(find.byType(FactorEvidence), findsNothing);
    expect(find.text(AppStrings.estimatedCompatibility), findsOneWidget);
    expect(find.text(AppStrings.openMatch), findsOneWidget);
  });
  testWidgets(
      'detalle agrupa nueve factores, desconocidos y advertencias extensas',
      (tester) async {
    final json = matchJson();
    json['warnings'] = ['Advertencia de prueba. ' * 40, 'Otra observación'];
    json['factors'][0]['status'] = 'unknown';
    json['factors'][0]['evaluable_weight'] = 0;
    json['factors'][0]['score'] = 0;
    await tester.pumpWidget(application(
        MatchCard(match: ObjectMatchModel.fromJson(json), detail: true),
        reduced: true));
    await tester.pumpAndSettle();
    expect(find.byType(FactorEvidence), findsNWidgets(9));
    expect(find.textContaining(AppStrings.identityEvidence), findsWidgets);
    expect(find.textContaining(AppStrings.contextEvidence), findsWidgets);
    expect(find.text(AppStrings.ownershipNotice), findsOneWidget);
    expect(find.text(AppStrings.warnings), findsOneWidget);
    expect(find.text(AppStrings.unknownFactor), findsWidgets);
    expect(find.text(AppStrings.noReportPhoto), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
  for (final width in [360.0, 390.0, 768.0, 1280.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('comparación sin overflow a ancho $width y texto $scale',
          (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(application(
            MatchCard(
                match: ObjectMatchModel.fromJson(matchJson()), detail: true),
            scale: scale,
            reduced: true));
        await tester.pumpAndSettle();
        expect(find.byType(FactorEvidence), findsNWidgets(9));
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final entry in [
    ('high', 100, true),
    ('possible', 83, true),
    ('low', 29, false)
  ]) {
    testWidgets('detalle soporta ${entry.$1} sin alterar puntuación',
        (tester) async {
      final json = matchJson()
        ..['level'] = entry.$1
        ..['percentage'] = entry.$2
        ..['compatible'] = entry.$3;
      await tester.pumpWidget(application(
          MatchCard(match: ObjectMatchModel.fromJson(json), detail: true),
          reduced: true));
      await tester.pumpAndSettle();
      expect(find.text('${entry.$2}%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
