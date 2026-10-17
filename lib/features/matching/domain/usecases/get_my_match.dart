import '../entities/object_match.dart';
import '../repositories/match_repository.dart';

class GetMyMatch {
  const GetMyMatch(this._repository);
  final MatchRepository _repository;
  Future<ObjectMatch> call(String id) => _repository.getMyMatch(id);
}
