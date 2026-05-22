import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/auth_state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('ログアウト'),
                content: const Text('ログアウトしますか？'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ログアウト')),
                ],
              ),
            );
            if (confirmed == true) {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            }
          },
          icon: const Icon(Icons.logout),
          label: const Text('ログアウト'),
        ),
      ),
    );
  }
}
