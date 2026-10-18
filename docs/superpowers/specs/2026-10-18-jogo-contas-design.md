# Jogo de Contas: design

**Data:** 2026-10-18
**Projeto:** Brincaki
**Status:** Aprovado na conversa

---

## Objetivo

Um jogo novo, **Contas** 🧮, para a criança treinar as quatro operações: adição, subtração, multiplicação e divisão. A tabuada do 1 ao 10 cobre multiplicação e divisão. Adição e subtração vão até 1000.

A gamificação vem do Duolingo: vidas, sequência de acertos (o "foguinho") que multiplica os pontos, comemorações curtas e um recorde para bater. A criança volta para bater o próprio recorde.

**Critério de sucesso**
- o 9º cartão do menu abre o jogo;
- dá para jogar uma rodada inteira com cada operação, nível e forma de responder;
- o recorde fica salvo depois de fechar o app;
- `flutter analyze` sem avisos, `flutter test` verde e `tool/check_coverage.py` passando;
- `integration_test/app_test.dart` joga uma rodada de Contas pelo app de verdade.

**Fora do escopo desta versão:** cronômetro, sons e vibração, trilha de lições, conquistas e estatísticas além do recorde.

**Seria um fracasso se:** a criança pudesse chutar e ganhar sem pensar, aparecesse uma conta com resultado negativo ou uma divisão não exata, ou a tela não coubesse em 320x568.

## Restrições herdadas

Valem as regras do `CLAUDE.md`:
- textos em pt-BR;
- Fredoka empacotada;
- nada de internet;
- módulo em `lib/games/contas/`;
- provider criado pelo `GameShell` do menu;
- `GameScaffold` e `ResultPanel`;
- todo arquivo começa com o comentário do próprio caminho;
- testes nas telas de 360x740 e 320x568.

---

## 1. Regras do jogo

### Uma rodada
1. Na tela de início a criança escolhe a **operação**, o **nível** (1, 2 ou 3) e a forma de **responder** (teclado ou opções), e toca em "Jogar!".
2. Aparece uma conta por vez. Ela só passa para a próxima quando responde.
3. **Acerto:** soma pontos, a sequência sobe e a próxima conta aparece na hora (decisão minha). Um aviso animado curto mostra "+10" e, quando a sequência fecha um múltiplo de 5, "5 seguidas! 🔥".
4. **Erro:** perde 1 das **3 vidas**, a sequência volta a 0 e a tela mostra a resposta certa ("7 × 8 = 56") com o botão "Continuar".
5. A rodada acaba no **3º erro** ou quando a criança toca em **⏸ Parar** no topo. No 3º erro, a resposta certa continua visível acima do painel de resultado.
6. **Fim:** o `ResultPanel` mostra os pontos, o recorde (com "Novo recorde!" quando bate), a maior sequência da rodada e os botões "Jogar de novo" (mesma escolha) e "Mudar nível" (volta à tela de início).

A rodada não tem fim nem cronômetro. Os pontos de uma rodada encerrada com Parar também contam para o recorde.

**Decisões minhas, depois da revisão:**
- Sair pela seta ou pelo "voltar" do sistema no meio da rodada, confirmando "Sair do jogo?", **não** salva o recorde. O diálogo já avisa que "O progresso desta partida será perdido". Para guardar os pontos, a criança usa ⏸ Parar.
- ⏸ Parar funciona em `playing` e em `mistake`, sem pedir confirmação. Em `mistake`, a resposta certa continua visível acima do painel de resultado.
- Empatar com o recorde não conta como "Novo recorde!". Só passar dele.

### Pontos e sequência
- Cada acerto vale `10 × multiplicador`. O multiplicador sai da sequência **antes** do acerto: `1 + sequência ~/ 5`.
  - Acertos 1 a 5 seguidos valem 10, do 6º ao 10º valem 20, do 11º ao 15º valem 30, e assim por diante.
  - **Decisão minha:** o multiplicador para em ×5 (50 pontos por acerto), para os números não explodirem.
- Um erro zera a sequência e o multiplicador volta a ×1.
- O jogo guarda a maior sequência da rodada para mostrar no resultado.
- Comemoração quando a sequência chega a 5, 10, 15... O aviso diz "N seguidas! 🔥" e, se o multiplicador subiu, "Agora ×M".

### Recorde
- Um recorde por **operação + nível** (12 no total). Teclado e opções dividem o mesmo recorde.
- Ele é salvo no `shared_preferences` quando a rodada acaba, se os pontos passaram do recorde anterior.
- A tela de início mostra o recorde da combinação selecionada.
- O jogo lembra a última operação, nível e forma de responder (no `shared_preferences`) e abre a tela de início com eles marcados.

## 2. Contas por nível

