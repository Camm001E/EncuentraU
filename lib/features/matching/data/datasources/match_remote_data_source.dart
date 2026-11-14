import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_durations.dart';
import '../../domain/entities/visual_review.dart';
import '../models/visual_review_model.dart';
import '../../../../core/network/authenticated_api_client.dart';
import '../../domain/entities/object_match.dart';
import '../../domain/entities/match_page.dart';
import '../models/object_match_model.dart';

class MatchRemoteDataSource {
  const MatchRemoteDataSource(this._api);
  final AuthenticatedApiClient _api;
  Future<VisualReview> review(String id) async => VisualReviewModel.fromJson(
      (await _api.request('POST', '${ApiConstants.matchPath(id)}/visual-review',
          requestTimeout: AppDurations.aiAnalysisTimeout))!);

  Future<GeneratedMatches> generate(String reportId) async =>
      ObjectMatchModel.generated((await _api.request(
          'POST', ApiConstants.generateMatchesPath(reportId)))!);
  Future<MatchPage> list(
          {required int limit,
          required int offset,
          MatchLevel? level,
          MatchStatus? status,
          String? reportId}) async =>
      ObjectMatchModel.page(
          (await _api.request('GET', ApiConstants.myMatchesPath, query: {
        ApiConstants.limitParameter: '$limit',
        ApiConstants.offsetParameter: '$offset',
        if (level != null) ApiConstants.levelParameter: level.name,
        if (status != null) ApiConstants.statusParameter: status.name,
        if (reportId != null) 'report_id': reportId,
      }))!);
  Future<ObjectMatch> get(String id) async => ObjectMatchModel.fromJson(
      (await _api.request('GET', ApiConstants.matchPath(id)))!);
}
