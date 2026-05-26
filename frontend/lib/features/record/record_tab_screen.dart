import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/app_config.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/ui/grass_animation.dart';
import 'package:buta_app/shared/ui/pixel_tab_bar.dart';

final recordsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('id_token') ?? '';
    final dio = Dio(BaseOptions(headers: {'Authorization': token}));
    final res = await dio.get('${AppConfig.recordingApiBase}/activities');
    debugPrint('activities response: ${res.data}');
    final data = res.data is String ? <String, dynamic>{} : res.data as Map<String, dynamic>;
    return {'records': (data['items'] ?? data['records'] ?? []) as List, 'summary': data['summary']};
  } catch (e) {
    debugPrint('activities error: $e');
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
    final sx = size.width / 390;
    final data = ref.watch(recordsProvider);

    return Scaffold(
      backgroundColor: ButaColors.blue,
      appBar: const PixelAppBar(title: 'きろく'),
      bottomNavigationBar: SafeArea(child: PixelTabBar(sx: sx, sy: size.height / 740, activeIndex: 1)),
      body: LayoutBuilder(builder: (context, constraints) {
        final sy = constraints.maxHeight / 636;
        return Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover)),
        const Positioned.fill(child: CloudAnimation()),
        Positioned.fill(child: GrassAnimation(sx: sx, sy: sy)),
        // ヘッダー
        // セグメント
        Positioned(top: 12 * sy, left: 55 * sx, child: Container(
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
        Positioned(top: 62 * sy, left: 14 * sx, right: 14 * sx, bottom: 75, child: data.when(
          data: (d) {
            final allRecords = d['records'] as List;
            final todayPts = d['summary']?['todayPoints'] ?? 0;
            final now = DateTime.now();
            final records = allRecords.where((r) {
              final date = (DateTime.tryParse(r['recordedAt'] ?? '') ?? now).toLocal();
              if (_segIndex == 0) return date.year == now.year && date.month == now.month && date.day == now.day;
              if (_segIndex == 1) return now.difference(date).inDays < 7;
              return now.difference(date).inDays < 30;
            }).toList();
            return Column(children: [
              SizedBox(height: 180 * sy, child: records.isEmpty
                ? Container(
                    decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
                    alignment: Alignment.center,
                    child: Text('まだ きろくが ないよ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.gray)),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: records.length,
                    itemBuilder: (context, i) => _buildCard(records[i], sx, sy),
                  ),
              ),
              SizedBox(height: 8 * sy),
              Text('合計: +${todayPts}pt', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: const Color(0xFFC46A85))),
              SizedBox(height: 8 * sy),
              SizedBox(height: 260 * sy, child: Container(
                padding: EdgeInsets.all(10 * sx),
                decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
                child: records.isEmpty
                  ? Center(child: Text('データなし', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray)))
                  : Column(children: [
                      Text(_segIndex == 0 ? 'きょうの きろく' : _segIndex == 1 ? 'しゅうかん グラフ' : 'げっかん グラフ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.ink)),
                      SizedBox(height: 8 * sy),
                      Expanded(child: SizedBox.expand(child: CustomPaint(painter: _ChartPainter(sx, sy, _segIndex, records)))),
                    ]),
              )),
            ]);
          },
          loading: () => Container(width: 362 * sx, height: 60 * sy, decoration: BoxDecoration(color: ButaColors.paper.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
          error: (_, __) => const SizedBox.shrink(),
        )),
        // きろくするボタン
        Positioned(bottom: 20, left: 95 * sx, child: GestureDetector(
          onTap: () => context.push('/record-category'),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 200 * sx, height: 48,
              decoration: BoxDecoration(color: ButaColors.yellow, border: Border.all(color: ButaColors.ink, width: 2)),
              alignment: Alignment.center,
              child: Row(mainAxisSize: MainAxisSize.min, children: [SvgPicture.asset('assets/pixel-art/icons/play.svg', width: 14, height: 14), const SizedBox(width: 4), Text('きろくする', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.ink))]),
            ),
            Container(width: 194 * sx, height: 5 * sy, color: Colors.black),
          ]),
        )),
      ]);
      }),
    );
  }

  Widget _buildCard(dynamic record, double sx, double sy) {
    final catId = record['categoryId'] as String? ?? '';
    final pts = record['points'] ?? 0;
    final name = const {
      'food_late_ramen': 'しんやラーメン', 'food_snack': 'かんしょく', 'food_binge': 'ぼういんぼうしょく',
      'food_junkfood': 'ジャンクフード', 'life_stay_up': 'よふかし', 'life_oversleep': 'にどね',
      'life_skip_exercise': 'うんどうサボり', 'life_binge_watch': 'いっきみ',
    }[catId] ?? catId;
    final date = DateTime.tryParse(record['recordedAt'] ?? '') ?? DateTime.now();
    final dateStr = '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: () => context.push('/record-detail', extra: {...record as Map<String, dynamic>, 'categoryName': name}),
      child: Container(
        width: 362 * sx, height: 60 * sy, margin: EdgeInsets.only(bottom: 4 * sy),
        padding: EdgeInsets.symmetric(horizontal: 14 * sx),
        decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(name, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink)),
            Text(dateStr, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: ButaColors.gray)),
          ]),
          const Spacer(),
          Text('+${pts}pt', style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 11, color: const Color(0xFFC46A85))),
        ]),
      ),
    );
  }
}


