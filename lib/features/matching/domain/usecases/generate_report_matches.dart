import '../entities/object_match.dart';
import '../repositories/match_repository.dart';

class GenerateReportMatches {
  const GenerateReportMatches(this._repository);
  final MatchRepository _repository;
  Future<GeneratedMatches> call(String reportId) =>
      _repository.generateReportMatches(reportId);
}
