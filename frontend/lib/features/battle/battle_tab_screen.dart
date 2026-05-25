import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/ui/pixel_tab_bar.dart';
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/ui/grass_animation.dart';

final battleHistoryProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  try {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/battles/history');
    return (res.data['history'] as List?) ?? [];
  } catch (_) {
    return [];
  }
});

class BattleTabScreen extends ConsumerWidget {
  const BattleTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.blue,
      appBar: const PixelAppBar(title: 'バトル'),
      bottomNavigationBar: SafeArea(child: PixelTabBar(sx: sx, sy: sy, activeIndex: 2)),
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover)),
        const Positioned.fill(child: CloudAnimation()),
        Positioned.fill(child: GrassAnimation(sx: sx, sy: sy)),
        Padding(
        padding: EdgeInsets.symmetric(horizontal: 14 * sx, vertical: 10),
        child: Column(children: [
          // ランダムマッチ
          GestureDetector(
            onTap: () => context.go('/battle-matching'),
            child: Container(
              width: double.infinity, height: 56,
              decoration: BoxDecoration(color: ButaColors.red, border: Border.all(color: ButaColors.ink, width: 2)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                SvgPicture.asset('assets/pixel-art/icons/swords.svg', width: 18, height: 18, colorFilter: const ColorFilter.mode(ButaColors.paper, BlendMode.srcIn)),
                const Text('ランダムマッチ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          // フレンド対戦
          GestureDetector(
            onTap: () async {
              final friends = await ref.read(apiClientProvider).get('/social/friends');
              final list = (friends.data['friends'] as List?) ?? [];
              if (!context.mounted || list.isEmpty) return;
              final selected = await showDialog<String>(
                context: context,
                builder: (ctx) => Dialog(
                  backgroundColor: ButaColors.paper,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('フレンドを えらぶ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.ink)),
                      const SizedBox(height: 12),
                      ...list.map<Widget>((f) => GestureDetector(
                        onTap: () => Navigator.pop(ctx, f['nickname'] ?? f['userId']),
                        child: Container(
                          width: double.infinity, height: 40, margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(color: ButaColors.bg, border: Border.all(color: ButaColors.ink)),
                          alignment: Alignment.center,
                          child: Text(f['nickname'] ?? f['userId'], style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
                        ),
                      )),
                    ]),
                  ),
                ),
              );
              if (selected != null && context.mounted) context.go('/battle-matching');
            },
            child: Container(
              width: double.infinity, height: 44,
              decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
              alignment: Alignment.center,
              child: Row(mainAxisSize: MainAxisSize.min, children: [SvgPicture.asset('assets/pixel-art/icons/mail.svg', width: 16, height: 16), const SizedBox(width: 6), const Text('フレンド たいせん', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink))]),
            ),
          ),
          const SizedBox(height: 12),
          // 履歴タイトル
          const Align(alignment: Alignment.centerLeft, child: Text('バトル りれき', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink))),
          const SizedBox(height: 6),
          // 履歴リスト
          Expanded(child: Container(
            decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
            padding: const EdgeInsets.all(8),
            child: ref.watch(battleHistoryProvider).when(
              data: (history) {
                if (history.isEmpty) return const Center(child: Text('まだ りれきが ないよ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray)));
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: history.length,
                  itemBuilder: (_, i) {
                    final h = history[i];
                    final win = h['result'] == 'WIN';
                    return Container(
                      height: 36, margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      color: win ? ButaColors.green.withValues(alpha: 0.15) : ButaColors.red.withValues(alpha: 0.15),
                      child: Row(children: [
                        SizedBox(width: 40, child: Text(win ? 'WIN' : 'LOSE', style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 8, color: win ? ButaColors.green : ButaColors.red))),
                        Text('vs ${h['opponentNickname']}', style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.ink)),
                        const Spacer(),
                        Text('${h['pointsChange'] > 0 ? '+' : ''}${h['pointsChange']}pt', style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.ink)),
                      ]),
                    );
                  },
                );
              },
              loading: () => const Center(child: Text('よみこみちゅう...', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
              error: (_, __) => const Center(child: Text('まだ りれきが ないよ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
            ),
          )),
        ]),
      ),
      ]),
    );
  }
}
