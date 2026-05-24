import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/ui/pixel_dialog.dart';
import 'package:buta_app/shared/ui/pixel_input.dart';

/// A-01 ログイン画面
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();

  Future<void> _login() async {
    final ok = await ref.read(authStateProvider.notifier).login(_emailCtrl.text, _pwCtrl.text);
    if (!mounted) return;
    if (ok) {
      context.go('/');
    } else {
      showPixelAlert(context, message: 'ログインに しっぱい\nしました。');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390;
    final sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.blue,
      body: Stack(
        children: [
          Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-barn.svg', fit: BoxFit.cover)),
          const Positioned.fill(child: CloudAnimation()),
          Positioned(top: 140 * sy, left: 0, right: 0, child: const Text('ログイン', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 20, color: ButaColors.paper))),
          Positioned(top: 240 * sy, left: 0, right: 0, child: const Text('メールアドレス', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
          Positioned(top: 258 * sy, left: 55 * sx, child: PixelInput(controller: _emailCtrl, sx: sx, sy: sy, hintText: 'mail@example.com')),
          Positioned(top: 310 * sy, left: 0, right: 0, child: const Text('パスワード', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
          Positioned(top: 328 * sy, left: 55 * sx, child: PixelInput(controller: _pwCtrl, sx: sx, sy: sy, obscure: true, hintText: 'パスワード')),
          Positioned(top: 390 * sy, left: 55 * sx, child: ListenableBuilder(
            listenable: Listenable.merge([_emailCtrl, _pwCtrl]),
            builder: (_, __) {
              final enabled = _emailCtrl.text.isNotEmpty && _pwCtrl.text.isNotEmpty;
              return PixelActionButton(width: 280 * sx, height: 44 * sy, label: '▶ ログイン', enabled: enabled, onTap: _login);
            },
          )),
          Positioned(top: 455 * sy, left: 0, right: 0, child: const Text('── または ──', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
          Positioned(top: 490 * sy, left: 55 * sx, child: PixelActionButton(width: 280 * sx, height: 40 * sy, label: 'Google で ログイン', fontSize: 14, color: ButaColors.paper, onTap: () {})),
          Positioned(top: 545 * sy, left: 55 * sx, child: PixelActionButton(width: 280 * sx, height: 40 * sy, label: 'X で ログイン', fontSize: 14, color: ButaColors.paper, onTap: () {})),
          Positioned(top: 610 * sy, left: 0, right: 0, child: GestureDetector(onTap: () => context.push('/signup'), child: const Text('アカウントを つくる →', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper)))),
          Positioned(top: 660 * sy, left: 0, right: 0, child: const Text('利用規約 ｜ プライバシーポリシー', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: ButaColors.paper))),
        ],
      ),
    );
  }
}
