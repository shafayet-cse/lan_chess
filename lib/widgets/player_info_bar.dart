import 'dart:ui';
import 'package:flutter/material.dart';

class PlayerInfoBar extends StatelessWidget {
  final String name;
  final bool isWhite;
  final int seconds;
  final bool isActive;

  const PlayerInfoBar({
    super.key,
    required this.name,
    required this.isWhite,
    required this.seconds,
    required this.isActive,
  });

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: isActive ? Colors.green.withOpacity(0.10) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            isWhite ? Icons.circle_outlined : Icons.circle,
            size: 16,
            color: isWhite ? Colors.black87 : Colors.black87,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? Colors.black87 : Colors.black12,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _fmt(seconds),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black54,
                fontFeatures: const [FontFeature.tabularFigures()],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
