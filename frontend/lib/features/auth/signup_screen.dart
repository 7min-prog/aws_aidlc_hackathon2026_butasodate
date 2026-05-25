import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/ui/pixel_dialog.dart';
import 'package:buta_app/shared/ui/pixel_input.dart';

/// A-02 サインアップ画面
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();
  bool _agreed = false;

  bool get _canSubmit => _emailCtrl.text.isNotEmpty && _pwCtrl.text.isNotEmpty && _pwConfirmCtrl.text.isNotEmpty && _agreed;

  Future<void> _signup() async {
    if (_pwCtrl.text != _pwConfirmCtrl.text) {
      showPixelAlert(context, message: 'パスワードが\nあっていません。');
      return;
    }
    final ok = await ref.read(authStateProvider.notifier).signup(_emailCtrl.text, _pwCtrl.text);
    if (!mounted) return;
    if (ok) {
      context.push('/confirm', extra: _emailCtrl.text);
    } else {
      showPixelAlert(context, message: 'アカウントの さくせいに\nしっぱい しました。');
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
      body: Stack(
        children: [
          Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-barn.svg', fit: BoxFit.cover)),
          const Positioned.fill(child: CloudAnimation()),
          Positioned(top: 138 * sy, left: 0, right: 0, child: const Text('アカウントを さくせい', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 20, color: ButaColors.paper))),
          Positioned(top: 170 * sy, left: 0, right: 0, child: const Text('メールアドレス', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
          Positioned(top: 188 * sy, left: 55 * sx, child: PixelInput(controller: _emailCtrl, sx: sx, sy: sy, hintText: 'mail@example.com')),
          Positioned(top: 240 * sy, left: 0, right: 0, child: const Text('パスワード', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
          Positioned(top: 258 * sy, left: 55 * sx, child: PixelInput(controller: _pwCtrl, sx: sx, sy: sy, obscure: true, hintText: 'パスワード')),
          Positioned(top: 310 * sy, left: 0, right: 0, child: const Text('パスワード（かくにん）', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
          Positioned(top: 328 * sy, left: 55 * sx, child: PixelInput(controller: _pwConfirmCtrl, sx: sx, sy: sy, obscure: true, hintText: 'もういちど にゅうりょく')),
          // 規約チェックボックス + テキスト
          Positioned(top: 385 * sy, left: 0, right: 0, child: GestureDetector(
            onTap: () => setState(() => _agreed = !_agreed),
            child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 20, height: 20, decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
                child: _agreed ? Center(child: SvgPicture.asset('assets/pixel-art/icons/check.svg', width: 14, height: 14)) : null),
              const SizedBox(width: 8),
              GestureDetector(onTap: () => context.push('/terms', extra: false), child: const Text('利用規約', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.paper, decoration: TextDecoration.underline))),
              const Text('・', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.gray)),
              GestureDetector(onTap: () => context.push('/privacy', extra: false), child: const Text('プライバシーポリシー', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.paper, decoration: TextDecoration.underline))),
              const Text('に同意', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.gray)),
            ]),
          )),
          // ボタン
          Positioned(top: 430 * sy, left: 55 * sx, child: ListenableBuilder(
            listenable: Listenable.merge([_emailCtrl, _pwCtrl, _pwConfirmCtrl]),
            builder: (_, __) => PixelActionButton(width: 280 * sx, height: 44 * sy, label: 'アカウントを つくる', icon: 'assets/pixel-art/icons/play.svg', enabled: _canSubmit, onTap: _signup),
          )),
          Positioned(top: 500 * sy, left: 0, right: 0, child: GestureDetector(onTap: () => context.pop(), child: const Text('すでに アカウントが ある →', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper)))),
        ],
      ),
    );
  }
}
