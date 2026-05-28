import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/starry_background.dart';
import 'package:buta_app/features/home/home_screen.dart';

class EvoAnimScreen extends ConsumerStatefulWidget {
  const EvoAnimScreen({super.key, this.oldName = 'こぶた', this.newName = 'ラーメンぶた', this.newLevel = 3});
  final String oldName;
  final String newName;
  final int newLevel;
  @override
  ConsumerState<EvoAnimScreen> createState() => _EvoAnimScreenState();
}

class _EvoAnimScreenState extends ConsumerState<EvoAnimScreen> with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  final AudioPlayer _sePlayer = AudioPlayer();
  // フェーズ: 0-3s 進化前表示+光集中, 3-5s フラッシュ+変身, 5-8s 進化後表示+パーティクル, 8-10s テキスト表示
  double get _phase => _ctrl.value * 10; // 0~10秒

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..forward();
    _sePlayer.play(AssetSource('bgm/evolution.wav'));
  }

  @override
  void dispose() { _sePlayer.dispose(); _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.ink,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _phase;
          return Stack(children: [
            // スタート画面と同じ星空背景
            const Positioned.fill(child: StarryBackground(seed: 77)),
            // 光の集中エフェクト (0-5s)
            if (t < 5) Center(child: _buildGatherLight(t, sx, sy)),
            // フラッシュ (3-5s)
            if (t >= 3 && t < 5) Positioned.fill(child: Container(
              color: Colors.white.withValues(alpha: ((t - 3) / 2).clamp(0, 0.8)),
            )),
            // 進化前のぶた (0-4s)
            if (t < 4) Positioned(
              top: 280 * sy, left: 130 * sx,
              child: Opacity(
                opacity: t < 3 ? 1.0 : (4 - t).clamp(0, 1),
                child: SizedBox(width: 130 * sx, height: 130 * sy, child: Image.asset('assets/pig_default.png', fit: BoxFit.contain)),
              ),
            ),
            // 進化後のぶた (4s~)
            if (t >= 4) Positioned(
              top: 250 * sy, left: (size.width - 160 * sx) / 2,
              child: Opacity(
                opacity: t < 5 ? (t - 4).clamp(0, 1) : 1.0,
                child: Transform.scale(
                  scale: t < 6 ? 0.5 + (t - 4) * 0.25 : 1.0,
                  child: SizedBox(width: 160 * sx, height: 160 * sy, child: Image.asset('assets/pig_ramen.png', fit: BoxFit.contain)),
                ),
              ),
            ),
            // パーティクル (5-10s)
            if (t >= 5) Positioned.fill(child: CustomPaint(painter: _ParticlePainter(t - 5, sx, sy))),
            // EVOLUTION!! (5s~)
            if (t >= 5) Positioned(top: 55 * sy, left: 115 * sx, child: Opacity(
              opacity: ((t - 5) / 0.5).clamp(0, 1),
              child: Container(
                width: 160 * sx, height: 26 * sy,
                decoration: BoxDecoration(color: ButaColors.red),
                alignment: Alignment.center,
                child: Text('EVOLUTION!!', style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 10, color: ButaColors.paper)),
              ),
            )),
            // テキスト (7s~)
            if (t >= 7) Positioned(top: 500 * sy, left: 35 * sx, child: Opacity(
              opacity: ((t - 7) / 1).clamp(0, 1),
              child: Container(
                width: 320 * sx, height: 100 * sy,
                decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
                padding: EdgeInsets.all(12 * sx),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${widget.oldName} は ${widget.newName} に しんかした！', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink)),
                  SizedBox(height: 6 * sy),
                  Text('★ ラーメンパワーを てにいれた！', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: ButaColors.ink)),
                  Text('★ ぜんステータスが アップした！', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: ButaColors.ink)),
                ]),
              ),
            )),
            // ホームへもどるボタン (8s~)
            if (t >= 8) Positioned(bottom: 40 * sy, left: 55 * sx, child: Opacity(
              opacity: ((t - 8) / 1).clamp(0, 1),
              child: GestureDetector(
                onTap: () { ref.invalidate(homeDataProvider); context.go('/home'); },
                child: Container(
                  width: 280 * sx, height: 44 * sy,
                  decoration: BoxDecoration(color: ButaColors.yellow, border: Border.all(color: ButaColors.ink, width: 2)),
                  alignment: Alignment.center,
                  child: Text('ホームへ もどる', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
                ),
              ),
            )),
            // 「〇〇のぶたは…」ぶたの上 (6s~)
            if (t >= 6) Positioned(top: 250 * sy, left: 0, right: 0, child: Opacity(
              opacity: ((t - 6) / 1).clamp(0, 1),
              child: Text(
                '${widget.oldName} の ぶたは…',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper),
              ),
            )),
            // 「〇〇に進化した！」ぶたの下 (7s~)
            if (t >= 7) Positioned(top: 430 * sy, left: 0, right: 0, child: Opacity(
              opacity: ((t - 7) / 1).clamp(0, 1),
              child: Text(
                '${widget.newName} に しんかした！',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper),
              ),
            )),
          ]);
        },
      ),
    );
  }

  Widget _buildGatherLight(double t, double sx, double sy) {
    final intensity = (t / 3).clamp(0.0, 1.0);
    return Container(
      width: (100 + intensity * 200) * sx,
      height: (100 + intensity * 200) * sy,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          ButaColors.yellow.withValues(alpha: 0.5 * intensity),
          ButaColors.paper.withValues(alpha: 0.2 * intensity),
          Colors.transparent,
        ]),
      ),
    );
  }
}

