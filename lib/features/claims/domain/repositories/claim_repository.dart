import '../../../../core/domain/page.dart';
import '../entities/ownership_claim.dart';

abstract interface class ClaimRepository {
  Future<OwnershipClaim> submit(String matchId, ClaimDraft draft);
  Future<Page<OwnershipClaim>> getMyClaims(
      {required int limit, required int offset, ClaimStatus? status});
  Future<OwnershipClaim> getClaim(String id);
  Future<OwnershipClaim?> getMatchClaim(String matchId);
}

abstract interface class AdminClaimRepository {
  Future<AdminClaimTotals> getTotals();
  Future<Page<AdminClaim>> getAdminClaims(
      {required int limit, required int offset, ClaimStatus? status});
  Future<AdminClaim> getAdminClaim(String id);
  Future<AdminClaim> approve(String id, {String? note});
  Future<AdminClaim> reject(String id, {required String reason, String? note});
}
