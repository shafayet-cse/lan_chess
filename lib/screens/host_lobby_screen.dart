import 'package:flutter/material.dart';
import '../services/host_service.dart';
import '../services/network_service.dart';
import 'game_screen.dart';

class HostLobbyScreen extends StatefulWidget {
  final HostService hostService;
  final String localName;
  const HostLobbyScreen({super.key, required this.hostService, required this.localName});

  @override
  State<HostLobbyScreen> createState() => _HostLobbyScreenState();
}

class _HostLobbyScreenState extends State<HostLobbyScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    widget.hostService.addListener(_onChange);
    widget.hostService.start();
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    if (widget.hostService.status == ConnectionStatus.connected && !_navigated) {
      _navigated = true;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => GameScreen(
          networkService: widget.hostService,
          isHost: true,
          localName: widget.localName,
        ),
      ));
    }
  }

  @override
  void dispose() {
    widget.hostService.removeListener(_onChange);
    if (!_navigated) widget.hostService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isError = widget.hostService.status == ConnectionStatus.error;
    return Scaffold(
      appBar: AppBar(title: const Text('Hosting Game')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isError)
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent)
              else
                const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                isError
                    ? 'Could not start hosting on this network.'
                    : 'Waiting for an opponent to join ${widget.localName}\'s game...',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Make sure the other phone is connected to the same Wi-Fi network, or to this phone\'s hotspot.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
