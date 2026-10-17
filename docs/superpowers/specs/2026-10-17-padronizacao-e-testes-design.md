# Padronização dos jogos e testes completos — design

Data: 2026-10-17

## Objetivo

1. Todos os 8 jogos com a mesma estrutura de tela, as mesmas cores do menu e
   o mesmo jeito de escolher modo e nível.
2. Jogo da Velha ganha o modo "Contra o computador" com 3 níveis, igual ao Lig 4.
3. Testes unitários, de widget (fluxo completo) e de integração (app real no
   Linux desktop) para todos os jogos, todos passando.

## Componentes compartilhados (`lib/widgets/`)

### `game_palette.dart`

```dart
class GamePalette {
  const GamePalette({required this.accent, required this.light,
                     required this.dark, required this.background});
  final Color accent;     // botões, placar, destaque
  final Color light;      // fim do gradiente do cartão no menu
  final Color dark;       // título e textos
  final Color background; // fundo da tela do jogo
  ThemeData get theme;    // Material 3, colorSchemeSeed: accent, Fredoka
}
```

Uma constante por jogo, com as cores do cartão no menu (que passam a ser a
fonte de verdade):

| Jogo          | accent  | light   | dark    | background |
|---------------|---------|---------|---------|------------|
| Caça-Palavras | F59E0B  | FBBF24  | B45309  | FFFBEB     |
| Sudoku        | 10B981  | 34D399  | 047857  | ECFDF5     |
| 2048          | F97316  | FB923C  | C2410C  | FFF7ED     |
| Jogo da Velha | EC4899  | F472B6  | BE185D  | FFF1F2     |
| Jogo da Forca | 3B82F6  | 60A5FA  | 1D4ED8  | F0F9FF     |
| Memória       | 8B5CF6  | A78BFA  | 5B21B6  | F5F3FF     |
| Termo         | 14B8A6  | 2DD4BF  | 0F766E  | F0FDFA     |
| Lig 4         | EF4444  | F87171  | B91C1C  | FEF2F2     |

O menu usa `palette.accent`/`palette.light` nos cartões e `palette.theme` no
`GameShell`. Sudoku deixa o tema escuro.

### `GameScaffold`

```dart
GameScaffold({
  required GamePalette palette,
  required String title,      // "Jogo • Nível" quando houver nível
  required Widget body,
  List<Widget>? actions,      // ex.: cronômetro do Sudoku, recorde do 2048
  Widget? result,             // ResultPanel, fica abaixo do corpo
  bool confirmExit = false,   // pergunta antes de sair no meio da partida
})
```

- Fundo `palette.background`; AppBar da mesma cor, sem sombra, título Fredoka
  20 negrito em `palette.dark`.
- Seta de voltar com tooltip "Voltar ao menu": fecha o jogo inteiro
  (`rootNavigator: true`).
- `confirmExit`: a seta e o voltar do sistema abrem o diálogo
  "Sair do jogo?" / "O progresso desta partida será perdido." com
  "Continuar jogando" e "Sair".
- Corpo em `SafeArea` → `Column[Expanded(body), if (result != null) result]`.

### `ResultPanel`

Cartão branco no rodapé (não cobre o tabuleiro: dá para ver a jogada final),
com borda `accent`, entrada animada.

```dart
ResultPanel({required GamePalette palette, required String emoji,
             required String title, String? message,
             required List<ResultAction> actions})
ResultAction(String label, VoidCallback onPressed, {bool primary = true})
```

Ação principal: `ElevatedButton` em `accent`. Secundária: `OutlinedButton`.

Textos padrão dos botões: "Jogar de novo", "Próximo nível", "Trocar jogadores"
(jogos de dois jogadores) e "Mudar nível" (jogos solo com nível).

### Telas de início

- `PlayerSetup` (já existe): jogos com dois jogadores — Velha, Lig 4, Memória.
  O seletor de nível passa a ser o `LevelPicker` comum.
- `SoloSetup` (novo): jogos solo com nível — Forca (7 níveis), Caça-Palavras
  (10 níveis, rótulo com o tema), Sudoku (5 dificuldades). Emoji, título,
  `LevelPicker` e botão "Jogar!", no mesmo visual do `PlayerSetup`.
