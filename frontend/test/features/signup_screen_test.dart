import 'package:flutter_test/flutter_test.dart';
import 'package:buta_app/features/auth/signup_screen.dart';

void main() {
  group('SignupScreen', () {
    test('クラスが存在する', () {
      expect(const SignupScreen(), isA<SignupScreen>());
    });
  });
}
