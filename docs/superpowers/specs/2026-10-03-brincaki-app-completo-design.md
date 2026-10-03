# Brincaki App Completo — Design Spec

**Date:** 2026-10-03
**Project:** Brincaki
**Status:** Aprovada

---

## Objetivo

Transformar o repositório num app Flutter executável com os 5 jogos do menu: **Caça-Palavras, Sudoku, 2048, Jogo da Velha e Jogo da Forca**. O visual do menu segue a referência `docs/menu-referencia.png`, que é exatamente o `lib/screens/menu_screen.dart` atual.

**Para quem:** a família, incluindo crianças pequenas e adultos, no celular. A distribuição é por APK instalado direto, sem loja. Não há anúncios nem coleta de dados.

**Critério de sucesso:**
- Um APK instalável em que cada card do menu abre o seu jogo.
- Todos os jogos são jogáveis do começo ao fim.
- O "voltar" sempre leva de volta ao menu.

## Estado atual

- **Já existem:** Jogo da Velha (`lib/games/tictactoe`), Jogo da Forca (`lib/games/forca`) e o menu.
- **Faltam:**
  - `pubspec.yaml`, `lib/main.dart`, `analysis_options.yaml` e as pastas de plataforma;
  - Sudoku, que existe como projeto separado em `../sudoku_game`;
  - 2048 e Caça-Palavras, que não existem em lugar nenhum.

## Decisões

| Tema | Decisão |
|------|---------|
| Plataformas | Todas (`flutter create` padrão). O alvo principal é o Android. |
| Pacote | `com.brincaki.brincaki`, nome exibido "Brincaki" |
| Persistência | Só o recorde do 2048 (`shared_preferences`). Todo o resto zera ao fechar. |
| Sudoku | Copiado de `../sudoku_game/lib`, sem o `main.dart` |
| Caça-Palavras | Progressão obrigatória: começa no nível 1 e avança vencendo. A seleção é feita arrastando o dedo. |
| Dificuldade | Os primeiros níveis são para crianças e os últimos desafiam adultos. |
| Imagem de referência | `Pasted image.png` vai para `docs/menu-referencia.png` |

---

## 1. Estrutura e configuração

- Rodar `flutter create --org com.brincaki --project-name brincaki .` na raiz. Isso não sobrescreve `lib/` e `test/`.
- Apagar o `test/widget_test.dart` de exemplo (o do contador).
- `pubspec.yaml`:
  - dependências: `provider`, `google_fonts`, `shared_preferences`
  - dependência de desenvolvimento: `flutter_lints`
- `lib/main.dart`:
  - `MaterialApp(title: 'Brincaki', debugShowCheckedModeBanner: false)`
  - tema base com fundo creme `#FFFBEB` e o `textTheme` Fredoka
  - `home: MenuScreen()`
  - nenhum provider global
- Nome exibido "Brincaki" no `AndroidManifest.xml` (`android:label`) e nas demais plataformas, onde o template permitir.

```
lib/
  main.dart
  screens/menu_screen.dart
  widgets/game_shell.dart
  games/
    cacapalavras/   novo
    sudoku/         copiado
    2048/           novo
    tictactoe/      existente
    forca/          existente
test/
  screens/menu_screen_test.dart
  games/<jogo>/...
```

## 2. Navegação: `GameShell`

**Problemas atuais:**
- O menu abre cada jogo dentro de um `Navigator` aninhado.
- A seta "voltar" do Jogo da Velha e da Forca chama `Navigator.of(context).pop()`, que afeta o `Navigator` interno e não volta ao menu.
- O "voltar" do Android ignora o `Navigator` interno.
- A `HomeScreen` do Sudoku não tem como voltar ao menu.

**Solução:** criar o widget `lib/widgets/game_shell.dart`.

```dart
class GameShell extends StatefulWidget {
  const GameShell({
    super.key,
    required this.theme,
    required this.home,
    this.wrapProvider,
  });

  final ThemeData theme;
  final WidgetBuilder home;
  /// Envolve o jogo no provider dele, por exemplo
  /// `(child) => ChangeNotifierProvider(create: (_) => TicTacToeProvider(), child: child)`.
  /// Fica nulo para o Caça-Palavras, que cria o provider na própria HomeScreen.
  final Widget Function(Widget child)? wrapProvider;
}
```

