class AppConstants {
  AppConstants._();

  // API Base URLs
  static const authApiBase = 'https://ubw8w4wnp7.execute-api.ap-northeast-1.amazonaws.com/dev';
  static const recordingApiBase = 'https://tlw1w8knh7.execute-api.ap-northeast-1.amazonaws.com/dev';
  static const avatarApiBase = 'https://dgjfsg2e9b.execute-api.ap-northeast-1.amazonaws.com/dev';
  static const socialApiBase = 'https://jn5w6ubvk5.execute-api.ap-northeast-1.amazonaws.com/dev';
  static const adminApiBase = 'https://0serzza7ba.execute-api.ap-northeast-1.amazonaws.com/dev';

  // Assets
  static const assetsBaseUrl = 'https://assets.butasodate.app/';

  // Timing
  static const splashMinDuration = Duration(seconds: 1);
  static const avatarCreateMaxRetries = 3;
  static const avatarCreateRetryDelay = Duration(seconds: 1);
}
