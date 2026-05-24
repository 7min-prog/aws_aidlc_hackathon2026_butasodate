import 'package:flutter/material.dart';

/// 空を流れる雲のアニメーション（ピクセルアート風）
/// bg-barn, bg-meadow など青空背景の画面で使用
class CloudAnimation extends StatefulWidget {
  const CloudAnimation({super.key});
  @override
  State<CloudAnimation> createState() => _CloudAnimationState();
}

class _CloudAnimationState extends State<CloudAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _ctrl, builder: (_, __) {
      return CustomPaint(painter: _CloudPainter(_ctrl.value), size: Size.infinite);
    });
  }
}

class _CloudPainter extends CustomPainter {
  final double t;
  _CloudPainter(this.t);

  // 雲の定義: [startX, y, width, height, speed]
  static const _clouds = [
    [0.1, 0.06, 40.0, 12.0, 1.0],
    [0.4, 0.10, 55.0, 14.0, 0.7],
    [0.75, 0.04, 35.0, 10.0, 1.2],
    [0.2, 0.15, 45.0, 12.0, 0.5],
    [0.6, 0.12, 30.0, 10.0, 0.9],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x60FFFFFF);

    for (final cloud in _clouds) {
      final baseX = cloud[0] as double;
      final yRatio = cloud[1] as double;
      final w = cloud[2] as double;
      final h = cloud[3] as double;
      final speed = cloud[4] as double;

      // 右から左へゆっくり流れる、画面外に出たら右から再登場
      final x = ((baseX + t * speed * 0.3) % 1.3 - 0.15) * size.width;
      final y = yRatio * size.height;

      // ピクセルアート風の雲（角丸なし、段差で形を作る）
      final sx = size.width / 390;
      final sy = size.height / 740;
      final cw = w * sx;
      final ch = h * sy;

      // 中段（メイン）
      canvas.drawRect(Rect.fromLTWH(x, y + ch * 0.3, cw, ch * 0.4), paint);
      // 上段（少し狭い）
      canvas.drawRect(Rect.fromLTWH(x + cw * 0.15, y, cw * 0.7, ch * 0.35), paint);
      // 下段（少し狭い）
      canvas.drawRect(Rect.fromLTWH(x + cw * 0.1, y + ch * 0.65, cw * 0.8, ch * 0.35), paint);
    }
  }

  @override
  bool shouldRepaint(_CloudPainter old) => old.t != t;
}
