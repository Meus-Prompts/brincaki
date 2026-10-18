# Jogo de Contas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar o 9º jogo, "Contas" 🧮: contas das quatro operações em 3 níveis, com vidas, sequência que multiplica pontos e recorde salvo.

**Architecture:** Módulo `lib/games/contas/` no padrão dos outros jogos. O sorteio das contas e das opções são funções puras em `logic/`. Um `ContasProvider` guarda o estado e as regras, e o `RecordStore` cuida do `shared_preferences`. A tela usa `GameScaffold`, `ResultPanel`, `SetupHeader`, `LevelPicker` e `StartButton`.

**Tech Stack:** Flutter 3.44, provider, google_fonts (Fredoka), shared_preferences, flutter_test, integration_test.

**Spec:** `docs/superpowers/specs/2026-10-18-jogo-contas-design.md`

## Global Constraints

- Textos, comentários e nomes de testes em pt-BR.
- Todo arquivo `.dart` novo começa com `// lib/...` ou `// test/...` (o próprio caminho).
- Fonte `GoogleFonts.fredoka`, sem internet.
- Paleta `kContasPalette`: accent `0xFF65A30D`, light `0xFF84CC16`, dark `0xFF3F6212`, background `0xFFF7FEE7`.
- 3 vidas, 10 pontos por acerto, multiplicador `min(1 + sequência ~/ 5, 5)` calculado antes de somar o acerto.
- Maior resposta possível: 1000, com até 4 dígitos no teclado.
- Recorde por operação + nível, compartilhado entre teclado e opções. Empatar não é recorde novo.
- Sair pela seta ou pelo "voltar" no meio da rodada não salva o recorde. ⏸ Parar salva.
- `flutter analyze` limpo, `flutter test` verde e `python3 tool/check_coverage.py` OK (≥ 90% por arquivo, ≥ 95% no total).
- Commits `feat(contas): ...` / `test(contas): ...` no branch `feat/jogo-contas`.

## Review Focus

1. **Sorteio que nunca acaba:** o "não repetir a conta anterior" não pode entrar em loop infinito, mesmo em faixas pequenas (ex.: tabuada do 1 com `1 × 1`). Teste com 2000 sorteios seguidos por operação e nível, comparando cada um com o anterior.
2. **Opções com respostas pequenas:** com resposta 0 ou 1 (subtração `5 − 5`, divisão `3 ÷ 3`), as 4 opções continuam distintas e ≥ 0. Teste com `Problem(Operation.subtraction, [5, 5])` e `Problem(Operation.division, [3, 3])`.
3. **Toques rápidos depois da rodada acabar:** tocar em dígito, ✓ ou opção em `mistake` ou `finished` não pode mudar pontos nem vidas. Isso fica coberto pelos testes de guarda de fase do provider.
4. **Recorde que chega depois:** o carregamento assíncrono termina depois de a criança já ter mudado a escolha ou começado a jogar. Nesse caso a escolha dela não é sobrescrita, e o provider não notifica depois do `dispose`. Testes com um `Completer` no store falso.
5. **Tela pequena:** em 320x568, o teclado inteiro e o cartão de erro com "Continuar" cabem sem overflow, e o painel de resultado aparece sem esconder a conta. Isso fica coberto pelo `game_screen_test` nos dois tamanhos.

---

### Task 1: Modelos e sorteio das contas

**Files:**
- Create: `lib/games/contas/models/game_state.dart`, `lib/games/contas/logic/problem.dart`
- Test: `test/games/contas/problem_test.dart`

**Interfaces:**
- Produces:
  - `enum ContasPhase { setup, playing, mistake, finished }`
  - `enum Operation { addition, subtraction, multiplication, division }`
  - `enum AnswerMode { keyboard, choices }`
  - `class Problem { const Problem(Operation operation, List<int> operands); Operation operation; List<int> operands; int get answer; String get text /* '7 × 8', '850 − 320 − 75' */; operator ==, hashCode }`
  - `String operationSymbol(Operation)` → `'+'`, `'−'`, `'×'`, `'÷'`
  - `Problem generateProblem(Operation op, int level, Random random, {Problem? avoid})` com `level` de 1 a 3
  - `List<int> generateChoices(Problem problem, Random random)`: 4 itens embaralhados

