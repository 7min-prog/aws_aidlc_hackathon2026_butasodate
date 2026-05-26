import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/audience_animation.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/services/api_client.dart';

class BattleResultScreen extends ConsumerStatefulWidget {
  const BattleResultScreen({super.key, this.win = true, this.myName = ''});
  final bool win;
  final String myName;
  @override
  ConsumerState<BattleResultScreen> createState() => _BattleResultScreenState();
}

class _BattleResultScreenState extends ConsumerState<BattleResultScreen> {
  int? _wins;
  int? _losses;

  @override
  void initState() {
    super.initState();
    _fetchRanking();
  }

  Future<void> _fetchRanking() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/rankings/me');
      final body = res.data is String ? {} : res.data as Map<String, dynamic>;
      final r = body['ranking'] as Map<String, dynamic>? ?? {};
      if (mounted) {
        setState(() {
        _wins = (r['wins'] as num?)?.toInt() ?? 0;
        _losses = (r['losses'] as num?)?.toInt() ?? 0;
      });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;
    final win = widget.win;
    final myName = widget.myName;

    return Scaffold(
      backgroundColor: ButaColors.blue,
      body: SafeArea(child: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-arena.svg', fit: BoxFit.cover)),
        const Positioned.fill(child: IgnorePointer(child: CloudAnimation())),
        const Positioned.fill(child: IgnorePointer(child: AudienceAnimation())),
        // 結果
        Positioned(top: 100 * sy, left: 55 * sx, width: 280 * sx, child: Text(
          win ? 'WIN!' : 'LOSE...',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 32, color: ButaColors.yellow),
        )),
        // メッセージ
        Positioned(top: 160 * sy, left: 55 * sx, width: 280 * sx, child: Text(
          win ? '$myName の しょうり！' : '$myName は まけた...',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink),
        )),
        // ポイント
        Positioned(top: 220 * sy, left: 120 * sx, child: Container(
          width: 150 * sx, height: 50 * sy,
          decoration: BoxDecoration(color: win ? ButaColors.green : ButaColors.red),
          alignment: Alignment.center,
          child: Text(win ? '+20 RP' : '-10 RP', style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 16, color: ButaColors.paper)),
        )),
        // 戦績
        Positioned(top: 290 * sy, left: 55 * sx, width: 280 * sx, child: Text(
          _wins != null ? 'せんせき: $_winsしょう $_lossesはい' : '',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray),
        )),
        // もう1回ボタン
        Positioned(top: 380 * sy, left: 55 * sx, child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ButaColors.yellow, foregroundColor: ButaColors.ink,
            minimumSize: Size(280 * sx, 44 * sy),
            shape: RoundedRectangleBorder(side: const BorderSide(color: ButaColors.ink, width: 2), borderRadius: BorderRadius.zero),
          ),
          onPressed: () => context.go('/battle-matching'),
          child: const Text('もう1かい', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14)),
        )),
        // ホームへ戻るボタン
        Positioned(top: 440 * sy, left: 55 * sx, child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ButaColors.paper, foregroundColor: ButaColors.ink,
            minimumSize: Size(280 * sx, 44 * sy),
            shape: RoundedRectangleBorder(side: const BorderSide(color: ButaColors.ink, width: 2), borderRadius: BorderRadius.zero),
          ),
          onPressed: () => context.go('/battle'),
          child: const Text('ホームへ もどる', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14)),
        )),
      ])),
    );
  }
}
