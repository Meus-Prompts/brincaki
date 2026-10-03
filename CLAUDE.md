# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Brincaki is a Flutter app made of casual games for kids (Dart package name `brincaki`). The UI text, comments, and test names are in Brazilian Portuguese. Keep new content in Portuguese too.

**This repository is incomplete.** It has no `pubspec.yaml`, `lib/main.dart`, or `analysis_options.yaml`. `lib/screens/menu_screen.dart` imports games that are not in the tree (`games/cacapalavras`, `games/sudoku`, `games/2048`). Only `tictactoe` and `forca` are here. As a result, `flutter` commands will fail in this checkout until the rest of the app is restored. Don't create stubs for the missing pieces unless asked.

Dependencies used in the code: `provider`, `google_fonts` (the Fredoka font everywhere), and `flutter_test`.

## Commands

These need the full Flutter project to be present:

```bash
flutter test                                        # all tests
flutter test test/games/forca/game_provider_test.dart   # single file
flutter test --plain-name 'começa no nível 1'        # single test by name
flutter analyze                                     # lint
flutter run --debug
```

## Architecture

**Each game is a self-contained module** under `lib/games/<game>/` with this layout:

- `models/game_state.dart`: enums only, such as the phase enum (`GamePhase` / `ForcaPhase`) and the cell or letter state enums.
- `providers/game_provider.dart`: a single `ChangeNotifier` that holds all game logic and state. It has private fields with getters, and every mutating method checks the current phase first (for example, `if (_phase != ForcaPhase.won) return;`).
- `screens/game_screen.dart`: the root screen. It picks what to show based on `provider.phase` and puts result overlays in a `Stack` or `Column`. Private sub-widgets (`_GameBody`, `_ResultOverlay`) live in the same file.
- `widgets/`: focused presentational widgets that read the provider through `context.watch` / `Consumer`.
- `data/` (optional): static content, such as `kWordsByLevel` for forca.

Each file starts with a `// lib/path/to/file.dart` comment.

**Menu integration** (`lib/screens/menu_screen.dart`): each game gets an `_open<Game>` method that pushes a route wrapping, from outside in:
`ChangeNotifierProvider(create: <Game>Provider)` → `Theme(<per-game ThemeData>)` → nested `Navigator`, whose `onGenerateRoute` builds the game screen.
The provider is scoped to that game's route, so state resets when the player leaves. There is no global provider in `main.dart`. The nested `Navigator` makes the game's dialogs and sub-routes inherit the game's theme and provider. Each game also gets a `_buildGameCard` entry that uses its own gradient color. Some provider files have the same class names, so import them with a prefix when that happens (`as forca`, `as cacapalavras`).

**Tests** live in `test/games/<game>/` and only unit-test the provider. There are no widget tests. Tests that depend on the randomly chosen word work out what to guess from `provider.currentWord` instead of fixing the random seed.

## Workflow

New games have followed the superpowers flow: a design spec goes in `docs/superpowers/specs/`, an implementation plan in `docs/superpowers/plans/`, and then the work is split into small commits with Conventional Commit messages scoped to the game, such as `feat(forca): ...` or `fix(tictactoe): ...`.
