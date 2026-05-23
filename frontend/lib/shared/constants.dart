class AppConstants {
  AppConstants._();

  // API Base URLs
  static const authApiBase = 'https://ubw8w4wnp7.execute-api.ap-northeast-1.amazonaws.com/dev';
  static const recordingApiBase = 'https://tlw1w8knh7.execute-api.ap-northeast-1.amazonaws.com/dev';
  static const avatarApiBase = 'https://dgjfsg2e9b.execute-api.ap-northeast-1.amazonaws.com/dev';
  static const socialApiBase = 'https://jn5w6ubvk5.execute-api.ap-northeast-1.amazonaws.com/dev';
  static const battleWsUrl = 'wss://cd3lmmh06a.execute-api.ap-northeast-1.amazonaws.com/dev';

  // S3 Assets
  static const assetsBaseUrl = 'https://butasodate-assets-718100330221-dev.s3.ap-northeast-1.amazonaws.com/assets/';
  static const defaultAvatarAsset = 'assets/images/default_buta.png';

  // Cognito
  static const userPoolId = 'ap-northeast-1_a9yJHt07e';
  static const clientId = '2dr80q7rhbij90i244le76su26';

  // Timing
  static const splashMinDuration = Duration(seconds: 1);
  static const avatarCreateMaxRetries = 3;
  static const avatarCreateRetryDelay = Duration(seconds: 1);
}
