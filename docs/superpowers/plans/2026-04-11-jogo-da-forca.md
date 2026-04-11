# Jogo da Forca Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar o Jogo da Forca ao Brincaki com 7 níveis de dificuldade, boneco animado via CustomPainter e teclado A-Z colorido.

**Architecture:** Provider-based state management (ChangeNotifier), um GameProvider que contém toda a lógica. UI dividida em widgets focados: HangmanPainter (CustomPainter), WordDisplay e LetterKeyboard. A tela principal (GameScreen) orquestra os widgets e exibe overlays de vitória/derrota.

**Tech Stack:** Flutter, Provider, Google Fonts (Fredoka), CustomPainter para o boneco animado.

---

## File Map

| Arquivo | Ação | Responsabilidade |
|---------|------|-----------------|
| `lib/games/forca/models/game_state.dart` | Criar | Enums: ForcaPhase, LetterState |
| `lib/games/forca/data/word_list.dart` | Criar | Lista de palavras por nível (7 níveis) |
| `lib/games/forca/providers/game_provider.dart` | Criar | Toda a lógica do jogo |
| `lib/games/forca/widgets/hangman_painter.dart` | Criar | CustomPainter do boneco + animação |
| `lib/games/forca/widgets/word_display.dart` | Criar | Exibição dos traços e letras reveladas |
| `lib/games/forca/widgets/letter_keyboard.dart` | Criar | Grid A-Z colorido |
| `lib/games/forca/screens/game_screen.dart` | Criar | Tela principal + overlays |
| `lib/screens/menu_screen.dart` | Modificar | Adicionar card do Jogo da Forca |
| `test/games/forca/game_provider_test.dart` | Criar | Testes unitários do provider |

---

### Task 1: Models e dados

**Files:**
- Create: `lib/games/forca/models/game_state.dart`
- Create: `lib/games/forca/data/word_list.dart`

- [ ] **Step 1: Criar game_state.dart**

```dart
// lib/games/forca/models/game_state.dart

enum ForcaPhase { playing, won, lost }

enum LetterState { unguessed, correct, wrong }
```

- [ ] **Step 2: Criar word_list.dart**

```dart
// lib/games/forca/data/word_list.dart

const Map<int, List<String>> kWordsByLevel = {
  1: [
    'UVA', 'BOI', 'CEU', 'PAO', 'MAR', 'SOL', 'RIO', 'MEL',
    'COR', 'GEL', 'CHA', 'PES', 'MAO', 'OVO', 'FIM',
  ],
  2: [
    'GATO', 'BOLA', 'CAMA', 'SAPO', 'PATO', 'LOBO', 'URSO',
    'LUPA', 'VALE', 'MESA', 'LAGO', 'RODA', 'COPO', 'VELA', 'FACA',
  ],
  3: [
    'PEIXE', 'TIGRE', 'ARVORE', 'FOLHA', 'COUVE', 'PRAIA',
    'PORTO', 'BURRO', 'FORCA', 'RELVA', 'BARCO', 'PIANO',
    'MONTE', 'FONTE', 'PONTE',
  ],
  4: [
    'ELEFANTE', 'GIRAFA', 'MACACO', 'GALINHA', 'CAVALO',
    'COELHO', 'POMBO', 'AGUIA', 'GAVIAO', 'BALEIA',
    'LEAO', 'CISNE', 'PANDA', 'ZEBRA', 'LINCE',
  ],
  5: [
    'BORBOLETA', 'TARTARUGA', 'CROCODILO', 'PAPAGAIO', 'ARANHA',
    'ESCORPIAO', 'FLAMINGO', 'PINGUIM', 'CAMELO', 'LEOPARDO',
    'CANGURU', 'ORNITORRINCO', 'BESOURO', 'FORMIGA', 'LIBÉLULA',
  ],
  6: [
    'JACARANDA', 'RINOCERONTE', 'ORANGOTANGO', 'CHIMPANZE',
    'SALAMANDRA', 'ALBATROZE', 'PIRANHA', 'ANACONDA',
    'MARIPOSA', 'ESCARAVELHA', 'CAPIVARA', 'TAMANDUÁ',
    'MORCEGO', 'PORCO-ESPINHO', 'ONCA-PINTADA',
  ],
  7: [
    'HIPOPOTAMO', 'DINOSSAURO', 'CAPIVARA', 'ALBATROZ',
    'TROGLODITA', 'PTEROSSAURO', 'ESTEGOSSAURO', 'TRICERATOPS',
    'BRONTOSSAURO', 'IGUANODONTE', 'MEGALODON', 'DIPLODOCO',
    'ARQUEOPTÉRIX', 'MOSASSAURO', 'PLESIOSSAURO',
  ],
};
```

