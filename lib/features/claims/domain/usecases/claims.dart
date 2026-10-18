import '../../../../core/domain/page.dart';
import '../entities/ownership_claim.dart';
import '../repositories/claim_repository.dart';

class GetAdminClaimTotals {
  const GetAdminClaimTotals(this.repository);
  final AdminClaimRepository repository;
  Future<AdminClaimTotals> call() => repository.getTotals();
}

class SubmitOwnershipClaim {
  const SubmitOwnershipClaim(this.repository);
  final ClaimRepository repository;
  Future<OwnershipClaim> call(String matchId, ClaimDraft draft) =>
      repository.submit(matchId, draft);
}

class ListMyClaims {
  const ListMyClaims(this.repository);
  final ClaimRepository repository;
  Future<Page<OwnershipClaim>> call(
          {required int limit, required int offset, ClaimStatus? status}) =>
      repository.getMyClaims(limit: limit, offset: offset, status: status);
}

class GetClaim {
  const GetClaim(this.repository);
  final ClaimRepository repository;
  Future<OwnershipClaim> call(String id) => repository.getClaim(id);
}

class GetMatchClaim {
  const GetMatchClaim(this.repository);
  final ClaimRepository repository;
  Future<OwnershipClaim?> call(String id) => repository.getMatchClaim(id);
}

class ListAdminClaims {
  const ListAdminClaims(this.repository);
  final AdminClaimRepository repository;
  Future<Page<AdminClaim>> call(
          {required int limit, required int offset, ClaimStatus? status}) =>
      repository.getAdminClaims(limit: limit, offset: offset, status: status);
}

class GetAdminClaim {
  const GetAdminClaim(this.repository);
  final AdminClaimRepository repository;
  Future<AdminClaim> call(String id) => repository.getAdminClaim(id);
}

class ApproveClaim {
  const ApproveClaim(this.repository);
  final AdminClaimRepository repository;
  Future<AdminClaim> call(String id, {String? note}) =>
      repository.approve(id, note: note);
}

class RejectClaim {
  const RejectClaim(this.repository);
  final AdminClaimRepository repository;
  Future<AdminClaim> call(String id, {required String reason, String? note}) =>
      repository.reject(id, reason: reason, note: note);
}
