import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buta_app/shared/router.dart';
import 'package:buta_app/shared/theme.dart';

void main() {
  runApp(const ProviderScope(child: ButaApp()));
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
    );
  }
}
