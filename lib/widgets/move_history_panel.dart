import 'package:flutter/material.dart';

/// Horizontal scrolling strip of move pairs, newest first.
class MoveHistoryPanel extends StatelessWidget {
  final List<String> history;
  const MoveHistoryPanel({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Text('Moves will appear here', style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }

    final pairs = <String>[];
    for (int i = 0; i < history.length; i += 2) {
      final white = history[i];
      final black = (i + 1 < history.length) ? history[i + 1] : '';
      pairs.add('${(i ~/ 2) + 1}. $white${black.isNotEmpty ? '  $black' : ''}');
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      itemCount: pairs.length,
      itemBuilder: (context, index) {
        final pair = pairs[pairs.length - 1 - index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Chip(
            label: Text(pair, style: const TextStyle(fontSize: 12)),
            visualDensity: VisualDensity.compact,
            backgroundColor: index == 0 ? Colors.green.withOpacity(0.15) : null,
          ),
        );
      },
    );
  }
}
