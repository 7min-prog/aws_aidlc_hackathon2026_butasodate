import 'dart:async';
import 'package:buta_app/shared/app_config.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  try { AppConfig.init(Flavor.dev); } catch (_) {}
  return testMain();
}
