import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_passport/design.dart';

void main() {
  test('Accent labels retain readable contrast on light glass', () {
    for (final foreground in [
      ink,
      muted,
      blue,
      violet,
      teal,
      topicColor('Мобильное'),
    ]) {
      final contrast =
          (Colors.white.computeLuminance() + .05) /
          (foreground.computeLuminance() + .05);
      expect(
        contrast,
        greaterThanOrEqualTo(4.5),
        reason: '$foreground on white',
      );
    }
  });

  testWidgets('Glass surfaces render at compact and desktop widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [390.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 960);
      await tester.pumpWidget(
        MaterialApp(
          theme: passportTheme(),
          home: Scaffold(
            body: AuroraBackground(
              child: ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  const LiquidGlass(blur: true, child: Text('Понятная задача')),
                  const SizedBox(height: 20),
                  surface(
                    const Column(children: [GlassOrbit(), ScoreRing(75)]),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Понятная задача'), findsOneWidget);
    }
  });

  testWidgets('Card keeps its tap action and respects reduced motion', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: passportTheme(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: HoverCard(
                  accent: violet,
                  onTap: () => taps++,
                  child: const Text('Открыть задачу'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(HoverCard),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(container.duration, Duration.zero);
    // The glass material must not block taps, including with reduced motion.
    expect(find.byType(BackdropFilter), findsOneWidget);
    await tester.tap(find.text('Открыть задачу'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
