import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';

class AvatarDetailScreen extends StatelessWidget {
  const AvatarDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ButaColors.background,
      appBar: AppBar(
        backgroundColor: ButaColors.background,
        foregroundColor: ButaColors.paper,
        title: const Text('ぽっちゃり', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            // アバター全身表示
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: ButaColors.bgDeep,
                border: Border.all(color: ButaColors.ink, width: 3),
              ),
              child: Center(child: SvgPicture.asset('assets/pixel-art/icons/pig.svg', width: 80.0, height: 80.0)),
            ),
            const SizedBox(height: 16),

            // ステータス一覧
            PixelBox(
              label: 'STATUS',
              child: Column(
                children: [
                  _StatRow(label: 'HP', value: 0.7, color: ButaColors.red, num: '280/400'),
                  const SizedBox(height: 8),
                  _StatRow(label: 'ATK', value: 0.5, color: ButaColors.yellow, num: '45'),
                  const SizedBox(height: 8),
                  _StatRow(label: 'DEF', value: 0.6, color: ButaColors.blue, num: '52'),
                  const SizedBox(height: 8),
                  _StatRow(label: 'SPD', value: 0.3, color: ButaColors.green, num: '28'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // スキル一覧
            PixelBox(
              label: 'SKILLS',
              child: Column(
                children: const [
                  _SkillRow(name: 'ぶたアタック', type: 'ATK', desc: 'たいあたりする'),
                  Divider(color: ButaColors.paperShadow, height: 12),
                  _SkillRow(name: 'もぐもぐ', type: 'HEAL', desc: 'HPを かいふくする'),
                  Divider(color: ButaColors.paperShadow, height: 12),
                  _SkillRow(name: 'ねむりガス', type: 'DEBUFF', desc: 'あいてを ねむらせる'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 進化履歴
            PixelBox(
              label: 'HISTORY',
              child: Column(
                children: const [
                  _EvolutionRow(from: 'こぶた', to: 'ぽっちゃり', level: 'LV.3'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String num;

  const _StatRow({required this.label, required this.value, required this.color, required this.num});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 36, child: Text(label, style: const TextStyle(fontFamily: kFontPressStart2P, fontSize: 8, color: ButaColors.ink))),
        Expanded(child: PixelBar(value: value, color: color)),
        const SizedBox(width: 8),
        Text(num, style: const TextStyle(fontFamily: kFontPressStart2P, fontSize: 8, color: ButaColors.ink2)),
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  final String name;
  final String type;
  final String desc;

  const _SkillRow({required this.name, required this.type, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PixelTag(text: type, color: type == 'ATK' ? ButaColors.red : type == 'HEAL' ? ButaColors.green : ButaColors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink)),
              Text(desc, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.ink2)),
            ],
          ),
        ),
      ],
    );
  }
}

class _EvolutionRow extends StatelessWidget {
  final String from;
  final String to;
  final String level;

  const _EvolutionRow({required this.from, required this.to, required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(from, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink)),
        const Text(' → ', style: TextStyle(fontSize: 14, color: ButaColors.ink)),
        Text(to, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.pinkDk)),
        const Spacer(),
        PixelTag(text: level, color: ButaColors.yellow),
      ],
    );
  }
}
