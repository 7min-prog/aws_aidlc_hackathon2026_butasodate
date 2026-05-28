import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/ui/pixel_tab_bar.dart';
import 'package:buta_app/shared/ui/pixel_loader.dart';
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/features/home/health_sync_result_dialog.dart';

final homeDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final api = ref.read(apiClientProvider);
    final results = await Future.wait([
      api.get('/avatar'),
      api.get('/activities'),
    ]);
    final avatarData = results[0].data is Map<String, dynamic> ? results[0].data as Map<String, dynamic> : <String, dynamic>{};
    final avatar = avatarData['avatar'] as Map<String, dynamic>? ?? avatarData;
    final actData = results[1].data is Map<String, dynamic> ? results[1].data as Map<String, dynamic> : <String, dynamic>{};
    return {
      'avatar': avatar.isNotEmpty ? avatar : {'name': 'こぶた', 'level': 1, 'totalPoints': 0},
      'records': (actData['items'] ?? actData['records'] ?? []) as List,
      'summary': actData['summary'] ?? {'todayCount': 0, 'todayPoints': 0},
    };
  } catch (_) {
    return {
      'avatar': {'name': 'こぶた', 'level': 1, 'totalPoints': 0},
      'records': <dynamic>[],
      'summary': {'todayCount': 0, 'todayPoints': 0},
    };
  }
});

/// アプリプロセス単位で1回だけヘルスデータ同期結果を表示するためのフラグ
bool _healthSyncShown = false;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkHealthSync());
  }

  Future<void> _checkHealthSync() async {
    if (_healthSyncShown) return;
    _healthSyncShown = true;
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.get('/health-sync/result'),
        api.get('/avatar'),
      ]);
      final data = results[0].data as Map<String, dynamic>?;
      if (data != null && data['hasResults'] == true && mounted) {
        final items = (data['items'] as List).cast<Map<String, dynamic>>();
        final totalPoints = data['totalPoints'] as int;
        final avatarData = results[1].data is Map<String, dynamic> ? results[1].data as Map<String, dynamic> : <String, dynamic>{};
        final avatar = avatarData['avatar'] as Map<String, dynamic>? ?? avatarData;
        final avatarName = avatar['name'] as String? ?? 'ぶた';
        showDialog(
          context: context,
          barrierColor: ButaColors.ink.withValues(alpha: 0.6),
          builder: (_) => HealthSyncResultDialog(items: items, totalPoints: totalPoints, avatarName: avatarName),
        );
      }
    } catch (_) {
      // ヘルスデータ取得失敗は無視
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390;
    final sy = size.height / 740;
    final homeData = ref.watch(homeDataProvider);

    return Scaffold(
      backgroundColor: ButaColors.blue,
      appBar: const PixelAppBar(title: 'ぶたそだて'),
      bottomNavigationBar: SafeArea(child: PixelTabBar(sx: sx, sy: sy, activeIndex: 0)),
      body: Stack(
        children: [
          // 背景
          Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover)),
          // 雲アニメーション
          const Positioned.fill(child: CloudAnimation()),
          // 草アニメーション
          Positioned.fill(child: _GrassAnimation(sx: sx, sy: sy)),
          // サマリーカード
          Positioned(top: 12 * sy, left: 14 * sx, child: GestureDetector(
            onTap: () => context.go('/recording'),
            child: _SummaryCard(sx: sx, sy: sy, homeData: homeData),
          )),
          // ステータスパネル
          Positioned(top: 122 * sy, left: 14 * sx, child: _StatPanel(sx: sx, sy: sy, homeData: homeData)),
          // アバターエリア
          Positioned(top: 262 * sy, left: 0, right: 0, child: GestureDetector(
            onTap: () => context.push('/avatar-detail', extra: homeData.value?['avatar']),
            child: SizedBox(
              height: 200 * sx,
              child: Center(child: _AnimatedPig(sx: sx, sy: sx, level: homeData.value?['avatar']?['level'] ?? 1)),
            ),
          )),
          // レベル + 名前
          Positioned(top: 482 * sy, left: 95 * sx, child: homeData.when(
            data: (d) {
              final avatar = d['avatar'] ?? {};
              return Row(children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6 * sx, vertical: 2 * sy),
                  color: const Color(0xFFC46A85),
                  child: Text('LV.${avatar['level'] ?? 1}', style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 10, color: ButaColors.paper)),
                ),
                SizedBox(width: 8 * sx),
                Text(avatar['name'] ?? 'こぶた', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.ink)),
              ]);
            },
            loading: () => Container(width: 100, height: 16, decoration: BoxDecoration(color: ButaColors.paper.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            error: (_, __) => Row(children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6 * sx, vertical: 2 * sy),
                color: const Color(0xFFC46A85),
                child: Text('LV.1', style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 10, color: ButaColors.paper)),
              ),
              SizedBox(width: 8 * sx),
              Text('こぶた', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.ink)),
            ]),
          )),
          // EXPバー
          Positioned(top: 512 * sy, left: 95 * sx, child: homeData.when(
            data: (d) {
              final pts = (d['avatar']?['totalPoints'] ?? 0) as int;
              final progress = (pts % 500) / 500;
              return _ExpBar(sx: sx, sy: sy, progress: progress);
            },
            loading: () => _ExpBar(sx: sx, sy: sy, progress: 0),
            error: (_, __) => _ExpBar(sx: sx, sy: sy, progress: 0),
          )),
          // 記録ボタン
          Positioned(bottom: 20, left: 95 * sx, child: _RecordButton(sx: sx, sy: sy)),
          // タブバー
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.sx, required this.sy, required this.homeData});
  final double sx, sy;
  final AsyncValue<Map<String, dynamic>> homeData;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362 * sx, height: 100 * sy,
      padding: EdgeInsets.symmetric(horizontal: 14 * sx, vertical: 8 * sy),
      decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
      child: homeData.when(
        data: (d) {
          final records = (d['records'] as List?) ?? [];
          final summary = d['summary'];
          final todayPts = summary?['todayPoints'] ?? 0;
          final now = DateTime.now();
          final todayRecords = records.where((r) {
            final date = (DateTime.tryParse(r['recordedAt'] ?? '') ?? DateTime(2000)).toLocal();
            return date.year == now.year && date.month == now.month && date.day == now.day;
          }).take(2).toList();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('きょうの きろく', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink)),
            SizedBox(height: 4 * sy),
            if (todayRecords.isEmpty) Text('まだ きろくが ないよ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray)),
            for (final r in todayRecords) ...[
              _summaryRow(_categoryName(r['categoryId']), '+${r['points']}pt'),
              SizedBox(height: 2 * sy),
            ],
            if (todayRecords.isNotEmpty) Text('きょうの合計: +${todayPts}pt', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: const Color(0xFFC46A85))),
          ]);
        },
        loading: () => const Center(child: PixelLoader()),
        error: (_, __) => Center(child: Text('エラー', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.red))),
      ),
    );
  }

  String _categoryName(String? id) {
    const names = {
      'food_late_ramen': 'しんやラーメン', 'food_snack': 'かんしょく', 'food_binge': 'ぼういんぼうしょく',
      'food_junkfood': 'ジャンクフード', 'life_stay_up': 'よふかし', 'life_oversleep': 'にどね',
      'life_skip_exercise': 'うんどうサボり', 'life_binge_watch': 'いっきみ',
    };
    return names[id] ?? id ?? '???';
  }

  Widget _summaryRow(String label, String pts) {
    return Row(children: [
      Text(label, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.ink2)),
      const Spacer(),
      Text(pts, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.ink2)),
    ]);
  }
}

