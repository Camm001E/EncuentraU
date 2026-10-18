import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/identifiers/client_message_id.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/presentation/api_message.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/usecases/conversations.dart';

class ChatController extends ChangeNotifier {
  ChatController(
      {required GetConversation get,
      required ListMessages list,
      required SendMessage send,
      required MarkConversationRead read,
      this.pollInterval = AppDurations.chatPolling,
      this.messageId = newClientMessageId,
      this.onActivity})
      : _get = get,
        _list = list,
        _send = send,
        _read = read;
  final GetConversation _get;
  final ListMessages _list;
  final SendMessage _send;
  final MarkConversationRead _read;
  final Duration pollInterval;
  final String Function() messageId;
  final void Function()? onActivity;
  Timer? _timer;
  bool _visible = false, _disposed = false, _fetching = false;
  int _epoch = 0;
  String? conversationId;
  Conversation? conversation;
  List<ChatMessage> _messages = const [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String? nextCursor, message, actionMessage;
  String? _pendingBody, _pendingId;
  bool isSending = false, isLoadingOlder = false;
  LoadStatus status = LoadStatus.initial;
  bool get isPolling => _timer?.isActive ?? false;
  bool _current(int epoch) => !_disposed && epoch == _epoch;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> open(String id) async {
    clear();
    conversationId = id;
    status = LoadStatus.loading;
    _notify();
    await refresh();
  }

  void setVisible(bool value) {
    _visible = value;
    _timer?.cancel();
    _timer = null;
    if (value && conversationId != null && !_disposed) {
      _timer = Timer.periodic(pollInterval, (_) {
        if (!_fetching) unawaited(refresh());
      });
      unawaited(refresh());
    }
  }

  List<ChatMessage> _merged(Iterable<ChatMessage> added) {
    final values = <String, ChatMessage>{
      for (final m in _messages) m.id: m,
      for (final m in added) m.id: m
    }.values.toList();
    values.sort((a, b) {
      final time = a.createdAt.compareTo(b.createdAt);
      return time == 0 ? a.id.compareTo(b.id) : time;
    });
    return List.unmodifiable(values);
  }

  Future<void> refresh() async {
    final id = conversationId;
    if (id == null || _fetching) return;
    final epoch = _epoch;
    _fetching = true;
    try {
      final values = await Future.wait<Object>([_get(id), _list(id)]);
      if (!_current(epoch)) return;
      final view = values[0] as Conversation, page = values[1] as MessagePage;
      final initial = conversation == null;
      conversation = view;
      final gap = !initial &&
          _messages.isNotEmpty &&
          page.nextCursor != null &&
          !page.items.any((item) => _messages.any((old) => old.id == item.id));
      // If an entire page arrived while hidden, restart the visible history at
      // the latest page. Its cursor can recover every missing older message.
      if (initial || gap) nextCursor = page.nextCursor;
      _messages = gap ? List.unmodifiable(page.items) : _merged(page.items);
      status = _messages.isEmpty ? LoadStatus.empty : LoadStatus.ready;
      message = null;
      _notify();
      if (_visible && page.items.isNotEmpty) {
        try {
          await _read(id, lastMessageId: page.items.last.id);
        } catch (error) {
          if (_current(epoch)) message = apiMessage(error);
        }
      }
    } catch (error) {
      if (_current(epoch)) {
        message = apiMessage(error);
        if (error is ApiException &&
            {
              ApiFailure.notFound,
              ApiFailure.unauthorized,
              ApiFailure.forbidden,
              ApiFailure.permissionDenied
            }.contains(error.failure)) {
          setVisible(false);
          _messages = const [];
          conversation = null;
        }
        if (conversation == null) status = LoadStatus.error;
      }
    } finally {
      if (_current(epoch)) {
        _fetching = false;
        _notify();
      }
    }
  }

  Future<void> loadOlder() async {
    final id = conversationId, cursor = nextCursor;
    if (id == null || cursor == null || isLoadingOlder) return;
    final epoch = _epoch;
    isLoadingOlder = true;
    _notify();
    try {
      final page = await _list(id, before: cursor);
      if (!_current(epoch)) return;
      _messages = _merged(page.items);
      nextCursor = page.nextCursor;
      message = null;
    } catch (error) {
      if (_current(epoch)) message = apiMessage(error);
    } finally {
      if (_current(epoch)) {
        isLoadingOlder = false;
        _notify();
      }
    }
  }

  Future<bool> send(String body) async {
    if (isSending || conversationId == null || conversation == null)
      return false;
    if (conversation!.status != ConversationStatus.active) {
      actionMessage = AppStrings.conversationClosed;
      _notify();
      return false;
    }
    final text = MessageDraft.normalize(body);
    if (!MessageDraft.isValid(text)) {
      actionMessage = AppStrings.messageValidation;
      _notify();
      return false;
    }
    final id = conversationId!, epoch = _epoch;
    if (_pendingBody != text || _pendingId == null) {
      _pendingBody = text;
      _pendingId = messageId();
    }
    final clientId = _pendingId!;
    isSending = true;
    actionMessage = null;
    _notify();
    try {
      final result = await _send(id, body: text, clientMessageId: clientId);
      if (!_current(epoch)) return false;
      _messages = _merged([result]);
      status = LoadStatus.ready;
      _pendingBody = null;
      _pendingId = null;
      onActivity?.call();
      return true;
    } catch (error) {
      if (_current(epoch)) actionMessage = apiMessage(error);
      return false;
    } finally {
      if (_current(epoch)) {
        isSending = false;
        _notify();
      }
    }
  }

  void clear() {
    _epoch++;
    _timer?.cancel();
    _timer = null;
    _visible = false;
    _fetching = false;
    conversationId = null;
    conversation = null;
    _messages = const [];
    nextCursor = null;
    message = null;
    actionMessage = null;
    _pendingBody = null;
    _pendingId = null;
    isSending = false;
    isLoadingOlder = false;
    status = LoadStatus.initial;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    clear();
    super.dispose();
  }
}
