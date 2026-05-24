import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/pixel_input.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/ui/grass_animation.dart';
import 'package:buta_app/shared/ui/pixel_dialog.dart';
import 'package:buta_app/features/home/home_screen.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nickCtrl = TextEditingController(text: 'プレイヤー');
  final _avatarCtrl = TextEditingController(text: 'こぶた');

  @override
  void dispose() { _nickCtrl.dispose(); _avatarCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.blue,
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover)),
        const Positioned.fill(child: CloudAnimation()),
        Positioned.fill(child: GrassAnimation(sx: sx, sy: sy)),
        Positioned(top: 0, left: 0, right: 0, height: 48 * sy, child: Container(color: ButaColors.ink, child: Stack(children: [
          Align(alignment: Alignment.centerLeft, child: GestureDetector(onTap: () => Navigator.pop(context), child: Padding(padding: EdgeInsets.only(left: 12 * sx), child: Text('◀', style: TextStyle(fontSize: 18, color: ButaColors.paper))))),
          Center(child: Text('プロフィール', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.paper))),
        ]))),
        Positioned(top: 48 * sy, left: 0, right: 0, child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 55 * sx),
          child: Column(children: [
            SizedBox(height: 24 * sy),
            Text('ニックネーム', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper)),
            SizedBox(height: 8 * sy),
            PixelInput(controller: _nickCtrl, sx: sx, sy: sy, hintText: 'ニックネーム'),
            SizedBox(height: 24 * sy),
            Text('アバターの なまえ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper)),
            SizedBox(height: 8 * sy),
            PixelInput(controller: _avatarCtrl, sx: sx, sy: sy, hintText: 'アバターの なまえ'),
            SizedBox(height: 32 * sy),
            Center(child: PixelActionButton(
              width: 280 * sx, height: 44 * sy, label: 'ほぞんする',
              onTap: () async {
                await showPixelAlert(context, message: 'ほぞんしました！');
                if (context.mounted) Navigator.pop(context);
              },
            )),
          ]),
        )),
        Positioned(bottom: 0, left: 0, right: 0, height: 56 * sy, child: PixelTabBar(sx: sx, sy: sy, activeIndex: 4)),
      ]),
    );
  }
}
