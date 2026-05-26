import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/ui/pixel_tab_bar.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/ui/grass_animation.dart';
import 'package:buta_app/shared/ui/pixel_loader.dart';
import 'package:buta_app/shared/services/api_client.dart';

class EvoBookScreen extends ConsumerStatefulWidget {
  const EvoBookScreen({super.key});
  @override
  ConsumerState<EvoBookScreen> createState() => _EvoBookScreenState();
}

class _EvoBookScreenState extends ConsumerState<EvoBookScreen> {
  List<Map<String, dynamic>> _evos = [];
  int _currentLevel = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);

      // アバター情報取得（レベル）
      final avatarRes = await api.get('/avatar');
      final avatar = avatarRes.data['avatar'] as Map<String, dynamic>? ?? avatarRes.data as Map<String, dynamic>;
      _currentLevel = (avatar['level'] as num?)?.toInt() ?? 1;

      // 進化履歴取得
      final histRes = await api.get('/avatar/evolution-history');
      final history = (histRes.data['history'] as List?) ?? [];
      final unlockedStages = history.map((h) => (h as Map<String, dynamic>)['stage'] ?? h['evolutionStage']).toSet();

      // 図鑑データ構築
      _evos = _defaultEvos.map((e) {
        final lv = e['lv'] as int;
        final unlocked = lv <= _currentLevel || unlockedStages.contains(e['stage']);
        return {...e, 'unlocked': unlocked};
      }).toList();
    } catch (_) {
      // API失敗時はレベルベースで解放判定
      _evos = _defaultEvos.map((e) {
        return {...e, 'unlocked': (e['lv'] as int) <= _currentLevel};
      }).toList();
    }
    if (mounted) setState(() => _loading = false);
  }

  static const _defaultEvos = [
    {'name': 'たまご', 'lv': 0, 'stage': 0},
    {'name': 'こぶた', 'lv': 1, 'stage': 1},
    {'name': 'ぽっちゃり', 'lv': 5, 'stage': 2},
    {'name': 'まるまる', 'lv': 10, 'stage': 3},
    {'name': 'メガトン', 'lv': 15, 'stage': 4},
    {'name': 'ぶたキング', 'lv': 20, 'stage': 5},
    {'name': '???', 'lv': 99, 'stage': 99},
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.blue,
      appBar: const PixelAppBar(title: 'しんか ずかん', showBack: true),
      bottomNavigationBar: SafeArea(child: PixelTabBar(sx: sx, sy: sy, activeIndex: 0)),
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover)),
        const Positioned.fill(child: IgnorePointer(child: CloudAnimation())),
        Positioned.fill(child: IgnorePointer(child: GrassAnimation(sx: sx, sy: sy))),
        _loading
          ? const Center(child: PixelLoader())
          : Positioned.fill(child: GridView.builder(
              padding: EdgeInsets.all(14 * sx),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10 * sy,
                crossAxisSpacing: 8 * sx,
                childAspectRatio: 116 / 130,
              ),
              itemCount: _evos.length,
              itemBuilder: (context, i) {
                final evo = _evos[i];
                final unlocked = evo['unlocked'] as bool? ?? false;
                final bg = unlocked ? ButaColors.paper : ButaColors.bgDeep;
                final textColor = unlocked ? ButaColors.ink : ButaColors.gray;
                return Container(
                  decoration: BoxDecoration(color: bg, border: Border.all(color: ButaColors.ink, width: 1)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(width: 50, height: 50, child: CustomPaint(
                      painter: unlocked ? _EvoBookPigPainter() : _LockedPigPainter(),
                    )),
                    const SizedBox(height: 6),
                    Text(unlocked ? evo['name'] as String : '???', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: textColor)),
                    const SizedBox(height: 2),
                    Text('LV.${evo['lv']}', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 9, color: const Color(0xFFC46A85))),
                  ]),
                );
              },
            )),
      ]),
    );
  }
}

class _EvoBookPigPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 16;
    void px(double x, double y, double w, double h, Color c) =>
        canvas.drawRect(Rect.fromLTWH(x * u, y * u, w * u, h * u), Paint()..color = c);
    px(4, 5, 8, 7, const Color(0xFFFF9BB3));
    px(5, 2, 6, 5, const Color(0xFFFF9BB3));
    px(4, 1, 2, 2, const Color(0xFFFF9BB3)); px(10, 1, 2, 2, const Color(0xFFFF9BB3));
    px(6, 4, 1, 1, const Color(0xFF3D2B4D)); px(9, 4, 1, 1, const Color(0xFF3D2B4D));
    px(7, 5, 2, 1, const Color(0xFFE8485A));
    px(5, 12, 2, 2, const Color(0xFFFF9BB3)); px(9, 12, 2, 2, const Color(0xFFFF9BB3));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LockedPigPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 16;
    void px(double x, double y, double w, double h, Color c) =>
        canvas.drawRect(Rect.fromLTWH(x * u, y * u, w * u, h * u), Paint()..color = c);
    px(4, 5, 8, 7, const Color(0xFFB8A99A));
    px(5, 2, 6, 5, const Color(0xFFB8A99A));
    px(4, 1, 2, 2, const Color(0xFFB8A99A)); px(10, 1, 2, 2, const Color(0xFFB8A99A));
    px(7, 6, 2, 2, const Color(0xFF8A5A2B));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
