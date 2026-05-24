import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/ui/grass_animation.dart';
import 'package:buta_app/shared/ui/pixel_dialog.dart';
import 'package:buta_app/features/home/home_screen.dart';

class AccountManageScreen extends ConsumerWidget {
  const AccountManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.blue,
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover)),
        const Positioned.fill(child: CloudAnimation()),
        Positioned.fill(child: GrassAnimation(sx: sx, sy: sy)),
        Positioned(top: 0, left: 0, right: 0, height: 48 * sy, child: Container(color: ButaColors.ink, child: Stack(children: [
          Align(alignment: Alignment.centerLeft, child: GestureDetector(onTap: () => Navigator.pop(context), child: Padding(padding: EdgeInsets.only(left: 12 * sx), child: Text('◀', style: TextStyle(fontSize: 18, color: ButaColors.paper))))),
          Center(child: Text('アカウント かんり', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.paper))),
        ]))),
        Positioned(top: 60 * sy, left: 14 * sx, child: Column(children: [
          _item(context, sx, sy, 'パスワード へんこう', onTap: () async {
            await showPixelAlert(context, message: 'パスワード へんこう きのうは じゅんびちゅう です');
          }),
          SizedBox(height: 2 * sy),
          _item(context, sx, sy, 'ログアウト', color: ButaColors.red, onTap: () async {
            final ok = await showPixelConfirm(context, message: 'ほんとうに ログアウトしますか？', confirmLabel: 'はい', cancelLabel: 'いいえ');
            if (ok == true && context.mounted) {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            }
          }),
          SizedBox(height: 2 * sy),
          _item(context, sx, sy, 'アカウント さくじょ', color: ButaColors.red, onTap: () async {
            final ok = await showPixelConfirm(context, message: 'アカウントを さくじょすると もとにもどせません', confirmLabel: 'さくじょする', cancelLabel: 'やめる');
            if (ok == true && context.mounted) {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            }
          }),
        ])),
        Positioned(bottom: 0, left: 0, right: 0, height: 56 * sy, child: PixelTabBar(sx: sx, sy: sy, activeIndex: 4)),
      ]),
    );
  }

  Widget _item(BuildContext context, double sx, double sy, String label, {Color? color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 362 * sx, height: 48 * sy,
        padding: EdgeInsets.symmetric(horizontal: 14 * sx),
        decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
        child: Row(children: [
          Text(label, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: color ?? ButaColors.ink)),
          const Spacer(),
          Text('▶', style: TextStyle(fontSize: 12, color: ButaColors.ink)),
        ]),
      ),
    );
  }
}
