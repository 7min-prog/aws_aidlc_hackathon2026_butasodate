import 'package:flutter/material.dart';

// ぶたそだて 16色 GBC風パレット
class ButaColors {
  static const background = Color(0xFF1A1228);     // ダーク紺（メイン背景）
  static const surface = Color(0xFFF5F0E8);        // 紙色（ダイアログ背景）
  static const surfaceLight = Color(0xFFFFFBF5);   // 明るい紙色
  static const border = Color(0xFF1A1228);         // 枠線（ダーク）
  static const primary = Color(0xFFFF9BB3);        // ピンク（ぶた）
  static const error = Color(0xFFE8485A);          // 赤（ダメ）
  static const orange = Color(0xFFF6C453);         // オレンジ/金
  static const green = Color(0xFF2ECC71);          // 緑（健康）
  static const blue = Color(0xFF4A90D9);           // 青（健康）
  static const brown = Color(0xFF8B6914);          // 茶
  static const textPrimary = Color(0xFF1A1228);    // テキスト（暗い面上）
  static const textOnDark = Color(0xFFF5F0E8);     // テキスト（暗い背景上）
}

final butaTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'DotGothic16',
  colorScheme: ColorScheme.dark(
    primary: ButaColors.primary,
    surface: ButaColors.background,
    error: ButaColors.error,
  ),
  scaffoldBackgroundColor: ButaColors.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: ButaColors.background,
    foregroundColor: ButaColors.textOnDark,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: 'DotGothic16',
      fontSize: 16,
      color: ButaColors.textOnDark,
    ),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontFamily: 'PressStart2P', fontSize: 20, color: ButaColors.textOnDark),
    headlineMedium: TextStyle(fontFamily: 'DotGothic16', fontSize: 18, color: ButaColors.textOnDark),
    bodyLarge: TextStyle(fontFamily: 'DotGothic16', fontSize: 14, color: ButaColors.textOnDark),
    bodyMedium: TextStyle(fontFamily: 'DotGothic16', fontSize: 12, color: ButaColors.textOnDark),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ButaColors.surface,
      foregroundColor: ButaColors.textPrimary,
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
        side: const BorderSide(color: ButaColors.border, width: 3),
      ),
      textStyle: const TextStyle(fontFamily: 'DotGothic16', fontSize: 14),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: ButaColors.surface,
    labelStyle: const TextStyle(fontFamily: 'DotGothic16', color: ButaColors.textPrimary),
    hintStyle: TextStyle(fontFamily: 'DotGothic16', color: ButaColors.textPrimary.withOpacity(0.5)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(2),
      borderSide: const BorderSide(color: ButaColors.border, width: 3),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(2),
      borderSide: const BorderSide(color: ButaColors.border, width: 3),
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
      textStyle: const TextStyle(fontFamily: 'DotGothic16', fontSize: 12),
    ),
  ),
);

