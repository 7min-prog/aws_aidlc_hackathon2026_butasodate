import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buta_app/shared/theme.dart';

/// Penpot準拠のピクセルアート風テキスト入力欄
/// フォーカス時に枠色が黄色に変わる
class PixelInput extends StatefulWidget {
  const PixelInput({super.key, required this.controller, required this.sx, required this.sy, this.obscure = false, this.hintText = 'なまえを いれてね...'});
  final TextEditingController controller;
  final double sx, sy;
  final bool obscure;
  final String hintText;

  @override
  State<PixelInput> createState() => _PixelInputState();
}

class _PixelInputState extends State<PixelInput> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280 * widget.sx, height: 36 * widget.sy,
      decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: _focused ? ButaColors.yellow : ButaColors.ink, width: 2)),
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 8 * widget.sx),
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        child: TextField(
          controller: widget.controller, obscureText: widget.obscure,
          style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink),
          decoration: InputDecoration(
            border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, disabledBorder: InputBorder.none,
            isDense: true, contentPadding: EdgeInsets.zero,
            hintText: widget.hintText,
            hintStyle: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.gray),
          ),
        ),
      ),
    );
  }
}

/// Penpot準拠のピクセルアート風ボタン
/// enabled=falseでグレー表示
class PixelActionButton extends StatelessWidget {
  const PixelActionButton({super.key, required this.width, required this.height, required this.label, this.onTap, this.enabled = true, this.fontSize = 16, this.color, this.icon});
  final double width, height;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final double fontSize;
  final Color? color;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final bg = enabled ? (color ?? ButaColors.yellow) : ButaColors.gray;
    final textColor = enabled ? ButaColors.ink : const Color(0xFF6B6B6B);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(color: bg, border: Border.all(color: ButaColors.ink, width: 2)),
        child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[SvgPicture.asset(icon!, width: 14, height: 14), const SizedBox(width: 6)],
          Text(label, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: fontSize, color: textColor)),
        ])),
      ),
    );
  }
}