- O state guarda uma `GlobalKey<NavigatorState>` e monta `wrapProvider?` (se houver), depois `Theme` e depois o `Navigator` aninhado.
- Envolve tudo em `NavigatorPopHandler`: o "voltar" do sistema faz `maybePop` no `Navigator` interno e, se não houver para onde voltar, faz `pop` na rota raiz, que leva ao menu.
- Os métodos `_open<Jogo>` do menu passam a usar o `GameShell`. Cards, cores e textos do menu não mudam.
- As setas "voltar" da primeira tela de cada jogo usam `Navigator.of(context, rootNavigator: true).pop()`. São elas:
  - Jogo da Velha
  - Forca
  - 2048
  - Caça-Palavras
  - a `HomeScreen` do Sudoku, que ganha uma `AppBar` com `leading`

## 3. Sudoku

- Copiar `../sudoku_game/lib/{models,providers,screens,services,widgets}` para `lib/games/sudoku/`. Os imports são relativos e não devem precisar de ajuste.
- O menu já fornece o tema escuro e o `GameProvider`, que fica igual ao `main.dart` original.
- Adicionar uma seta para voltar ao menu na `HomeScreen`, como descrito na seção 2.
- Novo teste `test/games/sudoku/game_provider_test.dart` cobrindo:
  - `startGame` gera um tabuleiro com o número de casas vazias dentro da faixa da dificuldade;
  - `enterNumber` marca um erro quando o número conflita com outro;
  - `useHint` consome uma dica, de um total de 3.

## 4. 2048

Pasta `lib/games/2048/`. Os nomes `Game2048Provider` e `Game2048Screen` já são usados pelo menu.

### Lógica: `logic/board_logic.dart` (funções puras)

- O tabuleiro é uma `List<List<int>>` 4×4, em que 0 é uma casa vazia.
- `enum Direction { up, down, left, right }`.
- `SlideResult slide(List<List<int>> board, Direction d)` devolve o novo tabuleiro, os pontos ganhos e um `bool moved`.
  - Comportamento clássico: as peças deslizam, as vizinhas iguais se juntam e cada peça se junta no máximo uma vez por jogada (`[2,2,2,2]` vira `[4,4,0,0]`).
  - Implementação: girar ou espelhar o tabuleiro, deslizar a linha para a esquerda e desfazer a rotação.
- `bool canMove(board)` é verdadeiro se houver uma casa vazia ou duas vizinhas iguais.

### Recorde: `data/high_score_store.dart`

- `abstract class HighScoreStore { Future<int> load(); Future<void> save(int); }`
- Implementação `SharedPrefsHighScoreStore` com a chave `game2048_best`.
- Os testes usam uma implementação em memória.

### Provider: `providers/game_provider.dart`

- `Game2048Provider({HighScoreStore? store, Random? random})`.
  - O store padrão é `SharedPrefsHighScoreStore`.
  - O recorde é carregado de forma assíncrona no construtor.
- Estado:
  - `board`
  - `score`
  - `best`
  - `phase` (`playing`, `won`, `lost`)
  - `_keepPlaying`
- `move(Direction)`:
  - Se `phase != playing` ou a jogada não mudar nada, não faz nada.
  - Senão, soma os pontos e coloca uma peça nova numa casa vazia aleatória: 2 com 90% de chance, 4 com 10%.
  - Se surgir o 2048 e `!_keepPlaying`, a fase vira `won`.
  - Se `!canMove`, a fase vira `lost`.
  - Se `score > best`, atualiza o recorde e salva.
- `continuePlaying()`: só funciona em `won`. Define `_keepPlaying = true` e a fase volta para `playing`.
- `newGame()`: tabuleiro zerado com 2 peças, `score = 0`, `_keepPlaying = false` e fase `playing`. O recorde é mantido.

### Tela: `screens/game_screen.dart`

- Fundo `#FAF8EF`.
- `AppBar` com a seta para voltar ao menu e o título "2048".
- Caixas "Pontos" e "Recorde", e o botão "Novo jogo".
- Tabuleiro quadrado com cores por valor (a paleta clássica do 2048). O tamanho da fonte diminui para valores com 4 dígitos ou mais.
- Gestos:
  - `GestureDetector.onPanEnd`: o eixo dominante da velocidade define a direção, ignorando gestos com velocidade menor que 100 px/s;
  - setas do teclado via `Focus` + `onKeyEvent`.
