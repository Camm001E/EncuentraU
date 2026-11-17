import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/session/session_manager.dart';

Stream<void> chatEvents(String id, SessionManager session) {
  final generation = session.generation;
  WebSocketChannel? channel;
  StreamSubscription<dynamic>? subscription;
  Timer? retry;
  bool stopped = false;
  late StreamController<void> controller;
  bool current() =>
      !stopped && session.active && session.generation == generation;
  Future<void> connect() async {
    if (!current()) return;
    try {
      final token = await session.readToken();
      if (token == null || !current()) return;
      final uri =
          ApiConstants.uri('${ApiConstants.conversationPath(id)}/events');
      final socket = WebSocketChannel.connect(
          uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws'));
      channel = socket;
      await socket.ready.timeout(const Duration(seconds: 10));
      if (!current()) {
        await socket.sink.close();
        return;
      }
      socket.sink.add(token);
      subscription =
          socket.stream.timeout(const Duration(seconds: 35)).listen((event) {
        if (!current()) return;
        try {
          final type = (jsonDecode(event as String) as Map)['type'];
          if (type == 'ready' || type == 'changed') controller.add(null);
        } catch (_) {}
      }, onError: (Object _) {
        socket.sink.close();
      }, onDone: () {
        if (current()) retry = Timer(const Duration(seconds: 5), connect);
      }, cancelOnError: false);
    } catch (_) {
      await channel?.sink.close();
      if (current()) retry = Timer(const Duration(seconds: 5), connect);
    }
  }

  controller = StreamController<void>(
      onListen: connect,
      onCancel: () async {
        stopped = true;
        retry?.cancel();
        await subscription?.cancel();
        await channel?.sink.close();
      });
  return controller.stream;
}