- [ ] **Step 1: Escrever os testes que falham.** Para cada `Operation × level` e 500 sorteios com `Random(seed)`:
  - Adição: no nível 1, 2 parcelas ≥ 1 e `answer` entre 2 e 100. No nível 2, 2 parcelas ≥ 1 e `answer` entre 101 e 1000. No nível 3, 3 parcelas ≥ 1 e `answer` ≤ 1000.
  - Subtração: no nível 1, `operands[0]` entre 2 e 100. Nos níveis 2 e 3, `operands[0]` entre 101 e 1000. No nível 3 são 3 parcelas. Toda parcela é ≥ 1 e `answer` ≥ 0.
  - Multiplicação: algum fator está em 1–5 no nível 1, em 6–10 no nível 2 e em 1–10 no nível 3, e o outro fator está em 1–10. Nos 500 sorteios do nível 2 aparecem as duas ordens.
  - Divisão: `operands[0] % operands[1] == 0` e o divisor fica em 1–5, 6–10 ou 1–10 conforme o nível. Quociente em 1–10.
  - Testes extras:
    - `Problem(Operation.multiplication, [7, 8]).text == '7 × 8'`;
    - `Problem(Operation.subtraction, [850, 320, 75]).answer == 455`;
    - 2000 sorteios encadeados com `avoid: anterior` nunca repetem a anterior (Review Focus 1);
    - `generateChoices` em 500 sorteios de cada combinação dá 4 itens, distintos, ≥ 0 e contendo `answer`;
    - os casos `[5, 5]` (subtração) e `[3, 3]` (divisão) também passam (Review Focus 2);
    - a tabuada vizinha aparece: para `Problem(multiplication, [7, 8])`, as opções erradas estão em `{48, 63, 49, 64, 55, 57, 72, 70, ...}` (aceite qualquer valor de `(a±1)×b`, `a×(b±1)` ou `answer±1..5`).
- [ ] **Step 2:** `flutter test test/games/contas/problem_test.dart`. Deve FALHAR (os arquivos não existem).
- [ ] **Step 3: Implementar o sorteio conforme a seção 2 da spec.**
  - Adição: sorteie o resultado `r` e reparta (`a` em `1..r-1`). No nível 3, use dois cortes distintos em `1..r-1`.
  - Subtração: sorteie `a` e depois `b` em `1..a` (no nível 3, `b + c ≤ a` com `b, c ≥ 1`, então `a ≥ 2`).
  - `avoid`: sorteie de novo até 20 vezes e, se não der, aceite a repetida. A tabuada do 1 com nível 1 tem 50 contas, então isso só importa nos testes.
  - Candidatos de `generateChoices`:
    - multiplicação: `(a±1)×b`, `a×(b±1)`, `answer±1`;
    - divisão: `answer±1`, `answer±2`;
    - adição e subtração: `answer±1`, `answer±10`, e `answer±100` se `answer > 100`.
  - Filtre `≥ 0`, `≠ answer` e distintos, embaralhe e pegue 3. Complete com `answer±1..±5` (e depois `answer+6...`) se faltar.
- [ ] **Step 4:** rodar o mesmo comando. Deve PASSAR.
- [ ] **Step 5:** commit `feat(contas): add problem generator and answer choices`.

### Task 2: Recordes e última escolha

**Files:**
- Create: `lib/games/contas/data/record_store.dart`
- Test: `test/games/contas/record_store_test.dart`

**Interfaces:**
- Consumes: `Operation`, `AnswerMode` (Task 1).
- Produces:
  - `class LastChoice { const LastChoice(this.operation, this.level, this.mode); ... }`
  - `abstract class RecordStore { Future<int> loadRecord(Operation op, int level); Future<void> saveRecord(Operation op, int level, int value); Future<LastChoice?> loadLastChoice(); Future<void> saveLastChoice(LastChoice choice); }`
  - `class SharedPrefsRecordStore implements RecordStore`. As chaves são `'contas_record_${op.name}_$level'` (int) e `'contas_last'` (String `'${op.name}|$level|${mode.name}'`).

