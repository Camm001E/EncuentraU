import '../../../../core/domain/page.dart';
import '../../../../core/domain/ownership_limits.dart';
import '../../../../core/errors/api_exception.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../datasources/conversation_remote_data_source.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  const ConversationRepositoryImpl(this.remote);
  final ConversationRemoteDataSource remote;
  Future<T> _parse<T>(Future<T> Function() work) async {
    try {
      return await work();
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  @override
  Future<Page<Conversation>> getMyConversations(
          {required int limit, required int offset}) =>
      _parse(() => remote.list(limit: limit, offset: offset));
  @override
  Future<Conversation> getConversation(String id) =>
      _parse(() => remote.get(id));
  @override
  Future<MessagePage> getMessages(String id,
          {int limit = OwnershipLimits.messagesPageSize, String? before}) =>
      _parse(() => remote.messages(id, limit: limit, before: before));
  @override
  Future<ChatMessage> sendMessage(String id,
          {required String body, required String clientMessageId}) =>
      _parse(() => remote.send(id, body, clientMessageId));
  @override
  Future<void> markRead(String id, {String? lastMessageId}) =>
      _parse(() => remote.read(id, lastMessageId));
}
