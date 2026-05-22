class AppConstants {
  AppConstants._();

  // API Base URLs (CDKデプロイ後に差し替え)
  static const authApiBase = 'https://YOUR_AUTH_API.execute-api.ap-northeast-1.amazonaws.com/dev';
  static const recordingApiBase = 'https://YOUR_RECORDING_API.execute-api.ap-northeast-1.amazonaws.com/dev';
  static const avatarApiBase = 'https://YOUR_AVATAR_API.execute-api.ap-northeast-1.amazonaws.com/dev';
  static const socialApiBase = 'https://YOUR_SOCIAL_API.execute-api.ap-northeast-1.amazonaws.com/dev';

  // S3 Assets
  static const assetsBaseUrl = 'https://YOUR_BUCKET.s3.ap-northeast-1.amazonaws.com/assets/';
  static const defaultAvatarAsset = 'assets/images/default_buta.png';

  // Timing
  static const splashMinDuration = Duration(seconds: 1);
  static const avatarCreateMaxRetries = 3;
  static const avatarCreateRetryDelay = Duration(seconds: 1);
}
