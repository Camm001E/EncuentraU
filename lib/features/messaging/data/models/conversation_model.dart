import '../../../../core/network/json_reader.dart';
import '../../../matching/data/models/object_match_model.dart';
import '../../domain/entities/conversation.dart';

abstract final class ConversationModel {
  static ChatMessage message(Map<String, dynamic> json) => ChatMessage(
      id: JsonReader.string(json['id']),
      clientMessageId: JsonReader.string(json['client_message_id']),
      body: JsonReader.string(json['body']),
      isMine: JsonReader.boolean(json['is_mine']),
      createdAt: JsonReader.date(json['created_at']).toUtc());
  static Conversation fromJson(Map<String, dynamic> json) {
    final unread = JsonReader.integer(json['unread_count']);
    final name = JsonReader.string(json['other_display_name']);
    if (unread < 0 || name.contains('@')) throw const FormatException();
    return Conversation(
        id: JsonReader.string(json['id']),
        matchId: JsonReader.string(json['match_id']),
        claimId: JsonReader.string(json['claim_id']),
        status:
            JsonReader.enumeration(json['status'], ConversationStatus.values),
        otherDisplayName: name,
        report: ObjectMatchModel.summary(JsonReader.object(json['report'])),
        unreadCount: unread,
        createdAt: JsonReader.date(json['created_at']).toUtc(),
        updatedAt: JsonReader.date(json['updated_at']).toUtc(),
        lastMessage: json['last_message'] == null
            ? null
            : message(JsonReader.object(json['last_message'])),
        lastMessageAt: json['last_message_at'] == null
            ? null
            : JsonReader.date(json['last_message_at']).toUtc());
  }

  static MessagePage messages(Map<String, dynamic> json) => MessagePage(
      items:
          JsonReader.list(json['items'], (v) => message(JsonReader.object(v))),
      limit: JsonReader.integer(json['limit']),
      nextCursor: JsonReader.optionalString(json['next_cursor']));
  static Map<String, dynamic> messageBody(
          String body, String clientMessageId) =>
      {
        'body': MessageDraft.normalize(body),
        'client_message_id': clientMessageId
      };
}