- Animações:
  - a peça nova aparece com escala de 0 a 1 (cerca de 150 ms);
  - as peças que se juntam dão um "pulo" (escala 1 → 1,15 → 1);
  - não há animação de deslizamento.
- Overlays:
  - `won`: "Você chegou ao 2048!", com os botões **Continuar** e **Novo jogo**;
  - `lost`: "Fim de jogo" e os pontos, com o botão **Jogar de novo**.

### Testes: `test/games/2048/`

- `board_logic_test.dart`:
  - `slide` nas 4 direções;
  - o caso `[2,2,2,2]` e o caso `[2,2,4,0]`, que vira `[4,4,0,0]`;
  - uma jogada que não muda nada dá `moved == false`;
  - `canMove` com o tabuleiro cheio, com e sem vizinhas iguais.
- `game_provider_test.dart`:
  - jogada inválida não cria peça nova;
  - vitória acontece uma vez só e `continuePlaying` funciona;
  - derrota é detectada;
  - o recorde é atualizado e salvo no store em memória.

## 5. Caça-Palavras

Pasta `lib/games/cacapalavras/`. O menu já importa `screens/home_screen.dart as cacapalavras` e usa `cacapalavras.HomeScreen` com tema roxo (`Colors.deepPurple`) e Fredoka.

### Níveis: `data/levels.dart`

Palavras em maiúsculas e sem acento. Cada tema tem cerca de 20 palavras, e cada partida sorteia a quantidade do nível.

| Nível | Grade | Palavras | Direções | Tema |
|---|---|---|---|---|
| 1 | 6×6 | 4 | → ↓ | Animais |
| 2 | 7×7 | 5 | → ↓ | Frutas |
| 3 | 8×8 | 5 | → ↓ | Cores |
| 4 | 8×8 | 6 | → ↓ ↘ | Corpo humano |
| 5 | 9×9 | 7 | → ↓ ↘ ↗ | Casa |
| 6 | 10×10 | 8 | → ↓ ↘ ↗ | Profissões |
| 7 | 10×10 | 8 | as 4 anteriores + ← ↑ | Natureza |
| 8 | 11×11 | 9 | todas as 8 | Esportes |
| 9 | 12×12 | 10 | todas as 8 | Países |
| 10 | 12×12 | 12 | todas as 8 | Ciência |

O tamanho de cada palavra não pode passar do tamanho da grade do seu nível.

```dart
class LevelConfig {
  final int size;
  final int wordCount;
  final List<Direction> directions;
  final String theme;
  final List<String> words;
}
```

### Modelos: `models/game_state.dart`

- `enum WordSearchPhase { playing, won }`
- `enum Direction` com as 8 direções, cada uma com `dr` e `dc`
- `class PlacedWord { String word; int row; int col; Direction dir; List<(int,int)> cells; }`

### Gerador: `services/grid_generator.dart`

- Função pura `GeneratedGrid generateGrid({required List<String> candidates, required int wordCount, required int size, required List<Direction> directions, required Random random})`.
- Passos:
  1. Embaralhar os candidatos.
  2. Para cada palavra, fazer até 100 tentativas de posição e direção aleatórias, aceitando o cruzamento apenas se as letras forem iguais.
  3. Se a palavra não couber, passar para o próximo candidato.
  4. Parar ao atingir `wordCount`.
- Preencher as casas vazias com letras A–Z aleatórias.
- Se os candidatos acabarem antes de atingir `wordCount`, reiniciar a grade, com até 10 recomeços. Com cerca de 20 palavras por tema, isso não deve acontecer na prática.

### Provider: `providers/game_provider.dart`

- `WordSearchProvider({Random? random})`. Começa no nível 1 e gera a grade.
- Estado:
  - `level`
  - `grid` (`List<List<String>>`)
  - `words` (`List<PlacedWord>`)
  - `found` (`Set<String>`)
  - `selectionStart`, `selectionEnd`
  - `phase`