class _ChartPainter extends CustomPainter {
  final double sx, sy;
  final int segIndex;
  final List<dynamic> records;
  _ChartPainter(this.sx, this.sy, this.segIndex, this.records);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final chartLeft = 30.0;
    final chartTop = 10.0;
    final chartBottom = size.height - 40;
    final chartHeight = chartBottom - chartTop;

    // 実データから集計
    final List<int> values;
    final List<String> labels;
    final now = DateTime.now();

    if (segIndex == 0) {
      // きょう: カテゴリ別
      const catNames = {
        'food_late_ramen': 'ラーメン', 'food_snack': 'かんしょく', 'food_binge': 'ぼうしょく',
        'food_junkfood': 'ジャンク', 'life_stay_up': 'よふかし', 'life_oversleep': 'にどね',
        'life_skip_exercise': 'サボり', 'life_binge_watch': 'いっきみ',
      };
      final Map<String, int> catPts = {};
      for (final r in records) {
        final cat = r['categoryId'] as String? ?? '?';
        final short = catNames[cat] ?? cat;
        catPts[short] = (catPts[short] ?? 0) + ((r['points'] as num?)?.toInt() ?? 0);
      }
      if (catPts.isEmpty) { values = [0]; labels = ['-']; } else {
        values = catPts.values.toList();
        labels = catPts.keys.toList();
      }
    } else if (segIndex == 1) {
      // しゅう: 日別
      values = List.filled(7, 0);
      labels = List.generate(7, (i) { final d = now.subtract(Duration(days: 6 - i)); return '${d.month}/${d.day}'; });
      for (final r in records) {
        final date = DateTime.tryParse(r['recordedAt'] ?? '') ?? now;
        final diff = now.difference(DateTime(date.year, date.month, date.day)).inDays;
        if (diff >= 0 && diff < 7) values[6 - diff] += (r['points'] as num?)?.toInt() ?? 0;
      }
    } else {
      // つき: 週別
      values = List.filled(4, 0);
      labels = ['1週', '2週', '3週', '4週'];
      for (final r in records) {
        final date = DateTime.tryParse(r['recordedAt'] ?? '') ?? now;
        final diff = now.difference(date).inDays;
        final week = (diff / 7).floor();
        if (week >= 0 && week < 4) values[3 - week] += (r['points'] as num?)?.toInt() ?? 0;
      }
    }

    final int maxVal = values.isEmpty ? 1 : (values.reduce((a, b) => a > b ? a : b)).clamp(1, 99999);
    final barCount = values.length;
    final barWidth = (size.width - chartLeft - 20) / barCount * 0.6;
    final barSpacing = (size.width - chartLeft - 20) / barCount;

    final colors = [const Color(0xFFB8A99A), const Color(0xFFF6C453), const Color(0xFF6CB979), const Color(0xFF6CB979), const Color(0xFFF6C453), const Color(0xFF6CB979), const Color(0xFFB8A99A)];
    final total = values.reduce((a, b) => a + b);

    // Y軸メモリ
    for (int i = 0; i <= 4; i++) {
      final gy = chartTop + i * (chartHeight / 4);
      paint.color = const Color(0xFFB8A99A);
      canvas.drawRect(Rect.fromLTWH(chartLeft, gy, size.width - chartLeft - 10, 1), paint);
      final label = (maxVal - (maxVal / 4 * i)).round().toString();
      _drawText(canvas, label, 2, gy - 6, 9, const Color(0xFFB8A99A));
    }

    // 棒グラフ
    for (int i = 0; i < values.length; i++) {
      final barH = (values[i] / maxVal) * chartHeight;
      final barX = chartLeft + i * barSpacing;
      final barY = chartBottom - barH;
      paint.color = colors[i % colors.length];
      canvas.drawRect(Rect.fromLTWH(barX, barY, barWidth, barH), paint);
      if (values[i] > 0) {
        _drawText(canvas, '${values[i]}', barX + 2, barY - 14, 9, const Color(0xFF1A1228));
      }
    }

    // X軸ラベル
    for (int i = 0; i < labels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: const TextStyle(fontFamily: 'DotGothic16', fontSize: 9, color: Color(0xFF1A1228))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(chartLeft + i * barSpacing + (barWidth - tp.width) / 2, chartBottom + 4));
    }

    // 合計
    final totalTp = TextPainter(
      text: TextSpan(text: '合計: +${total}pt', style: const TextStyle(fontFamily: 'DotGothic16', fontSize: 11, color: Color(0xFFC46A85))),
      textDirection: TextDirection.ltr,
    )..layout();
    totalTp.paint(canvas, Offset((size.width - totalTp.width) / 2, chartBottom + 20));
  }

  void _drawText(Canvas canvas, String text, double x, double y, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontFamily: 'DotGothic16', fontSize: fontSize, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
