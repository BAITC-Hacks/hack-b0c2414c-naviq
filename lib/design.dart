import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';

const ink = Color(0xFF142743);
const muted = Color(0xFF586A80);
const blue = Color(0xFF315CF5);
const violet = Color(0xFF7856D8);
const teal = Color(0xFF087B80);
const canvas = Color(0xFFF0F6FC);
const line = Color(0xFFDDE7F2);
const mint = Color(0xFFDCF5EA);
const brandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF74A6FF), blue, Color(0xFF4F48D9)],
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
    fillColor: Color(0xA8FFFFFF),
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
      elevation: 0,
      shadowColor: blue.withValues(alpha: .22),
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

/// Soft light beneath the translucent surfaces. Nothing animates continuously.
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
            colors: [Color(0xFFEAF3FE), Color(0xFFF7FAFF), Color(0xFFEDF7FA)],
          ),
        ),
      ),
      const Positioned(
        top: -230,
        right: -170,
        width: 1010,
        height: 760,
        child: _ColorWash(Color(0xFFB2D1FF)),
      ),
      const Positioned(
        top: 170,
        left: -280,
        width: 770,
        height: 820,
        child: _ColorWash(Color(0xFFBDECE7)),
      ),
      const Positioned(
        bottom: -370,
        right: 80,
        width: 950,
        height: 760,
        child: _ColorWash(Color(0xFFDCD6FF)),
      ),
      const Positioned.fill(
        child: IgnorePointer(child: CustomPaint(painter: _LightContours())),
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
          colors: [color.withValues(alpha: .78), color.withValues(alpha: 0)],
        ),
      ),
    ),
  );
}

class _LightContours extends CustomPainter {
  const _LightContours();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .54);
    for (var i = 0; i < 3; i++) {
      final shift = i * 22.0;
      final path = Path()
        ..moveTo(size.width * .45 + shift, -20)
        ..cubicTo(
          size.width * .2 + shift,
          size.height * .38,
          size.width * 1.05 + shift,
          size.height * .5,
          size.width * .95 + shift,
          size.height + 20,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_LightContours oldDelegate) => false;
}

/// A translucent material with real backdrop diffusion, a thick optical rim,
/// and separate contact / cast shadows. Blur is opt-in for large surfaces;
/// repeated catalog cards use a shared backdrop group for efficient diffusion.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 24,
    this.blur = false,
    this.tint = blue,
    this.opacity,
    this.blurSigma = 22,
    this.elevation = 1,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool blur;
  final Color tint;
  final double? opacity;
  final double blurSigma;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final alpha = opacity ?? (blur ? .52 : .82);
    final content = CustomPaint(
      foregroundPainter: _GlassRim(radius: radius, tint: tint),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0, .37, .7, 1],
            colors: [
              Colors.white.withValues(alpha: (alpha + .23).clamp(0, 1)),
              Colors.white.withValues(alpha: alpha),
              Color.lerp(
                Colors.white,
                tint,
                .035,
              )!.withValues(alpha: (alpha - .10).clamp(0, 1)),
              Colors.white.withValues(alpha: (alpha + .08).clamp(0, 1)),
            ],
          ),
          borderRadius: borderRadius,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          if (elevation > 0) ...[
            BoxShadow(
              color: const Color(0xFF255280)
                  .withValues(alpha: .075 * elevation),
              blurRadius: 32,
              spreadRadius: -8,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: const Color(0xFF3A6694).withValues(alpha: .05 * elevation),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: blur
            ? BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: blurSigma,
                  sigmaY: blurSigma,
                ),
                child: content,
              )
            : content,
      ),
    );
  }
}

/// The opposing light/dark edge bands give clear material visible thickness.
/// A clipped rim avoids painting over either content or neighboring surfaces.
class _GlassRim extends CustomPainter {
  _GlassRim({
    required this.radius,
    required this.tint,
    this.pointer,
    this.active = false,
  }) : super(repaint: pointer);

