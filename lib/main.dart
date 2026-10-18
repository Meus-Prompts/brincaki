// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/menu_screen.dart';
import 'widgets/phone_frame.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureApp();
  runApp(const BrincakiApp());
}

/// Fontes só do próprio app (funciona sem internet) e tela sempre na vertical.
Future<void> configureApp() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      'assets/termo/LICENSE-fserb-pt-br.txt',
    );
    yield LicenseEntryWithLineBreaks(['fserb/pt-br'], license);
  });
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
      builder: (context, child) => PhoneFrame(enabled: kIsWeb, child: child!),
      home: const MenuScreen(),
    );
  }
}
