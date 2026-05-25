import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buta_app/shared/theme.dart';

void main() {
  group('ButaColors', () {
    test('Foundation', () {
      expect(ButaColors.ink, const Color(0xFF1A1228));
      expect(ButaColors.paper, const Color(0xFFFFF8E6));
      expect(ButaColors.blue, const Color(0xFF5A8ED1));
    });
    test('Aliases', () {
      expect(ButaColors.primary, ButaColors.pink);
      expect(ButaColors.error, ButaColors.red);
      expect(ButaColors.background, ButaColors.blue);
    });
  });

  group('butaTheme', () {
    test('useMaterial3', () => expect(butaTheme.useMaterial3, true));
    test('scaffoldBg', () => expect(butaTheme.scaffoldBackgroundColor, ButaColors.blue));
    test('appBar bg', () => expect(butaTheme.appBarTheme.backgroundColor, ButaColors.background));
    test('inputDecoration filled', () => expect(butaTheme.inputDecorationTheme.filled, true));
  });

  group('Font constants', () {
    test('DotGothic16', () => expect(kFontDotGothic16, 'DotGothic16'));
    test('PressStart2P', () => expect(kFontPressStart2P, 'PressStart2P'));
  });
}
