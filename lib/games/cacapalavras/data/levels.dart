// lib/games/cacapalavras/data/levels.dart

import '../models/game_state.dart';

class LevelConfig {
  const LevelConfig({
    required this.size,
    required this.wordCount,
    required this.directions,
    required this.theme,
    required this.words,
  });

  final int size;
  final int wordCount;
  final List<Direction> directions;
  final String theme;
  final List<String> words;
}

const _straight = [Direction.right, Direction.down];
const _oneDiagonal = [..._straight, Direction.downRight];
const _twoDiagonals = [..._oneDiagonal, Direction.upRight];
const _withBackwards = [..._twoDiagonals, Direction.left, Direction.up];
const _all = Direction.values;

/// Nível N = kLevels[N - 1]. Palavras em maiúsculas, sem acento.
const List<LevelConfig> kLevels = [
  LevelConfig(
    size: 6,
    wordCount: 4,
    directions: _straight,
    theme: 'Animais',
    words: [
      'GATO', 'CAO', 'PATO', 'SAPO', 'VACA', 'BOI', 'URSO', 'LEAO',
      'LOBO', 'RATO', 'PEIXE', 'FOCA', 'ONCA', 'COBRA', 'ZEBRA', 'TATU',
      'MACACO', 'CAVALO', 'COELHO', 'GALO',
    ],
  ),
  LevelConfig(
    size: 7,
    wordCount: 5,
    directions: _straight,
    theme: 'Frutas',
    words: [
      'UVA', 'PERA', 'MACA', 'KIWI', 'FIGO', 'CAQUI', 'MANGA', 'LIMAO',
      'BANANA', 'MELAO', 'AMORA', 'GOIABA', 'CEREJA', 'CAJU', 'COCO',
      'LARANJA', 'AMEIXA', 'ACAI', 'PITAYA', 'MAMAO',
    ],
  ),
  LevelConfig(
    size: 8,
    wordCount: 5,
    directions: _straight,
    theme: 'Cores',
    words: [
      'AZUL', 'VERDE', 'ROXO', 'ROSA', 'PRETO', 'BRANCO', 'CINZA', 'LILAS',
      'BEGE', 'MARROM', 'DOURADO', 'PRATA', 'LARANJA', 'AMARELO', 'VINHO',
      'CREME', 'ANIL', 'CORAL', 'SALMAO', 'VIOLETA', 'VERMELHO',
    ],
  ),
  LevelConfig(
    size: 8,
    wordCount: 6,
    directions: _oneDiagonal,
    theme: 'Corpo humano',
    words: [
      'CABECA', 'OLHO', 'NARIZ', 'BOCA', 'DENTE', 'LINGUA', 'ORELHA',
      'PESCOCO', 'OMBRO', 'BRACO', 'COTOVELO', 'MAO', 'DEDO', 'UNHA',
      'PERNA', 'JOELHO', 'BARRIGA', 'COSTAS', 'PEITO', 'CORACAO', 'PULMAO',
      'CABELO',
    ],
  ),
  LevelConfig(
    size: 9,
    wordCount: 7,
    directions: _twoDiagonals,
    theme: 'Casa',
    words: [
      'SALA', 'QUARTO', 'COZINHA', 'BANHEIRO', 'JANELA', 'PORTA', 'TELHADO',
      'ESCADA', 'PAREDE', 'SOFA', 'CAMA', 'MESA', 'CADEIRA', 'ARMARIO',
      'TAPETE', 'ESPELHO', 'GELADEIRA', 'FOGAO', 'CORTINA', 'VARANDA',
      'QUINTAL', 'GARAGEM',
    ],
  ),
  LevelConfig(
    size: 10,
    wordCount: 8,
    directions: _twoDiagonals,
    theme: 'Profissões',
    words: [
      'MEDICO', 'PROFESSOR', 'BOMBEIRO', 'POLICIAL', 'PADEIRO', 'PEDREIRO',
      'PILOTO', 'DENTISTA', 'CARTEIRO', 'MOTORISTA', 'ADVOGADO',
      'COZINHEIRO', 'ENFERMEIRO', 'PINTOR', 'ATOR', 'JUIZ', 'AGRICULTOR',
      'ENGENHEIRO', 'CANTOR', 'ARQUITETO', 'FOTOGRAFO',
    ],
  ),
  LevelConfig(
    size: 10,
    wordCount: 8,
    directions: _withBackwards,
    theme: 'Natureza',
    words: [
      'ARVORE', 'FLOR', 'FOLHA', 'RIO', 'MAR', 'LAGO', 'MONTANHA',
      'FLORESTA', 'CACHOEIRA', 'PEDRA', 'AREIA', 'NUVEM', 'CHUVA', 'VENTO',
      'SOL', 'LUA', 'ESTRELA', 'PRAIA', 'ILHA', 'VULCAO', 'SEMENTE', 'RAIZ',
    ],
  ),
  LevelConfig(
    size: 11,
    wordCount: 9,
    directions: _all,
    theme: 'Esportes',
    words: [
      'FUTEBOL', 'VOLEI', 'BASQUETE', 'TENIS', 'NATACAO', 'CORRIDA', 'JUDO',
      'KARATE', 'BOXE', 'SURFE', 'SKATE', 'CICLISMO', 'XADREZ', 'HANDEBOL',
      'GINASTICA', 'ATLETISMO', 'ESGRIMA', 'REMO', 'GOLFE', 'RUGBY',
      'BEISEBOL', 'CANOAGEM',
    ],
  ),
  LevelConfig(
    size: 12,
    wordCount: 10,
    directions: _all,
    theme: 'Países',
    words: [
      'BRASIL', 'PORTUGAL', 'ARGENTINA', 'CHILE', 'PERU', 'URUGUAI',
      'PARAGUAI', 'MEXICO', 'CANADA', 'ESPANHA', 'FRANCA', 'ITALIA',
      'ALEMANHA', 'JAPAO', 'CHINA', 'INDIA', 'EGITO', 'ANGOLA', 'MOCAMBIQUE',
      'AUSTRALIA', 'RUSSIA', 'GRECIA', 'MARROCOS',
    ],
  ),
  LevelConfig(
    size: 12,
    wordCount: 12,
    directions: _all,
    theme: 'Ciência',
    words: [
      'ATOMO', 'MOLECULA', 'CELULA', 'ENERGIA', 'GRAVIDADE', 'PLANETA',
      'GALAXIA', 'FOTOSSINTESE', 'MICROSCOPIO', 'TELESCOPIO', 'EVOLUCAO',
      'GENETICA', 'OXIGENIO', 'HIDROGENIO', 'ELETRON', 'PROTON', 'NEUTRON',
      'MAGNETISMO', 'ECLIPSE', 'FOSSIL', 'BACTERIA', 'VACINA', 'LABORATORIO',
    ],
  ),
];
