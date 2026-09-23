import 'dart:ui' as ui;

import 'package:flutter/material.dart';

const ink = Color(0xFF202841);
const muted = Color(0xFF63708A);
const blue = Color(0xFF425AE8);
const violet = Color(0xFF8554D8);
const teal = Color(0xFF087E83);
const canvas = Color(0xFFF1F4FC);
const line = Color(0xFFDCE3F2);
const mint = Color(0xFFDCF5EA);
const brandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF6183FF), blue, violet],
);

ThemeData passportTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: canvas,
  colorScheme: ColorScheme.fromSeed(
    seedColor: blue,
    primary: blue,
    surface: Colors.white,
  ),
  splashFactory: InkSparkle.splashFactory,
  dividerColor: line,
  iconTheme: const IconThemeData(color: muted, size: 21),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 38,
      height: 1.14,
      letterSpacing: -1.35,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 1.2,
      letterSpacing: -.7,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: ink),
    bodyMedium: TextStyle(fontSize: 15, height: 1.5, color: ink),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Color(0xB3FFFFFF),
    hintStyle: TextStyle(color: Color(0xFF89919D), fontSize: 15),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: blue, width: 1.6),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: blue,
      foregroundColor: Colors.white,
      elevation: 3,
      shadowColor: blue.withValues(alpha: .3),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: .1,
      ),
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ink,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      side: const BorderSide(color: line),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: blue,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  ),
  tooltipTheme: const TooltipThemeData(
    waitDuration: Duration(milliseconds: 450),
  ),
);

/// Static aurora washes keep the glass visible without continuous animation.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEEF1FF), Color(0xFFF5F7FC), Color(0xFFEDF7FA)],
          ),
        ),
      ),
      const Positioned(
        top: -210,
        right: -110,
        width: 850,
        height: 740,
        child: _ColorWash(Color(0xFFC5B8FF)),
      ),
      const Positioned(
        top: 210,
        left: -180,
        width: 720,
        height: 750,
        child: _ColorWash(Color(0xFFADDFF1)),
      ),
      const Positioned(
        bottom: -340,
        right: -100,
        width: 830,
        height: 750,
        child: _ColorWash(Color(0xFFF7D8D9)),
      ),
      child,
    ],
  );
}

class _ColorWash extends StatelessWidget {
  const _ColorWash(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [color.withValues(alpha: .7), color.withValues(alpha: 0)],
        ),
      ),
    ),
  );
}

/// Blurred glass is reserved for a few large surfaces. Repeated cards use the
/// same translucent finish without an expensive backdrop filter per item.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 24,
    this.blur = false,
    this.tint = blue,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool blur;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final content = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .9),
            Colors.white.withValues(alpha: .66),
            Color.lerp(Colors.white, tint, .14)!.withValues(alpha: .7),
          ],
        ),
        borderRadius: borderRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: .94),
          width: 1.2,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: tint.withValues(alpha: .08)),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: .07),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: blur
            ? BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: content,
              )
            : content,
      ),
    );
  }
}

Widget surface(Widget child, {EdgeInsets padding = const EdgeInsets.all(24)}) =>
    LiquidGlass(padding: padding, child: child);

