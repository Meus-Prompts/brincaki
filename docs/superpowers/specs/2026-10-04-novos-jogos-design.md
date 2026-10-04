# Novos Jogos (Memória, Termo, Lig 4) — Design Spec

**Date:** 2026-10-04
**Project:** Brincaki
**Status:** Aguardando revisão

---

## Objetivo

Adicionar três jogos ao Brincaki, para ampliar o público do app:
- **Jogo da Memória**, pensado para os mais novos;
- **Termo**, em português, pensado para os adultos;
- **Lig 4**, para dois jogadores ou contra o computador.

Cada jogo ganha um card no menu e segue o mesmo padrão dos atuais: módulo em `lib/games/<jogo>/`, provider próprio, aberto pelo `GameShell` e com testes.

**Critério de sucesso:**
- os 3 cards abrem os seus jogos;
- os 3 jogos são jogáveis do começo ao fim;
- o "voltar" sempre leva ao menu;
- `flutter analyze` sem avisos e `flutter test` verde;
- nada usa internet em tempo de execução.

## Restrições herdadas

Continuam valendo:
- sem internet e sem anúncios;
- app só na vertical;
- Fredoka empacotada (`GoogleFonts.fredoka`);
- textos em pt-BR;
- cada provider criado pelo `GameShell` do menu;
- setas "voltar" da primeira tela de cada jogo com `Navigator.of(context, rootNavigator: true).pop()` e `tooltip: 'Voltar ao menu'`;
- todo arquivo `.dart` novo começa com o comentário do próprio caminho.

## Decisões

