# Jogo das Sílabas: design

**Data:** 2026-10-18
**Projeto:** Brincaki
**Status:** Aprovado na conversa

---

## Objetivo

Um jogo novo, **Sílabas** 🔤, para treinar três conteúdos de português do 3º e 4º ano (8 a 9 anos):
- separar a palavra em sílabas;
- marcar a sílaba tônica;
- classificar a palavra pela posição da tônica: oxítona, paroxítona ou proparoxítona.

A criança que erra vê onde errou e tenta de novo, na mesma palavra. A partida tem 10 palavras e termina com a pontuação.

**Critério de sucesso**
- o 12º cartão do menu, depois do Xadrez, abre o jogo;
- dá para jogar uma partida inteira em cada nível, errando e acertando cada etapa;
- toda palavra da lista tem separação e tônica certas pela norma escolar;
- a palavra mais longa cabe em 320x568;
- `flutter analyze` sem avisos, `flutter test` verde e `tool/check_coverage.py` passando;
- `integration_test/app_test.dart` joga uma partida de Sílabas pelo app de verdade.

**Fora do escopo desta versão:** sons, recorde salvo, explicação das regras de separação, classificação pelo número de sílabas (monossílaba, dissílaba...), monossílabas tônicas e átonas, e outras atividades de português.

**Seria um fracasso se:**
- a lista tivesse uma palavra com separação ou tônica errada, ou com duas separações aceitas pela escola;
- a criança pudesse passar de etapa sem acertar;
- a tela de erro entregasse a resposta da separação de bandeja;
- a palavra não coubesse em 320x568.

**"Várias partes" (decisão minha):** este é um jogo próprio. Se mais tarde entrarem outras atividades de português, decide-se então se viram jogos próprios ou modos deste. Nada aqui antecipa essa estrutura.

## Restrições herdadas

Valem as regras do `CLAUDE.md`:
- textos, comentários e nomes de teste em pt-BR;
- Fredoka empacotada;
- nada de internet;
- módulo em `lib/games/silabas/`;
- provider criado pelo `GameShell` do menu;
- `GameScaffold`, `SoloSetup` e `ResultPanel`;
- todo arquivo começa com o comentário do próprio caminho;
- testes nas telas de 360x740 e 320x568.

---

## 1. Regras do jogo

### Uma partida
1. Na tela de início a criança escolhe o **nível** (Fácil, Médio ou Difícil) e toca em "Jogar!" (`SoloSetup`).
2. Saem **10 palavras** do nível, sorteadas sem repetir dentro da partida. Uma de cada vez.
3. Cada palavra tem **três etapas**, sempre nesta ordem. A etapa seguinte só abre quando a anterior está certa.
4. Depois da 3ª etapa certa, aparece a palavra resolvida e o botão **"Próxima palavra"**. Na 10ª, o botão é **"Ver resultado"**.
5. **Fim:** a última palavra resolvida continua visível e o `ResultPanel` mostra os pontos, as estrelas e os botões "Jogar de novo" (mesmo nível, novas palavras) e "Mudar nível" (volta à tela de início).

### Etapa 1: separar
- A palavra aparece com as letras grandes e um **espaço tocável entre cada par de letras vizinhas**.
- Tocar num espaço liga o corte (um risco na cor do jogo). Tocar de novo desliga.
- O botão **"Conferir"** fica desabilitado enquanto não houver nenhum corte.
- **Acerto:** os cortes coincidem exatamente com a separação da palavra. As letras se juntam em blocos de sílaba e a etapa 2 abre.
- **Erro (mostra o erro sem entregar a resposta):**
  - cada corte que não devia existir fica **vermelho**;
  - quando falta corte, aparece a dica "A palavra tem N sílabas";
  - se há cortes errados, a mensagem é "Os cortes em vermelho estão no lugar errado";
  - os cortes certos não são marcados como certos, para não entregar quais estão bons quando falta algum;
  - a criança mexe nos cortes (o vermelho some no primeiro toque) e confere de novo.
  - cada "Conferir" errado conta como **um** erro da etapa, mesmo quando mostra o vermelho e a dica juntos.

