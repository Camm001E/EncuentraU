import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/authenticated_api_client.dart';
import '../../domain/entities/object_match.dart';
import '../../domain/entities/match_page.dart';
import '../models/object_match_model.dart';

class MatchRemoteDataSource {
  const MatchRemoteDataSource(this._api);
  final AuthenticatedApiClient _api;
  Future<GeneratedMatches> generate(String reportId) async =>
      ObjectMatchModel.generated((await _api.request(
          'POST', ApiConstants.generateMatchesPath(reportId)))!);
  Future<MatchPage> list(
          {required int limit,
          required int offset,
          MatchLevel? level,
          MatchStatus? status}) async =>
      ObjectMatchModel.page(
          (await _api.request('GET', ApiConstants.myMatchesPath, query: {
        ApiConstants.limitParameter: '$limit',
        ApiConstants.offsetParameter: '$offset',
        if (level != null) ApiConstants.levelParameter: level.name,
        if (status != null) ApiConstants.statusParameter: status.name,
      }))!);
  Future<ObjectMatch> get(String id) async => ObjectMatchModel.fromJson(
      (await _api.request('GET', ApiConstants.matchPath(id)))!);
}
