import 'dart:convert';

/// All message kinds exchanged between host and joiner over the WebSocket.
enum MessageType { hello, move, resign, restartRequest, restartAccept }

/// Simple JSON-over-WebSocket envelope.
class GameMessage {
  final MessageType type;
  final Map<String, dynamic> data;

  GameMessage(this.type, [this.data = const {}]);

  String encode() => jsonEncode({'type': type.name, 'data': data});

  static GameMessage decode(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final type = MessageType.values.firstWhere(
      (t) => t.name == map['type'],
      orElse: () => throw FormatException('Unknown message type: ${map['type']}'),
    );
    return GameMessage(type, Map<String, dynamic>.from(map['data'] ?? {}));
  }
}
