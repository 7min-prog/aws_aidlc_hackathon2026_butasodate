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
  static const _accessTokenKey = 'access_token';

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..forward().then((_) => _decideRoute());
  }

  Future<void> _decideRoute() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final tutorialSeen = prefs.getBool(_tutorialSeenKey) ?? false;
    if (!tutorialSeen) {
      context.go('/tutorial');
      return;
    }

    final hasToken = prefs.getString(_accessTokenKey) != null;
    context.go(hasToken ? '/home' : '/login');
  }

  @override
  void dispose() { _progressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390;

    return Scaffold(
      backgroundColor: ButaColors.ink,
      body: Stack(
        children: [
          const StarryBackground(seed: 42),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('データを よみこんでいます...', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.bg)),
                const SizedBox(height: 16),
                SizedBox(
                  width: 240 * sx,
                  height: 10,
                  child: AnimatedBuilder(animation: _progressCtrl, builder: (context, _) => Stack(children: [
                    Container(color: ButaColors.ink2),
                    FractionallySizedBox(widthFactor: _progressCtrl.value, child: Container(color: ButaColors.green)),
                  ])),
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(animation: _progressCtrl, builder: (context, _) => Text('${(_progressCtrl.value * 100).toInt()}%', style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.green))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
