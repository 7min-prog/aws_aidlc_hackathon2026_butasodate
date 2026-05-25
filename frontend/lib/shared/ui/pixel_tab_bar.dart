import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';

class PixelTabBar extends StatelessWidget {
  const PixelTabBar({super.key, required this.sx, required this.sy, this.activeIndex = 0});
  final double sx, sy;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ButaColors.black,
      padding: EdgeInsets.only(top: 5 * sy, left: 4 * sx, right: 4 * sx),
      child: Row(children: [
        _tab(context, 'assets/pixel-art/icons/tab-home.svg', 'ホーム', activeIndex == 0, '/home'),
        SizedBox(width: 2 * sx),
        _tab(context, 'assets/pixel-art/icons/tab-record.svg', 'きろく', activeIndex == 1, '/recording'),
        SizedBox(width: 2 * sx),
        _tab(context, 'assets/pixel-art/icons/tab-battle.svg', 'バトル', activeIndex == 2, '/battle'),
        SizedBox(width: 2 * sx),
        _tab(context, 'assets/pixel-art/icons/tab-friend.svg', 'フレンド', activeIndex == 3, '/friends'),
        SizedBox(width: 2 * sx),
        _tab(context, 'assets/pixel-art/icons/tab-settings.svg', 'せってい', activeIndex == 4, '/settings'),
      ]),
    );
  }

  Widget _tab(BuildContext context, String iconAsset, String label, bool active, String route) {
    final bg = active ? ButaColors.yellow : ButaColors.bg;
    final fg = ButaColors.ink;
    return Expanded(child: GestureDetector(
      onTap: active ? null : () => GoRouter.of(context).go(route),
      child: Container(
        height: 48 * sy,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(2)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SvgPicture.asset(iconAsset, width: 20 * sx, height: 20 * sy),
          SizedBox(height: 2 * sy),
          Text(label, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 8, color: fg)),
        ]),
      ),
    ));
  }
}