- [ ] **Step 3: Commit**

```bash
git add lib/games/forca/models/game_state.dart lib/games/forca/data/word_list.dart
git commit -m "feat(forca): add models and word list data"
```

---

### Task 2: GameProvider — lógica do jogo

**Files:**
- Create: `lib/games/forca/providers/game_provider.dart`
- Create: `test/games/forca/game_provider_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/games/forca/game_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/forca/providers/game_provider.dart';
import 'package:brincaki/games/forca/models/game_state.dart';

void main() {
  group('ForcaProvider', () {
    late ForcaProvider provider;

    setUp(() {
      provider = ForcaProvider();
    });

    test('começa no nível 1 com fase playing', () {
      expect(provider.level, 1);
      expect(provider.phase, ForcaPhase.playing);
      expect(provider.wrongCount, 0);
    });

    test('letra correta revela letra e fica verde', () {
      final firstLetter = provider.currentWord[0];
      provider.guessLetter(firstLetter);
      expect(provider.letterStates[firstLetter], LetterState.correct);
      expect(provider.revealedWord.contains(firstLetter), isTrue);
    });

    test('letra errada incrementa wrongCount e fica vermelha', () {
      // Encontra letra que não está na palavra
      final wrongLetter = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
          .split('')
          .firstWhere((l) => !provider.currentWord.contains(l));
      provider.guessLetter(wrongLetter);
      expect(provider.wrongCount, 1);
      expect(provider.letterStates[wrongLetter], LetterState.wrong);
    });

    test('6 erros resulta em derrota (fase lost)', () {
      // Garante que temos 6 letras erradas disponíveis
      final wrongLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
          .split('')
          .where((l) => !provider.currentWord.contains(l))
          .take(6)
          .toList();
      for (final l in wrongLetters) {
        provider.guessLetter(l);
      }
      expect(provider.phase, ForcaPhase.lost);
    });

    test('acertar a palavra inteira resulta em vitória (fase won)', () {
      for (final letter in provider.currentWord.split('').toSet()) {
        provider.guessLetter(letter);
      }
      expect(provider.phase, ForcaPhase.won);
    });

    test('avança de nível após vitória', () {
      expect(provider.level, 1);
      for (final letter in provider.currentWord.split('').toSet()) {
        provider.guessLetter(letter);
      }
      provider.nextWord(); // avança
      expect(provider.level, 2);
    });

    test('derrota reseta para nível 1', () {
      provider.nextWord(); // vai para nível 2
      expect(provider.level, 2);
      final wrongLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
          .split('')
          .where((l) => !provider.currentWord.contains(l))
          .take(6)
          .toList();
      for (final l in wrongLetters) {
        provider.guessLetter(l);
      }
      provider.retry(); // reseta
      expect(provider.level, 1);
    });

    test('letra já tentada é ignorada', () {
      final firstLetter = provider.currentWord[0];
      provider.guessLetter(firstLetter);
      provider.guessLetter(firstLetter); // segunda tentativa ignorada
      expect(provider.letterStates[firstLetter], LetterState.correct);
      expect(provider.wrongCount, 0);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste para confirmar falha**

```bash
flutter test test/games/forca/game_provider_test.dart
```

Esperado: erro de compilação — `ForcaProvider` não existe ainda.

- [ ] **Step 3: Implementar ForcaProvider**

```dart
// lib/games/forca/providers/game_provider.dart

import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../data/word_list.dart';

