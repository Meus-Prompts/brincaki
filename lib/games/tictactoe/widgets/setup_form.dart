// lib/games/tictactoe/widgets/setup_form.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class SetupForm extends StatefulWidget {
  const SetupForm({super.key});

  @override
  State<SetupForm> createState() => _SetupFormState();
}

class _SetupFormState extends State<SetupForm> {
  final _p1Controller = TextEditingController();
  final _p2Controller = TextEditingController();

  bool get _canStart =>
      _p1Controller.text.trim().isNotEmpty &&
      _p2Controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _p1Controller.dispose();
    _p2Controller.dispose();
    super.dispose();
  }

  void _start(BuildContext context) {
    if (!_canStart) return;
    context.read<TicTacToeProvider>().setNames(
          _p1Controller.text.trim(),
          _p2Controller.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            '✖️⭕',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 56),
          ),
          const SizedBox(height: 8),
          Text(
            'Jogo da Velha',
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFBE185D),
            ),
          ),
          const SizedBox(height: 40),
          _PlayerField(
            label: '❌ Nome do Jogador 1',
            controller: _p1Controller,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _PlayerField(
            label: '⭕ Nome do Jogador 2',
            controller: _p2Controller,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _canStart ? () => _start(context) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFFBBF24).withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Jogar! 🎮',
              style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _PlayerField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.words,
      style: GoogleFonts.fredoka(fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.fredoka(color: const Color(0xFFBE185D)),
        filled: true,
        fillColor: const Color(0xFFFDF2F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFBBF24)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEC4899), width: 2),
        ),
      ),
    );
  }
}
