import '../../../../core/domain/page.dart';
import '../../../../core/domain/ownership_limits.dart';
import '../entities/conversation.dart';

abstract interface class ConversationRepository {
  Future<Page<Conversation>> getMyConversations(
      {required int limit, required int offset});
  Future<Conversation> getConversation(String id);
  Future<MessagePage> getMessages(String id,
      {int limit = OwnershipLimits.messagesPageSize, String? before});
  Future<ChatMessage> sendMessage(String id,
      {required String body, required String clientMessageId});
  Future<void> markRead(String id, {String? lastMessageId});
}