### Etapa 2: sílaba tônica
- As sílabas aparecem como blocos e a pergunta é "Qual é a sílaba mais forte?".
- Um toque já responde.
- **Acerto:** o bloco fica na cor do jogo (destacado) e a etapa 3 abre.
- **Erro:** o bloco tocado fica vermelho com "Essa não é a mais forte. Tente de novo!" e não pode mais ser tocado.

### Etapa 3: classificar
- A tônica continua destacada. A pergunta é "Como ela se chama?" e há três botões: **Oxítona**, **Paroxítona** e **Proparoxítona**, cada um com uma linha curta embaixo ("a última é a mais forte", "a penúltima...", "a antepenúltima...").
- **Acerto:** o botão fica verde e aparece a palavra resolvida.
- **Erro:** o botão fica vermelho e desabilitado, com "Quase! Conte as sílabas de trás para frente."

### Palavra resolvida
Mostra a separação com a tônica destacada (`pás · sa · ro`), a classificação ("Paroxítona") e os pontos ganhos na palavra ("+25").

### Pontos (decisão minha)
- Cada etapa vale **10** pontos quando é acertada na primeira tentativa, **5** depois de um erro e **2** depois de dois ou mais erros.
- Isso dá até **30** pontos por palavra e até **300** por partida.
- **Estrelas:** ⭐⭐⭐ a partir de 270, ⭐⭐ a partir de 180, ⭐ abaixo disso.
- O título do painel é "Mandou muito!" com 3 estrelas, "Muito bem!" com 2 e "Boa tentativa!" com 1.
- A mensagem é "N pontos de 300" seguida da linha das estrelas.

### Sair no meio
A seta de voltar pergunta "Sair do jogo?" (`confirmExit`) durante a partida. Na tela de início e no resultado, sai direto.

## 2. As palavras

### Formato
- Lista feita à mão em `lib/games/silabas/data/word_list.dart`, com pelo menos **40 palavras por nível**.
- Cada palavra é gravada com as sílabas separadas por hífen e a tônica em maiúsculas, por exemplo `'PÁS-sa-ro'`, `'ja-ca-RÉ'` e `'ja-NE-la'`.
- O código deriva o resto: as sílabas, o índice da tônica e a classificação, contando a tônica de trás para frente (1ª = oxítona, 2ª = paroxítona, 3ª = proparoxítona).
- A palavra mostrada é a junção das sílabas em minúsculas, com os acentos.

### Critérios da lista
- Os acentos ficam como na escrita, porque é assim que a criança vê a palavra na escola. Palavras com acento ajudam a achar a tônica, por isso cada nível também tem palavras sem acento.
- Tem **2 a 5 sílabas**, sem monossílabas.
- Tem **no máximo 10 letras**, para caber em 320 px.
- Cada nível tem as três classificações, com pelo menos 8 palavras de cada.
- Palavras conhecidas da criança e sem sentido ruim.
- **Fica fora** toda palavra com mais de uma separação aceita: ditongo crescente no fim, como his-tó-ria / his-tó-ri-a, á-gua, sé-rie e ci-ên-cia; casos como "pi-a-no / pia-no", "ru-im" e "su-a-ve". Na dúvida, a palavra sai da lista.
- **Regra concreta do ditongo crescente no fim** (o teste usa esta): a palavra sai se sua última sílaba é átona e (a) contém `i` ou `u` seguido de vogal (`ria`, `gua`, `cie`), ou (b) é só uma vogal e vem depois de outra sílaba átona terminada em `i` ou `u` (`ri-a`). Hiatos depois da tônica, como em po-e-SI-a e sa-Ú-de, continuam valendo, porque a separação deles é única na escola.
- **Til só na tônica** (decisão minha): ficam fora as palavras com til em sílaba átona, como órfã e órgão. Assim o teste "o acento gráfico está na tônica" vale para todos os acentos.

