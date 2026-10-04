// lib/games/memoria/widgets/memory_card_tile.dart

import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game_state.dart';

const kMemoryPurple = Color(0xFF8B5CF6);

/// Carta que gira em Y ao virar: verso roxo com "?" e frente com o emoji.
class MemoryCardTile extends StatelessWidget {
  const MemoryCardTile({super.key, required this.card, required this.onTap});

  final MemoryCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showFace = card.faceUp || card.matched;
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: showFace ? 1 : 0),
        duration: const Duration(milliseconds: 250),
        builder: (context, t, _) {
          final front = t >= 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(t * pi),
            child: front
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: _Front(card: card),
                  )
                : const _Back(),
          );
        },
      ),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kMemoryPurple, Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const FittedBox(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            '?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _Front extends StatelessWidget {
  const _Front({required this.card});

  final MemoryCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD6FE), width: 2),
      ),
      child: Opacity(
        opacity: card.matched ? 0.5 : 1,
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text(card.emoji, style: const TextStyle(fontSize: 40)),
          ),
        ),
      ),
    );
  }
}
