import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/ui/pixel_dialog.dart';
import 'package:buta_app/shared/ui/pixel_input.dart';

/// A-03 メール確認画面
class ConfirmScreen extends ConsumerStatefulWidget {
  const ConfirmScreen({super.key, required this.email});
  final String email;
  @override
  ConsumerState<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends ConsumerState<ConfirmScreen> {
  final _codeCtrl = TextEditingController();

  Future<void> _confirm() async {
    final ok = await ref.read(authStateProvider.notifier).confirmSignup(widget.email, _codeCtrl.text);
    if (!mounted) return;
    if (ok) {
      await showPixelAlert(context, title: 'かんりょう', message: 'メールを かくにん しました！\nログインして ください。');
      if (mounted) context.go('/login');
    } else {
      showPixelAlert(context, message: 'コードが ちがいます。');
    }
  }

  Future<void> _resend() async {
    // mockサーバーは常に成功を返す
    showPixelAlert(context, title: 'おしらせ', message: 'コードを さいそうしん\nしました。');
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
      body: Stack(
        children: [
          Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-barn.svg', fit: BoxFit.cover)),
          const Positioned.fill(child: CloudAnimation()),
          Positioned(top: 140 * sy, left: 0, right: 0, child: const Text('メールを かくにん', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 20, color: ButaColors.paper))),
          Positioned(top: 220 * sy, left: 0, right: 0, child: const Text('とうろくした メールアドレスに\nかくにんコードを おくりました', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: Color(0xFFE8E9EA), height: 1.6))),
          // メールアドレス表示
          Positioned(top: 268 * sy, left: 0, right: 0, child: Text(widget.email, textAlign: TextAlign.center, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.paper))),
          Positioned(top: 290 * sy, left: 0, right: 0, child: const Text('かくにんコード', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
          // コード入力欄（中央、200x44）
          Positioned(top: 310 * sy, left: 95 * sx, child: _CodeInput(controller: _codeCtrl, sx: sx, sy: sy)),
          // 確認ボタン
          Positioned(top: 380 * sy, left: 55 * sx, child: ListenableBuilder(
            listenable: _codeCtrl,
            builder: (_, __) => PixelActionButton(width: 280 * sx, height: 44 * sy, label: 'かくにん', icon: 'assets/pixel-art/icons/play.svg', enabled: _codeCtrl.text.length == 6, onTap: _confirm),
          )),
          // 再送信リンク
          Positioned(top: 450 * sy, left: 0, right: 0, child: GestureDetector(onTap: _resend, child: const Text('コードを さいそうしん', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.paper)))),
          // 戻る導線
          Positioned(top: 490 * sy, left: 0, right: 0, child: GestureDetector(onTap: () => context.pop(), child: const Text('← サインアップに もどる', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: Color(0xFFE8E9EA))))),
        ],
      ),
    );
  }
}

class _CodeInput extends StatefulWidget {
  const _CodeInput({required this.controller, required this.sx, required this.sy});
  final TextEditingController controller;
  final double sx, sy;
  @override
  State<_CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<_CodeInput> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200 * widget.sx, height: 44 * widget.sy,
      decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: _focused ? ButaColors.yellow : ButaColors.ink, width: 2)),
      alignment: Alignment.center,
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        child: TextField(
          controller: widget.controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.ink, letterSpacing: 8),
          decoration: const InputDecoration(
            border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, disabledBorder: InputBorder.none,
            isDense: true, counterText: '', contentPadding: EdgeInsets.zero,
            hintText: '000000',
            hintStyle: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.gray, letterSpacing: 8),
          ),
        ),
      ),
    );
  }
}