  final double radius;
  final Color tint;
  final ValueNotifier<Offset?>? pointer;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    RRect shape(double inset) => RRect.fromRectAndRadius(
      bounds.deflate(inset),
      Radius.circular(math.max(0, radius - inset)),
    );
    final bevel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..shader = const LinearGradient(
        begin: Alignment(-.8, -1),
        end: Alignment(.8, 1),
        colors: [
          Color(0xBFFFFFFF),
          Color(0x16FFFFFF),
          Color(0x00709BC4),
          Color(0x12709BC4),
          Color(0x77FFFFFF),
        ],
        stops: [0, .25, .56, .85, 1],
      ).createShader(bounds);
    canvas.drawRRect(shape(2.5), bevel);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Colors.white.withValues(alpha: .84),
          tint.withValues(alpha: active ? .24 : .10),
          Colors.white.withValues(alpha: .94),
        ],
        stops: const [0, .32, .74, 1],
      ).createShader(bounds);
    canvas.drawRRect(shape(.65), edge);
    canvas.drawRRect(
      shape(5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withValues(alpha: .035),
            Colors.white.withValues(alpha: .06),
            Colors.white.withValues(alpha: .58),
          ],
        ).createShader(bounds),
    );
    final light = pointer?.value;
    if (active && light != null) {
      final glow = Paint()
        ..shader = ui.Gradient.radial(light, 190, [
          Colors.white.withValues(alpha: .22),
          Colors.white.withValues(alpha: 0),
        ]);
      canvas.save();
      canvas.clipRRect(shape(1));
      canvas.drawRect(bounds, glow);
      canvas.restore();
      canvas.drawRRect(
        shape(1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7
          ..shader = ui.Gradient.radial(light, 170, [
            Colors.white,
            const Color(0x00FFFFFF),
          ]),
      );
    }
  }

  @override
  bool shouldRepaint(_GlassRim oldDelegate) =>
      radius != oldDelegate.radius ||
      tint != oldDelegate.tint ||
      pointer != oldDelegate.pointer ||
      active != oldDelegate.active;
}

Widget surface(Widget child, {EdgeInsets padding = const EdgeInsets.all(24)}) =>
    LiquidGlass(padding: padding, child: child);

