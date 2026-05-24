import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/audience_animation.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';

class BattleFightScreen extends StatefulWidget {
  const BattleFightScreen({super.key});
  @override
  State<BattleFightScreen> createState() => _BattleFightScreenState();
}

class _BattleFightScreenState extends State<BattleFightScreen> with TickerProviderStateMixin {
  int _turn = 1;
  double _myHp = 1.0, _oppHp = 1.0;
  String _log = 'バトル かいし！';
  bool _myShake = false, _oppShake = false, _flash = false;
  bool _showDamage = false;
  String _damageText = '';
  bool _damageOnOpp = true;
  final _skills = ['にくあつプレス', 'ねむりこうげき', 'ぼうしょくタックル', 'ぼうぎょ'];
  final _skillColors = [ButaColors.yellow, ButaColors.paper, ButaColors.paper, ButaColors.paper];
  bool _inputLocked = false;
  int _remaining = 20;
  Timer? _timer;
  late final AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _startTurnTimer();
  }

  void _startTurnTimer() {
    _timer?.cancel();
    _remaining = 20;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining = max(0, _remaining - 1));
      if (_remaining <= 0) {
        // 時間切れ→自動でぼうぎょ
        _attack(3);
      }
    });
  }

  @override
  void dispose() { _timer?.cancel(); _shakeCtrl.dispose(); super.dispose(); }

  void _attack(int idx) {
    if (_inputLocked) return;
    _inputLocked = true;
    _timer?.cancel();
    final dmg = idx == 3 ? 0.0 : (0.1 + Random().nextDouble() * 0.1);
    setState(() {
      _log = 'ぽっちゃり の ${_skills[idx]}！';
      if (idx != 3) {
        _oppShake = true;
        _flash = true;
        _oppHp = (_oppHp - dmg).clamp(0.0, 1.0);
        _showDamage = true;
        _damageText = '-${(dmg * 100).round()}';
        _damageOnOpp = true;
      }
    });
    _shakeCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() { _oppShake = false; _flash = false; _showDamage = false; });
      if (_oppHp <= 0) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) context.go('/battle-result', extra: {'win': true});
        });
        return;
      }
      // 相手の反撃
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        final oppDmg = 0.08 + Random().nextDouble() * 0.08;
        setState(() {
          _myShake = true;
          _flash = true;
          _myHp = (_myHp - oppDmg).clamp(0.0, 1.0);
          _log = 'あいて の こうげき！';
          _showDamage = true;
          _damageText = '-${(oppDmg * 100).round()}';
          _damageOnOpp = false;
          _turn++;
        });
        _shakeCtrl.forward(from: 0);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          setState(() { _myShake = false; _flash = false; _showDamage = false; _inputLocked = false; });
          if (_myHp <= 0) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) context.go('/battle-result', extra: {'win': false});
            });
          } else {
            _startTurnTimer();
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.blue,
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-arena.svg', fit: BoxFit.cover)),
        const Positioned.fill(child: CloudAnimation()),
        Positioned.fill(child: AudienceAnimation(sx: sx, sy: sy)),
        // フラッシュ
        if (_flash) Positioned.fill(child: IgnorePointer(child: Container(color: Colors.white.withValues(alpha: 0.3)))),
        // タイマー（1ターン20秒）
        Positioned(top: 14 * sy, left: 55 * sx, width: 280 * sx, child: Text(
          '00:${_remaining.toString().padLeft(2, '0')}', textAlign: TextAlign.center,
          style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 14, color: _remaining <= 5 ? ButaColors.red : ButaColors.yellow),
        )),
        // ターン
        Positioned(top: 36 * sy, left: 55 * sx, width: 280 * sx, child: Text(
          'TURN $_turn/10', textAlign: TextAlign.center,
          style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: ButaColors.gray),
        )),
        // 相手名前+HP
        Positioned(top: 70 * sy, left: 200 * sx, child: Text('まるまる LV.5', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.ink))),
        Positioned(top: 90 * sy, left: 200 * sx, child: _hpBar(170 * sx, 10 * sy, _oppHp)),
        // 相手アバター（揺れ）
        Positioned(top: 130 * sy, left: 230 * sx, child: AnimatedBuilder(
          animation: _shakeCtrl,
          builder: (_, child) {
            final offset = _oppShake ? sin(_shakeCtrl.value * pi * 6) * 6 : 0.0;
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: SizedBox(width: 120 * sx, height: 120 * sy, child: CustomPaint(painter: _FightPigPainter(color: const Color(0xFF5A8ED1)))),
        )),
        // 自分名前+HP
        Positioned(top: 290 * sy, left: 20 * sx, child: Text('ぽっちゃり LV.3', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.ink))),
        Positioned(top: 310 * sy, left: 20 * sx, child: _hpBar(170 * sx, 10 * sy, _myHp)),
        // 自分アバター（揺れ）
        Positioned(top: 350 * sy, left: 40 * sx, child: AnimatedBuilder(
          animation: _shakeCtrl,
          builder: (_, child) {
            final offset = _myShake ? sin(_shakeCtrl.value * pi * 6) * 6 : 0.0;
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: SizedBox(width: 120 * sx, height: 120 * sy, child: CustomPaint(painter: _FightPigPainter(color: const Color(0xFFFF9BB3)))),
        )),
        // ダメージ数字
        if (_showDamage) Positioned(
          top: (_damageOnOpp ? 140 : 360) * sy, left: (_damageOnOpp ? 280 : 90) * sx,
          child: Text(_damageText, style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 18, color: ButaColors.red)),
        ),
        // ログ
        Positioned(top: 490 * sy, left: 14 * sx, child: Container(
          width: 362 * sx, height: 40 * sy,
          decoration: BoxDecoration(color: ButaColors.black),
          alignment: Alignment.center,
          child: Text(_log, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.paper)),
        )),
        // コマンドパネル
        Positioned(top: 545 * sy, left: 14 * sx, child: Container(
          width: 362 * sx, height: 180 * sy,
          decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
          padding: EdgeInsets.all(8 * sx),
          child: GridView.count(
            crossAxisCount: 2, mainAxisSpacing: 8 * sy, crossAxisSpacing: 8 * sx, childAspectRatio: 2.3,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(4, (i) => GestureDetector(
              onTap: _inputLocked ? null : () => _attack(i),
              child: Container(
                decoration: BoxDecoration(color: _skillColors[i], border: Border.all(color: ButaColors.ink, width: 1)),
                alignment: Alignment.center,
                child: Text(_skills[i], style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.ink)),
              ),
            )),
          ),
        )),
      ]),
    );
  }

  Widget _hpBar(double w, double h, double ratio) {
    return Container(width: w, height: h, color: ButaColors.ink, child: Align(
      alignment: Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: w * ratio, height: h,
        color: ratio > 0.3 ? ButaColors.green : ButaColors.red,
      ),
    ));
  }
}

class _FightPigPainter extends CustomPainter {
  _FightPigPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 16;
    void px(double x, double y, double w, double h, Color c) =>
        canvas.drawRect(Rect.fromLTWH(x * u, y * u, w * u, h * u), Paint()..color = c);
    px(4, 5, 8, 7, color);
    px(5, 2, 6, 5, color);
    px(4, 1, 2, 2, color); px(10, 1, 2, 2, color);
    px(6, 4, 1, 1, const Color(0xFF3D2B4D)); px(9, 4, 1, 1, const Color(0xFF3D2B4D));
    px(7, 5, 2, 1, const Color(0xFFE8485A));
    px(5, 12, 2, 2, color); px(9, 12, 2, 2, color);
    px(12, 6, 1, 1, color); px(13, 5, 1, 1, color); px(13, 7, 1, 1, color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
