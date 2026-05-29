import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/shared/ui/pixel_input.dart';
import 'package:buta_app/shared/ui/pixel_dialog.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/utils/error_helper.dart';

class NicknameScreen extends ConsumerStatefulWidget {
  const NicknameScreen({super.key});
  @override
  ConsumerState<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends ConsumerState<NicknameScreen> {
  final _nicknameCtrl = TextEditingController();
  final _pigNameCtrl = TextEditingController();

  Future<void> _submit() async {
    final nickname = _nicknameCtrl.text.trim();
    final pigName = _pigNameCtrl.text.trim();
    if (nickname.isEmpty || pigName.isEmpty) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/users/profile', data: {'nickname': nickname});
      await api.post('/avatar', data: {'name': pigName});
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) showPixelAlert(context, message: 'エラーが おきました\n\n${formatApiError(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390;
    final sy = size.height / 740;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ButaColors.blue,
      appBar: PreferredSize(preferredSize: Size.zero, child: Container(color: Colors.transparent)),
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-barn.svg', fit: BoxFit.cover)),
        const Positioned.fill(child: CloudAnimation()),
        // タイトル1
        Positioned(top: 136 * sy, left: 0, right: 0, child: const Text('あなたの なまえ', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 20, color: ButaColors.paper))),
        // ラベル1
        Positioned(top: 180 * sy, left: 0, right: 0, child: const Text('ニックネーム', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
        // 入力1
        Positioned(top: 198 * sy, left: 55 * sx, child: PixelInput(controller: _nicknameCtrl, sx: sx, sy: sy, hintText: 'なまえを いれてね')),
        // タイトル2
        Positioned(top: 274 * sy, left: 0, right: 0, child: const Text('ぶたの なまえ', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 20, color: ButaColors.paper))),
        // ラベル2
        Positioned(top: 320 * sy, left: 0, right: 0, child: const Text('ぶたの なまえ', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
        // 入力2
        Positioned(top: 338 * sy, left: 55 * sx, child: PixelInput(controller: _pigNameCtrl, sx: sx, sy: sy, hintText: 'なまえを いれてね')),
        // ぶたプレビュー
        Positioned(top: 410 * sy, left: 145 * sx, child: Container(
          width: 100 * sx, height: 100 * sy,
          decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
          child: Center(child: CustomPaint(size: Size(60 * sx, 60 * sy), painter: _PigPreviewPainter(sx, sy))),
        )),
        // ボタン
        Positioned(top: 550 * sy, left: 55 * sx, child: ListenableBuilder(
          listenable: Listenable.merge([_nicknameCtrl, _pigNameCtrl]),
          builder: (_, __) => PixelActionButton(
            width: 280 * sx, height: 44 * sy,
            label: 'はじめる！', icon: 'assets/pixel-art/icons/play.svg',
            enabled: _nicknameCtrl.text.trim().isNotEmpty && _pigNameCtrl.text.trim().isNotEmpty,
            onTap: _submit,
          ),
        )),
      ]),
    );
  }
}


class _PigPreviewPainter extends CustomPainter {
  final double sx, sy;
  _PigPreviewPainter(this.sx, this.sy);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    void r(double x, double y, double w, double h, Color c) {
      p.color = c;
      canvas.drawRect(Rect.fromLTWH(x * size.width / 120, y * size.height / 120, w * size.width / 120, h * size.height / 120), p);
    }
    const pink = Color(0xFFFF9BB3);
    const darkPink = Color(0xFFC46A85);
    const ink = Color(0xFF1A1228);
    const white = Color(0xFFFFFFFF);
    const nose = Color(0xFFE8485A);
    r(20, 30, 80, 70, pink);
    r(25, 20, 15, 15, pink); r(80, 20, 15, 15, pink);
    r(28, 22, 8, 8, darkPink); r(83, 22, 8, 8, darkPink);
    r(38, 48, 10, 10, white); r(72, 48, 10, 10, white);
    r(42, 52, 6, 6, ink); r(76, 52, 6, 6, ink);
    r(50, 65, 20, 14, nose); r(54, 69, 4, 4, ink); r(62, 69, 4, 4, ink);
    r(55, 82, 10, 3, darkPink);
    r(30, 100, 15, 12, pink); r(75, 100, 15, 12, pink);
    r(28, 60, 8, 6, darkPink); r(84, 60, 8, 6, darkPink);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