/// Decorative, code-native glass objects; excluded from the reading order.
class GlassOrbit extends StatelessWidget {
  const GlassOrbit({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: SizedBox(
        width: 238,
        height: 218,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 31,
              top: 18,
              child: Container(
                width: 178,
                height: 178,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-.55, -.6),
                    radius: 1.15,
                    colors: [
                      Color(0xFFF4FEFF),
                      Color(0xFFACD8FA),
                      Color(0xFFB09AEF),
                      Color(0xFF718FE6),
                    ],
                    stops: [0, .35, .7, 1],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .85),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: violet.withValues(alpha: .19),
                      blurRadius: 28,
                      offset: const Offset(8, 18),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 26,
              top: 27,
              child: Transform.rotate(
                angle: -.16,
                child: LiquidGlass(
                  radius: 25,
                  padding: const EdgeInsets.all(19),
                  tint: violet,
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 44,
                    color: violet,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 5,
              bottom: 15,
              child: Transform.rotate(
                angle: .12,
                child: LiquidGlass(
                  blur: true,
                  radius: 24,
                  padding: const EdgeInsets.all(19),
                  tint: teal,
                  child: const Icon(
                    Icons.people_alt_rounded,
                    size: 45,
                    color: teal,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 24,
              child: Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: brandGradient,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: blue.withValues(alpha: .2),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 23,
                  color: Colors.white,
                ),
              ),
            ),
            const Positioned(
              right: 8,
              top: 5,
              child: Icon(Icons.add_rounded, color: violet, size: 23),
            ),
          ],
        ),
      ),
    ),
  );
}

Color levelColor(String level) => switch (level) {
  'Приоритетная' => const Color(0xFF087F66),
  'Готовая' => blue,
  'Рабочая' => const Color(0xFFB06000),
  _ => const Color(0xFF737780),
};

Widget levelPill(String level) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
  decoration: BoxDecoration(
    color: levelColor(level).withValues(alpha: .10),
    borderRadius: BorderRadius.circular(99),
  ),
  child: Text(
    level,
    style: TextStyle(
      color: levelColor(level),
      fontWeight: FontWeight.w600,
      fontSize: 12,
    ),
  ),
);

Color topicColor(String topic) => switch (topic) {
  'AI' => violet,
  'Веб' => blue,
  'Данные' => teal,
  'Мобильное' => const Color(0xFFB85630),
  _ => const Color(0xFF6F7C91),
};
IconData topicIcon(String topic) => switch (topic) {
  'AI' => Icons.auto_awesome_rounded,
  'Веб' => Icons.web_rounded,
  'Данные' => Icons.bar_chart_rounded,
  'Мобильное' => Icons.phone_iphone_rounded,
  _ => Icons.widgets_outlined,
};

Widget topicMark(String topic, {double size = 48}) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: .92),
        topicColor(topic).withValues(alpha: .2),
      ],
    ),
    border: Border.all(color: Colors.white.withValues(alpha: .95)),
    boxShadow: [
      BoxShadow(
        color: topicColor(topic).withValues(alpha: .1),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
    borderRadius: BorderRadius.circular(size * .3),
  ),
  child: Icon(topicIcon(topic), color: topicColor(topic), size: size * .47),
);

class HoverCard extends StatefulWidget {
  const HoverCard({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(24),
    this.accent = blue,
  });
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsets padding;
  final Color accent;
  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool hovered = false, focused = false;
  @override
  Widget build(BuildContext context) {
    final active = hovered || focused;
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, active ? -3 : 0, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, .52, 1],
          colors: [
            Color.lerp(Colors.white, widget.accent, active ? .13 : .08)!,
            Colors.white.withValues(alpha: .9),
            Color.lerp(
              Colors.white,
              widget.accent,
              .06,
            )!.withValues(alpha: .84),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: active ? widget.accent.withValues(alpha: .38) : Colors.white,
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accent.withValues(alpha: active ? .16 : .07),
            blurRadius: active ? 28 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: widget.onTap,
          onHover: (v) => setState(() => hovered = v),
          onFocusChange: (v) => setState(() => focused = v),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
  }
}

class ScoreRing extends StatelessWidget {
  const ScoreRing(this.score, {super.key, this.small = false});
  final int score;
  final bool small;
  @override
  Widget build(BuildContext context) {
    final color = score >= 70
        ? teal
        : score >= 40
        ? blue
        : const Color(0xFF9299A6);
    final size = small ? 42.0 : 112.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.white, color.withValues(alpha: .07)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .12),
            blurRadius: 25,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: small ? 3 : 7,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: color.withValues(alpha: .10),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: small ? 14 : 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.8,
                  color: ink,
                ),
              ),
              if (!small)
                const Text(
                  'из 100',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
