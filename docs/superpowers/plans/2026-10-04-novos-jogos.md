# Novos Jogos (Memória, Termo, Lig 4) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar Jogo da Memória, Termo e Lig 4 ao Brincaki, cada um com card no menu, testes e o mesmo padrão dos jogos atuais.

**Architecture:**
- Cada jogo é um módulo em `lib/games/<jogo>/`, com:
  - lógica pura em `logic/`;
  - um `ChangeNotifier` em `providers/`;
  - telas em `screens/` e `widgets/`.
- A Memória e o Lig 4 usam dois widgets novos em `lib/widgets/`: `PlayerSetup` e `ScoreBoard`.
- O Termo lê listas de palavras de `assets/termo/`, geradas por `tool/build_termo_words.py` a partir do fserb/pt-br (MIT). A palavra do dia fica salva em `shared_preferences`.

**Tech Stack:** Flutter 3.44 / Dart 3.12, `provider`, `google_fonts` (Fredoka empacotada), `shared_preferences`, `flutter_test`, Python 3 só para o script de dados.

**Spec:** `docs/superpowers/specs/2026-10-04-novos-jogos-design.md`

## Global Constraints

- Textos de interface em pt-BR. Fonte via `GoogleFonts.fredoka(...)`.
- Todo arquivo `.dart` novo começa com o comentário do próprio caminho (`// lib/...` ou `// test/...`).
- A seta "voltar" da primeira tela de cada jogo usa `Icons.arrow_back`, `tooltip: 'Voltar ao menu'` e `Navigator.of(context, rootNavigator: true).pop()`.
- Sem acesso à internet em tempo de execução. O script do Termo é a única coisa que baixa dados, e só quando o desenvolvedor o executa.
- Única persistência nova: a chave `termo_daily` (JSON com `date` e `guesses`).
- Nenhum `pumpAndSettle` pode depender de animação infinita: animações repetidas usam `count`.
- Commits no estilo do histórico (`feat(memoria): ...`, `feat(termo): ...`, `feat(lig4): ...`, em inglês). Toda mensagem de commit termina com:
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt
  ```
- Branch: `feat/novos-jogos`.

**Desvios conscientes da spec:**
- O léxico do fserb vem todo em minúsculas, então o filtro "nenhuma que comece com maiúscula" não existe. Nomes próprios, estrangeirismos, contrações e palavrões saem pela lista `EXCLUIR`, montada lendo as 1.300 candidatas mais frequentes (`REVISADAS`), e só essa faixa revisada vira resposta. Resultado conferido: **902 respostas** e **8.628 válidas**.
- As grades da Memória ficam em pé: o "3×4" da spec vira 4 linhas por 3 colunas, e assim por diante, porque o app só roda na vertical.
- A tela do Termo mostra o texto "Carregando palavras..." em vez de um indicador animado, para os testes de widget não ficarem esperando uma animação infinita.
- `WordBank.load` usa `bundle.load` e decodifica em UTF-8 em vez de `loadString`, que manda arquivos grandes para um isolate e pode travar nos testes.

## Review Focus

1. **Memória, toques rápidos:** enquanto duas cartas erradas estão à mostra, um terceiro toque não pode virar carta. Sair da tela com o `Timer` pendente também não pode dar erro. Testes nas Tasks 2 e 3.
2. **Termo, palavra do dia com estado salvo inválido ou de outro dia:** um JSON corrompido ou tentativas que não estão mais no dicionário não podem travar o jogo. Um dia novo começa limpo. Testes na Task 5.
3. **Termo, letras repetidas:** as cores seguem a regra oficial (`ARARA` contra `CARRO`, `SALAS` contra `ASSAR`), e o teclado nunca rebaixa uma letra verde para amarela. Testes nas Tasks 5 e 6.
4. **Lig 4, toque durante a vez do computador ou depois de sair:** o toque é ignorado, e uma jogada do computador que chega depois de "Trocar jogadores" ou "Jogar de novo" é descartada. Testes na Task 8.
5. **Lig 4, nível Difícil:** decide em menos de 2 s e nunca escolhe uma coluna cheia; o Médio sempre bloqueia. Testes na Task 7.

---

### Task 1: Componentes compartilhados (`PlayerSetup`, `ScoreBoard`)

**Files:**
- Create: `lib/widgets/player_setup.dart`
- Create: `lib/widgets/score_board.dart`
- Test: `test/widgets/player_setup_test.dart`
- Test: `test/widgets/score_board_test.dart`

**Interfaces:**
- Produces:
  - `enum PlayMode { solo, twoPlayers }`
  - `class PlayerSetupResult { final PlayMode mode; final String player1; final String player2; final int? levelIndex; }`
  - `PlayerSetup({required String title, required String emoji, required Color accent, required String soloLabel, required (String, String) symbols, required ValueChanged<PlayerSetupResult> onStart, List<String>? levels, String? soloOpponentName})`
  - `ScoreBoard({required String name1, required String name2, required String symbol1, required String symbol2, required int score1, required int score2, required int draws, int? activePlayer, required Color accent})`
  - Keys usadas nos testes: `Key('name1')` e `Key('name2')` nos campos de nome.

- [ ] **Step 1: Escrever os testes que falham**

```dart
// test/widgets/player_setup_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/widgets/player_setup.dart';

void main() {
  PlayerSetupResult? result;

  Future<void> pumpSetup(WidgetTester tester,
      {List<String>? levels, String? opponent}) async {
    result = null;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PlayerSetup(
          title: 'Lig 4',
          emoji: '🔴',
          accent: Colors.red,
          soloLabel: 'Contra o computador',
          symbols: ('🔴', '🟡'),
          levels: levels,
          soloOpponentName: opponent,
          onStart: (r) => result = r,
        ),
      ),
    ));
  }

  testWidgets('solo sem nome usa os nomes padrão e o primeiro nível',
      (tester) async {
    await pumpSetup(tester,
        levels: ['Fácil', 'Médio', 'Difícil'], opponent: 'Computador');
    await tester.tap(find.text('Jogar!'));
    expect(result!.mode, PlayMode.solo);
    expect(result!.player1, 'Jogador 1');
    expect(result!.player2, 'Computador');
    expect(result!.levelIndex, 0);
  });

  testWidgets('solo com nível escolhido', (tester) async {
    await pumpSetup(tester,
        levels: ['Fácil', 'Médio', 'Difícil'], opponent: 'Computador');
    await tester.enterText(find.byKey(const Key('name1')), '  Ana  ');
    await tester.tap(find.text('Difícil'));
    await tester.pump();
    await tester.tap(find.text('Jogar!'));
    expect(result!.player1, 'Ana');
    expect(result!.levelIndex, 2);
  });

  testWidgets('dois jogadores mostra dois nomes e esconde os níveis',
      (tester) async {
    await pumpSetup(tester,
        levels: ['Fácil', 'Médio', 'Difícil'], opponent: 'Computador');
    await tester.tap(find.text('Dois jogadores'));
    await tester.pump();
    expect(find.text('Médio'), findsNothing);
    await tester.enterText(find.byKey(const Key('name1')), 'Ana');
    await tester.enterText(find.byKey(const Key('name2')), 'Beto');
    await tester.tap(find.text('Jogar!'));
    expect(result!.mode, PlayMode.twoPlayers);
    expect(result!.player1, 'Ana');
    expect(result!.player2, 'Beto');
    expect(result!.levelIndex, isNull);
  });

  testWidgets('dois jogadores sem nomes usa Jogador 1 e Jogador 2',
      (tester) async {
    await pumpSetup(tester);
    await tester.tap(find.text('Dois jogadores'));
    await tester.pump();
    await tester.tap(find.text('Jogar!'));
    expect(result!.player1, 'Jogador 1');
    expect(result!.player2, 'Jogador 2');
  });

  testWidgets('solo sem adversário (Memória) deixa player2 vazio',
      (tester) async {
    await pumpSetup(tester);
    await tester.tap(find.text('Jogar!'));
    expect(result!.player2, '');
    expect(result!.levelIndex, isNull);
  });

  testWidgets('cabe num celular pequeno', (tester) async {
    tester.view.physicalSize = const Size(320, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpSetup(tester,
        levels: ['Fácil', 'Médio', 'Difícil'], opponent: 'Computador');
    expect(tester.takeException(), isNull);
  });
}
```

```dart
// test/widgets/score_board_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/widgets/score_board.dart';

