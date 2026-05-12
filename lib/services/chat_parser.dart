import 'dart:convert';

abstract class ChatEvent {}

class ChatMessageEvent extends ChatEvent {
  final String from;
  final String text;
  final int? timestamp;
  ChatMessageEvent({required this.from, required this.text, this.timestamp});
}

class UserListEvent extends ChatEvent {
  final List<String> users;
  UserListEvent(this.users);
}

class RegisteredEvent extends ChatEvent {
  final String username;
  RegisteredEvent(this.username);
}

class MessageStatusEvent extends ChatEvent {
  final String status;
  MessageStatusEvent(this.status);
}

class MoveEvent extends ChatEvent {
  final double x;
  final double y;
  MoveEvent(this.x, this.y);
}

class ErrorEvent extends ChatEvent {
  final String error;
  ErrorEvent(this.error);
}

class UnknownEvent extends ChatEvent {
  final dynamic raw;
  UnknownEvent(this.raw);
}

class ChatParser {
  static ChatEvent parse(dynamic data) {
    dynamic decoded = data;
    try {
      if (data is String) decoded = jsonDecode(data);
    } catch (_) {
      return UnknownEvent(data);
    }

    if (decoded is! Map) return UnknownEvent(decoded);

    final type = decoded['type'];
    switch (type) {
      case 'chat_message':
        return ChatMessageEvent(
          from: decoded['from']?.toString() ?? 'anonymous',
          text: decoded['text']?.toString() ?? '',
          timestamp: decoded['timestamp'] is num
              ? (decoded['timestamp'] as num).toInt()
              : null,
        );
      case 'user_list':
        final list = decoded['users'];
        if (list is List) {
          return UserListEvent(list.map((e) => e.toString()).toList());
        }
        return UserListEvent([]);
      case 'registered':
        return RegisteredEvent(decoded['username']?.toString() ?? '');
      case 'message_status':
        return MessageStatusEvent(decoded['status']?.toString() ?? '');
      case 'move_event':
        final x = (decoded['x'] is num)
            ? (decoded['x'] as num).toDouble()
            : 0.0;
        final y = (decoded['y'] is num)
            ? (decoded['y'] as num).toDouble()
            : 0.0;
        return MoveEvent(x, y);
      case 'error':
        return ErrorEvent(decoded['error']?.toString() ?? '');
      default:
        return UnknownEvent(decoded);
    }
  }
}