// パーティクル
class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.t, this.sx, this.sy);
  final double t, sx, sy;
  static final _colors = [ButaColors.yellow, ButaColors.pink, ButaColors.green, ButaColors.blue, ButaColors.red];
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(99);
    for (int i = 0; i < 30; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = 40 + rng.nextDouble() * 80;
      final cx = size.width / 2 + cos(angle) * speed * t * sx * 0.3;
      final cy = size.height * 0.47 + sin(angle) * speed * t * sy * 0.3;
      final alpha = (1 - t / 5).clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromLTWH(cx, cy, 6 * sx, 6 * sy),
        Paint()..color = _colors[i % 5].withValues(alpha: alpha),
      );
    }
  }
  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}

// 進化前のぶた（小さめ）
class _OldPigPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 16;
    void px(double x, double y, double w, double h, Color c) =>
        canvas.drawRect(Rect.fromLTWH(x * u, y * u, w * u, h * u), Paint()..color = c);
    px(5, 6, 6, 5, const Color(0xFFFF9BB3));
    px(6, 3, 4, 4, const Color(0xFFFF9BB3));
    px(5, 2, 2, 2, const Color(0xFFFF9BB3)); px(9, 2, 2, 2, const Color(0xFFFF9BB3));
    px(7, 4, 1, 1, const Color(0xFF3D2B4D)); px(8, 4, 1, 1, const Color(0xFF3D2B4D));
    px(7, 5, 2, 1, const Color(0xFFE8485A));
    px(6, 11, 1, 2, const Color(0xFFFF9BB3)); px(9, 11, 1, 2, const Color(0xFFFF9BB3));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 進化後のぶた（大きめ、キラキラ付き）
class _NewPigPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 16;
    void px(double x, double y, double w, double h, Color c) =>
        canvas.drawRect(Rect.fromLTWH(x * u, y * u, w * u, h * u), Paint()..color = c);
    px(4, 5, 8, 7, const Color(0xFFFF9BB3));
    px(5, 2, 6, 5, const Color(0xFFFF9BB3));
    px(4, 1, 2, 2, const Color(0xFFFF9BB3)); px(10, 1, 2, 2, const Color(0xFFFF9BB3));
    px(6, 4, 1, 1, const Color(0xFF3D2B4D)); px(9, 4, 1, 1, const Color(0xFF3D2B4D));
    px(6, 3, 1, 1, const Color(0xFF3D2B4D)); px(9, 3, 1, 1, const Color(0xFF3D2B4D)); // happy eyes
    px(7, 5, 2, 1, const Color(0xFFE8485A));
    px(6, 6, 4, 1, const Color(0xFF3D2B4D)); // smile
    px(5, 12, 2, 2, const Color(0xFFFF9BB3)); px(9, 12, 2, 2, const Color(0xFFFF9BB3));
    px(12, 6, 1, 1, const Color(0xFFFF9BB3)); px(13, 5, 1, 1, const Color(0xFFFF9BB3)); px(13, 7, 1, 1, const Color(0xFFFF9BB3));
    // sparkles
    px(2, 2, 1, 1, const Color(0xFFF6C453)); px(13, 1, 1, 1, const Color(0xFFF6C453));
    px(1, 3, 1, 1, const Color(0xFFF6C453)); px(14, 3, 1, 1, const Color(0xFFF6C453));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
