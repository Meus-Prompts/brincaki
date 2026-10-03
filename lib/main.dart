// lib/main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/menu_screen.dart';

void main() {
  runApp(const BrincakiApp());
}

class BrincakiApp extends StatelessWidget {
  const BrincakiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brincaki',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFF59E0B),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFBEB),
        textTheme: GoogleFonts.fredokaTextTheme(),
      ),
      home: const MenuScreen(),
    );
  }
}
