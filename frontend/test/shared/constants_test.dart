import 'package:flutter_test/flutter_test.dart';
import 'package:buta_app/shared/constants.dart';

void main() {
  test('AppConstants all properties accessible', () {
    expect(AppConstants.authApiBase, isA<String>());
    expect(AppConstants.recordingApiBase, isA<String>());
    expect(AppConstants.avatarApiBase, isA<String>());
    expect(AppConstants.socialApiBase, isA<String>());
    expect(AppConstants.assetsBaseUrl, isA<String>());
    expect(AppConstants.splashMinDuration, const Duration(seconds: 1));
    expect(AppConstants.avatarCreateMaxRetries, 3);
    expect(AppConstants.avatarCreateRetryDelay, const Duration(seconds: 1));
  });
}
