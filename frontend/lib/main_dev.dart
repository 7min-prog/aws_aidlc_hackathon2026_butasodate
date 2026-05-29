import 'package:buta_app/shared/app_config.dart';
import 'package:buta_app/main.dart' as app;

void main() {
  AppConfig.init(Flavor.dev);
  app.main();
}
