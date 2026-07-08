import 'package:flutter/material.dart';
import '../services/host_service.dart';
import '../services/client_service.dart';
import 'host_lobby_screen.dart';
import 'join_lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameController = TextEditingController();

  String _resolvedName(String fallback) {
    final trimmed = _nameController.text.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LAN Chess')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sports_esports, size: 72, color: Color(0xFF769656)),
                const SizedBox(height: 16),
                const Text(
                  'Offline Wi-Fi Chess',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Play a friend on the same Wi-Fi or hotspot. No internet, no server, no account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.wifi_tethering),
                    label: const Text('Host Game'),
                    onPressed: () {
                      final name = _resolvedName('Host');
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => HostLobbyScreen(
                          hostService: HostService(playerName: name),
                          localName: name,
                        ),
                      ));
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Join Game'),
                    onPressed: () {
                      final name = _resolvedName('Guest');
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => JoinLobbyScreen(
                          clientService: ClientService(playerName: name),
                          localName: name,
                        ),
                      ));
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'The host is always White, the joiner is always Black.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