- [ ] **Step 1: Testes.**
  - Sem nada salvo, o recorde é 0 e a última escolha é `null`.
  - Salvar e ler `(multiplication, 2, 230)` devolve 230, e `(addition, 2)` continua 0.
  - Os valores `'muito'`, `-10` e `true` valem 0.
  - Salvar e ler `LastChoice(division, 3, choices)` devolve a mesma escolha.
  - `'contas_last'` com `'x|2|keyboard'`, `'addition|7|keyboard'`, `'addition|2'`, `'addition|abc|keyboard'` ou `42` dá `null`.
- [ ] **Step 2:** `flutter test test/games/contas/record_store_test.dart`. Deve FALHAR.
- [ ] **Step 3:** implementar como o `lib/games/2048/data/high_score_store.dart` (`prefs.get` + checagem de tipo). Nível válido: 1 a 3.
- [ ] **Step 4:** deve PASSAR.
- [ ] **Step 5:** commit `feat(contas): save records per operation and level and the last choice`.

### Task 3: ContasProvider

**Files:**
- Create: `lib/games/contas/providers/game_provider.dart`
- Test: `test/games/contas/game_provider_test.dart` (com um `FakeRecordStore` em memória no próprio teste, que pode atrasar com `Completer` ou lançar erro)

**Interfaces:**
- Consumes: Task 1 e Task 2.
- Produces: `class ContasProvider extends ChangeNotifier` com `ContasProvider({RecordStore? store, Random? random})` e:
  - Constantes: `static const maxLives = 3, pointsPerHit = 10, streakStep = 5, maxMultiplier = 5, maxDigits = 4, maxLevel = 3`.
  - Getters:
    - `phase`, `operation`, `level`, `answerMode`;
    - `problem` (`Problem?`, null em `setup`), `choices` (`List<int>`, vazia no teclado), `typed` (`String`);
    - `lives`, `streak`, `bestStreak`, `score`, `multiplier`;
    - `lastPoints`, `correctCount` (aumenta a cada acerto e serve de chave da animação);
    - `isMilestone` (`streak > 0 && streak % streakStep == 0`);
    - `int record(Operation op, int level)`, `int get currentRecord`, `bool isNewRecord`, `bool endedByMistake`.
  - Métodos:
    - `select({Operation? operation, int? level, AnswerMode? mode})`, só em `setup`;
    - `start()`, só em `setup`;
    - `typeDigit(int d)`, `deleteDigit()` e `submit()`, só em `playing` e no modo teclado;
    - `choose(int value)`, só em `playing` e no modo opções;
    - `continueAfterMistake()`, só em `mistake`;
    - `stop()`, em `playing` ou `mistake`;
    - `playAgain()`, só em `finished`;
    - `exitToSetup()`, em `finished`.

