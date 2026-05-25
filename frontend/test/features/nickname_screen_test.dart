import 'package:flutter_test/flutter_test.dart';
import 'package:buta_app/features/auth/nickname_screen.dart';

void main() {
  group('NicknameScreen', () {
    test('クラスが存在する', () {
      expect(const NicknameScreen(), isA<NicknameScreen>());
    });
  });
}
