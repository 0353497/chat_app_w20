import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatService {
  ChatService._internal();

  static final ChatService _instance = ChatService._internal();

  factory ChatService.instance() => _instance;

  late final WebSocketChannel _channel = WebSocketChannel.connect(
    Uri.parse('ws://10.0.2.2:8080'),
  );

  WebSocketSink get sink => _channel.sink;
  Stream<dynamic> get stream => _channel.stream;

  void dispose() {
    try {
      _channel.sink.close();
    } catch (_) {}
  }

  void register(String username) {
    _channel.sink.add(
      jsonEncode({"type": "register", "username": username.trim()}),
    );
  }

  void sendMessage(String msg) {
    _channel.sink.add(jsonEncode({"type": "chat_message", "text": msg}));
  }
}
