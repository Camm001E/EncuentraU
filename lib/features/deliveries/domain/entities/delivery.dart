import '../../../claims/domain/entities/ownership_claim.dart';
import '../../../matching/domain/entities/object_match.dart';
import '../../../messaging/domain/entities/conversation.dart';

enum DeliveryStatus {
  coordinating,
  awaitingConfirmations,
  awaitingAdmin,
  disputed,
  completed;

  String get wireName => switch (this) {
        awaitingConfirmations => 'awaiting_confirmations',
        awaitingAdmin => 'awaiting_admin',
        _ => name,
      };
}

enum DeliveryEventType {
  deliveryCreated,
  custodianConfirmed,
  claimantConfirmed,
  disputeOpened,
  adminReopened,
  adminCompleted;

  String get wireName => switch (this) {
        deliveryCreated => 'delivery_created',
        custodianConfirmed => 'custodian_confirmed',
        claimantConfirmed => 'claimant_confirmed',
        disputeOpened => 'dispute_opened',
        adminReopened => 'admin_reopened',
        adminCompleted => 'admin_completed',
      };
}

enum DeliveryRole { claimant, custodian, admin }

class DeliveryEvent {
  const DeliveryEvent(
      {required this.id,
      required this.type,
      required this.actor,
      required this.createdAt,
      this.note});
  final String id;
  final DeliveryEventType type;
  final DeliveryRole actor;
  final String? note;
  final DateTime createdAt;
}

class DeliveryRecord {
  const DeliveryRecord(
      {required this.id,
      required this.matchId,
      required this.claimId,
      required this.conversationId,
      required this.status,
      required this.conversationStatus,
      required this.lostReport,
      required this.foundReport,
      required this.createdAt,
      required this.updatedAt,
      this.claimantConfirmedAt,
      this.custodianConfirmedAt,
      this.completedAt});
  final String id, matchId, claimId, conversationId;
  final DeliveryStatus status;
  final ConversationStatus conversationStatus;
  final MatchReportSummary lostReport, foundReport;
  final DateTime createdAt, updatedAt;
  final DateTime? claimantConfirmedAt, custodianConfirmedAt, completedAt;
}

class Delivery extends DeliveryRecord {
  const Delivery(
      {required super.id,
      required super.matchId,
      required super.claimId,
      required super.conversationId,
      required super.status,
      required super.conversationStatus,
      required super.lostReport,
      required super.foundReport,
      required super.createdAt,
      required super.updatedAt,
      super.claimantConfirmedAt,
      super.custodianConfirmedAt,
      super.completedAt,
      required this.relationship,
      required this.canConfirm,
      required this.canDispute,
      required this.events,
      this.myConfirmedAt,
      this.otherConfirmedAt,
      this.disputeReason});
  final DeliveryRole relationship;
  final bool canConfirm, canDispute;
  final DateTime? myConfirmedAt, otherConfirmedAt;
  final String? disputeReason;
  final List<DeliveryEvent> events;
}

class AdminDelivery extends DeliveryRecord {
  const AdminDelivery(
      {required super.id,
      required super.matchId,
      required super.claimId,
      required super.conversationId,
      required super.status,
      required super.conversationStatus,
      required super.lostReport,
      required super.foundReport,
      required super.createdAt,
      required super.updatedAt,
      super.claimantConfirmedAt,
      super.custodianConfirmedAt,
      super.completedAt,
      this.claim,
      this.disputeReason,
      this.adminNote,
      this.events = const [],
      this.messageCount,
      this.lastActivityAt});
  final AdminClaim? claim;
  final String? disputeReason, adminNote;
  final List<DeliveryEvent> events;
  final int? messageCount;
  final DateTime? lastActivityAt;
}

abstract final class DeliveryLimits {
  static const minimumReasonLength = 10;
  static const maximumNoteLength = 2000;
}
