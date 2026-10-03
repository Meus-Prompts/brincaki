# Brincaki App Completo — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transformar o repositório num app Flutter executável com os 5 jogos do menu (Caça-Palavras, Sudoku, 2048, Jogo da Velha, Jogo da Forca) e gerar um APK.

**Architecture:**
- Cada jogo é um módulo em `lib/games/<jogo>/` com `models/`, `providers/` (um `ChangeNotifier` com toda a lógica), `screens/` e `widgets/`. Funções puras ficam em `logic/` ou `services/`.
- O menu abre cada jogo por meio de um `GameShell`: provider + tema + `Navigator` aninhado, com um `NavigatorPopHandler` para o "voltar" do sistema.
- Só o recorde do 2048 é salvo (`shared_preferences`).

**Tech Stack:** Flutter 3.44 / Dart 3.12, `provider`, `google_fonts` (Fredoka), `shared_preferences`, `flutter_lints`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-10-03-brincaki-app-completo-design.md`

## Global Constraints

- Todo texto de interface em português do Brasil. Palavras dos jogos em MAIÚSCULAS, sem acento, só A–Z.
- Fonte Fredoka (`GoogleFonts.fredoka(...)`) em todo texto novo de interface.
- Todo arquivo `.dart` novo começa com o comentário do próprio caminho, por exemplo `// lib/games/2048/logic/board_logic.dart`. Os arquivos copiados do Sudoku ficam como estão.
- Sem provider global no `main.dart`. Cada jogo cria o seu.
- Única persistência: o recorde do 2048, na chave `game2048_best`.
- Projeto: `--org com.brincaki`, `--project-name brincaki`, nome exibido **Brincaki**.
- Setas "voltar" da primeira tela de cada jogo: `Navigator.of(context, rootNavigator: true).pop()`, com `tooltip: 'Voltar ao menu'` e `Icons.arrow_back`.
- Commits no estilo do histórico (`feat(<jogo>): ...`, em inglês). Toda mensagem de commit termina com:
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt
  ```
- Ambiente desta máquina (`flutter doctor`): só a plataforma **web/Chrome** funciona. Não há SDK do Android nem toolchain Linux. Por isso a verificação manual da Task 10 roda no Chrome, e o APK depende de instalar o SDK do Android (Task 10, Step 4).

**Desvios conscientes da spec:**
- O 2048 desliza por "linhas" extraídas em cada direção em vez de girar o tabuleiro. O resultado é idêntico e o código é mais simples.
- O gerador do Caça-Palavras testa todas as posições e direções, em ordem embaralhada, em vez de fazer 100 tentativas aleatórias. Assim ele nunca deixa de achar um lugar que existe.
- A verificação manual roda no Chrome em vez do Linux.

## Review Focus

1. **Arrasto na grade do Caça-Palavras:**
   - um arrasto vertical tem que selecionar letras, e não rolar a tela;
   - a seleção começa na célula onde o dedo encostou, e não deslocada pelo "slop" do gesto.
   - A tela não usa `ScrollView`, e o `GestureDetector` usa `DragStartBehavior.down`. Teste de widget na Task 8.
2. **2048, vitória com o tabuleiro travado:** se o 2048 surge e não sobra nenhuma jogada, "Continuar" deve levar ao fim de jogo, e não a um tabuleiro parado. Teste na Task 4.
3. **2048, recorde carregado com atraso:** se o recorde salvo chega depois de o jogador já ter feito mais pontos, ele não pode sobrescrever o valor maior. Teste na Task 4.
4. **"Voltar" do sistema dentro de uma partida de Sudoku:** pede confirmação, volta à escolha de dificuldade e só no próximo "voltar" sai para o menu. Teste de widget na Task 9.
5. **Gerador do Caça-Palavras:**
   - nunca falha, em qualquer seed e em qualquer nível;
   - duas palavras nunca compartilham mais de uma célula;
   - os dados dos níveis são válidos: A–Z, sem repetição, cabem na grade e há palavras de reserva.
   - Testes na Task 6.

---

### Task 1: Projeto Flutter e `main.dart`

**Files:**
- Create (via `flutter create`): `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, `.metadata`, `README.md`, `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`
- Create: `lib/main.dart` (substitui o contador gerado)
- Create: `test/flutter_test_config.dart`
- Delete: `test/widget_test.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`, `web/index.html`, `web/manifest.json`, `linux/runner/my_application.cc`, `windows/runner/main.cpp`

**Interfaces:**
- Produces:
  - `class BrincakiApp extends StatelessWidget` em `package:brincaki/main.dart`, usado pelo teste do menu na Task 9;
  - `test/flutter_test_config.dart`, que desliga o download de fontes em todos os testes.

- [ ] **Step 1: Gerar o projeto**

```bash
cd /home/filipecrespodev/Workspace/My/brincaki
flutter create --org com.brincaki --project-name brincaki --description "Jogos para a família brincar" .
rm test/widget_test.dart
flutter pub add provider google_fonts shared_preferences
```

Esperado: o `flutter create` lista os arquivos criados e não toca nos `.dart` existentes, exceto pela criação de `lib/main.dart`, que ainda não existia. O `pubspec.yaml` passa a ter `provider`, `google_fonts` e `shared_preferences` em `dependencies`, e `flutter_lints` em `dev_dependencies`.

- [ ] **Step 2: Escrever `lib/main.dart`**

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/menu_screen.dart';

void main() {
  runApp(const BrincakiApp());
}

class BrincakiApp extends StatelessWidget {
  const BrincakiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brincaki',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFF59E0B),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFBEB),
        textTheme: GoogleFonts.fredokaTextTheme(),
      ),
      home: const MenuScreen(),
    );
  }
}
```

- [ ] **Step 3: Configuração global dos testes**

`google_fonts` tenta baixar a fonte da internet. Com `allowRuntimeFetching = false`, ele apenas imprime um aviso e usa a fonte padrão, sem falhar o teste.

```dart
// test/flutter_test_config.dart

