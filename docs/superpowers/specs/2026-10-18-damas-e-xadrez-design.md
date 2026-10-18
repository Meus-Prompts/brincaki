# Damas e Xadrez: design

**Data:** 2026-10-18
**Projeto:** Brincaki
**Status:** Aprovado na conversa (o usuário pediu para escrever, implementar e só entregar com tudo pronto)

---

## Objetivo

Dois jogos novos de tabuleiro, **Damas** ⚫ e **Xadrez** ♟️, do mesmo jeito que o Jogo da Velha e o Lig 4: "Contra o computador" (Fácil, Médio, Difícil) ou "Dois jogadores" no mesmo aparelho, com placar.

As regras são **completas** nas duas, por pedido do usuário: Damas brasileiras e Xadrez oficial. A criança aprende o jogo de verdade, e a tela ajuda mostrando as jogadas possíveis.

**Critério de sucesso**
- o 10º e o 11º cartões do menu abrem Damas e Xadrez;
- dá para jogar uma partida inteira contra o computador (nos três níveis) e entre dois jogadores, com as duas cores;
- nenhum lance ilegal é aceito e nenhum lance legal é recusado;
- o computador no Difícil é um desafio para uma criança que já sabe jogar (não precisa ser forte para um adulto) e responde em no máximo ~2 s num celular comum, sem travar a tela (decisão minha: a busca fica abaixo de ~1,5 s, somada aos 500 ms de "pensar");
- `flutter analyze` sem avisos, `flutter test` verde e `tool/check_coverage.py` passando;
- `integration_test/app_test.dart` joga uma partida de cada um pelo app de verdade.

**Fora do escopo (decisão minha):** desfazer jogada, relógio, desistir ou propor empate, salvar partida no meio, histórico de lances em notação, sons.

**Seria um fracasso se:** um lance legal fosse recusado (ou um ilegal aceito), o computador travasse a tela ou ficasse preso em "Pensando...", o tabuleiro não coubesse em 320x568, ou a criança não entendesse por que não consegue mexer uma peça (captura obrigatória sem destaque).

## Restrições herdadas

Valem as regras do `CLAUDE.md`: textos em pt-BR, Fredoka empacotada, nada de internet, módulos em `lib/games/damas/` e `lib/games/xadrez/`, provider criado pelo `GameShell` do menu, `GameScaffold` e `ResultPanel`, todo arquivo começa com o comentário do próprio caminho, testes nas telas de 360x740 e 320x568, commits pequenos `feat(damas): ...` / `feat(xadrez): ...`.

---

## 1. Partes comuns às duas

### Tela inicial
`PlayerSetup`, como no Lig 4, com uma novidade: um seletor de cor **Brancas / Pretas**.
- O `PlayerSetup` ganha um parâmetro opcional `sides` (os dois rótulos). Quando passado, mostra um `LevelPicker` a mais ("Sua cor" no solo, "Cor do Jogador 1" em dois jogadores) e devolve `PlayerSetupResult.sideIndex` (0 = brancas, 1 = pretas). Os outros jogos não passam `sides` e não mudam.
- Contra o computador: nível (Fácil, Médio, Difícil) e cor. Em dois jogadores: nomes e a cor do Jogador 1 (decisão minha).

### Quem começa e cor
- **As brancas sempre começam**, nas duas e em toda partida (pedido do usuário).
- A cor escolhida fica a mesma em "Jogar de novo". Só muda voltando à tela inicial ("Trocar jogadores").
- Se o jogador humano está com as pretas contra o computador, o computador faz o primeiro lance (depois do tempo de "pensar").

### Tabuleiro na tela
- Contra o computador: virado para o humano (a cor dele embaixo).
- Dois jogadores: fixo com as brancas embaixo (decisão minha).
- Quadrado, ocupa a largura disponível (limitado pela altura), cabe em 320x568 com o placar e o painel de resultado.

### Como se joga
1. Toca numa peça da vez: ela fica selecionada e os destinos possíveis acendem (um ponto nas casas vazias, um anel nas casas com peça a capturar).
2. Toca num destino aceso: o lance acontece. Tocar noutra peça própria troca a seleção; tocar fora desmarca.
3. A **última jogada** fica marcada (casa de origem e destino com um tom claro).
4. O texto acima do tabuleiro diz "Vez de ⚪ Nome" / "Vez de ⚫ Nome", ou "🤖 Pensando..." na vez do computador.
5. Durante a vez do computador, toques no tabuleiro são ignorados.

### Placar e resultado
- `ScoreBoard` com os nomes, ⚪ ou ⚫ conforme a cor de cada um, vitórias e empates (zera ao voltar à tela inicial).
- Fim de partida: `ResultPanel` no rodapé, com o tabuleiro final visível.
  - Títulos: "🏆 Nome venceu!", "🤖 O computador venceu!" ou "🤝 Empate!".
  - Mensagem com o motivo: "Xeque-mate!", "Sem peças para jogar", "Sem jogadas possíveis", "Afogamento", "Só sobraram peças que não dão mate", "50 lances sem captura nem peão", "A mesma posição 3 vezes", "20 lances só com damas", "5 lances no final de damas".
  - Botões: "Jogar de novo" e "Trocar jogadores" (volta ao setup).