- `selectedCells`: as células da reta entre o início e o fim.
  - O fim é ajustado para a direção mais próxima entre as 8, usando o ângulo do vetor.
  - O comprimento é o maior entre `|dr|` e `|dc|`, limitado à borda da grade.
- `startSelection(r,c)`, `updateSelection(r,c)` e `endSelection()`.
  - Ao terminar a seleção, as letras são lidas. Se a sequência, ou o seu inverso, for uma palavra ainda não encontrada e as células forem exatamente as dela, a palavra é marcada como encontrada.
  - A seleção é limpa ao final.
  - Quando todas as palavras forem encontradas, a fase vira `won`.
- `nextLevel()`: só funciona em `won`.
  - Do nível 1 ao 9, avança um nível.
  - No nível 10, volta ao nível 1.
  - Gera uma grade nova.
- Não há derrota nem cronômetro.

### Telas e widgets

- `screens/home_screen.dart` (`HomeScreen`):
  - cria o `WordSearchProvider` (via `ChangeNotifierProvider`) e mostra o jogo diretamente;
  - `AppBar` com a seta para voltar ao menu e o título "Caça-Palavras • Nível N — Tema".
- `widgets/letter_grid.dart`:
  - grade quadrada com a largura disponível;
  - um único `GestureDetector` (`onPanStart`, `onPanUpdate`, `onPanEnd`) converte a posição do toque em (linha, coluna);
  - a seleção em andamento aparece em amarelo;
  - as palavras encontradas ficam destacadas com uma cor por palavra, de uma paleta de cerca de 8 cores.
- `widgets/word_list.dart`: as palavras como chips, riscadas e esmaecidas quando encontradas.
- Overlay de vitória no estilo da Forca:
  - "Nível N completo!", com o botão **Próximo nível**;
  - no nível 10, o texto é "Você completou todos os níveis!" e o botão é **Jogar de novo**.

### Testes: `test/games/cacapalavras/`

- `grid_generator_test.dart`, com uma seed fixa e para cada um dos 10 níveis:
  - posiciona exatamente `wordCount` palavras;
  - cada palavra pode ser lida na grade nas suas células;
  - usa apenas as direções permitidas;
  - todas as casas são letras A–Z.
- `game_provider_test.dart`:
  - seleção correta, nos dois sentidos, marca a palavra;
  - seleção errada não marca nada;
  - encontrar todas as palavras dá `won`;
  - `nextLevel` avança e, no nível 10, volta ao 1;
  - `updateSelection` ajusta a reta para a direção mais próxima.

## 6. Verificação

- `flutter analyze` sem avisos.
- `flutter test` passando, incluindo `test/screens/menu_screen_test.dart`, que:
  - renderiza o menu com os 5 cards;
  - toca em cada card, confere que a tela do jogo abriu e volta ao menu.
- Nos testes de widget, o Google Fonts precisa evitar requisições de rede: `GoogleFonts.config.allowRuntimeFetching = false`, mais o que for necessário para não falhar sem a fonte.
- Execução manual no Chrome (`flutter run -d web-server`), passando por cada jogo e tirando capturas de tela. Esta máquina não tem toolchain Linux, só web:
  - abrir, jogar, vencer ou perder;
  - voltar pela seta e pelo "voltar".

## 7. Entrega

- Pré-requisito: o SDK do Android, que hoje não está instalado nesta máquina. Instalar só depois de confirmar com o usuário.
- `flutter build apk --release` gera `build/app/outputs/flutter-apk/app-release.apk`, assinado com a chave de debug, o que basta para instalar sem loja.
- O ícone do app é o padrão do Flutter. Um ícone personalizado fica fora deste escopo.

## Ordem de implementação

1. Projeto Flutter, `pubspec`, `main.dart`, `GameShell` e ajuste da navegação no menu, no Jogo da Velha e na Forca
2. Sudoku, com testes
3. 2048, com testes
4. Caça-Palavras, com testes
5. Teste do menu, verificação manual com capturas de tela e APK

## Fora do escopo

- Publicação na Play Store e chave de assinatura própria
- Ícone personalizado
- Perfis por pessoa, recorde por jogador ou persistência além do recorde do 2048
- Animação de deslizamento no 2048
- Sons
