import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/shared/utils/error_helper.dart';

class RecordConfirmScreen extends ConsumerStatefulWidget {
  const RecordConfirmScreen({super.key, required this.category});
  final Map<String, dynamic> category;
  @override
  ConsumerState<RecordConfirmScreen> createState() => _RecordConfirmScreenState();
}

class _RecordConfirmScreenState extends ConsumerState<RecordConfirmScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  String _formatDate() {
    final n = _selectedDate;
    return '${n.year}/${n.month.toString().padLeft(2, '0')}/${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _submit() async {
    final cat = widget.category;
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post('/activities', data: {'records': [{'categoryId': cat['categoryId']}]});
      if (!mounted) return;
      final data = res.data as Map<String, dynamic>?;
      if (data?['evolved'] == true) {
        final avatar = data?['avatar'] as Map<String, dynamic>? ?? {};
        context.go('/evo-anim', extra: {'name': avatar['name'] ?? 'ぽっちゃり', 'level': avatar['level'] ?? 5});
      } else {
        context.go('/record-complete', extra: {'points': cat['basePoints'] ?? cat['points'], 'result': data});
      }
    } catch (e) {
      if (mounted) context.go('/record-complete', extra: {'points': cat['basePoints'] ?? cat['points'], 'error': formatApiError(e)});
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;
    final pts = widget.category['basePoints'] ?? widget.category['points'] ?? 0;
    final name = widget.category['name'] ?? '';
    final iconKey = widget.category['iconKey'] as String? ?? 'ramen';
    const iconMap = {
      'ramen': 'cat-ramen', 'snack': 'cat-snack', 'binge': 'cat-binge',
      'junk': 'cat-binge', 'night': 'cat-late-night', 'sleep': 'cat-oversleep',
      'couch': 'cat-skip-exercise', 'tv': 'cat-gaming', 'nap': 'cat-nap',
    };
    final iconPath = 'assets/pixel-art/icons/${iconMap[iconKey] ?? 'cat-ramen'}.svg';

    return Scaffold(
      appBar: const PixelAppBar(title: 'きろく かくにん', showBack: true),
      backgroundColor: const Color(0xFF8A5A2B),
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-record.svg', fit: BoxFit.cover)),
        Positioned(top: 20 * sy, left: 14 * sx, child: Container(
          width: 362 * sx, height: 60 * sy,
          decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
          child: Column(children: [
            Container(width: 362 * sx, height: 6 * sy, color: const Color(0xFF8A5A2B)),
            Expanded(child: Row(children: [
              SizedBox(width: 14 * sx),
              SvgPicture.asset(iconPath, width: 24, height: 24),
              SizedBox(width: 10 * sx),
              Text(name, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.ink)),
            ])),
          ]),
        )),
        Positioned(top: 102 * sy, left: 14 * sx, child: Text('にちじ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
        Positioned(top: 120 * sy, left: 14 * sx, child: GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: 362 * sx, height: 36 * sy,
            padding: EdgeInsets.symmetric(horizontal: 14 * sx),
            decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
            alignment: Alignment.centerLeft,
            child: Row(children: [
              Expanded(child: Text(_formatDate(), style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink))),
              Icon(Icons.calendar_today, size: 16, color: ButaColors.ink),
            ]),
          ),
        )),
        Positioned(top: 176 * sy, left: 14 * sx, child: Text('メモ（にんい）', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
        Positioned(top: 194 * sy, left: 14 * sx, child: Container(
          width: 362 * sx, height: 80 * sy,
          padding: EdgeInsets.all(10 * sx),
          decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
          alignment: Alignment.topLeft,
          child: Text('ひとこと かいてね...', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.gray)),
        )),
        Positioned(top: 302 * sy, left: 14 * sx, child: Container(
          width: 362 * sx, height: 60 * sy,
          color: ButaColors.yellow,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('+${pts}pt もらえるよ！', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 20, color: ButaColors.ink, fontWeight: FontWeight.bold)),
            Text('ぶたが よろこぶ！', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.ink)),
          ]),
        )),
        Positioned(top: 392 * sy, left: 14 * sx, child: GestureDetector(
          onTap: _submit,
          child: Container(
            width: 362 * sx, height: 48 * sy,
            decoration: BoxDecoration(color: ButaColors.yellow, border: Border.all(color: ButaColors.ink, width: 2)),
            alignment: Alignment.center,
            child: Row(mainAxisSize: MainAxisSize.min, children: [SvgPicture.asset('assets/pixel-art/icons/play.svg', width: 14, height: 14), const SizedBox(width: 4), Text('きろくする', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.ink))]),
          ),
        )),
      ]),
    );
  }
}