- [ ] **Step 1: Testes** (com `Random(seed)` e lendo `p.problem!.answer`).
  - Começa em `setup`, com adição, nível 1 e teclado.
  - Depois de `select(...)`, `start()` vai para `playing` com `lives == 3`, `score == 0` e uma `problem` da operação e nível certos.
  - **Pontos:** 5 acertos seguidos dão `score == 50`. O 6º vale 20 (`lastPoints == 20`) e `multiplier` passa a 2 depois do 5º. Com 25 acertos o multiplicador fica em 5, e o 26º vale 50.
  - `isMilestone` é verdadeiro depois do 5º acerto e falso depois do 6º.
  - **Erro:** `lives == 2`, `streak == 0` e `phase == mistake`, com a `problem` ainda igual. Depois, `continueAfterMistake()` volta para `playing` com conta nova. `bestStreak` guarda o maior valor.
  - **3º erro:** `phase == finished` e `endedByMistake == true`.
  - **Recorde:**
    - com recorde salvo 0, terminar com 30 pontos chama `saveRecord(op, level, 30)` e deixa `isNewRecord == true`;
    - com recorde 30, terminar com 30 não salva e deixa `isNewRecord == false`;
    - `stop()` com 20 pontos salva e deixa `endedByMistake == false`;
    - `stop()` em `mistake` também termina.
  - **Teclado:**
    - `typeDigit` 1,2,3,4,5 resulta em `typed == '1234'`;
    - `typeDigit(0)` com o campo vazio resulta em `'0'`, e outro 0 continua `'0'`;
    - com `'0'`, digitar 5 resulta em `'5'`;
    - `deleteDigit` apaga o último;
    - `submit()` com o campo vazio não faz nada;
    - `typed` volta a `''` na conta seguinte.
  - **Opções:** no modo `choices`, `choices` tem 4 itens com a resposta. `choose(errada)` leva a `mistake`.
  - **Guardas** (Review Focus 3):
    - `typeDigit`, `submit` e `choose` em `mistake`/`finished` não mudam `score`, `lives` nem `typed`;
    - `choose` no modo teclado é ignorado, e `typeDigit` no modo opções também;
    - `start()` fora de `setup` é ignorado, assim como `select()`.
  - **Jogar de novo e Mudar nível:** `playAgain()` zera pontos, vidas e sequência com a mesma operação e nível. `exitToSetup()` volta para `setup` com `problem == null`.
  - **Carregamento** (Review Focus 4):
    - os recordes salvos aparecem em `record()` depois de `await pumpEventQueue()`, e a última escolha salva vira a seleção;
    - se `select()` acontece antes de a última escolha chegar, a seleção da criança fica;
    - `dispose()` antes do `Completer` completar não lança nem notifica;
    - um store que lança erro na leitura deixa tudo em 0, e um que lança na escrita não quebra a rodada;
    - `start()` chama `saveLastChoice` com a seleção.
- [ ] **Step 2:** `flutter test test/games/contas/game_provider_test.dart`. Deve FALHAR.
- [ ] **Step 3:** implementar.
  - Seguir o padrão do `Game2048Provider` (`_disposed`, `unawaited`, `try/catch` no load, `_safeSave`).
  - Os pontos do acerto são `pointsPerHit * multiplier` com o `multiplier` antes de incrementar `streak`.
  - Nova conta: `generateProblem(..., avoid: problem)`, e `generateChoices` no modo opções.
- [ ] **Step 4:** deve PASSAR.
- [ ] **Step 5:** commit `feat(contas): add game provider with lives, streak multiplier and records`.

### Task 4: Widgets de jogo

**Files:**
- Create: `lib/games/contas/widgets/status_bar.dart`, `number_pad.dart`, `choice_grid.dart`
- Modify: `lib/widgets/game_palette.dart` (adicionar `kContasPalette`)
- Test: `test/games/contas/widgets_test.dart`

**Interfaces:**
- Produces:
  - `StatusBar({required int lives, required int maxLives, required int streak, required int score, required int multiplier, required int maxMultiplier, required int streakStep})`
    - mostra `maxLives` ícones `Icons.favorite`, cheios ou vazios (`Key('vida-$i')`);
    - mostra `'🔥 $streak'` e `'⭐ $score'`;
    - mostra o texto `'×$m pontos · faltam $n para ×${m+1}'`, ou `'×$max pontos'` no máximo;
    - tem uma `LinearProgressIndicator` com `(streak % step) / step` (1.0 no máximo).
  - `NumberPad({required String typed, required ValueChanged<int> onDigit, required VoidCallback onDelete, required VoidCallback onSubmit})`
    - campo com `typed`;
    - teclas `Key('tecla-0')`..`Key('tecla-9')`, `Key('tecla-apagar')` e `Key('tecla-ok')` (desabilitada com `typed` vazio).
  - `ChoiceGrid({required List<int> choices, required ValueChanged<int> onChoose})`: grade 2×2 com `Key('opcao-$valor')`.
  - `kContasPalette` com os valores das Global Constraints.

