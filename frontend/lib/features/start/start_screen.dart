import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/starry_background.dart';

/// X-00 スタート画面 (デザイン基準: 390x740, bg: #1a1228)
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  static const double _dw = 390;
  static const double _dh = 740;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / _dw;
    final sy = size.height / _dh;

    return Scaffold(
      backgroundColor: ButaColors.ink,
      body: GestureDetector(
        onTap: () => context.go('/loading'),
        behavior: HitTestBehavior.opaque,
        child: SizedBox.expand(
          child: Stack(
            children: [
              const StarryBackground(seed: 42),

              // 月: 影
              Positioned(top: 88 * sy, left: 258 * sx, child: Container(width: 72 * sx, height: 72 * sx, decoration: const BoxDecoration(shape: BoxShape.circle, color: ButaColors.brown))),
              // 月: 本体
              Positioned(top: 84 * sy, left: 254 * sx, child: Container(width: 72 * sx, height: 72 * sx, decoration: const BoxDecoration(shape: BoxShape.circle, color: ButaColors.yellow))),
              // 月: クレーター
              Positioned(top: 100 * sy, left: 270 * sx, child: Container(width: 16 * sx, height: 16 * sx, decoration: const BoxDecoration(shape: BoxShape.circle, color: ButaColors.bgDeep))),
              Positioned(top: 122 * sy, left: 290 * sx, child: Container(width: 20 * sx, height: 20 * sx, decoration: const BoxDecoration(shape: BoxShape.circle, color: ButaColors.bgDeep))),
              Positioned(top: 125 * sy, left: 269 * sx, child: Container(width: 10 * sx, height: 10 * sx, decoration: const BoxDecoration(shape: BoxShape.circle, color: ButaColors.bgDeep))),
              Positioned(top: 102 * sy, left: 298 * sx, child: Container(width: 12 * sx, height: 12 * sx, decoration: const BoxDecoration(shape: BoxShape.circle, color: ButaColors.bgDeep))),

              // バナー: 赤背景
              Positioned(top: 225 * sy, left: (size.width - 200 * sx) / 2, child: Container(width: 200 * sx, height: 30 * sy, color: ButaColors.red)),
              // バナー: 黄色枠
              Positioned(top: 228 * sy, left: (size.width - 194 * sx) / 2, child: Container(width: 194 * sx, height: 24 * sy, decoration: BoxDecoration(border: Border.all(color: ButaColors.yellow, width: 2)))),
              // バナーテキスト
              Positioned(top: 231 * sy, left: 0, right: 0, child: const Text('HEALTH × RPG', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.yellow))),

              // タイトル影
              Positioned(top: 262 * sy, left: 2, right: 0, child: const Text('ぶたそだて', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 56, color: ButaColors.ink2))),
              // タイトル本体
              Positioned(top: 260 * sy, left: 0, right: 0, child: const Text('ぶたそだて', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 56, color: ButaColors.paper))),
              // サブタイトル
              Positioned(top: 338 * sy, left: 0, right: 0, child: const Text('〜 人をダメにする育成RPG 〜', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.yellow))),

              // PigSprite
              Positioned(
                top: 400 * sy, left: (size.width - 160 * sx) / 2,
                child: Container(width: 160 * sx, height: 140 * sy, decoration: BoxDecoration(color: ButaColors.pink, border: Border.all(color: ButaColors.ink, width: 2)), child: const Center(child: Text('🐷', style: TextStyle(fontSize: 64)))),
              ),

              // PRESS START (点滅)
              Positioned(top: 610 * sy, left: 0, right: 0, child: const _BlinkText()),
              // コピーライト
              Positioned(top: 700 * sy, left: 0, right: 0, child: Text('© 2026 TEAM BUTASODATE', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: ButaColors.paper.withValues(alpha: 0.5)))),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlinkText extends StatefulWidget {
  const _BlinkText();
  @override
  State<_BlinkText> createState() => _BlinkTextState();
}

class _BlinkTextState extends State<_BlinkText> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _ctrl, child: const Text('+ PRESS START +', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper)));
}
