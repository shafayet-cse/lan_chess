import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_message.dart';
import '../services/chess_game_controller.dart';
import '../services/network_service.dart';
import '../widgets/chess_board_widget.dart';
import '../widgets/player_info_bar.dart';
import '../widgets/move_history_panel.dart';

class GameScreen extends StatefulWidget {
  final NetworkService networkService;
  final bool isHost; // host is always White, joiner is always Black
  final String localName;

  const GameScreen({
    super.key,
    required this.networkService,
    required this.isHost,
    required this.localName,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late ChessGameController _controller;
  Timer? _clock;

  int _whiteSeconds = 0;
  int _blackSeconds = 0;
  bool _rematchRequestedByMe = false;
  bool _opponentWantsRematch = false;

  @override
  void initState() {
    super.initState();
    _controller = ChessGameController(localPlaysWhite: widget.isHost);
    widget.networkService.onMessage = _handleNetworkMessage;
    widget.networkService.addListener(_onNetworkChanged);

    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_controller.isGameOver) return;
      setState(() {
        if (_controller.whiteToMove) {
          _whiteSeconds++;
        } else {
          _blackSeconds++;
        }
      });
    });
  }

  void _onNetworkChanged() {
    if (mounted) setState(() {});
  }

  void _handleNetworkMessage(GameMessage msg) {
    switch (msg.type) {
      case MessageType.move:
        _controller.applyRemoteMove(
          msg.data['from'] as String,
          msg.data['to'] as String,
          promotion: msg.data['promotion'] as String?,
        );
        break;
      case MessageType.resign:
        // The opponent resigned - the opponent plays the color opposite ours.
        _controller.resign(!_controller.localPlaysWhite);
        break;
      case MessageType.restartRequest:
        setState(() => _opponentWantsRematch = true);
        break;
      case MessageType.restartAccept:
        _startRematch();
        break;
      case MessageType.hello:
        break; // handled inside the network services themselves
    }
    if (mounted) setState(() {});
  }

  void _onLocalMove(String from, String to, {String? promotion}) {
    widget.networkService.send(GameMessage(MessageType.move, {
      'from': from,
      'to': to,
      if (promotion != null) 'promotion': promotion,
    }));
    setState(() {});
  }

  void _requestOrAcceptRematch() {
    if (_opponentWantsRematch) {
      widget.networkService.send(GameMessage(MessageType.restartAccept));
      _startRematch();
    } else if (!_rematchRequestedByMe) {
      widget.networkService.send(GameMessage(MessageType.restartRequest));
      setState(() => _rematchRequestedByMe = true);
    }
  }

  void _startRematch() {
    setState(() {
      _controller.reset();
      _whiteSeconds = 0;
      _blackSeconds = 0;
      _rematchRequestedByMe = false;
      _opponentWantsRematch = false;
    });
  }

  void _resign() {
    widget.networkService.send(GameMessage(MessageType.resign));
    _controller.resign(_controller.localPlaysWhite);
    setState(() {});
  }

  @override
  void dispose() {
    _clock?.cancel();
    widget.networkService.removeListener(_onNetworkChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opponentName = widget.networkService.opponentName ?? 'Opponent';
    final myName = widget.localName;

    // Always draw the opponent at the top, the local player at the bottom.
    final topName = opponentName;
    final bottomName = myName;
    final topIsWhite = !_controller.localPlaysWhite;
    final bottomIsWhite = _controller.localPlaysWhite;

    final connected = widget.networkService.status == ConnectionStatus.connected;

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_controller.statusText, overflow: TextOverflow.ellipsis),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 10, color: connected ? Colors.greenAccent : Colors.redAccent),
                  const SizedBox(width: 6),
                  Text(
                    connected ? 'Connected' : 'Disconnected',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              PlayerInfoBar(
                name: topName,
                isWhite: topIsWhite,
                seconds: topIsWhite ? _whiteSeconds : _blackSeconds,
                isActive: !_controller.isGameOver && _controller.whiteToMove == topIsWhite,
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ChessBoardWidget(onLocalMove: _onLocalMove),
                  ),
                ),
              ),
              PlayerInfoBar(
                name: bottomName,
                isWhite: bottomIsWhite,
                seconds: bottomIsWhite ? _whiteSeconds : _blackSeconds,
                isActive: !_controller.isGameOver && _controller.whiteToMove == bottomIsWhite,
              ),
              const Divider(height: 1),
              SizedBox(
                height: 56,
                child: MoveHistoryPanel(history: _controller.moveHistory),
              ),
              if (_controller.isGameOver)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _controller.statusText,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _controller.isGameOver ? null : _resign,
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Resign'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _requestOrAcceptRematch,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        _opponentWantsRematch
                            ? 'Accept rematch'
                            : (_rematchRequestedByMe ? 'Waiting for opponent...' : 'Rematch'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
