# Damas e Xadrez Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Two new board games, Damas (Brazilian rules) and Xadrez (official rules), each with "Contra o computador" (3 levels) and "Dois jogadores", built like Lig 4.

**Architecture:** Each game is a module under `lib/games/<game>/` with pure, immutable rules in `logic/` (position, legal moves, a `Game` history object that detects the end), an AI in `logic/ai.dart` run through `compute`, one `ChangeNotifier` provider driving tap-to-select / tap-to-move, and a screen built on `GameScaffold`, `PlayerSetup`, `ScoreBoard` and `ResultPanel`. Shared work (color picker in `PlayerSetup`, palettes, chess font) lands first; the two games are then independent tracks; the menu and the integration test close.

**Tech Stack:** Flutter/Dart, `provider`, `google_fonts` (bundled Fredoka), `flutter_test`, `integration_test`.

**Spec:** `docs/superpowers/specs/2026-10-18-damas-e-xadrez-design.md`

## Global Constraints

- All UI text, comments and test names in Brazilian Portuguese.
- Every file starts with a `// lib/path/to/file.dart` (or `// test/...`) comment.
- No internet at runtime: fonts are bundled (`assets/google_fonts/`, `assets/fonts/`).
- Providers: private fields + getters; every mutating method checks the phase first; computer opponent takes injectable `thinkTime` (default 500 ms) and `aiRunner`; late moves discarded with `_gameId`; never notify after `dispose`; if the runner throws, play a random legal move.
- Brancas always start; the chosen color stays across "Jogar de novo".
- Board faces the human vs computer; fixed with brancas at the bottom in "Dois jogadores".
- Widget tests at 360x740 and 320x568.
- Computer search under ~1.5 s on a phone (Hard), Medium/Hard via `compute`.
- `flutter analyze` clean; `flutter test` green; `flutter test --coverage && python3 tool/check_coverage.py` passes (≥90% per file, ≥95% total).
- Commits: Conventional Commits scoped `feat(damas)`, `feat(xadrez)`, `feat(widgets)`, `test(...)`; end messages with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Square index everywhere: `index = row * 8 + col`, row 0 = top of the board as seen with brancas at the bottom (black's back rank), col 0 = left (file "a").

## Review Focus

1. Damas multi-capture with a flying king where two landing squares lead to different continuations: only landings that keep the maximum capture count must light up (test in Task 2 `lei da maioria vale para onde a dama pousa`, and Task 5 `salto por toque só acende pousos da maioria`).
2. Double taps / taps during "Pensando..." or after the game ended must be ignored and never apply two moves (tests in Task 5 and Task 10: `ignora toques na vez do computador`, `ignora toques depois do fim`).
3. Leaving with "Trocar jogadores" or the back arrow while the computer is thinking must not apply a stale move (tests in Task 5/Task 10: `descarta lance atrasado do computador`).
4. Promotion selection cancelled (Xadrez) must leave the position untouched and the turn unchanged (test in Task 10 `cancelar promoção não mexe no tabuleiro`).
5. Playing pretas vs computer: computer opens, board is flipped, and the tap keys still address the real squares (tests in Task 6/Task 11 `com as pretas o computador começa e o tabuleiro vira`).

---

### Task 1: Shared pieces (color picker, palettes, chess font)

**Files:**
- Modify: `lib/widgets/player_setup.dart`, `lib/widgets/game_palette.dart`, `pubspec.yaml`
- Create: `assets/fonts/ChessSymbols.ttf` (subset of Noto Sans Symbols 2, U+2654–265F, already built at `/tmp/claude-1000/-home-filipecrespodev-Workspace-My-brincaki/46588c67-7958-4259-a7b3-f613e14b4555/scratchpad/font/ChessSymbols.ttf`), `assets/fonts/OFL.txt` (OFL 1.1 text copied from `assets/google_fonts/OFL.txt` with the first line `Copyright 2022 The Noto Project Authors (https://github.com/notofonts/symbols)`)
- Test: `test/widgets/player_setup_test.dart`, `test/widgets/game_palette_test.dart`

**Interfaces:**
- Produces: `PlayerSetup(..., (String, String)? sides)`; `PlayerSetupResult.sideIndex` (`int?`, 0 = first label, 1 = second, null when `sides` is null); `kDamasPalette`, `kXadrezPalette`; font family `ChessSymbols`.

- [ ] **Step 1: Failing tests** in `player_setup_test.dart`:
  - `sem sides não mostra a escolha de cor e devolve sideIndex nulo`
  - `com sides mostra "Sua cor" no solo e devolve a cor escolhida` — pump with `sides: ('Brancas', 'Pretas')`, expect `find.text('Sua cor')`, tap `Pretas`, tap `Jogar!`, expect `result.sideIndex == 1`; default (no tap) gives 0.
  - `em dois jogadores o rótulo é "Cor do Jogador 1"` and sideIndex still returned.
  - `com pretas os símbolos dos nomes trocam` — symbols `('⚪','⚫')`, choose Pretas: name1 field's prefix is `⚫`.
- [ ] **Step 2:** `flutter test test/widgets/player_setup_test.dart` → FAIL.
- [ ] **Step 3:** Implement: a second `LevelPicker` (label `'Sua cor'` solo / `'Cor do Jogador 1'` duo, levels `[sides.$1, sides.$2]`) shown in both modes right after the name fields; symbols swap when side 1 is selected.
- [ ] **Step 4:** Test passes; `flutter test test/widgets` green.
- [ ] **Step 5:** Commit `feat(widgets): let PlayerSetup pick a side`.
- [ ] **Step 6:** Add palettes: `kDamasPalette` (accent `0xFFA16207`, light `0xFFCA8A04`, dark `0xFF713F12`, background `0xFFFEFCE8`) and `kXadrezPalette` (accent `0xFF4F46E5`, light `0xFF818CF8`, dark `0xFF3730A3`, background `0xFFEEF2FF`); extend `game_palette_test.dart` if it lists palettes. Copy the font and OFL, add to `pubspec.yaml` under `flutter:` a `fonts:` entry `family: ChessSymbols` → `assets/fonts/ChessSymbols.ttf`. `flutter test test/widgets` green.
- [ ] **Step 7:** Commit `feat: add Damas and Xadrez palettes and the chess font`.

---

## Track D — Damas (`lib/games/damas/`)

Encoding: `List<int> cells` of 64; `0` empty, `1` pedra branca, `2` dama branca, `-1` pedra preta, `-2` dama preta. Dark (playable) squares: `(row + col).isOdd`. Initial: pretas on dark squares of rows 0–2, brancas on rows 5–7. Brancas move "up" (row decreasing) and promote on row 0; pretas promote on row 7.

### Task 2: Rules (moves, captures, lei da maioria, promotion)

**Files:**
- Create: `lib/games/damas/models/game_state.dart`, `lib/games/damas/logic/board.dart`
- Test: `test/games/damas/board_test.dart`

**Interfaces:**
- Produces (`models/game_state.dart`): `enum DamasPhase { setup, playing, finished }`, `enum DamasSide { white, black }` (with `DamasSide get opponent`), `enum DamasEnd { noPieces, noMoves, repetition, twentyMoves, fiveMoves }`.
- Produces (`logic/board.dart`):
  - `class DamasMove { const DamasMove(this.path, this.captured); final List<int> path; final List<int> captured; int get from; int get to; bool get isCapture; }` with value `==`/`hashCode` over path.
  - `class DamasPosition { DamasPosition(this.cells, this.turn); factory DamasPosition.initial(); final List<int> cells; final DamasSide turn; String get key; }` (`key` = cells + turn, used for repetition).
  - `List<DamasMove> legalMoves(DamasPosition p)` — if any capture exists, only captures with the maximum number of captured pieces; else simple moves.
  - `DamasPosition applyMove(DamasPosition p, DamasMove m)` — removes captured, promotes a pedra only if `m.to` is on its last row, flips turn.
  - `bool isMan(int v)`, `bool isKing(int v)`, `DamasSide? sideOf(int v)`.

- [ ] **Step 1: Failing tests** (build positions with a helper `pos(Map<int,int> pieces, DamasSide turn)`):
  - `posição inicial tem 12 de cada lado e 7 lances para as brancas`
  - `pedra só anda para a frente`
  - `pedra captura para trás`
  - `captura é obrigatória` (a simple move exists but only the capture is legal)
  - `captura em sequência é um lance só` (path length 3, captured length 2)
  - `lei da maioria escolhe a sequência que come mais` (one branch takes 1, another 2 → only the 2)
  - `empate no número de capturas deixa escolher` (two branches of 1 → both)
  - `dama anda várias casas` and `dama captura a distância e pousa em qualquer casa depois`
  - `lei da maioria vale para onde a dama pousa` (only landing squares that continue capturing are legal)
  - `não pula a mesma peça duas vezes` and `peça capturada continua bloqueando até o fim do lance`
  - `pedra que passa pela última fileira capturando não vira dama`; `pedra que termina na última fileira vira dama`
  - `applyMove troca a vez e tira as capturadas`
- [ ] **Step 2:** `flutter test test/games/damas/board_test.dart` → FAIL.
- [ ] **Step 3:** Implement. Captures via DFS from each own piece on a working copy: track jumped squares (not removed until the end); a man jumps an adjacent enemy in all 4 diagonals onto the empty square right behind; a king slides over empties, meets one enemy not yet jumped, then may land on every empty square beyond until blocked. Recurse; a sequence ends when no further jump. Men promote only after the whole sequence. Filter by max `captured.length`.
- [ ] **Step 4:** Tests pass.
- [ ] **Step 5:** Commit `feat(damas): add the Brazilian draughts rules`.

### Task 3: Game history and endings

**Files:**
- Create: `lib/games/damas/logic/game.dart`
- Test: `test/games/damas/game_test.dart`

**Interfaces:**
- Produces: `class DamasGame { factory DamasGame.start([DamasPosition? from]); DamasPosition get position; List<DamasMove> get legalMoves; DamasGame play(DamasMove m); DamasEnd? get end; DamasSide? get winner; DamasMove? get lastMove; }` — immutable (`play` returns a new game); `play` throws `StateError` if the move is not legal or the game ended.
- Rules: `noPieces`/`noMoves` → winner is the side that just moved (checked for the side to move). `repetition` when `position.key` occurs the 3rd time. `twentyMoves` after 40 consecutive half-moves with no capture and no pedra move. `fiveMoves` after 10 half-moves counted from when material first becomes one of: 2D×2D, 2D×1D, 2D×(1D+1P), 1D×1D, 1D×(1D+1P) (either side; counter resets if material changes to another listed set or leaves the list).

- [ ] **Step 1: Failing tests:** `vence quem tira todas as peças`, `vence quem deixa o adversário sem lance`, `empata com a mesma posição 3 vezes`, `empata com 20 lances de cada lado só com damas`, `lance de pedra zera a contagem dos 20 lances`, `empata com 5 lances em 2 damas contra 1`, `play recusa lance ilegal`, `play recusa lance depois do fim`.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement (keep a `Map<String,int>` of key counts and the two counters; copy on `play`). **Step 4:** Pass.
- [ ] **Step 5:** Commit `feat(damas): detect wins and draws`.

### Task 4: Computer

**Files:**
- Create: `lib/games/damas/logic/ai.dart`
- Test: `test/games/damas/ai_test.dart`

**Interfaces:**
- Produces: `enum AiLevel { easy, medium, hard }`; `DamasMove chooseMove(DamasPosition p, AiLevel level, Random random, {Duration budget = const Duration(milliseconds: 1200)})`; `int chooseMoveInIsolate((List<int> cells, int turn, int level, int seed) args)` → index into `legalMoves(p)`.
- Easy: random; with prob. 0.5 picks the move capturing the most pieces. Medium: 2-ply minimax on material (pedra 100, dama 300), random tie-break. Hard: iterative-deepening alpha-beta up to 8 plies within `budget` (stop and keep the last completed depth), eval = material + advancement of pedras + center + back-row guard; captures are forced moves so no quiescence needed beyond extending when the only moves are captures.

- [ ] **Step 1: Failing tests:** `todos os níveis só devolvem lances legais` (100 random positions from random playouts with `Random(seed)`), `médio e difícil pegam a peça de graça`, `difícil não entrega peça de graça`, `difícil responde dentro do orçamento` (initial position, < 2 s), `chooseMoveInIsolate devolve o índice do lance`.
- [ ] **Step 2–4:** Run → FAIL, implement, pass.
- [ ] **Step 5:** Commit `feat(damas): add the computer opponent`.

### Task 5: Provider

**Files:**
- Create: `lib/games/damas/providers/game_provider.dart`
- Test: `test/games/damas/game_provider_test.dart`

**Interfaces:**
- Consumes: Tasks 2–4, `PlayerSetupResult` (with `sideIndex`).
- Produces: `typedef DamasAiRunner = Future<DamasMove> Function(DamasPosition position, AiLevel level);` `class DamasProvider extends ChangeNotifier { DamasProvider({Random? random, Duration thinkTime = const Duration(milliseconds: 500), DamasAiRunner? aiRunner}); }` with getters: `phase`, `mode`, `name1`, `name2`, `aiLevel`, `player1Side` (`DamasSide`), `game` (`DamasGame`), `selected` (`int?`), `targets` (`Set<int>`), `partialPath` (`List<int>`), `capturedSoFar` (`Set<int>`), `mustCapture` (`Set<int>` of own squares that can capture, empty when no capture is forced), `lastMove` (`DamasMove?`), `wins1`, `wins2`, `draws`, `aiThinking`, `isComputerTurn`, `flipped` (`bool`: true when the bottom of the screen is pretas), `winnerPlayer` (`int?`: 1, 2 or null), `currentPlayer` (`int`: 1 or 2); methods `start(PlayerSetupResult)`, `tapSquare(int index)`, `playAgain()`, `exitToSetup()`.
- In solo, player 1 is the human; the computer is player 2 with the other side. `start` reads `sideIndex ?? 0` (0 = brancas).
- `tapSquare`: in `playing`, not `aiThinking`, not `isComputerTurn`. No partial path: tapping an own piece that starts a legal move selects it (`targets` = next squares of those moves); tapping a target extends `partialPath`; when the path equals a full legal move it is played. Once a capture sequence has begun (`partialPath.length >= 2`) only targets are accepted. Tapping elsewhere without a partial path clears the selection.

- [ ] **Step 1: Failing tests:** `começa na fase setup`, `start com brancas: vez do jogador 1`, `seleciona peça e acende destinos`, `peça que não pode capturar não é selecionada quando há captura`, `mustCapture lista as peças obrigadas`, `salto por toque só acende pousos da maioria`, `troca a vez depois do lance completo`, `computador joga depois do thinkTime` (fake async), `com pretas o computador começa`, `ignora toques na vez do computador`, `ignora toques depois do fim`, `descarta lance atrasado do computador` (exitToSetup while thinking), `runner que falha joga um lance legal`, `não notifica depois do dispose`, `vitória soma no placar e playAgain mantém as cores`, `exitToSetup zera o placar`.
- [ ] **Step 2–4:** Run → FAIL, implement, pass.
- [ ] **Step 5:** Commit `feat(damas): add the game provider`.

### Task 6: Screen and board

**Files:**
- Create: `lib/games/damas/screens/game_screen.dart` (`DamasScreen`), `lib/games/damas/widgets/board_view.dart` (`DamasBoardView`)
- Test: `test/games/damas/game_screen_test.dart`

**Interfaces:**
- Squares have `Key('sq-$index')` (board index, not display position), one `GestureDetector` per square calling `tapSquare`.
- `PlayerSetup(title: 'Damas', emoji: '⚫', soloLabel: 'Contra o computador', symbols: ('⚪', '⚫'), levels: ['Fácil','Médio','Difícil'], sides: ('Brancas', 'Pretas'), soloOpponentName: 'Computador')`. Title `'Damas • Fácil'` in solo. Turn line `'Vez de ⚪ Nome'` / `'🤖 Pensando...'`; when forced, add `' • Captura obrigatória!'`. `confirmExit: phase == playing`. Result per spec §1 with the end-reason message (`noPieces` → `'Sem peças para jogar'`, `noMoves` → `'Sem jogadas possíveis'`, `repetition` → `'A mesma posição 3 vezes'`, `twentyMoves` → `'20 lances só com damas'`, `fiveMoves` → `'5 lances no final de damas'`) and buttons `Jogar de novo` / `Trocar jogadores`.
- Board: square `AspectRatio(1)`, light `0xFFF3E3C3`, dark `0xFF9A6B3F`; selected / last move tints; target dot (empty) — pieces drawn as circles with a crown icon for kings (`Icons.workspace_premium` or similar); `mustCapture` pieces outlined in `kDamasPalette.accent`; `capturedSoFar` pieces at 40% opacity. Flip by mapping display (r, c) → `flipped ? 63 - i : i`.

- [ ] **Step 1: Failing tests** (pattern of `test/games/lig4/game_screen_test.dart`, fake `aiRunner` = first legal move, thinkTime zero), each at 360x740 and 320x568: `dois jogadores: lance pelos toques e vez passa`, `captura obrigatória mostra o aviso`, `fim de jogo mostra o painel e o tabuleiro` (start the provider from a near-end position via a test-only path: play a forced short sequence from `DamasGame.start(custom)` — add `@visibleForTesting void startFrom(PlayerSetupResult setup, DamasPosition position)` to the provider), `Jogar de novo` / `Trocar jogadores` / voltar com confirmação, `com as pretas o computador começa e o tabuleiro vira`, `sem overflow em 320x568`.
- [ ] **Step 2–4:** Run → FAIL, implement, pass. Also run `flutter analyze`.
- [ ] **Step 5:** Commit `feat(damas): add the setup, board and result screen`.

---

## Track X — Xadrez (`lib/games/xadrez/`)

Encoding: `List<int> cells` of 64, row 0 = rank 8. `1` peão, `2` cavalo, `3` bispo, `4` torre, `5` dama, `6` rei; positive brancas, negative pretas. Castling bits: `1` K, `2` Q, `4` k, `8` q.

### Task 7: Position and legal moves

**Files:**
- Create: `lib/games/xadrez/models/game_state.dart`, `lib/games/xadrez/logic/position.dart`
- Test: `test/games/xadrez/position_test.dart`

**Interfaces:**
- Produces (models): `enum XadrezPhase { setup, playing, finished }`, `enum ChessSide { white, black }` (`opponent`), `enum XadrezEnd { checkmate, stalemate, insufficientMaterial, fiftyMoves, repetition }`, piece constants `kPawn = 1 ... kKing = 6`.
- Produces (logic): `class ChessMove { const ChessMove(this.from, this.to, {this.promotion = 0, this.isCastle = false, this.isEnPassant = false, this.captured = 0}); }` with `==` over from/to/promotion; `String get uci` (e.g. `e2e4`, `e7e8q`).
  `class ChessPosition { factory ChessPosition.initial(); factory ChessPosition.fromFen(String fen); String toFen(); List<int> get cells; ChessSide get turn; int get castling; int? get enPassant; int get halfmoveClock; List<ChessMove> legalMoves(); ChessPosition play(ChessMove m); bool get inCheck; int kingSquare(ChessSide side); bool isAttacked(int square, ChessSide by); bool get insufficientMaterial; String get repetitionKey; }`
  `int perft(ChessPosition p, int depth)`; `int squareOf(String name)` (`'e4'` → 36) and `String nameOf(int square)`.
- `repetitionKey` = piece placement + turn + castling + en-passant square only if a legal en passant capture exists.
- Promotion moves are generated for all four pieces (`promotion` = 5, 4, 3, 2).

- [ ] **Step 1: Failing tests:** `posição inicial tem 20 lances`; perft initial `[20, 400, 8902]` (depth 1–3); perft Kiwipete `r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1` → `[48, 2039]`; perft position 3 `8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1` → `[14, 191, 2812]`; perft position 4 `r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1` → `[6, 264, 9467]`; `roque não passa por casa atacada`, `en passant só no lance seguinte`, `promoção gera as quatro peças`, `fen ida e volta`, `material insuficiente` (KvK, KBvK, KNvK, KB v KB mesma cor = true; KB v KB cores diferentes, KP v K = false), `repetitionKey ignora en passant impossível`.
- [ ] **Step 2–4:** Run → FAIL, implement (pseudo-legal generation, then filter by `!play(m).isAttacked(kingSquare(turn), opponent)`; castling checks the king's start, the crossed square and the target), pass. Perft tests must finish in a few seconds.
- [ ] **Step 5:** Commit `feat(xadrez): add the chess rules and move generation`.

### Task 8: Game history and endings

**Files:**
- Create: `lib/games/xadrez/logic/game.dart`
- Test: `test/games/xadrez/game_test.dart`

**Interfaces:**
- Produces: `class ChessGame { factory ChessGame.start([ChessPosition? from]); ChessPosition get position; List<ChessMove> get legalMoves; ChessGame play(ChessMove m); XadrezEnd? get end; ChessSide? get winner; ChessMove? get lastMove; }` — `play` throws `StateError` on illegal move or after the end. Ends: no legal move + in check → `checkmate` (winner = side that moved); no legal move otherwise → `stalemate`; `insufficientMaterial`; `halfmoveClock >= 100` → `fiftyMoves`; 3rd occurrence of `repetitionKey` → `repetition`.

- [ ] **Step 1: Failing tests:** `mate do louco` (f2f3 e7e5 g2g4 d8h4 → checkmate, winner black), `afogamento empata`, `rei contra rei empata`, `50 lances empata`, `repetição 3 vezes empata` (knights out and back), `play recusa lance ilegal`.
- [ ] **Step 2–4:** Run → FAIL, implement, pass.
- [ ] **Step 5:** Commit `feat(xadrez): detect checkmate and draws`.

### Task 9: Computer

**Files:**
- Create: `lib/games/xadrez/logic/ai.dart`
- Test: `test/games/xadrez/ai_test.dart`

**Interfaces:**
- Produces: `enum AiLevel { easy, medium, hard }`; `ChessMove chooseMove(ChessPosition p, AiLevel level, Random random, {Duration budget = const Duration(milliseconds: 1200)})`; `int chooseMoveInIsolate((String fen, int level, int seed) args)` → index into `ChessPosition.fromFen(fen).legalMoves()`. Always promotes to queen when it picks a promotion (only consider `promotion == 5` or `0`).
- Easy: mate-in-1 if any, else 50% best capture (MVV-LVA), else random. Medium: 2-ply material minimax with small random noise (±10 cp). Hard: iterative deepening alpha-beta (depth up to 4) within `budget`, quiescence on captures, MVV-LVA ordering, piece-square tables, mate scores preferring faster mates.

- [ ] **Step 1: Failing tests:** `todos os níveis só devolvem lances legais` (random positions), `médio e difícil acham mate em 1`, `difícil não deixa a dama ser comida de graça`, `difícil responde dentro do orçamento` (initial and Kiwipete, < 2 s), `promove para dama`, `chooseMoveInIsolate devolve o índice do lance`.
- [ ] **Step 2–4:** Run → FAIL, implement, pass.
- [ ] **Step 5:** Commit `feat(xadrez): add the computer opponent`.

### Task 10: Provider

**Files:**
- Create: `lib/games/xadrez/providers/game_provider.dart`
- Test: `test/games/xadrez/game_provider_test.dart`

**Interfaces:**
- Produces: `typedef XadrezAiRunner = Future<ChessMove> Function(ChessPosition position, AiLevel level);` `class XadrezProvider extends ChangeNotifier { XadrezProvider({Random? random, Duration thinkTime = const Duration(milliseconds: 500), XadrezAiRunner? aiRunner}); }` getters `phase`, `mode`, `name1`, `name2`, `aiLevel`, `player1Side` (`ChessSide`), `game` (`ChessGame`), `selected`, `targets` (`Set<int>`), `lastMove`, `checkSquare` (`int?`: the king square of the side to move when in check), `pendingPromotion` (`(int from, int to)?`), `wins1`, `wins2`, `draws`, `aiThinking`, `isComputerTurn`, `flipped`, `winnerPlayer`, `currentPlayer`; methods `start(PlayerSetupResult)`, `tapSquare(int)`, `promote(int pieceType)` (2–5), `cancelPromotion()`, `playAgain()`, `exitToSetup()`, `@visibleForTesting startFrom(PlayerSetupResult, ChessPosition)`.
- Tapping a target that is a promotion sets `pendingPromotion` instead of moving; while it is set, `tapSquare` is ignored.

- [ ] **Step 1: Failing tests:** same list as Task 5 adapted (seleção, destinos, vez, computador, pretas começa com computador, toques ignorados, lance atrasado descartado, runner que falha, dispose, placar, exitToSetup), plus `roque pelos toques do rei`, `promoção espera a escolha`, `cancelar promoção não mexe no tabuleiro`, `checkSquare marca o rei em xeque`.
- [ ] **Step 2–4:** Run → FAIL, implement, pass.
- [ ] **Step 5:** Commit `feat(xadrez): add the game provider`.

### Task 11: Screen, board and promotion picker

**Files:**
- Create: `lib/games/xadrez/screens/game_screen.dart` (`XadrezScreen`), `lib/games/xadrez/widgets/board_view.dart` (`XadrezBoardView`), `lib/games/xadrez/widgets/chess_piece.dart` (`ChessPiece(value, size)`), `lib/games/xadrez/widgets/promotion_picker.dart`
- Test: `test/games/xadrez/game_screen_test.dart`

**Interfaces:**
- Squares `Key('sq-$index')`; promotion options `Key('promo-$pieceType')` plus a `'Cancelar'` button; picker shown over the board (inside a `Stack`) while `pendingPromotion != null`, title `'Promover para:'`.
- `ChessPiece`: glyph from U+2654–265F in `fontFamily: 'ChessSymbols'`; brancas = filled glyph (black set code point) in white with the outline glyph (white set code point) in black stacked on top; pretas = filled glyph in black.
- `PlayerSetup(title: 'Xadrez', emoji: '♟️', soloLabel: 'Contra o computador', symbols: ('⚪', '⚫'), levels: [...], sides: ('Brancas', 'Pretas'), soloOpponentName: 'Computador')`. Turn line adds `' • Xeque!'` when in check. Board colors are the builder's call (distinct from Damas); check square red; coordinates a–h on the bottom row and 1–8 on the left column (respecting flip). Result messages: `checkmate` → `'Xeque-mate!'`, `stalemate` → `'Afogamento'`, `insufficientMaterial` → `'Só sobraram peças que não dão mate'`, `fiftyMoves` → `'50 lances sem captura nem peão'`, `repetition` → `'A mesma posição 3 vezes'`. `confirmExit: phase == playing`.

- [ ] **Step 1: Failing tests** at both sizes: `dois jogadores: mate do louco pelos toques` (sq 53→45, 12→28, 54→38, 3→39; expect `'Xeque-mate!'` and `'Jogador 2 venceu!'`), `xeque mostra o aviso`, `promoção pelo seletor` (via `startFrom` with a pawn on the 7th), `cancelar promoção`, every result button and back, `com as pretas o computador começa e o tabuleiro vira`, `sem overflow em 320x568`.
- [ ] **Step 2–4:** Run → FAIL, implement, pass; `flutter analyze`.
- [ ] **Step 5:** Commit `feat(xadrez): add the setup, board and result screen`.

---

### Task 12: Menu, integration test, docs, gates

**Files:**
- Modify: `lib/screens/menu_screen.dart`, `test/screens/menu_screen_test.dart`, `integration_test/app_test.dart`, `CLAUDE.md`

- [ ] **Step 1:** Menu tests: `menu mostra os 11 jogos`, and Damas/Xadrez in the "abre pelo card e volta" table. Run → FAIL.
- [ ] **Step 2:** `_openDamas` / `_openXadrez` with `GameShell` + `ChangeNotifierProvider` + palette theme; cards `⚫ Damas` "Capture todas as peças do adversário!" tags `['Contra o computador', '2 jogadores']` and `♟️ Xadrez` "Dê xeque-mate no rei adversário!" same tags. Menu tests pass. Two commits: `feat(damas): add the Damas card to the menu`, then `feat(xadrez): add the Xadrez card to the menu`.
- [ ] **Step 3:** Integration tests: `Xadrez: mate do louco em dois jogadores e uma partida contra o computador` (fool's mate by taps; then solo Fácil: tap the first legal move's from/to read from the provider until a `ResultPanel` or 40 human moves, then back with confirmation) and `Damas: dois jogadores até o fim` (loop tapping each square of `p.game.legalMoves.first.path` until `ResultPanel`). Run `flutter test integration_test -d linux` → PASS. Commit `test: play Damas and Xadrez in the integration test`.
- [ ] **Step 4:** Update `CLAUDE.md` (eleven games, list `damas` and `xadrez`, `PlayerSetup` `sides`, the chess font). Commit `docs: describe Damas and Xadrez in CLAUDE.md`.
- [ ] **Step 5:** Gates: `flutter analyze` (no issues), `flutter test` (all pass), `flutter test --coverage && python3 tool/check_coverage.py` (pass). Fix and commit anything they flag.
