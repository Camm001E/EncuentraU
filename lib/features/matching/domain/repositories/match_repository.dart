import '../entities/object_match.dart';
import '../entities/match_page.dart';

abstract interface class MatchRepository {
  Future<GeneratedMatches> generateReportMatches(String reportId);
  Future<MatchPage> getMyMatches(
      {required int limit,
      required int offset,
      MatchLevel? level,
      MatchStatus? status});
  Future<ObjectMatch> getMyMatch(String id);
}
