import 'package:flutter/foundation.dart';
import '../models/game_message.dart';

enum ConnectionStatus {
  idle,
  hosting,      // server started, mDNS broadcasting, waiting for a peer
  discovering,  // scanning for hosts on the LAN
  connecting,
  connected,
  disconnected,
  error,
}

/// Common surface used by both [HostService] and [ClientService] so the UI
/// layer (lobby screens, game screen) doesn't need to care which side it is.
abstract class NetworkService extends ChangeNotifier {
  ConnectionStatus status = ConnectionStatus.idle;
  String? opponentName;

  /// Called whenever a [GameMessage] arrives from the peer.
  void Function(GameMessage message)? onMessage;

  Future<void> start();
  void send(GameMessage message);
  Future<void> stop();
}
