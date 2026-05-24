import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/starry_background.dart';

/// X-02 ローディング画面
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});
  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _progressCtrl;

  static const _tutorialSeenKey = 'tutorial_seen';

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..forward().then((_) async {
        if (!mounted) return;
        final prefs = await SharedPreferences.getInstance();
        final seen = prefs.getBool(_tutorialSeenKey) ?? false;
        if (!mounted) return;
        context.go(seen ? '/login' : '/tutorial');
      });
  }

  @override
  void dispose() { _progressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390;
    final sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.ink,
      body: Stack(
        children: [
          const StarryBackground(seed: 42),
          // テキスト
          Positioned(top: 380 * sy, left: 0, right: 0, child: const Text('データを よみこんでいます...', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.bg))),
          // プログレスバー背景
          Positioned(top: 420 * sy, left: 75 * sx, child: Container(width: 240 * sx, height: 10 * sy, color: ButaColors.ink2)),
          // プログレスバー
          Positioned(top: 420 * sy, left: 75 * sx, child: AnimatedBuilder(animation: _progressCtrl, builder: (context, _) => Container(width: 240 * sx * _progressCtrl.value, height: 10 * sy, color: ButaColors.green))),
          // パーセント
          Positioned(top: 440 * sy, left: 0, right: 0, child: AnimatedBuilder(animation: _progressCtrl, builder: (context, _) => Text('${(_progressCtrl.value * 100).toInt()}%', textAlign: TextAlign.center, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.green)))),
        ],
      ),
    );
  }
}
