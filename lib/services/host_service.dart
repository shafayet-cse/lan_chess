import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/game_message.dart';
import 'network_service.dart';

/// The mDNS/Bonjour service type both sides look for. Keep this identical
/// in [HostService] and [ClientService].
const String kServiceType = '_lanchess._tcp';
const int kDefaultPort = 8765;

/// Runs on the phone that creates the game. Starts a plain WebSocket
/// server on the local network and advertises it via mDNS so the other
/// phone can find it automatically - no internet, no cloud, no login.
class HostService extends NetworkService {
  final String playerName;
  final int port;

  HttpServer? _server;
  BonsoirBroadcast? _broadcast;
  WebSocketChannel? _clientChannel;
  StreamSubscription? _clientSub;

  HostService({required this.playerName, this.port = kDefaultPort});

  @override
  Future<void> start() async {
    status = ConnectionStatus.hosting;
    notifyListeners();

    final handler = webSocketHandler((WebSocketChannel webSocket, String? protocol) {
      // This app is 1v1 - ignore any connection after the first.
      if (_clientChannel != null) {
        webSocket.sink.close();
        return;
      }
      _clientChannel = webSocket;
      status = ConnectionStatus.connected;
      notifyListeners();

      // Introduce ourselves once the socket is open.
      _clientChannel!.sink.add(GameMessage(MessageType.hello, {'name': playerName}).encode());

      _clientSub = webSocket.stream.listen(
        (raw) {
          try {
            final msg = GameMessage.decode(raw as String);
            if (msg.type == MessageType.hello) {
              opponentName = msg.data['name'] as String?;
            }
            onMessage?.call(msg);
            notifyListeners();
          } catch (_) {
            // Ignore malformed frames.
          }
        },
        onDone: () {
          status = ConnectionStatus.disconnected;
          notifyListeners();
        },
        onError: (_) {
          status = ConnectionStatus.error;
          notifyListeners();
        },
        cancelOnError: true,
      );
    });

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

    final service = BonsoirService(
      name: "$playerName's Chess Game",
      type: kServiceType,
      port: port,
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.ready;
    await _broadcast!.start();
  }

  @override
  void send(GameMessage message) {
    _clientChannel?.sink.add(message.encode());
  }

  @override
  Future<void> stop() async {
    await _clientSub?.cancel();
    await _clientChannel?.sink.close();
    await _broadcast?.stop();
    await _server?.close(force: true);
  }
}