- `confirmExit` ligado durante a partida (as partidas são longas; decisão minha).

### Computador
- Mesmo padrão do Lig 4: `thinkTime` injetável (500 ms por padrão), `aiRunner` injetável, `_gameId` para descartar lances atrasados, nunca notificar depois do `dispose`, e se o runner falhar joga um lance legal qualquer.
- Médio e Difícil rodam em `compute` (isolate). A lógica é toda em funções puras com `Random` injetável.
- Fácil: lance aleatório, mas pega uma captura de graça metade das vezes.
- Médio: busca rasa (2 lances) por material, com um pouco de sorte entre lances iguais.
- Difícil: alfa-beta mais fundo com avaliação posicional e limite de tempo/nós, para nunca passar de ~2 s.

### Peças
- Damas: círculos desenhados (branco/creme e preto/grafite) com borda; a dama tem uma coroa (👑 ou desenho) por cima.
- Xadrez: símbolos Unicode (♔♕♖♗♘♙ / ♚♛♜♝♞♟) numa fonte de símbolos **empacotada** (subconjunto da Noto Sans Symbols 2, licença OFL), porque a Fredoka não tem esses símbolos e o app não baixa fontes. As brancas são o símbolo cheio pintado de branco com o contorno preto por cima; as pretas, o símbolo cheio em preto.

---

## 2. Damas (regra brasileira)

- Tabuleiro 8x8, joga-se nas casas escuras. A casa do canto inferior esquerdo de cada jogador é escura.
- 12 pedras de cada lado nas três primeiras fileiras. Brancas começam.
- **Pedra** anda uma casa na diagonal, só para a frente. **Captura** para a frente e para trás, pulando uma peça adversária vizinha para a casa vazia logo atrás.
- **Dama** (pedra que termina o lance na última fileira) anda quantas casas quiser na diagonal ("dama voadora"). Captura a distância: pode haver casas vazias antes da peça capturada e pode parar em qualquer casa vazia depois dela.
- **Captura obrigatória**, e em sequência enquanto houver o que capturar.
- **Lei da maioria**: entre as capturas possíveis, é obrigatório fazer a que captura mais peças (pedra e dama valem igual). Empatando no número, o jogador escolhe.
- Na sequência, uma peça não pode ser pulada duas vezes, e as peças capturadas só saem do tabuleiro no fim do lance (continuam bloqueando a passagem até lá).
- Uma pedra que chega à última fileira **no meio** de uma captura e precisa continuar capturando não vira dama. Só vira se o lance terminar lá.
- **Vitória**: o adversário não tem peças ou não tem lance possível na vez dele.
- **Empate** (decisão minha sobre o conjunto, seguindo a regra da CBD):
  - a mesma posição (com a mesma vez) pela 3ª vez;
  - 20 lances seguidos (de cada lado, 40 meios-lances) só com damas, sem captura e sem mexer pedra (decisão minha: o contador conta meios-lances seguidos sem captura e sem lance de pedra, e zera com qualquer um dos dois, mesmo que ainda haja pedras paradas no tabuleiro);
  - 5 lances de cada lado (10 meios-lances) quando o material é um destes: 2 damas × 2 damas, 2 damas × 1 dama, 2 damas × 1 dama + 1 pedra, 1 dama × 1 dama, 1 dama × 1 dama + 1 pedra (contados a partir do momento em que a posição chega a esse material).

### Como a criança joga a captura
- No início da vez, se há captura obrigatória, **as peças que podem capturar ficam destacadas** (um contorno pulsando na cor do jogo) e só elas podem ser selecionadas.
- Captura múltipla: **um salto por toque**. Depois de cada salto a peça continua selecionada, só os próximos saltos válidos (que respeitam a lei da maioria) acendem, e as peças já capturadas ficam meio transparentes até o fim do lance.
- O lance só termina (e a vez passa) quando a sequência acaba.

### Computador nas Damas
- Gera lances completos (a sequência inteira). Na tela, o lance do computador é aplicado de uma vez, e a última jogada marca origem e destino final.
- Difícil: alfa-beta com profundidade ~6 meios-lances (com extensão em capturas), avaliação: material (pedra 100, dama 300), avanço das pedras, centro e a última fileira protegida.

## 3. Xadrez (regras oficiais)

