import '../../../../core/network/json_reader.dart';
import '../../../claims/data/models/claim_model.dart';
import '../../../matching/data/models/object_match_model.dart';
import '../../../messaging/domain/entities/conversation.dart';
import '../../domain/entities/delivery.dart';

abstract final class DeliveryModel {
  static DateTime? date(dynamic value) =>
      value == null ? null : JsonReader.date(value).toUtc();
  static T wire<T>(dynamic value, List<T> values, String Function(T) name) =>
      values.firstWhere((v) => name(v) == value,
          orElse: () => throw const FormatException());
  static DeliveryEvent event(dynamic value) {
    final j = JsonReader.object(value);
    return DeliveryEvent(
        id: JsonReader.string(j['id']),
        type:
            wire(j['event_type'], DeliveryEventType.values, (v) => v.wireName),
        actor: JsonReader.enumeration(j['actor'], DeliveryRole.values),
        createdAt: JsonReader.date(j['created_at']).toUtc(),
        note: JsonReader.optionalString(j['note']));
  }

  static DeliveryRecord summary(Map<String, dynamic> j) => DeliveryRecord(
      id: JsonReader.string(j['id']),
      matchId: JsonReader.string(j['match_id']),
      claimId: JsonReader.string(j['claim_id']),
      conversationId: JsonReader.string(j['conversation_id']),
      status: wire(j['status'], DeliveryStatus.values, (v) => v.wireName),
      conversationStatus: JsonReader.enumeration(
          j['conversation_status'], ConversationStatus.values),
      lostReport: ObjectMatchModel.summary(JsonReader.object(j['lost_report'])),
      foundReport:
          ObjectMatchModel.summary(JsonReader.object(j['found_report'])),
      createdAt: JsonReader.date(j['created_at']).toUtc(),
      updatedAt: JsonReader.date(j['updated_at']).toUtc(),
      claimantConfirmedAt: date(j['claimant_confirmed_at']),
      custodianConfirmedAt: date(j['custodian_confirmed_at']),
      completedAt: date(j['completed_at']));
  static Delivery fromJson(Map<String, dynamic> j) {
    final s = summary(j);
    final role = JsonReader.enumeration(j['relationship'], DeliveryRole.values);
    if (role == DeliveryRole.admin) throw const FormatException();
    return Delivery(
        id: s.id,
        matchId: s.matchId,
        claimId: s.claimId,
        conversationId: s.conversationId,
        status: s.status,
        conversationStatus: s.conversationStatus,
        lostReport: s.lostReport,
        foundReport: s.foundReport,
        createdAt: s.createdAt,
        updatedAt: s.updatedAt,
        claimantConfirmedAt: s.claimantConfirmedAt,
        custodianConfirmedAt: s.custodianConfirmedAt,
        completedAt: s.completedAt,
        relationship: role,
        canConfirm: JsonReader.boolean(j['can_confirm']),
        canDispute: JsonReader.boolean(j['can_dispute']),
        myConfirmedAt: date(j['my_confirmed_at']),
        otherConfirmedAt: date(j['other_confirmed_at']),
        disputeReason: JsonReader.optionalString(j['dispute_reason']),
        events: JsonReader.list(j['events'], (value) {
          final e = event(value);
          return DeliveryEvent(
              id: e.id,
              type: e.type,
              actor: e.actor,
              createdAt: e.createdAt,
              note: e.type == DeliveryEventType.disputeOpened ? e.note : null);
        }));
  }

  static AdminDelivery admin(Map<String, dynamic> j) {
    final s = summary(j);
    return AdminDelivery(
        id: s.id,
        matchId: s.matchId,
        claimId: s.claimId,
        conversationId: s.conversationId,
        status: s.status,
        conversationStatus: s.conversationStatus,
        lostReport: s.lostReport,
        foundReport: s.foundReport,
        createdAt: s.createdAt,
        updatedAt: s.updatedAt,
        claimantConfirmedAt: s.claimantConfirmedAt,
        custodianConfirmedAt: s.custodianConfirmedAt,
        completedAt: s.completedAt,
        claim: j['claim'] == null
            ? null
            : ClaimModel.admin(JsonReader.object(j['claim'])),
        disputeReason: JsonReader.optionalString(j['dispute_reason']),
        adminNote: JsonReader.optionalString(j['admin_note']),
        events: j['events'] == null
            ? const []
            : JsonReader.list(j['events'], event),
        messageCount: j['message_count'] == null
            ? null
            : JsonReader.integer(j['message_count']),
        lastActivityAt: date(j['last_activity_at']));
  }
}
