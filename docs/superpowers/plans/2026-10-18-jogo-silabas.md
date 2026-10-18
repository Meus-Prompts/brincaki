# Jogo das Sílabas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A new one-player game, Sílabas, where a child (8–9 years) splits 10 words into syllables, taps the stressed syllable and classifies it as oxítona/paroxítona/proparoxítona, retrying each step until right, with points at the end.

**Architecture:** Module `lib/games/silabas/` following the Forca pattern: a pure `parseWord` in `logic/word.dart` turns a hand-written encoded word (`'PÁS-sa-ro'`) into a `SilabasWord`; a curated list in `data/word_list.dart` guarded by a strict structural test; one synchronous `ChangeNotifier` provider; three presentational widgets; a screen on `GameScaffold` + `SoloSetup` + `ResultPanel`; then the menu card and integration test.

**Tech Stack:** Flutter/Dart, `provider`, `google_fonts` (bundled Fredoka), `flutter_test`, `integration_test`.

**Spec:** `docs/superpowers/specs/2026-10-18-jogo-silabas-design.md`

## Global Constraints

- All UI text, comments and test names in Brazilian Portuguese.
- Every file starts with a `// lib/path/to/file.dart` (or `// test/...`, `// integration_test/...`) comment.
- No internet at runtime; Fredoka via `GoogleFonts.fredoka` (bundled).
- Provider: private fields + getters; every mutating method checks phase (and step) first and returns silently otherwise; injectable `Random`; no timers, no async.
- Widget tests at 360x740 and 320x568.
- `flutter analyze` clean; `flutter test` green; `flutter test --coverage && python3 tool/check_coverage.py` passes (≥90% per file, ≥95% total).
- Commits: Conventional Commits scoped `feat(silabas)` / `test(silabas)` / `docs(silabas)`; end messages with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Cut position = index of the letter the cut sits before, in `word.text` (1 … `text.length − 1`). Words are NFC, so one accented letter is one UTF-16 unit.
- Levels are indices: 0 = Fácil, 1 = Médio, 2 = Difícil.

## Review Focus

1. Toggling cuts after a failed "Conferir" must clear all red marks and the hint, and a later correct split must still be accepted (Task 3 test `tocar num corte limpa o vermelho e a dica`).
2. A double tap on the right stress syllable or class must not score twice nor skip a step (Task 3 test `toque repetido não pontua duas vezes`).
3. The longest word in the list (10 letters, 9 gaps) must lay out without overflow at 320x568 (Task 5 test `palavra mais longa cabe em 320x568`).
4. "Jogar de novo" must start a fresh set of 10 words with score 0 at the same level; "Mudar nível" must reopen the setup with that level marked (Task 5 screen test).
5. A word with a graphic accent outside the stressed syllable (typo like `'pas-SA-ro'`) must fail the list test (Task 2 test `acento gráfico só na tônica`).

---

### Task 1: Models and `parseWord`

**Files:**
- Create: `lib/games/silabas/models/game_state.dart`, `lib/games/silabas/logic/word.dart`
- Test: `test/games/silabas/word_test.dart`

**Interfaces:**
- Produces:
  - `enum SilabasPhase { setup, playing, finished }`
  - `enum SilabasStep { split, stress, classify, solved }`
  - `enum StressClass { oxitona, paroxitona, proparoxitona }`
  - `class SilabasWord { final List<String> syllables; final int stressIndex; String get text; StressClass get stressClass; Set<int> get cutPositions; }` (syllables lowercase; `text = syllables.join()`)
  - `SilabasWord parseWord(String encoded)` — throws `FormatException` on invalid input.
  - `String stressClassLabel(StressClass c)` → `'Oxítona'`, `'Paroxítona'`, `'Proparoxítona'`.
  - `String stressClassHint(StressClass c)` → `'a última é a mais forte'`, `'a penúltima é a mais forte'`, `'a antepenúltima é a mais forte'`.

- [ ] **Step 1: Write the failing tests** in `test/games/silabas/word_test.dart`:
  - `'PÁS-sa-ro'` → syllables `['pás','sa','ro']`, stressIndex 0, text `'pássaro'`, `proparoxitona`, cuts `{3, 5}`.
  - `'ja-NE-la'` → stressIndex 1, `paroxitona`, cuts `{2, 4}`.
  - `'ja-ca-RÉ'` → stressIndex 2, `oxitona`, text `'jacaré'`.
  - `'co-ra-ÇÃO'` → text `'coração'`, `oxitona`, cuts `{2, 4}`.
  - `parseWord` throws `FormatException` for: `'sapato'` (one syllable / no hyphen), `'sa-pa-to'` (no stress), `'SA-PA-to'` (two stressed), `'E-xer-ci-to'` (stress 4th from end), `'sa--to'` (empty syllable).
  - The three labels and three hints, exact strings above.
