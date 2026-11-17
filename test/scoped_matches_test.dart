import 'package:flutter_test/flutter_test.dart';
import 'package:encuentra_u/features/matching/data/models/object_match_model.dart';
import 'package:encuentra_u/features/matching/domain/entities/object_match.dart';
import 'package:encuentra_u/features/matching/domain/entities/match_page.dart';
import 'package:encuentra_u/features/matching/presentation/controllers/match_controller.dart';
import 'remote/controller_support.dart';
import 'remote/support.dart';
import 'images/support.dart';

ObjectMatch sample(String id,
    {String? verdict, String state = 'active', String status = 'pending'}) {
  final json = matchJson();
  json['id'] = id;
  json['status'] = status;
  for (final field in ['my_report', 'candidate_report']) {
    final report = json[field] as Map<String, dynamic>;
    report['status'] = state;
    report['image'] = {
      ...imageJson(reportId: report['id']),
      'sha256': (field == 'my_report' ? 'a' : 'b').padRight(64, '0')
    };
  }
  if (verdict != null) {
    json['visual_review'] = {
      'comparison': {
        'verdict': verdict,
        'explanation': 'Revisión guardada.',
        'agreements': <String>[],
        'contradictions': <String>[]
      },
      'source_sha256': 'a'.padRight(64, '0'),
      'candidate_sha256': 'b'.padRight(64, '0'),
    };
  }
  return ObjectMatchModel.fromJson(json);
}

class ScopedRepository extends MatchRepositoryStub {
  final calls = <String?>[];
  final values = [
    sample('active'),
    sample('discarded', verdict: 'different'),
    sample('closed', state: 'resolved'),
    sample('rejected', status: 'rejected')
  ];
  @override
  Future<MatchPage> getMyMatches(
      {required int limit,
      required int offset,
      MatchLevel? level,
      MatchStatus? status,
      String? reportId}) async {
    calls.add(reportId);
    return MatchPage(
        items: values, total: values.length, limit: limit, offset: offset);
  }

  @override
  Future<ObjectMatch> getMyMatch(String id) async =>
      values.firstWhere((m) => m.id == id);
}

void main() {
  test('report scope reaches listing without changing general controller',
      () async {
    final repo = ScopedRepository();
    final general = matchController(repo),
        scoped = matchController(repo).forReport('my-report');
    addTearDown(general.dispose);
    addTearDown(scoped.dispose);
    await scoped.refresh();
    await general.refresh();
    expect(repo.calls, ['my-report', null]);
  });
  test('discarded and resolved are separate after refresh', () async {
    final c = matchController(ScopedRepository());
    addTearDown(c.dispose);
    await c.refresh();
    expect(c.visibleItems.map((m) => m.id), ['active']);
    c.selectSection(MatchSection.discarded);
    expect(c.visibleItems.map((m) => m.id).toSet(), {'discarded', 'rejected'});
    await c.refresh();
    expect(c.visibleItems.map((m) => m.id).toSet(), {'discarded', 'rejected'});
    c.selectSection(MatchSection.closed);
    expect(c.visibleItems.single.id, 'closed');
  });
  test('persisted photo comparison is available without another AI request',
      () async {
    final c = matchController(ScopedRepository());
    addTearDown(c.dispose);
    await c.loadDetail('discarded');
    expect(c.visualReviewFor(c.detail!)?.explanation, 'Revisión guardada.');
    expect(c.sectionFor(c.detail!), MatchSection.discarded);
  });
}
