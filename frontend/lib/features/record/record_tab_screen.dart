import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/ui/grass_animation.dart';
import 'package:buta_app/features/home/home_screen.dart';

final recordsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    await ref.watch(authStateProvider.future);
    final api = ref.read(apiClientProvider);
    final res = await api.get('/activities');
    return {'records': res.data['records'] as List? ?? [], 'summary': res.data['summary']};
  } catch (_) {
    return {'records': <dynamic>[], 'summary': {'todayPoints': 0}};
  }
});

class RecordTabScreen extends ConsumerStatefulWidget {
  const RecordTabScreen({super.key});
  @override
  ConsumerState<RecordTabScreen> createState() => _RecordTabScreenState();
}

class _RecordTabScreenState extends ConsumerState<RecordTabScreen> {
  int _segIndex = 0;
  static const _segLabels = ['きょう', 'しゅう', 'つき'];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;
    final data = ref.watch(recordsProvider);

    return Scaffold(
      backgroundColor: ButaColors.blue,
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover)),
        const Positioned.fill(child: CloudAnimation()),
        Positioned.fill(child: GrassAnimation(sx: sx, sy: sy)),
        // ヘッダー
        Positioned(top: 0, left: 0, right: 0, height: 48 * sy, child: Container(color: ButaColors.ink, alignment: Alignment.center, child: Text('きろく', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.paper)))),
        // セグメント
        Positioned(top: 60 * sy, left: 55 * sx, child: Container(
          width: 280 * sx, height: 32 * sy,
          color: const Color(0xFFE8D9B0),
          padding: EdgeInsets.all(2 * sx),
          child: Row(children: [
            for (int i = 0; i < 3; i++) Expanded(child: GestureDetector(
              onTap: () => setState(() => _segIndex = i),
              child: Container(
                color: _segIndex == i ? ButaColors.paper : Colors.transparent,
                alignment: Alignment.center,
                child: Text(_segLabels[i], style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: _segIndex == i ? ButaColors.ink : ButaColors.gray)),
              ),
            )),
          ]),
        )),
        // 記録カード
        Positioned(top: 110 * sy, left: 14 * sx, child: data.when(
          data: (d) {
            final records = d['records'] as List;
            final todayPts = d['summary']?['todayPoints'] ?? 0;
            if (records.isEmpty) {
              return Column(children: [
                Container(
                  width: 362 * sx, height: 60 * sy,
                  decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
                  alignment: Alignment.center,
                  child: Text('まだ きろくが ないよ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.gray)),
                ),
              ]);
            }
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final r in records.take(3)) _buildCard(r, sx, sy),
              SizedBox(height: 10 * sy),
              SizedBox(width: 362 * sx, child: Text('きょうの合計: +${todayPts}pt', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: const Color(0xFFC46A85)))),
            ]);
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        )),
        // 週間チャート
        Positioned(top: 370 * sy, left: 14 * sx, child: Container(
          width: 362 * sx, height: 220 * sy,
          padding: EdgeInsets.all(10 * sx),
          decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
          child: Column(children: [
            Text(_segIndex == 0 ? 'きょうの きろく' : _segIndex == 1 ? 'しゅうかん グラフ' : 'げっかん グラフ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.ink)),
            SizedBox(height: 8 * sy),
            Expanded(child: _WeeklyChart(sx: sx, sy: sy, segIndex: _segIndex)),
          ]),
        )),
        // タブバー
        // きろくするボタン
        Positioned(bottom: 64 * sy, left: 55 * sx, child: GestureDetector(
          onTap: () => context.push('/record-category'),
          child: Container(
            width: 280 * sx, height: 44 * sy,
            decoration: BoxDecoration(color: ButaColors.yellow, border: Border.all(color: ButaColors.ink, width: 2)),
            alignment: Alignment.center,
            child: Text('▶ きろくする', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.ink)),
          ),
        )),
        Positioned(bottom: 0, left: 0, right: 0, height: 56 * sy, child: PixelTabBar(sx: sx, sy: sy, activeIndex: 1)),
      ]),
    );
  }

  Widget _buildCard(dynamic record, double sx, double sy) {
    final catId = record['categoryId'] as String? ?? '';
    final pts = record['points'] ?? 0;
    final name = const {'food-ramen': '深夜ラーメン', 'food-snack': '間食した', 'food-binge': '暴飲暴食', 'life-oversleep': '二度寝した', 'life-skip-exercise': '運動サボり', 'life-late-night': '夜更かし', 'life-gaming': 'ゲーム三昧', 'life-nap': '昼寝しすぎ'}[catId] ?? catId;
    return GestureDetector(
      onTap: () => context.push('/record-detail', extra: {...record as Map<String, dynamic>, 'categoryName': name}),
      child: Container(
        width: 362 * sx, height: 60 * sy, margin: EdgeInsets.only(bottom: 4 * sy),
        padding: EdgeInsets.symmetric(horizontal: 14 * sx),
        decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
        child: Row(children: [
          Text(name, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
          const Spacer(),
          Text('+${pts}pt', style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 12, color: const Color(0xFFC46A85))),
        ]),
      ),
    );
  }
}