- [ ] **Step 2: Run** `flutter test test/games/silabas/word_test.dart` — FAIL (files missing).
- [ ] **Step 3: Implement.** A syllable is stressed when `s == s.toUpperCase() && s != s.toLowerCase()`; store lowercase. `stressClass` from `syllables.length - 1 - stressIndex` (0/1/2). `cutPositions` are cumulative syllable lengths except the last.
- [ ] **Step 4: Run** the test — PASS. `flutter analyze` clean.
- [ ] **Step 5: Commit** `feat(silabas): palavra codificada com sílabas e tônica`.

### Task 2: Word list and its guard test

**Files:**
- Create: `lib/games/silabas/data/word_list.dart`
- Test: `test/games/silabas/word_list_test.dart`

**Interfaces:**
- Consumes: `parseWord`, `SilabasWord`, `StressClass` (Task 1).
- Produces: `const Map<int, List<String>> kSilabasWordsByLevel` (keys 0, 1, 2; values encoded like `'PÁS-sa-ro'`).

- [ ] **Step 1: Write the guard test** `word_list_test.dart`. For every encoded word of every level (one `test` per rule, failing message lists the offending words):
  - `parseWord` succeeds; the encoded string has no combining marks (U+0300–U+036F) — `é NFC`.
  - text letters only from `abcdefghijklmnopqrstuvwxyzáéíóúâêôãõàç`.
  - syllable count: level 0 → 2–3, level 1 → 2–4, level 2 → 3–5; `text.length <= 10`.
  - no text repeated anywhere in the map.
  - each level ≥ 40 words and ≥ 8 of each `StressClass`.
  - `acento gráfico só na tônica`: every letter from `áéíóúâêôãõà` lies in the stressed syllable, and a word has at most one acute/circumflex.
  - `proparoxítona sempre tem acento`: each proparoxítona's stressed syllable has an acute or circumflex.
  - `oxítona terminada em a, e, o tem acento`: oxítonas whose text ends in `a, e, o, as, es, os` (2+ syllables) have an accent (acute, circumflex or til) in the stressed syllable; same for endings `em, ens`.
  - `sem ditongo crescente átono no fim`, the spec rule: reject if the last syllable is unstressed and (a) contains `i` or `u` followed by a vowel letter, or (b) is a single vowel and the previous syllable is unstressed and ends in `i` or `u`. (Exception to (a): `que`, `qui`, `gue`, `gui`, where the `u` is silent, are fine. `gua`/`quo` still count — `lín-gua` is rejected.)
- [ ] **Step 2: Write the list** in `word_list.dart`: ≥ 40 words per level (aim for ~45 to leave room for removals in Task 3), meeting the spec's level table (Fácil: simple CV syllables, many visible accents; Médio: rr/ss/sc/sç/xc split, ch/lh/nh/qu/gu kept, consonant clusters, closed syllables; Difícil: hiatos, falling diphthongs kept together, unaccented words with non-obvious stress), known to 8–9 year olds, no word with more than one school-accepted separation, no tilde outside the stressed syllable. Group by classification inside each level with a comment per group.
- [ ] **Step 3: Run** `flutter test test/games/silabas/word_list_test.dart` — PASS; fix words, never loosen the rules.
- [ ] **Step 4: Commit** `feat(silabas): lista de palavras por nível`.

### Task 3: Independent linguistic review of the list

**Files:**
- Modify: `lib/games/silabas/data/word_list.dart`

