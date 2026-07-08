import 'package:flutter/foundation.dart';
import 'package:chess/chess.dart' as ch;

enum GameOverReason {
  none,
  checkmate,
  stalemate,
  draw,
  threefoldRepetition,
  insufficientMaterial,
  resignation,
}

/// Wraps the `chess` package (a Dart port of chess.js) and exposes just
/// what the UI needs: board state, legal-move highlighting, move
/// application (local or remote), and game-over detection. All official
/// rules - check, checkmate, castling, en passant, promotion, stalemate,
/// draw by repetition/insufficient material - are handled by the
/// underlying library; this class just adapts it for the app.
class ChessGameController extends ChangeNotifier {
  final ch.Chess game = ch.Chess();

  /// True if the local device is playing White (the host is always White,
  /// the joiner is always Black - see README for why this is kept simple).
  final bool localPlaysWhite;

  String? selectedSquare;
  List<String> legalTargets = [];

  /// Move history in simple coordinate notation, e.g. "e2-e4", easy to
  /// read and completely independent of the chess package's internal SAN
  /// generation (which varies between library versions).
  final List<String> moveHistory = [];

  bool isGameOver = false;
  GameOverReason overReason = GameOverReason.none;
  String? winner; // 'white' | 'black' | null (draw)

  ChessGameController({required this.localPlaysWhite});

  /// Whether it is currently the local player's turn.
  bool get localToMove => whiteToMove == localPlaysWhite;

  bool get whiteToMove => game.turn == ch.Color.WHITE;

  ch.Piece? pieceAt(String square) => game.get(square);

  bool isLocalPieceAt(String square) {
    final piece = pieceAt(square);
    if (piece == null) return false;
    final pieceIsWhite = piece.color == ch.Color.WHITE;
    return pieceIsWhite == localPlaysWhite;
  }

  void selectSquare(String square) {
    if (!localToMove || isGameOver) return;
    if (!isLocalPieceAt(square)) return;
    selectedSquare = square;
    legalTargets = _legalTargetsFrom(square);
    notifyListeners();
  }

  void clearSelection() {
    selectedSquare = null;
    legalTargets = [];
    notifyListeners();
  }

  /// Derives legal destination squares for [square] from the SAN move list
  /// the library returns. Destination square is always the last two
  /// characters of standard algebraic notation once check/mate symbols and
  /// any promotion suffix are stripped, with castling handled explicitly.
  List<String> _legalTargetsFrom(String square) {
    final rawMoves = game.moves({'square': square}) as List;
    final piece = pieceAt(square);
    final isWhite = piece?.color == ch.Color.WHITE;
    final targets = <String>[];

    for (final m in rawMoves) {
      final san = m.toString();
      if (san == 'O-O') {
        targets.add(isWhite ? 'g1' : 'g8');
        continue;
      }
      if (san == 'O-O-O') {
        targets.add(isWhite ? 'c1' : 'c8');
        continue;
      }
      var s = san.replaceAll('+', '').replaceAll('#', '');
      if (s.contains('=')) s = s.split('=')[0];
      if (s.length >= 2) targets.add(s.substring(s.length - 2));
    }
    return targets;
  }

  bool needsPromotion(String from, String to) {
    final piece = pieceAt(from);
    if (piece == null || piece.type != ch.PieceType.PAWN) return false;
    final destinationRank = to[1];
    return destinationRank == '1' || destinationRank == '8';
  }

  /// Attempts a move made by the local player. Returns true on success.
  bool attemptMove(String from, String to, {String? promotion}) {
    final success = _applyMove(from, to, promotion: promotion);
    clearSelection();
    return success;
  }

  /// Applies a move received from the opponent over the network.
  void applyRemoteMove(String from, String to, {String? promotion}) {
    _applyMove(from, to, promotion: promotion);
  }

  bool _applyMove(String from, String to, {String? promotion}) {
    final moveMap = <String, String>{'from': from, 'to': to};
    if (promotion != null) moveMap['promotion'] = promotion;

    final result = game.move(moveMap);
    final success = result != null && result != false;
    if (success) {
      moveHistory.add(promotion != null ? '$from-$to=${promotion.toUpperCase()}' : '$from-$to');
      _checkGameOver();
      notifyListeners();
    }
    return success;
  }

  void _checkGameOver() {
    if (game.in_checkmate) {
      isGameOver = true;
      overReason = GameOverReason.checkmate;
      // The side to move now is the side that got checkmated.
      winner = whiteToMove ? 'black' : 'white';
    } else if (game.in_stalemate) {
      isGameOver = true;
      overReason = GameOverReason.stalemate;
      winner = null;
    } else if (game.in_threefold_repetition) {
      isGameOver = true;
      overReason = GameOverReason.threefoldRepetition;
      winner = null;
    } else if (game.insufficient_material) {
      isGameOver = true;
      overReason = GameOverReason.insufficientMaterial;
      winner = null;
    } else if (game.in_draw) {
      isGameOver = true;
      overReason = GameOverReason.draw;
      winner = null;
    }
  }

  /// [resigningPlayerIsWhite] identifies who gave up.
  void resign(bool resigningPlayerIsWhite) {
    isGameOver = true;
    overReason = GameOverReason.resignation;
    winner = resigningPlayerIsWhite ? 'black' : 'white';
    notifyListeners();
  }

  void reset() {
    game.reset();
    selectedSquare = null;
    legalTargets = [];
    moveHistory.clear();
    isGameOver = false;
    overReason = GameOverReason.none;
    winner = null;
    notifyListeners();
  }

  String get statusText {
    if (isGameOver) {
      final winnerLabel = winner == 'white' ? 'White' : 'Black';
      switch (overReason) {
        case GameOverReason.checkmate:
          return 'Checkmate — $winnerLabel wins';
        case GameOverReason.stalemate:
          return 'Draw — stalemate';
        case GameOverReason.threefoldRepetition:
          return 'Draw — threefold repetition';
        case GameOverReason.insufficientMaterial:
          return 'Draw — insufficient material';
        case GameOverReason.draw:
          return 'Draw';
        case GameOverReason.resignation:
          return '$winnerLabel wins by resignation';
        case GameOverReason.none:
          return 'Game over';
      }
    }
    final sideLabel = whiteToMove ? 'White' : 'Black';
    if (game.in_check) return '$sideLabel is in check';
    return '$sideLabel to move';
  }
}