class _StatPanel extends StatelessWidget {
  const _StatPanel({required this.sx, required this.sy, required this.homeData});
  final double sx, sy;
  final AsyncValue<Map<String, dynamic>> homeData;
  @override
  Widget build(BuildContext context) {
    return homeData.when(
      data: (d) {
        final avatar = d['avatar'] ?? {};
        final stats = avatar['stats'] ?? {'hp': 0, 'attack': 0, 'defense': 0, 'speed': 0};
        return _buildStats(stats);
      },
      loading: () => _buildStats({'hp': 0, 'attack': 0, 'defense': 0, 'speed': 0}),
      error: (_, __) => _buildStats({'hp': 0, 'attack': 0, 'defense': 0, 'speed': 0}),
    );
  }

  Widget _buildStats(Map<String, dynamic> stats) {
    return SizedBox(
      width: 362 * sx, height: 123 * sy,
      child: Wrap(spacing: 5 * sx, runSpacing: 5 * sy, children: [
        _statCard('HP', '${stats['hp']}/100', (stats['hp'] as int) / 100, const Color(0xFFE8485A), 'assets/pixel-art/icons/stat-hp.svg'),
        _statCard('ATK', '${stats['attack']}/50', (stats['attack'] as int) / 50, ButaColors.yellow, 'assets/pixel-art/icons/stat-atk.svg'),
        _statCard('DEF', '${stats['defense']}/50', (stats['defense'] as int) / 50, ButaColors.green, 'assets/pixel-art/icons/stat-def.svg'),
        _statCard('SPD', '${stats['speed']}/50', (stats['speed'] as int) / 50, ButaColors.blue, 'assets/pixel-art/icons/stat-spd.svg'),
      ]),
    );
  }

