import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/auth_state.dart';

/// A-01 ログイン画面 (390x740, bg-barn)
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
    if (ok && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390;
    final sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.blue, // bg-barn: #5a8ed1
      body: SizedBox.expand(
        child: Stack(
          children: [
            // bg-barn SVG背景
            Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-barn.svg', fit: BoxFit.cover)),

            // タイトル
            Positioned(top: 140 * sy, left: 0, right: 0, child: const Text('ログイン', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 20, color: ButaColors.paper))),

            // メールラベル
            Positioned(top: 240 * sy, left: 0, right: 0, child: const Text('メールアドレス', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
            // メール入力
            Positioned(top: 258 * sy, left: 55 * sx, child: _input(_emailCtrl, sx, sy)),

            // パスワードラベル
            Positioned(top: 310 * sy, left: 0, right: 0, child: const Text('パスワード', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
            // パスワード入力
            Positioned(top: 328 * sy, left: 55 * sx, child: _input(_pwCtrl, sx, sy, obscure: true)),

            // ログインボタン
            Positioned(top: 390 * sy, left: 55 * sx, child: _btn(280 * sx, 44 * sy, ButaColors.yellow, '▶ ログイン', 16, ButaColors.ink, _login)),

            // 区切り
            Positioned(top: 455 * sy, left: 0, right: 0, child: const Text('── または ──', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),

            // Googleボタン
            Positioned(top: 490 * sy, left: 55 * sx, child: _btn(280 * sx, 40 * sy, ButaColors.paper, 'Google で ログイン', 14, ButaColors.ink, () {})),
            // Xボタン
            Positioned(top: 545 * sy, left: 55 * sx, child: _btn(280 * sx, 40 * sy, ButaColors.paper, 'X で ログイン', 14, ButaColors.ink, () {})),

            // サインアップリンク
            Positioned(top: 610 * sy, left: 0, right: 0, child: GestureDetector(onTap: () => context.push('/signup'), child: const Text('アカウントを つくる →', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: Color(0xFFE8E9EA))))),

            // 法務リンク
            Positioned(top: 660 * sy, left: 0, right: 0, child: const Text('利用規約 ｜ プライバシーポリシー', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: Color(0xFFE8E9EA)))),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, double sx, double sy, {bool obscure = false}) {
    return Container(
      width: 280 * sx, height: 36 * sy,
      decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
      padding: EdgeInsets.symmetric(horizontal: 8 * sx),
      child: TextField(
        controller: ctrl, obscureText: obscure,
        style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink),
        decoration: const InputDecoration(
          border: InputBorder.none, isDense: true,
          hintText: 'なまえを いれてね...',
          hintStyle: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.gray),
        ),
      ),
    );
  }

  Widget _btn(double w, double h, Color bg, String label, double fontSize, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w, height: h,
        decoration: BoxDecoration(color: bg, border: Border.all(color: ButaColors.ink, width: 2)),
        child: Center(child: Text(label, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: fontSize, color: textColor))),
      ),
    );
  }
}
