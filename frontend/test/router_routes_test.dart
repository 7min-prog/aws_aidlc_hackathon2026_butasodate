import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buta_app/shared/router.dart';

void main() {
  group('Router routes', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('router has /start route', () {
      final router = container.read(routerProvider);
      final match = router.configuration.findMatch(Uri.parse('/start'));
      expect(match.matches.isNotEmpty, isTrue);
    });

    test('router has /loading route', () {
      final router = container.read(routerProvider);
      final match = router.configuration.findMatch(Uri.parse('/terms'));
      expect(match.matches.isNotEmpty, isTrue);
    });

    test('router has /privacy route', () {
      final router = container.read(routerProvider);
      final match = router.configuration.findMatch(Uri.parse('/privacy'));
      expect(match.matches.isNotEmpty, isTrue);
    });
  });
}