This task is a review by a fresh agent on the most capable model, who reads every word against the school norm (Acordo Ortográfico, VOLP/ABL): separation, stressed syllable, classification, the "only one accepted separation" rule, and fit for 8–9 year olds and the level. Every word judged wrong or doubtful is corrected or removed (adding replacements if a count would drop below the guard test's minimums).

- [ ] **Step 1:** Review word by word; record each change with its reason in the report.
- [ ] **Step 2: Run** `flutter test test/games/silabas/` — PASS.
- [ ] **Step 3: Commit** `fix(silabas): revisão da separação e da tônica na lista`.

### Task 4: `SilabasProvider`

**Files:**
- Create: `lib/games/silabas/providers/game_provider.dart`
- Test: `test/games/silabas/game_provider_test.dart`

**Interfaces:**
- Consumes: Tasks 1–2.
- Produces `class SilabasProvider extends ChangeNotifier`:
  - `SilabasProvider({Random? random, Map<int, List<String>>? words})` — `words` defaults to `kSilabasWordsByLevel` (injectable so tests can pin small lists).
  - `static const int wordsPerGame = 10; static const List<String> levelNames = ['Fácil', 'Médio', 'Difícil'];`
  - getters: `phase`, `level` (int 0–2, default 0), `index` (0–9), `word` (`SilabasWord?`, null in setup), `step`, `score`, `wordPoints`, `cuts`, `wrongCuts` (unmodifiable `Set<int>`), `missingHint` (`int?`), `wrongStress` (`Set<int>`), `wrongClasses` (`Set<StressClass>`), `isLastWord` (`index == wordsPerGame - 1`), `stars` (3 if `score >= 270`, 2 if `>= 180`, else 1).
  - methods: `start(int level)`, `toggleCut(int pos)`, `checkSplit()`, `chooseStress(int i)`, `chooseClass(StressClass c)`, `nextWord()`, `playAgain()`, `exitToSetup()`.
- Points per step: `10` with 0 errors in that step, `5` with 1, `2` with 2+. Each successful step adds to both `score` and `wordPoints`; `wordPoints` resets on each new word.

- [ ] **Step 1: Write failing tests** (inject `Random(seed)` and, where exactness matters, `words:` with a tiny list):
  - `start` from setup: phase `playing`, step `split`, index 0, score 0; 10 distinct words from that level; `start` with level outside 0–2 ignored.
  - `toggleCut` on/off; positions outside 1…`text.length−1` ignored; only in step `split`.
  - `checkSplit` with no cuts does nothing (no error counted).
  - wrong cut → `wrongCuts` holds it, `missingHint` null if nothing missing; missing cut → `missingHint == syllables.length`, `wrongCuts` empty; both at once; each failed check counts one error.
  - `tocar num corte limpa o vermelho e a dica`: after a failed check, `toggleCut` clears `wrongCuts` and `missingHint`; correcting then checking → step `stress`.
  - stress wrong → added to `wrongStress`, same step; tapping an index already in `wrongStress` does nothing; right → step `classify`.
  - class wrong → `wrongClasses`; right → step `solved`.
  - points: 0/1/2/3 errors give 10/5/2/2 for a step; a perfect word gives `wordPoints == 30`.
  - `toque repetido não pontua duas vezes`: calling `chooseStress(right)` twice and `chooseClass(right)` twice keeps score at the same value.
  - `nextWord` only in `solved`; advances index, resets step state and `wordPoints`; on the 10th → `finished`.
  - `stars` at 300, 270, 269, 180, 179.
  - `playAgain` only from `finished`: same level, score 0, index 0, new 10 words; `exitToSetup` from playing/finished → setup, `level` kept; from setup ignored.
  - guards: every method ignored in the wrong phase/step (no notify, no state change).
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement.** Draw: copy the level list, `shuffle(_random)`, take 10, `parseWord` each.
- [ ] **Step 4: Run** — PASS; `flutter analyze` clean.
- [ ] **Step 5: Commit** `feat(silabas): provider com as três etapas e a pontuação`.

### Task 5: Palette, widgets and screen

**Files:**
- Modify: `lib/widgets/game_palette.dart` (add `kSilabasPalette`: accent `0xFF0891B2`, light `0xFF22D3EE`, dark `0xFF155E75`, background `0xFFECFEFF`)
- Create: `lib/games/silabas/widgets/split_word.dart`, `lib/games/silabas/widgets/syllable_blocks.dart`, `lib/games/silabas/widgets/classify_buttons.dart`, `lib/games/silabas/screens/game_screen.dart`
- Test: `test/games/silabas/widgets_test.dart`, `test/games/silabas/game_screen_test.dart`

**Interfaces:**
- Consumes: Tasks 1, 4.
- Produces:
  - `SplitWord({required GamePalette palette, required String text, required Set<int> cuts, required Set<int> wrongCuts, ValueChanged<int>? onToggle})` — gap widgets keyed `Key('corte-$pos')`, each ≥ 24 px wide and as tall as the letters; letters shrink to fit the width (gaps keep 24 px); cut = accent bar, wrong cut = red `0xFFDC2626` bar.
  - `SyllableBlocks({required GamePalette palette, required List<String> syllables, int? highlighted, Set<int> wrong = const {}, ValueChanged<int>? onTap})` — blocks keyed `Key('silaba-$i')`; highlighted = filled accent with white text; wrong = red border/text and not tappable; null `onTap` = not tappable.
  - `ClassifyButtons({required GamePalette palette, Set<StressClass> wrong = const {}, StressClass? correct, ValueChanged<StressClass>? onChoose})` — buttons keyed `Key('classe-${c.name}')`, label `stressClassLabel(c)` with `stressClassHint(c)` below; wrong = red and disabled; correct = green `0xFF16A34A`.
  - `SilabasScreen` (const, reads `SilabasProvider`).
- Screen copy (exact): AppBar `'Sílabas'` in setup, `'Sílabas • ${levelNames[level]}'` in game; `SoloSetup(title: 'Sílabas', emoji: '🔤', levels: levelNames, initialLevel: level)`; status `'Palavra ${index + 1} de 10'` and `'⭐ $score'`; step instructions `'Toque entre as letras para separar as sílabas'`, `'Qual é a sílaba mais forte?'`, `'Como ela se chama?'`; button `'Conferir'` (disabled with no cuts); errors `'Os cortes em vermelho estão no lugar errado'`, `'A palavra tem N sílabas'`, `'Essa não é a mais forte. Tente de novo!'` (while `wrongStress` non-empty in step stress), `'Quase! Conte as sílabas de trás para frente.'` (while `wrongClasses` non-empty in step classify); solved card: syllables joined with `' · '` with stressed one highlighted (use `SyllableBlocks` with `highlighted`), the label, `'+$wordPoints'`, and button `'Próxima palavra'` or `'Ver resultado'` when `isLastWord`. `confirmExit: phase == playing`. Result: `ResultPanel(emoji: '🏆', title: 'Mandou muito!'/'Muito bem!'/'Boa tentativa!' by stars, message: '$score pontos de 300\n' + '⭐' * stars, actions: [ResultAction('Jogar de novo', playAgain), ResultAction('Mudar nível', exitToSetup, primary: false)])`; the last solved word stays visible above it.

- [ ] **Step 1: Write failing widget tests** (`widgets_test.dart`): each widget's taps call back with the right value; wrong/highlight/correct states render with the colors above; null callbacks make taps no-ops.
- [ ] **Step 2: Write failing screen tests** (`game_screen_test.dart`, pumped like `test/games/forca/game_screen_test.dart` via `GameShell` and a `MaterialPageRoute`), at 360x740 and 320x568: setup → pick "Médio" → "Jogar!" → wrong cut shows red message → fix → stress wrong message → right → class wrong message → right → solved card with `+N` → "Próxima palavra" … through 10 words (read `provider.word` for answers) → "Ver resultado" → panel title/stars → "Jogar de novo" (score 0, word 1) → finish again → "Mudar nível" shows setup with "Médio" marked → back arrow to menu; "Sair do jogo?" dialog during play (cancel stays, confirm leaves). `palavra mais longa cabe em 320x568`: inject `words:` with the longest word of `kSilabasWordsByLevel` in all levels and assert no exceptions (`tester.takeException()` null) through all three steps.
- [ ] **Step 3: Implement** palette, widgets, screen.
- [ ] **Step 4: Run** `flutter test test/games/silabas/` — PASS; `flutter analyze` clean.
- [ ] **Step 5: Commit** `feat(silabas): tela do jogo com as três etapas`.

### Task 6: Menu, integration test and docs

**Files:**
- Modify: `lib/screens/menu_screen.dart`, `test/screens/menu_screen_test.dart`, `integration_test/app_test.dart`, `CLAUDE.md`

- [ ] **Step 1:** Menu: `_openSilabas` (GameShell, `ChangeNotifierProvider(create: (_) => SilabasProvider())`, `kSilabasPalette.theme`, `SilabasScreen`) and a card after Xadrez: emoji `'🔤'`, title `'Sílabas'`, description `'Separe as sílabas e ache a mais forte!'`, tags `['Português', '3 níveis']`.
- [ ] **Step 2:** Menu test: add `'Sílabas'` to the titles list and `'Sílabas': find.text('Nível')` to the open-and-back map. Run — PASS.
- [ ] **Step 3:** Integration test `'Sílabas: joga as 10 palavras, erra uma vez e volta'`: open from menu, "Jogar!", for each word tap the right gaps (`corte-$pos` from `provider.word.cutPositions`) and "Conferir", the stressed block, the right class; on the first word first tap one wrong class; "Próxima palavra"/"Ver resultado"; expect the panel; back to menu. Run `flutter test integration_test -d linux` — PASS.
- [ ] **Step 4:** `CLAUDE.md`: "Twelve games", add `silabas` (syllables, stressed syllable and its classification) to the list, and mention Sílabas among the `SoloSetup` users.
- [ ] **Step 5:** Full gate: `flutter analyze`, `flutter test`, `flutter test --coverage && python3 tool/check_coverage.py`.
- [ ] **Step 6: Commit** `feat(silabas): cartão no menu e teste de integração`.
