import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Router redirect logic', () {
    test('public paths are accessible when not logged in', () {
      final publicPaths = ['/start', '/loading', '/tutorial', '/login', '/signup', '/confirm', '/nickname'];
      for (final path in publicPaths) {
        final result = _simulateRedirect(isLoggedIn: false, path: path);
        expect(result, isNull, reason: 'Path $path should be accessible when not logged in');
      }
    });

    test('non-public paths redirect to /start when not logged in', () {
      final result = _simulateRedirect(isLoggedIn: false, path: '/');
      expect(result, '/start');

      final result2 = _simulateRedirect(isLoggedIn: false, path: '/records');
      expect(result2, '/start');

      final result3 = _simulateRedirect(isLoggedIn: false, path: '/avatar');
      expect(result3, '/start');
    });

    test('/start redirects to / when logged in', () {
      final result = _simulateRedirect(isLoggedIn: true, path: '/start');
      expect(result, '/');
    });

    test('/tutorial does NOT redirect when logged in', () {
      final result = _simulateRedirect(isLoggedIn: true, path: '/tutorial');
      expect(result, isNull);
    });

    test('/loading does NOT redirect when logged in', () {
      final result = _simulateRedirect(isLoggedIn: true, path: '/loading');
      expect(result, isNull);
    });

    test('/login does NOT redirect when logged in', () {
      // ログイン済みでも/loginにはアクセス可能（リダイレクトしない）
      final result = _simulateRedirect(isLoggedIn: true, path: '/login');
      expect(result, isNull);
    });

    test('/ is accessible when logged in', () {
      final result = _simulateRedirect(isLoggedIn: true, path: '/');
      expect(result, isNull);
    });
  });
}

/// Simulates the redirect logic from router.dart
String? _simulateRedirect({required bool isLoggedIn, required String path}) {
  final publicPaths = ['/start', '/loading', '/tutorial', '/login', '/signup', '/confirm', '/nickname'];
  final isPublicPath = publicPaths.contains(path);

  if (!isLoggedIn && !isPublicPath) return '/start';
  if (isLoggedIn && path == '/start') return '/';
  return null;
}
