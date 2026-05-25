import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/ui/grass_animation.dart';
import 'package:buta_app/shared/ui/pixel_dialog.dart';
import 'package:buta_app/shared/ui/pixel_tab_bar.dart';

class AccountManageScreen extends ConsumerWidget {
  const AccountManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.blue,
      appBar: const PixelAppBar(title: 'アカウント かんり', showBack: true),
      bottomNavigationBar: SafeArea(child: PixelTabBar(sx: sx, sy: sy, activeIndex: 4)),
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover)),
        const Positioned.fill(child: CloudAnimation()),
        Positioned.fill(child: GrassAnimation(sx: sx, sy: sy)),
        Positioned(top: 12 * sy, left: 14 * sx, child: Column(children: [
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
          SvgPicture.asset('assets/pixel-art/icons/play.svg', width: 12, height: 12),
        ]),
      ),
    );
  }
}
