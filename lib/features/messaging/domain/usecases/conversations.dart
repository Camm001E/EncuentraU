import '../../../../core/domain/page.dart';
import '../../../../core/domain/ownership_limits.dart';
import '../entities/conversation.dart';
import '../repositories/conversation_repository.dart';

class ListConversations {
  const ListConversations(this.repository);
  final ConversationRepository repository;
  Future<Page<Conversation>> call({required int limit, required int offset}) =>
      repository.getMyConversations(limit: limit, offset: offset);
}

class GetConversation {
  const GetConversation(this.repository);
  final ConversationRepository repository;
  Future<Conversation> call(String id) => repository.getConversation(id);
}

class ListMessages {
  const ListMessages(this.repository);
  final ConversationRepository repository;
  Future<MessagePage> call(String id,
          {int limit = OwnershipLimits.messagesPageSize, String? before}) =>
      repository.getMessages(id, limit: limit, before: before);
}

class SendMessage {
  const SendMessage(this.repository);
  final ConversationRepository repository;
  Future<ChatMessage> call(String id,
          {required String body, required String clientMessageId}) =>
      repository.sendMessage(id, body: body, clientMessageId: clientMessageId);
}

class MarkConversationRead {
  const MarkConversationRead(this.repository);
  final ConversationRepository repository;
  Future<void> call(String id, {String? lastMessageId}) =>
      repository.markRead(id, lastMessageId: lastMessageId);
}
