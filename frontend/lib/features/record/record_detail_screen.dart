import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/app_config.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/ui/pixel_dialog.dart';
import 'package:buta_app/shared/ui/pixel_tab_bar.dart';
import 'package:buta_app/features/record/record_tab_screen.dart';

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
      appBar: const PixelAppBar(title: 'きろく しょうさい', showBack: true),
      bottomNavigationBar: SafeArea(child: PixelTabBar(sx: sx, sy: sy, activeIndex: 1)),
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-record.svg', fit: BoxFit.cover)),
        // カテゴリ
        Positioned(top: 20 * sy, left: 14 * sx, child: Container(
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
        Positioned(top: 102 * sy, left: 14 * sx, child: Text('にちじ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
        Positioned(top: 120 * sy, left: 14 * sx, child: Container(
          width: 362 * sx, height: 36 * sy,
          padding: EdgeInsets.symmetric(horizontal: 14 * sx),
          decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
          alignment: Alignment.centerLeft,
          child: Text(_formatDate(date), style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
        )),
        // メモ
        Positioned(top: 176 * sy, left: 14 * sx, child: Text('メモ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
        Positioned(top: 194 * sy, left: 14 * sx, child: Container(
          width: 362 * sx, height: 80 * sy,
          padding: EdgeInsets.all(10 * sx),
          decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
          alignment: Alignment.topLeft,
          child: Text(memo.isEmpty ? '—' : memo, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
        )),
        // 削除ボタン（画面下部、タブバーの上）
        Positioned(bottom: 8 * sy, left: 14 * sx, child: GestureDetector(
          onTap: () => _delete(context, ref),
          child: Container(
            width: 362 * sx, height: 40 * sy,
            decoration: BoxDecoration(color: ButaColors.red, border: Border.all(color: ButaColors.ink, width: 2)),
            alignment: Alignment.center,
            child: Text('⚠ このきろくを けす', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
          ),
        )),
        // タブバー
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('id_token') ?? '';
      final dio = Dio(BaseOptions(headers: {'Authorization': token}));
      await dio.delete('${AppConfig.recordingApiBase}/activities/${record['recordId']}');
      debugPrint('DELETE OK: ${record['recordId']}');
      ref.invalidate(recordsProvider);
    } catch (e) {
      if (context.mounted) {
        final msg = e is DioException ? '${e.response?.statusCode}: ${e.response?.data}' : '$e';
        showPixelAlert(context, message: msg);
        return;
      }
    }
    if (context.mounted) context.pop();
  }
}