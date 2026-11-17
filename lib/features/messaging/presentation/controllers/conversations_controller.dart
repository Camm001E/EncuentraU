import '../../../../core/domain/page.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/usecases/conversations.dart';

class ConversationsController extends PagedController<Conversation> {
  ConversationsController(this._list);
  final ListConversations _list;
  @override
  String itemId(Conversation item) => item.id;
  @override
  Future<Page<Conversation>> fetchPage(int limit, int offset) =>
      _list(limit: limit, offset: offset);
}