- [ ] **Step 1: Testes.**
  - `StatusBar(lives: 2, ...)` mostra 2 corações cheios e 1 vazio, mais `'🔥 6'` e `'⭐ 140'`.
  - Com `streak 6` e `multiplier 2`, o texto é `'×2 pontos · faltam 4 para ×3'`.
  - Com `multiplier 5`, o texto é `'×5 pontos'`.
  - Tocar nas teclas chama os callbacks com o dígito certo. `tecla-ok` com `typed: ''` não chama `onSubmit`.
  - `ChoiceGrid` mostra 4 textos, e o toque chama `onChoose(valor)`.
- [ ] **Step 2:** rodar. Deve FALHAR.
- [ ] **Step 3:** implementar. Os widgets recebem valores e não leem o provider, porque assim os testes ficam simples. Teclas com altura ≥ 44 e Fredoka.
- [ ] **Step 4:** deve PASSAR.
- [ ] **Step 5:** commit `feat(contas): add status bar, number pad and choice grid`.

### Task 5: Tela do jogo

**Files:**
- Create: `lib/games/contas/screens/game_screen.dart` (`ContasScreen` + `_Setup`, `_GameBody`, `_Feedback`, `_Result` privados)
- Test: `test/games/contas/game_screen_test.dart` (helper `pumpGame` igual ao da forca, com `ContasProvider(store: FakeRecordStore, random: Random(7))`)

**Interfaces:**
- Consumes: Tasks 1–4.
- Produces: `ContasScreen` (`const`).

Textos fixos:
- **Início:**
  - título do AppBar `'Contas'`;
  - `SetupHeader(emoji: '🧮', title: 'Contas')`;
  - `LevelPicker` com label `'Operação'` e os rótulos `'+ Adição'`, `'− Subtração'`, `'× Multiplicação'`, `'÷ Divisão'`;
  - `LevelPicker` com label `'Nível'` e os rótulos `'1'`, `'2'`, `'3'`, mais a frase do nível da tabela da spec;
  - `LevelPicker` com label `'Responder com'` e os rótulos `'⌨️ Teclado'` e `'🔘 Opções'`;
  - `'🏆 Recorde: N'`;
  - `StartButton`.
- **Jogo:**
  - título `'Contas • Multiplicação 2'` (nomes: Adição, Subtração, Multiplicação, Divisão);
  - ação `IconButton(Icons.pause_rounded, tooltip: 'Parar')` em `playing` e `mistake`;
  - `confirmExit` em `playing` e `mistake`;
  - a conta como `'${problem.text} = ?'`. Em `mistake` e em `finished` com `endedByMistake`, ela vira `'${problem.text} = ${answer}'`;
  - aviso de acerto (`TweenAnimationBuilder` com `key: ValueKey(correctCount)`, que some sozinho): `'+$lastPoints'` e, se `isMilestone`, `'$streak seguidas! 🔥'` (mais `' Agora ×$multiplier'` se subiu, ou seja, `multiplier > 1 && streak ~/ 5 < maxMultiplier`);
  - cartão de erro: `'Quase!'`, `'A resposta certa é $answer'` e o botão `'Continuar'`.
- **Resultado:**
  - recorde novo: emoji `'🏆'`, título `'Novo recorde!'`;
  - senão: emoji `'🎯'`, título `'Fim de jogo!'`;
  - mensagem `'⭐ $score pontos · Recorde: $record\n🔥 Maior sequência: $bestStreak'`;
  - ações `'Jogar de novo'` (`playAgain`) e `'Mudar nível'` (`exitToSetup`, `primary: false`).