### Níveis
| | Fácil | Médio | Difícil |
|---|---|---|---|
| Sílabas | 2 a 3 | 2 a 4 | 3 a 5 |
| O que treina | sílabas simples (consoante + vogal), com acento visível em muitas oxítonas e proparoxítonas | dígrafos que se separam (rr, ss, sc, sç, xc) e que não se separam (ch, lh, nh, qu, gu), encontros consonantais (bl, br, pr, tr...), sílabas terminadas em consoante (r, s, l, m, n) | hiatos (sa-ú-de, po-e-si-a), ditongos que ficam juntos (cai-xa, pei-xe), palavras sem acento cuja tônica não é óbvia |
| Exemplos | BO-la, ja-NE-la, ca-FÉ, sa-PA-to, MÁ-gi-ca, so-FÁ | CAR-ro, PÁS-sa-ro, pa-LHA-ço, pro-FES-sor, nas-CER, bi-ci-CLE-ta | sa-Ú-de, po-e-SI-a, LÂM-pa-da, e-XÉR-ci-to, ju-VEN-tu-de, co-ra-ÇÃO |

Os exemplos acima são ilustrações; cada palavra da lista é conferida antes de entrar (ver Conferência).

### Conferência
Quem monta a lista confere cada palavra pela norma escolar (Acordo Ortográfico e VOLP da ABL). Os testes garantem a forma, não a ortografia.

**Como a conferência é feita (decisão minha):** depois de escrita, a lista passa por um revisor independente, no modelo mais capaz, que lê palavra por palavra a separação, a tônica e a classificação. Toda palavra que ele apontar como errada ou duvidosa é corrigida ou sai da lista. Essa conferência é uma tarefa própria do plano e acontece antes das telas. Uma pessoa ainda pode revisar a lista depois. Ela fica toda num arquivo só, fácil de ler.

## 3. Telas

Esboço aprovado na conversa: três etapas na mesma tela, com o progresso e os pontos no topo.

**Início:** `SoloSetup` com 🔤, título "Sílabas", rótulo "Nível" e as opções `['Fácil', 'Médio', 'Difícil']`. O nível escolhido fica marcado ao voltar.

**Jogo** (título do AppBar "Sílabas • Fácil", por exemplo)
- Faixa de status com "Palavra 3 de 10" e "⭐ 45".
- Instrução da etapa em uma linha, por exemplo "Toque entre as letras para separar as sílabas".
- A palavra, que é o elemento central:
  - na etapa 1, as letras e os espaços tocáveis;
  - nas etapas 2 e 3, os blocos de sílaba.
- A mensagem de erro, quando houver, em vermelho embaixo da palavra.
- Embaixo vem o botão "Conferir" (etapa 1), os três botões de classificação (etapa 3) ou o cartão da palavra resolvida com "Próxima palavra".
- O espaço tocável entre as letras tem pelo menos **24 px de largura** e a altura da letra. Assim, numa palavra de 10 letras em 320 px, as letras encolhem (com `FittedBox` ou um tamanho calculado) e os espaços continuam com 24 px.

**Paleta** `kSilabasPalette`, ciano, que nenhum outro jogo usa:
- accent `0xFF0891B2`
- light `0xFF22D3EE`
- dark `0xFF155E75`
- background `0xFFECFEFF`

**Menu:** o cartão vem depois do Xadrez, com 🔤, "Sílabas", "Separe as sílabas e ache a mais forte!" e as tags `['Português', '3 níveis']`.

## 4. Arquitetura

Segue o padrão do `CLAUDE.md`. Os nomes abaixo são a proposta e o construtor pode ajustar detalhes internos.

```
lib/games/silabas/
  models/game_state.dart       enum SilabasPhase { setup, playing, finished }
                               enum SilabasStep { split, stress, classify, solved }
                               enum StressClass { oxitona, paroxitona, proparoxitona }
  logic/word.dart              class SilabasWord { syllables, stressIndex, text, stressClass, cutPositions }
                               SilabasWord parseWord(String encoded)   // 'PÁS-sa-ro'
  data/word_list.dart          const Map<int, List<String>> kSilabasWordsByLevel  // 0 fácil, 1 médio, 2 difícil
  providers/game_provider.dart SilabasProvider({Random? random})
  screens/game_screen.dart     SilabasScreen (+ _GameBody, _Result privados)
  widgets/split_word.dart      letras + espaços tocáveis (etapa 1)
  widgets/syllable_blocks.dart blocos de sílaba (etapas 2, 3 e resolvida)
  widgets/classify_buttons.dart três botões (etapa 3)
```

