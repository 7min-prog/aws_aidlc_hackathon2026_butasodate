import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/boot_state.dart';
import 'package:buta_app/features/home/widgets/avatar_card.dart';
import 'package:buta_app/features/home/widgets/summary_card.dart';
import 'package:buta_app/features/home/widgets/record_button.dart';
import 'package:buta_app/features/home/widgets/offline_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootResult = ref.watch(bootProvider).value;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (bootResult?.isOffline == true) const OfflineBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    AvatarCard(
                      avatar: bootResult?.avatar,
                      imagePath: bootResult?.avatarImagePath,
                    ),
                    const SizedBox(height: 16),
                    SummaryCard(summary: bootResult?.summary),
                    const SizedBox(height: 24),
                    const RecordButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: const Color(0xFFFF69B4),
        onTap: (index) {
          switch (index) {
            case 1:
              context.push('/recording');
            case 2:
              context.push('/battle');
            case 3:
              context.push('/settings');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: '記録'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_mma), label: 'バトル'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}
