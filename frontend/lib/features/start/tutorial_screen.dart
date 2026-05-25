import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/starry_background.dart';

/// X-06a/b/c チュートリアル画面（carousel_slider）
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});
  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _ctrl = CarouselSliderController();
  int _page = 0;

  static const _pages = [
    _TutorialPage(accentColor: ButaColors.yellow, pigColor: ButaColors.pink, emoji: '^_^', title: 'ダメなじぶんを\nきろくしよう！', body: 'しんやラーメン、よふかし、\nうんどうサボり...\nぜんぶ きろくするだけ！', btnLabel: 'つぎへ', btnColor: ButaColors.blue),
    _TutorialPage(accentColor: ButaColors.green, pigColor: ButaColors.red, emoji: '>w<', title: 'ぶたが どんどん\nそだっていく！', body: 'きろくするほど ぶたが\nまるまると せいちょう！\nスキルも おぼえるよ', btnLabel: 'つぎへ', btnColor: ButaColors.blue),
    _TutorialPage(accentColor: ButaColors.red, pigColor: ButaColors.blue, emoji: '!!', title: 'そだてた ぶたで\nバトルだ！', body: 'フレンドの ぶたと たいせん！\nダメなほど つよくなる\nさいきょうの ぶたを めざせ', btnLabel: 'はじめる！', btnColor: ButaColors.red),
  ];

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_seen', true);
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_page < 2) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _completeTutorial();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390;
    final sy = size.height / 740;
    final p = _pages[_page];

    return Scaffold(
      backgroundColor: ButaColors.ink,
      body: Stack(
        children: [
          const StarryBackground(seed: 99),
          CarouselSlider.builder(
            carouselController: _ctrl,
            itemCount: 3,
            options: CarouselOptions(height: size.height, viewportFraction: 1.0, enableInfiniteScroll: false, onPageChanged: (i, _) => setState(() => _page = i)),
            itemBuilder: (context, i, _) => _buildPage(_pages[i], i, sx, sy, size),
          ),
          // ドットインジケーター（タップ可能）
          Positioned(
            top: 560 * sy, left: 0, right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => GestureDetector(
              onTap: () => _ctrl.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
              child: Container(width: 12 * sx, height: 12 * sx, margin: EdgeInsets.symmetric(horizontal: 6 * sx), color: i == _page ? p.accentColor : ButaColors.ink2),
            ))),
          ),
          // ボタン
          Positioned(
            top: 610 * sy, left: (size.width - 200 * sx) / 2,
            child: GestureDetector(
              onTap: _next,
              child: Container(
                width: 200 * sx, height: 48 * sy,
                decoration: BoxDecoration(color: p.btnColor, border: Border.all(color: ButaColors.ink2, width: 2)),
                child: Center(child: Text(p.btnLabel, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper))),
              ),
            ),
          ),
          // スキップ
          if (_page < 2)
            Positioned(
              top: 700 * sy, right: 20 * sx,
              child: GestureDetector(onTap: _completeTutorial, child: const Text('スキップ >', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.gray))),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(_TutorialPage p, int index, double sx, double sy, Size size) {
    return Stack(
      children: [
        Positioned(top: 80 * sy, left: 0, right: 0, child: Text('${index + 1} / 3', textAlign: TextAlign.center, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.gray))),
        Positioned(
          top: 120 * sy, left: (size.width - 200 * sx) / 2,
          child: Container(
            width: 200 * sx, height: 180 * sy,
            decoration: BoxDecoration(color: ButaColors.ink, border: Border.all(color: p.accentColor, width: 3)),
            child: Stack(alignment: Alignment.center, children: [
              Container(width: 80 * sx, height: 70 * sy, decoration: BoxDecoration(color: p.pigColor, border: Border.all(color: ButaColors.ink2, width: 2))),
              Positioned(top: 10 * sy, child: Text(p.emoji, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: p.accentColor))),
            ]),
          ),
        ),
        Positioned(top: 350 * sy, left: 0, right: 0, child: Text(p.title, textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: p.accentColor))),
        Positioned(top: 430 * sy, left: 0, right: 0, child: Text(p.body, textAlign: TextAlign.center, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.bg))),
      ],
    );
  }
}

class _TutorialPage {
  final Color accentColor, pigColor, btnColor;
  final String emoji, title, body, btnLabel;
  const _TutorialPage({required this.accentColor, required this.pigColor, required this.emoji, required this.title, required this.body, required this.btnLabel, required this.btnColor});
}
