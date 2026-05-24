import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/features/home/home_screen.dart';

class HealthDataScreen extends StatefulWidget {
  const HealthDataScreen({super.key});
  @override
  State<HealthDataScreen> createState() => _HealthDataScreenState();
}

class _HealthDataScreenState extends State<HealthDataScreen> {
  bool _connected = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.blue,
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover)),
        // Header
        Positioned(top: 0, left: 0, right: 0, height: 48 * sy, child: Container(color: ButaColors.ink, child: Stack(children: [
          Align(alignment: Alignment.centerLeft, child: GestureDetector(onTap: () => Navigator.pop(context), child: Padding(padding: EdgeInsets.only(left: 14 * sx), child: Text('◀', style: TextStyle(fontSize: 18, color: ButaColors.paper))))),
          Center(child: Text('ヘルスデータ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.paper))),
        ]))),
        // Content
        Positioned(top: 60 * sy, left: 14 * sx, right: 14 * sx, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ステータスラベル
          Text('れんけい じょうたい', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray)),
          SizedBox(height: 4 * sy),
          // ステータスボックス
          Container(
            width: 362 * sx, height: 44 * sy,
            padding: EdgeInsets.symmetric(horizontal: 14 * sx),
            decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
            alignment: Alignment.centerLeft,
            child: Text(_connected ? '● れんけいちゅう' : '● みせつぞく', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: _connected ? ButaColors.green : ButaColors.gray)),
          ),
          SizedBox(height: 20 * sy),
          // データラベル
          Text('しゅとく データ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray)),
          SizedBox(height: 4 * sy),
          // リストアイテム3つ
          _listItem(sx, sy, 'たいじゅう'),
          SizedBox(height: 2 * sy),
          _listItem(sx, sy, 'ほすう'),
          SizedBox(height: 2 * sy),
          _listItem(sx, sy, 'すいみん'),
          SizedBox(height: 16 * sy),
          // 同期日時
          Text('さいご の どうき: 2026/05/23 08:00', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.gray)),
          SizedBox(height: 40 * sy),
          // 解除ボタン
          GestureDetector(
            onTap: () => setState(() => _connected = !_connected),
            child: Container(
              width: 362 * sx, height: 40 * sy,
              decoration: BoxDecoration(color: ButaColors.red, border: Border.all(color: ButaColors.ink, width: 2)),
              alignment: Alignment.center,
              child: Text('れんけい を かいじょ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper)),
            ),
          ),
        ])),
        // TabBar
        Positioned(bottom: 0, left: 0, right: 0, height: 56 * sy, child: PixelTabBar(sx: sx, sy: sy, activeIndex: 4)),
      ]),
    );
  }

  Widget _listItem(double sx, double sy, String label) {
    return Container(
      width: 362 * sx, height: 48 * sy,
      padding: EdgeInsets.symmetric(horizontal: 14 * sx),
      decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
      child: Row(children: [
        Text(label, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
        const Spacer(),
        Text('▶', style: TextStyle(fontSize: 12, color: ButaColors.ink)),
      ]),
    );
  }
}