- Movimentos normais das seis peças.
- **Roque** dos dois lados: rei e torre nunca mexidos, casas entre eles vazias, o rei não está em xeque, não passa por casa atacada nem termina em xeque. Na tela, toca o rei e depois a casa de destino do rei (duas casas para o lado).
- **En passant**: só no lance logo depois do avanço duplo do peão adversário.
- **Promoção**: peão na última fileira abre uma escolha (diálogo com dama, torre, bispo e cavalo, nos símbolos da cor dele). O computador promove para dama (decisão minha). Fechar o diálogo sem escolher cancela o lance.
- Nenhum lance pode deixar o próprio rei em xeque.
- **"Xeque!"**: o rei em xeque fica com a casa vermelha e o texto da vez mostra "Xeque!".
- **Fim**:
  - xeque-mate: vitória;
  - afogamento (sem lance legal e sem xeque): empate;
  - material insuficiente: rei × rei, rei + bispo × rei, rei + cavalo × rei, rei + bispo × rei + bispo com bispos da mesma cor de casa;
  - 50 lances de cada lado (100 meios-lances) sem captura nem lance de peão;
  - a mesma posição pela 3ª vez (mesma vez, mesmos direitos de roque e de en passant).
  - As regras de 50 lances e repetição são **automáticas**, sem precisar pedir (decisão minha: não há botão de pedir empate).
- Coordenadas a–h e 1–8 pequenas na borda das casas (decisão minha; ajudam a aprender).

### Computador no Xadrez
- Difícil: alfa-beta com aprofundamento iterativo até 3 meios-lances (4 se der tempo), busca de quietude só em capturas, ordenação MVV-LVA, tabelas de posição por peça. Limite de tempo para nunca passar de ~1,5 s.
- Médio: 2 meios-lances, material, um pouco de aleatoriedade entre lances próximos.
- Fácil: aleatório, com preferência por capturas e por dar mate em 1 quando há.

---

## 4. Arquitetura

Cada jogo é um módulo como os outros:

```
lib/games/damas/
  models/game_state.dart      DamasPhase { setup, playing, finished }, DamasEnd (motivo), cor
  logic/board.dart            posição, geração de lances (com lei da maioria), aplicar lance, fim/empate
  logic/ai.dart               chooseMove(position, level, random) + versão para compute
  providers/game_provider.dart DamasProvider
  screens/game_screen.dart    DamasScreen
  widgets/board_view.dart     tabuleiro e peças
lib/games/xadrez/
  models/game_state.dart      XadrezPhase, XadrezEnd, PieceType, Side
  logic/position.dart         posição, lances legais, roque, en passant, promoção, xeque, fim, chave de repetição
  logic/ai.dart               chooseMove
  providers/game_provider.dart XadrezProvider
  screens/game_screen.dart    XadrezScreen (inclui o diálogo de promoção)
  widgets/board_view.dart     tabuleiro, coordenadas, peças
```

- Provider: campos privados com getters, toda mutação confere a fase primeiro; `select(square)`/`tapSquare(square)` para a interação, `legalTargets`, `selected`, `lastMove`, `inCheck`, `mustCapturePieces` (Damas), `capturedInSequence` (Damas), `pendingPromotion` (Xadrez).
- Lógica pura e imutável do lado de fora (uma posição nova por lance), para facilitar testes, repetição e o isolate.
- `GamePalette` nova para cada um: `kDamasPalette` e `kXadrezPalette`, com cores diferentes das existentes (decisão minha: Damas em marrom/âmbar madeira, Xadrez em ardósia/índigo).
- Menu: `_openDamas` e `_openXadrez` com `GameShell`, e dois cartões novos.
- Fonte de xadrez: `assets/fonts/` com o subconjunto da Noto Sans Symbols 2 e o `OFL.txt`, declarada em `pubspec.yaml` como família `ChessSymbols`.

## 5. Testes

- `test/games/damas/`: regras (movimento, captura obrigatória, lei da maioria, dama voadora, captura sem pular a mesma peça, peças que só saem no fim, promoção só no fim do lance, vitória por falta de lance, os três empates), IA (lances sempre legais nos três níveis, pega captura grátis, não demora), provider (fluxo, seleção, salto por toque, computador, gameId, dispose), tela (setup → partida → resultado → cada botão → voltar, nas duas telas).
- `test/games/xadrez/`: contagem perft das posições de referência (inicial até profundidade 3, e a "Kiwipete" até 2 ou 3) para pegar qualquer erro de geração; roque, en passant, promoção, xeque, mate, afogamento, material insuficiente, 50 lances, repetição; IA (legal, acha mate em 1 no Médio e no Difícil, não entrega a dama de graça no Difícil); provider; tela com mate do pastor/louco pelos toques e o diálogo de promoção.
- `test/widgets/player_setup_test.dart`: o seletor de cor.
- `test/screens/menu_screen_test.dart`: os dois cartões novos abrem os jogos.
- `integration_test/app_test.dart`: Xadrez em dois jogadores com o mate do louco tocando nas casas; Damas em dois jogadores tocando em lances legais lidos do provider até o painel de resultado; os dois voltam ao menu.

## 6. Entrega

Decisão minha: tudo num branch `feat/damas-xadrez` com commits pequenos; sem subir versão nem release. O merge no `main` fica para o usuário decidir.

## 7. O que fica para quem constrói

Cores exatas, tamanhos, animação do lance, o desenho da coroa da dama, a avaliação exata das IAs e os tempos limite, desde que respeitem o que está acima.
