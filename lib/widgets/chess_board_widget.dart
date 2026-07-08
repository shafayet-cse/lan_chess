import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chess/chess.dart' as ch;

import '../services/chess_game_controller.dart';
import 'promotion_dialog.dart';

/// Renders the 8x8 board, oriented so each player always sees their own
/// pieces at the bottom. Supports both tap-to-move and drag-and-drop.
class ChessBoardWidget extends StatelessWidget {
  final void Function(String from, String to, {String? promotion}) onLocalMove;

  const ChessBoardWidget({super.key, required this.onLocalMove});

  static const _lightSquare = Color(0xFFEEEED2);
  static const _darkSquare = Color(0xFF769656);
  static const _selectedSquare = Color(0xFFF6F669);
  static const _checkSquare = Color(0xFFEF6B6B);

  static const _pieceGlyphs = {
    'PAWN': {'w': '♙', 'b': '♟'},
    'KNIGHT': {'w': '♘', 'b': '♞'},
    'BISHOP': {'w': '♗', 'b': '♝'},
    'ROOK': {'w': '♖', 'b': '♜'},
    'QUEEN': {'w': '♕', 'b': '♛'},
    'KING': {'w': '♔', 'b': '♚'},
  };

  String _glyphFor(ch.Piece piece) {
    // ch.PieceType wraps a name like PAWN/KNIGHT/... - fall back to the
    // raw string form if the enum's naming differs between package versions.
    final key = piece.type.toString().split('.').last.toUpperCase();
    final color = piece.color == ch.Color.WHITE ? 'w' : 'b';
    return _pieceGlyphs[key]?[color] ?? '?';
  }

  bool _isKingSquare(ChessGameController controller, String square, bool inCheck) {
    if (!inCheck) return false;
    final piece = controller.pieceAt(square);
    if (piece == null || piece.type != ch.PieceType.KING) return false;
    final kingIsWhite = piece.color == ch.Color.WHITE;
    return kingIsWhite == controller.whiteToMove;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChessGameController>();
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    final ranks = controller.localPlaysWhite ? [8, 7, 6, 5, 4, 3, 2, 1] : [1, 2, 3, 4, 5, 6, 7, 8];
    final orderedFiles = controller.localPlaysWhite ? files : files.reversed.toList();
    final inCheck = controller.game.in_check;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final squareSize = boardSize / 8;
        return SizedBox(
          width: boardSize,
          height: boardSize,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ranks.map((rank) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: orderedFiles.map((file) {
                  final square = '$file$rank';
                  return _buildSquare(context, controller, square, squareSize, inCheck);
                }).toList(),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSquare(
    BuildContext context,
    ChessGameController controller,
    String square,
    double size,
    bool inCheck,
  ) {
    final fileIndex = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rankIndex = int.parse(square[1]);
    final isLight = (fileIndex + rankIndex) % 2 == 0;

    Color squareColor = isLight ? _lightSquare : _darkSquare;
    if (_isKingSquare(controller, square, inCheck)) {
      squareColor = _checkSquare;
    } else if (controller.selectedSquare == square) {
      squareColor = _selectedSquare;
    }

    final piece = controller.pieceAt(square);
    final isLegalTarget = controller.legalTargets.contains(square);

    final content = Container(
      width: size,
      height: size,
      color: squareColor,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (piece != null)
            Text(_glyphFor(piece), style: TextStyle(fontSize: size * 0.68)),
          if (isLegalTarget)
            Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
            ),
        ],
      ),
    );

    final canDrag = piece != null && controller.isLocalPieceAt(square) && controller.localToMove;

    final dragTarget = DragTarget<String>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => _handleDrop(context, controller, details.data, square),
      builder: (context, candidateData, rejectedData) => content,
    );

    return GestureDetector(
      onTap: () => _handleTap(context, controller, square),
      child: canDrag
          ? Draggable<String>(
              data: square,
              feedback: Material(
                color: Colors.transparent,
                child: Text(_glyphFor(piece), style: TextStyle(fontSize: size * 0.68)),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: content),
              child: dragTarget,
            )
          : dragTarget,
    );
  }

  void _handleTap(BuildContext context, ChessGameController controller, String square) {
    if (controller.selectedSquare == null) {
      controller.selectSquare(square);
    } else if (controller.selectedSquare == square) {
      controller.clearSelection();
    } else if (controller.legalTargets.contains(square)) {
      _executeMove(context, controller, controller.selectedSquare!, square);
    } else {
      controller.selectSquare(square);
    }
  }

  Future<void> _handleDrop(
    BuildContext context,
    ChessGameController controller,
    String from,
    String to,
  ) async {
    if (!controller.localToMove || !controller.isLocalPieceAt(from)) return;
    controller.selectSquare(from);
    if (!controller.legalTargets.contains(to)) {
      controller.clearSelection();
      return;
    }
    await _executeMove(context, controller, from, to);
  }

  Future<void> _executeMove(
    BuildContext context,
    ChessGameController controller,
    String from,
    String to,
  ) async {
    String? promotion;
    if (controller.needsPromotion(from, to)) {
      final piece = controller.pieceAt(from);
      promotion = await showPromotionDialog(context, piece?.color == ch.Color.WHITE);
      if (promotion == null) {
        controller.clearSelection();
        return;
      }
    }
    final success = controller.attemptMove(from, to, promotion: promotion);
    if (success) {
      onLocalMove(from, to, promotion: promotion);
    }
  }
}