class ForcaProvider extends ChangeNotifier {
  static const int _maxErrors = 6;
  static const int _maxLevel = 7;

  int _level = 1;
  late String _currentWord;
  final Map<String, LetterState> _letterStates = {};
  final Set<String> _usedWords = {};
  ForcaPhase _phase = ForcaPhase.playing;

  ForcaProvider() {
    _pickWord();
  }

  int get level => _level;
  String get currentWord => _currentWord;
  ForcaPhase get phase => _phase;
  Map<String, LetterState> get letterStates => Map.unmodifiable(_letterStates);

  int get wrongCount =>
      _letterStates.values.where((s) => s == LetterState.wrong).length;

  /// Palavra revelada: letras acertadas no lugar, '_' para as demais.
  String get revealedWord => _currentWord
      .split('')
      .map((l) => _letterStates[l] == LetterState.correct ? l : '_')
      .join(' ');

  void guessLetter(String letter) {
    if (_phase != ForcaPhase.playing) return;
    if (_letterStates.containsKey(letter)) return;

    if (_currentWord.contains(letter)) {
      _letterStates[letter] = LetterState.correct;
      if (_isWordComplete()) {
        _phase = ForcaPhase.won;
      }
    } else {
      _letterStates[letter] = LetterState.wrong;
      if (wrongCount >= _maxErrors) {
        _phase = ForcaPhase.lost;
      }
    }
    notifyListeners();
  }

  /// Avança para a próxima palavra (chamado após vitória).
  void nextWord() {
    if (_level < _maxLevel) _level++;
    _letterStates.clear();
    _phase = ForcaPhase.playing;
    _pickWord();
    notifyListeners();
  }

  /// Reseta para o nível 1 (chamado após derrota).
  void retry() {
    _level = 1;
    _letterStates.clear();
    _usedWords.clear();
    _phase = ForcaPhase.playing;
    _pickWord();
    notifyListeners();
  }

  void _pickWord() {
    final words = kWordsByLevel[_level]!;
    final available = words.where((w) => !_usedWords.contains(w)).toList();
    // Se esgotou as palavras do nível, reseta as usadas
    final pool = available.isEmpty ? words : available;
    if (available.isEmpty) _usedWords.removeWhere((w) => words.contains(w));
    _currentWord = pool[Random().nextInt(pool.length)];
    _usedWords.add(_currentWord);
  }

  bool _isWordComplete() {
    return _currentWord.split('').every(
          (l) => _letterStates[l] == LetterState.correct,
        );
  }
}
```

- [ ] **Step 4: Rodar os testes para confirmar que passam**

```bash
flutter test test/games/forca/game_provider_test.dart
```

Esperado: todos os 8 testes passam.

- [ ] **Step 5: Commit**

```bash
git add lib/games/forca/providers/game_provider.dart test/games/forca/game_provider_test.dart
git commit -m "feat(forca): add ForcaProvider with level progression logic"
```

---

### Task 3: HangmanPainter — boneco animado

**Files:**
- Create: `lib/games/forca/widgets/hangman_painter.dart`

- [ ] **Step 1: Implementar HangmanPainter**

```dart
// lib/games/forca/widgets/hangman_painter.dart

import 'package:flutter/material.dart';

/// Widget que exibe a forca e o boneco.
/// [wrongCount] de 0 a 6 controla quantas partes são desenhadas.
/// [animationValue] de 0.0 a 1.0 anima a parte mais recente.
class HangmanWidget extends StatefulWidget {
  final int wrongCount;

  const HangmanWidget({super.key, required this.wrongCount});

  @override
  State<HangmanWidget> createState() => _HangmanWidgetState();
}

class _HangmanWidgetState extends State<HangmanWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _prevWrongCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _prevWrongCount = widget.wrongCount;
  }

  @override
  void didUpdateWidget(HangmanWidget old) {
    super.didUpdateWidget(old);
    if (widget.wrongCount > old.wrongCount) {
      _prevWrongCount = old.wrongCount;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => CustomPaint(
        size: const Size(200, 220),
        painter: _HangmanPainter(
          wrongCount: widget.wrongCount,
          newPartProgress: _animation.value,
          prevWrongCount: _prevWrongCount,
        ),
      ),
    );
  }
}