**Cortes:** a posição de um corte é o índice da letra antes da qual ele fica (de 1 a `text.length − 1`). As posições são contadas em letras da palavra exibida. Uma letra acentuada conta como uma só (a lista usa caracteres pré-compostos, NFC, e o teste confere isso).

**`SilabasProvider`**
- Estado:
  - partida: `phase`, `level`, `index` (0–9), `word`, `step`, `score`, `wordPoints`;
  - etapa 1: `cuts` (Set<int>) e `wrongCuts` (Set<int>, os vermelhos depois de conferir); `missingHint` (int? com o total de sílabas quando falta corte);
  - etapa 2: `wrongStress` (Set<int>);
  - etapa 3: `wrongClasses` (Set<StressClass>);
  - pontos e fim: `errorsInStep`, `stars`.
- Métodos (cada um confere a fase e a etapa primeiro):
  - `start(int level)`;
  - `toggleCut(int pos)`, que também limpa `wrongCuts` e `missingHint`, e `checkSplit()`;
  - `chooseStress(int i)`;
  - `chooseClass(StressClass c)`;
  - `nextWord()`, que leva a `finished` depois da 10ª palavra;
  - `playAgain()` e `exitToSetup()`.
- `Random` injetável. O sorteio pega 10 palavras distintas do nível. Não há timers nem trabalho assíncrono.

**Menu:** `_openSilabas` com `GameShell`, `ChangeNotifierProvider(create: (_) => SilabasProvider())` e `kSilabasPalette.theme`.

## 5. Testes

- `test/games/silabas/word_test.dart`: o `parseWord` em oxítona, paroxítona e proparoxítona, com as posições de corte certas, o texto em minúsculas e entradas inválidas (sem tônica, duas tônicas, tônica antes da antepenúltima) que disparam erro.
- `test/games/silabas/word_list_test.dart`, que vale para **toda** a lista:
  - cada palavra é válida para o `parseWord`;
  - está em NFC;
  - tem de 2 a 5 sílabas e até 10 letras;
  - não se repete entre os níveis;
  - cada nível tem pelo menos 40 palavras e pelo menos 8 de cada classificação;
  - só usa letras do português;
  - a palavra com acento gráfico tem o acento na tônica (pega erros de digitação como `'pas-SA-ro'` para pássaro);
  - nenhuma palavra termina em ditongo crescente átono (pega `his-tó-ria`).
- `game_provider_test.dart`:
  - 10 palavras distintas com a semente;
  - corte liga e desliga;
  - conferir com corte errado (fica vermelho), com corte faltando (dica de N) e com os dois casos ao mesmo tempo;
  - tocar limpa o vermelho;
  - tônica e classificação erradas e depois certas;
  - pontos 10/5/2 por etapa e estrelas nos limites 270 e 180;
  - fim depois da 10ª palavra, "Jogar de novo" e "Mudar nível";
  - guardas de fase e de etapa.
- `widgets_test.dart`: espaços tocáveis, blocos e botões, com os estados normal, errado e destacado.
- `game_screen_test.dart`: o fluxo inteiro (início → separar errando → separar certo → tônica errando → certo → classificar errando → certo → próxima → ... → resultado → cada botão → voltar), em 360x740 e 320x568, com a palavra mais longa da lista sem overflow, mais o diálogo "Sair do jogo?".
- `test/screens/menu_screen_test.dart`: o cartão novo abre o jogo.
- `integration_test/app_test.dart`: abre Sílabas pelo menu e joga as 10 palavras tocando na tela. Lê `provider.word` para saber onde cortar, a tônica e a classificação. Erra uma vez, vê o painel e volta.

## 6. Fluxo de trabalho

O plano fica em `docs/superpowers/plans/2026-10-18-jogo-silabas.md`. Os commits são pequenos, como `feat(silabas): ...` e `test(silabas): ...`, no branch `feat/silabas`. O `CLAUDE.md` passa a dizer doze jogos.
