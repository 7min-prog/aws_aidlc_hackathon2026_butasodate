import 'package:flutter_test/flutter_test.dart';
import 'package:buta_app/features/home/home_screen.dart';
import 'package:buta_app/shared/state/boot_state.dart';

void main() {
  group('HomeScreen', () {
    test('homeDataProviderが定義されている', () {
      expect(homeDataProvider, isNotNull);
    });

    test('HomeScreenクラスが存在する', () {
      expect(const HomeScreen(), isA<HomeScreen>());
    });
  });
}