  Widget _statCard(String label, String value, double progress, Color barColor, String iconAsset) {
    return Container(
      width: 176 * sx, height: 54 * sy,
      padding: EdgeInsets.symmetric(horizontal: 8 * sx, vertical: 4 * sy),
      decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          SvgPicture.asset(iconAsset, width: 12 * sx, height: 12 * sy),
          SizedBox(width: 4 * sx),
          Text(label, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: ButaColors.ink)),
          const Spacer(),
          Text(value, style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 11, color: ButaColors.ink)),
        ]),
        SizedBox(height: 4 * sy),
        SizedBox(height: 8 * sy, child: Stack(children: [
          Container(color: ButaColors.ink),
          FractionallySizedBox(widthFactor: progress, child: Container(color: barColor)),
        ])),
      ]),
    );
  }
}

class _AnimatedPig extends StatefulWidget {
  const _AnimatedPig({required this.sx, required this.sy, required this.level});
  final double sx, sy;
  final int level;
  @override
  State<_AnimatedPig> createState() => _AnimatedPigState();
}

class _AnimatedPigState extends State<_AnimatedPig> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  // 徘徊パス: ランダム生成
  late final List<List<double>> _path;
  double _totalDuration = 0;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    final halfW = (390 - 80) / 2; // 正規化座標（sxで実画面に変換される）
    _path = List.generate(6, (_) => [
      (rng.nextDouble() - 0.5) * 2 * halfW, // x: ±155（sx掛けで実画面端まで）
      (rng.nextDouble() * 60 - 30),
      2.0 + rng.nextDouble() * 2.0,
      rng.nextDouble() < 0.4 ? 1.0 + rng.nextDouble() : 0.0,
    ]);
    for (final p in _path) {
      _totalDuration += p[2] + p[3];
    }
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: (_totalDuration * 1000).round()))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _ctrl, builder: (_, __) {
      final elapsed = _ctrl.value * _totalDuration;
      // 現在のセグメントを特定
      double acc = 0;
      double dx = 0, dy = 0;
      bool walking = false;
      for (int i = 0; i < _path.length; i++) {
        final moveDur = _path[i][2];
        final pauseDur = _path[i][3];
        final segDur = moveDur + pauseDur;
        if (elapsed < acc + segDur) {
          final segElapsed = elapsed - acc;
          final prevX = i == 0 ? _path.last[0] : _path[i - 1][0];
          final prevY = i == 0 ? _path.last[1] : _path[i - 1][1];
          final targetX = _path[i][0];
          final targetY = _path[i][1];
          if (segElapsed < moveDur) {
            // 歩き中 - smoothstep補間
            final p = segElapsed / moveDur;
            final smooth = p * p * (3 - 2 * p);
            dx = prevX + (targetX - prevX) * smooth;
            dy = prevY + (targetY - prevY) * smooth;
            walking = true;
          } else {
            // 立ち止まり中
            dx = targetX;
            dy = targetY;
            walking = false;
          }
          break;
        }
        acc += segDur;
      }

      // 歩きバウンス（滑らかなsin波）
      final bounce = walking ? math.sin(_ctrl.value * _totalDuration * 6 * math.pi) * 2.0 * widget.sy : 0.0;

      return Transform.translate(
        offset: Offset(dx * widget.sx, dy * widget.sy + bounce),
        child: Image.asset(widget.level >= 5 ? 'assets/pig_ramen.png' : 'assets/pig_default.png', width: 120 * widget.sx, height: 120 * widget.sx, fit: BoxFit.contain),
      );
    });
  }
}

class _PigPainter extends CustomPainter {
  _PigPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    void r(double x, double y, double w, double h, Color c) {
      p.color = c;
      canvas.drawRect(Rect.fromLTWH(x * 80 / 120, y * 80 / 120, w * 80 / 120, h * 80 / 120), p);
    }

    const pink = Color(0xFFFF9BB3);
    const darkPink = Color(0xFFC46A85);
    const ink = Color(0xFF1A1228);
    const white = Color(0xFFFFFFFF);
    const nose = Color(0xFFE8485A);