void main() {
  testWidgets('mostra nomes, pontos e empates', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ScoreBoard(
          name1: 'Ana',
          name2: 'Beto',
          symbol1: '🔴',
          symbol2: '🟡',
          score1: 3,
          score2: 1,
          draws: 2,
          activePlayer: 1,
          accent: Colors.red,
        ),
      ),
    ));
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Beto'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Empates'), findsOneWidget);
  });

  testWidgets('nomes longos não estouram num celular pequeno', (tester) async {
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ScoreBoard(
          name1: 'Maria Eduarda',
          name2: 'João Guilherme',
          symbol1: '🐶',
          symbol2: '🐱',
          score1: 10,
          score2: 12,
          draws: 3,
          accent: Colors.purple,
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/widgets`
Esperado: FAIL na compilação, porque `player_setup.dart` e `score_board.dart` não existem.

- [ ] **Step 3: Implementar `PlayerSetup`**

```dart
// lib/widgets/player_setup.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum PlayMode { solo, twoPlayers }

class PlayerSetupResult {
  const PlayerSetupResult({
    required this.mode,
    required this.player1,
    required this.player2,
    this.levelIndex,
  });

  final PlayMode mode;
  final String player1;

  /// "Jogador 2" em dois jogadores; no solo, o nome do adversário (ou vazio).
  final String player2;

  /// Índice em `levels`, só no modo solo quando há níveis.
  final int? levelIndex;
}

/// Tela inicial dos jogos com modo solo e de dois jogadores.
class PlayerSetup extends StatefulWidget {
  const PlayerSetup({
    super.key,
    required this.title,
    required this.emoji,
    required this.accent,
    required this.soloLabel,
    required this.symbols,
    required this.onStart,
    this.levels,
    this.soloOpponentName,
  });

  final String title;
  final String emoji;
  final Color accent;
  final String soloLabel;
  final (String, String) symbols;
  final ValueChanged<PlayerSetupResult> onStart;
  final List<String>? levels;
  final String? soloOpponentName;

  @override
  State<PlayerSetup> createState() => _PlayerSetupState();
}

class _PlayerSetupState extends State<PlayerSetup> {
  PlayMode _mode = PlayMode.solo;
  int _level = 0;
  final _name1 = TextEditingController();
  final _name2 = TextEditingController();

  @override
  void dispose() {
    _name1.dispose();
    _name2.dispose();
    super.dispose();
  }

  String _nameOr(TextEditingController controller, String fallback) {
    final name = controller.text.trim();
    return name.isEmpty ? fallback : name;
  }

  void _start() {
    final solo = _mode == PlayMode.solo;
    widget.onStart(PlayerSetupResult(
      mode: _mode,
      player1: _nameOr(_name1, 'Jogador 1'),
      player2: solo ? (widget.soloOpponentName ?? '') : _nameOr(_name2, 'Jogador 2'),
      levelIndex: solo && widget.levels != null ? _level : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final solo = _mode == PlayMode.solo;
    final levels = widget.levels;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(widget.emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: widget.accent,
            ),
          ),
          const SizedBox(height: 24),
          SegmentedButton<PlayMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: PlayMode.solo, label: Text(widget.soloLabel)),
              const ButtonSegment(
                value: PlayMode.twoPlayers,
                label: Text('Dois jogadores'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 20),
          _NameField(
            key: const Key('name1'),
            controller: _name1,
            symbol: widget.symbols.$1,
            label: solo ? 'Seu nome' : 'Nome do Jogador 1',
          ),
          if (!solo) ...[
            const SizedBox(height: 12),
            _NameField(
              key: const Key('name2'),
              controller: _name2,
              symbol: widget.symbols.$2,
              label: 'Nome do Jogador 2',
            ),
          ],
          if (solo && levels != null) ...[
            const SizedBox(height: 20),
            Text(
              'Nível',
              style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (var i = 0; i < levels.length; i++)
                  ButtonSegment(value: i, label: Text(levels[i])),
              ],
              selected: {_level},
              onSelectionChanged: (s) => setState(() => _level = s.first),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Jogar!',
                style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    super.key,
    required this.controller,
    required this.symbol,
    required this.label,
  });

  final TextEditingController controller;
  final String symbol;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: 12,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        prefixText: '$symbol  ',
        labelText: label,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
```

- [ ] **Step 4: Implementar `ScoreBoard`**

```dart
// lib/widgets/score_board.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Placar de dois jogadores com empates no centro.
class ScoreBoard extends StatelessWidget {
  const ScoreBoard({
    super.key,
    required this.name1,
    required this.name2,
    required this.symbol1,
    required this.symbol2,
    required this.score1,
    required this.score2,
    required this.draws,
    this.activePlayer,
    required this.accent,
  });

  final String name1;
  final String name2;
  final String symbol1;
  final String symbol2;
  final int score1;
  final int score2;
  final int draws;
  final int? activePlayer;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PlayerScore(
              name: name1,
              symbol: symbol1,
              score: score1,
              active: activePlayer == 1,
              accent: accent,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                const Text('🤝', style: TextStyle(fontSize: 18)),
                Text(
                  '$draws',
                  style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Empates',
                  style: GoogleFonts.fredoka(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          Expanded(
            child: _PlayerScore(
              name: name2,
              symbol: symbol2,
              score: score2,
              active: activePlayer == 2,
              accent: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerScore extends StatelessWidget {
  const _PlayerScore({
    required this.name,
    required this.symbol,
    required this.score,
    required this.active,
    required this.accent,
  });

  final String name;
  final String symbol;
  final int score;
  final bool active;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: active ? accent.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(symbol, style: const TextStyle(fontSize: 22)),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Text(
            '$score',
            style: GoogleFonts.fredoka(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Rodar e ver passar**

Run: `flutter test test/widgets && flutter analyze`
Esperado: PASS nos 8 testes e `No issues found!`.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/player_setup.dart lib/widgets/score_board.dart test/widgets
git commit -m "feat: add shared PlayerSetup and ScoreBoard widgets" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt"
```

---

### Task 2: Memória, modelos, níveis e provider

**Files:**
- Create: `lib/games/memoria/models/game_state.dart`
- Create: `lib/games/memoria/data/emojis.dart`
- Create: `lib/games/memoria/data/levels.dart`
- Create: `lib/games/memoria/providers/game_provider.dart`
- Test: `test/games/memoria/game_provider_test.dart`

**Interfaces:**
- Consumes (Task 1): `PlayMode`, `PlayerSetupResult`.
- Produces:
  - `enum MemoryPhase { setup, playing, finished }`
  - `class MemoryCard { final int id; final String emoji; final bool faceUp; final bool matched; MemoryCard copyWith({bool? faceUp, bool? matched}); }`
  - `class MemoryGrid { final int rows; final int cols; int get pairs; }`, com `kSoloLevels` (5 itens) e `kDuoSizes` (`Map<String, MemoryGrid>` com 'Pequena', 'Média' e 'Grande')
  - `const List<String> kMemoryEmojis` (24 emojis distintos)
  - `class MemoryProvider extends ChangeNotifier`:
    - construtor `MemoryProvider({Random? random})`;
    - getters `phase`, `mode`, `name1`, `name2`, `level`, `duoSize`, `grid`, `isLastLevel`, `cards`, `currentPlayer`, `pairs1`, `pairs2`, `moves`, `wins1`, `wins2`, `draws`, `waitingToHide`, `winner` (`int?`);
    - métodos `start(PlayerSetupResult)`, `setDuoSize(String)`, `flip(int id)`, `hideMismatched()`, `nextLevel()`, `playAgain()`, `exitToSetup()`.

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/games/memoria/game_provider_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/memoria/data/levels.dart';
import 'package:brincaki/games/memoria/models/game_state.dart';
import 'package:brincaki/games/memoria/providers/game_provider.dart';
import 'package:brincaki/widgets/player_setup.dart';

const _solo = PlayerSetupResult(mode: PlayMode.solo, player1: 'Ana', player2: '');
const _duo =
    PlayerSetupResult(mode: PlayMode.twoPlayers, player1: 'Ana', player2: 'Beto');

/// Ids das duas cartas de cada emoji ainda não encontrado.
List<(int, int)> pairsOf(MemoryProvider p) {
  final byEmoji = <String, List<int>>{};
  for (final c in p.cards) {
    if (!c.matched) byEmoji.putIfAbsent(c.emoji, () => []).add(c.id);
  }
  return [for (final ids in byEmoji.values) (ids[0], ids[1])];
}

/// Duas cartas de emojis diferentes, ainda não encontradas.
(int, int) mismatch(MemoryProvider p) {
  final pairs = pairsOf(p);
  return (pairs[0].$1, pairs[1].$1);
}

void findAll(MemoryProvider p) {
  for (final (a, b) in pairsOf(p)) {
    p.flip(a);
    p.flip(b);
  }
}

void main() {
  late MemoryProvider p;

  setUp(() => p = MemoryProvider(random: Random(5)));

  test('começa na configuração', () {
    expect(p.phase, MemoryPhase.setup);
    expect(p.cards, isEmpty);
  });

  test('cada nível solo tem rows×cols cartas com cada emoji 2 vezes', () {
    p.start(_solo);
    for (var level = 1; level <= kSoloLevels.length; level++) {
      final grid = kSoloLevels[level - 1];
      expect(p.level, level);
      expect(p.cards.length, grid.rows * grid.cols);
      final counts = <String, int>{};
      for (final c in p.cards) {
        counts[c.emoji] = (counts[c.emoji] ?? 0) + 1;
      }
      expect(counts.length, grid.pairs);
      expect(counts.values.every((n) => n == 2), isTrue);
      expect([for (var i = 0; i < p.cards.length; i++) p.cards[i].id],
          List.generate(p.cards.length, (i) => i));
      findAll(p);
      p.nextLevel();
    }
    expect(p.level, 1); // depois do nível 5 volta ao 1
  });

  test('par encontrado fica virado e conta para o jogador da vez', () {
    p.start(_duo);
    final (a, b) = pairsOf(p).first;
    p.flip(a);
    p.flip(b);
    expect(p.cards[a].matched && p.cards[b].matched, isTrue);
    expect(p.pairs1, 1);
    expect(p.currentPlayer, 1); // acertou, joga de novo
    expect(p.moves, 1);
  });

  test('erro deixa as cartas à mostra, bloqueia toques e passa a vez', () {
    p.start(_duo);
    final (a, b) = mismatch(p);
    p.flip(a);
    p.flip(b);
    expect(p.waitingToHide, isTrue);

    final other = p.cards.firstWhere((c) => !c.faceUp).id;
    p.flip(other); // ignorado enquanto as erradas estão à mostra
    expect(p.cards[other].faceUp, isFalse);

    p.hideMismatched();
    expect(p.waitingToHide, isFalse);
    expect(p.cards[a].faceUp || p.cards[b].faceUp, isFalse);
    expect(p.currentPlayer, 2);
  });

  test('no solo, errar não troca de jogador', () {
    p.start(_solo);
    final (a, b) = mismatch(p);
    p.flip(a);
    p.flip(b);
    p.hideMismatched();
    expect(p.currentPlayer, 1);
    expect(p.moves, 1);
  });

  test('virar carta já virada ou encontrada não faz nada', () {
    p.start(_solo);
    final (a, b) = pairsOf(p).first;
    p.flip(a);
    p.flip(a);
    expect(p.moves, 0);
    p.flip(b);
    p.flip(a);
    expect(p.moves, 1);
    expect(p.waitingToHide, isFalse);
  });

  test('terminar em dois jogadores atualiza vitórias e empates', () {
    p.start(_duo);
    findAll(p); // o jogador 1 acha todos os pares
    expect(p.phase, MemoryPhase.finished);
    expect(p.winner, 1);
    expect(p.wins1, 1);

    p.playAgain();
    expect(p.phase, MemoryPhase.playing);
    expect(p.currentPlayer, 2); // quem começa alterna
    // Empate: cada um acha metade dos pares (o tamanho Médio tem 10).
    final pairs = pairsOf(p);
    for (var i = 0; i < pairs.length; i++) {
      if (i == pairs.length ~/ 2) {
        final (x, y) = mismatch(p);
        p.flip(x);
        p.flip(y);
        p.hideMismatched(); // passa a vez para o jogador 1
      }
      final (a, b) = pairs[i];
      p.flip(a);
      p.flip(b);
    }
    expect(p.pairs1, p.pairs2);
    expect(p.winner, isNull);
    expect(p.draws, 1);
    expect(p.wins1, 1);
  });

  test('setDuoSize troca a grade só antes da primeira jogada', () {
    p.start(_duo);
    expect(p.duoSize, 'Média');
    p.setDuoSize('Grande');
    expect(p.cards.length, kDuoSizes['Grande']!.rows * kDuoSizes['Grande']!.cols);
    final (a, b) = mismatch(p);
    p.flip(a);
    p.flip(b);
    p.hideMismatched();
    p.setDuoSize('Pequena');
    expect(p.duoSize, 'Grande');
  });

  test('exitToSetup zera o placar', () {
    p.start(_duo);
    findAll(p);
    p.exitToSetup();
    expect(p.phase, MemoryPhase.setup);
    expect(p.wins1 + p.wins2 + p.draws, 0);
  });

  test('nextLevel e playAgain só funcionam no modo e na fase certos', () {
    p.start(_solo);
    p.nextLevel();
    expect(p.level, 1);
    findAll(p);
    p.playAgain();
    expect(p.phase, MemoryPhase.finished);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/games/memoria/game_provider_test.dart`
Esperado: FAIL na compilação, porque `lib/games/memoria/...` não existe.

- [ ] **Step 3: Implementar modelos e dados**

```dart
// lib/games/memoria/models/game_state.dart

enum MemoryPhase { setup, playing, finished }

class MemoryCard {
  const MemoryCard({
    required this.id,
    required this.emoji,
    this.faceUp = false,
    this.matched = false,
  });

  /// Posição na grade.
  final int id;
  final String emoji;
  final bool faceUp;
  final bool matched;

  MemoryCard copyWith({bool? faceUp, bool? matched}) => MemoryCard(
        id: id,
        emoji: emoji,
        faceUp: faceUp ?? this.faceUp,
        matched: matched ?? this.matched,
      );
}
```

```dart
// lib/games/memoria/data/emojis.dart

/// Figuras das cartas: fáceis de reconhecer e bem diferentes entre si.
const List<String> kMemoryEmojis = [
  '🐶', '🐱', '🐭', '🐰', '🦊', '🐻', '🐼', '🐨',
  '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🐔', '🐧',
  '🐢', '🐙', '🍎', '🍌', '🍇', '🍓', '⚽', '🚗',
];
```

```dart
// lib/games/memoria/data/levels.dart

class MemoryGrid {
  const MemoryGrid(this.rows, this.cols);

  final int rows;
  final int cols;

  int get pairs => rows * cols ~/ 2;
}

/// Níveis do modo solo, em pé (o app só roda na vertical).
const List<MemoryGrid> kSoloLevels = [
  MemoryGrid(4, 3),
  MemoryGrid(4, 4),
  MemoryGrid(5, 4),
  MemoryGrid(6, 5),
  MemoryGrid(6, 6),
];

const Map<String, MemoryGrid> kDuoSizes = {
  'Pequena': MemoryGrid(4, 3),
  'Média': MemoryGrid(5, 4),
  'Grande': MemoryGrid(6, 6),
};
```

- [ ] **Step 4: Implementar o provider**

```dart
// lib/games/memoria/providers/game_provider.dart

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../widgets/player_setup.dart';
import '../data/emojis.dart';
import '../data/levels.dart';
import '../models/game_state.dart';

class MemoryProvider extends ChangeNotifier {
  MemoryProvider({Random? random}) : _random = random ?? Random();

  final Random _random;

  MemoryPhase _phase = MemoryPhase.setup;
  PlayMode _mode = PlayMode.solo;
  String _name1 = '';
  String _name2 = '';
  int _level = 1;
  String _duoSize = 'Média';
  List<MemoryCard> _cards = const [];
  int _currentPlayer = 1;
  int _startingPlayer = 1;
  int _pairs1 = 0;
  int _pairs2 = 0;
  int _moves = 0;
  int _wins1 = 0;
  int _wins2 = 0;
  int _draws = 0;
  bool _waitingToHide = false;

  /// Cartas viradas na jogada atual que ainda não formaram par.
  final List<int> _open = [];

  MemoryPhase get phase => _phase;
  PlayMode get mode => _mode;
  String get name1 => _name1;
  String get name2 => _name2;
  int get level => _level;
  String get duoSize => _duoSize;
  MemoryGrid get grid =>
      _mode == PlayMode.solo ? kSoloLevels[_level - 1] : kDuoSizes[_duoSize]!;
  bool get isLastLevel => _level == kSoloLevels.length;
  List<MemoryCard> get cards => List.unmodifiable(_cards);
  int get currentPlayer => _currentPlayer;
  int get pairs1 => _pairs1;
  int get pairs2 => _pairs2;
  int get moves => _moves;
  int get wins1 => _wins1;
  int get wins2 => _wins2;
  int get draws => _draws;
  bool get waitingToHide => _waitingToHide;

  /// Vencedor da partida em dois jogadores (null = empate ou ainda jogando).
  int? get winner {
    if (_phase != MemoryPhase.finished || _mode != PlayMode.twoPlayers) return null;
    if (_pairs1 == _pairs2) return null;
    return _pairs1 > _pairs2 ? 1 : 2;
  }

  void start(PlayerSetupResult setup) {
    _mode = setup.mode;
    _name1 = setup.player1;
    _name2 = setup.player2;
    _level = 1;
    _duoSize = 'Média';
    _wins1 = 0;
    _wins2 = 0;
    _draws = 0;
    _startingPlayer = 1;
    _deal();
    notifyListeners();
  }

  /// Troca o tamanho da grade em dois jogadores, antes da primeira jogada.
  void setDuoSize(String size) {
    if (_mode != PlayMode.twoPlayers ||
        _phase != MemoryPhase.playing ||
        _moves > 0 ||
        !kDuoSizes.containsKey(size)) {
      return;
    }
    _duoSize = size;
    _deal();
    notifyListeners();
  }

  void flip(int id) {
    if (_phase != MemoryPhase.playing || _waitingToHide) return;
    if (id < 0 || id >= _cards.length) return;
    final card = _cards[id];
    if (card.faceUp || card.matched) return;

    _cards = [..._cards];
    _cards[id] = card.copyWith(faceUp: true);
    _open.add(id);

    if (_open.length == 2) {
      _moves++;
      final a = _cards[_open[0]];
      final b = _cards[_open[1]];
      if (a.emoji == b.emoji) {
        _cards[a.id] = a.copyWith(matched: true);
        _cards[b.id] = b.copyWith(matched: true);
        _open.clear();
        if (_currentPlayer == 1) {
          _pairs1++;
        } else {
          _pairs2++;
        }
        if (_cards.every((c) => c.matched)) _finish();
      } else {
        _waitingToHide = true;
      }
    }
    notifyListeners();
  }

  /// Desvira as duas cartas erradas; em dois jogadores, passa a vez.
  void hideMismatched() {
    if (!_waitingToHide) return;
    _cards = [..._cards];
    for (final id in _open) {
      _cards[id] = _cards[id].copyWith(faceUp: false);
    }
    _open.clear();
    _waitingToHide = false;
    if (_mode == PlayMode.twoPlayers) _currentPlayer = 3 - _currentPlayer;
    notifyListeners();
  }

  void nextLevel() {
    if (_mode != PlayMode.solo || _phase != MemoryPhase.finished) return;
    _level = isLastLevel ? 1 : _level + 1;
    _deal();
    notifyListeners();
  }

  void playAgain() {
    if (_mode != PlayMode.twoPlayers || _phase != MemoryPhase.finished) return;
    _startingPlayer = 3 - _startingPlayer;
    _deal();
    notifyListeners();
  }

  void exitToSetup() {
    _phase = MemoryPhase.setup;
    _cards = const [];
    _open.clear();
    _waitingToHide = false;
    _wins1 = 0;
    _wins2 = 0;
    _draws = 0;
    notifyListeners();
  }

  void _finish() {
    _phase = MemoryPhase.finished;
    if (_mode != PlayMode.twoPlayers) return;
    if (_pairs1 > _pairs2) {
      _wins1++;
    } else if (_pairs2 > _pairs1) {
      _wins2++;
    } else {
      _draws++;
    }
  }

  void _deal() {
    final pairs = grid.pairs;
    final emojis = ([...kMemoryEmojis]..shuffle(_random)).take(pairs).toList();
    final faces = [...emojis, ...emojis]..shuffle(_random);
    _cards = [
      for (var i = 0; i < faces.length; i++) MemoryCard(id: i, emoji: faces[i]),
    ];
    _open.clear();
    _waitingToHide = false;
    _pairs1 = 0;
    _pairs2 = 0;
    _moves = 0;
    _currentPlayer = _startingPlayer;
    _phase = MemoryPhase.playing;
  }
}
```

- [ ] **Step 5: Rodar e ver passar**

Run: `flutter test test/games/memoria/game_provider_test.dart && flutter analyze lib/games/memoria test/games/memoria`
Esperado: PASS e `No issues found!`.

Se o teste de empate falhar porque a quantidade de pares da grade "Média" é ímpar, isso é um problema nos dados: a grade Média de 5×4 tem 10 pares, que é par.

- [ ] **Step 6: Commit**

```bash
git add lib/games/memoria test/games/memoria
git commit -m "feat(memoria): add memory game models, levels and provider" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt"
```

---

### Task 3: Memória, tela

**Files:**
- Create: `lib/games/memoria/widgets/memory_card_tile.dart`
- Create: `lib/games/memoria/screens/game_screen.dart`
- Test: `test/games/memoria/game_screen_test.dart`

**Interfaces:**
- Consumes:
  - da Task 2: `MemoryProvider` e todos os seus getters e métodos, mais `MemoryPhase` e `kDuoSizes`;
  - da Task 1: `PlayerSetup` e `ScoreBoard`.
- Produces:
  - `class MemoryScreen extends StatelessWidget` (`const MemoryScreen({super.key})`), que lê o `MemoryProvider` de cima da árvore;
  - `Key('card-$id')` em cada carta, usada nos testes.

- [ ] **Step 1: Escrever o teste de widget que falha**

```dart
// test/games/memoria/game_screen_test.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/memoria/models/game_state.dart';
import 'package:brincaki/games/memoria/providers/game_provider.dart';
import 'package:brincaki/games/memoria/screens/game_screen.dart';

Future<MemoryProvider> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = MemoryProvider(random: Random(2));
  await tester.pumpWidget(ChangeNotifierProvider.value(
    value: provider,
    child: const MaterialApp(home: MemoryScreen()),
  ));
  return provider;
}

Map<String, List<int>> byEmoji(MemoryProvider p) {
  final map = <String, List<int>>{};
  for (final c in p.cards) {
    if (!c.matched) map.putIfAbsent(c.emoji, () => []).add(c.id);
  }
  return map;
}

void main() {
  testWidgets('solo: acha todos os pares e vê o nível completo', (tester) async {
    final p = await pumpScreen(tester);
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    expect(find.text('Memória • Nível 1'), findsOneWidget);
    expect(find.byKey(const Key('card-0')), findsOneWidget);

    for (final ids in byEmoji(p).values) {
      await tester.tap(find.byKey(Key('card-${ids[0]}')));
      await tester.tap(find.byKey(Key('card-${ids[1]}')));
      await tester.pumpAndSettle();
    }
    expect(p.phase, MemoryPhase.finished);
    expect(find.text('Nível 1 completo em 6 jogadas!'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Próximo nível'));
    await tester.pumpAndSettle();
    expect(find.text('Memória • Nível 2'), findsOneWidget);
  });

  testWidgets('erro: cartas desviram sozinhas depois de um instante',
      (tester) async {
    final p = await pumpScreen(tester);
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();

    final groups = byEmoji(p).values.toList();
    await tester.tap(find.byKey(Key('card-${groups[0][0]}')));
    await tester.tap(find.byKey(Key('card-${groups[1][0]}')));
    await tester.pump();
    expect(p.waitingToHide, isTrue);

    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();
    expect(p.waitingToHide, isFalse);
    expect(p.cards.where((c) => c.faceUp), isEmpty);
  });

  testWidgets('sair com cartas erradas à mostra não deixa timer pendente',
      (tester) async {
    final p = await pumpScreen(tester);
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    final groups = byEmoji(p).values.toList();
    await tester.tap(find.byKey(Key('card-${groups[0][0]}')));
    await tester.tap(find.byKey(Key('card-${groups[1][0]}')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox()); // a tela sai da árvore
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dois jogadores: placar e fim de partida', (tester) async {
    final p = await pumpScreen(tester);
    await tester.tap(find.text('Dois jogadores'));
    await tester.pump();
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    expect(find.text('Empates'), findsOneWidget);
    expect(find.text('Grande'), findsOneWidget); // tamanho antes da 1ª jogada

    for (final ids in byEmoji(p).values) {
      await tester.tap(find.byKey(Key('card-${ids[0]}')));
      await tester.tap(find.byKey(Key('card-${ids[1]}')));
      await tester.pumpAndSettle();
    }
    expect(find.text('🏆 Jogador 1 venceu!'), findsOneWidget);
    await tester.tap(find.text('Trocar jogadores'));
    await tester.pumpAndSettle();
    expect(find.text('Jogar!'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/games/memoria/game_screen_test.dart`
Esperado: FAIL na compilação, porque `game_screen.dart` não existe.

- [ ] **Step 3: Implementar a carta**

```dart
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
```

- [ ] **Step 4: Implementar a tela**

```dart
// lib/games/memoria/screens/game_screen.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../widgets/player_setup.dart';
import '../../../widgets/score_board.dart';
import '../data/levels.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/memory_card_tile.dart';

const _background = Color(0xFFF5F3FF);
const _dark = Color(0xFF5B21B6);

class MemoryScreen extends StatelessWidget {
  const MemoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MemoryProvider>();
    final title = switch (p.phase) {
      MemoryPhase.setup => 'Jogo da Memória',
      _ when p.mode == PlayMode.solo => 'Memória • Nível ${p.level}',
      _ => 'Memória',
    };

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _dark),
          tooltip: 'Voltar ao menu',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        title: Text(
          title,
          style: GoogleFonts.fredoka(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _dark,
          ),
        ),
      ),
      body: SafeArea(
        child: p.phase == MemoryPhase.setup
            ? PlayerSetup(
                title: 'Jogo da Memória',
                emoji: '🧠',
                accent: kMemoryPurple,
                soloLabel: 'Sozinho',
                symbols: ('🐶', '🐱'),
                onStart: p.start,
              )
            : const _GameView(),
      ),
    );
  }
}

class _GameView extends StatefulWidget {
  const _GameView();

  @override
  State<_GameView> createState() => _GameViewState();
}

class _GameViewState extends State<_GameView> {
  late final MemoryProvider _provider;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _provider = context.read<MemoryProvider>();
    _provider.addListener(_onChange);
  }

  /// Duas cartas erradas à mostra: desvira depois de um instante.
  void _onChange() {
    if (_provider.waitingToHide && _hideTimer == null) {
      _hideTimer = Timer(const Duration(milliseconds: 900), () {
        _hideTimer = null;
        _provider.hideMismatched();
      });
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onChange);
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MemoryProvider>();
    final duo = p.mode == PlayMode.twoPlayers;

    return Stack(
      children: [
        Column(
          children: [
            if (duo) ...[
              ScoreBoard(
                name1: p.name1,
                name2: p.name2,
                symbol1: '🐶',
                symbol2: '🐱',
                score1: p.pairs1,
                score2: p.pairs2,
                draws: p.draws,
                activePlayer: p.phase == MemoryPhase.playing ? p.currentPlayer : null,
                accent: kMemoryPurple,
              ),
              Text(
                'Vitórias: ${p.wins1} × ${p.wins2}',
                style: GoogleFonts.fredoka(fontSize: 14, color: _dark),
              ),
              if (p.phase == MemoryPhase.playing && p.moves == 0)
                Wrap(
                  spacing: 8,
                  children: [
                    for (final size in kDuoSizes.keys)
                      ChoiceChip(
                        label: Text(size),
                        selected: p.duoSize == size,
                        onSelected: (_) => p.setDuoSize(size),
                      ),
                  ],
                ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Jogadas: ${p.moves}',
                  style: GoogleFonts.fredoka(fontSize: 18, color: _dark),
                ),
              ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: _CardGrid(),
              ),
            ),
          ],
        ),
        if (p.phase == MemoryPhase.finished) const _ResultOverlay(),
      ],
    );
  }
}

class _CardGrid extends StatelessWidget {
  const _CardGrid();

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MemoryProvider>();
    final grid = p.grid;
    final cards = p.cards;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(
          (constraints.maxWidth - _gap * (grid.cols - 1)) / grid.cols,
          (constraints.maxHeight - _gap * (grid.rows - 1)) / grid.rows,
        );
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var r = 0; r < grid.rows; r++)
                Padding(
                  padding: EdgeInsets.only(top: r == 0 ? 0 : _gap),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var c = 0; c < grid.cols; c++)
                        Padding(
                          padding: EdgeInsets.only(left: c == 0 ? 0 : _gap),
                          child: SizedBox.square(
                            dimension: side,
                            child: MemoryCardTile(
                              key: Key('card-${r * grid.cols + c}'),
                              card: cards[r * grid.cols + c],
                              onTap: () => p.flip(r * grid.cols + c),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MemoryProvider>();
    final solo = p.mode == PlayMode.solo;
    final winner = p.winner;
    final emoji = solo ? '🎉' : (winner == null ? '🤝' : '🏆');
    final title = solo
        ? 'Nível ${p.level} completo em ${p.moves} jogadas!'
        : (winner == null
            ? '🤝 Empate!'
            : '🏆 ${winner == 1 ? p.name1 : p.name2} venceu!');

    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (solo) Text(emoji, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _dark,
                  ),
                ),
                if (!solo)
                  Text(
                    '${p.pairs1} × ${p.pairs2} pares',
                    style: GoogleFonts.fredoka(fontSize: 16, color: Colors.black54),
                  ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: solo ? p.nextLevel : p.playAgain,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMemoryPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        solo
                            ? (p.isLastLevel ? 'Jogar de novo' : 'Próximo nível')
                            : 'Jogar de novo',
                        style: GoogleFonts.fredoka(fontSize: 16),
                      ),
                    ),
                    if (!solo)
                      OutlinedButton(
                        onPressed: p.exitToSetup,
                        child: Text(
                          'Trocar jogadores',
                          style: GoogleFonts.fredoka(fontSize: 16),
                        ),
                      ),
                  ],
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

- [ ] **Step 5: Rodar e ver passar**

Run: `flutter test test/games/memoria && flutter analyze lib/games/memoria test/games/memoria`
Esperado: PASS e `No issues found!`.

- [ ] **Step 6: Commit**

```bash
git add lib/games/memoria test/games/memoria
git commit -m "feat(memoria): add memory game screen with flip animation and overlays" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt"
```

---

### Task 4: Termo, listas de palavras e `WordBank`

**Files:**
- Create: `tool/build_termo_words.py`
- Create (gerado pelo script): `assets/termo/validas.txt`, `assets/termo/respostas.txt`, `assets/termo/LICENSE-fserb-pt-br.txt`
- Create: `lib/games/termo/logic/normalize.dart`
- Create: `lib/games/termo/data/word_bank.dart`
- Modify: `pubspec.yaml`, para adicionar `- assets/termo/` em `flutter.assets`
- Modify: `lib/main.dart`, para registrar a licença do fserb em `configureApp`
- Test: `test/games/termo/word_data_test.dart`
- Modify (teste): `test/app_setup_test.dart`

**Interfaces:**
- Produces:
  - `String normalizeWord(String word)`: maiúsculas, sem acento (`'avião'` vira `'AVIAO'`)
  - `class WordBank`:
    - construtor `WordBank({required Map<String, String> valid, required List<String> answers})`;
    - `List<String> answers`, `bool isValid(String normal)`, `String display(String normal)`, `int get validCount`;
    - `static Future<WordBank> load(AssetBundle bundle)`.
  - Formato dos assets: `validas.txt` com uma linha `NORMAL;EXIBIÇÃO` por palavra (por exemplo `AVIAO;AVIÃO`), e `respostas.txt` com uma linha `NORMAL` por palavra.

- [ ] **Step 1: Escrever os testes que falham**

```dart
// test/games/termo/word_data_test.dart

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/termo/data/word_bank.dart';
import 'package:brincaki/games/termo/logic/normalize.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('normalizeWord tira acentos e põe em maiúsculas', () {
    expect(normalizeWord('avião'), 'AVIAO');
    expect(normalizeWord('Açúcar'), 'ACUCAR');
    expect(normalizeWord('ÔNIBUS'), 'ONIBUS');
  });

  test('WordBank em memória', () {
    final bank = WordBank(
      valid: {'AVIAO': 'AVIÃO', 'CARRO': 'CARRO'},
      answers: ['CARRO'],
    );
    expect(bank.isValid('AVIAO'), isTrue);
    expect(bank.isValid('ZZZZZ'), isFalse);
    expect(bank.display('AVIAO'), 'AVIÃO');
    expect(bank.display('ZZZZZ'), 'ZZZZZ');
    expect(bank.answers, ['CARRO']);
  });

  test('listas reais do app são válidas', () async {
    final bank = await WordBank.load(rootBundle);
    final five = RegExp(r'^[A-Z]{5}$');

    expect(bank.answers.length, greaterThanOrEqualTo(500));
    expect(bank.validCount, greaterThanOrEqualTo(3000));
    expect(bank.answers.toSet().length, bank.answers.length,
        reason: 'resposta repetida');
    for (final answer in bank.answers) {
      expect(answer, matches(five));
      expect(bank.isValid(answer), isTrue, reason: answer);
      final shown = bank.display(answer);
      expect(shown.length, 5, reason: shown);
      expect(normalizeWord(shown), answer, reason: shown);
    }
  });
}
```

Em `test/app_setup_test.dart`, acrescentar ao final de `main()`:

```dart
  test('a licença das palavras do Termo aparece na tela de licenças',
      () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await configureApp();
    final licenses = await LicenseRegistry.licenses.toList();
    expect(
      licenses.any((l) => l.packages.contains('fserb/pt-br')),
      isTrue,
    );
  });
```

Adicione `import 'package:flutter/foundation.dart';` em `test/app_setup_test.dart`, se o analyzer pedir, por causa do `LicenseRegistry`.

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/games/termo/word_data_test.dart test/app_setup_test.dart`
Esperado: FAIL na compilação (`word_bank.dart` e `normalize.dart` não existem).

- [ ] **Step 3: Implementar `normalize.dart` e `word_bank.dart`**

```dart
// lib/games/termo/logic/normalize.dart

const _accents = {
  'Á': 'A', 'À': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A',
  'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
  'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I',
  'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
  'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U',
  'Ç': 'C', 'Ñ': 'N',
};

/// Maiúsculas e sem acento: 'avião' → 'AVIAO'.
String normalizeWord(String word) =>
    word.toUpperCase().split('').map((c) => _accents[c] ?? c).join();
```

```dart
// lib/games/termo/data/word_bank.dart

import 'dart:convert';

import 'package:flutter/services.dart';

/// Palavras aceitas (com a forma acentuada para mostrar) e respostas possíveis.
class WordBank {
  WordBank({required Map<String, String> valid, required List<String> answers})
      : _valid = valid,
        answers = List.unmodifiable(answers);

  final Map<String, String> _valid;
  final List<String> answers;

  int get validCount => _valid.length;

  bool isValid(String normal) => _valid.containsKey(normal);

  /// Forma com acento, por exemplo 'AVIAO' → 'AVIÃO'.
  String display(String normal) => _valid[normal] ?? normal;

  static Future<WordBank> load(AssetBundle bundle) async {
    // bundle.load + utf8 em vez de loadString: arquivos grandes iriam para
    // um isolate, o que trava em testes de widget.
    Future<List<String>> lines(String path) async {
      final data = await bundle.load(path);
      final text = utf8.decode(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      return const LineSplitter().convert(text).where((l) => l.isNotEmpty).toList();
    }

    final valid = <String, String>{};
    for (final line in await lines('assets/termo/validas.txt')) {
      final parts = line.split(';');
      if (parts.length == 2) valid[parts[0]] = parts[1];
    }
    return WordBank(valid: valid, answers: await lines('assets/termo/respostas.txt'));
  }
}
```

- [ ] **Step 4: Criar o script e gerar os assets**

Crie `tool/build_termo_words.py` exatamente com o conteúdo abaixo. A lista `EXCLUIR` vem da leitura das 1.300 candidatas mais frequentes.

```python
#!/usr/bin/env python3
"""Gera assets/termo/ a partir do fserb/pt-br (licença MIT).

Uso (só quando for preciso refazer as listas):
    python3 tool/build_termo_words.py

Baixa os arquivos do commit fixo abaixo e grava:
    assets/termo/validas.txt     NORMAL;EXIBIÇÃO, todas as tentativas aceitas
    assets/termo/respostas.txt   NORMAL, as palavras que podem ser sorteadas
    assets/termo/LICENSE-fserb-pt-br.txt

As respostas são as palavras de 5 letras mais frequentes (pontuação ICF) do
léxico, sem verbos flexionados, entre as REVISADAS primeiras, que foram lidas
uma a uma; o que não serve como resposta para a família está em EXCLUIR.
"""
import os
import re
import sys
import unicodedata
import urllib.parse
import urllib.request
from pathlib import Path

COMMIT = '93ba2a6f3b2f85262fba72df09d448c6bb2fa50a'
BASE = f'https://raw.githubusercontent.com/fserb/pt-br/{COMMIT}/'
OUT = Path(__file__).resolve().parent.parent / 'assets' / 'termo'
# Para testar sem rede: FSERB_DIR=/caminho/com/os/arquivos
LOCAL = os.environ.get('FSERB_DIR')
REVISADAS = 1300

# Nomes próprios, estrangeirismos, palavrões, contrações e palavras raras ou
# impróprias para crianças, entre as REVISADAS candidatas mais frequentes.
EXCLUIR = set('''
neste desta nesta disso jesus nesse maria dessa nessa delas china daqui light
bruno goiás facto nisso japão porno black login micro braga vasco invés recém
sousa chico flash merda aonde índia césar autos nunes jeans vosso moura mouse
piauí chile porra infra drive celso egito bunda laser ultra abreu suíça marte
júlio tesão marta seios diogo motel joana color laura mauro green multi penha
meter jóias síria queen caput corsa gozar skate fusca stand blues weber amaro
crack adobe angra malta henry diana milão major bauru roque judeu hélio modem
spray amapá guiné couto simão slide pênis short nobel nisto anais timão ibope
judas macau cache cover clean bacon staff lúcio siena break jeová corno lauro
combo sushi fezes trans donde macro blush bosta magno sedan foder madre nylon
grill veiga hobby rally front paper pixel close lobby remix dante romeu timor
duche round dunga swing tietê cotia souto blitz máfia elena crato vênus coach
xerox fraga ávila tarso rugby match diodo gávea capão sigma cairo toner congo
chica anglo hasta sugar mafra orgia reiki logos bangu nudez praxe aquém mercê
lobão sacra orixá aedes apolo oxalá seara viado karma tecto cozer vulgo drink
quota edema táxis baião liceu bessa apart strip túlio dogma cerne araxá caicó
betão lorde quiçá fetal hidro relax quina coque pampa casta still durão rouge
varão logar xeque cosmo alter mixer gibis bolão hacer focal horto látex áurea
babel bicha vilar romão guria timer derby lítio loiça tetra ferry dorso botox
ibero error áries tatuí buggy tróia coxim labor carte caída rolim gnome novel
tetas ítalo serva hiato antão cusco célio hindu laico limbo tesla recta cólon
nitro povão guará sêmen curry rente cabal abade guaçu rotor furor jumbo grado
train malte urano reich coifa trial xangô acolá pagão areal tarja beato corja
óscar átrio óvulo input babar rabão blast cisão modal devir modus senda ósseo
tenor âmago chope guião égide veado vanda marra bocal dotar gueto alana bamba
xisto penny retos papal mento rapel páreo islão logon rifle creta tanga twist
chili ethos maçom carma graal catch drops sheik lycra kraft avaré batel sunga
cariz sarro coupé basal rasto reger sacro ganga óbice leone aruba sarja mouro
cagar epóxi untar mango neuro cisto honor haras jango débil parma lomba canas
algoz ninfa blend suede crush goela curió corso jataí sachê axial ceres tirso
basco tutti ímpio tecno horda rebel copel édipo
'''.split())


def fetch(name):
    if LOCAL:
        return (Path(LOCAL) / name).read_text(encoding='utf-8')
    with urllib.request.urlopen(BASE + urllib.parse.quote(name)) as r:
        return r.read().decode('utf-8')


def norm(word):
    decomposed = unicodedata.normalize('NFD', word.upper())
    return ''.join(c for c in decomposed if unicodedata.category(c) != 'Mn')


def is_five(n):
    return re.fullmatch('[A-Z]{5}', n) is not None


def main():
    lexico = [w.strip() for w in fetch('lexico').splitlines() if w.strip()]
    conj = [w.strip() for w in fetch('conjugações').splitlines() if w.strip()]
    icf = {}
    for line in fetch('icf').splitlines():
        word, _, score = line.rpartition(',')
        try:
            icf[word] = float(score)
        except ValueError:
            pass

    # Léxico primeiro: a forma com acento dele vence a das conjugações.
    validas = {}
    for w in lexico + conj:
        n = norm(w)
        if is_five(n):
            validas.setdefault(n, unicodedata.normalize('NFC', w.upper()))

    flexionadas = {norm(w) for w in conj}
    excluir = {norm(w) for w in EXCLUIR}
    candidatas = []
    for w in lexico:
        n = norm(w)
        if not is_five(n) or w not in icf:
            continue
        # Verbo flexionado não vira resposta; infinitivo pode.
        if n in flexionadas and not re.search('(AR|ER|IR)$', n):
            continue
        candidatas.append((icf[w], n))
    candidatas.sort()

    vistas, respostas = set(), []
    for _, n in candidatas:
        if n in vistas:
            continue
        vistas.add(n)
        if len(vistas) > REVISADAS:
            break
        if n not in excluir:
            respostas.append(n)

    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'validas.txt').write_text(
        ''.join(f'{n};{validas[n]}\n' for n in sorted(validas)), encoding='utf-8')
    (OUT / 'respostas.txt').write_text(
        ''.join(f'{n}\n' for n in sorted(respostas)), encoding='utf-8')
    (OUT / 'LICENSE-fserb-pt-br.txt').write_text(fetch('LICENSE'), encoding='utf-8')
    print(f'válidas: {len(validas)}  respostas: {len(respostas)}', file=sys.stderr)


if __name__ == '__main__':
    main()
```

Run:
```bash
python3 tool/build_termo_words.py
```
Esperado:
- stderr: `válidas: 8628  respostas: 902`;
- três arquivos em `assets/termo/`;
- a primeira linha de `validas.txt` é `ABABA;ABABÁ`.

Se a rede falhar, baixe `lexico`, `conjugações`, `icf` e `LICENSE` do commit `93ba2a6f...` para uma pasta e rode com `FSERB_DIR=<pasta>`.

- [ ] **Step 5: Registrar os assets e a licença**

Em `pubspec.yaml`, logo abaixo de `- assets/google_fonts/`:
```yaml
    - assets/termo/
```

Em `lib/main.dart`, dentro de `configureApp()`, depois do `LicenseRegistry.addLicense` da Fredoka:
```dart
  LicenseRegistry.addLicense(() async* {
    final license =
        await rootBundle.loadString('assets/termo/LICENSE-fserb-pt-br.txt');
    yield LicenseEntryWithLineBreaks(['fserb/pt-br'], license);
  });
```

- [ ] **Step 6: Rodar e ver passar**

Run: `flutter test test/games/termo/word_data_test.dart test/app_setup_test.dart && flutter analyze`
Esperado: PASS e `No issues found!`.

Se `normalizeWord(shown)` falhar para alguma palavra, o caractere acentuado está faltando em `_accents`: acrescente-o ao mapa. Não mexa nos dados.

- [ ] **Step 7: Commit**

```bash
git add tool/build_termo_words.py assets/termo pubspec.yaml lib/main.dart lib/games/termo test/games/termo test/app_setup_test.dart
git commit -m "feat(termo): add Portuguese word lists from fserb/pt-br and WordBank" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt"
```

---

### Task 5: Termo, regras, palavra do dia e provider

**Files:**
- Create: `lib/games/termo/logic/evaluate.dart`
- Create: `lib/games/termo/logic/daily.dart`
- Create: `lib/games/termo/data/daily_store.dart`
- Create: `lib/games/termo/models/game_state.dart`
- Create: `lib/games/termo/providers/game_provider.dart`
- Test: `test/games/termo/evaluate_test.dart`
- Test: `test/games/termo/game_provider_test.dart`

**Interfaces:**
- Consumes (Task 4): `WordBank`, `normalizeWord`.
- Produces:
  - `enum LetterResult { correct, present, absent }` e `List<LetterResult> evaluateGuess(String guess, String answer)`
  - `String dailyAnswer(WordBank bank, DateTime today)` e `String dateKey(DateTime d)` (`yyyy-MM-dd`)
  - `class DailyState { final String date; final List<String> guesses; }`, mais `abstract class DailyStore { Future<DailyState?> load(); Future<void> save(DailyState state); }` e `class SharedPrefsDailyStore implements DailyStore`
  - `enum TermoMode { daily, unlimited }` e `enum TermoPhase { playing, won, lost }`
  - `class TermoProvider extends ChangeNotifier`:
    - construtor `TermoProvider({Future<WordBank>? bank, DailyStore? store, DateTime Function()? now, Random? random})`;
    - constantes `wordLength = 5` e `maxGuesses = 6`;
    - getters `loading`, `mode`, `answer`, `answerDisplay`, `guesses`, `current`, `phase`, `lastError`, `shakeCount`, `keyboard` (`Map<String, LetterResult>`);
    - métodos `display(String)`, `resultsFor(String guess)`, `type(String letter)`, `backspace()`, `submit()`, `setMode(TermoMode)`, `newUnlimited()`.

- [ ] **Step 1: Escrever os testes que falham**

```dart
// test/games/termo/evaluate_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/termo/data/word_bank.dart';
import 'package:brincaki/games/termo/logic/daily.dart';
import 'package:brincaki/games/termo/logic/evaluate.dart';

const c = LetterResult.correct;
const p = LetterResult.present;
const a = LetterResult.absent;

void main() {
  group('evaluateGuess', () {
    test('todas certas', () {
      expect(evaluateGuess('CARRO', 'CARRO'), [c, c, c, c, c]);
    });

    test('nenhuma letra na palavra', () {
      expect(evaluateGuess('TUMBI', 'CARRO'), [a, a, a, a, a]);
    });

    test('letras no lugar errado', () {
      expect(evaluateGuess('ROCAR', 'CARRO'), [p, p, p, p, p]);
    });

    test('repetidas: só colore quantas a resposta tem (ARARA × CARRO)', () {
      expect(evaluateGuess('ARARA', 'CARRO'), [p, p, a, c, a]);
    });

    test('repetidas: verdes contam primeiro (SALAS × ASSAR)', () {
      expect(evaluateGuess('SALAS', 'ASSAR'), [p, p, a, c, p]);
    });
  });

  group('dailyAnswer', () {
    final bank = WordBank(
      valid: {for (final w in ['CARRO', 'PEDRA', 'AVIAO', 'TERMO']) w: w},
      answers: ['CARRO', 'PEDRA', 'AVIAO', 'TERMO'],
    );

    test('mesma data, mesma palavra (ignora a hora)', () {
      expect(dailyAnswer(bank, DateTime(2026, 10, 4, 8)),
          dailyAnswer(bank, DateTime(2026, 10, 4, 23, 59)));
    });

    test('dias seguidos têm palavras diferentes', () {
      for (var d = 0; d < 30; d++) {
        final day = DateTime(2026, 3, 1).add(Duration(days: d));
        expect(dailyAnswer(bank, day),
            isNot(dailyAnswer(bank, day.add(const Duration(days: 1)))));
      }
    });

    test('dateKey', () {
      expect(dateKey(DateTime(2026, 1, 5, 13)), '2026-01-05');
    });
  });
}
```

Observação: "dias seguidos diferentes" vale enquanto `index % length` não cair no mesmo índice; com uma permutação de 4 elementos e passo de 1 dia, dias consecutivos sempre caem em posições diferentes.

```dart
// test/games/termo/game_provider_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/termo/data/daily_store.dart';
import 'package:brincaki/games/termo/data/word_bank.dart';
import 'package:brincaki/games/termo/logic/daily.dart';
import 'package:brincaki/games/termo/logic/evaluate.dart';
import 'package:brincaki/games/termo/models/game_state.dart';
import 'package:brincaki/games/termo/providers/game_provider.dart';

class MemoryDailyStore implements DailyStore {
  MemoryDailyStore([this.state]);
  DailyState? state;
  int saves = 0;

  @override
  Future<DailyState?> load() async => state;

  @override
  Future<void> save(DailyState s) async {
    state = s;
    saves++;
  }
}

final bank = WordBank(
  valid: {
    'CARRO': 'CARRO', 'PEDRA': 'PEDRA', 'AVIAO': 'AVIÃO', 'TERMO': 'TERMO',
    'ARARA': 'ARARA', 'PORTA': 'PORTA', 'MESAS': 'MESAS', 'ROCAR': 'ROÇAR',
  },
  answers: ['CARRO', 'PEDRA', 'AVIAO', 'TERMO'],
);

final day1 = DateTime(2026, 10, 4, 10);
final day2 = DateTime(2026, 10, 5, 9);

Future<TermoProvider> ready({
  MemoryDailyStore? store,
  DateTime? now,
  Random? random,
}) async {
  final provider = TermoProvider(
    bank: Future.value(bank),
    store: store ?? MemoryDailyStore(),
    now: () => now ?? day1,
    random: random ?? Random(1),
  );
  while (provider.loading) {
    await Future<void>.delayed(Duration.zero);
  }
  return provider;
}

void typeWord(TermoProvider p, String word) {
  for (final letter in word.split('')) {
    p.type(letter);
  }
}

/// Uma palavra válida que não é a resposta.
String wrongWord(TermoProvider p) =>
    ['PORTA', 'MESAS', 'ARARA'].firstWhere((w) => w != p.answer);

void main() {
  test('começa na palavra do dia', () async {
    final p = await ready();
    expect(p.mode, TermoMode.daily);
    expect(p.answer, dailyAnswer(bank, day1));
    expect(p.phase, TermoPhase.playing);
  });

  test('menos de 5 letras e palavra inválida dão erro e tremor', () async {
    final p = await ready();
    typeWord(p, 'CAR');
    p.submit();
    expect(p.lastError, 'Só palavras com 5 letras');
    expect(p.shakeCount, 1);
    typeWord(p, 'XY');
    p.submit();
    expect(p.lastError, 'Palavra inválida');
    expect(p.shakeCount, 2);
    expect(p.guesses, isEmpty);
  });

  test('digitar: no máximo 5 letras, aceita acento, backspace apaga', () async {
    final p = await ready();
    typeWord(p, 'avião');
    p.type('X');
    expect(p.current, 'AVIAO');
    p.backspace();
    expect(p.current, 'AVIA');
    p.type('1');
    expect(p.current, 'AVIA');
  });

  test('acertar vence e salva o dia', () async {
    final store = MemoryDailyStore();
    final p = await ready(store: store);
    typeWord(p, p.answer);
    p.submit();
    expect(p.phase, TermoPhase.won);
    expect(store.state!.date, '2026-10-04');
    expect(store.state!.guesses, [p.answer]);
    p.type('A'); // fim de jogo: nada mais entra
    expect(p.current, '');
  });

  test('6 erros perdem', () async {
    final p = await ready();
    for (var i = 0; i < TermoProvider.maxGuesses; i++) {
      typeWord(p, wrongWord(p));
      p.submit();
    }
    expect(p.phase, TermoPhase.lost);
    expect(p.answerDisplay, bank.display(p.answer));
  });

  test('teclado guarda o melhor resultado de cada letra', () async {
    final p = await ready();
    // Resposta fixa para o teste: modo ilimitado com o primeiro sorteio.
    await p.setMode(TermoMode.unlimited);
    final answer = p.answer;
    for (final guess in ['ARARA', 'CARRO', 'PORTA']) {
      if (guess == answer || p.phase != TermoPhase.playing) continue;
      typeWord(p, guess);
      p.submit();
    }
    for (final entry in p.keyboard.entries) {
      final best = p.guesses
          .expand((g) => [
                for (var i = 0; i < 5; i++)
                  if (g[i] == entry.key) evaluateGuess(g, answer)[i],
              ])
          .reduce((x, y) => x.index < y.index ? x : y);
      expect(entry.value, best, reason: entry.key);
    }
  });

  test('reabrir no mesmo dia restaura as tentativas', () async {
    final store = MemoryDailyStore();
    final first = await ready(store: store);
    final wrong = wrongWord(first);
    typeWord(first, wrong);
    first.submit();

    final again = await ready(store: store);
    expect(again.guesses, [wrong]);
    expect(again.phase, TermoPhase.playing);
  });

  test('palavra do dia terminada continua terminada ao reabrir', () async {
    final store = MemoryDailyStore();
    final first = await ready(store: store);
    typeWord(first, first.answer);
    first.submit();

    final again = await ready(store: store);
    expect(again.phase, TermoPhase.won);
    again.type('A');
    expect(again.current, '');
  });

  test('novo dia começa do zero', () async {
    final store = MemoryDailyStore(
        DailyState(date: '2026-10-04', guesses: const ['PORTA']));
    final p = await ready(store: store, now: day2);
    expect(p.guesses, isEmpty);
    expect(p.answer, dailyAnswer(bank, day2));
  });

  test('estado salvo com palavras fora do dicionário é ignorado', () async {
    final store = MemoryDailyStore(
        DailyState(date: '2026-10-04', guesses: const ['ZZZZZ', 'PORTA']));
    final p = await ready(store: store);
    expect(p.guesses, ['PORTA']);
  });

  test('ilimitado não salva e sorteia nova palavra ao terminar', () async {
    final store = MemoryDailyStore();
    final p = await ready(store: store);
    await p.setMode(TermoMode.unlimited);
    typeWord(p, p.answer);
    p.submit();
    expect(p.phase, TermoPhase.won);
    expect(store.saves, 0);
    p.newUnlimited();
    expect(p.phase, TermoPhase.playing);
    expect(p.guesses, isEmpty);
  });

  test('voltar ao modo diário restaura o dia', () async {
    final store = MemoryDailyStore();
    final p = await ready(store: store);
    final wrong = wrongWord(p);
    typeWord(p, wrong);
    p.submit();
    await p.setMode(TermoMode.unlimited);
    await p.setMode(TermoMode.daily);
    expect(p.guesses, [wrong]);
    expect(p.answer, dailyAnswer(bank, day1));
  });

  test('DailyState.fromJson rejeita lixo', () {
    expect(DailyState.fromJson('oi'), isNull);
    expect(DailyState.fromJson({'date': 1}), isNull);
    final s = DailyState.fromJson({'date': '2026-10-04', 'guesses': ['PORTA', 3]});
    expect(s!.guesses, ['PORTA']);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/games/termo/evaluate_test.dart test/games/termo/game_provider_test.dart`
Esperado: FAIL na compilação, porque `evaluate.dart`, `daily.dart` e `daily_store.dart` não existem.

- [ ] **Step 3: Implementar regras e palavra do dia**

```dart
// lib/games/termo/logic/evaluate.dart

enum LetterResult { correct, present, absent }

/// Cores de uma tentativa, pela regra oficial: verdes primeiro; amarelas só
/// enquanto sobrar a letra na resposta.
List<LetterResult> evaluateGuess(String guess, String answer) {
  final result = List.filled(guess.length, LetterResult.absent);
  final remaining = <String, int>{};
  for (var i = 0; i < answer.length; i++) {
    if (guess[i] == answer[i]) {
      result[i] = LetterResult.correct;
    } else {
      remaining[answer[i]] = (remaining[answer[i]] ?? 0) + 1;
    }
  }
  for (var i = 0; i < guess.length; i++) {
    if (result[i] == LetterResult.correct) continue;
    final left = remaining[guess[i]] ?? 0;
    if (left > 0) {
      result[i] = LetterResult.present;
      remaining[guess[i]] = left - 1;
    }
  }
  return result;
}
```

```dart
// lib/games/termo/logic/daily.dart

import 'dart:math';

import '../data/word_bank.dart';

final _epoch = DateTime.utc(2026, 1, 1);

/// Palavra do dia: a mesma em todos os celulares na mesma data, sem internet.
String dailyAnswer(WordBank bank, DateTime today) {
  final order = [...bank.answers]..shuffle(Random(20260101));
  final day = DateTime.utc(today.year, today.month, today.day);
  final index = day.difference(_epoch).inDays;
  return order[index % order.length];
}

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
```

```dart
// lib/games/termo/data/daily_store.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DailyState {
  const DailyState({required this.date, required this.guesses});

  /// Data no formato yyyy-MM-dd.
  final String date;
  final List<String> guesses;

  Map<String, Object> toJson() => {'date': date, 'guesses': guesses};

  static DailyState? fromJson(Object? json) {
    if (json is! Map) return null;
    final date = json['date'];
    final guesses = json['guesses'];
    if (date is! String || guesses is! List) return null;
    return DailyState(
      date: date,
      guesses: [for (final g in guesses) if (g is String) g],
    );
  }
}

abstract class DailyStore {
  Future<DailyState?> load();
  Future<void> save(DailyState state);
}

class SharedPrefsDailyStore implements DailyStore {
  static const _key = 'termo_daily';

  @override
  Future<DailyState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return DailyState.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(DailyState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }
}
```

```dart
// lib/games/termo/models/game_state.dart

enum TermoMode { daily, unlimited }

enum TermoPhase { playing, won, lost }
```

- [ ] **Step 4: Implementar o provider**

```dart
// lib/games/termo/providers/game_provider.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/daily_store.dart';
import '../data/word_bank.dart';
import '../logic/daily.dart';
import '../logic/evaluate.dart';
import '../logic/normalize.dart';
import '../models/game_state.dart';

class TermoProvider extends ChangeNotifier {
  TermoProvider({
    Future<WordBank>? bank,
    DailyStore? store,
    DateTime Function()? now,
    Random? random,
  })  : _store = store ?? SharedPrefsDailyStore(),
        _now = now ?? DateTime.now,
        _random = random ?? Random() {
    _init(bank ?? WordBank.load(rootBundle));
  }

  static const int wordLength = 5;
  static const int maxGuesses = 6;
  static final _letter = RegExp(r'^[A-Z]$');

  final DailyStore _store;
  final DateTime Function() _now;
  final Random _random;
  WordBank? _bank;
  bool _disposed = false;

  bool _loading = true;
  TermoMode _mode = TermoMode.daily;
  String _answer = '';
  String _dailyDate = '';
  final List<String> _guesses = [];
  String _current = '';
  TermoPhase _phase = TermoPhase.playing;
  String? _lastError;
  int _shakeCount = 0;

  bool get loading => _loading;
  TermoMode get mode => _mode;
  String get answer => _answer;
  String get answerDisplay => display(_answer);
  List<String> get guesses => List.unmodifiable(_guesses);
  String get current => _current;
  TermoPhase get phase => _phase;
  String? get lastError => _lastError;
  int get shakeCount => _shakeCount;

  /// Melhor resultado de cada letra já usada (verde > amarelo > cinza).
  Map<String, LetterResult> get keyboard {
    final best = <String, LetterResult>{};
    for (final guess in _guesses) {
      final results = evaluateGuess(guess, _answer);
      for (var i = 0; i < guess.length; i++) {
        final previous = best[guess[i]];
        if (previous == null || results[i].index < previous.index) {
          best[guess[i]] = results[i];
        }
      }
    }
    return best;
  }

  String display(String normal) => _bank?.display(normal) ?? normal;

  List<LetterResult> resultsFor(String guess) => evaluateGuess(guess, _answer);

  void type(String letter) {
    if (_loading || _phase != TermoPhase.playing) return;
    if (_current.length >= wordLength) return;
    final normal = normalizeWord(letter);
    if (!_letter.hasMatch(normal)) return;
    _current += normal;
    _lastError = null;
    notifyListeners();
  }

  void backspace() {
    if (_loading || _phase != TermoPhase.playing || _current.isEmpty) return;
    _current = _current.substring(0, _current.length - 1);
    notifyListeners();
  }

  void submit() {
    if (_loading || _phase != TermoPhase.playing) return;
    if (_current.length < wordLength) {
      _error('Só palavras com 5 letras');
      return;
    }
    if (!_bank!.isValid(_current)) {
      _error('Palavra inválida');
      return;
    }
    _guesses.add(_current);
    _current = '';
    _lastError = null;
    _updatePhase();
    if (_mode == TermoMode.daily) {
      unawaited(_store.save(
          DailyState(date: _dailyDate, guesses: List.of(_guesses))));
    }
    notifyListeners();
  }

  Future<void> setMode(TermoMode mode) async {
    if (_loading || mode == _mode) return;
    if (mode == TermoMode.unlimited) {
      _mode = TermoMode.unlimited;
      _newUnlimitedWord();
      notifyListeners();
    } else {
      _loading = true;
      notifyListeners();
      await _startDaily();
    }
  }

  /// Nova palavra no modo ilimitado, depois de terminar a atual.
  void newUnlimited() {
    if (_mode != TermoMode.unlimited || _phase == TermoPhase.playing) return;
    _newUnlimitedWord();
    notifyListeners();
  }

  Future<void> _init(Future<WordBank> bank) async {
    _bank = await bank;
    if (_disposed) return;
    await _startDaily();
  }

  Future<void> _startDaily() async {
    final now = _now();
    _mode = TermoMode.daily;
    _dailyDate = dateKey(now);
    _answer = dailyAnswer(_bank!, now);
    _guesses.clear();
    _current = '';
    _lastError = null;

    final saved = await _store.load();
    if (_disposed) return;
    if (saved != null && saved.date == _dailyDate) {
      _guesses.addAll(saved.guesses.where(_bank!.isValid).take(maxGuesses));
    }
    _updatePhase();
    _loading = false;
    notifyListeners();
  }

  void _newUnlimitedWord() {
    final answers = _bank!.answers;
    _answer = answers[_random.nextInt(answers.length)];
    _guesses.clear();
    _current = '';
    _lastError = null;
    _phase = TermoPhase.playing;
  }

  void _updatePhase() {
    if (_guesses.contains(_answer)) {
      _phase = TermoPhase.won;
    } else if (_guesses.length >= maxGuesses) {
      _phase = TermoPhase.lost;
    } else {
      _phase = TermoPhase.playing;
    }
  }

  void _error(String message) {
    _lastError = message;
    _shakeCount++;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
```

- [ ] **Step 5: Rodar e ver passar**

Run: `flutter test test/games/termo && flutter analyze lib/games/termo test/games/termo`
Esperado: PASS e `No issues found!`.

- [ ] **Step 6: Commit**

```bash
git add lib/games/termo test/games/termo
git commit -m "feat(termo): add scoring rules, daily word and game provider" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt"
```

---

### Task 6: Termo, tela

**Files:**
- Create: `lib/games/termo/widgets/guess_grid.dart`
- Create: `lib/games/termo/widgets/termo_keyboard.dart`
- Create: `lib/games/termo/screens/game_screen.dart`
- Test: `test/games/termo/game_screen_test.dart`

**Interfaces:**
- Consumes (Task 5): `TermoProvider`, `TermoMode`, `TermoPhase`, `LetterResult`.
- Produces:
  - `class TermoScreen extends StatefulWidget` (`const TermoScreen({super.key})`), que lê o `TermoProvider` de cima da árvore;
  - `Key('key-$label')` em cada tecla da tela (`key-A` ... `key-Z`, `key-ENTER`, `key-⌫`).

- [ ] **Step 1: Escrever o teste de widget que falha**

```dart
// test/games/termo/game_screen_test.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/termo/data/daily_store.dart';
import 'package:brincaki/games/termo/data/word_bank.dart';
import 'package:brincaki/games/termo/models/game_state.dart';
import 'package:brincaki/games/termo/providers/game_provider.dart';
import 'package:brincaki/games/termo/screens/game_screen.dart';

class _Store implements DailyStore {
  DailyState? state;
  @override
  Future<DailyState?> load() async => state;
  @override
  Future<void> save(DailyState s) async => state = s;
}

final _bank = WordBank(
  valid: {
    'CARRO': 'CARRO', 'PEDRA': 'PEDRA', 'AVIAO': 'AVIÃO',
    'PORTA': 'PORTA', 'MESAS': 'MESAS',
  },
  answers: ['CARRO', 'PEDRA', 'AVIAO'],
);

Future<TermoProvider> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = TermoProvider(
    bank: Future.value(_bank),
    store: _Store(),
    now: () => DateTime(2026, 10, 4),
    random: Random(3),
  );
  await tester.pumpWidget(ChangeNotifierProvider.value(
    value: provider,
    child: const MaterialApp(home: TermoScreen()),
  ));
  await tester.pumpAndSettle();
  return provider;
}

Future<void> tapWord(WidgetTester tester, String word) async {
  for (final letter in word.split('')) {
    await tester.tap(find.byKey(Key('key-$letter')));
  }
  await tester.tap(find.byKey(const Key('key-ENTER')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('acertar pelo teclado da tela mostra a vitória', (tester) async {
    final p = await pumpScreen(tester);
    expect(find.text('Palavra do dia'), findsOneWidget);
    await tapWord(tester, p.answer);
    expect(p.phase, TermoPhase.won);
    expect(find.text('🎉 Acertou em 1!'), findsOneWidget);
    expect(find.text('Volte amanhã para a próxima palavra!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('palavra inválida mostra o aviso', (tester) async {
    final p = await pumpScreen(tester);
    await tapWord(tester, 'CARRA'); // 5 letras, mas não está no dicionário
    expect(find.text('Palavra inválida'), findsOneWidget);
    expect(p.guesses, isEmpty);
  });

  testWidgets('teclado físico também funciona', (tester) async {
    final p = await pumpScreen(tester);
    final wrong = ['PORTA', 'MESAS'].firstWhere((w) => w != p.answer);
    for (final letter in wrong.split('')) {
      await tester.sendKeyEvent(
          LogicalKeyboardKey.findKeyByKeyId(letter.toLowerCase().codeUnitAt(0))!);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(p.guesses, [wrong]);
  });

  testWidgets('ilimitado: perder mostra a resposta e Nova palavra',
      (tester) async {
    final p = await pumpScreen(tester);
    await tester.tap(find.text('Ilimitado'));
    await tester.pumpAndSettle();
    expect(p.mode, TermoMode.unlimited);
    final wrong = ['PORTA', 'MESAS'].firstWhere((w) => w != p.answer);
    for (var i = 0; i < TermoProvider.maxGuesses; i++) {
      await tapWord(tester, wrong);
    }
    expect(find.text('A palavra era: ${p.answerDisplay}'), findsOneWidget);
    await tester.tap(find.text('Nova palavra'));
    await tester.pumpAndSettle();
    expect(p.phase, TermoPhase.playing);
  });
}
```

`findKeyByKeyId` usa o código da letra minúscula, que é o `keyId` das teclas de letra no Flutter: `LogicalKeyboardKey.keyA.keyId == 0x61`.

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/games/termo/game_screen_test.dart`
Esperado: FAIL na compilação, porque `game_screen.dart` não existe.

- [ ] **Step 3: Implementar a grade**

```dart
// lib/games/termo/widgets/guess_grid.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../logic/evaluate.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';

const kTermoGreen = Color(0xFF22C55E);
const kTermoYellow = Color(0xFFEAB308);
const kTermoGrey = Color(0xFF6B7280);

Color resultColor(LetterResult r) => switch (r) {
      LetterResult.correct => kTermoGreen,
      LetterResult.present => kTermoYellow,
      LetterResult.absent => kTermoGrey,
    };

class GuessGrid extends StatelessWidget {
  const GuessGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TermoProvider>();
    return AspectRatio(
      aspectRatio: TermoProvider.wordLength / TermoProvider.maxGuesses,
      child: Column(
        children: [
          for (var row = 0; row < TermoProvider.maxGuesses; row++)
            Expanded(child: _row(p, row)),
        ],
      ),
    );
  }

  Widget _row(TermoProvider p, int row) {
    if (row < p.guesses.length) {
      final guess = p.guesses[row];
      final shown = p.display(guess);
      final results = p.resultsFor(guess);
      return Row(
        children: [
          for (var i = 0; i < TermoProvider.wordLength; i++)
            Expanded(
              child: _RevealTile(
                key: ValueKey('r$row-$i-$guess'),
                letter: shown[i],
                color: resultColor(results[i]),
                delay: Duration(milliseconds: 120 * i),
              ),
            ),
        ],
      );
    }
    final isCurrent = row == p.guesses.length && p.phase == TermoPhase.playing;
    final letters = isCurrent ? p.current : '';
    final tiles = Row(
      children: [
        for (var i = 0; i < TermoProvider.wordLength; i++)
          Expanded(
            child: _Tile(
              letter: i < letters.length ? letters[i] : '',
              filled: i < letters.length,
            ),
          ),
      ],
    );
    if (!isCurrent || p.shakeCount == 0) return tiles;
    return TweenAnimationBuilder<double>(
      key: ValueKey('shake-${p.shakeCount}'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      builder: (context, t, child) => Transform.translate(
        offset: Offset(sin(t * pi * 6) * 8 * (1 - t), 0),
        child: child,
      ),
      child: tiles,
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.letter, required this.filled});

  final String letter;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: filled ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: _Letter(letter: letter, color: const Color(0xFF0F172A)),
      ),
    );
  }
}

/// Letra de uma tentativa enviada: gira e aparece com a cor do resultado.
class _RevealTile extends StatefulWidget {
  const _RevealTile({
    super.key,
    required this.letter,
    required this.color,
    required this.delay,
  });

  final String letter;
  final Color color;
  final Duration delay;

  @override
  State<_RevealTile> createState() => _RevealTileState();
}

class _RevealTileState extends State<_RevealTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  Timer? _start;

  @override
  void initState() {
    super.initState();
    _start = Timer(widget.delay, _controller.forward);
  }

  @override
  void dispose() {
    _start?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final revealed = t >= 0.5;
        return Padding(
          padding: const EdgeInsets.all(3),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..rotateX(t * pi),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationX(revealed ? pi : 0),
              child: Container(
                decoration: BoxDecoration(
                  color: revealed ? widget.color : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: revealed ? widget.color : const Color(0xFF334155),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: _Letter(
                  letter: widget.letter,
                  color: revealed ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Letter extends StatelessWidget {
  const _Letter({required this.letter, required this.color});

  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Text(
          letter,
          style: GoogleFonts.fredoka(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implementar o teclado**

```dart
// lib/games/termo/widgets/termo_keyboard.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import 'guess_grid.dart';

const _rows = [
  ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
  ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
  ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '⌫'],
];

class TermoKeyboard extends StatelessWidget {
  const TermoKeyboard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TermoProvider>();
    final colors = p.keyboard;

    return Column(
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                if (row.length == 9 && row.first == 'A') const Spacer(flex: 5),
                for (final label in row)
                  Expanded(
                    flex: label.length > 1 ? 15 : 10,
                    child: _Key(
                      label: label,
                      color: colors[label] == null
                          ? const Color(0xFFE2E8F0)
                          : resultColor(colors[label]!),
                      onTap: () {
                        if (label == 'ENTER') {
                          p.submit();
                        } else if (label == '⌫') {
                          p.backspace();
                        } else {
                          p.type(label);
                        }
                      },
                    ),
                  ),
                if (row.length == 9 && row.first == 'A') const Spacer(flex: 5),
              ],
            ),
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final light = color == const Color(0xFFE2E8F0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          key: Key('key-$label'),
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Center(
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    label,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: light ? const Color(0xFF0F172A) : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Implementar a tela**

```dart
// lib/games/termo/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/guess_grid.dart';
import '../widgets/termo_keyboard.dart';

const _background = Color(0xFFF0FDFA);
const _dark = Color(0xFF0F766E);

class TermoScreen extends StatefulWidget {
  const TermoScreen({super.key});

  @override
  State<TermoScreen> createState() => _TermoScreenState();
}

class _TermoScreenState extends State<TermoScreen> {
  late final TermoProvider _provider;
  int _shownShake = 0;

  @override
  void initState() {
    super.initState();
    _provider = context.read<TermoProvider>();
    _provider.addListener(_onChange);
  }

  /// Cada erro novo (shakeCount muda) mostra o aviso uma vez.
  void _onChange() {
    if (_provider.shakeCount == _shownShake) return;
    _shownShake = _provider.shakeCount;
    final message = _provider.lastError;
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  void dispose() {
    _provider.removeListener(_onChange);
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _provider.submit();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _provider.backspace();
      return KeyEventResult.handled;
    }
    final label = event.logicalKey.keyLabel;
    if (label.length == 1) {
      _provider.type(label);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TermoProvider>();

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _dark),
            tooltip: 'Voltar ao menu',
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
          title: Text(
            'Termo',
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: [
                SegmentedButton<TermoMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: TermoMode.daily, label: Text('Palavra do dia')),
                    ButtonSegment(value: TermoMode.unlimited, label: Text('Ilimitado')),
                  ],
                  selected: {p.mode},
                  onSelectionChanged: (s) => p.setMode(s.first),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: p.loading
                        ? Text(
                            'Carregando palavras...',
                            style: GoogleFonts.fredoka(fontSize: 16, color: _dark),
                          )
                        : const GuessGrid(),
                  ),
                ),
                if (!p.loading && p.phase != TermoPhase.playing) const _EndPanel(),
                const SizedBox(height: 8),
                if (!p.loading) const TermoKeyboard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EndPanel extends StatelessWidget {
  const _EndPanel();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TermoProvider>();
    final won = p.phase == TermoPhase.won;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _dark.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            won ? '🎉 Acertou em ${p.guesses.length}!' : 'A palavra era: ${p.answerDisplay}',
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          const SizedBox(height: 6),
          if (p.mode == TermoMode.daily)
            Text(
              'Volte amanhã para a próxima palavra!',
              style: GoogleFonts.fredoka(fontSize: 14, color: Colors.black54),
            )
          else
            ElevatedButton(
              onPressed: p.newUnlimited,
              style: ElevatedButton.styleFrom(
                backgroundColor: _dark,
                foregroundColor: Colors.white,
              ),
              child: Text('Nova palavra', style: GoogleFonts.fredoka(fontSize: 16)),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Rodar e ver passar**

Run: `flutter test test/games/termo && flutter analyze lib/games/termo test/games/termo`
Esperado: PASS e `No issues found!`.

Se o teste "palavra inválida" encontrar dois widgets com o texto (o `SnackBar` e outro), troque o `expect` para `findsWidgets`. O que importa é o aviso aparecer e `guesses` continuar vazio.

- [ ] **Step 7: Commit**

```bash
git add lib/games/termo test/games/termo
git commit -m "feat(termo): add Termo screen with animated grid and on-screen keyboard" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt"
```

---

### Task 7: Lig 4, tabuleiro e computador

**Files:**
- Create: `lib/games/lig4/logic/board.dart`
- Create: `lib/games/lig4/logic/ai.dart`
- Test: `test/games/lig4/board_test.dart`
- Test: `test/games/lig4/ai_test.dart`

**Interfaces:**
- Produces:
  - `const kRows = 6` e `const kCols = 7`. Tabuleiro `List<List<int>>` com `[linha][coluna]`, sendo a linha 0 o topo, 0 vazio e 1 ou 2 para os jogadores.
  - `List<List<int>> emptyBoard()`, `int? dropRow(board, int col)`, `List<List<int>> drop(board, int col, int player)` (lança `ArgumentError` se a coluna estiver cheia), `List<(int, int)>? winningLine(board)`, `bool hasLine(board, int player)`, `bool isFull(board)`, `List<int> validColumns(board)`
  - `enum AiLevel { easy, medium, hard }` e `int chooseColumn(List<List<int>> board, int me, AiLevel level, Random random)`
  - `int chooseColumnInIsolate((List<List<int>>, int, int, int) args)`: `(board, me, levelIndex, seed)`, função de topo para usar com `compute`

- [ ] **Step 1: Escrever os testes que falham**

```dart
// test/games/lig4/board_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/lig4/logic/board.dart';

/// Monta um tabuleiro a partir de 6 strings de 7 caracteres ('.', '1', '2'),
/// da linha de cima para a de baixo.
List<List<int>> board(List<String> rows) => [
      for (final r in rows) [for (final ch in r.split('')) ch == '.' ? 0 : int.parse(ch)],
    ];

void main() {
  test('peça cai na posição livre mais baixa', () {
    var b = emptyBoard();
    expect(dropRow(b, 3), 5);
    b = drop(b, 3, 1);
    expect(b[5][3], 1);
    expect(dropRow(b, 3), 4);
  });

  test('coluna cheia não aceita peça', () {
    var b = emptyBoard();
    for (var i = 0; i < kRows; i++) {
      b = drop(b, 0, i.isEven ? 1 : 2);
    }
    expect(dropRow(b, 0), isNull);
    expect(validColumns(b), [1, 2, 3, 4, 5, 6]);
    expect(() => drop(b, 0, 1), throwsArgumentError);
  });

  test('vitória horizontal, vertical e nas duas diagonais', () {
    expect(winningLine(board([
      '.......', '.......', '.......', '.......', '.......', '.1111..',
    ])), [(5, 1), (5, 2), (5, 3), (5, 4)]);
    expect(winningLine(board([
      '.......', '.......', '..2....', '..2....', '..2....', '..2....',
    ])), isNotNull);
    expect(winningLine(board([
      '.......', '.......', '...1...', '..12...', '.122...', '1222...',
    ])), isNotNull); // diagonal ↗
    expect(winningLine(board([
      '.......', '.......', '1......', '21.....', '221....', '2221...',
    ])), isNotNull); // diagonal ↘
  });

  test('peças de jogadores diferentes não formam linha', () {
    expect(winningLine(board([
      '.......', '.......', '.......', '.......', '.......', '.1121..',
    ])), isNull);
    expect(hasLine(board([
      '.......', '.......', '.......', '.......', '.......', '2222...',
    ]), 1), isFalse);
  });

  test('isFull', () {
    expect(isFull(emptyBoard()), isFalse);
    expect(isFull(List.generate(kRows, (r) => List.filled(kCols, 1 + r % 2))), isTrue);
  });
}
```

```dart
// test/games/lig4/ai_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/lig4/logic/ai.dart';

List<List<int>> board(List<String> rows) => [
      for (final r in rows) [for (final ch in r.split('')) ch == '.' ? 0 : int.parse(ch)],
    ];

void main() {
  // 1 tem três na linha de baixo e é a vez de 1.
  final winNow = board([
    '.......', '.......', '.......', '.......', '22.....', '111....',
  ]);
  // 2 tem três na linha de baixo e é a vez de 1.
  final mustBlock = board([
    '.......', '.......', '.......', '.......', '11.....', '222...1',
  ]);
  // Jogar na coluna 3 (vazia) deixa 2 completar a linha 4 logo em cima.
  final poisoned = board([
    '.......', '.......', '.......', '.......', '222....', '121..11',
  ]);
  // Vez de 1: jogar na coluna 1 ou 4 cria três abertos na linha de baixo
  // (ameaça dupla) e a vitória é forçada.
  final doubleThreat = board([
    '.......', '.......', '.......', '.......', '..22...', '..11...',
  ]);
  // Vez de 2: se não jogar na coluna 1 ou 4 agora, 1 cria a ameaça dupla.
  final trap = board([
    '.......', '.......', '.......', '.......', '...2...', '..11...',
  ]);

  test('médio sempre aproveita a vitória imediata', () {
    for (var seed = 0; seed < 20; seed++) {
      expect(chooseColumn(winNow, 1, AiLevel.medium, Random(seed)), 3);
    }
  });

  test('médio sempre bloqueia a vitória do adversário', () {
    for (var seed = 0; seed < 20; seed++) {
      expect(chooseColumn(mustBlock, 1, AiLevel.medium, Random(seed)), 3);
    }
  });

  test('médio não joga onde entrega a vitória', () {
    for (var seed = 0; seed < 30; seed++) {
      expect(chooseColumn(poisoned, 1, AiLevel.medium, Random(seed)), isNot(3));
    }
  });

  test('difícil acha a vitória com ameaça dupla', () {
    for (var seed = 0; seed < 5; seed++) {
      expect(chooseColumn(doubleThreat, 1, AiLevel.hard, Random(seed)),
          anyOf(1, 4));
    }
  });

  test('difícil evita a armadilha em que o médio cai', () {
    for (var seed = 0; seed < 5; seed++) {
      expect(chooseColumn(trap, 2, AiLevel.hard, Random(seed)), anyOf(1, 4));
    }
    final mediumChoices = {
      for (var seed = 0; seed < 30; seed++)
        chooseColumn(trap, 2, AiLevel.medium, Random(seed)),
    };
    expect(mediumChoices.difference({1, 4}), isNotEmpty);
  });

  test('nenhum nível escolhe coluna cheia', () {
    final fullCenter = board([
      '...1...', '...2...', '...1...', '...2...', '...1...', '...2...',
    ]);
    for (final level in AiLevel.values) {
      for (var seed = 0; seed < 30; seed++) {
        final col = chooseColumn(fullCenter, 1, level, Random(seed));
        expect(col, isNot(3));
        expect(col, inInclusiveRange(0, 6));
      }
    }
  });

  test('fácil às vezes não bloqueia', () {
    final choices = {
      for (var seed = 0; seed < 40; seed++)
        chooseColumn(mustBlock, 1, AiLevel.easy, Random(seed)),
    };
    expect(choices.length, greaterThan(1));
  });

  test('difícil decide em menos de 2 segundos no meio da partida', () {
    final midGame = board([
      '.......', '.......', '...2...', '..121..', '..212..', '.12121.',
    ]);
    final watch = Stopwatch()..start();
    chooseColumn(midGame, 1, AiLevel.hard, Random(1));
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/games/lig4`
Esperado: FAIL na compilação, porque `board.dart` e `ai.dart` não existem.

- [ ] **Step 3: Implementar o tabuleiro**

```dart
// lib/games/lig4/logic/board.dart

const int kRows = 6;
const int kCols = 7;

const _directions = [(0, 1), (1, 0), (1, 1), (-1, 1)];

List<List<int>> emptyBoard() => List.generate(kRows, (_) => List.filled(kCols, 0));

/// Linha onde a peça cairia na coluna, ou null se a coluna estiver cheia.
int? dropRow(List<List<int>> board, int col) {
  for (var r = kRows - 1; r >= 0; r--) {
    if (board[r][col] == 0) return r;
  }
  return null;
}

List<List<int>> drop(List<List<int>> board, int col, int player) {
  final row = dropRow(board, col);
  if (row == null) throw ArgumentError('Coluna $col cheia');
  final next = board.map((r) => List<int>.from(r)).toList();
  next[row][col] = player;
  return next;
}

/// As 4 células alinhadas de qualquer jogador, ou null.
List<(int, int)>? winningLine(List<List<int>> board) {
  for (final player in const [1, 2]) {
    final line = _lineOf(board, player);
    if (line != null) return line;
  }
  return null;
}

bool hasLine(List<List<int>> board, int player) => _lineOf(board, player) != null;

List<(int, int)>? _lineOf(List<List<int>> board, int player) {
  for (var r = 0; r < kRows; r++) {
    for (var c = 0; c < kCols; c++) {
      if (board[r][c] != player) continue;
      for (final (dr, dc) in _directions) {
        final cells = [for (var k = 0; k < 4; k++) (r + dr * k, c + dc * k)];
        if (cells.every((p) =>
            p.$1 >= 0 && p.$1 < kRows && p.$2 >= 0 && p.$2 < kCols &&
            board[p.$1][p.$2] == player)) {
          return cells;
        }
      }
    }
  }
  return null;
}

bool isFull(List<List<int>> board) => board[0].every((v) => v != 0);

List<int> validColumns(List<List<int>> board) =>
    [for (var c = 0; c < kCols; c++) if (board[0][c] == 0) c];
```

- [ ] **Step 4: Implementar o computador**

```dart
// lib/games/lig4/logic/ai.dart

import 'dart:math';

import 'board.dart';

enum AiLevel { easy, medium, hard }

const _centerOrder = [3, 2, 4, 1, 5, 0, 6];
const _centerWeights = [1, 2, 3, 4, 3, 2, 1];
const _winScore = 1000000;
const _infinity = 1 << 40;
const _hardDepth = 6;

/// Coluna escolhida pelo computador (jogador [me]) no nível pedido.
int chooseColumn(List<List<int>> board, int me, AiLevel level, Random random) {
  return switch (level) {
    AiLevel.easy => _easy(board, me, random),
    AiLevel.medium => _medium(board, me, random),
    AiLevel.hard => _hard(board, me, random),
  };
}

/// Para `compute`: (tabuleiro, jogador, índice do nível, semente).
int chooseColumnInIsolate((List<List<int>>, int, int, int) args) {
  final (board, me, level, seed) = args;
  return chooseColumn(board, me, AiLevel.values[level], Random(seed));
}

int? _winningMove(List<List<int>> board, int player) {
  for (final c in validColumns(board)) {
    if (hasLine(drop(board, c, player), player)) return c;
  }
  return null;
}

int _easy(List<List<int>> board, int me, Random random) {
  final win = _winningMove(board, me);
  if (win != null && random.nextBool()) return win;
  final valid = validColumns(board);
  return valid[random.nextInt(valid.length)];
}

int _medium(List<List<int>> board, int me, Random random) {
  final opp = 3 - me;
  final win = _winningMove(board, me);
  if (win != null) return win;
  final block = _winningMove(board, opp);
  if (block != null) return block;
  final valid = validColumns(board);
  final safe = [
    for (final c in valid)
      if (_winningMove(drop(board, c, me), opp) == null) c,
  ];
  return _weightedCenter(safe.isEmpty ? valid : safe, random);
}

int _weightedCenter(List<int> options, Random random) {
  final total = options.fold<int>(0, (sum, c) => sum + _centerWeights[c]);
  var pick = random.nextInt(total);
  for (final c in options) {
    pick -= _centerWeights[c];
    if (pick < 0) return c;
  }
  return options.last;
}

int _hard(List<List<int>> board, int me, Random random) {
  final opp = 3 - me;
  var best = -_infinity;
  final bestCols = <int>[];
  for (final c in _centerOrder) {
    if (board[0][c] != 0) continue;
    final score =
        -_negamax(drop(board, c, me), _hardDepth - 1, -_infinity, _infinity, opp);
    if (score > best) {
      best = score;
      bestCols
        ..clear()
        ..add(c);
    } else if (score == best) {
      bestCols.add(c);
    }
  }
  return bestCols[random.nextInt(bestCols.length)];
}

/// Pontuação do ponto de vista de [player], que joga agora.
int _negamax(List<List<int>> board, int depth, int alpha, int beta, int player) {
  final opp = 3 - player;
  // Quem acabou de jogar foi o adversário: se ele alinhou, perdi.
  // Perder mais tarde (menos profundidade restante) é menos ruim.
  if (hasLine(board, opp)) return -(_winScore + depth);
  if (isFull(board)) return 0;
  if (depth == 0) return _evaluate(board, player);

  var best = -_infinity;
  for (final c in _centerOrder) {
    if (board[0][c] != 0) continue;
    final score = -_negamax(drop(board, c, player), depth - 1, -beta, -alpha, opp);
    if (score > best) best = score;
    if (best > alpha) alpha = best;
    if (alpha >= beta) break;
  }
  return best;
}

int _evaluate(List<List<int>> board, int me) {
  final opp = 3 - me;
  var score = 0;
  for (var r = 0; r < kRows; r++) {
    if (board[r][3] == me) score += 6;
  }
  for (var r = 0; r < kRows; r++) {
    for (var c = 0; c < kCols; c++) {
      for (final (dr, dc) in const [(0, 1), (1, 0), (1, 1), (-1, 1)]) {
        final endR = r + dr * 3;
        final endC = c + dc * 3;
        if (endR < 0 || endR >= kRows || endC >= kCols) continue;
        var mine = 0, theirs = 0, empty = 0;
        for (var k = 0; k < 4; k++) {
          final v = board[r + dr * k][c + dc * k];
          if (v == me) {
            mine++;
          } else if (v == opp) {
            theirs++;
          } else {
            empty++;
          }
        }
        if (mine == 3 && empty == 1) score += 50;
        if (mine == 2 && empty == 2) score += 10;
        if (theirs == 3 && empty == 1) score -= 80;
        if (theirs == 2 && empty == 2) score -= 10;
      }
    }
  }
  return score;
}
```

- [ ] **Step 5: Rodar e ver passar**

Run: `flutter test test/games/lig4 && flutter analyze lib/games/lig4 test/games/lig4`
Esperado: PASS e `No issues found!`.

O teste "difícil evita a armadilha" também confere que o médio cai nela em pelo menos uma de 30 sementes. Se o médio nunca cair (o peso do centro favorece as colunas 2, 3 e 4), a premissa do teste está errada e não o código. Nesse caso, troque o tabuleiro `trap` por um em que o centro esteja ocupado e a defesa fique nas bordas, e mantenha as duas metades do teste.

- [ ] **Step 6: Commit**

```bash
git add lib/games/lig4/logic test/games/lig4
git commit -m "feat(lig4): add Connect Four board logic and three AI levels" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt"
```

---

### Task 8: Lig 4, provider e tela

**Files:**
- Create: `lib/games/lig4/models/game_state.dart`
- Create: `lib/games/lig4/providers/game_provider.dart`
- Create: `lib/games/lig4/widgets/board_view.dart`
- Create: `lib/games/lig4/screens/game_screen.dart`
- Test: `test/games/lig4/game_provider_test.dart`
- Test: `test/games/lig4/game_screen_test.dart`

**Interfaces:**
- Consumes:
  - da Task 7: `emptyBoard`, `dropRow`, `drop`, `winningLine`, `isFull`, `validColumns`, `AiLevel`, `chooseColumn` e `chooseColumnInIsolate`;
  - da Task 1: `PlayerSetup`, `PlayerSetupResult`, `PlayMode` e `ScoreBoard`.
- Produces:
  - `enum Lig4Phase { setup, playing, finished }`
  - `typedef AiRunner = Future<int> Function(List<List<int>> board, int me, AiLevel level)`
  - `class Lig4Provider extends ChangeNotifier`:
    - construtor `Lig4Provider({Random? random, Duration thinkTime = const Duration(milliseconds: 500), AiRunner? aiRunner})`;
    - constante `computer = 2`;
    - getters `phase`, `mode`, `name1`, `name2`, `aiLevel`, `board`, `currentPlayer`, `winner`, `winningCells`, `wins1`, `wins2`, `draws`, `aiThinking`, `lastMove`, `moveCount`, `isComputerTurn`;
    - métodos `start(PlayerSetupResult)`, `play(int col)`, `playAgain()`, `exitToSetup()`.
  - `class Lig4Screen extends StatelessWidget` (`const Lig4Screen({super.key})`), com `Key('col-$c')` em cada coluna.

- [ ] **Step 1: Escrever os testes que falham**

```dart
// test/games/lig4/game_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/lig4/logic/ai.dart';
import 'package:brincaki/games/lig4/logic/board.dart';
import 'package:brincaki/games/lig4/models/game_state.dart';
import 'package:brincaki/games/lig4/providers/game_provider.dart';
import 'package:brincaki/widgets/player_setup.dart';

const _duo = PlayerSetupResult(mode: PlayMode.twoPlayers, player1: 'Ana', player2: 'Beto');
const _vsAi = PlayerSetupResult(
    mode: PlayMode.solo, player1: 'Ana', player2: 'Computador', levelIndex: 1);

/// Computador previsível: primeira coluna livre.
Future<int> firstFree(List<List<int>> board, int me, AiLevel level) async =>
    validColumns(board).first;

Future<void> settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('dois jogadores alternam e a vitória atualiza o placar', () {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree)..start(_duo);
    expect(p.phase, Lig4Phase.playing);
    for (final col in [0, 1, 0, 1, 0, 1]) {
      p.play(col);
    }
    expect(p.currentPlayer, 1);
    p.play(0); // quatro em pé na coluna 0
    expect(p.phase, Lig4Phase.finished);
    expect(p.winner, 1);
    expect(p.winningCells, hasLength(4));
    expect(p.wins1, 1);
    p.play(2); // depois do fim, nada muda
    expect(p.board[5][2], 0);
  });

  test('coluna cheia é ignorada', () {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree)..start(_duo);
    for (var i = 0; i < kRows; i++) {
      p.play(3);
    }
    final player = p.currentPlayer;
    p.play(3);
    expect(p.currentPlayer, player);
  });

  test('empate com o tabuleiro cheio', () {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree)..start(_duo);
    // Ordem conferida: enche as 42 casas sem ninguém alinhar 4.
    const order = [0, 1, 0, 1, 0, 1, 2, 3, 2, 3, 2, 3, 1, 0, 1, 0, 1, 0,
                   3, 2, 3, 2, 3, 2, 4, 5, 4, 5, 4, 5, 6, 4, 5, 6, 6, 4,
                   5, 6, 6, 4, 5, 6];
    for (final col in order) {
      p.play(col);
    }
    expect(isFull(p.board), isTrue);
    expect(p.phase, Lig4Phase.finished);
    expect(p.winner, isNull);
    expect(p.draws, 1);
  });

  test('contra o computador: ele responde e toques na vez dele são ignorados',
      () async {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree)..start(_vsAi);
    expect(p.aiLevel, AiLevel.medium);
    p.play(3);
    expect(p.isComputerTurn, isTrue);
    p.play(4); // vez do computador: ignorado
    expect(p.board[5][4], 0);
    await settle();
    expect(p.board[5][0], Lig4Provider.computer);
    expect(p.currentPlayer, 1);
    expect(p.aiThinking, isFalse);
  });

  test('jogada do computador que chega depois de sair é descartada', () async {
    final p = Lig4Provider(thinkTime: const Duration(milliseconds: 50), aiRunner: firstFree)
      ..start(_vsAi);
    p.play(3);
    p.exitToSetup();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(p.phase, Lig4Phase.setup);
    expect(p.aiThinking, isFalse);
  });

  test('jogar de novo alterna quem começa; o computador começa sozinho',
      () async {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree)..start(_vsAi);
    // Humano vence rápido na coluna 6 (o computador joga sempre na 0).
    for (var i = 0; i < 4; i++) {
      p.play(6);
      await settle();
    }
    expect(p.winner, 1);
    p.playAgain();
    await settle();
    expect(p.board[5][0], Lig4Provider.computer);
    expect(p.currentPlayer, 1);
  });

  test('trocar jogadores zera o placar', () {
    final p = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree)..start(_duo);
    for (final col in [0, 1, 0, 1, 0, 1, 0]) {
      p.play(col);
    }
    p.exitToSetup();
    expect(p.phase, Lig4Phase.setup);
    expect(p.wins1 + p.wins2 + p.draws, 0);
  });
}
```

A ordem do teste de empate foi conferida por simulação: enche as 42 casas sem nenhuma linha de 4.

```dart
// test/games/lig4/game_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/lig4/logic/ai.dart';
import 'package:brincaki/games/lig4/logic/board.dart';
import 'package:brincaki/games/lig4/providers/game_provider.dart';
import 'package:brincaki/games/lig4/screens/game_screen.dart';

Future<int> firstFree(List<List<int>> board, int me, AiLevel level) async =>
    validColumns(board).first;

Future<Lig4Provider> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = Lig4Provider(thinkTime: Duration.zero, aiRunner: firstFree);
  await tester.pumpWidget(ChangeNotifierProvider.value(
    value: provider,
    child: const MaterialApp(home: Lig4Screen()),
  ));
  return provider;
}

void main() {
  testWidgets('dois jogadores: tocar na coluna solta a peça', (tester) async {
    final p = await pumpScreen(tester);
    await tester.tap(find.text('Dois jogadores'));
    await tester.pump();
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('col-3')));
    await tester.pumpAndSettle();
    expect(p.board[5][3], 1);
    expect(find.text('Vez de 🟡 Jogador 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('contra o computador: ele responde e o título mostra o nível',
      (tester) async {
    final p = await pumpScreen(tester);
    await tester.tap(find.text('Difícil'));
    await tester.pump();
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    expect(find.text('Lig 4 • Difícil'), findsOneWidget);
    await tester.tap(find.byKey(const Key('col-3')));
    await tester.pumpAndSettle();
    expect(p.board[5][0], Lig4Provider.computer);
  });

  testWidgets('vitória mostra o resultado e Trocar jogadores volta ao setup',
      (tester) async {
    final p = await pumpScreen(tester);
    await tester.tap(find.text('Dois jogadores'));
    await tester.pump();
    await tester.tap(find.text('Jogar!'));
    await tester.pumpAndSettle();
    for (final col in [0, 1, 0, 1, 0, 1, 0]) {
      await tester.tap(find.byKey(Key('col-$col')));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pump(const Duration(seconds: 2));
    expect(p.winner, 1);
    expect(find.text('🏆 Jogador 1 venceu!'), findsOneWidget);
    await tester.tap(find.text('Trocar jogadores'));
    await tester.pumpAndSettle();
    expect(find.text('Jogar!'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/games/lig4/game_provider_test.dart test/games/lig4/game_screen_test.dart`
Esperado: FAIL na compilação, porque o provider e a tela não existem.

- [ ] **Step 3: Implementar o modelo e o provider**

```dart
// lib/games/lig4/models/game_state.dart

enum Lig4Phase { setup, playing, finished }
```

```dart
// lib/games/lig4/providers/game_provider.dart

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../widgets/player_setup.dart';
import '../logic/ai.dart';
import '../logic/board.dart';
import '../models/game_state.dart';

typedef AiRunner = Future<int> Function(List<List<int>> board, int me, AiLevel level);

class Lig4Provider extends ChangeNotifier {
  Lig4Provider({
    Random? random,
    Duration thinkTime = const Duration(milliseconds: 500),
    AiRunner? aiRunner,
  })  : _random = random ?? Random(),
        _thinkTime = thinkTime {
    _aiRunner = aiRunner ?? _defaultRunner;
  }

  /// O humano é sempre o jogador 1 (🔴); o computador é o 2 (🟡).
  static const int computer = 2;

  final Random _random;
  final Duration _thinkTime;
  late final AiRunner _aiRunner;
  bool _disposed = false;

  /// Muda a cada partida nova: descarta jogadas do computador atrasadas.
  int _gameId = 0;

  Lig4Phase _phase = Lig4Phase.setup;
  PlayMode _mode = PlayMode.twoPlayers;
  String _name1 = '';
  String _name2 = '';
  AiLevel _aiLevel = AiLevel.medium;
  List<List<int>> _board = emptyBoard();
  int _currentPlayer = 1;
  int _startingPlayer = 1;
  int? _winner;
  List<(int, int)>? _winningCells;
  int _wins1 = 0;
  int _wins2 = 0;
  int _draws = 0;
  bool _aiThinking = false;
  (int, int)? _lastMove;
  int _moveCount = 0;

  Lig4Phase get phase => _phase;
  PlayMode get mode => _mode;
  String get name1 => _name1;
  String get name2 => _name2;
  AiLevel get aiLevel => _aiLevel;
  List<List<int>> get board => _board;
  int get currentPlayer => _currentPlayer;
  int? get winner => _winner;
  List<(int, int)>? get winningCells => _winningCells;
  int get wins1 => _wins1;
  int get wins2 => _wins2;
  int get draws => _draws;
  bool get aiThinking => _aiThinking;
  (int, int)? get lastMove => _lastMove;
  int get moveCount => _moveCount;
  bool get isComputerTurn =>
      _mode == PlayMode.solo &&
      _phase == Lig4Phase.playing &&
      _currentPlayer == computer;

  void start(PlayerSetupResult setup) {
    _mode = setup.mode;
    _name1 = setup.player1;
    _name2 = setup.player2;
    _aiLevel = AiLevel.values[setup.levelIndex ?? 1];
    _wins1 = 0;
    _wins2 = 0;
    _draws = 0;
    _startingPlayer = 1;
    _newGame();
    notifyListeners();
  }

  void play(int col) {
    if (_phase != Lig4Phase.playing || _aiThinking || isComputerTurn) return;
    _apply(col);
  }

  void playAgain() {
    if (_phase != Lig4Phase.finished) return;
    _startingPlayer = 3 - _startingPlayer;
    _newGame();
    notifyListeners();
    if (isComputerTurn) _computerMove();
  }

  void exitToSetup() {
    _gameId++;
    _phase = Lig4Phase.setup;
    _aiThinking = false;
    _wins1 = 0;
    _wins2 = 0;
    _draws = 0;
    notifyListeners();
  }

  void _apply(int col) {
    final row = dropRow(_board, col);
    if (row == null) return;
    _board = drop(_board, col, _currentPlayer);
    _lastMove = (row, col);
    _moveCount++;

    final line = winningLine(_board);
    if (line != null) {
      _winner = _currentPlayer;
      _winningCells = line;
      _phase = Lig4Phase.finished;
      if (_winner == 1) {
        _wins1++;
      } else {
        _wins2++;
      }
    } else if (isFull(_board)) {
      _winner = null;
      _phase = Lig4Phase.finished;
      _draws++;
    } else {
      _currentPlayer = 3 - _currentPlayer;
    }
    notifyListeners();
    if (isComputerTurn) _computerMove();
  }

  Future<void> _computerMove() async {
    final game = _gameId;
    _aiThinking = true;
    notifyListeners();
    await Future<void>.delayed(_thinkTime);
    if (_disposed || game != _gameId) return;
    final snapshot = _board.map((r) => List<int>.from(r)).toList();
    final col = await _aiRunner(snapshot, computer, _aiLevel);
    if (_disposed || game != _gameId) return;
    _aiThinking = false;
    _apply(col);
  }

  Future<int> _defaultRunner(List<List<int>> board, int me, AiLevel level) {
    final seed = _random.nextInt(1 << 30);
    if (level == AiLevel.hard) {
      return compute(chooseColumnInIsolate, (board, me, level.index, seed));
    }
    return Future.value(chooseColumn(board, me, level, Random(seed)));
  }

  void _newGame() {
    _gameId++;
    _board = emptyBoard();
    _currentPlayer = _startingPlayer;
    _winner = null;
    _winningCells = null;
    _lastMove = null;
    _moveCount = 0;
    _aiThinking = false;
    _phase = Lig4Phase.playing;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
```

- [ ] **Step 4: Implementar o tabuleiro na tela**

```dart
// lib/games/lig4/widgets/board_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/board.dart';
import '../providers/game_provider.dart';

const kLig4Blue = Color(0xFF2563EB);
const kLig4Red = Color(0xFFEF4444);
const kLig4Yellow = Color(0xFFFACC15);

class BoardView extends StatelessWidget {
  const BoardView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<Lig4Provider>();
    final winning = p.winningCells?.toSet() ?? const <(int, int)>{};

    return AspectRatio(
      aspectRatio: kCols / kRows,
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: kLig4Blue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            for (var c = 0; c < kCols; c++)
              Expanded(
                child: GestureDetector(
                  key: Key('col-$c'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => p.play(c),
                  child: Column(
                    children: [
                      for (var r = 0; r < kRows; r++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: _Hole(
                              value: p.board[r][c],
                              winning: winning.contains((r, c)),
                              falling: p.lastMove == (r, c),
                              dropRows: r + 1,
                              moveCount: p.moveCount,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Hole extends StatelessWidget {
  const _Hole({
    required this.value,
    required this.winning,
    required this.falling,
    required this.dropRows,
    required this.moveCount,
  });

  final int value;
  final bool winning;
  final bool falling;
  final int dropRows;
  final int moveCount;

  @override
  Widget build(BuildContext context) {
    if (value == 0) {
      return const DecoratedBox(
        decoration: BoxDecoration(color: Color(0xFFDBEAFE), shape: BoxShape.circle),
      );
    }
    Widget piece = DecoratedBox(
      decoration: BoxDecoration(
        color: value == 1 ? kLig4Red : kLig4Yellow,
        shape: BoxShape.circle,
        border: winning ? Border.all(color: Colors.white, width: 3) : null,
      ),
    );
    if (winning) piece = _Pulse(child: piece);
    if (!falling) return piece;
    // Cai de cima da coluna até a posição dela.
    return TweenAnimationBuilder<double>(
      key: ValueKey('drop-$moveCount'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
      builder: (context, t, child) => FractionalTranslation(
        translation: Offset(0, -dropRows * (1 - t)),
        child: child,
      ),
      child: piece,
    );
  }
}

/// Pulsa algumas vezes (nunca para sempre: testes usam pumpAndSettle).
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    lowerBound: 1,
    upperBound: 1.12,
  )..repeat(reverse: true, count: 6);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _controller, child: widget.child);
  }
}
```

- [ ] **Step 5: Implementar a tela**

```dart
// lib/games/lig4/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../widgets/player_setup.dart';
import '../../../widgets/score_board.dart';
import '../logic/ai.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/board_view.dart';

const _background = Color(0xFFFEF2F2);
const _dark = Color(0xFFB91C1C);
const _levels = ['Fácil', 'Médio', 'Difícil'];

class Lig4Screen extends StatelessWidget {
  const Lig4Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<Lig4Provider>();
    final title = p.phase != Lig4Phase.setup && p.mode == PlayMode.solo
        ? 'Lig 4 • ${_levels[AiLevel.values.indexOf(p.aiLevel)]}'
        : 'Lig 4';

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _dark),
          tooltip: 'Voltar ao menu',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        title: Text(
          title,
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _dark,
          ),
        ),
      ),
      body: SafeArea(
        child: p.phase == Lig4Phase.setup
            ? PlayerSetup(
                title: 'Lig 4',
                emoji: '🔴',
                accent: kLig4Red,
                soloLabel: 'Contra o computador',
                symbols: ('🔴', '🟡'),
                levels: _levels,
                soloOpponentName: 'Computador',
                onStart: p.start,
              )
            : const _GameView(),
      ),
    );
  }
}

class _GameView extends StatelessWidget {
  const _GameView();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<Lig4Provider>();
    final symbol = p.currentPlayer == 1 ? '🔴' : '🟡';
    final name = p.currentPlayer == 1 ? p.name1 : p.name2;
    final turn = p.isComputerTurn || p.aiThinking ? '🤖 Pensando...' : 'Vez de $symbol $name';

    return Column(
      children: [
        ScoreBoard(
          name1: p.name1,
          name2: p.name2,
          symbol1: '🔴',
          symbol2: '🟡',
          score1: p.wins1,
          score2: p.wins2,
          draws: p.draws,
          activePlayer: p.phase == Lig4Phase.playing ? p.currentPlayer : null,
          accent: kLig4Red,
        ),
        if (p.phase == Lig4Phase.playing)
          Text(
            turn,
            style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600, color: _dark),
          ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: BoardView()),
          ),
        ),
        if (p.phase == Lig4Phase.finished) const _ResultPanel(),
      ],
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<Lig4Provider>();
    final text = switch (p.winner) {
      null => '🤝 Empate!',
      Lig4Provider.computer when p.mode == PlayMode.solo => '🤖 O computador venceu!',
      1 => '🏆 ${p.name1} venceu!',
      _ => '🏆 ${p.name2} venceu!',
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kLig4Red.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.bold, color: _dark),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                onPressed: p.playAgain,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kLig4Red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Jogar de novo', style: GoogleFonts.fredoka(fontSize: 16)),
              ),
              OutlinedButton(
                onPressed: p.exitToSetup,
                child: Text('Trocar jogadores', style: GoogleFonts.fredoka(fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Rodar e ver passar**

Run: `flutter test test/games/lig4 && flutter analyze lib/games/lig4 test/games/lig4`
Esperado: PASS e `No issues found!`.

- [ ] **Step 7: Commit**

```bash
git add lib/games/lig4 test/games/lig4
git commit -m "feat(lig4): add Connect Four provider and screen with falling pieces" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt"
```

---

### Task 9: Menu com os 3 jogos novos

**Files:**
- Modify: `lib/screens/menu_screen.dart`, com os imports, os três métodos `_open*` e os três cards
- Modify: `test/screens/menu_screen_test.dart`

**Interfaces:**
- Consumes:
  - `MemoryScreen` e `MemoryProvider` (Tasks 2 e 3);
  - `TermoScreen` e `TermoProvider` (Tasks 5 e 6);
  - `Lig4Screen` e `Lig4Provider` (Task 8);
  - o `GameShell`, que já existe.

- [ ] **Step 1: Atualizar o teste do menu (falha primeiro)**

Em `test/screens/menu_screen_test.dart`:

1. Na lista do teste `'menu mostra os 5 jogos'`, renomeie o teste para `'menu mostra os 8 jogos'` e acrescente os três títulos:
```dart
      'Jogo da Memória',
      'Termo',
      'Lig 4',
```
2. No mapa `games`, acrescente:
```dart
    'Jogo da Memória': find.text('Sozinho'),
    'Termo': find.text('Ilimitado'),
    'Lig 4': find.text('Contra o computador'),
```

Run: `flutter test test/screens/menu_screen_test.dart`
Esperado: FAIL. Os testes novos não acham os cards 'Jogo da Memória', 'Termo' e 'Lig 4'.

- [ ] **Step 2: Acrescentar os cards e as aberturas**

Em `lib/screens/menu_screen.dart`, adicione aos imports:
```dart
import '../games/memoria/screens/game_screen.dart';
import '../games/memoria/providers/game_provider.dart';
import '../games/termo/screens/game_screen.dart';
import '../games/termo/providers/game_provider.dart';
import '../games/lig4/screens/game_screen.dart';
import '../games/lig4/providers/game_provider.dart';
```

Logo depois de `_openForca`, adicione:
```dart
  void _openMemoria(BuildContext context) {
    _openGame(
      context,
      GameShell(
        wrapProvider: (child) =>
            ChangeNotifierProvider(create: (_) => MemoryProvider(), child: child),
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF8B5CF6),
          useMaterial3: true,
          textTheme: GoogleFonts.fredokaTextTheme(),
        ),
        home: (_) => const MemoryScreen(),
      ),
    );
  }

  void _openTermo(BuildContext context) {
    _openGame(
      context,
      GameShell(
        wrapProvider: (child) =>
            ChangeNotifierProvider(create: (_) => TermoProvider(), child: child),
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF14B8A6),
          useMaterial3: true,
          textTheme: GoogleFonts.fredokaTextTheme(),
        ),
        home: (_) => const TermoScreen(),
      ),
    );
  }

  void _openLig4(BuildContext context) {
    _openGame(
      context,
      GameShell(
        wrapProvider: (child) =>
            ChangeNotifierProvider(create: (_) => Lig4Provider(), child: child),
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFFEF4444),
          useMaterial3: true,
          textTheme: GoogleFonts.fredokaTextTheme(),
        ),
        home: (_) => const Lig4Screen(),
      ),
    );
  }
```

No `build`, entre o card do Jogo da Forca (`onTap: () => _openForca(context),` seguido de `),`) e o `const SizedBox(height: 32),` que vem antes de `_buildFooter()`, insira:
```dart
              const SizedBox(height: 16),
              _buildGameCard(
                emoji: '🧠',
                title: 'Jogo da Memória',
                description: 'Vire as cartas e encontre os pares!',
                tags: const ['1 ou 2 jogadores', 'Níveis'],
                gradientColors: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                shadowColor: const Color(0xFF8B5CF6),
                onTap: () => _openMemoria(context),
              ),
              const SizedBox(height: 16),
              _buildGameCard(
                emoji: '🟩',
                title: 'Termo',
                description: 'Descubra a palavra em 6 tentativas',
                tags: const ['Palavra do dia', 'Português'],
                gradientColors: const [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
                shadowColor: const Color(0xFF14B8A6),
                onTap: () => _openTermo(context),
              ),
              const SizedBox(height: 16),
              _buildGameCard(
                emoji: '🔴',
                title: 'Lig 4',
                description: 'Alinhe 4 peças antes do adversário!',
                tags: const ['Contra o computador', '2 jogadores'],
                gradientColors: const [Color(0xFFEF4444), Color(0xFFF87171)],
                shadowColor: const Color(0xFFEF4444),
                onTap: () => _openLig4(context),
              ),
```

- [ ] **Step 3: Rodar a suíte inteira**

Run: `flutter test && flutter analyze`
Esperado: PASS em todos os testes (os 3 jogos novos abrem e voltam pela seta e pelo "voltar" do sistema) e `No issues found!`.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/menu_screen.dart test/screens/menu_screen_test.dart
git commit -m "feat: add Memória, Termo and Lig 4 to the main menu" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt"
```

---

### Task 10: Verificação manual no Chrome

**Files:** nenhum arquivo de código. Correções que a verificação revelar entram com um teste primeiro.

- [ ] **Step 1: Suíte completa**

Run: `flutter analyze && flutter test`
Esperado: `No issues found!` e todos os testes passando.

- [ ] **Step 2: Subir o app e o Chrome headless**

```bash
flutter run -d web-server --web-port 8080 --web-hostname localhost   # em background
google-chrome --headless=new --remote-debugging-port=9222 \
  --user-data-dir=<scratchpad>/chrome-profile --window-size=412,915 about:blank   # em background
```

Use o script `cdp.mjs` do scratchpad, o mesmo da verificação anterior: `open`, `shot`, `click x y`, `drag`, `key`, `type`.

- [ ] **Step 3: Passar pelos 3 jogos e tirar capturas de tela**

1. **Menu:** os 8 cards aparecem; rolar até o fim.
2. **Memória:**
   - Sozinho: virar cartas, achar um par e errar um par (as cartas desviram).
   - Voltar e entrar em Dois jogadores: aparecem o placar e a escolha de tamanho.
3. **Termo:**
   - Palavra do dia: digitar uma tentativa válida e ver as cores; digitar "XXXXX" e ver "Palavra inválida".
   - Ilimitado: jogar uma partida até o fim.
   - Voltar ao menu, abrir o Termo de novo e confirmar que a palavra do dia manteve as tentativas.
4. **Lig 4:**
   - Contra o computador no Médio: jogar 3 ou 4 peças e ver o computador responder.
   - Dois jogadores: vencer na vertical e ver o painel de resultado.

Em cada jogo, volte ao menu pela seta. Qualquer problema vira um teste que o reproduz, a correção e um commit `fix(<jogo>): ...`.

- [ ] **Step 4: Desligar o servidor e o Chrome**

Pare o `flutter run` e o Chrome. Para não matar o próprio shell, use `ps -eo pid,args | awk '/[c]hrome-profile/ {print $1}' | xargs -r kill`.
