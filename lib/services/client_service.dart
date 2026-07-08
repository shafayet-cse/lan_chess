import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/game_message.dart';
import 'host_service.dart' show kServiceType;
import 'network_service.dart';

class DiscoveredHost {
  final String name;
  final String ip;
  final int port;
  DiscoveredHost({required this.name, required this.ip, required this.port});
}

/// Runs on the phone joining a game. Discovers hosts advertising
/// [kServiceType] on the local network via mDNS, then connects over a
/// plain WebSocket once the user picks one.
class ClientService extends NetworkService {
  final String playerName;

  BonsoirDiscovery? _discovery;
  StreamSubscription? _discoverySub;
  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;

  final List<DiscoveredHost> discoveredHosts = [];

  /// UI hook - called whenever [discoveredHosts] changes.
  void Function()? onHostsChanged;

  ClientService({required this.playerName});

  @override
  Future<void> start() => startDiscovery();

  Future<void> startDiscovery() async {
    status = ConnectionStatus.discovering;
    notifyListeners();

    _discovery = BonsoirDiscovery(type: kServiceType);
    await _discovery!.ready;

    _discoverySub = _discovery!.eventStream!.listen((event) {
      final service = event.service;
      if (service == null) return;

      if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
        service.resolve(_discovery!.serviceResolver);
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
        final resolved = service as ResolvedBonsoirService;
        final ip = resolved.ip;
        if (ip == null || ip.isEmpty) return;
        final alreadyKnown = discoveredHosts.any((h) => h.ip == ip && h.port == resolved.port);
        if (!alreadyKnown) {
          discoveredHosts.add(DiscoveredHost(name: resolved.name, ip: ip, port: resolved.port));
          onHostsChanged?.call();
        }
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
        discoveredHosts.removeWhere((h) => h.name == service.name);
        onHostsChanged?.call();
      }
    });

    await _discovery!.start();
  }

  Future<void> connectTo(DiscoveredHost host) async {
    status = ConnectionStatus.connecting;
    notifyListeners();
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://${host.ip}:${host.port}'));
      opponentName = host.name;

      _channelSub = _channel!.stream.listen(
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

      send(GameMessage(MessageType.hello, {'name': playerName}));
      status = ConnectionStatus.connected;
      notifyListeners();
    } catch (_) {
      status = ConnectionStatus.error;
      notifyListeners();
    }
  }

  @override
  void send(GameMessage message) {
    _channel?.sink.add(message.encode());
  }

  @override
  Future<void> stop() async {
    await _channelSub?.cancel();
    await _channel?.sink.close();
    await _discoverySub?.cancel();
    await _discovery?.stop();
  }
}