- `LevelPicker` (novo): `Wrap` de `ChoiceChip`s, usado pelos dois.
- 2048 e Termo continuam sem tela de início (não têm escolha antes de jogar;
  o Termo mantém o seletor "Palavra do dia" / "Ilimitado" na tela).

## Mudanças por jogo

**Jogo da Velha**
- `logic/board.dart`: tabuleiro puro (`winningLine`, `isFull`, jogadas livres).
- `logic/ai.dart`: `chooseMove(board, me, level, random)`.
  - Fácil: joga aleatório; pega a vitória imediata só metade das vezes.
  - Médio: vence se puder, bloqueia se precisar; senão centro, cantos, lados
    (aleatório entre empatados).
  - Difícil: minimax completo (nunca perde); sorteia entre jogadas ótimas.
- Provider no modelo do Lig 4: `start(PlayerSetupResult)`, `play(row, col)`,
  `playAgain()` (alterna quem começa), `exitToSetup()`, `isComputerTurn`,
  `aiThinking`, tempo de "pensar" injetável e descarte de jogadas atrasadas.
  O humano é ❌ (jogador 1), o computador ⭕ (jogador 2).
- Tela: `PlayerSetup` (solo "Contra o computador", níveis Fácil/Médio/Difícil),
  `ScoreBoard`, "Vez de ❌ Nome" / "🤖 Pensando...", tabuleiro com a linha
  vencedora destacada, `ResultPanel`. Título "Jogo da Velha • Médio" no solo.
- Saem `setup_form.dart`, `score_banner.dart`, `result_overlay.dart`.
- Menu: descrição "Contra o computador ou um amigo!", tags
  "Contra o computador", "2 jogadores".

**Lig 4, Memória** — `GameScaffold` + `ResultPanel` no lugar do painel/overlay.
Memória solo passa a escolher o nível inicial (1–5) no `PlayerSetup`.

**Forca** — fase `setup` com `SoloSetup` (nível inicial 1–7), `GameScaffold`,
`ResultPanel` no lugar do overlay (o teclado some quando a partida acaba).
Botões: venceu → "Próxima palavra"; perdeu → "Tentar de novo"; ambos com
"Mudar nível".

**Caça-Palavras** — provider passa para o `GameShell` (como os outros), fase
`setup` com `SoloSetup` (nível 1–10 com o tema), `GameScaffold`, `ResultPanel`
("Próximo nível" / "Jogar de novo" no último, e "Mudar nível").

**Sudoku** — uma tela só (`SudokuScreen`) com fase `setup` (`SoloSetup` com as
5 dificuldades), tema claro esmeralda, `GameScaffold(confirmExit: partida em
andamento)`, cronômetro em `actions`, `ResultPanel` ("Tempo: mm:ss",
"Jogar de novo", "Mudar dificuldade").

**2048** — `GameScaffold` com fundo da paleta (as cores das peças ficam);
`ResultPanel` para "Você chegou ao 2048!" ("Continuar", "Novo jogo") e
"Fim de jogo" ("Novo jogo").

**Termo** — `GameScaffold` + `ResultPanel` com os mesmos textos e botões de hoje.

## Testes

- **Unitários** (`test/`): toda lógica pura e todo provider, com casos de
  borda: entradas inválidas, chamadas fora de fase, provider descartado com
  timers pendentes, persistência.
- **Widget** (`test/`): cada widget compartilhado; para cada jogo, o fluxo
  completo — início → partida → resultado → cada botão do resultado → voltar.
  Menu: cada cartão abre o jogo certo e o voltar retorna ao menu.
- **Integração** (`integration_test/app_test.dart`, pacote `integration_test`):
  o app real (`main.dart`), um teste por jogo: abre pelo menu, joga até o
  resultado e volta ao menu. Roda com `flutter test integration_test -d linux`.
- **Critério de pronto**: `flutter analyze` sem avisos; `flutter test` e o
  teste de integração passando; cobertura de linhas ≥ 90% em cada arquivo de
  `lib/` que tenha código executável e ≥ 95% no total
  (`tool/check_coverage.py`).
