import 'package:flutter_test/flutter_test.dart';
import 'package:buta_app/shared/state/boot_state.dart';

void main() {
  group('BootResult', () {
    test('creates with required destination', () {
      final result = BootResult(destination: BootDestination.login);
      expect(result.destination, BootDestination.login);
      expect(result.profile, isNull);
      expect(result.avatar, isNull);
      expect(result.summary, isNull);
      expect(result.pendingRequestCount, 0);
      expect(result.isOffline, false);
      expect(result.avatarImagePath, isNull);
      expect(result.errorMessage, isNull);
    });

    test('creates with all fields', () {
      final result = BootResult(
        destination: BootDestination.home,
        pendingRequestCount: 3,
        isOffline: true,
        avatarImagePath: '/path/to/img',
        errorMessage: 'error',
      );
      expect(result.pendingRequestCount, 3);
      expect(result.isOffline, true);
      expect(result.avatarImagePath, '/path/to/img');
      expect(result.errorMessage, 'error');
    });
  });

  group('BootDestination', () {
    test('has all values', () {
      expect(BootDestination.values.length, 3);
      expect(BootDestination.values, contains(BootDestination.login));
      expect(BootDestination.values, contains(BootDestination.nickname));
      expect(BootDestination.values, contains(BootDestination.home));
    });
  });

  group('AppBootStatus', () {
    test('has all values', () {
      expect(AppBootStatus.values.length, 4);
    });
  });
}
