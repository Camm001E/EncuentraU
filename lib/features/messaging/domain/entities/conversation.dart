import '../../../matching/domain/entities/object_match.dart';
import '../../../../core/domain/ownership_limits.dart';

enum ConversationStatus { active, closed }

class ChatMessage {
  const ChatMessage(
      {required this.id,
      required this.clientMessageId,
      required this.body,
      required this.isMine,
      required this.createdAt});
  final String id, clientMessageId, body;
  final bool isMine;
  final DateTime createdAt;
}

class Conversation {
  const Conversation(
      {required this.id,
      required this.matchId,
      required this.claimId,
      required this.status,
      required this.otherDisplayName,
      required this.report,
      required this.unreadCount,
      required this.createdAt,
      required this.updatedAt,
      this.lastMessage,
      this.lastMessageAt});
  final String id, matchId, claimId, otherDisplayName;
  final ConversationStatus status;
  final MatchReportSummary report;
  final int unreadCount;
  final DateTime createdAt, updatedAt;
  final ChatMessage? lastMessage;
  final DateTime? lastMessageAt;
}

class MessagePage {
  const MessagePage(
      {required this.items, required this.limit, this.nextCursor});
  final List<ChatMessage> items;
  final int limit;
  final String? nextCursor;
}

abstract final class MessageDraft {
  static String normalize(String value) =>
      value.trim().replaceAll('\r\n', '\n');
  static bool isValid(String value) =>
      normalize(value).isNotEmpty &&
      normalize(value).runes.length <= OwnershipLimits.maximumMessageLength;
}
