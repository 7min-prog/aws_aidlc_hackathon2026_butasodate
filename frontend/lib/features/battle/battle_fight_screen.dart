import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/audience_animation.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/services/battle_ws_service.dart';
import 'package:buta_app/shared/services/api_client.dart';

class BattleFightScreen extends ConsumerStatefulWidget {
  const BattleFightScreen({super.key, this.matchData});
  final Map<String, dynamic>? matchData;
  @override
  ConsumerState<BattleFightScreen> createState() => _BattleFightScreenState();
}

class _BattleFightScreenState extends ConsumerState<BattleFightScreen> with TickerProviderStateMixin {
  int _turn = 1;
  double _myHp = 1.0, _oppHp = 1.0;
  String _log = 'じゅんび しています...';
  bool _myShake = false, _oppShake = false, _flash = false;
  bool _showDamage = false;
  String _damageText = '';
  bool _damageOnOpp = true;
  List<Map<String, String>> _skills = [
    {'id': 'skill-basic-attack', 'name': 'こうげき'},
    {'id': 'skill-basic-attack', 'name': 'こうげき'},
    {'id': 'skill-basic-attack', 'name': 'こうげき'},
    {'id': 'defend', 'name': 'ぼうぎょ'},
  ];
  final _skillColors = [ButaColors.yellow, ButaColors.paper, ButaColors.paper, ButaColors.paper];
  bool _inputLocked = true;
  int _remaining = 20;
  Timer? _timer;
  late final AnimationController _shakeCtrl;
  String? _matchId;
  StreamSubscription? _sub;
  String _myUserId = '';
  String _myName = 'じぶん';
  String _oppName = 'あいて';
  bool _isPlayer1 = true;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _matchId = widget.matchData?['matchId'] ?? BattleWsService.instance.matchId;
    // matchDataからplayer判定
    final md = widget.matchData ?? {};
    _sub = BattleWsService.instance.messages.listen(_onWsMessage);
    _loadSkillsAndReady(md);
  }

  Future<void> _loadSkillsAndReady(Map<String, dynamic> md) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('id_token') ?? prefs.getString('access_token') ?? '';
    // JWTからuserId取得
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        _myUserId = (jsonDecode(payload) as Map<String, dynamic>)['sub'] ?? '';
      }
    } catch (_) {}
    // player1/2判定
    _isPlayer1 = md['player1Id'] == _myUserId || md['player2Id'] != _myUserId;

    // アバターAPIからスキルと名前取得
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/avatar');
      final data = res.data as Map<String, dynamic>;
      _myName = (data['name'] as String?) ?? 'じぶん';
      final skillIds = (data['skillIds'] as List?)?.cast<String>() ?? [];
      final skills = (data['skills'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      if (skills.isNotEmpty) {
        _skills = skills.take(3).map((s) => {'id': s['skillId'] as String, 'name': s['name'] as String}).toList();
        _skills.add({'id': 'defend', 'name': 'ぼうぎょ'});
      } else if (skillIds.isNotEmpty) {
        _skills = skillIds.take(3).map((id) => {'id': id, 'name': id}).toList();
        _skills.add({'id': 'defend', 'name': 'ぼうぎょ'});
      }
    } catch (_) {}

    if (mounted) setState(() {});

    // setReady送信
    BattleWsService.instance.send({
      'action': 'setReady',
      'data': {'matchId': _matchId, 'skills': _skills.map((s) => s['id']).toList()},
    });
  }

  void _onWsMessage(Map<String, dynamic> msg) {
    if (!mounted) return;
    final type = msg['type'];
    final data = msg['data'] as Map<String, dynamic>? ?? {};

    switch (type) {
      case 'battleStart':
        if (data['opponentName'] != null) _oppName = data['opponentName'] as String;
        setState(() { _log = 'バトル かいし！'; _inputLocked = false; });
        _startTurnTimer();
        break;
      case 'turnResult':
        _applyTurnResult(data);
        break;
      case 'battleEnd':
        _timer?.cancel();
        final winnerId = data['winnerId'] as String?;
        final win = winnerId == _myUserId;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) context.go('/battle-result', extra: {'win': win, 'myName': _myName, 'oppName': _oppName, 'data': data});
        });
        break;
      case 'opponentDisconnected':
        setState(() => _log = 'あいてが せつだん しました');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.go('/battle-result', extra: {'win': true});
        });
        break;
    }
  }

  void _applyTurnResult(Map<String, dynamic> data) {
    final state = data['battleState'] as Map<String, dynamic>? ?? {};
    final p1 = state['player1'] as Map<String, dynamic>? ?? {};
    final p2 = state['player2'] as Map<String, dynamic>? ?? {};
    final myData = _isPlayer1 ? p1 : p2;
    final oppData = _isPlayer1 ? p2 : p1;
    final myHpNew = ((myData['currentHp'] ?? myData['hp']) as num?)?.toDouble() ?? 300;
    final oppHpNew = ((oppData['currentHp'] ?? oppData['hp']) as num?)?.toDouble() ?? 300;
    final maxHpMy = ((myData['maxHp'] ?? myData['hp']) as num?)?.toDouble() ?? 300;
    final maxHpOpp = ((oppData['maxHp'] ?? oppData['hp']) as num?)?.toDouble() ?? 300;

    // 演出: ダメージ判定
    final oldMyHp = _myHp;
    final oldOppHp = _oppHp;
    final newMyHp = maxHpMy > 0 ? (myHpNew / maxHpMy).clamp(0.0, 1.0) : 1.0;
    final newOppHp = maxHpOpp > 0 ? (oppHpNew / maxHpOpp).clamp(0.0, 1.0) : 1.0;

    // 相手にダメージが入った場合
    if (newOppHp < oldOppHp) {
      final dmg = ((oldOppHp - newOppHp) * maxHpOpp).round();
      setState(() {
        _oppShake = true;
        _flash = true;
        _showDamage = true;
        _damageText = '-$dmg';
        _damageOnOpp = true;
      });
      _shakeCtrl.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() { _oppShake = false; _flash = false; _showDamage = false; });
        // 自分にダメージが入った場合
        if (newMyHp < oldMyHp) {
          final myDmg = ((oldMyHp - newMyHp) * maxHpMy).round();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            setState(() { _myShake = true; _flash = true; _showDamage = true; _damageText = '-$myDmg'; _damageOnOpp = false; });
            _shakeCtrl.forward(from: 0);
            Future.delayed(const Duration(milliseconds: 400), () {
              if (!mounted) return;
              setState(() { _myShake = false; _flash = false; _showDamage = false; });
              _finishTurn(newMyHp, newOppHp, data);
            });
          });
        } else {
          _finishTurn(newMyHp, newOppHp, data);
        }
      });
    } else if (newMyHp < oldMyHp) {
      // 自分だけダメージ
      final myDmg = ((oldMyHp - newMyHp) * maxHpMy).round();
      setState(() { _myShake = true; _flash = true; _showDamage = true; _damageText = '-$myDmg'; _damageOnOpp = false; });
      _shakeCtrl.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() { _myShake = false; _flash = false; _showDamage = false; });
        _finishTurn(newMyHp, newOppHp, data);
      });
    } else {
      // ダメージなし（両方ぼうぎょ等）
      _finishTurn(newMyHp, newOppHp, data);
    }
  }

  void _finishTurn(double newMyHp, double newOppHp, Map<String, dynamic> data) {
    setState(() {
      _myHp = newMyHp;
      _oppHp = newOppHp;
      _turn++;
      _log = data['description'] as String? ?? 'ターン $_turn';
      _inputLocked = false;
    });
    _startTurnTimer();
  }

  void _startTurnTimer() {
    _timer?.cancel();
    _remaining = 20;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining = max(0, _remaining - 1));
      if (_remaining <= 0) _selectAction(3);
    });
  }

  void _selectAction(int idx) {
    if (_inputLocked) return;
    _inputLocked = true;
    _timer?.cancel();
    final skill = _skills[idx];
    setState(() => _log = '${skill['name']} を えらんだ！\nあいてを まっています...');
    BattleWsService.instance.send({
      'action': 'selectAction',
      'data': {'matchId': _matchId, 'action': {'type': skill['id'] == 'defend' ? 'defend' : 'skill', 'skillId': skill['id']}},
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeCtrl.dispose();
    _sub?.cancel();
    BattleWsService.instance.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390;
    final fieldHeight = size.height - 270;
    final sy = (fieldHeight / 500).clamp(0.0, 1.5);

    return Scaffold(
      backgroundColor: ButaColors.blue,
      body: SafeArea(child: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-arena.svg', fit: BoxFit.cover)),
        const Positioned.fill(child: IgnorePointer(child: CloudAnimation())),
        const Positioned.fill(child: IgnorePointer(child: AudienceAnimation())),
        if (_flash) Positioned.fill(child: IgnorePointer(child: Container(color: Colors.white.withValues(alpha: 0.3)))),
        // タイマー
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
        Positioned(top: 70 * sy, left: 200 * sx, child: Text(_oppName, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.ink))),
        Positioned(top: 90 * sy, left: 200 * sx, child: _hpBar(170 * sx, 10 * sy, _oppHp)),
        // 相手アバター
        Positioned(top: 110 * sy, left: 240 * sx, child: AnimatedBuilder(
          animation: _shakeCtrl,
          builder: (_, child) {
            final offset = _oppShake ? sin(_shakeCtrl.value * pi * 6) * 6 : 0.0;
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: SizedBox(width: 90 * sx, height: 90 * sx, child: CustomPaint(painter: _FightPigPainter(color: const Color(0xFF5A8ED1)))),
        )),
        // 自分名前+HP
        Positioned(top: 220 * sy, left: 20 * sx, child: Text(_myName, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.ink))),
        Positioned(top: 240 * sy, left: 20 * sx, child: _hpBar(170 * sx, 10 * sy, _myHp)),
        // 自分アバター
        Positioned(top: 260 * sy, left: 40 * sx, child: AnimatedBuilder(
          animation: _shakeCtrl,
          builder: (_, child) {
            final offset = _myShake ? sin(_shakeCtrl.value * pi * 6) * 6 : 0.0;
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: SizedBox(width: 90 * sx, height: 90 * sx, child: CustomPaint(painter: _FightPigPainter(color: const Color(0xFFFF9BB3)))),
        )),
        // ダメージ数字
        if (_showDamage) Positioned(
          top: (_damageOnOpp ? 120 : 270) * sy, left: (_damageOnOpp ? 280 : 90) * sx,
          child: Text(_damageText, style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 18, color: ButaColors.red)),
        ),
        // ログ
        Positioned(bottom: 230, left: 14 * sx, right: 14 * sx, child: Container(
          height: 36,
          decoration: BoxDecoration(color: ButaColors.black),
          alignment: Alignment.center,
          child: Text(_log, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.paper), textAlign: TextAlign.center),
        )),
        // コマンドパネル
        Positioned(bottom: 0, left: 14 * sx, right: 14 * sx, height: 220, child: Container(
          decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            Expanded(child: Row(children: [
              for (int i = 0; i < 2; i++) Expanded(child: GestureDetector(
                onTap: _inputLocked ? null : () => _selectAction(i),
                child: Container(
                  margin: EdgeInsets.only(right: i == 0 ? 4 : 0, left: i == 1 ? 4 : 0),
                  decoration: BoxDecoration(color: _inputLocked ? ButaColors.gray : _skillColors[i], border: Border.all(color: ButaColors.ink, width: 1)),
                  alignment: Alignment.center,
                  child: Text(_skills[i]['name'] ?? '', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.ink)),
                ),
              )),
            ])),
            const SizedBox(height: 8),
            Expanded(child: Row(children: [
              for (int i = 2; i < 4; i++) Expanded(child: GestureDetector(
                onTap: _inputLocked ? null : () => _selectAction(i),
                child: Container(
                  margin: EdgeInsets.only(right: i == 2 ? 4 : 0, left: i == 3 ? 4 : 0),
                  decoration: BoxDecoration(color: _inputLocked ? ButaColors.gray : _skillColors[i], border: Border.all(color: ButaColors.ink, width: 1)),
                  alignment: Alignment.center,
                  child: Text(_skills[i]['name'] ?? '', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.ink)),
                ),
              )),
            ])),
          ]),
        )),
      ])),
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
