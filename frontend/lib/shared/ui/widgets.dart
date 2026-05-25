import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buta_app/shared/theme.dart';

/// ① PixelBox — JRPG窓（三重ボーダー）
class PixelBox extends StatelessWidget {
  final Widget child;
  final String? label;
  final Color? backgroundColor;

  const PixelBox({super.key, required this.child, this.label, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor ?? ButaColors.paper,
        border: Border.all(color: ButaColors.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: ButaColors.paper, spreadRadius: 3),
          BoxShadow(color: ButaColors.ink, spreadRadius: 6),
        ],
      ),
      child: label != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: ButaColors.pinkDk,
                  child: Text(label!, style: const TextStyle(fontFamily: kFontPressStart2P, fontSize: 8, color: ButaColors.paper)),
                ),
                const SizedBox(height: 8),
                child,
              ],
            )
          : child,
    );
  }
}

/// ② PixelButton — A/Bボタン
enum PixelButtonStyle { primary, secondary, danger }

class PixelButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final PixelButtonStyle style;
  final bool showMarker;

  const PixelButton({
    super.key,
    required this.text,
    this.onTap,
    this.style = PixelButtonStyle.primary,
    this.showMarker = false,
  });

  Color get _bg => switch (style) {
    PixelButtonStyle.primary => ButaColors.yellow,
    PixelButtonStyle.secondary => ButaColors.paper,
    PixelButtonStyle.danger => ButaColors.red,
  };

  Color get _fg => switch (style) {
    PixelButtonStyle.primary => ButaColors.ink,
    PixelButtonStyle.secondary => ButaColors.ink,
    PixelButtonStyle.danger => ButaColors.paper,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _bg,
          border: Border.all(color: ButaColors.ink, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x2E000000), offset: Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showMarker) Padding(padding: const EdgeInsets.only(right: 4), child: SvgPicture.asset('assets/pixel-art/icons/play.svg', width: 12, height: 12)),
            Text(text, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: _fg, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

/// ③ PixelBar — HP/EXPバー
class PixelBar extends StatelessWidget {
  final double value; // 0.0 ~ 1.0
  final Color color;
  final double height;

  const PixelBar({super.key, required this.value, this.color = ButaColors.green, this.height = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: ButaColors.ink,
        border: Border.all(color: ButaColors.ink, width: 2),
      ),
      padding: const EdgeInsets.all(2),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(color: color),
      ),
    );
  }
}

/// ④ PixelTag — ラベルタグ
class PixelTag extends StatelessWidget {
  final String text;
  final Color color;

  const PixelTag({super.key, required this.text, this.color = ButaColors.pink});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: ButaColors.ink, width: 2),
      ),
      child: Text(text, style: const TextStyle(fontFamily: kFontPressStart2P, fontSize: 8, color: ButaColors.ink, letterSpacing: 1)),
    );
  }
}

/// ⑤ BottomNavBar — ピクセル風タブバー（Penpot: PixelTabBar）
class ButaBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ButaBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  static const _tabs = [
    _NavItem(svg: 'assets/pixel-art/icons/tab-home.svg', label: 'ホーム'),
    _NavItem(svg: 'assets/pixel-art/icons/tab-record.svg', label: 'きろく'),
    _NavItem(svg: 'assets/pixel-art/icons/tab-battle.svg', label: 'バトル'),
    _NavItem(svg: 'assets/pixel-art/icons/tab-friend.svg', label: 'フレンド'),
    _NavItem(svg: 'assets/pixel-art/icons/tab-settings.svg', label: 'せってい'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: ButaColors.black,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: selected ? ButaColors.yellow : ButaColors.bg,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(_tabs[i].svg, width: 16, height: 16),
                    const SizedBox(height: 2),
                    Text(
                      _tabs[i].label,
                      style: TextStyle(
                        fontFamily: kFontDotGothic16,
                        fontSize: 10,
                        color: ButaColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final String svg;
  final String label;
  const _NavItem({required this.svg, required this.label});
}

/// PixelAppBar — ピクセル風AppBar
class PixelAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  const PixelAppBar({super.key, required this.title, this.showBack = false});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48 + MediaQuery.paddingOf(context).top,
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      color: ButaColors.ink2,
      child: Stack(
        children: [
          if (showBack)
            Align(alignment: Alignment.centerLeft, child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(width: 48, height: 48, child: Center(child: SvgPicture.asset('assets/pixel-art/icons/back.svg', width: 18.0, height: 18.0, colorFilter: const ColorFilter.mode(ButaColors.paper, BlendMode.srcIn)))),
            )),
          Center(child: Text(title, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.paper))),
        ],
      ),
    );
  }
}
