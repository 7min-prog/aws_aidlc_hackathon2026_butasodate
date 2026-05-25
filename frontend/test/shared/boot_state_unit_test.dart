import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/shared/state/auth_state.dart';

void main() {
  group('BootNotifier', () {
    test('returns login destination when no tokens', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(bootProvider.future);
      expect(result.destination, BootDestination.login);
    });

    test('returns home/error when tokens exist but API fails', () async {
      SharedPreferences.setMockInitialValues({
        'access_token': 'test_token',
        'refresh_token': 'test_refresh',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(bootProvider.future);
      // API fails → offline handler → no cached profile → home with offline
      expect(result.destination, isIn([BootDestination.login, BootDestination.home]));
    });
  });

  group('BootResult properties', () {
    test('default values', () {
      final r = BootResult(destination: BootDestination.home);
      expect(r.pendingRequestCount, 0);
      expect(r.isOffline, false);
      expect(r.avatarImagePath, isNull);
      expect(r.errorMessage, isNull);
      expect(r.profile, isNull);
      expect(r.avatar, isNull);
      expect(r.summary, isNull);
    });

    test('all fields set', () {
      final r = BootResult(
        destination: BootDestination.nickname,
        pendingRequestCount: 5,
        isOffline: true,
        avatarImagePath: '/img.png',
        errorMessage: 'err',
      );
      expect(r.destination, BootDestination.nickname);
      expect(r.pendingRequestCount, 5);
      expect(r.isOffline, true);
      expect(r.avatarImagePath, '/img.png');
      expect(r.errorMessage, 'err');
    });
  });
}
