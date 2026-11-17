import '../../../../core/constants/api_constants.dart';
import '../../../../core/domain/page.dart';
import '../../../../core/network/authenticated_api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../domain/entities/conversation.dart';
import '../models/conversation_model.dart';

class ConversationRemoteDataSource {
  const ConversationRemoteDataSource(this.api);
  final AuthenticatedApiClient api;
  Future<Page<Conversation>> list(
          {required int limit, required int offset}) async =>
      JsonReader.page(
          (await api.request('GET', ApiConstants.myConversationsPath, query: {
            ApiConstants.limitParameter: '$limit',
            ApiConstants.offsetParameter: '$offset'
          }))!,
          (v) => ConversationModel.fromJson(JsonReader.object(v)));
  Future<Conversation> get(String id) async => ConversationModel.fromJson(
      (await api.request('GET', ApiConstants.conversationPath(id)))!);
  Future<MessagePage> messages(String id,
          {required int limit, String? before}) async =>
      ConversationModel.messages(
          (await api.request('GET', ApiConstants.messagesPath(id), query: {
        ApiConstants.limitParameter: '$limit',
        if (before != null) ApiConstants.beforeParameter: before
      }))!);
  Future<ChatMessage> send(
          String id, String body, String clientMessageId) async =>
      ConversationModel.message((await api.request(
          'POST', ApiConstants.messagesPath(id),
          body: ConversationModel.messageBody(body, clientMessageId),
          expectedStatus: ApiConstants.created))!);
  Future<void> read(String id, String? lastMessageId) async {
    await api.request('POST', ApiConstants.readConversationPath(id),
        body: {if (lastMessageId != null) 'last_message_id': lastMessageId},
        expectedStatus: ApiConstants.noContent);
  }
}
