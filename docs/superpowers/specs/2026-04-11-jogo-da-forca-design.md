# Jogo da Forca — Design Spec

**Date:** 2026-04-11  
**Project:** Brincaki  
**Status:** Approved

---

## Overview

Adicionar o Jogo da Forca ao app Brincaki. Jogo single-player com progressão por níveis, boneco animado e teclado colorido de letras.

---

## Estrutura de Arquivos

```
lib/games/forca/
  models/game_state.dart       — enums ForcaPhase, LetterState
  data/word_list.dart          — 7 níveis, ~15 palavras cada
  providers/game_provider.dart — lógica do jogo via ChangeNotifier
  screens/game_screen.dart     — tela principal
  widgets/hangman_painter.dart — CustomPainter animado do boneco
  widgets/word_display.dart    — traços com letras reveladas
  widgets/letter_keyboard.dart — teclado A-Z colorido
```

Integração:
- `lib/screens/menu_screen.dart` — novo card "Jogo da Forca"
- `lib/main.dart` — sem mudança necessária (Provider injetado no menu)

---

## Dados — Níveis e Palavras

Palavras em maiúsculo sem acento (para simplicidade do teclado).

| Nível | Dificuldade | Exemplo de palavras |
|-------|-------------|---------------------|
| 1 | 3–4 letras, simples | UVA, BOI, CEU, PAO, MAR, SOL |
| 2 | 4–5 letras, animais/objetos comuns | GATO, BOLA, CAMA, SAPO, PATO |
| 3 | 5–6 letras | PEIXE, TIGRE, ARVORE, FOLHA |
| 4 | 6–7 letras | ELEFANTE, GIRAFA, MACACO |
| 5 | 7–9 letras, compostas | BORBOLETA, TARTARUGA, CROCODILO |
| 6 | 9–10 letras | JACARANDA, RINOCERONTE, ORANGOTANGO |
| 7 | 10+ letras, difíceis | HIPOPOTAMO, DINOSSAURO, CAPIVARA |

Cada nível tem ~15 palavras. Sorteio aleatório sem repetição dentro da sessão.

---

## Mecânica do Jogo

- **Máximo de erros:** 6 (cada erro adiciona uma parte ao boneco)
- **Acerto da palavra:** avança para o próximo nível (no nível 7, continua no 7 ciclando novas palavras)
- **Derrota (6 erros):** mostra a palavra correta, reseta para nível 1

### Estados (ForcaPhase)
- `playing` — jogo em andamento
- `won` — palavra acertada (overlay de celebração)
- `lost` — 6 erros (overlay de derrota com a palavra revelada)

### LetterState (por letra A-Z)
- `unguessed` — cinza, habilitada
- `correct` — verde, desabilitada
- `wrong` — vermelho, desabilitada

---

## Boneco Animado (HangmanPainter)

CustomPainter com 6 partes, desenhadas incrementalmente conforme `wrongCount`:

1. Cabeça (círculo)
2. Corpo (linha vertical)
3. Braço esquerdo
4. Braço direito
5. Perna esquerda
6. Perna direita

A forca (base + poste + viga + corda) é desenhada desde o início.

Cada parte nova aparece com animação via `AnimationController` + `CurvedAnimation(curve: Curves.easeOut)` acionada quando `wrongCount` aumenta.

---

## Widget: WordDisplay

- Uma linha de traços, um por letra da palavra
- Letras corretamente chutadas aparecem no traço em verde
- Espaços (se palavra composta) mostrados como espaço visual

---

## Widget: LetterKeyboard

- Grid A-Z em 6 colunas (26 letras = 4 linhas + 2 letras na última)
- Cada botão: fundo cinza claro (unguessed), verde (correct), vermelho (wrong)
- Fonte Fredoka, tamanho compacto para caber na tela

---

## Tela Principal (GameScreen)

Layout vertical:
```
AppBar — "Jogo da Forca" + indicador de nível
Hangman (CustomPainter, tamanho fixo ~200px altura)
WordDisplay (letras/traços)
Contagem de erros (ex: "Erros: 3/6")
LetterKeyboard
```

Overlays de vitória/derrota como AnimatedContainer sobre o layout, com botão "Próxima Palavra" ou "Tentar Novamente".

---

## Integração com Menu

Card novo no `MenuScreen`:
- Emoji: 🪢
- Título: "Jogo da Forca"
- Descrição: "Adivinhe a palavra letra por letra!"
- Tags: `['7 níveis', 'Vocabulário']`
- Gradient: azul (`Color(0xFF3B82F6)` → `Color(0xFF60A5FA)`)

---

## Fora do Escopo

- Recordes/persistência entre sessões
- Modo multiplayer
- Letras com acento no teclado