- [ ] **Step 1: Testes**, cada fluxo em 360x740 e 320x568, como no `test/games/forca/game_screen_test.dart`.
  - Início: os rótulos aparecem. Escolher `'× Multiplicação'` e `'2'` mostra `'Tabuada do 6 ao 10'` e `'🏆 Recorde: 0'`. "Jogar!" leva ao título `'Contas • Multiplicação 2'`.
  - Teclado:
    - digitar a resposta certa e tocar em ✓ aumenta os pontos (`'⭐ 10'`) e mostra uma conta nova;
    - digitar uma errada mostra `'Quase!'` e o `'Continuar'`, e o coração fica vazio;
    - "Continuar" volta ao teclado;
    - mais 2 erros mostram o `ResultPanel` `'Novo recorde!'` (10 pontos > 0), com a conta e a resposta ainda visíveis;
    - `'Jogar de novo'` deixa `'⭐ 0'` sem painel;
    - errar 3 vezes e tocar em `'Mudar nível'` volta ao início com `'🏆 Recorde: 10'`.
  - Opções: escolher `'🔘 Opções'`, tocar em `opcao-$answer` soma pontos, e tocar numa errada mostra `'Quase!'`.
  - Parar: em `playing`, o painel `'Fim de jogo!'` aparece com 0 pontos e "Parar" some. Em `mistake` também termina.
  - Sair: a seta em `playing` mostra `'Sair do jogo?'`. `'Continuar jogando'` fica no jogo, e `'Sair'` volta ao menu de teste. Na tela de início, a seta volta direto.
  - Comemoração: 5 acertos mostram `'5 seguidas! 🔥 Agora ×2'`.
  - Nenhum `tester.takeException()` nos dois tamanhos (Review Focus 5).
- [ ] **Step 2:** rodar. Deve FALHAR.
- [ ] **Step 3:** implementar.
  - O corpo do jogo é um `SingleChildScrollView` com `StatusBar`, a conta (`FittedBox`, fonte ~44) e embaixo `NumberPad`/`ChoiceGrid` em `playing`, `_Feedback` em `mistake` e nada em `finished`.
  - O `_Setup` guarda a seleção no provider (`select`), para o recorde e a frase acompanharem.
- [ ] **Step 4:** deve PASSAR, e `flutter analyze` deve ficar limpo.
- [ ] **Step 5:** commit `feat(contas): add setup, game and result screen`.

### Task 6: Menu, teste de integração e documentação

**Files:**
- Modify: `lib/screens/menu_screen.dart` (import, `_openContas`, cartão depois do Lig 4)
- Modify: `test/screens/menu_screen_test.dart` (lista dos 9 jogos e entrada `'Contas': find.text('Responder com')`)
- Modify: `integration_test/app_test.dart` (lista dos 9 jogos e teste novo)
- Modify: `CLAUDE.md` (nove jogos, incluindo `contas`; `contas` na lista do `solo_setup` fica como "tela própria")

**Interfaces:** consome `ContasScreen`, `ContasProvider` e `kContasPalette`.

- [ ] **Step 1: Testes.**
  - Menu: o teste `'menu mostra os 9 jogos'` inclui `'Contas'`. Abrir pelo cartão e voltar pela seta funciona, e o "voltar" do sistema também.
  - Integração `'Contas: acerta pelo teclado, erra 3 vezes e volta'`:
    - escolher `'× Multiplicação'`;
    - acertar 3 contas tocando as teclas dos dígitos de `p.problem!.answer` e depois `tecla-ok`;
    - errar 3 vezes (digitar `answer + 1` e tocar em "Continuar" entre os erros);
    - ver `inPanel('Novo recorde!')` e voltar ao menu.
- [ ] **Step 2:** `flutter test test/screens/menu_screen_test.dart`. Deve FALHAR.
- [ ] **Step 3:** adicionar `_openContas` e o cartão `🧮` `'Contas'`, `'Resolva as contas e bata o seu recorde!'`, `['+ − × ÷', '3 níveis']`, e atualizar o `CLAUDE.md`.
- [ ] **Step 4:** `flutter test` passa, `flutter test --coverage && python3 tool/check_coverage.py` termina em `OK`, `flutter analyze` mostra `No issues found!` e `flutter test integration_test -d linux` passa.
- [ ] **Step 5:** commit `feat(contas): add the Contas card to the menu` (com os testes e o CLAUDE.md).
