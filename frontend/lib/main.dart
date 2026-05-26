import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buta_app/shared/router.dart';
import 'package:buta_app/shared/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xFF0A0612),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    ProviderScope(
      retry: (retryCount, error) => null,
      child: const ButaApp(),
    ),
  );
}

class ButaApp extends ConsumerWidget {
  const ButaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ぶたそだて',
      theme: butaTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => child ?? const SizedBox.shrink(),
    );
  }
}
