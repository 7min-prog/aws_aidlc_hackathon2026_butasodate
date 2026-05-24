import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/shared/ui/pixel_dialog.dart';
import 'package:buta_app/features/home/home_screen.dart';

class RecordDetailScreen extends ConsumerWidget {
  const RecordDetailScreen({super.key, required this.record});
  final Map<String, dynamic> record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;
    final catId = record['categoryId'] ?? '';
    final name = record['categoryName'] ?? catId;
    final pts = record['points'] ?? 0;
    final memo = record['memo'] ?? '';
    final date = record['recordedAt'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF8A5A2B),
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-record.svg', fit: BoxFit.cover)),
        Positioned(top: 0, left: 0, right: 0, height: 48 * sy, child: Container(
          color: ButaColors.ink,
          child: Stack(children: [
            Positioned(left: 14 * sx, top: 14 * sy, child: GestureDetector(onTap: () => context.pop(), child: Text('◀', style: TextStyle(fontSize: 16, color: ButaColors.paper)))),
            Center(child: Text('きろく しょうさい', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.paper))),
          ]),
        )),
        // カテゴリ
        Positioned(top: 68 * sy, left: 14 * sx, child: Container(
          width: 362 * sx, height: 60 * sy,
          decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
          child: Column(children: [
            Container(width: 362 * sx, height: 6 * sy, color: const Color(0xFF8A5A2B)),
            Expanded(child: Row(children: [
              SizedBox(width: 14 * sx),
              Text(name, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.ink)),
              const Spacer(),
              Text('+${pts}pt', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
              SizedBox(width: 14 * sx),
            ])),
          ]),
        )),
        // 日時
        Positioned(top: 150 * sy, left: 14 * sx, child: Text('にちじ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
        Positioned(top: 168 * sy, left: 14 * sx, child: Container(
          width: 362 * sx, height: 36 * sy,
          padding: EdgeInsets.symmetric(horizontal: 14 * sx),
          decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
          alignment: Alignment.centerLeft,
          child: Text(_formatDate(date), style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
        )),
        // メモ
        Positioned(top: 224 * sy, left: 14 * sx, child: Text('メモ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
        Positioned(top: 242 * sy, left: 14 * sx, child: Container(
          width: 362 * sx, height: 80 * sy,
          padding: EdgeInsets.all(10 * sx),
          decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
          alignment: Alignment.topLeft,
          child: Text(memo.isEmpty ? '—' : memo, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
        )),
        // 削除ボタン（画面下部、タブバーの上）
        Positioned(bottom: 64 * sy, left: 14 * sx, child: GestureDetector(
          onTap: () => _delete(context, ref),
          child: Container(
            width: 362 * sx, height: 40 * sy,
            decoration: BoxDecoration(color: ButaColors.red, border: Border.all(color: ButaColors.ink, width: 2)),
            alignment: Alignment.center,
            child: Text('⚠ このきろくを けす', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
          ),
        )),
        // タブバー
        Positioned(bottom: 0, left: 0, right: 0, height: 56 * sy, child: PixelTabBar(sx: sx, sy: sy, activeIndex: 1)),
      ]),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showPixelConfirm(context, title: 'きろくをけす', message: 'このきろくを\nけしますか？');
    if (confirmed != true || !context.mounted) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/activities/${record['recordId']}');
    } catch (_) {}
    if (context.mounted) context.pop();
  }
}