    // 体
    r(20, 30, 80, 70, pink);
    // 耳
    r(25, 20, 15, 15, pink);
    r(80, 20, 15, 15, pink);
    r(28, 22, 8, 8, darkPink);
    r(83, 22, 8, 8, darkPink);
    // 目
    r(38, 48, 10, 10, white);
    r(72, 48, 10, 10, white);
    r(42, 52, 6, 6, ink);
    r(76, 52, 6, 6, ink);
    // 鼻
    r(50, 65, 20, 14, nose);
    r(54, 69, 4, 4, ink);
    r(62, 69, 4, 4, ink);
    // 口
    r(55, 82, 10, 3, darkPink);
    // 足
    r(30, 100, 15, 12, pink);
    r(75, 100, 15, 12, pink);
    // ほっぺ
    r(28, 60, 8, 6, darkPink);
    r(84, 60, 8, 6, darkPink);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GrassAnimation extends StatefulWidget {
  const _GrassAnimation({required this.sx, required this.sy});
  final double sx, sy;
  @override
  State<_GrassAnimation> createState() => _GrassAnimationState();
}

class _GrassAnimationState extends State<_GrassAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _ctrl, builder: (_, __) {
      return CustomPaint(painter: _GrassPainter(_ctrl.value, widget.sx, widget.sy));
    });
  }
}

class _GrassPainter extends CustomPainter {
  final double t, sx, sy;
  _GrassPainter(this.t, this.sx, this.sy);

  static const _blades = [
    [30.0, 420.0], [120.0, 415.0], [210.0, 425.0], [310.0, 418.0],
    [70.0, 440.0], [160.0, 450.0], [250.0, 435.0], [340.0, 445.0],
    [45.0, 470.0], [135.0, 465.0], [225.0, 475.0], [305.0, 468.0],
    [80.0, 500.0], [180.0, 495.0], [270.0, 505.0], [360.0, 498.0],
    [50.0, 530.0], [150.0, 540.0], [240.0, 525.0], [330.0, 535.0],
    [100.0, 560.0], [200.0, 555.0], [290.0, 565.0], [370.0, 558.0],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (int i = 0; i < _blades.length; i++) {
      final bx = _blades[i][0] * sx;
      final by = _blades[i][1] * sy;
      // 風が左から右に流れる：x位置で位相をずらす
      final windPhase = t * 2 * 3.14159 - (_blades[i][0] / 390) * 3.14159;
      // sin波で滑らかに傾く（-1〜1）
      final bend = _sin(windPhase) * 3 * sx;

      paint.color = i % 3 == 0 ? const Color(0xFF2F6B3C) : const Color(0xFF4A9B5A);
      final h = (8 + (i % 3) * 2).toDouble() * sy;

      // 草を3段で描画（根→中→先端）、上に行くほど傾く
      canvas.drawRect(Rect.fromLTWH(bx, by, 2 * sx, h * 0.4), paint);
      canvas.drawRect(Rect.fromLTWH(bx + bend * 0.3, by - h * 0.3, 2 * sx, h * 0.3), paint);
      canvas.drawRect(Rect.fromLTWH(bx + bend * 0.7, by - h * 0.6, 2 * sx, h * 0.3), paint);
    }
  }

  double _sin(double v) {
    v = v % (2 * 3.14159);
    if (v < 0) v += 2 * 3.14159;
    // Bhaskara近似 sin
    final x = v > 3.14159 ? v - 2 * 3.14159 : v;
    return (16 * x * (3.14159 - x)) / (5 * 3.14159 * 3.14159 - 4 * x * (3.14159 - x));
  }

  @override
  bool shouldRepaint(_GrassPainter old) => old.t != t;
}

class _ExpBar extends StatelessWidget {
  const _ExpBar({required this.sx, required this.sy, required this.progress});
  final double sx, sy, progress;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200 * sx, height: 16 * sy,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: ButaColors.ink, border: Border.all(color: ButaColors.ink, width: 2)),
      child: Stack(children: [
        Container(color: const Color(0xFF2A1E3A)),
        FractionallySizedBox(widthFactor: progress, child: Container(color: ButaColors.green)),
      ]),
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.sx, required this.sy});
  final double sx, sy;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => GoRouter.of(context).push('/avatar-detail'),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 200 * sx, height: 48,
          decoration: BoxDecoration(color: ButaColors.yellow, border: Border.all(color: ButaColors.ink, width: 2)),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [SvgPicture.asset('assets/pixel-art/icons/play.svg', width: 14, height: 14), const SizedBox(width: 4), Text('ようすをみる', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.ink))]),
        ),
        Container(width: 194 * sx, height: 5 * sy, color: Colors.black),
      ]),
    );
  }
}