| | Nível 1 | Nível 2 | Nível 3 |
|---|---|---|---|
| **Adição** | `a + b`, resultado de 2 a 100 | `a + b`, resultado de 101 a 1000 | `a + b + c`, resultado de 3 a 1000 |
| **Subtração** | `a − b`, `a` de 2 a 100 | `a − b`, `a` de 101 a 1000 | `a − b − c`, `a` de 101 a 1000 |
| **Multiplicação** | tabuada do 1 ao 5 | tabuada do 6 ao 10 | tabuada do 1 ao 10 |
| **Divisão** | divisor de 1 a 5 | divisor de 6 a 10 | divisor de 1 a 10 |

Regras de todos os níveis:
- Todo número da conta é **≥ 1**.
- Na **subtração** o resultado é **≥ 0** e cada parcela subtraída é ≥ 1.
- Na **multiplicação**, "tabuada do X" é `X × n` com `n` de 1 a 10. A ordem dos fatores é sorteada (`7 × 8` ou `8 × 7`).
- Na **divisão**, o divisor `d` e o quociente `q` (de 1 a 10) são sorteados, e a conta é `(d × q) ÷ d`. É sempre exata.
- A maior resposta possível é **1000**, então o teclado aceita até 4 dígitos.
- A mesma conta (mesmos números na mesma ordem) **não sai duas vezes seguidas**.

Frase curta que aparece embaixo do nível na tela de início:

| | 1 | 2 | 3 |
|---|---|---|---|
| Adição | Somas até 100 | Somas até 1000 | Três números até 1000 |
| Subtração | Números até 100 | Números até 1000 | Três números até 1000 |
| Multiplicação | Tabuada do 1 ao 5 | Tabuada do 6 ao 10 | Tabuada do 1 ao 10 |
| Divisão | Dividir por 1 a 5 | Dividir por 6 a 10 | Dividir por 1 a 10 |

**Sorteio (decisão minha):** os números saem uniformes dentro das faixas. Por exemplo, na adição nível 2 sorteia-se o resultado `r` entre 101 e 1000 e depois `a` entre 1 e `r−1`, com `b = r − a`. Na nível 3, sorteia-se `r` entre 3 e 1000 e ele é dividido em três parcelas ≥ 1. A subtração usa a mesma ideia: sorteia `a` e depois as parcelas que cabem nele.

## 3. Formas de responder

### Teclado
- Um teclado numérico na própria tela com 0–9, ⌫ apagar e ✓ confirmar. É grande e fácil de tocar.
- O campo da resposta mostra o que foi digitado, com até 4 dígitos. Depois disso os dígitos são ignorados. Zero à esquerda é ignorado ("0" sozinho é aceito).
- ✓ fica desabilitado com o campo vazio.

### Opções
- 4 botões em grade 2×2, com uma resposta certa e 3 erradas, em ordem sorteada.
- As erradas são **plausíveis**, todas diferentes entre si, diferentes da certa e ≥ 0:
  - **Multiplicação:** a tabuada vizinha (`(a±1) × b`, `a × (b±1)`) e ±1.
  - **Divisão:** quociente ±1 e ±2.
  - **Adição e subtração:** ±1, ±10 (erro de "vai um" ou "empresta um") e ±100 quando a resposta passa de 100.
  - Se faltarem candidatos válidos, o resto é completado com números próximos (±1 a ±5).
- Um toque já responde (sem confirmar).

## 4. Telas

Esboços aprovados na conversa (verde-limão, Fredoka):

**Início** (dentro do `GameScaffold`, título "Contas")
- `SetupHeader` com 🧮 e "Contas".
- **Operação:** 4 chips com símbolo e nome ("+ Adição", "− Subtração", "× Multiplicação", "÷ Divisão").
- **Nível:** chips 1, 2 e 3, com a frase do nível embaixo.
- **Responder com:** "⌨️ Teclado" ou "🔘 Opções".
- "🏆 Recorde: N" da combinação selecionada.
- `StartButton` ("Jogar!").
- O `SoloSetup` não serve porque só tem um seletor. Esta tela é própria do jogo e reaproveita `SetupHeader`, `LevelPicker` (os três seletores são chips) e `StartButton`.

**Jogo** (título "Contas • Multiplicação 2", por exemplo)
- Ação ⏸ "Parar" no AppBar.
- Faixa de status: ❤️ vidas (cheias e vazias), 🔥 sequência e ⭐ pontos.
- Barra de progresso até o próximo multiplicador, com o texto "×2 pontos · faltam 4 para ×3". No ×5 a barra fica cheia e o texto é só "×5 pontos".
- A conta grande, com o sinal `+ − × ÷` e "= ?".
- Embaixo, o teclado ou as opções. Depois de um erro, eles dão lugar a um cartão vermelho: "Quase! A resposta certa é 56", "7 × 8 = 56" e o botão "Continuar".
- Aviso animado de acerto e de comemoração sobre a conta.
- No fim da rodada, a conta (com a resposta certa, se acabou por erro) continua visível e o `ResultPanel` aparece embaixo.

