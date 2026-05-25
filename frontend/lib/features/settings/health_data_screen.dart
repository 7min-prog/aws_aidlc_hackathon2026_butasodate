import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/ui/pixel_tab_bar.dart';

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
      appBar: const PixelAppBar(title: 'ヘルスデータ', showBack: true),
      bottomNavigationBar: SafeArea(child: PixelTabBar(sx: sx, sy: sy, activeIndex: 4)),
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover)),
        // Header
        // Content
        Positioned(top: 12 * sy, left: 14 * sx, right: 14 * sx, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
        SvgPicture.asset('assets/pixel-art/icons/play.svg', width: 12, height: 12),
      ]),
    );
  }
}
