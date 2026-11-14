import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:encuentra_u/features/matching/data/models/object_match_model.dart';
import 'package:encuentra_u/features/matching/data/models/visual_review_model.dart';
import 'package:encuentra_u/features/matching/domain/entities/object_match.dart';
import 'package:encuentra_u/features/matching/domain/entities/match_page.dart';
import 'package:encuentra_u/features/matching/domain/entities/visual_review.dart';
import 'package:encuentra_u/features/matching/domain/usecases/generate_report_matches.dart';
import 'package:encuentra_u/features/matching/domain/usecases/get_my_matches.dart';
import 'package:encuentra_u/features/matching/domain/usecases/get_my_match.dart';
import 'package:encuentra_u/features/matching/presentation/controllers/match_controller.dart';
import 'package:encuentra_u/features/matching/presentation/widgets/visual_review_panel.dart';
import 'remote/controller_support.dart';
import 'remote/support.dart';
import 'images/support.dart';

ObjectMatch match({String id = 'one', String hash = 'a'}) {
  final data = matchJson();
  data['id'] = id;
  for (final key in ['my_report', 'candidate_report']) {
    final report = data[key] as Map<String, dynamic>;
    report['image'] = {
      ...imageJson(reportId: report['id'] as String),
      'sha256': (key == 'my_report' ? hash : 'b').padRight(64, '0')
    };
  }
  return ObjectMatchModel.fromJson(data);
}

VisualReview result(ObjectMatch m,
        [VisualVerdict verdict = VisualVerdict.different]) =>
    VisualReview(
        verdict: verdict,
        explanation: 'Dos cierres frente a uno.',
        agreements: const [],
        contradictions: const ['Los cierres son distintos.'],
        suggestedPhoto: 'Fotografia el cierre de cerca.',
        sourceSha256: m.myReport.image!.sha256,
        candidateSha256: m.candidateReport.image!.sha256);
MatchController controller(Future<VisualReview> Function(String) review,
    {MatchRepositoryStub? repo}) {
  final r = repo ?? MatchRepositoryStub();
  return MatchController(
      generateReportMatches: GenerateReportMatches(r),
      getMyMatches: GetMyMatches(r),
      getMyMatch: GetMyMatch(r),
      reviewPhotos: review);
}

class DetailRepository extends MatchRepositoryStub {
  DetailRepository(this.value);
  final ObjectMatch value;
  @override
  Future<ObjectMatch> getMyMatch(String id) async => value;
}

void main() {
  test('detail automatically reviews once and reuses matching image evidence',
      () async {
    final m = match();
    var calls = 0;
    final c = controller((_) async {
      calls++;
      return result(m);
    }, repo: DetailRepository(m));
    addTearDown(c.dispose);
    await c.loadDetail(m.id);
    expect(c.visualReviewFor(m), isNotNull);
    await c.loadDetail(m.id);
    expect(calls, 1);
  });
  test('parser rejects unknown verdict and malformed evidence', () {
    expect(
        () => VisualReviewModel.fromJson({
              'comparison': {'verdict': 'certain'}
            }),
        throwsFormatException);
  });
  test('duplicates are bounded and logout discards late replies', () async {
    final m = match(), waiting = Completer<VisualReview>();
    var calls = 0;
    final c = controller((_) {
      calls++;
      return waiting.future;
    });
    addTearDown(c.dispose);
    final pending = c.review(m);
    await c.review(m);
    expect(calls, 1);
    c.clear();
    waiting.complete(result(m));
    await pending;
    expect(c.visualReviewFor(m), isNull);
    expect(c.reviewing, isEmpty);
  });
  test('replaced photos never inherit old evidence', () async {
    final m = match();
    final c = controller((_) async => result(m));
    addTearDown(c.dispose);
    await c.review(m);
    expect(c.visualReviewFor(m), isNotNull);
    expect(c.visualReviewFor(match(hash: 'c')), isNull);
    await c.review(match(hash: 'c'));
    expect(c.reviewErrors[m.id], isNotNull);
    expect(c.visualReviewFor(m), isNull);
  });
  test('batch compares at most five and preserves original scores', () async {
    final objects = List.generate(8, (i) => match(id: 'm$i'));
    var calls = 0;
    final repo = MatchRepositoryStub()
      ..onList = (limit, offset) async =>
          MatchPage(items: objects, total: 8, limit: limit, offset: offset);
    final c = controller((id) async {
      calls++;
      return result(objects.firstWhere((m) => m.id == id));
    }, repo: repo);
    addTearDown(c.dispose);
    await c.refresh();
    await c.reviewVisible();
    expect(calls, 5);
    expect(c.rankedItems.first.id, 'm5');
    expect(c.items.first.id, 'm0');
    expect(c.rankedItems.first.percentage, objects.first.percentage);
  });
  test('batch stops when session is cleared', () async {
    final m = match(), waiting = Completer<VisualReview>();
    var calls = 0;
    final repo = MatchRepositoryStub()
      ..onList = (limit, offset) async => MatchPage(
          items: [m, match(id: 'two')], total: 2, limit: limit, offset: offset);
    final c = controller((_) {
      calls++;
      return waiting.future;
    }, repo: repo);
    addTearDown(c.dispose);
    await c.refresh();
    final work = c.reviewVisible();
    c.clear();
    waiting.complete(result(m));
    await work;
    expect(calls, 1);
    expect(c.isReviewingBatch, false);
  });
  for (final verdict in VisualVerdict.values) {
    testWidgets('review panel is readable at 320px with large text: $verdict',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final m = match();
      final c = controller((_) async => result(m, verdict));
      addTearDown(c.dispose);
      await c.review(m);
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.7)),
              child: Scaffold(
                  body: SingleChildScrollView(
                      child: VisualReviewPanel(match: m, controller: c))))));
      expect(find.text(verdict.label), findsOneWidget);
      expect(find.text('Foto que puede ayudar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
