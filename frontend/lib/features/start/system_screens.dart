import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/starry_background.dart';

/// X-03 エラー画面
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _SystemScreen(
      icon: '⚠',
      title: 'エラーが はっせいしました',
      message: 'サーバーに せつぞくできません。\nネットワークを かくにんしてください。',
      buttonLabel: 'リトライ',
      onTap: () => context.go('/splash'),
    );
  }
}

/// X-04 メンテナンス画面
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _SystemScreen(
      icon: '🔧',
      title: 'メンテナンスちゅう',
      message: 'ただいま メンテナンスを\nおこなっています。\n\nよてい しゅうりょう: 15:00',
      buttonLabel: 'とじる',
      onTap: () => context.go('/splash'),
    );
  }
}

/// X-05 強制アップデート画面
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _SystemScreen(
      icon: '⬆',
      title: 'アップデートが ひつようです',
      message: 'あたらしい バージョンが\nこうかいされています。\nストアから こうしんしてください。',
      buttonLabel: 'ストアへ',
      onTap: () {},
    );
  }
}

class _SystemScreen extends StatelessWidget {
  const _SystemScreen({required this.icon, required this.title, required this.message, required this.buttonLabel, required this.onTap});
  final String icon, title, message, buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;
    return Scaffold(
      backgroundColor: ButaColors.ink,
      body: Stack(children: [
        const Positioned.fill(child: StarryBackground(seed: 99)),
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(icon, style: TextStyle(fontSize: 48 * sx)),
          SizedBox(height: 16 * sy),
          Text(title, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.paper), textAlign: TextAlign.center),
          SizedBox(height: 16 * sy),
          Text(message, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.gray), textAlign: TextAlign.center),
          SizedBox(height: 32 * sy),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 200 * sx, height: 44 * sy,
              decoration: BoxDecoration(color: ButaColors.yellow, border: Border.all(color: ButaColors.ink, width: 2)),
              alignment: Alignment.center,
              child: Text(buttonLabel, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
            ),
          ),
        ])),
      ]),
    );
  }
}