| Tema | Decisão |
|------|---------|
| Memória | Sozinho com 5 níveis, ou dois jogadores alternando com placar |
| Termo | Palavra do dia + modo ilimitado; tentativas validadas num dicionário |
| Dicionário | [fserb/pt-br](https://github.com/fserb/pt-br) (licença MIT), filtrado por um script e incluído no app |
| Lig 4 | Dois jogadores ou contra o computador, com níveis Fácil, Médio e Difícil |
| Código compartilhado | Tela de configuração e placar novos em `lib/widgets/`, usados pela Memória e pelo Lig 4. O Jogo da Velha não muda. |
| Persistência | Só o estado da palavra do dia do Termo. Os placares zeram ao sair. |

---

## 1. Componentes compartilhados

### `lib/widgets/player_setup.dart`

```dart
enum PlayMode { solo, twoPlayers }   // solo = "Sozinho" ou "Contra o computador"

class PlayerSetupResult {
  final PlayMode mode;
  final String player1;      // nunca vazio: padrão "Jogador 1"
  final String player2;      // "Jogador 2" ou "Computador" (no solo do Lig 4); vazio no solo da Memória
  final int? levelIndex;     // índice em `levels`, se houver
}

class PlayerSetup extends StatefulWidget {
  final String title;                 // "Jogo da Memória"
  final String emoji;                 // "🧠"
  final Color accent;
  final String soloLabel;             // "Sozinho" | "Contra o computador"
  final (String, String) symbols;     // ('🐶', '🐱') | ('🔴', '🟡')
  final List<String>? levels;         // ['Fácil', 'Médio', 'Difícil'], mostrado só no modo solo
  final String? soloOpponentName;     // 'Computador' no Lig 4; null na Memória
  final ValueChanged<PlayerSetupResult> onStart;
}
```

- Uma escolha segmentada no topo, entre o modo solo e "Dois jogadores".
- **Solo:** um campo de nome e, se houver `levels`, a escolha do nível (o padrão é o primeiro).
- **Dois jogadores:** dois campos de nome, cada um com o seu símbolo.
- O nome é opcional. Se ficar vazio, vale "Jogador 1" ou "Jogador 2", e o nome é limitado a 12 caracteres.
- O botão "Jogar!" está sempre habilitado.
- O widget não lê nenhum provider.

### `lib/widgets/score_board.dart`

```dart
class ScoreBoard extends StatelessWidget {
  final String name1, name2;
  final String symbol1, symbol2;
  final int score1, score2, draws;
  final int? activePlayer;   // 1, 2 ou null
  final Color accent;
}
```

- O visual segue o `ScoreBanner` do Jogo da Velha, com 🤝 e o número de empates no centro.
- O jogador ativo fica destacado com o fundo `accent` em 15% de opacidade.
- Os nomes longos são cortados com reticências.

### Menu

Três cards novos, depois do Jogo da Forca, com `_open*` usando o `GameShell`:

| Jogo | Emoji | Gradiente | Tags | Tema (`colorSchemeSeed`) |
|---|---|---|---|---|
| Jogo da Memória | 🧠 | `#8B5CF6` → `#A78BFA` | "1 ou 2 jogadores", "Níveis" | `#8B5CF6` |
| Termo | 🟩 | `#14B8A6` → `#2DD4BF` | "Palavra do dia", "Português" | `#14B8A6` |
| Lig 4 | 🔴 | `#EF4444` → `#F87171` | "Contra o computador", "2 jogadores" | `#EF4444` |

Todos usam `textTheme: GoogleFonts.fredokaTextTheme()` e `useMaterial3: true`.

O `test/screens/menu_screen_test.dart` passa a cobrir os 8 jogos, nos dois testes de "voltar": pela seta e pelo sistema.

---

## 2. Jogo da Memória (`lib/games/memoria/`)

### Modelos (`models/game_state.dart`)

```dart
enum MemoryPhase { setup, playing, finished }

class MemoryCard {
  final int id;          // posição na grade
  final String emoji;
  final bool faceUp;
  final bool matched;
}
```

### Dados

- `data/emojis.dart` tem `kMemoryEmojis`, com pelo menos 18 emojis distintos e fáceis de reconhecer: animais, frutas e objetos.
- `data/levels.dart` define os níveis e as grades:

```dart
class MemoryLevel { final int rows, cols; int get pairs => rows * cols ~/ 2; }
const kSoloLevels = [ (3×4), (4×4), (4×5), (5×6), (6×6) ];      // 6, 8, 10, 15, 18 pares
const kDuoSizes   = {'Pequena': (3×4), 'Média': (4×5), 'Grande': (6×6)};
```

### Provider (`providers/game_provider.dart`, `MemoryProvider({Random? random})`)

- Estado:
  - `phase`, `mode`, nomes, `level` (no solo) e `duoSize` (em dois jogadores);
  - `cards`, `currentPlayer` (1 ou 2), `pairs1`, `pairs2`, `moves`;
  - o placar de partidas (`wins1`, `wins2`, `draws`);
  - `waitingToHide` (bool), verdadeiro enquanto duas cartas erradas estão à mostra.
- `start(PlayerSetupResult)`: guarda o modo e os nomes e começa o nível 1 (solo) ou a grade "Média" (em dois). Em dois jogadores, `setDuoSize(String)` troca o tamanho e gera uma grade nova; só funciona enquanto `moves == 0`.
- `flip(int id)`:
  - É ignorada se `phase != playing`, se `waitingToHide`, ou se a carta já está virada ou encontrada.
  - Vira a carta. Se for a segunda carta virada da jogada:
    - `moves++`;
    - **par:** as duas ficam `matched` e o jogador atual soma um par (em dois jogadores, continua jogando). Se todas foram encontradas, a fase vira `finished` e, em dois jogadores, o placar de partidas é atualizado (vitória de quem tem mais pares, ou empate);
    - **não é par:** `waitingToHide = true`.
- `hideMismatched()`: desvira as duas cartas, `waitingToHide = false` e, em dois jogadores, a vez passa para o outro.
- `nextLevel()` (solo, em `finished`): avança do nível 1 ao 5 e volta ao 1 depois do 5. Gera uma grade nova.
- `playAgain()` (dois jogadores, em `finished`): grade nova do mesmo tamanho. O placar de partidas é mantido e quem começa alterna.
- `exitToSetup()`: volta à fase `setup` e zera o placar.
- A grade é embaralhada com o `Random` injetado: sorteia `pairs` emojis de `kMemoryEmojis` e duplica cada um.

### Tela (`screens/game_screen.dart`, `MemoryScreen`)

- Na fase `setup`, mostra a `PlayerSetup` (solo "Sozinho", símbolos 🐶 e 🐱, sem níveis).
- Na fase `playing` ou `finished`:
  - **Solo:** `AppBar` "Memória • Nível N", com "Jogadas: X" abaixo.
  - **Dois jogadores:** `ScoreBoard` com os pares da partida em andamento, mais uma linha "Vitórias: A × B".
  - A escolha de tamanho (Pequena, Média, Grande) aparece acima da grade enquanto nenhuma carta foi virada na partida. Trocar o tamanho gera uma grade nova.
- A grade usa `GridView` sem rolagem e se ajusta à altura disponível.
- Cada carta tem o verso roxo com "?" e a frente com o emoji grande. A virada é uma animação de giro em Y de cerca de 250 ms (`TweenAnimationBuilder` + `Transform`). As cartas encontradas ficam com 50% de opacidade.
- Quando `waitingToHide` vira verdadeiro, a tela agenda um `Timer` de 900 ms que chama `hideMismatched()` e é cancelado no `dispose`.
- **Overlays:**
  - solo: "Nível N completo em X jogadas!", com **Próximo nível**, que no nível 5 vira "Jogar de novo";
  - dois jogadores: "🏆 Nome venceu!" ou "🤝 Empate!", com **Jogar de novo** e **Trocar jogadores**, que chama `exitToSetup()`.

### Testes (`test/games/memoria/`)

- Com `Random` fixo, a grade de cada nível tem `rows × cols` cartas, cada emoji exatamente 2 vezes, e os emojis são distintos entre os pares.
- Virar duas cartas iguais marca o par e soma ao jogador atual. Em dois jogadores, a vez continua com ele.
- Virar duas diferentes deixa `waitingToHide`. Um terceiro `flip` é ignorado; `hideMismatched` desvira e passa a vez (só em dois jogadores).
- `flip` numa carta virada ou encontrada é ignorado.
- Terminar no solo dá `finished`, e `nextLevel` avança, com o nível 5 voltando ao 1.
- Terminar em dois jogadores atualiza `wins1`, `wins2` ou `draws` corretamente, incluindo o empate.
- Teste de widget: o fluxo setup → grade → virar → overlay, com o `Timer` controlado por `tester.pump(Duration)`.

---

## 3. Termo (`lib/games/termo/`)

### Dados (`assets/termo/`, gerados por `tool/build_termo_words.py`)

- **Fonte:** os arquivos `lexico` e `conjugações` do repositório fserb/pt-br, com licença MIT, num commit fixo registrado no script. O script baixa os arquivos só quando é executado manualmente pelo desenvolvedor. O app nunca baixa nada.
- **Normalização:** maiúsculas, sem acento (á→A, ç→C etc.), só A–Z, exatamente 5 letras.
- **`validas.txt`:** uma linha por palavra válida, no formato `NORMAL;Exibição`, por exemplo `AVIAO;Avião`. Quando várias formas com acento normalizam igual, vale a do léxico, ou a primeira em ordem alfabética.
- **`respostas.txt`:** as palavras mais comuns pela pontuação ICF (o arquivo `icf` do mesmo repositório).
  - Filtros:
    - só palavras do `lexico`, sem as conjugações, para não sortear verbos flexionados;
    - nenhuma que comece com maiúscula na fonte, para não sortear nomes próprios;
    - nada da lista `EXCLUIR` do script, com palavrões e termos ofensivos.
  - Ficam cerca de 1.000 palavras, em ordem alfabética.
- **`LICENSE-fserb-pt-br.txt`:** a licença MIT da fonte.
- O `configureApp()` registra essa licença no `LicenseRegistry`, além da OFL da Fredoka.
- O script imprime as contagens. As respostas são revisadas por quem roda o script antes do commit.
- **Teste dos dados:**
  - todas as linhas têm 5 letras A–Z;
  - as respostas estão contidas nas válidas;
  - não há repetidas;
  - há pelo menos 500 respostas e pelo menos 3.000 válidas.

### Lógica

- `logic/evaluate.dart`:
  - `enum LetterResult { correct, present, absent }`
  - `List<LetterResult> evaluateGuess(String guess, String answer)`, com as duas palavras normalizadas.
  - Algoritmo oficial: primeiro marca os `correct` e desconta as letras; depois marca os `present` enquanto sobrar contagem da letra; o resto é `absent`.
- `data/word_bank.dart`:
  - `class WordBank { Map<String,String> valid; List<String> answers; bool isValid(String); String display(String); }`
  - `static Future<WordBank> load(AssetBundle)` lê os dois arquivos. Os testes constroem um `WordBank` com listas pequenas.
- `logic/daily.dart`:
  - `String dailyAnswer(WordBank bank, DateTime today)`.
  - O índice é o número de dias entre a data fixa `2026-01-01` e `today` (data local, sem hora), aplicado à lista de respostas embaralhada com `Random(20260101)`, módulo o tamanho da lista.
- `data/daily_store.dart`:
  - `abstract class DailyStore { Future<DailyState?> load(); Future<void> save(DailyState); }`, com uma implementação `shared_preferences` na chave `termo_daily`, em JSON.
  - `DailyState { String date; List<String> guesses; }`, com a data em `yyyy-MM-dd`.

### Provider (`providers/game_provider.dart`)

`TermoProvider({required Future<WordBank> bank, DailyStore? store, DateTime Function()? now, Random? random})`

- Estado:
  - `loading`;
  - `mode` (`daily` ou `unlimited`; começa em `daily`);
  - `answer`, `guesses` (as tentativas enviadas, normalizadas) e `current` (a linha em digitação);
  - `phase` (`playing`, `won`, `lost`);
  - `keyboard` (`Map<String, LetterResult>`, com o melhor resultado de cada letra);
  - `lastError` (`String?`, "Palavra inválida" ou "Só palavras com 5 letras");
  - `shakeCount`, que aumenta a cada erro e dispara a animação de tremer.
- Ao carregar, no modo diário:
  - se o `DailyState` salvo for de hoje, restaura as tentativas e a fase;
  - senão, começa uma palavra nova de hoje.
- `type(String letter)` e `backspace()` só funcionam em `playing`, com no máximo 5 letras.
- `submit()`:
  - com menos de 5 letras, mostra o erro e o tremor;
  - com palavra inválida, mostra o erro e o tremor;
  - senão, adiciona a tentativa, atualiza o `keyboard` e verifica vitória ou a 6ª tentativa.
  - No modo diário, salva o `DailyState`.
- `setMode(TermoMode)`:
  - troca de modo;
  - o diário restaura o dia;
  - o ilimitado sorteia uma palavra nova com o `Random`.
- `newUnlimited()`: nova palavra no ilimitado.
- `display(String normal)` devolve a forma com acento para mostrar nas tentativas e na resposta.

### Tela (`screens/game_screen.dart`, `TermoScreen`)

- `AppBar` "Termo" com a seta para o menu.
- Abaixo dela, uma escolha segmentada: **Palavra do dia** ou **Ilimitado**.
- **Grade 6×5:**
  - quadrados com borda;
  - as letras enviadas mostram a forma com acento e as cores (verde `#22C55E`, amarelo `#EAB308`, cinza `#6B7280`), reveladas uma a uma com um giro (cerca de 120 ms por letra);
  - a linha atual treme quando `shakeCount` aumenta.
- **Teclado:**
  - três linhas: `QWERTYUIOP`, `ASDFGHJKL` e `ENTER ZXCVBNM ⌫`;
  - as teclas coloridas pelo `keyboard`;
  - teclas grandes, com altura de pelo menos 48 dp;
  - o teclado físico também funciona (letras, Enter e Backspace) via `Focus`.
- `lastError` aparece num aviso curto (`SnackBar`) no topo.
- **Fim de jogo**, num painel abaixo da grade em vez de um overlay, para a grade continuar visível:
  - vitória: "🎉 Acertou em N!";
  - derrota: "A palavra era: Exibição";
  - modo diário: "Volte amanhã para a próxima palavra!";
  - modo ilimitado: botão **Nova palavra**.
- **Carregamento:** um indicador de progresso enquanto `loading` for verdadeiro.

### Testes (`test/games/termo/`)

- `evaluateGuess`:
  - todas as letras certas;
  - nenhuma certa;
  - letras presentes;
  - repetidas: `ARARA` contra `CARRO` e `SALAS` contra `ASSAR` (comparar com a regra oficial, com o resultado esperado escrito no teste);
  - acentos ignorados.
- O provider, com um `WordBank` pequeno, uma data injetada e um store em memória:
  - erros de tamanho e de palavra inválida;
  - vitória;
  - derrota na 6ª tentativa;
  - cores do teclado (o verde não volta a ser amarelo);
  - restauração do dia salvo;
  - um novo dia começa do zero;
  - uma palavra do dia terminada continua terminada ao reabrir;
  - o ilimitado não salva nada.
- `dailyAnswer` é a mesma para a mesma data e sempre diferente em dias seguidos, porque a lista é uma permutação sem repetidas.
- O teste dos dados reais em `assets/termo/` (os itens da seção Dados).
- Teste de widget: digitar pelo teclado da tela, enviar e ver as cores; uma palavra inválida mostra o aviso.

---

## 4. Lig 4 (`lib/games/lig4/`)

### Lógica pura (`logic/board.dart`)

- O tabuleiro é uma `List<List<int>>` de 6 linhas por 7 colunas, com 0 vazio e 1 ou 2 para os jogadores. A linha 0 é o topo.
- `int? dropRow(board, col)` devolve a linha onde a peça cairia, ou `null` se a coluna estiver cheia.
- `List<List<int>> drop(board, col, player)` devolve um tabuleiro novo.
- `List<(int,int)>? winningLine(board)` devolve as 4 células alinhadas (horizontal, vertical ou diagonal) de qualquer jogador, ou `null`.
- `bool isFull(board)`.
- `List<int> validColumns(board)`.

### Computador (`logic/ai.dart`)

```dart
enum AiLevel { easy, medium, hard }
int chooseColumn(List<List<int>> board, int me, AiLevel level, Random random)
```

- **easy:**
  - se existir uma jogada que vence agora, usa essa jogada com 50% de chance;
  - senão, joga numa coluna válida aleatória;
  - não bloqueia.
- **medium:**
  1. se vence agora, joga;
  2. se o adversário venceria na próxima jogada numa coluna, bloqueia essa coluna;
  3. descarta as colunas em que a jogada permite ao adversário vencer logo em seguida, jogando por cima;
  4. entre as que sobram, escolhe com peso para o centro (pesos 1, 2, 3, 4, 3, 2, 1) usando o `random`. Se todas foram descartadas, escolhe entre as válidas com o mesmo peso.
- **hard:**
  - minimax com poda alfa-beta, profundidade 6, ordenando as colunas do centro para as bordas;
  - vitória vale `±(1000000 + profundidade restante)`, preferindo vencer cedo e perder tarde;
  - **avaliação** de cada janela de 4 células (horizontal, vertical e as duas diagonais), sendo "minha" uma janela com peças só minhas e "do adversário" uma com peças só dele:
    - 3 peças minhas e 1 vazia: +50;
    - 2 minhas e 2 vazias: +10;
    - 3 do adversário e 1 vazia: −80;
    - 2 do adversário e 2 vazias: −10;
    - cada peça minha na coluna central: +6;
  - empates de pontuação são desfeitos pelo `random`.
- A tela chama `chooseColumn` via `compute` (isolate) no nível hard, e diretamente nos outros.

### Provider (`providers/game_provider.dart`, `Lig4Provider({Random? random, Duration thinkTime = const Duration(milliseconds: 500), Future<int> Function(List<List<int>>, int, AiLevel)? aiRunner})`)

- Estado:
  - `phase` (`setup`, `playing`, `finished`);
  - `mode`, nomes, `aiLevel`;
  - `board`, `currentPlayer`, `startingPlayer`;
  - `winner` (`int?`), `winningCells`;
  - `wins1`, `wins2`, `draws`;
  - `aiThinking` (bool);
  - `lastMove` (`(int,int)?`), para a animação.
- `start(PlayerSetupResult)`:
  - guarda o modo e os nomes;
  - o nível vem de `levelIndex`: 0 para easy, 1 para medium, 2 para hard;
  - o humano é sempre o jogador 1 (🔴) e começa a primeira partida.
- `play(int col)`:
  - É ignorada se não estiver em `playing`, se `aiThinking`, se a coluna estiver cheia, ou se for a vez do computador.
  - Solta a peça e verifica vitória ou empate, atualizando o placar.
  - Senão, passa a vez. Se a vez for do computador, agenda a jogada dele.
- **Jogada do computador:**
  - `aiThinking = true`;
  - espera `thinkTime` e chama `aiRunner` (o padrão é `chooseColumn`, via `compute` no hard);
  - aplica a jogada como em `play` e faz `aiThinking = false`;
  - se o provider for descartado nesse meio-tempo, não aplica nada.
- `playAgain()`:
  - tabuleiro novo, e `startingPlayer` alterna;
  - se começar o computador, ele joga primeiro.
- `exitToSetup()`: volta à fase `setup` e zera o placar.

### Tela (`screens/game_screen.dart`, `Lig4Screen`)

- **Setup:** a `PlayerSetup` (solo "Contra o computador", símbolos 🔴 e 🟡, níveis Fácil, Médio e Difícil, adversário "Computador").
- **Jogo:**
  - `ScoreBoard` e uma linha "Vez de 🔴 Nome", ou "🤖 Pensando..." quando é o computador;
  - o tabuleiro tem fundo azul `#2563EB`, buracos circulares e peças vermelhas `#EF4444` e amarelas `#FACC15`;
  - o toque em qualquer ponto de uma coluna joga nela, com uma área de toque da coluna inteira;
  - a peça nova cai com uma animação de cerca de 300 ms (`TweenAnimationBuilder` na posição vertical);
  - as peças vencedoras ficam com borda branca e pulsam.
- `AppBar` "Lig 4", ou "Lig 4 • Médio" contra o computador.
- **Overlay de fim**, no estilo do Jogo da Velha, embaixo:
  - "🏆 Nome venceu!", "🤖 O computador venceu!" ou "🤝 Empate!";
  - botões **Jogar de novo** e **Trocar jogadores**.

### Testes (`test/games/lig4/`)

- `board`:
  - a peça cai na posição certa;
  - coluna cheia devolve `null`;
  - vitória horizontal, vertical e nas duas diagonais;
  - sem vitória falsa entre jogadores diferentes;
  - `isFull`.
- `ai`, com tabuleiros montados à mão:
  - **medium** sempre aproveita a vitória imediata e sempre bloqueia a do adversário;
  - **medium** não joga numa coluna que dá a vitória ao adversário quando há alternativa;
  - **hard** acha uma vitória em duas jogadas (uma ameaça dupla) e evita uma armadilha em que o medium cai (montar o caso no teste);
  - **easy** e todos os níveis nunca escolhem uma coluna cheia;
  - **hard** decide num tabuleiro do meio da partida em menos de 2 s no ambiente de teste.
- O provider, com `thinkTime` zero e um `aiRunner` determinístico:
  - turnos alternam;
  - um toque é ignorado durante `aiThinking` ou na vez do computador;
  - vitória e empate atualizam o placar;
  - `playAgain` alterna quem começa, e o computador joga sozinho quando é ele quem começa.
- Teste de widget: setup → tocar numa coluna → a peça aparece → contra o computador (`aiRunner` fixo), o computador responde.

---

## Ordem de implementação

1. Componentes compartilhados (`PlayerSetup`, `ScoreBoard`), com testes de widget
2. Jogo da Memória
3. Termo, primeiro o script dos dados e os assets, depois a lógica, o provider e a tela
4. Lig 4, primeiro o tabuleiro, depois o computador, o provider e a tela
5. Menu: os 3 cards, o `GameShell` e o teste do menu cobrindo os 8 jogos
6. Verificação no Chrome (headless) com capturas de tela

## Fora do escopo

- Estatísticas do Termo (sequência de vitórias, distribuição de tentativas) e compartilhar o resultado
- Placar salvo entre sessões da Memória e do Lig 4
- Computador para a Memória
- Sons
- Mudanças no Jogo da Velha