class _HangmanPainter extends CustomPainter {
  final int wrongCount;
  final double newPartProgress;
  final int prevWrongCount;

  _HangmanPainter({
    required this.wrongCount,
    required this.newPartProgress,
    required this.prevWrongCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final bodyPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // --- Forca (sempre visível) ---
    // Base
    canvas.drawLine(
      Offset(10, size.height - 10),
      Offset(size.width - 10, size.height - 10),
      paint,
    );
    // Poste vertical
    canvas.drawLine(
      Offset(50, size.height - 10),
      const Offset(50, 10),
      paint,
    );
    // Viga horizontal
    canvas.drawLine(
      const Offset(50, 10),
      Offset(size.width - 50, 10),
      paint,
    );
    // Corda
    canvas.drawLine(
      Offset(size.width - 50, 10),
      Offset(size.width - 50, 45),
      paint,
    );

    // Posições do boneco
    const cx = 150.0; // centro X do boneco
    const headTop = 45.0;
    const headRadius = 22.0;
    const bodyTop = headTop + headRadius * 2;
    const bodyBottom = bodyTop + 60.0;
    const armY = bodyTop + 15.0;
    const legBottomY = bodyBottom + 50.0;

    // Função que retorna o progresso de uma parte específica
    double progressFor(int partIndex) {
      if (wrongCount > partIndex) return 1.0; // já desenhada completamente
      if (wrongCount == partIndex + 1 && prevWrongCount == partIndex) {
        return newPartProgress; // esta é a nova parte sendo animada
      }
      return 0.0; // ainda não desenhada
    }

    // 1: Cabeça
    final headP = progressFor(0);
    if (headP > 0) {
      final sweepAngle = 2 * 3.14159 * headP;
      canvas.drawArc(
        Rect.fromCircle(
          center: const Offset(cx, headTop + headRadius),
          radius: headRadius,
        ),
        -3.14159 / 2,
        sweepAngle,
        false,
        bodyPaint,
      );
    }

    // 2: Corpo
    final bodyP = progressFor(1);
    if (bodyP > 0) {
      canvas.drawLine(
        Offset(cx, bodyTop),
        Offset(cx, bodyTop + (bodyBottom - bodyTop) * bodyP),
        bodyPaint,
      );
    }

    // 3: Braço esquerdo
    final lArmP = progressFor(2);
    if (lArmP > 0) {
      canvas.drawLine(
        Offset(cx, armY),
        Offset(cx - 35 * lArmP, armY + 30 * lArmP),
        bodyPaint,
      );
    }

    // 4: Braço direito
    final rArmP = progressFor(3);
    if (rArmP > 0) {
      canvas.drawLine(
        Offset(cx, armY),
        Offset(cx + 35 * rArmP, armY + 30 * rArmP),
        bodyPaint,
      );
    }

    // 5: Perna esquerda
    final lLegP = progressFor(4);
    if (lLegP > 0) {
      canvas.drawLine(
        Offset(cx, bodyBottom),
        Offset(cx - 30 * lLegP, bodyBottom + 50 * lLegP),
        bodyPaint,
      );
    }

    // 6: Perna direita
    final rLegP = progressFor(5);
    if (rLegP > 0) {
      canvas.drawLine(
        Offset(cx, bodyBottom),
        Offset(cx + 30 * rLegP, bodyBottom + 50 * rLegP),
        bodyPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_HangmanPainter old) =>
      old.wrongCount != wrongCount ||
      old.newPartProgress != newPartProgress;
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/games/forca/widgets/hangman_painter.dart
git commit -m "feat(forca): add animated HangmanWidget with CustomPainter"
```

---

### Task 4: WordDisplay — exibição da palavra

**Files:**
- Create: `lib/games/forca/widgets/word_display.dart`

- [ ] **Step 1: Implementar WordDisplay**

```dart
// lib/games/forca/widgets/word_display.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WordDisplay extends StatelessWidget {
  /// Palavra completa (maiúsculo, sem acento).
  final String word;

  /// Conjunto de letras corretamente adivinhadas.
  final Set<String> correctLetters;

  const WordDisplay({
    super.key,
    required this.word,
    required this.correctLetters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: word.split('').map((letter) {
          final revealed = correctLetters.contains(letter);
          return _LetterSlot(letter: letter, revealed: revealed);
        }).toList(),
      ),
    );
  }
}

class _LetterSlot extends StatelessWidget {
  final String letter;
  final bool revealed;

  const _LetterSlot({required this.letter, required this.revealed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              revealed ? letter : ' ',
              key: ValueKey(revealed),
              style: GoogleFonts.fredoka(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF16A34A),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/games/forca/widgets/word_display.dart
git commit -m "feat(forca): add WordDisplay widget with animated letter reveal"
```

---

### Task 5: LetterKeyboard — teclado A-Z colorido

**Files:**
- Create: `lib/games/forca/widgets/letter_keyboard.dart`

- [ ] **Step 1: Implementar LetterKeyboard**

```dart
// lib/games/forca/widgets/letter_keyboard.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';

const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

class LetterKeyboard extends StatelessWidget {
  final Map<String, LetterState> letterStates;
  final ValueChanged<String> onLetterTap;
  final bool disabled;

  const LetterKeyboard({
    super.key,
    required this.letterStates,
    required this.onLetterTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: _alphabet.split('').map((letter) {
          final state = letterStates[letter] ?? LetterState.unguessed;
          return _LetterButton(
            letter: letter,
            state: state,
            onTap: disabled ? null : () => onLetterTap(letter),
          );
        }).toList(),
      ),
    );
  }
}

class _LetterButton extends StatelessWidget {
  final String letter;
  final LetterState state;
  final VoidCallback? onTap;

  const _LetterButton({
    required this.letter,
    required this.state,
    this.onTap,
  });

  Color get _backgroundColor {
    return switch (state) {
      LetterState.correct => const Color(0xFF16A34A),
      LetterState.wrong => const Color(0xFFDC2626),
      LetterState.unguessed => const Color(0xFFE2E8F0),
    };
  }

  Color get _textColor {
    return switch (state) {
      LetterState.correct || LetterState.wrong => Colors.white,
      LetterState.unguessed => const Color(0xFF1E293B),
    };
  }

  @override
  Widget build(BuildContext context) {
    final interactive = state == LetterState.unguessed && onTap != null;
    return GestureDetector(
      onTap: interactive ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: interactive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            letter,
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/games/forca/widgets/letter_keyboard.dart
git commit -m "feat(forca): add LetterKeyboard widget with color states"
```

---

### Task 6: GameScreen — tela principal com overlays

**Files:**
- Create: `lib/games/forca/screens/game_screen.dart`

- [ ] **Step 1: Implementar GameScreen**

```dart
// lib/games/forca/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/hangman_painter.dart';
import '../widgets/word_display.dart';
import '../widgets/letter_keyboard.dart';

class ForcaScreen extends StatelessWidget {
  const ForcaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F9FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1D4ED8)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Consumer<ForcaProvider>(
          builder: (_, p, __) => Text(
            'Jogo da Forca  •  Nível ${p.level}',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D4ED8),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            const _GameBody(),
            const _ResultOverlay(),
          ],
        ),
      ),
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ForcaProvider>();
    final correctLetters = p.letterStates.entries
        .where((e) => e.value == LetterState.correct)
        .map((e) => e.key)
        .toSet();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Boneco
          Center(
            child: HangmanWidget(wrongCount: p.wrongCount),
          ),
          const SizedBox(height: 8),
          // Contador de erros
          Text(
            'Erros: ${p.wrongCount} / 6',
            style: GoogleFonts.fredoka(
              fontSize: 15,
              color: p.wrongCount >= 4
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),
          // Palavra
          WordDisplay(
            word: p.currentWord,
            correctLetters: correctLetters,
          ),
          const SizedBox(height: 24),
          // Teclado
          LetterKeyboard(
            letterStates: p.letterStates,
            onLetterTap: p.guessLetter,
            disabled: p.phase != ForcaPhase.playing,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ForcaProvider>();
    if (p.phase == ForcaPhase.playing) return const SizedBox.shrink();

    final won = p.phase == ForcaPhase.won;

    return AnimatedOpacity(
      opacity: p.phase != ForcaPhase.playing ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 350),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  won ? '🎉' : '💀',
                  style: const TextStyle(fontSize: 56),
                ),
                const SizedBox(height: 8),
                Text(
                  won ? 'Parabéns!' : 'Que pena...',
                  style: GoogleFonts.fredoka(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: won
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
                if (!won) ...[
                  const SizedBox(height: 8),
                  Text(
                    'A palavra era:',
                    style: GoogleFonts.fredoka(
                      fontSize: 15,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    p.currentWord,
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
                if (won && p.level < 7) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Avançando para o nível ${p.level + 1}!',
                    style: GoogleFonts.fredoka(
                      fontSize: 15,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: won ? p.nextWord : p.retry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: won
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    won ? 'Próxima Palavra →' : 'Tentar Novamente',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/games/forca/screens/game_screen.dart
git commit -m "feat(forca): add ForcaScreen with game body and result overlays"
```

---

### Task 7: Integração no menu

**Files:**
- Modify: `lib/screens/menu_screen.dart`

- [ ] **Step 1: Adicionar import e método no MenuScreen**

No topo do arquivo `lib/screens/menu_screen.dart`, adicionar os imports:

```dart
import '../games/forca/screens/game_screen.dart';
import '../games/forca/providers/game_provider.dart' as forca;
```

Após o método `_openTicTacToe`, adicionar:

```dart
void _openForca(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider(
        create: (_) => forca.ForcaProvider(),
        child: Theme(
          data: ThemeData(
            colorSchemeSeed: const Color(0xFF3B82F6),
            useMaterial3: true,
            textTheme: GoogleFonts.fredokaTextTheme(),
          ),
          child: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => const ForcaScreen(),
            ),
          ),
        ),
      ),
    ),
  );
}
```

- [ ] **Step 2: Adicionar o card no build()**

No método `build()` do `MenuScreen`, após o card do Jogo da Velha, adicionar:

```dart
const SizedBox(height: 16),
_buildGameCard(
  emoji: '🪢',
  title: 'Jogo da Forca',
  description: 'Adivinhe a palavra letra por letra!',
  tags: const ['7 níveis', 'Vocabulário'],
  gradientColors: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
  shadowColor: const Color(0xFF3B82F6),
  onTap: () => _openForca(context),
),
```

- [ ] **Step 3: Rodar o app para confirmar compilação**

```bash
flutter run --debug
```

Esperado: app abre no menu com o card "Jogo da Forca". Ao tocar, abre a tela do jogo.

- [ ] **Step 4: Commit final**

```bash
git add lib/screens/menu_screen.dart
git commit -m "feat(forca): integrate Jogo da Forca into main menu"
```

---

## Self-Review

**Cobertura do spec:**
- [x] 7 níveis com palavras por dificuldade — Task 1
- [x] Progressão: acerto avança nível, erro reseta — Task 2 (ForcaProvider.nextWord / retry)
- [x] Boneco animado com 6 partes — Task 3
- [x] Letras vermelhas (erros) e verdes (acertos) — Tasks 4 e 5
- [x] Teclado desabilitado durante overlays — Task 6 (disabled param)
- [x] Card no menu — Task 7

**Sem placeholders:** Todos os steps têm código completo.

**Consistência de tipos:**
- `ForcaProvider` expõe `level`, `currentWord`, `phase`, `letterStates`, `wrongCount`, `revealedWord`, `guessLetter()`, `nextWord()`, `retry()` — usados consistentemente nos widgets.
- `LetterState` enum usado no provider e consumido pelo keyboard com o mesmo nome.
- `HangmanWidget` recebe `wrongCount: int` — alimentado pelo provider em GameScreen.