import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
```

- [ ] **Step 4: Nome exibido "Brincaki"**

```bash
sed -i 's/android:label="brincaki"/android:label="Brincaki"/' android/app/src/main/AndroidManifest.xml
sed -i 's#<title>brincaki</title>#<title>Brincaki</title>#' web/index.html
sed -i 's/"name": "brincaki"/"name": "Brincaki"/; s/"short_name": "brincaki"/"short_name": "Brincaki"/' web/manifest.json
sed -i 's/"brincaki"/"Brincaki"/g' linux/runner/my_application.cc
sed -i 's/L"brincaki"/L"Brincaki"/' windows/runner/main.cpp
grep -n -A1 "CFBundleDisplayName" ios/Runner/Info.plist
grep -rn "Brincaki" android/app/src/main/AndroidManifest.xml web/index.html web/manifest.json linux/runner/my_application.cc windows/runner/main.cpp
```

Esperado:
- O `grep` final mostra "Brincaki" em cada um dos 5 arquivos.
- O `Info.plist` já deve trazer `<string>Brincaki</string>`, porque o `flutter create` capitaliza o nome. Se trouxer `brincaki`, troque à mão para `Brincaki`.

- [ ] **Step 5: Rodar os testes existentes**

Run: `flutter test test/games`
Esperado: PASS em todos os testes de `tictactoe` e `forca`.

Run: `flutter analyze`
Esperado: erros **apenas** em `lib/screens/menu_screen.dart`, por imports de `games/cacapalavras`, `games/sudoku` e `games/2048`, que ainda não existem. Eles somem até a Task 8. Qualquer outro erro precisa ser corrigido agora.

- [ ] **Step 6: Commit**

```bash
git add -A
git status --short   # conferir que só entraram arquivos do projeto Flutter, lib/main.dart e test/flutter_test_config.dart
git commit -m "chore: scaffold Flutter project and app entry point" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt"
```

---

### Task 2: Sudoku

**Files:**
- Create (cópia): `lib/games/sudoku/{models,providers,screens,services,widgets}/**`, vindos de `../sudoku_game/lib/`
- Modify: `lib/games/sudoku/screens/home_screen.dart`, para adicionar a `AppBar` com a seta para o menu
- Test: `test/games/sudoku/game_provider_test.dart`

**Interfaces:**
- Produces, já usados pelo menu:
  - `GameProvider` em `package:brincaki/games/sudoku/providers/game_provider.dart`;
  - `HomeScreen` em `package:brincaki/games/sudoku/screens/home_screen.dart`.
- API do provider usada nos testes:
  - `startGame(Difficulty)`, `board` (`SudokuBoard?`), `selectCell(int,int)`, `enterNumber(int)`, `useHint()`, `hintsRemaining`, `dispose()`;
  - `SudokuBoard.getCell(r,c)` devolve um `SudokuCell` com `value`, `isFixed`, `isError` e `isEmpty`;
  - `Difficulty.values` tem `minEmpty`, `maxEmpty` e `name`.

- [ ] **Step 1: Copiar o código**

```bash
mkdir -p lib/games/sudoku
cp -r ../sudoku_game/lib/models ../sudoku_game/lib/providers ../sudoku_game/lib/screens ../sudoku_game/lib/services ../sudoku_game/lib/widgets lib/games/sudoku/
grep -rn "package:sudoku_game" lib/games/sudoku || echo "sem imports de pacote"
```

Esperado: `sem imports de pacote`. Todos os imports internos são relativos.

- [ ] **Step 2: Escrever o teste que falha**

```dart
// test/games/sudoku/game_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/sudoku/models/difficulty.dart';
import 'package:brincaki/games/sudoku/providers/game_provider.dart';

void main() {
  group('Sudoku GameProvider', () {
    late GameProvider provider;

    setUp(() {
      provider = GameProvider();
    });

    tearDown(() {
      provider.dispose(); // cancela o cronômetro
    });

    int countEmpty() {
      var empty = 0;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (provider.board!.getCell(r, c).isEmpty) empty++;
        }
      }
      return empty;
    }

    (int, int) firstEmptyCell() {
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (provider.board!.getCell(r, c).isEmpty) return (r, c);
        }
      }
      throw StateError('tabuleiro sem casas vazias');
    }

    for (final difficulty in Difficulty.values) {
      test('startGame(${difficulty.name}) deixa casas vazias dentro da faixa', () {
        provider.startGame(difficulty);
        expect(
          countEmpty(),
          inInclusiveRange(difficulty.minEmpty, difficulty.maxEmpty),
        );
      });
    }

    test('enterNumber marca erro quando o número já está na linha', () {
      provider.startGame(Difficulty.easy);
      final (row, col) = firstEmptyCell();
      // Um número fixo da mesma linha sempre conflita.
      final fixedInRow = List.generate(9, (c) => provider.board!.getCell(row, c))
          .firstWhere((cell) => cell.isFixed)
          .value;

      provider.selectCell(row, col);
      provider.enterNumber(fixedInRow);

      expect(provider.board!.getCell(row, col).value, fixedInRow);
      expect(provider.board!.getCell(row, col).isError, isTrue);
    });

    test('useHint preenche a casa com a solução e consome uma dica', () {
      provider.startGame(Difficulty.easy);
      final (row, col) = firstEmptyCell();

      provider.selectCell(row, col);
      provider.useHint();

      expect(provider.hintsRemaining, 2);
      expect(provider.board!.getCell(row, col).value,
          provider.board!.getHint(row, col));
      expect(provider.board!.getCell(row, col).isError, isFalse);
    });

    test('dicas acabam depois de 3 usos', () {
      provider.startGame(Difficulty.easy);
      for (var i = 0; i < 4; i++) {
        final (row, col) = firstEmptyCell();
        provider.selectCell(row, col);
        provider.useHint();
      }
      expect(provider.hintsRemaining, 0);
    });
  });
}
```

- [ ] **Step 3: Rodar os testes**

Run: `flutter test test/games/sudoku/game_provider_test.dart`
Esperado: PASS. O código já existe e foi copiado; este teste cobre o comportamento herdado. Se algum falhar, investigue antes de seguir, porque significa que a cópia ou o entendimento da API está errado.

- [ ] **Step 4: Seta para voltar ao menu na `HomeScreen`**

Em `lib/games/sudoku/screens/home_screen.dart`, no `Scaffold` do `build`, adicionar a `appBar` antes de `body:`:

```dart
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar ao menu',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ),
      body: SafeArea(
```

Run: `flutter test test/games/sudoku` → PASS.
Run: `flutter analyze lib/games/sudoku` → `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/games/sudoku test/games/sudoku
git commit -m "feat(sudoku): import Sudoku game with back-to-menu button and tests" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt"
```

---

### Task 3: 2048, lógica pura do tabuleiro

**Files:**
- Create: `lib/games/2048/logic/board_logic.dart`
- Test: `test/games/2048/board_logic_test.dart`

**Interfaces:**
- Produces:
  - `enum Direction { up, down, left, right }`
  - `class SlideResult { final List<List<int>> board; final int points; final bool moved; final Set<(int, int)> merged; }`
  - `SlideResult slide(List<List<int>> board, Direction direction)`, que não modifica o `board` recebido
  - `bool canMove(List<List<int>> board)`
  - `Direction? directionFromVelocity(Offset velocity)`, que devolve `null` abaixo de 100 px/s

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/games/2048/board_logic_test.dart

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/2048/logic/board_logic.dart';

void main() {
  group('slide', () {
    test('esquerda junta pares uma vez só: [2,2,2,2] → [4,4,0,0]', () {
      final r = slide([
        [2, 2, 2, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], Direction.left);
      expect(r.board[0], [4, 4, 0, 0]);
      expect(r.points, 8);
      expect(r.moved, isTrue);
      expect(r.merged, {(0, 0), (0, 1)});
    });

    test('esquerda: [2,2,4,0] → [4,4,0,0] (o 4 novo não junta de novo)', () {
      final r = slide([
        [2, 2, 4, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], Direction.left);
      expect(r.board[0], [4, 4, 0, 0]);
      expect(r.points, 4);
    });

    test('direita: [2,0,2,4] → [0,0,4,4]', () {
      final r = slide([
        [2, 0, 2, 4],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], Direction.right);
      expect(r.board[0], [0, 0, 4, 4]);
      expect(r.merged, {(0, 2)});
    });

    test('cima e baixo trabalham nas colunas', () {
      final board = [
        [2, 0, 0, 0],
        [2, 0, 0, 0],
        [4, 0, 0, 0],
        [0, 0, 0, 8],
      ];
      final up = slide(board, Direction.up);
      expect([for (final row in up.board) row[0]], [4, 4, 0, 0]);
      expect(up.board[0][3], 8);

      final down = slide(board, Direction.down);
      expect([for (final row in down.board) row[0]], [0, 0, 4, 4]);
      expect(down.board[3][3], 8);
      expect(down.merged, {(2, 0)});
    });

    test('jogada que não muda nada devolve moved == false e não mexe no original', () {
      final board = [
        [2, 4, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ];
      final r = slide(board, Direction.left);
      expect(r.moved, isFalse);
      expect(r.points, 0);
      expect(board[0], [2, 4, 0, 0]);
    });

    test('não modifica o tabuleiro recebido', () {
      final board = [
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ];
      slide(board, Direction.left);
      expect(board[0], [2, 2, 0, 0]);
    });
  });

  group('canMove', () {
    test('verdadeiro com casa vazia', () {
      expect(
        canMove([
          [2, 4, 2, 4],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [4, 2, 4, 0],
        ]),
        isTrue,
      );
    });

    test('verdadeiro com vizinhas iguais na vertical', () {
      expect(
        canMove([
          [2, 4, 2, 4],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [2, 8, 16, 32],
        ]),
        isTrue,
      );
    });

    test('falso com tabuleiro cheio sem vizinhas iguais', () {
      expect(
        canMove([
          [2, 4, 2, 4],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [4, 2, 4, 2],
        ]),
        isFalse,
      );
    });
  });

  group('directionFromVelocity', () {
    test('eixo dominante define a direção', () {
      expect(directionFromVelocity(const Offset(500, 100)), Direction.right);
      expect(directionFromVelocity(const Offset(-500, 100)), Direction.left);
      expect(directionFromVelocity(const Offset(100, 500)), Direction.down);
      expect(directionFromVelocity(const Offset(100, -500)), Direction.up);
    });

    test('ignora gestos lentos', () {
      expect(directionFromVelocity(const Offset(50, 40)), isNull);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e ver falhar**

Run: `flutter test test/games/2048/board_logic_test.dart`
Esperado: FAIL na compilação, com "Target of URI doesn't exist: 'package:brincaki/games/2048/logic/board_logic.dart'".

- [ ] **Step 3: Implementar**

```dart
// lib/games/2048/logic/board_logic.dart

import 'dart:ui';

enum Direction { up, down, left, right }

class SlideResult {
  const SlideResult({
    required this.board,
    required this.points,
    required this.moved,
    required this.merged,
  });

  final List<List<int>> board;
  final int points;
  final bool moved;

  /// Células (linha, coluna) que receberam uma peça juntada nesta jogada.
  final Set<(int, int)> merged;
}

/// Células de uma linha do tabuleiro, da borda para onde as peças vão
/// até a borda oposta.
List<(int, int)> _line(int index, Direction direction, int size) {
  return switch (direction) {
    Direction.left => [for (var c = 0; c < size; c++) (index, c)],
    Direction.right => [for (var c = size - 1; c >= 0; c--) (index, c)],
    Direction.up => [for (var r = 0; r < size; r++) (r, index)],
    Direction.down => [for (var r = size - 1; r >= 0; r--) (r, index)],
  };
}

SlideResult slide(List<List<int>> board, Direction direction) {
  final size = board.length;
  final result = board.map((row) => List<int>.from(row)).toList();
  final merged = <(int, int)>{};
  var points = 0;
  var moved = false;

  for (var i = 0; i < size; i++) {
    final cells = _line(i, direction, size);
    final tiles = [
      for (final (r, c) in cells)
        if (board[r][c] != 0) board[r][c],
    ];

    final packed = <int>[];
    final mergedAt = <int>[];
    for (var k = 0; k < tiles.length; k++) {
      if (k + 1 < tiles.length && tiles[k] == tiles[k + 1]) {
        final value = tiles[k] * 2;
        mergedAt.add(packed.length);
        packed.add(value);
        points += value;
        k++;
      } else {
        packed.add(tiles[k]);
      }
    }

    for (var k = 0; k < size; k++) {
      final (r, c) = cells[k];
      final value = k < packed.length ? packed[k] : 0;
      if (result[r][c] != value) moved = true;
      result[r][c] = value;
    }
    for (final k in mergedAt) {
      merged.add(cells[k]);
    }
  }

  return SlideResult(board: result, points: points, moved: moved, merged: merged);
}

bool canMove(List<List<int>> board) {
  final size = board.length;
  for (var r = 0; r < size; r++) {
    for (var c = 0; c < size; c++) {
      final value = board[r][c];
      if (value == 0) return true;
      if (c + 1 < size && board[r][c + 1] == value) return true;
      if (r + 1 < size && board[r + 1][c] == value) return true;
    }
  }
  return false;
}

/// Converte a velocidade de um swipe numa direção, ou `null` se for lento demais.
Direction? directionFromVelocity(Offset velocity) {
  if (velocity.distance < 100) return null;
  if (velocity.dx.abs() > velocity.dy.abs()) {
    return velocity.dx > 0 ? Direction.right : Direction.left;
  }
  return velocity.dy > 0 ? Direction.down : Direction.up;
}
```

- [ ] **Step 4: Rodar o teste e ver passar**

Run: `flutter test test/games/2048/board_logic_test.dart`
Esperado: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/games/2048/logic test/games/2048/board_logic_test.dart
git commit -m "feat(2048): add pure board slide and move-detection logic" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt"
```

---

### Task 4: 2048, recorde e provider

**Files:**
- Create: `lib/games/2048/models/game_state.dart`
- Create: `lib/games/2048/data/high_score_store.dart`
- Create: `lib/games/2048/providers/game_provider.dart`
- Test: `test/games/2048/game_provider_test.dart`

**Interfaces:**
- Consumes (Task 3): `Direction`, `slide`, `canMove`, `SlideResult.merged`.
- Produces:
  - `enum Game2048Phase { playing, won, lost }`
  - `abstract class HighScoreStore { Future<int> load(); Future<void> save(int value); }` e `class SharedPrefsHighScoreStore implements HighScoreStore`
  - `class Game2048Provider extends ChangeNotifier`:
    - construtor `Game2048Provider({HighScoreStore? store, Random? random})`;
    - getters `List<List<int>> board`, `int score`, `int best`, `Game2048Phase phase`, `int moveCount`, `(int, int)? newTile`, `Set<(int, int)> mergedTiles`;
    - métodos `move(Direction)`, `continuePlaying()`, `newGame()`, `@visibleForTesting debugSetBoard(List<List<int>>)`.

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/games/2048/game_provider_test.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/2048/data/high_score_store.dart';
import 'package:brincaki/games/2048/logic/board_logic.dart';
import 'package:brincaki/games/2048/models/game_state.dart';
import 'package:brincaki/games/2048/providers/game_provider.dart';

class MemoryHighScoreStore implements HighScoreStore {
  MemoryHighScoreStore([this.value = 0]);
  int value;
  Completer<int>? pendingLoad;

  @override
  Future<int> load() => pendingLoad?.future ?? Future.value(value);

  @override
  Future<void> save(int v) async => value = v;
}

int countTiles(List<List<int>> board) =>
    board.expand((row) => row).where((v) => v != 0).length;

void main() {
  group('Game2048Provider', () {
    late MemoryHighScoreStore store;
    late Game2048Provider provider;

    setUp(() {
      store = MemoryHighScoreStore();
      provider = Game2048Provider(store: store, random: Random(42));
    });

    test('começa com 2 peças, 0 pontos e fase playing', () {
      expect(countTiles(provider.board), 2);
      expect(provider.score, 0);
      expect(provider.phase, Game2048Phase.playing);
    });

    test('jogada que não muda nada não cria peça nova', () {
      provider.debugSetBoard([
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      provider.move(Direction.left);
      expect(countTiles(provider.board), 1);
      expect(provider.moveCount, 0);
    });

    test('jogada válida soma pontos e cria uma peça 2 ou 4', () {
      provider.debugSetBoard([
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      provider.move(Direction.left);
      expect(provider.score, 4);
      expect(provider.board[0][0], 4);
      expect(countTiles(provider.board), 2);
      final (r, c) = provider.newTile!;
      expect(provider.board[r][c], anyOf(2, 4));
      expect(provider.mergedTiles, {(0, 0)});
      expect(provider.moveCount, 1);
    });

    test('formar 2048 vence uma vez só; continuePlaying volta a jogar', () {
      provider.debugSetBoard([
        [1024, 1024, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      provider.move(Direction.left);
      expect(provider.phase, Game2048Phase.won);

      final before = provider.board;
      provider.move(Direction.right); // ignorado enquanto o overlay aparece
      expect(provider.board, before);

      provider.continuePlaying();
      expect(provider.phase, Game2048Phase.playing);

      provider.debugSetBoard([
        [1024, 1024, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      provider.move(Direction.left);
      expect(provider.phase, Game2048Phase.playing);
    });

    test('tabuleiro travado depois da jogada dá derrota', () {
      provider.debugSetBoard([
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [32, 4, 2, 4],
        [8, 16, 8, 0],
      ]);
      provider.move(Direction.right);
      expect(provider.phase, Game2048Phase.lost);
    });

    test('vitória com tabuleiro travado: Continuar leva ao fim de jogo', () {
      provider.debugSetBoard([
        [1024, 1024, 8, 16],
        [8, 16, 32, 64],
        [16, 32, 64, 128],
        [32, 64, 128, 256],
      ]);
      provider.move(Direction.left);
      expect(provider.phase, Game2048Phase.won);
      provider.continuePlaying();
      expect(provider.phase, Game2048Phase.lost);
    });

    test('carrega o recorde salvo e atualiza quando os pontos passam dele', () async {
      store = MemoryHighScoreStore(100);
      provider = Game2048Provider(store: store, random: Random(1));
      await Future<void>.delayed(Duration.zero);
      expect(provider.best, 100);

      provider.debugSetBoard([
        [64, 64, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      provider.move(Direction.left);
      expect(provider.score, 128);
      expect(provider.best, 128);
      expect(store.value, 128);
    });

    test('recorde que chega atrasado não sobrescreve um valor maior', () async {
      store = MemoryHighScoreStore()..pendingLoad = Completer<int>();
      provider = Game2048Provider(store: store, random: Random(1));
      provider.debugSetBoard([
        [4, 4, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      provider.move(Direction.left);
      expect(provider.best, 8);

      store.pendingLoad!.complete(2);
      await Future<void>.delayed(Duration.zero);
      expect(provider.best, 8);
    });

    test('newGame zera pontos e mantém o recorde', () {
      provider.debugSetBoard([
        [4, 4, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      provider.move(Direction.left);
      provider.newGame();
      expect(provider.score, 0);
      expect(provider.best, 8);
      expect(countTiles(provider.board), 2);
      expect(provider.phase, Game2048Phase.playing);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e ver falhar**

Run: `flutter test test/games/2048/game_provider_test.dart`
Esperado: FAIL na compilação, porque os arquivos `high_score_store.dart`, `game_state.dart` e `game_provider.dart` não existem.

- [ ] **Step 3: Implementar o modelo e o store**

```dart
// lib/games/2048/models/game_state.dart

enum Game2048Phase { playing, won, lost }
```

```dart
// lib/games/2048/data/high_score_store.dart

import 'package:shared_preferences/shared_preferences.dart';

abstract class HighScoreStore {
  Future<int> load();
  Future<void> save(int value);
}

class SharedPrefsHighScoreStore implements HighScoreStore {
  static const _key = 'game2048_best';

  @override
  Future<int> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  @override
  Future<void> save(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, value);
  }
}
```

- [ ] **Step 4: Implementar o provider**

```dart
// lib/games/2048/providers/game_provider.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/high_score_store.dart';
import '../logic/board_logic.dart';
import '../models/game_state.dart';

class Game2048Provider extends ChangeNotifier {
  Game2048Provider({HighScoreStore? store, Random? random})
      : _store = store ?? SharedPrefsHighScoreStore(),
        _random = random ?? Random() {
    _resetBoard();
    _loadBest();
  }

  static const int size = 4;
  static const int target = 2048;

  final HighScoreStore _store;
  final Random _random;
  bool _disposed = false;

  late List<List<int>> _board;
  int _score = 0;
  int _best = 0;
  Game2048Phase _phase = Game2048Phase.playing;
  bool _keepPlaying = false;
  int _moveCount = 0;
  (int, int)? _newTile;
  Set<(int, int)> _mergedTiles = const {};

  List<List<int>> get board => _board;
  int get score => _score;
  int get best => _best;
  Game2048Phase get phase => _phase;
  int get moveCount => _moveCount;
  (int, int)? get newTile => _newTile;
  Set<(int, int)> get mergedTiles => _mergedTiles;

  void move(Direction direction) {
    if (_phase != Game2048Phase.playing) return;
    final result = slide(_board, direction);
    if (!result.moved) return;

    _board = result.board;
    _score += result.points;
    _mergedTiles = result.merged;
    _newTile = _spawnTile();
    _moveCount++;

    if (_score > _best) {
      _best = _score;
      unawaited(_store.save(_best));
    }

    if (!_keepPlaying && _board.any((row) => row.contains(target))) {
      _phase = Game2048Phase.won;
    } else if (!canMove(_board)) {
      _phase = Game2048Phase.lost;
    }
    notifyListeners();
  }

  /// Fecha o aviso de vitória. Se não sobrou jogada, vai direto ao fim de jogo.
  void continuePlaying() {
    if (_phase != Game2048Phase.won) return;
    _keepPlaying = true;
    _phase = canMove(_board) ? Game2048Phase.playing : Game2048Phase.lost;
    notifyListeners();
  }

  void newGame() {
    _resetBoard();
    notifyListeners();
  }

  @visibleForTesting
  void debugSetBoard(List<List<int>> board) {
    _board = board.map((row) => List<int>.from(row)).toList();
    _phase = Game2048Phase.playing;
    notifyListeners();
  }

  void _resetBoard() {
    _board = List.generate(size, (_) => List.filled(size, 0));
    _score = 0;
    _phase = Game2048Phase.playing;
    _keepPlaying = false;
    _moveCount = 0;
    _mergedTiles = const {};
    _spawnTile();
    _newTile = _spawnTile();
  }

  (int, int)? _spawnTile() {
    final empty = [
      for (var r = 0; r < size; r++)
        for (var c = 0; c < size; c++)
          if (_board[r][c] == 0) (r, c),
    ];
    if (empty.isEmpty) return null;
    final (r, c) = empty[_random.nextInt(empty.length)];
    _board[r][c] = _random.nextDouble() < 0.9 ? 2 : 4;
    return (r, c);
  }

  Future<void> _loadBest() async {
    final saved = await _store.load();
    if (_disposed || saved <= _best) return;
    _best = saved;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
```

- [ ] **Step 5: Rodar o teste e ver passar**

Run: `flutter test test/games/2048`
Esperado: PASS em `board_logic_test.dart` e `game_provider_test.dart`.

- [ ] **Step 6: Commit**

```bash
git add lib/games/2048/models lib/games/2048/data lib/games/2048/providers test/games/2048/game_provider_test.dart
git commit -m "feat(2048): add game provider with persisted high score" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt"
```

---

### Task 5: 2048, tela

**Files:**
- Create: `lib/games/2048/widgets/tile_widget.dart`
- Create: `lib/games/2048/widgets/board_widget.dart`
- Create: `lib/games/2048/widgets/score_box.dart`
- Create: `lib/games/2048/screens/game_screen.dart`
- Test: `test/games/2048/game_screen_test.dart`

**Interfaces:**
- Consumes:
  - da Task 4: `Game2048Provider` (`board`, `score`, `best`, `phase`, `moveCount`, `newTile`, `mergedTiles`, `move`, `continuePlaying`, `newGame`) e `Game2048Phase`;
  - da Task 3: `Direction` e `directionFromVelocity`.
- Produces: `class Game2048Screen extends StatelessWidget` (`const Game2048Screen({super.key})`), que lê o `Game2048Provider` de cima da árvore. O nome já é usado pelo menu.

- [ ] **Step 1: Escrever o teste de widget que falha**

```dart
// test/games/2048/game_screen_test.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/2048/data/high_score_store.dart';
import 'package:brincaki/games/2048/logic/board_logic.dart';
import 'package:brincaki/games/2048/models/game_state.dart';
import 'package:brincaki/games/2048/providers/game_provider.dart';
import 'package:brincaki/games/2048/screens/game_screen.dart';

class _MemoryStore implements HighScoreStore {
  @override
  Future<int> load() async => 0;
  @override
  Future<void> save(int value) async {}
}

void main() {
  late Game2048Provider provider;

  Future<void> pumpScreen(WidgetTester tester) async {
    provider = Game2048Provider(store: _MemoryStore(), random: Random(3));
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: Game2048Screen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra Pontos, Recorde e Novo jogo', (tester) async {
    await pumpScreen(tester);
    expect(find.text('PONTOS'), findsOneWidget);
    expect(find.text('RECORDE'), findsOneWidget);
    expect(find.text('Novo jogo'), findsOneWidget);
  });

  testWidgets('seta do teclado move as peças', (tester) async {
    await pumpScreen(tester);
    provider.debugSetBoard([
      [0, 0, 0, 2],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(provider.board[0][0], 2);
  });

  testWidgets('swipe para a esquerda move as peças', (tester) async {
    await pumpScreen(tester);
    provider.debugSetBoard([
      [0, 0, 0, 2],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    await tester.pump();
    await tester.fling(find.byKey(const Key('board2048')), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(provider.board[0][0], 2);
  });

  testWidgets('overlay de vitória com Continuar', (tester) async {
    await pumpScreen(tester);
    provider.debugSetBoard([
      [1024, 1024, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    provider.move(Direction.left);
    await tester.pumpAndSettle();
    expect(find.text('Você chegou ao 2048!'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(provider.phase, Game2048Phase.playing);
    expect(find.text('Você chegou ao 2048!'), findsNothing);
  });
}
```

- [ ] **Step 2: Rodar o teste e ver falhar**

Run: `flutter test test/games/2048/game_screen_test.dart`
Esperado: FAIL na compilação, porque `game_screen.dart` não existe.

- [ ] **Step 3: Implementar os widgets**

```dart
// lib/games/2048/widgets/tile_widget.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _tileColors = <int, Color>{
  2: Color(0xFFEEE4DA),
  4: Color(0xFFEDE0C8),
  8: Color(0xFFF2B179),
  16: Color(0xFFF59563),
  32: Color(0xFFF67C5F),
  64: Color(0xFFF65E3B),
  128: Color(0xFFEDCF72),
  256: Color(0xFFEDCC61),
  512: Color(0xFFEDC850),
  1024: Color(0xFFEDC53F),
  2048: Color(0xFFEDC22E),
};

Color tileColor(int value) {
  if (value == 0) return const Color(0xFFCDC1B4);
  return _tileColors[value] ?? const Color(0xFF3C3A32);
}

class TileWidget extends StatelessWidget {
  const TileWidget({
    super.key,
    required this.value,
    required this.isNew,
    required this.isMerged,
    required this.moveCount,
  });

  final int value;
  final bool isNew;
  final bool isMerged;

  /// Muda a cada jogada, para reiniciar a animação da peça.
  final int moveCount;

  @override
  Widget build(BuildContext context) {
    final face = _TileFace(value: value);
    if (value == 0 || (!isNew && !isMerged)) return face;

    return TweenAnimationBuilder<double>(
      key: ValueKey('$moveCount-${isNew ? 'new' : 'merged'}'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 150),
      builder: (context, t, child) => Transform.scale(
        scale: isNew ? t : 1 + 0.15 * sin(pi * t),
        child: child,
      ),
      child: face,
    );
  }
}

class _TileFace extends StatelessWidget {
  const _TileFace({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final digits = value.toString().length;
        final fontSize = side * (digits <= 2 ? 0.45 : (digits == 3 ? 0.36 : 0.28));

        return Container(
          decoration: BoxDecoration(
            color: tileColor(value),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: value == 0
              ? null
              : Text(
                  '$value',
                  style: GoogleFonts.fredoka(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: value <= 4 ? const Color(0xFF776E65) : Colors.white,
                  ),
                ),
        );
      },
    );
  }
}
```

```dart
// lib/games/2048/widgets/board_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/board_logic.dart';
import '../providers/game_provider.dart';
import 'tile_widget.dart';

class BoardWidget extends StatelessWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<Game2048Provider>();

    return GestureDetector(
      key: const Key('board2048'),
      onPanEnd: (details) {
        final direction = directionFromVelocity(details.velocity.pixelsPerSecond);
        if (direction != null) p.move(direction);
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFBBADA0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            for (var r = 0; r < Game2048Provider.size; r++)
              Expanded(
                child: Row(
                  children: [
                    for (var c = 0; c < Game2048Provider.size; c++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: TileWidget(
                            value: p.board[r][c],
                            isNew: p.newTile == (r, c),
                            isMerged: p.mergedTiles.contains((r, c)),
                            moveCount: p.moveCount,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

```dart
// lib/games/2048/widgets/score_box.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScoreBox extends StatelessWidget {
  const ScoreBox({super.key, required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFBBADA0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.fredoka(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEEE4DA),
            ),
          ),
          Text(
            '$value',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Implementar a tela**

```dart
// lib/games/2048/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../logic/board_logic.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/board_widget.dart';
import '../widgets/score_box.dart';

const _brown = Color(0xFF776E65);
const _buttonColor = Color(0xFF8F7A66);

class Game2048Screen extends StatelessWidget {
  const Game2048Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => _onKey(context, event),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF8EF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFAF8EF),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _brown),
            tooltip: 'Voltar ao menu',
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
          title: Text(
            '2048',
            style: GoogleFonts.fredoka(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _brown,
            ),
          ),
        ),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _Header(),
                SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [BoardWidget(), _ResultOverlay()],
                      ),
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

  KeyEventResult _onKey(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp => Direction.up,
      LogicalKeyboardKey.arrowDown => Direction.down,
      LogicalKeyboardKey.arrowLeft => Direction.left,
      LogicalKeyboardKey.arrowRight => Direction.right,
      _ => null,
    };
    if (direction == null) return KeyEventResult.ignored;
    context.read<Game2048Provider>().move(direction);
    return KeyEventResult.handled;
  }
}

ButtonStyle _buttonStyle() => ElevatedButton.styleFrom(
      backgroundColor: _buttonColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600),
    );

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<Game2048Provider>();
    return Row(
      children: [
        ScoreBox(label: 'Pontos', value: p.score),
        const SizedBox(width: 8),
        ScoreBox(label: 'Recorde', value: p.best),
        const Spacer(),
        ElevatedButton(
          onPressed: p.newGame,
          style: _buttonStyle(),
          child: const Text('Novo jogo'),
        ),
      ],
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<Game2048Provider>();
    if (p.phase == Game2048Phase.playing) return const SizedBox.shrink();

    final won = p.phase == Game2048Phase.won;

    return Container(
      decoration: BoxDecoration(
        color: (won ? const Color(0xFFEDC22E) : const Color(0xFFEEE4DA))
            .withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            won ? 'Você chegou ao 2048!' : 'Fim de jogo',
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: won ? Colors.white : _brown,
            ),
          ),
          if (!won) ...[
            const SizedBox(height: 4),
            Text(
              '${p.score} pontos',
              style: GoogleFonts.fredoka(fontSize: 18, color: _brown),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (won)
                ElevatedButton(
                  onPressed: p.continuePlaying,
                  style: _buttonStyle(),
                  child: const Text('Continuar'),
                ),
              ElevatedButton(
                onPressed: p.newGame,
                style: _buttonStyle(),
                child: Text(won ? 'Novo jogo' : 'Jogar de novo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

Quando o overlay de vitória aparece, existem dois botões "Novo jogo": um no cabeçalho e outro no overlay. Os testes usam apenas "Continuar", então isso não causa ambiguidade.

- [ ] **Step 5: Rodar os testes e ver passar**

Run: `flutter test test/games/2048`
Esperado: PASS nos três arquivos.

Run: `flutter analyze lib/games/2048 test/games/2048`
Esperado: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/games/2048/widgets lib/games/2048/screens test/games/2048/game_screen_test.dart
git commit -m "feat(2048): add game screen with swipe, keyboard and result overlays" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt"
```

---

### Task 6: Caça-Palavras, níveis e gerador da grade

**Files:**
- Create: `lib/games/cacapalavras/models/game_state.dart`
- Create: `lib/games/cacapalavras/data/levels.dart`
- Create: `lib/games/cacapalavras/services/grid_generator.dart`
- Test: `test/games/cacapalavras/grid_generator_test.dart`

**Interfaces:**
- Produces:
  - `enum WordSearchPhase { playing, won }`
  - `enum Direction` com `right, down, downRight, upRight, left, up, upLeft, downLeft`, cada um com os campos `int dr` e `int dc`
  - `class PlacedWord { final String word; final Direction direction; final List<(int, int)> cells; }`
  - `class LevelConfig { final int size; final int wordCount; final List<Direction> directions; final String theme; final List<String> words; }` e `const List<LevelConfig> kLevels` (10 itens; o nível N é `kLevels[N - 1]`)
  - `class GeneratedGrid { final List<List<String>> letters; final List<PlacedWord> words; }`
  - `GeneratedGrid generateGrid({required List<String> candidates, required int wordCount, required int size, required List<Direction> directions, required Random random})`

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/games/cacapalavras/grid_generator_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/cacapalavras/data/levels.dart';
import 'package:brincaki/games/cacapalavras/services/grid_generator.dart';

final _word = RegExp(r'^[A-Z]+$');
final _letter = RegExp(r'^[A-Z]$');

void main() {
  group('kLevels', () {
    test('tem 10 níveis', () {
      expect(kLevels.length, 10);
    });

    for (var i = 0; i < 10; i++) {
      test('nível ${i + 1}: palavras válidas e reserva suficiente', () {
        final level = kLevels[i];
        expect(level.words.length, greaterThanOrEqualTo(level.wordCount + 5));
        expect(level.words.toSet().length, level.words.length,
            reason: 'palavra repetida no tema ${level.theme}');
        for (final w in level.words) {
          expect(w, matches(_word), reason: w);
          expect(w.length, inInclusiveRange(3, level.size), reason: w);
        }
      });
    }
  });

  group('generateGrid', () {
    for (var i = 0; i < 10; i++) {
      test('nível ${i + 1}: 20 grades válidas', () {
        final level = kLevels[i];
        for (var seed = 0; seed < 20; seed++) {
          final g = generateGrid(
            candidates: level.words,
            wordCount: level.wordCount,
            size: level.size,
            directions: level.directions,
            random: Random(seed),
          );

          expect(g.letters.length, level.size);
          for (final row in g.letters) {
            expect(row.length, level.size);
            for (final l in row) {
              expect(l, matches(_letter));
            }
          }

          expect(g.words.length, level.wordCount);
          expect(g.words.map((w) => w.word).toSet().length, level.wordCount);

          for (final w in g.words) {
            expect(level.words, contains(w.word));
            expect(level.directions, contains(w.direction));
            expect(w.cells.length, w.word.length);
            expect(w.cells.map((c) => g.letters[c.$1][c.$2]).join(), w.word);
            for (var k = 1; k < w.cells.length; k++) {
              expect(w.cells[k].$1 - w.cells[k - 1].$1, w.direction.dr);
              expect(w.cells[k].$2 - w.cells[k - 1].$2, w.direction.dc);
            }
          }

          for (var a = 0; a < g.words.length; a++) {
            for (var b = a + 1; b < g.words.length; b++) {
              final shared = g.words[a].cells
                  .toSet()
                  .intersection(g.words[b].cells.toSet());
              expect(shared.length, lessThanOrEqualTo(1),
                  reason: '${g.words[a].word} x ${g.words[b].word}');
            }
          }
        }
      });
    }
  });
}
```

- [ ] **Step 2: Rodar o teste e ver falhar**

Run: `flutter test test/games/cacapalavras/grid_generator_test.dart`
Esperado: FAIL na compilação, porque `levels.dart` e `grid_generator.dart` não existem.

- [ ] **Step 3: Implementar os modelos**

```dart
// lib/games/cacapalavras/models/game_state.dart

enum WordSearchPhase { playing, won }

enum Direction {
  right(0, 1),
  down(1, 0),
  downRight(1, 1),
  upRight(-1, 1),
  left(0, -1),
  up(-1, 0),
  upLeft(-1, -1),
  downLeft(1, -1);

  const Direction(this.dr, this.dc);

  final int dr;
  final int dc;
}

class PlacedWord {
  const PlacedWord({
    required this.word,
    required this.direction,
    required this.cells,
  });

  final String word;
  final Direction direction;

  /// Células (linha, coluna) da primeira à última letra.
  final List<(int, int)> cells;
}
```

- [ ] **Step 4: Implementar os níveis**

```dart
// lib/games/cacapalavras/data/levels.dart

import '../models/game_state.dart';

class LevelConfig {
  const LevelConfig({
    required this.size,
    required this.wordCount,
    required this.directions,
    required this.theme,
    required this.words,
  });

  final int size;
  final int wordCount;
  final List<Direction> directions;
  final String theme;
  final List<String> words;
}

const _straight = [Direction.right, Direction.down];
const _oneDiagonal = [..._straight, Direction.downRight];
const _twoDiagonals = [..._oneDiagonal, Direction.upRight];
const _withBackwards = [..._twoDiagonals, Direction.left, Direction.up];
const _all = Direction.values;

/// Nível N = kLevels[N - 1]. Palavras em maiúsculas, sem acento.
const List<LevelConfig> kLevels = [
  LevelConfig(
    size: 6,
    wordCount: 4,
    directions: _straight,
    theme: 'Animais',
    words: [
      'GATO', 'CAO', 'PATO', 'SAPO', 'VACA', 'BOI', 'URSO', 'LEAO',
      'LOBO', 'RATO', 'PEIXE', 'FOCA', 'ONCA', 'COBRA', 'ZEBRA', 'TATU',
      'MACACO', 'CAVALO', 'COELHO', 'GALO',
    ],
  ),
  LevelConfig(
    size: 7,
    wordCount: 5,
    directions: _straight,
    theme: 'Frutas',
    words: [
      'UVA', 'PERA', 'MACA', 'KIWI', 'FIGO', 'CAQUI', 'MANGA', 'LIMAO',
      'BANANA', 'MELAO', 'AMORA', 'GOIABA', 'CEREJA', 'CAJU', 'COCO',
      'LARANJA', 'AMEIXA', 'ACAI', 'PITAYA', 'MAMAO',
    ],
  ),
  LevelConfig(
    size: 8,
    wordCount: 5,
    directions: _straight,
    theme: 'Cores',
    words: [
      'AZUL', 'VERDE', 'ROXO', 'ROSA', 'PRETO', 'BRANCO', 'CINZA', 'LILAS',
      'BEGE', 'MARROM', 'DOURADO', 'PRATA', 'LARANJA', 'AMARELO', 'VINHO',
      'CREME', 'ANIL', 'CORAL', 'SALMAO', 'VIOLETA', 'VERMELHO',
    ],
  ),
  LevelConfig(
    size: 8,
    wordCount: 6,
    directions: _oneDiagonal,
    theme: 'Corpo humano',
    words: [
      'CABECA', 'OLHO', 'NARIZ', 'BOCA', 'DENTE', 'LINGUA', 'ORELHA',
      'PESCOCO', 'OMBRO', 'BRACO', 'COTOVELO', 'MAO', 'DEDO', 'UNHA',
      'PERNA', 'JOELHO', 'BARRIGA', 'COSTAS', 'PEITO', 'CORACAO', 'PULMAO',
      'CABELO',
    ],
  ),
  LevelConfig(
    size: 9,
    wordCount: 7,
    directions: _twoDiagonals,
    theme: 'Casa',
    words: [
      'SALA', 'QUARTO', 'COZINHA', 'BANHEIRO', 'JANELA', 'PORTA', 'TELHADO',
      'ESCADA', 'PAREDE', 'SOFA', 'CAMA', 'MESA', 'CADEIRA', 'ARMARIO',
      'TAPETE', 'ESPELHO', 'GELADEIRA', 'FOGAO', 'CORTINA', 'VARANDA',
      'QUINTAL', 'GARAGEM',
    ],
  ),
  LevelConfig(
    size: 10,
    wordCount: 8,
    directions: _twoDiagonals,
    theme: 'Profissões',
    words: [
      'MEDICO', 'PROFESSOR', 'BOMBEIRO', 'POLICIAL', 'PADEIRO', 'PEDREIRO',
      'PILOTO', 'DENTISTA', 'CARTEIRO', 'MOTORISTA', 'ADVOGADO',
      'COZINHEIRO', 'ENFERMEIRO', 'PINTOR', 'ATOR', 'JUIZ', 'AGRICULTOR',
      'ENGENHEIRO', 'CANTOR', 'ARQUITETO', 'FOTOGRAFO',
    ],
  ),
  LevelConfig(
    size: 10,
    wordCount: 8,
    directions: _withBackwards,
    theme: 'Natureza',
    words: [
      'ARVORE', 'FLOR', 'FOLHA', 'RIO', 'MAR', 'LAGO', 'MONTANHA',
      'FLORESTA', 'CACHOEIRA', 'PEDRA', 'AREIA', 'NUVEM', 'CHUVA', 'VENTO',
      'SOL', 'LUA', 'ESTRELA', 'PRAIA', 'ILHA', 'VULCAO', 'SEMENTE', 'RAIZ',
    ],
  ),
  LevelConfig(
    size: 11,
    wordCount: 9,
    directions: _all,
    theme: 'Esportes',
    words: [
      'FUTEBOL', 'VOLEI', 'BASQUETE', 'TENIS', 'NATACAO', 'CORRIDA', 'JUDO',
      'KARATE', 'BOXE', 'SURFE', 'SKATE', 'CICLISMO', 'XADREZ', 'HANDEBOL',
      'GINASTICA', 'ATLETISMO', 'ESGRIMA', 'REMO', 'GOLFE', 'RUGBY',
      'BEISEBOL', 'CANOAGEM',
    ],
  ),
  LevelConfig(
    size: 12,
    wordCount: 10,
    directions: _all,
    theme: 'Países',
    words: [
      'BRASIL', 'PORTUGAL', 'ARGENTINA', 'CHILE', 'PERU', 'URUGUAI',
      'PARAGUAI', 'MEXICO', 'CANADA', 'ESPANHA', 'FRANCA', 'ITALIA',
      'ALEMANHA', 'JAPAO', 'CHINA', 'INDIA', 'EGITO', 'ANGOLA', 'MOCAMBIQUE',
      'AUSTRALIA', 'RUSSIA', 'GRECIA', 'MARROCOS',
    ],
  ),
  LevelConfig(
    size: 12,
    wordCount: 12,
    directions: _all,
    theme: 'Ciência',
    words: [
      'ATOMO', 'MOLECULA', 'CELULA', 'ENERGIA', 'GRAVIDADE', 'PLANETA',
      'GALAXIA', 'FOTOSSINTESE', 'MICROSCOPIO', 'TELESCOPIO', 'EVOLUCAO',
      'GENETICA', 'OXIGENIO', 'HIDROGENIO', 'ELETRON', 'PROTON', 'NEUTRON',
      'MAGNETISMO', 'ECLIPSE', 'FOSSIL', 'BACTERIA', 'VACINA', 'LABORATORIO',
    ],
  ),
];
```

O `dart format` vai reorganizar as listas de palavras numa por linha. Isso é esperado; não brigue com o formatador.

- [ ] **Step 5: Implementar o gerador**

```dart
// lib/games/cacapalavras/services/grid_generator.dart

import 'dart:math';

import '../models/game_state.dart';

class GeneratedGrid {
  const GeneratedGrid({required this.letters, required this.words});

  final List<List<String>> letters;
  final List<PlacedWord> words;
}

/// Monta uma grade [size]×[size] com [wordCount] palavras sorteadas de
/// [candidates]. Duas palavras compartilham no máximo uma célula, e só se a
/// letra for a mesma.
GeneratedGrid generateGrid({
  required List<String> candidates,
  required int wordCount,
  required int size,
  required List<Direction> directions,
  required Random random,
}) {
  for (var attempt = 0; attempt < 10; attempt++) {
    final grid = _tryGenerate(candidates, wordCount, size, directions, random);
    if (grid != null) return grid;
  }
  throw StateError('Não foi possível montar a grade com $wordCount palavras');
}

GeneratedGrid? _tryGenerate(
  List<String> candidates,
  int wordCount,
  int size,
  List<Direction> directions,
  Random random,
) {
  final pool = [...candidates]..shuffle(random);
  // Palavras longas primeiro: são as mais difíceis de encaixar.
  final queue = pool.take(wordCount).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  final reserve = pool.skip(wordCount).toList();

  final grid = List.generate(size, (_) => List<String?>.filled(size, null));
  final placed = <PlacedWord>[];

  while (placed.length < wordCount) {
    if (queue.isEmpty) {
      if (reserve.isEmpty) return null;
      queue.add(reserve.removeAt(0));
    }
    final word = queue.removeAt(0);
    final placement = _place(grid, word, directions, random);
    if (placement != null) placed.add(placement);
  }

  final letters = [
    for (final row in grid)
      [for (final l in row) l ?? String.fromCharCode(65 + random.nextInt(26))],
  ];
  return GeneratedGrid(letters: letters, words: placed);
}

PlacedWord? _place(
  List<List<String?>> grid,
  String word,
  List<Direction> directions,
  Random random,
) {
  final size = grid.length;
  final options = [
    for (final d in directions)
      for (var r = 0; r < size; r++)
        for (var c = 0; c < size; c++) (d, r, c),
  ]..shuffle(random);

  for (final (dir, row, col) in options) {
    final endRow = row + dir.dr * (word.length - 1);
    final endCol = col + dir.dc * (word.length - 1);
    if (endRow < 0 || endRow >= size || endCol < 0 || endCol >= size) continue;

    final cells = [
      for (var k = 0; k < word.length; k++) (row + dir.dr * k, col + dir.dc * k),
    ];

    var overlaps = 0;
    var fits = true;
    for (var k = 0; k < word.length; k++) {
      final existing = grid[cells[k].$1][cells[k].$2];
      if (existing == null) continue;
      overlaps++;
      if (existing != word[k] || overlaps > 1) {
        fits = false;
        break;
      }
    }
    if (!fits) continue;

    for (var k = 0; k < word.length; k++) {
      grid[cells[k].$1][cells[k].$2] = word[k];
    }
    return PlacedWord(word: word, direction: dir, cells: cells);
  }
  return null;
}
```

- [ ] **Step 6: Rodar o teste e ver passar**

Run: `flutter test test/games/cacapalavras/grid_generator_test.dart`
Esperado: PASS. Se algum nível lançar `StateError`, o problema está nos dados e não no teste:
- troque palavras longas demais desse nível por outras menores do mesmo tema;
- mantenha ao menos `wordCount + 5` palavras;
- rode de novo.

- [ ] **Step 7: Commit**

```bash
git add lib/games/cacapalavras test/games/cacapalavras
git commit -m "feat(cacapalavras): add 10 themed levels and grid generator" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt"
```

---

### Task 7: Caça-Palavras, seleção e provider

**Files:**
- Create: `lib/games/cacapalavras/services/selection.dart`
- Create: `lib/games/cacapalavras/providers/game_provider.dart`
- Test: `test/games/cacapalavras/selection_test.dart`
- Test: `test/games/cacapalavras/game_provider_test.dart`

**Interfaces:**
- Consumes (Task 6): `kLevels`, `LevelConfig`, `generateGrid`, `PlacedWord`, `WordSearchPhase`.
- Produces:
  - `List<(int, int)> snapLine((int, int) start, (int, int) end, int size)`
  - `class WordSearchProvider extends ChangeNotifier`:
    - construtor `WordSearchProvider({Random? random})`;
    - getters `int level`, `LevelConfig config`, `bool isLastLevel`, `List<List<String>> grid`, `List<PlacedWord> words`, `Set<String> found`, `WordSearchPhase phase`, `List<(int, int)> selectedCells`;
    - métodos `startSelection(int row, int col)`, `updateSelection(int row, int col)`, `endSelection()`, `nextLevel()`.

- [ ] **Step 1: Escrever os testes que falham**

```dart
// test/games/cacapalavras/selection_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/cacapalavras/services/selection.dart';

void main() {
  group('snapLine', () {
    test('mesma célula devolve só ela', () {
      expect(snapLine((2, 2), (2, 2), 6), [(2, 2)]);
    });

    test('horizontal, vertical e para cima', () {
      expect(snapLine((1, 1), (1, 4), 6), [(1, 1), (1, 2), (1, 3), (1, 4)]);
      expect(snapLine((0, 2), (2, 2), 6), [(0, 2), (1, 2), (2, 2)]);
      expect(snapLine((3, 3), (0, 3), 6), [(3, 3), (2, 3), (1, 3), (0, 3)]);
    });

    test('ponto fora da reta gruda na direção mais próxima', () {
      // (2,3) está a ~34° da horizontal → diagonal ↘, comprimento 3.
      expect(snapLine((0, 0), (2, 3), 6), [(0, 0), (1, 1), (2, 2), (3, 3)]);
      // (1,4) está a ~14° → horizontal.
      expect(snapLine((0, 0), (1, 4), 6), [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4)]);
    });

    test('para na borda da grade', () {
      expect(snapLine((4, 4), (1, 7), 6), [(4, 4), (3, 5)]);
    });
  });
}
```

```dart
// test/games/cacapalavras/game_provider_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/games/cacapalavras/models/game_state.dart';
import 'package:brincaki/games/cacapalavras/providers/game_provider.dart';

void select(WordSearchProvider p, (int, int) from, (int, int) to) {
  p.startSelection(from.$1, from.$2);
  p.updateSelection(to.$1, to.$2);
  p.endSelection();
}

void findAll(WordSearchProvider p) {
  for (final w in p.words) {
    select(p, w.cells.first, w.cells.last);
  }
}

void main() {
  group('WordSearchProvider', () {
    late WordSearchProvider provider;

    setUp(() {
      provider = WordSearchProvider(random: Random(7));
    });

    test('começa no nível 1 com grade 6×6 e 4 palavras', () {
      expect(provider.level, 1);
      expect(provider.phase, WordSearchPhase.playing);
      expect(provider.grid.length, 6);
      expect(provider.words.length, 4);
      expect(provider.found, isEmpty);
    });

    test('selecionar da primeira à última letra marca a palavra', () {
      final w = provider.words.first;
      select(provider, w.cells.first, w.cells.last);
      expect(provider.found, {w.word});
      expect(provider.selectedCells, isEmpty);
    });

    test('selecionar de trás para frente também marca', () {
      final w = provider.words.first;
      select(provider, w.cells.last, w.cells.first);
      expect(provider.found, {w.word});
    });

    test('seleção parcial ou de uma célula não marca nada', () {
      final w = provider.words.first;
      select(provider, w.cells.first, w.cells.first);
      select(provider, w.cells.first, w.cells[w.cells.length - 2]);
      expect(provider.found, isEmpty);
    });

    test('selectedCells acompanha o arrasto', () {
      final w = provider.words.first;
      provider.startSelection(w.cells.first.$1, w.cells.first.$2);
      provider.updateSelection(w.cells.last.$1, w.cells.last.$2);
      expect(provider.selectedCells, w.cells);
    });

    test('encontrar todas vence; seleção é ignorada depois', () {
      findAll(provider);
      expect(provider.phase, WordSearchPhase.won);
      provider.startSelection(0, 0);
      expect(provider.selectedCells, isEmpty);
    });

    test('nextLevel só funciona depois de vencer', () {
      provider.nextLevel();
      expect(provider.level, 1);

      findAll(provider);
      provider.nextLevel();
      expect(provider.level, 2);
      expect(provider.grid.length, 7);
      expect(provider.words.length, 5);
      expect(provider.found, isEmpty);
      expect(provider.phase, WordSearchPhase.playing);
    });

    test('depois do nível 10 volta ao nível 1', () {
      for (var level = 1; level <= 10; level++) {
        expect(provider.level, level);
        expect(provider.isLastLevel, level == 10);
        findAll(provider);
        provider.nextLevel();
      }
      expect(provider.level, 1);
    });
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/games/cacapalavras/selection_test.dart test/games/cacapalavras/game_provider_test.dart`
Esperado: FAIL na compilação, porque `selection.dart` e `game_provider.dart` não existem.

- [ ] **Step 3: Implementar `snapLine`**

```dart
// lib/games/cacapalavras/services/selection.dart

import 'dart:math';

/// Células da reta que sai de [start] em direção a [end], ajustada para a mais
/// próxima das 8 direções e cortada na borda da grade.
List<(int, int)> snapLine((int, int) start, (int, int) end, int size) {
  final dr = end.$1 - start.$1;
  final dc = end.$2 - start.$2;
  if (dr == 0 && dc == 0) return [start];

  final octant = (atan2(dr, dc) / (pi / 4)).round();
  final stepRow = sin(octant * pi / 4).round();
  final stepCol = cos(octant * pi / 4).round();
  final length = max(dr.abs(), dc.abs());

  final cells = <(int, int)>[];
  for (var k = 0; k <= length; k++) {
    final r = start.$1 + stepRow * k;
    final c = start.$2 + stepCol * k;
    if (r < 0 || r >= size || c < 0 || c >= size) break;
    cells.add((r, c));
  }
  return cells;
}
```

- [ ] **Step 4: Implementar o provider**

```dart
// lib/games/cacapalavras/providers/game_provider.dart

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/levels.dart';
import '../models/game_state.dart';
import '../services/grid_generator.dart';
import '../services/selection.dart';

class WordSearchProvider extends ChangeNotifier {
  WordSearchProvider({Random? random}) : _random = random ?? Random() {
    _generate();
  }

  final Random _random;

  int _level = 1;
  late List<List<String>> _grid;
  late List<PlacedWord> _words;
  final Set<String> _found = {};
  (int, int)? _selectionStart;
  (int, int)? _selectionEnd;
  WordSearchPhase _phase = WordSearchPhase.playing;

  int get level => _level;
  LevelConfig get config => kLevels[_level - 1];
  bool get isLastLevel => _level == kLevels.length;
  List<List<String>> get grid => _grid;
  List<PlacedWord> get words => List.unmodifiable(_words);
  Set<String> get found => Set.unmodifiable(_found);
  WordSearchPhase get phase => _phase;

  List<(int, int)> get selectedCells {
    final start = _selectionStart;
    final end = _selectionEnd;
    if (start == null || end == null) return const [];
    return snapLine(start, end, config.size);
  }

  void startSelection(int row, int col) {
    if (_phase != WordSearchPhase.playing) return;
    _selectionStart = (row, col);
    _selectionEnd = (row, col);
    notifyListeners();
  }

  void updateSelection(int row, int col) {
    if (_selectionStart == null || _selectionEnd == (row, col)) return;
    _selectionEnd = (row, col);
    notifyListeners();
  }

  void endSelection() {
    final cells = selectedCells;
    _selectionStart = null;
    _selectionEnd = null;

    for (final w in _words) {
      if (_found.contains(w.word)) continue;
      if (listEquals(cells, w.cells) ||
          listEquals(cells, w.cells.reversed.toList())) {
        _found.add(w.word);
        if (_found.length == _words.length) _phase = WordSearchPhase.won;
        break;
      }
    }
    notifyListeners();
  }

  /// Vai para o próximo nível (depois do 10, volta ao 1).
  void nextLevel() {
    if (_phase != WordSearchPhase.won) return;
    _level = isLastLevel ? 1 : _level + 1;
    _generate();
    notifyListeners();
  }

  void _generate() {
    final level = config;
    final generated = generateGrid(
      candidates: level.words,
      wordCount: level.wordCount,
      size: level.size,
      directions: level.directions,
      random: _random,
    );
    _grid = generated.letters;
    _words = generated.words;
    _found.clear();
    _selectionStart = null;
    _selectionEnd = null;
    _phase = WordSearchPhase.playing;
  }
}
```

- [ ] **Step 5: Rodar e ver passar**

Run: `flutter test test/games/cacapalavras`
Esperado: PASS nos três arquivos.

- [ ] **Step 6: Commit**

```bash
git add lib/games/cacapalavras/services/selection.dart lib/games/cacapalavras/providers test/games/cacapalavras/selection_test.dart test/games/cacapalavras/game_provider_test.dart
git commit -m "feat(cacapalavras): add selection snapping and game provider" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt"
```

---

### Task 8: Caça-Palavras, telas

**Files:**
- Create: `lib/games/cacapalavras/widgets/letter_grid.dart`
- Create: `lib/games/cacapalavras/widgets/word_list.dart`
- Create: `lib/games/cacapalavras/screens/home_screen.dart`
- Test: `test/games/cacapalavras/home_screen_test.dart`

**Interfaces:**
- Consumes (Task 7): `WordSearchProvider` com todos os getters e métodos listados lá.
- Produces: `class HomeScreen extends StatelessWidget` (`const HomeScreen({super.key, this.random})`, com `final Random? random`). O menu importa esse arquivo `as cacapalavras` e usa `const cacapalavras.HomeScreen()`. A tela cria o próprio `WordSearchProvider`.

- [ ] **Step 1: Escrever o teste de widget que falha**

```dart
// test/games/cacapalavras/home_screen_test.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brincaki/games/cacapalavras/providers/game_provider.dart';
import 'package:brincaki/games/cacapalavras/screens/home_screen.dart';
import 'package:brincaki/games/cacapalavras/widgets/letter_grid.dart';

Offset cellCenter(Rect grid, int size, (int, int) cell) {
  final side = grid.width / size;
  return grid.topLeft + Offset((cell.$2 + 0.5) * side, (cell.$1 + 0.5) * side);
}

/// Arrasta devagar, em vários passos, como um dedo de verdade.
Future<void> drag(WidgetTester tester, Offset from, Offset to) async {
  final gesture = await tester.startGesture(from);
  for (var i = 1; i <= 8; i++) {
    await gesture.moveTo(Offset.lerp(from, to, i / 8)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pump();
}

void main() {
  testWidgets('arrastar sobre cada palavra marca todas e mostra a vitória',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen(random: Random(11))));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nível 1'), findsOneWidget);

    final gridFinder = find.byType(LetterGrid);
    final provider =
        Provider.of<WordSearchProvider>(tester.element(gridFinder), listen: false);
    final rect = tester.getRect(gridFinder);
    final size = provider.config.size;

    for (final w in provider.words) {
      await drag(
        tester,
        cellCenter(rect, size, w.cells.first),
        cellCenter(rect, size, w.cells.last),
      );
      expect(provider.found, contains(w.word), reason: w.word);
    }

    await tester.pumpAndSettle();
    expect(find.text('Nível 1 completo!'), findsOneWidget);

    await tester.tap(find.text('Próximo nível'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nível 2'), findsOneWidget);
  });

  testWidgets('arrasto que sai da grade fica preso na borda', (tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen(random: Random(11))));
    await tester.pumpAndSettle();

    final gridFinder = find.byType(LetterGrid);
    final provider =
        Provider.of<WordSearchProvider>(tester.element(gridFinder), listen: false);
    final rect = tester.getRect(gridFinder);

    final gesture = await tester.startGesture(cellCenter(rect, 6, (0, 0)));
    await gesture.moveTo(rect.topRight + const Offset(100, 0));
    await tester.pump();
    expect(provider.selectedCells.last, (0, 5));
    await gesture.up();
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/games/cacapalavras/home_screen_test.dart`
Esperado: FAIL na compilação, porque `home_screen.dart` e `letter_grid.dart` não existem.

- [ ] **Step 3: Implementar a grade**

```dart
// lib/games/cacapalavras/widgets/letter_grid.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';

/// Cores das palavras encontradas, na ordem da lista de palavras.
const kFoundColors = [
  Color(0xFFA7F3D0),
  Color(0xFFBFDBFE),
  Color(0xFFFBCFE8),
  Color(0xFFFED7AA),
  Color(0xFFDDD6FE),
  Color(0xFFBBF7D0),
  Color(0xFFFECACA),
  Color(0xFFA5F3FC),
];

const _selectionColor = Color(0xFFFDE047);

class LetterGrid extends StatelessWidget {
  const LetterGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<WordSearchProvider>();
    final size = p.config.size;
    final selected = p.selectedCells.toSet();

    final foundColors = <(int, int), Color>{};
    for (var i = 0; i < p.words.length; i++) {
      final w = p.words[i];
      if (!p.found.contains(w.word)) continue;
      for (final cell in w.cells) {
        foundColors[cell] = kFoundColors[i % kFoundColors.length];
      }
    }

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSize = constraints.maxWidth / size;

          (int, int) toCell(Offset position) => (
                (position.dy / cellSize).floor().clamp(0, size - 1),
                (position.dx / cellSize).floor().clamp(0, size - 1),
              );

          return GestureDetector(
            // Começa a seleção onde o dedo encostou, não onde o arrasto foi
            // reconhecido.
            dragStartBehavior: DragStartBehavior.down,
            onPanStart: (d) {
              final (r, c) = toCell(d.localPosition);
              p.startSelection(r, c);
            },
            onPanUpdate: (d) {
              final (r, c) = toCell(d.localPosition);
              p.updateSelection(r, c);
            },
            onPanEnd: (_) => p.endSelection(),
            onPanCancel: p.endSelection,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (var r = 0; r < size; r++)
                    Expanded(
                      child: Row(
                        children: [
                          for (var c = 0; c < size; c++)
                            Expanded(
                              child: _LetterCell(
                                letter: p.grid[r][c],
                                fontSize: cellSize * 0.55,
                                background: selected.contains((r, c))
                                    ? _selectionColor
                                    : foundColors[(r, c)],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LetterCell extends StatelessWidget {
  const _LetterCell({
    required this.letter,
    required this.fontSize,
    required this.background,
  });

  final String letter;
  final double fontSize;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.fredoka(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3B0764),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implementar a lista de palavras**

```dart
// lib/games/cacapalavras/widgets/word_list.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';

class WordList extends StatelessWidget {
  const WordList({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<WordSearchProvider>();
    final words = p.words.map((w) => w.word).toList()..sort();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final word in words)
          _WordChip(word: word, found: p.found.contains(word)),
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.word, required this.found});

  final String word;
  final bool found;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: found ? const Color(0xFFEDE9FE) : Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFC4B5FD)),
      ),
      child: Text(
        word,
        style: GoogleFonts.fredoka(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: found ? const Color(0xFFA78BFA) : const Color(0xFF5B21B6),
          decoration: found ? TextDecoration.lineThrough : null,
          decorationThickness: 2,
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Implementar a tela**

A tela **não** usa `SingleChildScrollView`. Uma rolagem vertical disputaria o arrasto com a grade e venceria nos arrastos verticais (Review Focus 1).

```dart
// lib/games/cacapalavras/screens/home_screen.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/letter_grid.dart';
import '../widgets/word_list.dart';

const _purple = Color(0xFF5B21B6);
const _background = Color(0xFFF5F3FF);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.random});

  /// Só para testes: deixa a grade previsível.
  final Random? random;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WordSearchProvider(random: random),
      child: const _WordSearchView(),
    );
  }
}

class _WordSearchView extends StatelessWidget {
  const _WordSearchView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _purple),
          tooltip: 'Voltar ao menu',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        title: Consumer<WordSearchProvider>(
          builder: (context, p, child) => Text(
            'Caça-Palavras • Nível ${p.level} — ${p.config.theme}',
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _purple,
            ),
          ),
        ),
      ),
      body: const SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(child: Center(child: LetterGrid())),
                  SizedBox(height: 16),
                  WordList(),
                ],
              ),
            ),
            _ResultOverlay(),
          ],
        ),
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<WordSearchProvider>();
    if (p.phase != WordSearchPhase.won) return const SizedBox.shrink();

    final last = p.isLastLevel;

    return Positioned.fill(
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
                Text(last ? '🏆' : '🎉', style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text(
                  last
                      ? 'Você completou todos os níveis!'
                      : 'Nível ${p.level} completo!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: p.nextLevel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
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
                    last ? 'Jogar de novo' : 'Próximo nível',
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

O `Positioned.fill` dentro de `_ResultOverlay` funciona porque o widget é filho direto do `Stack`.

- [ ] **Step 6: Rodar e ver passar**

Run: `flutter test test/games/cacapalavras`
Esperado: PASS em todos os arquivos.

Run: `flutter analyze`
Esperado: `No issues found!`. Agora todos os imports do menu existem.

- [ ] **Step 7: Commit**

```bash
git add lib/games/cacapalavras/widgets lib/games/cacapalavras/screens test/games/cacapalavras/home_screen_test.dart
git commit -m "feat(cacapalavras): add game screen with drag selection and word list" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt"
```

---

### Task 9: `GameShell`, menu e navegação

**Files:**
- Create: `lib/widgets/game_shell.dart`
- Modify: `lib/screens/menu_screen.dart`, os cinco métodos `_open*`
- Modify: `lib/games/tictactoe/screens/game_screen.dart:25-28`, a seta "voltar"
- Modify: `lib/games/forca/screens/game_screen.dart:22-25`, a seta "voltar"
- Test: `test/screens/menu_screen_test.dart`

**Interfaces:**
- Consumes:
  - `BrincakiApp` (Task 1);
  - `cacapalavras.HomeScreen` (Task 8);
  - `sudoku.HomeScreen` e `GameProvider` (Task 2);
  - `Game2048Screen` e `Game2048Provider` (Tasks 4 e 5);
  - `TicTacToeScreen` e `TicTacToeProvider`;
  - `ForcaScreen` e `forca.ForcaProvider`.
- Produces: `class GameShell extends StatefulWidget` com `GameShell({Key? key, required ThemeData theme, required WidgetBuilder home, Widget Function(Widget child)? wrapProvider})`.

- [ ] **Step 1: Escrever o teste do menu que falha**

```dart
// test/screens/menu_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brincaki/main.dart';

const _menuSubtitle = 'Escolha um jogo para brincar!';

/// Avança o relógio em passos, para animações encadeadas (fechar diálogo e
/// depois a tela). Não usa pumpAndSettle porque a partida de Sudoku tem um
/// cronômetro periódico.
Future<void> pumpSteps(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> openGame(WidgetTester tester, String title) async {
  final card = find.text(title);
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('menu mostra os 5 jogos', (tester) async {
    await tester.pumpWidget(const BrincakiApp());
    await tester.pumpAndSettle();
    for (final title in [
      'Caça-Palavras',
      'Sudoku',
      '2048',
      'Jogo da Velha',
      'Jogo da Forca',
    ]) {
      await tester.ensureVisible(find.text(title));
      expect(find.text(title), findsOneWidget);
    }
  });

  // Texto que só existe na primeira tela de cada jogo.
  final games = <String, Finder>{
    'Caça-Palavras': find.textContaining('Caça-Palavras • Nível 1'),
    'Sudoku': find.text('Selecione a dificuldade'),
    '2048': find.text('Novo jogo'),
    'Jogo da Velha': find.text('Jogo da Velha'),
    'Jogo da Forca': find.textContaining('Jogo da Forca  •  Nível 1'),
  };

  for (final entry in games.entries) {
    testWidgets('${entry.key}: abre pelo card e volta pela seta', (tester) async {
      await tester.pumpWidget(const BrincakiApp());
      await tester.pumpAndSettle();

      await openGame(tester, entry.key);
      expect(entry.value, findsWidgets);
      expect(find.text(_menuSubtitle), findsNothing);

      await tester.tap(find.byTooltip('Voltar ao menu'));
      await tester.pumpAndSettle();
      expect(find.text(_menuSubtitle), findsOneWidget);
    });

    testWidgets('${entry.key}: "voltar" do sistema volta ao menu', (tester) async {
      await tester.pumpWidget(const BrincakiApp());
      await tester.pumpAndSettle();

      await openGame(tester, entry.key);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(_menuSubtitle), findsOneWidget);
    });
  }

  testWidgets('Sudoku: "voltar" na partida confirma, volta à dificuldade e depois ao menu',
      (tester) async {
    await tester.pumpWidget(const BrincakiApp());
    await tester.pumpAndSettle();
    await openGame(tester, 'Sudoku');

    await tester.tap(find.text('Fácil'));
    await pumpSteps(tester);
    expect(find.text('Selecione a dificuldade'), findsNothing);

    await tester.binding.handlePopRoute();
    await pumpSteps(tester);
    expect(find.text('Sair do Jogo'), findsOneWidget);

    await tester.tap(find.text('Sair'));
    await pumpSteps(tester);
    expect(find.text('Selecione a dificuldade'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(_menuSubtitle), findsOneWidget);
  });
}
```

Notas:
- A partida de Sudoku tem um `Timer.periodic` de 1 s, por isso o teste usa `pumpSteps` em vez de `pumpAndSettle` enquanto a partida estiver aberta.
- O timer é cancelado no `dispose` do `GameProvider`, que acontece quando o `GameShell` sai da árvore.
- O título do Jogo da Velha aparece na `AppBar` e também no card do menu, que fica escondido debaixo da rota. Por isso o teste usa `findsWidgets` e confere que o subtítulo do menu sumiu.

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/screens/menu_screen_test.dart`
Esperado: FAIL.
- Os testes "volta pela seta" do Caça-Palavras, do Sudoku e do 2048 já passam, porque as Tasks 2, 5 e 8 usam `rootNavigator: true`.
- Os do Jogo da Velha e da Forca falham: a seta faz `pop` no `Navigator` interno e não volta ao menu.
- O teste de "voltar" dentro da partida de Sudoku falha: o "voltar" do sistema sai direto para o menu, sem o diálogo.

- [ ] **Step 3: Implementar o `GameShell`**

```dart
// lib/widgets/game_shell.dart

import 'package:flutter/material.dart';

/// Abre um jogo com tema próprio e um Navigator interno.
///
/// O "voltar" do sistema volta uma tela dentro do jogo; na primeira tela do
/// jogo, sai para o menu.
class GameShell extends StatefulWidget {
  const GameShell({
    super.key,
    required this.theme,
    required this.home,
    this.wrapProvider,
  });

  final ThemeData theme;
  final WidgetBuilder home;

  /// Envolve o jogo no provider dele, por exemplo
  /// `(child) => ChangeNotifierProvider(create: (_) => TicTacToeProvider(), child: child)`.
  /// Nulo para jogos que criam o provider na própria tela.
  final Widget Function(Widget child)? wrapProvider;

  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final game = Theme(
      data: widget.theme,
      child: NavigatorPopHandler<Object?>(
        onPopWithResult: (_) => _navigatorKey.currentState!.maybePop(),
        child: Navigator(
          key: _navigatorKey,
          onGenerateRoute: (_) => MaterialPageRoute(builder: widget.home),
        ),
      ),
    );
    return widget.wrapProvider?.call(game) ?? game;
  }
}
```

- [ ] **Step 4: Usar o `GameShell` no menu**

Em `lib/screens/menu_screen.dart`:
- adicionar `import '../widgets/game_shell.dart';`;
- substituir os cinco métodos `_openCacaPalavras`, `_openSudoku`, `_openGame2048`, `_openTicTacToe` e `_openForca`, do início de `_openCacaPalavras` até o fim de `_openForca`, por:

```dart
  void _openGame(BuildContext context, GameShell shell) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => shell));
  }

  void _openCacaPalavras(BuildContext context) {
    _openGame(
      context,
      GameShell(
        theme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          useMaterial3: true,
          textTheme: GoogleFonts.fredokaTextTheme(),
        ),
        home: (_) => const cacapalavras.HomeScreen(),
      ),
    );
  }

  void _openSudoku(BuildContext context) {
    _openGame(
      context,
      GameShell(
        wrapProvider: (child) =>
            ChangeNotifierProvider(create: (_) => GameProvider(), child: child),
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121212),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFBB86FC),
            surface: Color(0xFF1E1E1E),
            error: Color(0xFFCF6679),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBB86FC),
              foregroundColor: Colors.black,
            ),
          ),
        ),
        home: (_) => const sudoku.HomeScreen(),
      ),
    );
  }

  void _openGame2048(BuildContext context) {
    _openGame(
      context,
      GameShell(
        wrapProvider: (child) => ChangeNotifierProvider(
          create: (_) => Game2048Provider(),
          child: child,
        ),
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFFF97316),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFFAF8EF),
        ),
        home: (_) => const Game2048Screen(),
      ),
    );
  }

  void _openTicTacToe(BuildContext context) {
    _openGame(
      context,
      GameShell(
        wrapProvider: (child) => ChangeNotifierProvider(
          create: (_) => TicTacToeProvider(),
          child: child,
        ),
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFFEC4899),
          useMaterial3: true,
          textTheme: GoogleFonts.fredokaTextTheme(),
        ),
        home: (_) => const TicTacToeScreen(),
      ),
    );
  }

  void _openForca(BuildContext context) {
    _openGame(
      context,
      GameShell(
        wrapProvider: (child) => ChangeNotifierProvider(
          create: (_) => forca.ForcaProvider(),
          child: child,
        ),
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF3B82F6),
          useMaterial3: true,
          textTheme: GoogleFonts.fredokaTextTheme(),
        ),
        home: (_) => const ForcaScreen(),
      ),
    );
  }
```

O resto do arquivo (`build`, `_buildHeader`, `_buildGameCard`, `_buildFooter`) **não muda**.

- [ ] **Step 5: Corrigir as setas do Jogo da Velha e da Forca**

Em `lib/games/tictactoe/screens/game_screen.dart` e em `lib/games/forca/screens/game_screen.dart`, trocar o `IconButton` do `leading` por (mantendo a cor de cada arquivo: `Color(0xFFBE185D)` na Velha, `Color(0xFF1D4ED8)` na Forca):

```dart
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFBE185D)),
          tooltip: 'Voltar ao menu',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
```

- [ ] **Step 6: Rodar tudo**

Run: `flutter test`
Esperado: PASS em todos os testes, incluindo todos os de `test/screens/menu_screen_test.dart`.

Run: `flutter analyze`
Esperado: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/widgets lib/screens/menu_screen.dart lib/games/tictactoe/screens/game_screen.dart lib/games/forca/screens/game_screen.dart test/screens
git commit -m "feat: open games through GameShell so back always returns to the menu" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Xjg1TLqC4ZgdPxqjYVNytt"
```

---

### Task 10: Verificação manual e APK

**Files:** nenhum arquivo de código. Eventualmente correções que a verificação revelar, cada uma com um teste antes.

- [ ] **Step 1: Suíte completa**

Run: `flutter analyze && flutter test`
Esperado: `No issues found!` e todos os testes passando.

- [ ] **Step 2: Rodar no Chrome**

Run (em background): `flutter run -d web-server --web-port 8080 --web-hostname localhost`
Abrir `http://localhost:8080` com as ferramentas do Chrome (skill `claude-in-chrome`) numa janela de celular, redimensionada para 412×915.

- [ ] **Step 3: Passar por cada jogo e tirar capturas de tela**

Para cada um dos 5 cards:
1. Abrir o jogo pelo card.
2. Jogar:
   - **Caça-Palavras:** encontrar uma palavra arrastando, inclusive uma vertical.
   - **Sudoku:** escolher Fácil e preencher uma casa.
   - **2048:** fazer alguns movimentos com as setas e com arrasto do mouse.
   - **Jogo da Velha:** preencher os nomes e jogar até vencer.
   - **Forca:** acertar e errar uma letra.
3. Voltar ao menu pela seta.

Capturas obrigatórias: o menu, que deve bater com `docs/menu-referencia.png`, e uma de cada jogo. Qualquer problema visual ou de comportamento vira uma correção: um teste que reproduz o problema, depois a correção e um commit `fix(<jogo>): ...`.

- [ ] **Step 4: APK (precisa do SDK do Android)**

Esta máquina não tem o SDK do Android (`flutter doctor`: "Unable to locate Android SDK"). **Pare e pergunte ao usuário** antes de instalar qualquer coisa. A instalação é grande, cerca de 3 a 5 GB, e pode ser feita pelo Android Studio ou pelas `cmdline-tools`. Depois que o SDK estiver disponível:

```bash
flutter doctor --android-licenses
flutter build apk --release
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

Esperado: o APK existe, com algo em torno de 20 MB. O release é assinado com a chave de debug, como o `flutter create` configura por padrão, e isso basta para instalar sem loja.

- [ ] **Step 5: Entregar**

Informar o caminho do APK e como instalar: copiar para o celular, permitir "instalar apps desconhecidos" e abrir o arquivo. Enviar as capturas de tela com `SendUserFile`.
