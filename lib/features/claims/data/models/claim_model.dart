import '../../../../core/network/json_reader.dart';
import '../../../matching/data/models/object_match_model.dart';
import '../../domain/entities/ownership_claim.dart';

abstract final class ClaimModel {
  static DateTime? _optionalDate(dynamic value) =>
      value == null ? null : JsonReader.date(value).toUtc();
  static ClaimSummary summary(Map<String, dynamic> json) => ClaimSummary(
      id: JsonReader.string(json['id']),
      matchId: JsonReader.string(json['match_id']),
      status: JsonReader.enumeration(json['status'], ClaimStatus.values),
      match: ObjectMatchModel.fromJson(JsonReader.object(json['match'])),
      createdAt: JsonReader.date(json['created_at']).toUtc(),
      updatedAt: JsonReader.date(json['updated_at']).toUtc(),
      reviewedAt: _optionalDate(json['reviewed_at']),
      rejectionReason: JsonReader.optionalString(json['rejection_reason']),
      conversationId: JsonReader.optionalString(json['conversation_id']));
  static OwnershipClaim fromJson(Map<String, dynamic> json) {
    final base = summary(json);
    final relationship =
        JsonReader.enumeration(json['relationship'], ClaimRelationship.values);
    return OwnershipClaim(
        id: base.id,
        matchId: base.matchId,
        status: base.status,
        match: base.match,
        createdAt: base.createdAt,
        updatedAt: base.updatedAt,
        reviewedAt: base.reviewedAt,
        rejectionReason: base.rejectionReason,
        conversationId: base.conversationId,
        relationship: relationship,
        ownershipEvidence: relationship == ClaimRelationship.claimant
            ? JsonReader.optionalString(json['ownership_evidence'])
            : null);
  }

  static AdminClaim admin(Map<String, dynamic> json) {
    final base = summary(json);
    return AdminClaim(
        id: base.id,
        matchId: base.matchId,
        status: base.status,
        match: base.match,
        createdAt: base.createdAt,
        updatedAt: base.updatedAt,
        reviewedAt: base.reviewedAt,
        rejectionReason: base.rejectionReason,
        conversationId: base.conversationId,
        ownershipEvidence:
            JsonReader.optionalString(json['ownership_evidence']),
        lostPrivateFeature:
            JsonReader.optionalString(json['lost_private_feature']),
        foundPrivateFeature:
            JsonReader.optionalString(json['found_private_feature']),
        adminNote: JsonReader.optionalString(json['admin_note']));
  }

  static Map<String, dynamic> createBody(ClaimDraft draft) =>
      {'ownership_evidence': draft.normalized};
  static Map<String, dynamic> approvalBody(String? note) =>
      {if (note != null && note.trim().isNotEmpty) 'admin_note': note.trim()};
  static Map<String, dynamic> rejectionBody(String reason, String? note) =>
      {'rejection_reason': reason.trim(), ...approvalBody(note)};
}
