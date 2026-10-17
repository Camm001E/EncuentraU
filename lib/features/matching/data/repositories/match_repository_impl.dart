import '../../../../core/errors/api_exception.dart';
import '../../domain/entities/object_match.dart';
import '../../domain/entities/match_page.dart';
import '../../domain/repositories/match_repository.dart';
import '../datasources/match_remote_data_source.dart';

class MatchRepositoryImpl implements MatchRepository {
  const MatchRepositoryImpl(this._remote);
  final MatchRemoteDataSource _remote;
  Future<T> _parse<T>(Future<T> Function() work) async {
    try {
      return await work();
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  @override
  Future<GeneratedMatches> generateReportMatches(String reportId) =>
      _parse(() => _remote.generate(reportId));
  @override
  Future<MatchPage> getMyMatches(
          {required int limit,
          required int offset,
          MatchLevel? level,
          MatchStatus? status}) =>
      _parse(() => _remote.list(
          limit: limit, offset: offset, level: level, status: status));
  @override
  Future<ObjectMatch> getMyMatch(String id) => _parse(() => _remote.get(id));
}
