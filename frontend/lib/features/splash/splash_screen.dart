import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/boot_state.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<BootResult>>(bootProvider, (_, next) {
      next.whenData((result) {
        switch (result.destination) {
          case BootDestination.login:
            context.go('/login');
          case BootDestination.nickname:
            context.go('/nickname');
          case BootDestination.home:
            context.go('/');
        }
      });
    });

    final bootState = ref.watch(bootProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ロゴ
            const Icon(Icons.pets, size: 80, color: Color(0xFFFF69B4)),
            const SizedBox(height: 16),
            Text(
              'ぶたそだて',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF69B4),
                  ),
            ),
            const SizedBox(height: 48),
            // ローディング or エラー
            bootState.when(
              loading: () => const CircularProgressIndicator(
                color: Color(0xFFFF69B4),
              ),
              data: (_) => const SizedBox.shrink(),
              error: (error, _) => Column(
                children: [
                  Text(
                    'エラーが発生しました',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(bootProvider.notifier).retry(),
                    child: const Text('リトライ'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
