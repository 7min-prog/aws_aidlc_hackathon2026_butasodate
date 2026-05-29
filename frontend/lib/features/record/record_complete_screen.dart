import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/features/record/record_tab_screen.dart';
import 'package:buta_app/features/home/home_screen.dart';

class RecordCompleteScreen extends ConsumerWidget {
  const RecordCompleteScreen({super.key, required this.points});
  final int points;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      appBar: const PixelAppBar(title: 'きろく かんりょう！'),
      backgroundColor: const Color(0xFF8A5A2B),
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-record.svg', fit: BoxFit.cover)),
        // ぶたエリア
        Positioned(top: 52 * sy, left: 0, right: 0, child: Center(child: Container(
          width: 150 * sx, height: 150 * sy,
          decoration: BoxDecoration(color: const Color(0xFFFFF8E6), border: Border.all(color: ButaColors.ink, width: 2), borderRadius: BorderRadius.circular(8)),
          child: Image.asset('assets/pig_happy.png', fit: BoxFit.contain),
        ))),
        // リアクション
        Positioned(top: 222 * sy, left: 0, right: 0, child: Center(child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16 * sx, vertical: 6 * sy),
          decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
          child: Text('ぶたが よろこんでる！', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.ink)),
        ))),
        // ポイント
        Positioned(top: 282 * sy, left: 0, right: 0, child: Center(child: Container(
          width: 160 * sx, height: 60 * sy,
          decoration: BoxDecoration(color: ButaColors.yellow, border: Border.all(color: ButaColors.ink, width: 2)),
          alignment: Alignment.center,
          child: Text('+${points}pt!', style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 20, color: ButaColors.ink)),
        ))),
        // ホームへ戻るボタン
        Positioned(top: 432 * sy, left: 55 * sx, right: 55 * sx, child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ButaColors.yellow, foregroundColor: ButaColors.ink,
            minimumSize: Size(double.infinity, 44 * sy),
            shape: RoundedRectangleBorder(side: const BorderSide(color: ButaColors.ink, width: 2), borderRadius: BorderRadius.zero),
          ),
          onPressed: () { ref.invalidate(recordsProvider); ref.invalidate(homeDataProvider); context.go('/recording'); },
          child: const Text('もどる', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16)),
        )),
      ]),
    );
  }
}

class _HappyPigPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 16;
    void px(double x, double y, double w, double h, Color c) => canvas.drawRect(Rect.fromLTWH(x * u, y * u, w * u, h * u), Paint()..color = c);
    // body
    px(4, 5, 8, 7, const Color(0xFFFF9BB3));
    // head
    px(5, 2, 6, 5, const Color(0xFFFF9BB3));
    // ears
    px(4, 1, 2, 2, const Color(0xFFFF9BB3)); px(10, 1, 2, 2, const Color(0xFFFF9BB3));
    // eyes (happy ^_^)
    px(6, 4, 1, 1, const Color(0xFF3D2B4D)); px(9, 4, 1, 1, const Color(0xFF3D2B4D));
    px(6, 3, 1, 1, const Color(0xFF3D2B4D)); px(9, 3, 1, 1, const Color(0xFF3D2B4D));
    // snout
    px(7, 5, 2, 1, const Color(0xFFE8485A));
    // smile
    px(6, 6, 4, 1, const Color(0xFF3D2B4D));
    // legs
    px(5, 12, 2, 2, const Color(0xFFFF9BB3)); px(9, 12, 2, 2, const Color(0xFFFF9BB3));
    // tail
    px(12, 6, 1, 1, const Color(0xFFFF9BB3)); px(13, 5, 1, 1, const Color(0xFFFF9BB3)); px(13, 7, 1, 1, const Color(0xFFFF9BB3));
    // sparkles (happy!)
    px(2, 2, 1, 1, const Color(0xFFF6C453)); px(13, 2, 1, 1, const Color(0xFFF6C453));
    px(1, 3, 1, 1, const Color(0xFFF6C453)); px(14, 3, 1, 1, const Color(0xFFF6C453));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
