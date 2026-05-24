import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/features/home/home_screen.dart';

final _categoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/categories');
    return res.data['categories'] as List? ?? [];
  } catch (_) {
    return [
      {'categoryId': 'food-ramen', 'name': 'しんやラーメン', 'icon': '🍜', 'points': 50},
      {'categoryId': 'food-snack', 'name': 'かんしょく', 'icon': '🍰', 'points': 20},
      {'categoryId': 'food-binge', 'name': 'ぼういんぼうしょく', 'icon': '🍺', 'points': 60},
      {'categoryId': 'life-late-night', 'name': 'よふかし', 'icon': '📱', 'points': 35},
      {'categoryId': 'life-skip-exercise', 'name': 'うんどうサボり', 'icon': '🛋️', 'points': 40},
      {'categoryId': 'life-gaming', 'name': 'ゲームさんまい', 'icon': '🎮', 'points': 25},
    ];
  }
});

class CategorySelectScreen extends ConsumerWidget {
  const CategorySelectScreen({super.key});

  static String _catIcon(String id) {
    const map = {
      'food-ramen': 'cat-ramen', 'food-snack': 'cat-snack', 'food-binge': 'cat-binge',
      'life-oversleep': 'cat-oversleep', 'life-skip-exercise': 'cat-skip-exercise',
      'life-late-night': 'cat-late-night', 'life-gaming': 'cat-gaming', 'life-nap': 'cat-nap',
    };
    return 'assets/pixel-art/icons/${map[id] ?? 'cat-ramen'}.svg';
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;
    final cats = ref.watch(_categoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF8A5A2B),
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-record.svg', fit: BoxFit.cover)),
        // ヘッダー
        Positioned(top: 0, left: 0, right: 0, height: 48 * sy, child: Container(
          color: ButaColors.ink,
          child: Stack(children: [
            Positioned(left: 14 * sx, top: 14 * sy, child: GestureDetector(onTap: () => context.pop(), child: Text('◀', style: TextStyle(fontSize: 16, color: ButaColors.paper)))),
            Center(child: Text('なにを した？', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.paper))),
          ]),
        )),
        // カテゴリグリッド
        Positioned(top: 68 * sy, left: 14 * sx, right: 14 * sx, bottom: 56 * sy, child: cats.when(
          data: (list) => Wrap(spacing: 10 * sx, runSpacing: 10 * sy, children: [
            for (final cat in list) GestureDetector(
              onTap: () => context.push('/record-confirm', extra: cat),
              child: Container(
                width: 172 * sx, height: 108 * sy,
                decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 36 * sx, height: 36 * sx, child: SvgPicture.asset(CategorySelectScreen._catIcon(cat['categoryId'] ?? ''))),
                  SizedBox(height: 6 * sy),
                  Text(cat['name'] ?? '', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink)),
                ]),
              ),
            ),
          ]),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        )),
        // タブバー
        Positioned(bottom: 0, left: 0, right: 0, height: 56 * sy, child: PixelTabBar(sx: sx, sy: sy, activeIndex: 1)),
      ]),
    );
  }
}
