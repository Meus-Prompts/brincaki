// test/widgets/phone_frame_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brincaki/widgets/phone_frame.dart';

Future<Size> pumpFrame(
  WidgetTester tester,
  Size screen, {
  bool enabled = true,
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late Size seen;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => PhoneFrame(enabled: enabled, child: child!),
      home: Builder(
        builder: (context) {
          seen = MediaQuery.of(context).size;
          return const Scaffold(body: Text('jogo', key: Key('jogo')));
        },
      ),
    ),
  );
  return seen;
}

void main() {
  testWidgets('em tela larga o app fica numa coluna de 480 no meio', (
    tester,
  ) async {
    final seen = await pumpFrame(tester, const Size(1200, 800));
    expect(seen, const Size(480, 800));
    final rect = tester.getRect(find.byType(Scaffold));
    expect(rect.width, 480);
    expect(rect.left, 360);
  });

  testWidgets('em tela de celular não muda nada', (tester) async {
    final seen = await pumpFrame(tester, const Size(360, 740));
    expect(seen, const Size(360, 740));
    expect(tester.getRect(find.byType(Scaffold)).width, 360);
  });

  testWidgets('desligado (fora da web) não muda nada', (tester) async {
    final seen = await pumpFrame(tester, const Size(1200, 800), enabled: false);
    expect(seen, const Size(1200, 800));
  });
}
