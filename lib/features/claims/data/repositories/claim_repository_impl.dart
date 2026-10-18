import '../../../../core/domain/page.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../domain/entities/ownership_claim.dart';
import '../../domain/repositories/claim_repository.dart';
import '../datasources/claim_remote_data_source.dart';

class ClaimRepositoryImpl implements ClaimRepository, AdminClaimRepository {
  const ClaimRepositoryImpl(this.remote);
  final ClaimRemoteDataSource remote;
  @override
  Future<AdminClaimTotals> getTotals() async {
    final totals = await Future.wait([
      for (final status in ClaimStatus.values)
        _parse(() => remote.adminList(
            limit: ApiConstants.countPageSize,
            offset: 0,
            status: status)).then((p) => p.total)
    ]);
    return AdminClaimTotals(
        pending: totals[0], approved: totals[1], rejected: totals[2]);
  }

  Future<T> _parse<T>(Future<T> Function() work) async {
    try {
      return await work();
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  @override
  Future<OwnershipClaim> submit(String matchId, ClaimDraft draft) =>
      _parse(() => remote.submit(matchId, draft));
  @override
  Future<Page<OwnershipClaim>> getMyClaims(
          {required int limit, required int offset, ClaimStatus? status}) =>
      _parse(() => remote.list(limit: limit, offset: offset, status: status));
  @override
  Future<OwnershipClaim> getClaim(String id) => _parse(() => remote.get(id));
  @override
  Future<OwnershipClaim?> getMatchClaim(String matchId) =>
      _parse(() => remote.forMatch(matchId));
  @override
  Future<Page<AdminClaim>> getAdminClaims(
          {required int limit, required int offset, ClaimStatus? status}) =>
      _parse(
          () => remote.adminList(limit: limit, offset: offset, status: status));
  @override
  Future<AdminClaim> getAdminClaim(String id) =>
      _parse(() => remote.adminGet(id));
  @override
  Future<AdminClaim> approve(String id, {String? note}) =>
      _parse(() => remote.approve(id, note));
  @override
  Future<AdminClaim> reject(String id,
          {required String reason, String? note}) =>
      _parse(() => remote.reject(id, reason, note));
}
