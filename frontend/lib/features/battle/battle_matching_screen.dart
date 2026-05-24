import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/audience_animation.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';

class BattleMatchingScreen extends StatefulWidget {
  const BattleMatchingScreen({super.key});
  @override
  State<BattleMatchingScreen> createState() => _BattleMatchingScreenState();
}

class _BattleMatchingScreenState extends State<BattleMatchingScreen> {
  int _remaining = 30;
  late final Timer _timer;
  int _dotPhase = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _remaining--;
        _dotPhase = (_dotPhase + 1) % 4;
      });
      if (_remaining <= 25) {
        // デモ: 25秒残りでマッチ成立
        _timer.cancel();
        context.go('/battle-ready');
      } else if (_remaining <= 0) {
        _timer.cancel();
        context.go('/battle'); // タイムアウト
      }
    });
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;
    final mm = (_remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (_remaining % 60).toString().padLeft(2, '0');
    final dots = List.generate(3, (i) => i < _dotPhase ? '●' : '○').join(' ');

    return Scaffold(
      backgroundColor: ButaColors.blue,
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-arena.svg', fit: BoxFit.cover)),
        const Positioned.fill(child: CloudAnimation()),
        Positioned.fill(child: AudienceAnimation(sx: sx, sy: sy)),
        Positioned(top: 200 * sy, left: 55 * sx, width: 280 * sx, child: Text(
          'たいせんあいてを\nさがしています...',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink),
        )),
        Positioned(top: 280 * sy, left: 55 * sx, width: 280 * sx, child: Text(
          dots, textAlign: TextAlign.center,
          style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 20, color: ButaColors.pink),
        )),
        Positioned(top: 340 * sy, left: 145 * sx, child: Container(
          width: 100 * sx, height: 40 * sy,
          decoration: BoxDecoration(color: ButaColors.black),
          alignment: Alignment.center,
          child: Text('$mm:$ss', style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 14, color: ButaColors.yellow)),
        )),
        Positioned(top: 440 * sy, left: 95 * sx, child: GestureDetector(
          onTap: () => context.go('/battle'),
          child: Container(
            width: 200 * sx, height: 40 * sy,
            decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
            alignment: Alignment.center,
            child: Text('B キャンセル', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
          ),
        )),
      ]),
    );
  }
}
