import 'package:flutter/material.dart';
import '../services/client_service.dart';
import '../services/network_service.dart';
import 'game_screen.dart';

class JoinLobbyScreen extends StatefulWidget {
  final ClientService clientService;
  final String localName;
  const JoinLobbyScreen({super.key, required this.clientService, required this.localName});

  @override
  State<JoinLobbyScreen> createState() => _JoinLobbyScreenState();
}

class _JoinLobbyScreenState extends State<JoinLobbyScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    widget.clientService.onHostsChanged = () {
      if (mounted) setState(() {});
    };
    widget.clientService.addListener(_onChange);
    widget.clientService.start();
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    if (widget.clientService.status == ConnectionStatus.connected && !_navigated) {
      _navigated = true;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => GameScreen(
          networkService: widget.clientService,
          isHost: false,
          localName: widget.localName,
        ),
      ));
    }
  }

  @override
  void dispose() {
    widget.clientService.removeListener(_onChange);
    if (!_navigated) widget.clientService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hosts = widget.clientService.discoveredHosts;
    final isConnecting = widget.clientService.status == ConnectionStatus.connecting;

    return Scaffold(
      appBar: AppBar(title: const Text('Join Game')),
      body: isConnecting
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text('Connecting...'),
                ],
              ),
            )
          : hosts.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 24),
                        Text('Searching for games on your network...'),
                        SizedBox(height: 8),
                        Text(
                          'Make sure a friend has tapped "Host Game" and you\'re on the same Wi-Fi / hotspot.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: hosts.length,
                  itemBuilder: (context, index) {
                    final host = hosts[index];
                    return ListTile(
                      leading: const Icon(Icons.sports_esports),
                      title: Text(host.name),
                      subtitle: Text('${host.ip}:${host.port}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => widget.clientService.connectTo(host),
                    );
                  },
                ),
    );
  }
}
