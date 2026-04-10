import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../games/cacapalavras/screens/home_screen.dart' as cacapalavras;
import '../games/sudoku/screens/home_screen.dart' as sudoku;
import '../games/sudoku/providers/game_provider.dart';
import '../games/2048/screens/game_screen.dart';
import '../games/2048/providers/game_provider.dart';
import '../games/tictactoe/screens/game_screen.dart';
import '../games/tictactoe/providers/game_provider.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  void _openCacaPalavras(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Theme(
          data: ThemeData(
            colorSchemeSeed: Colors.deepPurple,
            useMaterial3: true,
            textTheme: GoogleFonts.fredokaTextTheme(),
          ),
          child: const cacapalavras.HomeScreen(),
        ),
      ),
    );
  }

  void _openSudoku(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => GameProvider(),
          child: Theme(
            data: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF121212),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFBB86FC),
                surface: Color(0xFF1E1E1E),
                error: Color(0xFFCF6679),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1E1E1E),
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBB86FC),
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => const sudoku.HomeScreen(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openGame2048(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => Game2048Provider(),
          child: Theme(
            data: ThemeData(
              colorSchemeSeed: const Color(0xFFF97316),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFFAF8EF),
            ),
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => const Game2048Screen(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openTicTacToe(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => TicTacToeProvider(),
          child: Theme(
            data: ThemeData(
              colorSchemeSeed: const Color(0xFFEC4899),
              useMaterial3: true,
              textTheme: GoogleFonts.fredokaTextTheme(),
            ),
            child: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => const TicTacToeScreen(),
            ),
          ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildGameCard(
                emoji: '🔍',
                title: 'Caça-Palavras',
                description: 'Encontre as palavras escondidas na grade',
                tags: const ['10 níveis', 'Português'],
                gradientColors: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                shadowColor: const Color(0xFFF59E0B),
                onTap: () => _openCacaPalavras(context),
              ),
              const SizedBox(height: 16),
              _buildGameCard(
                emoji: '🔢',
                title: 'Sudoku',
                description: 'Complete o tabuleiro de números',
                tags: const ['5 dificuldades', 'Lógica'],
                gradientColors: const [Color(0xFF10B981), Color(0xFF34D399)],
                shadowColor: const Color(0xFF10B981),
                onTap: () => _openSudoku(context),
              ),
              const SizedBox(height: 16),
              _buildGameCard(
                title: '2048',
                description: 'Some as peças e chegue ao 2048!',
                tags: const ['Swipe', 'Recorde'],
                gradientColors: const [Color(0xFFF97316), Color(0xFFFB923C)],
                shadowColor: const Color(0xFFF97316),
                onTap: () => _openGame2048(context),
                iconWidget: const Text(
                  '2048',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildGameCard(
                emoji: '✖️',
                title: 'Jogo da Velha',
                description: 'Dois jogadores, uma vitória!',
                tags: const ['2 Jogadores', 'Clássico'],
                gradientColors: const [Color(0xFFEC4899), Color(0xFFF472B6)],
                shadowColor: const Color(0xFFEC4899),
                onTap: () => _openTicTacToe(context),
              ),
              const SizedBox(height: 32),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text('🎮', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 8),
        Text(
          'Brincaki',
          style: GoogleFonts.fredoka(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF92400E),
            letterSpacing: 1,
          ),
        ),
        Text(
          'Escolha um jogo para brincar!',
          style: GoogleFonts.fredoka(
            fontSize: 16,
            color: const Color(0xFFB45309),
          ),
        ),
      ],
    );
  }

  Widget _buildGameCard({
    String? emoji,
    Widget? iconWidget,
    required String title,
    required String description,
    required List<String> tags,
    required List<Color> gradientColors,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: iconWidget ??
                    Text(emoji!, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.fredoka(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      'Sem anúncios · Sem dados · 100% diversão 🌟',
      style: GoogleFonts.fredoka(
        fontSize: 12,
        color: const Color(0xFFD97706),
      ),
    );
  }
}
