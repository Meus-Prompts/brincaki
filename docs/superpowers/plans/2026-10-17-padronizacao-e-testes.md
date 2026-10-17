# Padronização dos jogos e testes completos — plano

Spec: `docs/superpowers/specs/2026-10-17-padronizacao-e-testes-design.md`
Branch: `padronizacao-jogos`

## Fase A — base compartilhada (sequencial)

1. `tool/check_coverage.py`: lê `coverage/lcov.info`, falha se algum arquivo
   de `lib/` com código ficar abaixo de 90% ou o total abaixo de 95%.
2. `lib/widgets/game_palette.dart` com as 8 paletas + testes.
3. `lib/widgets/game_scaffold.dart` (voltar, `confirmExit`, `result`) + testes.
4. `lib/widgets/result_panel.dart` + testes.
5. `lib/widgets/level_picker.dart`, `lib/widgets/solo_setup.dart`;
   `PlayerSetup` passa a usar o `LevelPicker` + testes.
6. Menu usa as paletas (cartões e temas) + testes do menu.
7. Commit: `feat: add shared GameScaffold, ResultPanel, SoloSetup and palettes`.

## Fase B — um jogo por vez, em paralelo (worktrees)

Cada tarefa: migrar para os componentes comuns, testes unitários e de widget
exaustivos, cobertura ≥ 90% em cada arquivo do jogo, `flutter analyze` limpo,
commits pequenos `feat(<jogo>)` / `test(<jogo>)`.

- B1 Jogo da Velha: lógica, IA de 3 níveis, provider no modelo do Lig 4, tela.
- B2 Forca: setup de nível, `GameScaffold`, `ResultPanel`.
- B3 Sudoku: tela única, tema claro, setup, `confirmExit`, `ResultPanel`.
- B4 Caça-Palavras: provider no `GameShell`, setup de nível, `ResultPanel`.
- B5 2048 e Termo: `GameScaffold`, `ResultPanel`.
- B6 Lig 4 e Memória: `GameScaffold`, `ResultPanel`, nível inicial da Memória.

## Fase C — integração e verificação (sequencial)

1. Juntar os branches da fase B; ajustar o menu (`_open<Jogo>`).
2. `integration_test` no `pubspec.yaml`; `integration_test/app_test.dart`
   com um teste por jogo pelo app real.
3. Atualizar `CLAUDE.md` (repositório completo, tipos de teste, componentes).
4. Verificação final: `flutter analyze`, `flutter test --coverage`,
   `python3 tool/check_coverage.py`, `flutter test integration_test -d linux`.
