import '../../../matching/domain/entities/object_match.dart';
import '../../../../core/domain/ownership_limits.dart';

enum ClaimStatus { pending, approved, rejected }

enum ClaimRelationship { claimant, custodian }

class AdminClaimTotals {
  const AdminClaimTotals(
      {required this.pending, required this.approved, required this.rejected});
  final int pending, approved, rejected;
}

class ClaimSummary {
  const ClaimSummary(
      {required this.id,
      required this.matchId,
      required this.status,
      required this.match,
      required this.createdAt,
      required this.updatedAt,
      this.reviewedAt,
      this.rejectionReason,
      this.conversationId});
  final String id, matchId;
  final ClaimStatus status;
  final ObjectMatch match;
  final DateTime createdAt, updatedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason, conversationId;
}

/// Participant DTO: cannot contain another owner's private characteristics.
class OwnershipClaim extends ClaimSummary {
  const OwnershipClaim(
      {required super.id,
      required super.matchId,
      required super.status,
      required super.match,
      required super.createdAt,
      required super.updatedAt,
      super.reviewedAt,
      super.rejectionReason,
      super.conversationId,
      required this.relationship,
      this.ownershipEvidence});
  final ClaimRelationship relationship;
  final String? ownershipEvidence;
}

/// This separate entity is constructed only by administrative endpoints.
class AdminClaim extends ClaimSummary {
  const AdminClaim(
      {required super.id,
      required super.matchId,
      required super.status,
      required super.match,
      required super.createdAt,
      required super.updatedAt,
      super.reviewedAt,
      super.rejectionReason,
      super.conversationId,
      this.ownershipEvidence,
      this.lostPrivateFeature,
      this.foundPrivateFeature,
      this.adminNote});
  final String? ownershipEvidence,
      lostPrivateFeature,
      foundPrivateFeature,
      adminNote;
}

class ClaimDraft {
  const ClaimDraft(this.evidence);
  final String evidence;
  String get normalized => evidence.trim().replaceAll('\r\n', '\n');
  bool get isValid =>
      normalized.runes.length >= OwnershipLimits.minimumEvidenceLength &&
      normalized.runes.length <= OwnershipLimits.maximumEvidenceLength;
}
