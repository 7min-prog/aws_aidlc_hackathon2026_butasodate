enum Flavor { dev, prod }

class AppConfig {
  static Flavor _flavor = Flavor.dev;
  static Flavor get flavor => _flavor;

  static void init(Flavor f) => _flavor = f;

  static bool get isDev => _flavor == Flavor.dev;

  /// dev環境でのAPI接続先（ログイン画面から変更可能）
  static String devBaseUrl = 'http://192.168.11.18:3000';

  static String get authApiBase => isDev
      ? devBaseUrl
      : 'https://ubw8w4wnp7.execute-api.ap-northeast-1.amazonaws.com/dev';

  static String get recordingApiBase => isDev
      ? devBaseUrl
      : 'https://tlw1w8knh7.execute-api.ap-northeast-1.amazonaws.com/dev';

  static String get avatarApiBase => isDev
      ? devBaseUrl
      : 'https://dgjfsg2e9b.execute-api.ap-northeast-1.amazonaws.com/dev';

  static String get socialApiBase => isDev
      ? devBaseUrl
      : 'https://jn5w6ubvk5.execute-api.ap-northeast-1.amazonaws.com/dev';

  static String get adminApiBase => isDev
      ? devBaseUrl
      : 'https://0serzza7ba.execute-api.ap-northeast-1.amazonaws.com/dev';
}
