import 'package:flutter/material.dart';

/// フォントファミリー名（アセットとしてバンドル済み）
const String kFontDotGothic16 = 'DotGothic16';
const String kFontPressStart2P = 'PressStart2P';

// ぶたそだて GBC風パレット（design-rules.html準拠）
class ButaColors {
  // Foundation
  static const bg = Color(0xFFF4ECD8);
  static const bgDeep = Color(0xFFE8D9B0);
  static const paper = Color(0xFFFFF8E6);
  static const paperShadow = Color(0xFFD8C896);
  static const ink = Color(0xFF1A1228);
  static const ink2 = Color(0xFF3D2B4D);
  static const black = Color(0xFF0A0612);
  static const white = Color(0xFFFFFDF2);

  // Pink family
  static const pinkHi = Color(0xFFFFE2EB);
  static const pinkLo = Color(0xFFFFC8D8);
  static const pink = Color(0xFFFF9BB3);
  static const pinkDk = Color(0xFFC46A85);

  // Feedback
  static const red = Color(0xFFE8485A);
  static const redDk = Color(0xFF9C1D3A);
  static const yellow = Color(0xFFF6C453);
  static const yellowDk = Color(0xFFB0822A);
  static const green = Color(0xFF6CB979);
  static const greenDk = Color(0xFF2F6B3C);
  static const blue = Color(0xFF5A8ED1);
  static const blueDk = Color(0xFF2D4E8A);

  // Neutral
  static const brown = Color(0xFF8A5A2B);
  static const brownDk = Color(0xFF5A3814);
  static const gray = Color(0xFFB8A99A);
  static const grayDk = Color(0xFF6B5D4F);

  // Aliases
  static const background = blue; // 青空ベース
  static const surface = paper;
  static const primary = pink;
  static const error = red;
  static const textPrimary = ink;
  static const textOnDark = paper;
  static const tabBarBg = black; // タブバー背景
}

final butaTheme = ThemeData(
  useMaterial3: true,
  fontFamily: kFontDotGothic16,
  colorScheme: ColorScheme.dark(
    primary: ButaColors.primary,
    surface: ButaColors.blue,
    error: ButaColors.error,
  ),
  scaffoldBackgroundColor: ButaColors.blue,
  appBarTheme: const AppBarTheme(
    backgroundColor: ButaColors.background,
    foregroundColor: ButaColors.textOnDark,
    elevation: 0,
    titleTextStyle: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.textOnDark),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontFamily: kFontPressStart2P, fontSize: 20, color: ButaColors.textOnDark),
    headlineMedium: TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.textOnDark),
    bodyLarge: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.textOnDark),
    bodyMedium: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.textOnDark),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ButaColors.surface,
      foregroundColor: ButaColors.textPrimary,
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
        side: const BorderSide(color: ButaColors.ink, width: 3),
      ),
      textStyle: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 14),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: ButaColors.surface,
    labelStyle: const TextStyle(fontFamily: kFontDotGothic16, color: ButaColors.textPrimary),
    hintStyle: TextStyle(fontFamily: kFontDotGothic16, color: ButaColors.textPrimary.withValues(alpha: 0.5)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(2),
      borderSide: const BorderSide(color: ButaColors.ink, width: 3),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(2),
      borderSide: const BorderSide(color: ButaColors.ink, width: 3),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(2),
      borderSide: const BorderSide(color: ButaColors.primary, width: 3),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: ButaColors.primary,
      textStyle: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 12),
    ),
  ),
);

