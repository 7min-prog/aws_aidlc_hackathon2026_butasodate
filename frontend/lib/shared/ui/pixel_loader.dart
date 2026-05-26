import 'package:flutter/material.dart';
import 'package:buta_app/shared/theme.dart';

class PixelLoader extends StatefulWidget {
  const PixelLoader({super.key});
  @override
  State<PixelLoader> createState() => _PixelLoaderState();
}

class _PixelLoaderState extends State<PixelLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final frame = (_ctrl.value * 4).floor() % 4;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (i) => Container(
            width: 10, height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            color: i == frame ? ButaColors.yellow : ButaColors.paper,
          )),
        );
      },
    );
  }
}
