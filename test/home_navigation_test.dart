import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_passport/design.dart';
import 'package:task_passport/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Use Flutter's bundled font instead of the oversized Ahem test glyphs.
    // Resolve the SDK through package metadata so no host path is hard-coded.
    final config = File('.dart_tool/package_config.json').absolute;
    final packages =
        (jsonDecode(await config.readAsString()) as Map)['packages'] as List;
    final flutterPackage =
        packages.singleWhere((package) => package['name'] == 'flutter') as Map;
    final flutterDirectory = Directory.fromUri(
      config.uri.resolve(flutterPackage['rootUri'] as String),
    );
    final loader = FontLoader('Roboto');
    for (final weight in ['regular', 'medium', 'bold']) {
      final font = File.fromUri(
        flutterDirectory.uri.resolve(
          '../../bin/cache/artifacts/material_fonts/roboto-$weight.ttf',
        ),
      );
      loader.addFont(font.readAsBytes().then(ByteData.sublistView));
    }
    await loader.load();
  });

  for (final size in [const Size(1440, 1000), const Size(390, 844)]) {
    final desktop = size.width >= 980;
    testWidgets(
      'NaviQ logo returns to the catalogue on ${desktop ? 'desktop' : 'mobile'}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        // Widget tests block real HTTP requests. Navigation must still work
        // when the API is unavailable; this test never publishes any data.
        final theme = passportTheme();
        await tester.pumpWidget(
          MaterialApp(
            theme: theme.copyWith(
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontFamily: 'Roboto'),
                ),
              ),
            ),
            home: const Home(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.text(desktop ? 'Создать задачу' : 'Создать').first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Новая задача'), findsOneWidget);

        final logo = find.byKey(const ValueKey('home-logo'));
        expect(logo, findsOneWidget);
        await tester.tap(logo);
        await tester.pumpAndSettle();

        expect(find.text('Новая задача'), findsNothing);
        expect(find.text('Каталог задач'), findsWidgets);
        expect(
          find.text('От идеи\nк большему.', findRichText: true),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