**Seta de voltar:** pergunta "Sair do jogo?" (`confirmExit`) durante a rodada, ou seja, em `playing` e `mistake`. Na tela de início e no resultado, sai direto.

**Paleta** `kContasPalette` (verde-limão, cor que nenhum outro jogo usa):
- accent `0xFF65A30D`
- light `0xFF84CC16`
- dark `0xFF3F6212`
- background `0xFFF7FEE7`

O accent é o lime-600, para o texto branco nos botões ter contraste.

**Menu:** o cartão vem depois do Lig 4, com 🧮, "Contas", "Resolva as contas e bata o seu recorde!" e as tags `['+ − × ÷', '3 níveis']`.

## 5. Arquitetura

Segue o padrão do `CLAUDE.md`. Os nomes e assinaturas abaixo são a proposta. O construtor pode ajustar detalhes internos.

```
lib/games/contas/
  models/game_state.dart       enum ContasPhase { setup, playing, mistake, finished }
                               enum Operation { addition, subtraction, multiplication, division }
                               enum AnswerMode { keyboard, choices }
  logic/problem.dart           class Problem { List<int> operands; Operation op; int answer; String text }
                               Problem generateProblem(Operation, int level, Random, {Problem? avoid})
                               List<int> generateChoices(Problem, Random)  // 4, embaralhadas, contém answer
  data/record_store.dart       abstract RecordStore + SharedPrefsRecordStore
                               (recordes: chave 'contas_record_<op>_<nível>'; última escolha: 'contas_last')
  providers/game_provider.dart ContasProvider
  screens/game_screen.dart     ContasScreen (+ _Setup, _GameBody, _Result privados)
  widgets/status_bar.dart      vidas, sequência, pontos, barra do multiplicador
  widgets/number_pad.dart      teclado numérico
  widgets/choice_grid.dart     4 opções
```

**`ContasProvider({RecordStore? store, Random? random})`**
- Estado: `phase`, `operation`, `level`, `answerMode`, `problem`, `choices`, `typed` (o que foi digitado), `lives`, `streak`, `bestStreak`, `score`, `lastPoints`, `correctCount`, `record(op, level)`, `isNewRecord`.
- Métodos (cada um confere a fase primeiro):
  - `select(op, level, mode)` na tela de início;
  - `start()`;
  - `typeDigit(int)`, `deleteDigit()` e `submit()` para o teclado;
  - `choose(int)` para as opções;
  - `continueAfterMistake()`;
  - `stop()`;
  - `playAgain()`;
  - `exitToSetup()`.
- Carrega recordes e a última escolha de forma assíncrona no construtor, como o 2048 faz com `_loadBest`. Ignora valores inválidos, nunca notifica depois do `dispose` e, se a leitura falhar, segue com zeros.
- Salva o recorde no fim da rodada e a última escolha no `start()`, com `unawaited`. Uma falha ao salvar não quebra o jogo.
- `correctCount` serve de chave para o aviso animado de acerto na tela, então o provider não precisa de timers.

**Menu:** `_openContas` com `GameShell`, `ChangeNotifierProvider(create: (_) => ContasProvider())` e `kContasPalette.theme`.

## 6. Testes

- `test/games/contas/problem_test.dart`: para cada operação e nível, com muitas sementes, as faixas, resultado ≥ 0, divisão exata, `answer` correta, 3 parcelas no nível 3 de adição e subtração, sem repetir com `avoid`, e opções (4, distintas, ≥ 0, contendo a certa).
- `record_store_test.dart`: valores ausentes, inválidos e negativos, ida e volta, e última escolha estragada.
- `game_provider_test.dart`: pontos e multiplicador (incluindo o teto ×5), vidas, sequência e maior sequência, erro → `mistake` → continuar, 3º erro → `finished`, parar, recorde novo e não novo, "Jogar de novo" e "Mudar nível", guardas de fase, teclado (4 dígitos, zero à esquerda, apagar, vazio), `dispose` antes do carregamento e loja que falha.
- `widgets_test.dart`: teclado, opções e faixa de status.
- `game_screen_test.dart`: o fluxo inteiro (início → jogo → acerto → erro → continuar → fim → cada botão → voltar) com teclado e com opções, em 360x740 e 320x568, mais o diálogo "Sair do jogo?" e o Parar.
- `test/screens/menu_screen_test.dart`: o cartão novo abre o jogo.
- `integration_test/app_test.dart`: abre Contas pelo menu, acerta algumas contas tocando no teclado (lendo `provider.problem.answer`), erra 3 vezes, vê o painel e volta.

## 7. Fluxo de trabalho

Plano em `docs/superpowers/plans/2026-10-18-jogo-contas.md` e commits pequenos `feat(contas): ...` / `test(contas): ...` num branch próprio.
