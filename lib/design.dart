import 'package:flutter/material.dart';

const ink = Color(0xFF17233D);
const muted = Color(0xFF6D7891);
const blue = Color(0xFF3459E6);
const canvas = Color(0xFFF5F7FB);
const line = Color(0xFFE3E8F2);
const mint = Color(0xFFDBF7E8);

ThemeData passportTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: canvas,
  colorScheme: ColorScheme.fromSeed(
    seedColor: blue,
    primary: blue,
    surface: Colors.white,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 34,
      height: 1.15,
      fontWeight: FontWeight.w800,
      color: ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 26,
      height: 1.2,
      fontWeight: FontWeight.w800,
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
    bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: ink),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: blue, width: 1.6),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: line),
    ),
  ),
);

Widget surface(Widget child, {EdgeInsets padding = const EdgeInsets.all(24)}) =>
    Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F2244),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

Color levelColor(String level) => switch (level) {
  'Приоритетная' => const Color(0xFF15875C),
  'Готовая' => const Color(0xFF2769C8),
  'Рабочая' => const Color(0xFFB27A13),
  _ => const Color(0xFF8C6570),
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
      fontWeight: FontWeight.w700,
      fontSize: 12,
    ),
  ),
);
