// lib/games/contas/models/game_state.dart

/// `mistake`: a criança errou e vê a resposta certa antes de continuar.
enum ContasPhase { setup, playing, mistake, finished }

enum Operation { addition, subtraction, multiplication, division }

enum AnswerMode { keyboard, choices }
