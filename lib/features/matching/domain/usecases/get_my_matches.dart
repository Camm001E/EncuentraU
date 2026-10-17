import '../entities/object_match.dart';
import '../entities/match_page.dart';
import '../repositories/match_repository.dart';

class GetMyMatches {
  const GetMyMatches(this._repository);
  final MatchRepository _repository;
  Future<MatchPage> call(
          {required int limit,
          required int offset,
          MatchLevel? level,
          MatchStatus? status}) =>
      _repository.getMyMatches(
          limit: limit, offset: offset, level: level, status: status);
}
