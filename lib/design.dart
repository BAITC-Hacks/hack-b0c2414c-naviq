import 'package:flutter/material.dart';

const ink = Color(0xFF202124);
const muted = Color(0xFF6B7280);
const blue = Color(0xFF1967D2);
const canvas = Color(0xFFF7F9FC);
const line = Color(0xFFE8EBF0);
const mint = Color(0xFFE6F4EA);

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
    fillColor: Color(0xFFF8FAFD),
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

Widget surface(Widget child, {EdgeInsets padding = const EdgeInsets.all(24)}) =>
    Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF0F2F6)),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x050F2244),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

Color levelColor(String level) => switch (level) {
  'Приоритетная' => const Color(0xFF188038),
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
  'AI' => const Color(0xFF7462E0),
  'Веб' => const Color(0xFF1A73E8),
  'Данные' => const Color(0xFF13866A),
  'Мобильное' => const Color(0xFFCE6D37),
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
    color: topicColor(topic).withValues(alpha: .09),
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
  });
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsets padding;
  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool hovered = false, focused = false;
  @override
  Widget build(BuildContext context) {
    final active = hovered || focused;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, active ? -3 : 0, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: active ? const Color(0xFFC5D8F6) : line),
        boxShadow: [
          BoxShadow(
            color: Color(active ? 0x100C2D64 : 0x030C2D64),
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
        ? const Color(0xFF188038)
        : score >= 40
        ? blue
        : const Color(0xFF9299A6);
    final size = small ? 42.0 : 112.0;
    return SizedBox(
      width: size,
      height: size,
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
