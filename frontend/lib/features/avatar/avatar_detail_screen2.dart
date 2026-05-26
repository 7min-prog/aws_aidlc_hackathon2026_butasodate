import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/app_config.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/ui/pixel_tab_bar.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/ui/grass_animation.dart';

class AvatarDetailScreen extends StatefulWidget {
  const AvatarDetailScreen({super.key, this.avatar});
  final Map<String, dynamic>? avatar;
  @override
  State<AvatarDetailScreen> createState() => _AvatarDetailScreenState();
}

class _AvatarDetailScreenState extends State<AvatarDetailScreen> {
  Map<String, dynamic>? _avatar;

  @override
  void initState() {
    super.initState();
    _avatar = widget.avatar;
    if (_avatar == null || _avatar!.isEmpty) _fetchAvatar();
  }

  Future<void> _fetchAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('id_token') ?? '';
      final dio = Dio(BaseOptions(headers: {'Authorization': token}));
      final res = await dio.get('${AppConfig.avatarApiBase}/avatar');
      final data = res.data as Map<String, dynamic>? ?? {};
      if (mounted) setState(() => _avatar = data['avatar'] as Map<String, dynamic>? ?? data);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;
    final a = _avatar ?? {'name': 'こぶた', 'level': 1, 'stats': {'hp': 100, 'attack': 10, 'defense': 10, 'speed': 10}};
    final stats = a['stats'] as Map<String, dynamic>? ?? {};
    final skillList = (a['skills'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final skills = skillList.isNotEmpty
        ? skillList.map((s) => s['name'] as String? ?? s['skillId'] as String? ?? '???').toList()
        : (a['skillIds'] as List?)?.cast<String>() ?? ['まだ スキルが ないよ'];

    return Scaffold(
      backgroundColor: ButaColors.blue,
      appBar: const PixelAppBar(title: 'ぶたの ようす', showBack: true),
      bottomNavigationBar: SafeArea(child: PixelTabBar(sx: sx, sy: sy, activeIndex: 0)),
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover)),
        const Positioned.fill(child: CloudAnimation()),
        Positioned.fill(child: GrassAnimation(sx: sx, sy: sy)),
        // アバター背景 + SVG
        Positioned(top: 12 * sy, left: 120 * sx, child: SizedBox(
          width: 150 * sx, height: 150 * sx,
          child: Center(child: SizedBox(width: 100, height: 100, child: CustomPaint(painter: _DetailPigPainter()))),
        )),
        // 名前
        Positioned(top: 172 * sy, left: 14 * sx, width: 362 * sx, child: Text(
          a['name'] ?? 'こぶた', textAlign: TextAlign.center,
          style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.ink),
        )),
        // レベル
        Positioned(top: 194 * sy, left: 14 * sx, width: 362 * sx, child: Text(
          'LV.${a['level'] ?? 1}', textAlign: TextAlign.center,
          style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: const Color(0xFFC46A85)),
        )),
        // ステータスカード
        Positioned(top: 222 * sy, left: 14 * sx, child: Container(
          width: 362 * sx, height: 105 * sy,
          padding: EdgeInsets.symmetric(horizontal: 12 * sx, vertical: 8 * sy),
          decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ステータス', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.ink)),
            SizedBox(height: 4 * sy),
            _statBar('HP', (stats['hp'] as num?)?.toDouble() ?? 0, 200, ButaColors.green, sx, sy),
            SizedBox(height: 3 * sy),
            _statBar('ATK', (stats['attack'] as num?)?.toDouble() ?? 0, 100, ButaColors.red, sx, sy),
            SizedBox(height: 3 * sy),
            _statBar('DEF', (stats['defense'] as num?)?.toDouble() ?? 0, 100, ButaColors.blue, sx, sy),
            SizedBox(height: 3 * sy),
            _statBar('SPD', (stats['speed'] as num?)?.toDouble() ?? 0, 100, ButaColors.yellow, sx, sy),
          ]),
        )),
        // スキルタイトル
        Positioned(top: 337 * sy, left: 14 * sx, child: Text('スキル', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.ink))),
        // スキルリスト
        ...List.generate(skills.length.clamp(0, 4), (i) => Positioned(
          top: (357 + i * 38) * sy, left: 14 * sx,
          child: Container(
            width: 362 * sx, height: 34 * sy,
            padding: EdgeInsets.symmetric(horizontal: 12 * sx),
            decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
            alignment: Alignment.centerLeft,
            child: Text(skills[i], style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.ink)),
          ),
        )),
        // 進化図鑑リンク
        Positioned(top: 522 * sy, left: 14 * sx, child: GestureDetector(
          onTap: () => context.push('/evo-book'),
          child: Container(
            width: 362 * sx, height: 40 * sy,
            decoration: BoxDecoration(color: ButaColors.bgDeep, border: Border.all(color: ButaColors.ink, width: 1)),
            alignment: Alignment.center,
            child: Text('しんか ずかん →', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink)),
          ),
        )),
        // タブバー
      ]),
    );
  }

  Widget _statBar(String label, double value, double max, Color color, double sx, double sy) {
    return Row(children: [
      SizedBox(width: 32 * sx, child: Text(label, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 9, color: ButaColors.gray))),
      Expanded(child: SizedBox(height: 8 * sy, child: Stack(children: [
        Container(color: ButaColors.ink),
        FractionallySizedBox(widthFactor: (value / max).clamp(0, 1), child: Container(color: color)),
      ]))),
      SizedBox(width: 4 * sx),
      SizedBox(width: 28 * sx, child: Text('${value.toInt()}', style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 8, color: ButaColors.ink))),
    ]);
  }
}


class _DetailPigPainter extends CustomPainter {
  _DetailPigPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    final s = size.width / 120;
    void r(double x, double y, double w, double h, Color c) {
      p.color = c;
      canvas.drawRect(Rect.fromLTWH(x * s, y * s, w * s, h * s), p);
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
    r(50, 65, 20, 14, nose);
    r(54, 69, 4, 4, ink); r(62, 69, 4, 4, ink);
    r(55, 82, 10, 3, darkPink);
    r(30, 100, 15, 12, pink); r(75, 100, 15, 12, pink);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}