/// Decorative, code-native glass sculpture; excluded from the reading order.
class GlassOrbit extends StatelessWidget {
  const GlassOrbit({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: SizedBox(
        width: 300,
        height: 260,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _GlassSculpture()),
            ),
            Positioned(
              left: 2,
              top: 23,
              child: Transform.rotate(
                angle: -.10,
                child: LiquidGlass(
                  radius: 22,
                  blur: true,
                  blurSigma: 8,
                  opacity: .32,
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: 109,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.description_rounded,
                              color: blue,
                              size: 19,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Идея',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _sketchLine(98, blue.withValues(alpha: .24)),
                        const SizedBox(height: 6),
                        _sketchLine(77, blue.withValues(alpha: .12)),
                        const SizedBox(height: 6),
                        _sketchLine(87, blue.withValues(alpha: .12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -3,
              bottom: 23,
              child: Transform.rotate(
                angle: .09,
                child: LiquidGlass(
                  blur: true,
                  blurSigma: 9,
                  opacity: .39,
                  radius: 22,
                  padding: const EdgeInsets.all(14),
                  tint: teal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Команда',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 101,
                        height: 31,
                        child: Stack(
                          children: [
                            _avatar(0, 'A', const Color(0xFF7199FB)),
                            _avatar(23, 'M', const Color(0xFF79C9C4)),
                            _avatar(46, 'D', const Color(0xFF9B8CDD)),
                            const Positioned(
                              right: 0,
                              top: 6,
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: teal,
                                size: 19,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 42,
              bottom: 29,
              child: Transform.rotate(
                angle: -.14,
                child: LiquidGlass(
                  blur: true,
                  blurSigma: 5,
                  opacity: .35,
                  radius: 17,
                  padding: const EdgeInsets.all(13),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 25,
                    color: blue,
                  ),
                ),
              ),
            ),
            const Positioned(
              right: 13,
              top: 26,
              child: Icon(
                Icons.add_rounded,
                color: Color(0xFF91B1ED),
                size: 23,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _sketchLine(double width, Color color) => Container(
    width: width,
    height: 4,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(4),
    ),
  );

  Widget _avatar(double left, String initial, Color color) => Positioned(
    left: left,
    child: Container(
      width: 31,
      height: 31,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: const Color(0xFFEFF8FF), width: 2),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    ),
  );
}

/// Layered vector optics for the hero sculpture. The edge bands model the
/// changing light through a curved glass cross-section; cards above it use
/// actual backdrop blur. No renderer-specific fragment shader is required.
class _GlassSculpture extends CustomPainter {
  const _GlassSculpture();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 300, size.height / 260);
    final shadow = Paint()
      ..color = blue.withValues(alpha: .13)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 17);
    canvas.drawOval(const Rect.fromLTWH(82, 210, 163, 21), shadow);

    // Rear cobalt link; the second clear link catches its color at the overlap.
    _loop(
      canvas,
      center: const Offset(184, 117),
      angle: .46,
      rect: const Rect.fromLTWH(-43, -78, 86, 156),
      width: 27,
      clear: false,
    );
    _loop(
      canvas,
      center: const Offset(148, 144),
      angle: -.54,
      rect: const Rect.fromLTWH(-63, -47, 126, 94),
      width: 25,
      clear: true,
    );

    final bead = const Rect.fromLTWH(235, 90, 22, 22);
    canvas.drawOval(
      bead.shift(const Offset(0, 6)),
      Paint()
        ..color = teal.withValues(alpha: .15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawOval(
      bead,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.45, -.6),
          radius: 1,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFB4EFF0),
            Color(0xFF51AAAF),
            Color(0xFFDCF9FC),
          ],
          stops: [0, .4, .82, 1],
        ).createShader(bead),
    );
    canvas.drawOval(
      bead.deflate(.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .8),
    );
    canvas.restore();
  }

  void _loop(
    Canvas canvas, {
    required Offset center,
    required double angle,
    required Rect rect,
    required double width,
    required bool clear,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(44)));
    final bounds = rect.inflate(width);
    Paint stroke(double thickness) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      path.shift(const Offset(4, 10)),
      stroke(width + 3)
        ..color = const Color(0xFF4175BD).withValues(alpha: clear ? .12 : .18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawPath(
      path.shift(const Offset(2, 5)),
      stroke(width)
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: clear
              ? const [
                  Color(0xBBF5FFFF),
                  Color(0x88476BA6),
                  Color(0xBBBCD3F3),
                  Color(0xCCE0FFFF),
                ]
              : const [
                  Color(0xFF80B4FF),
                  Color(0xFF2847AB),
                  Color(0xFF337BDE),
                  Color(0xFFAFD1FF),
                ],
        ).createShader(bounds),
    );
    canvas.drawPath(
      path,
      stroke(width)
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: clear
              ? const [
                  Color(0xFFFFFFFF),
                  Color(0x99B0D5F4),
                  Color(0xB8DAEEFF),
                  Color(0x804F85C1),
                  Color(0xDBF6FFFF),
                ]
              : const [
                  Color(0xFFF1FFFF),
                  Color(0xFF92C8FF),
                  Color(0xFF558FEF),
                  Color(0xFF4167DE),
                  Color(0xFFABCDFE),
                ],
          stops: const [0, .22, .5, .74, 1],
        ).createShader(bounds),
    );
    canvas.drawPath(
      path.shift(const Offset(-2, -3)),
      stroke(width * .66)
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .85),
            Colors.white.withValues(alpha: clear ? .12 : .40),
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: .43),
          ],
          stops: const [0, .31, .59, 1],
        ).createShader(bounds),
    );

    // Sharp outer and inner highlights make the transparent edges legible.
    final outer = RRect.fromRectAndRadius(
      rect.inflate(width / 2 - .7),
      Radius.circular(44 + width / 2),
    );
    final inner = RRect.fromRectAndRadius(
      rect.deflate(width / 2 - .7),
      Radius.circular(44 - width / 2),
    );
    final edgeShader = const LinearGradient(
      begin: Alignment(-1, -1),
      end: Alignment(1, 1),
      colors: [
        Color(0xFFFFFFFF),
        Color(0xDFFFFFFF),
        Color(0x14426EAD),
        Color(0xCBEEFFFF),
      ],
      stops: [0, .25, .64, 1],
    ).createShader(bounds);
    canvas.drawRRect(outer, stroke(1.3)..shader = edgeShader);
    canvas.drawRRect(inner, stroke(1.8)..shader = edgeShader);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(width / 2 - 3),
        Radius.circular(44 - width / 2 + 3),
      ),
      stroke(1)
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x4D477ABB), Color(0x00FFFFFF), Color(0xBAFFFFFF)],
        ).createShader(bounds),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlassSculpture oldDelegate) => false;
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
  final _pointer = ValueNotifier<Offset?>(null);

  @override
  void dispose() {
    _pointer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = hovered || focused;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedContainer(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(
        0,
        active && !reduceMotion ? -4 : 0,
        0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: active
              ? widget.accent.withValues(alpha: .22)
              : Colors.white.withValues(alpha: .94),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B5286)
                .withValues(alpha: active ? .11 : .055),
            blurRadius: active ? 28 : 20,
            spreadRadius: active ? -3 : -7,
            offset: Offset(0, active ? 15 : 9),
          ),
          BoxShadow(
            color: widget.accent.withValues(alpha: active ? .07 : .03),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter.grouped(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0, .25, .64, 1],
                colors: [
                  Colors.white.withValues(alpha: .80),
                  Colors.white.withValues(alpha: active ? .72 : .66),
                  Colors.white.withValues(alpha: active ? .68 : .60),
                  Color.lerp(
                    Colors.white,
                    widget.accent,
                    active ? .08 : .045,
                  )!.withValues(alpha: .71),
                ],
              ),
            ),
            child: MouseRegion(
              onHover: reduceMotion
                  ? null
                  : (event) => _pointer.value = event.localPosition,
              onExit: (_) => _pointer.value = null,
              child: CustomPaint(
                foregroundPainter: _GlassRim(
                  radius: 28,
                  tint: widget.accent,
                  pointer: reduceMotion ? null : _pointer,
                  active: active,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    splashColor: widget.accent.withValues(alpha: .055),
                    hoverColor: widget.accent.withValues(alpha: .015),
                    focusColor: widget.accent.withValues(alpha: .07),
                    onTap: widget.onTap,
                    onHover: (v) => setState(() => hovered = v),
                    onFocusChange: (v) => setState(() => focused = v),
                    child: Padding(
                      padding: widget.padding,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
