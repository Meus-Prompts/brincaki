# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Brincaki is a Flutter app made of casual games for kids (Dart package name `brincaki`). The UI text, comments, and test names are in Brazilian Portuguese. Keep new content in Portuguese too.

Eleven games live under `lib/games/`: `cacapalavras`, `sudoku`, `2048`, `tictactoe` (Jogo da Velha), `forca`, `memoria`, `termo`, `lig4`, `contas` (math drills with lives, a streak multiplier and saved records), `damas` (checkers, mandatory and majority capture, flying kings) and `xadrez` (chess with full rules, promotion picker and a computer opponent).

Dependencies used in the code: `provider`, `google_fonts` (the Fredoka font everywhere, bundled in `assets/google_fonts/`, never fetched at runtime), `shared_preferences`, `flutter_test` and `integration_test`. The chess piece glyphs use the bundled `ChessSymbols` font in `assets/fonts/` (Noto Sans Symbols 2 subset, OFL).

## Commands

```bash
flutter test                                        # unit + widget tests
flutter test test/games/forca/game_provider_test.dart   # single file
flutter test --plain-name 'começa no nível 1'        # single test by name
flutter test --coverage && python3 tool/check_coverage.py   # coverage gate
flutter test integration_test -d linux              # real app (needs clang + ninja-build)
flutter analyze                                     # lint
flutter run --debug
```

`tool/check_coverage.py` fails if any file in `lib/` with executable code is below 90% line coverage or the total is below 95%. Keep it passing.

## Architecture

**Shared widgets** (`lib/widgets/`) give every game the same look:

- `game_palette.dart`: one `GamePalette` per game (`accent`, `light`, `dark`, `background`, plus `theme`). The menu card and the game screen both use it.
- `game_scaffold.dart`: `GameScaffold` is the root of every game screen. It has the AppBar with the "Voltar ao menu" arrow (pops the root navigator), an optional `result` slot under the body, and `confirmExit` to ask "Sair do jogo?" mid-game.
- `result_panel.dart`: `ResultPanel` is the end-of-game card at the bottom, so the final board stays visible. Standard button labels: "Jogar de novo", "Próximo nível", "Trocar jogadores", "Mudar nível".
- `player_setup.dart` (games with "Contra o computador"/"Sozinho" and "Dois jogadores": Velha, Lig 4, Memória, Damas, Xadrez; its optional `sides` adds a color picker, e.g. Brancas/Pretas, used by Damas and Xadrez) and `solo_setup.dart` (one-player games with a level: Forca, Caça-Palavras, Sudoku). Both use `level_picker.dart` and `setup_header.dart`. 2048 and Termo have no setup screen. Contas has its own setup (operation, level and answer mode) built from `LevelPicker`, `SetupHeader` and `StartButton`.
- `score_board.dart` for two-player scores, and `game_shell.dart` (see below).

**Each game is a self-contained module** under `lib/games/<game>/`:

- `models/game_state.dart`: enums only, such as the phase enum (`setup`/`playing`/finished states) and cell or letter state enums.
- `providers/game_provider.dart`: a single `ChangeNotifier` that holds all game logic and state. It has private fields with getters, and every mutating method checks the current phase first (for example, `if (_phase != ForcaPhase.won) return;`). Computer opponents (Velha, Lig 4, Damas, Xadrez) take an injectable think time and AI runner, discard late moves with a game id, and never notify after `dispose`.
- `logic/` (optional): pure functions such as board rules and AI (`chooseMove`/`chooseColumn` with `easy`/`medium`/`hard`).
- `screens/game_screen.dart`: the root screen, built on `GameScaffold`. It picks what to show based on `provider.phase`. Private sub-widgets live in the same file.
- `widgets/`: focused presentational widgets that read the provider through `context.watch` / `Consumer`.
- `data/` (optional): static content and persistence, such as `kWordsByLevel` for forca.

Each file starts with a `// lib/path/to/file.dart` comment.

**Menu integration** (`lib/screens/menu_screen.dart`): each game gets an `_open<Game>` method that pushes a `GameShell` with `wrapProvider` (the game's `ChangeNotifierProvider`), `theme: k<Game>Palette.theme` and `home` (the game screen). `GameShell` adds a nested `Navigator`, so dialogs and sub-routes inherit the game's theme and provider, and the provider is scoped to that route, so state resets when the player leaves. There is no global provider in `main.dart`. Each game also gets a `_buildGameCard` entry with its palette. Some provider files have the same class names, so import them with a prefix when that happens (`as forca`, `as cacapalavras`).

## Tests

- `test/games/<game>/`: unit tests for the logic and provider, plus `game_screen_test.dart` widget tests of the full flow (setup → game → result → every result button → back), run at 360x740 and 320x568.
- `test/widgets/`, `test/screens/`: the shared widgets and the menu.
- `integration_test/app_test.dart`: the real app. Each test opens a game from the menu, plays it to the result panel by tapping and returns.
- Tests that depend on randomness read the state from the provider (`provider.currentWord`, `provider.cards`, `board.solution`) or inject `Random(seed)` instead of fixing a global seed.

## Workflow

New games and larger changes follow the superpowers flow: a design spec goes in `docs/superpowers/specs/`, an implementation plan in `docs/superpowers/plans/`, and then the work is split into small commits with Conventional Commit messages scoped to the game, such as `feat(forca): ...` or `fix(tictactoe): ...`.
