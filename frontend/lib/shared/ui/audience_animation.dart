import 'dart:math';
import 'package:flutter/material.dart';
import 'package:buta_app/shared/theme.dart';

/// bg-arenaの観客席部分（カラフルなドットが小さく揺れる）
class AudienceAnimation extends StatefulWidget {
  const AudienceAnimation({super.key, required this.sx, required this.sy});
  final double sx, sy;
  @override
  State<AudienceAnimation> createState() => _AudienceAnimationState();
}

class _AudienceAnimationState extends State<AudienceAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: Size(390 * widget.sx, 740 * widget.sy),
        painter: _AudiencePainter(_ctrl.value, widget.sx, widget.sy),
      ),
    );
  }
}

class _AudiencePainter extends CustomPainter {
  _AudiencePainter(this.t, this.sx, this.sy);
  final double t, sx, sy;

  // [x, y, color, phaseOffset]
  static final _dots = <List<dynamic>>[
    [50, 400, ButaColors.pink, 0.0], [70, 398, ButaColors.green, 0.8], [90, 402, ButaColors.yellow, 1.6],
    [120, 400, ButaColors.blue, 2.4], [140, 396, ButaColors.red, 3.2], [170, 400, ButaColors.pink, 4.0],
    [200, 398, ButaColors.green, 4.8], [230, 402, ButaColors.yellow, 5.6], [260, 398, ButaColors.blue, 0.4],
    [290, 400, ButaColors.red, 1.2], [320, 396, ButaColors.pink, 2.0], [340, 400, ButaColors.green, 2.8],
    [60, 430, ButaColors.yellow, 3.6], [90, 432, ButaColors.blue, 4.4], [120, 428, ButaColors.pink, 5.2],
    [150, 432, ButaColors.red, 0.6], [180, 430, ButaColors.green, 1.4], [210, 428, ButaColors.yellow, 2.2],
    [240, 432, ButaColors.blue, 3.0], [270, 430, ButaColors.pink, 3.8], [300, 428, ButaColors.red, 4.6],
    [330, 432, ButaColors.green, 5.4],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in _dots) {
      final x = (d[0] as int).toDouble() * sx;
      final baseY = (d[1] as int).toDouble() * sy;
      final phase = d[3] as double;
      // 小さくゆっくり上下（最大2px）
      final bounce = sin(t * 2 * pi + phase) * 2 * sy;
      canvas.drawRect(
        Rect.fromLTWH(x, baseY + bounce, 8 * sx, 8 * sy),
        Paint()..color = d[2] as Color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AudiencePainter old) => true;
}
