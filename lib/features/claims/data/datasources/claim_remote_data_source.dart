import '../../../../core/constants/api_constants.dart';
import '../../../../core/domain/page.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/authenticated_api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../domain/entities/ownership_claim.dart';
import '../models/claim_model.dart';

class ClaimRemoteDataSource {
  const ClaimRemoteDataSource(this.api);
  final AuthenticatedApiClient api;
  Future<OwnershipClaim> submit(String matchId, ClaimDraft draft) async =>
      ClaimModel.fromJson((await api.request(
          'POST', ApiConstants.submitClaimPath(matchId),
          body: ClaimModel.createBody(draft),
          expectedStatus: ApiConstants.created))!);
  Future<Page<OwnershipClaim>> list(
          {required int limit,
          required int offset,
          ClaimStatus? status}) async =>
      JsonReader.page(
          (await api.request('GET', ApiConstants.myClaimsPath,
              query: _query(limit, offset, status)))!,
          (v) => ClaimModel.fromJson(JsonReader.object(v)));
  Future<OwnershipClaim> get(String id) async => ClaimModel.fromJson(
      (await api.request('GET', ApiConstants.claimPath(id)))!);
  Future<OwnershipClaim?> forMatch(String matchId) async {
    try {
      return ClaimModel.fromJson(
          (await api.request('GET', ApiConstants.matchClaimPath(matchId)))!);
    } on ApiException catch (error) {
      if (error.failure == ApiFailure.notFound) return null;
      rethrow;
    }
  }

  Map<String, String> _query(int limit, int offset, ClaimStatus? status) => {
        ApiConstants.limitParameter: '$limit',
        ApiConstants.offsetParameter: '$offset',
        if (status != null) ApiConstants.statusParameter: status.name
      };
  Future<Page<AdminClaim>> adminList(
          {required int limit,
          required int offset,
          ClaimStatus? status}) async =>
      JsonReader.page(
          (await api.request('GET', ApiConstants.adminClaimsPath,
              query: _query(limit, offset, status)))!,
          (v) => ClaimModel.admin(JsonReader.object(v)));
  Future<AdminClaim> adminGet(String id) async => ClaimModel.admin(
      (await api.request('GET', ApiConstants.adminClaimPath(id)))!);
  Future<AdminClaim> approve(String id, String? note) async => ClaimModel.admin(
      (await api.request('POST', ApiConstants.approveClaimPath(id),
          body: ClaimModel.approvalBody(note)))!);
  Future<AdminClaim> reject(String id, String reason, String? note) async =>
      ClaimModel.admin((await api.request(
          'POST', ApiConstants.rejectClaimPath(id),
          body: ClaimModel.rejectionBody(reason, note)))!);
}
