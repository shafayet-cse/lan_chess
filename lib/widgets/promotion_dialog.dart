import 'package:flutter/material.dart';

/// Shows a dialog letting the player pick a piece to promote a pawn to.
/// Returns the piece code ('q', 'r', 'b', 'n') or null if dismissed.
Future<String?> showPromotionDialog(BuildContext context, bool isWhite) {
  final options = [
    {'code': 'q', 'glyph': isWhite ? '♕' : '♛', 'name': 'Queen'},
    {'code': 'r', 'glyph': isWhite ? '♖' : '♜', 'name': 'Rook'},
    {'code': 'b', 'glyph': isWhite ? '♗' : '♝', 'name': 'Bishop'},
    {'code': 'n', 'glyph': isWhite ? '♘' : '♞', 'name': 'Knight'},
  ];

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text('Promote pawn to'),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: options.map((o) {
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Navigator.of(context).pop(o['code']),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text(o['glyph']!, style: const TextStyle(fontSize: 34)),
                    const SizedBox(height: 4),
                    Text(o['name']!, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
    },
  );
}
