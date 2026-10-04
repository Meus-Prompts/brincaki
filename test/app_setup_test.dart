// test/app_setup_test.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brincaki/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('as fontes Fredoka estão empacotadas no app', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    for (final weight in ['Light', 'Regular', 'Medium', 'SemiBold', 'Bold']) {
      expect(manifest.listAssets(),
          contains('assets/google_fonts/Fredoka-$weight.ttf'));
    }
  });

  test('configureApp usa só as fontes locais e trava o app na vertical',
      () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    GoogleFonts.config.allowRuntimeFetching = true;

    await configureApp();

    expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
    final orientation = calls
        .singleWhere((c) => c.method == 'SystemChrome.setPreferredOrientations');
    expect(orientation.arguments, ['DeviceOrientation.portraitUp']);
  });

  test('a licença das palavras do Termo aparece na tela de licenças',
      () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await configureApp();
    final licenses = await LicenseRegistry.licenses.toList();
    expect(
      licenses.any((l) => l.packages.contains('fserb/pt-br')),
      isTrue,
    );
  });
}
