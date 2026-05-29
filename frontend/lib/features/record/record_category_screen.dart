import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';

class RecordCategoryScreen extends StatelessWidget {
  const RecordCategoryScreen({super.key});

  static const _categories = [
    _Cat(name: 'しんやラーメン', icon: '🍜', points: 50),
    _Cat(name: 'のみすぎ', icon: '🍺', points: 60),
    _Cat(name: 'かんしょく', icon: '🍰', points: 20),
    _Cat(name: 'ぼういんぼうしょく', icon: '🍖', points: 60),
    _Cat(name: 'よふかし', icon: '📱', points: 35),
    _Cat(name: 'うんどうサボり', icon: '🛋️', points: 40),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ButaColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // PixelHeader
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: SvgPicture.asset('assets/pixel-art/icons/back.svg', width: 16.0, height: 16.0),
                  ),
                  const SizedBox(width: 12),
                  const Text('なにを した？', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.ink)),
                ],
              ),
            ),
            // カテゴリグリッド (2列×3行, 各172x108)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 172 / 108,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    return GestureDetector(
                      onTap: () => context.push('/record/confirm', extra: cat),
                      child: Container(
                        decoration: BoxDecoration(
                          color: ButaColors.paper,
                          border: Border.all(color: ButaColors.ink, width: 2),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(cat.icon, style: const TextStyle(fontSize: 32)),
                            const SizedBox(height: 8),
                            Text(cat.name, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cat {
  final String name;
  final String icon;
  final int points;
  const _Cat({required this.name, required this.icon, required this.points});
}