class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.sx, required this.sy, required this.segIndex});
  final double sx, sy;
  final int segIndex;
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChartPainter(sx, sy, segIndex),
      size: Size(362 * sx, 260 * sy),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final double sx, sy;
  final int segIndex;
  _ChartPainter(this.sx, this.sy, this.segIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final chartLeft = 30 * sx;
    final chartTop = 20 * sy;
    final chartBottom = 180 * sy;
    final chartHeight = chartBottom - chartTop;
    final barWidth = 30 * sx;
    final barSpacing = 44 * sx;

    // セグメントに応じたデータ
    final List<int> values;
    final List<String> labels;
    final int maxVal;
    if (segIndex == 0) {
      values = [50, 35, 40];
      labels = ['ラーメン', 'よふかし', 'サボり'];
      maxVal = 100;
    } else if (segIndex == 1) {
      values = [60, 100, 40, 160, 80, 180, 120];
      labels = ['5/18', '5/19', '5/20', '5/21', '5/22', '5/23', '5/24'];
      maxVal = 200;
    } else {
      values = [400, 520, 380, 600];
      labels = ['1週', '2週', '3週', '4週'];
      maxVal = 700;
    }

    final colors = [const Color(0xFFB8A99A), const Color(0xFFF6C453), const Color(0xFF6CB979), const Color(0xFF6CB979), const Color(0xFFF6C453), const Color(0xFF6CB979), const Color(0xFFB8A99A)];
    final total = values.reduce((a, b) => a + b);
    final spacing = values.length <= 4 ? 70.0 * sx : barSpacing;

    // Y軸メモリ
    for (int i = 0; i <= 4; i++) {
      final gy = chartTop + i * (chartHeight / 4);
      paint.color = const Color(0xFFB8A99A);
      canvas.drawRect(Rect.fromLTWH(chartLeft, gy, 300 * sx, 1), paint);
      final label = (maxVal - (maxVal / 4 * i)).round().toString();
      _drawText(canvas, label, 2 * sx, gy - 6 * sy, 9, const Color(0xFFB8A99A));
    }

    // 棒グラフ
    for (int i = 0; i < values.length; i++) {
      final barH = (values[i] / maxVal) * chartHeight;
      final barX = chartLeft + i * spacing;
      final barY = chartBottom - barH;
      paint.color = colors[i % colors.length];
      canvas.drawRect(Rect.fromLTWH(barX, barY, barWidth, barH), paint);
      if (values[i] > 0) {
        _drawText(canvas, '${values[i]}', barX + 4 * sx, barY - 14 * sy, 9, const Color(0xFF1A1228));
      }
    }

    // X軸ラベル
    for (int i = 0; i < labels.length; i++) {
      _drawText(canvas, labels[i], chartLeft + i * spacing, 188 * sy, 9, const Color(0xFF1A1228));
    }

    // 合計
    _drawText(canvas, '合計: +${total}pt', 130 * sx, 200 * sy, 11, const Color(0xFFC46A85));
  }

  void _drawText(Canvas canvas, String text, double x, double y, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontFamily: 'DotGothic16', fontSize: fontSize * sx, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
