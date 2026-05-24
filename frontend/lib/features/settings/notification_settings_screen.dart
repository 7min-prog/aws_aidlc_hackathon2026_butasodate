import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/ui/grass_animation.dart';
import 'package:buta_app/features/home/home_screen.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _battleInvite = true;
  bool _recordReminder = false;

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
          Center(child: Text('つうち せってい', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.paper))),
        ]))),
        Positioned(top: 60 * sy, left: 14 * sx, child: Column(children: [
          _toggle(sx, sy, 'プッシュつうち', _pushEnabled, (v) => setState(() => _pushEnabled = v)),
          SizedBox(height: 2 * sy),
          _toggle(sx, sy, 'バトル しょうたい', _battleInvite, (v) => setState(() => _battleInvite = v)),
          SizedBox(height: 2 * sy),
          _toggle(sx, sy, 'きろく リマインダー', _recordReminder, (v) => setState(() => _recordReminder = v)),
        ])),
        Positioned(bottom: 0, left: 0, right: 0, height: 56 * sy, child: PixelTabBar(sx: sx, sy: sy, activeIndex: 4)),
      ]),
    );
  }

  Widget _toggle(double sx, double sy, String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 362 * sx, height: 48 * sy,
        padding: EdgeInsets.symmetric(horizontal: 14 * sx),
        decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
        child: Row(children: [
          Text(label, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
          const Spacer(),
          Container(
            width: 40 * sx, height: 22 * sy,
            decoration: BoxDecoration(color: value ? ButaColors.green : ButaColors.gray, border: Border.all(color: ButaColors.ink, width: 2)),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 2 * sx),
            child: Container(width: 14 * sx, height: 14 * sy, color: ButaColors.paper),
          ),
        ]),
      ),
    );
  }
}
