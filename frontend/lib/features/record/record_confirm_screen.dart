import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/services/api_client.dart';

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
      if (mounted) context.go('/record-complete', extra: {'points': cat['points'], 'result': res.data});
    } catch (_) {
      if (mounted) context.go('/record-complete', extra: {'points': cat['points']});
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;
    final pts = widget.category['points'] ?? 0;
    final name = widget.category['name'] ?? '';
    final icon = widget.category['icon'] ?? '?';

    return Scaffold(
      backgroundColor: const Color(0xFF8A5A2B),
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-record.svg', fit: BoxFit.cover)),
        Positioned(top: 0, left: 0, right: 0, height: 48 * sy, child: Container(
          color: ButaColors.ink,
          child: Stack(children: [
            Positioned(left: 14 * sx, top: 14 * sy, child: GestureDetector(onTap: () => context.pop(), child: Text('◀', style: TextStyle(fontSize: 16, color: ButaColors.paper)))),
            Center(child: Text('きろく かくにん', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.paper))),
          ]),
        )),
        Positioned(top: 68 * sy, left: 14 * sx, child: Container(
          width: 362 * sx, height: 60 * sy,
          decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
          child: Column(children: [
            Container(width: 362 * sx, height: 6 * sy, color: const Color(0xFF8A5A2B)),
            Expanded(child: Row(children: [
              SizedBox(width: 14 * sx),
              Text(icon, style: const TextStyle(fontSize: 24)),
              SizedBox(width: 10 * sx),
              Text(name, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.ink)),
            ])),
          ]),
        )),
        Positioned(top: 150 * sy, left: 14 * sx, child: Text('にちじ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
        Positioned(top: 168 * sy, left: 14 * sx, child: GestureDetector(
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
        Positioned(top: 224 * sy, left: 14 * sx, child: Text('メモ（にんい）', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
        Positioned(top: 242 * sy, left: 14 * sx, child: Container(
          width: 362 * sx, height: 80 * sy,
          padding: EdgeInsets.all(10 * sx),
          decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
          alignment: Alignment.topLeft,
          child: Text('ひとこと かいてね...', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.gray)),
        )),
        Positioned(top: 350 * sy, left: 14 * sx, child: Container(
          width: 362 * sx, height: 60 * sy,
          color: ButaColors.yellow,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('+${pts}pt もらえるよ！', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 20, color: ButaColors.ink, fontWeight: FontWeight.bold)),
            Text('ぶたが よろこぶ！', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.ink)),
          ]),
        )),
        Positioned(top: 440 * sy, left: 14 * sx, child: GestureDetector(
          onTap: _submit,
          child: Container(
            width: 362 * sx, height: 48 * sy,
            decoration: BoxDecoration(color: ButaColors.yellow, border: Border.all(color: ButaColors.ink, width: 2)),
            alignment: Alignment.center,
            child: Text('▶ きろくする', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.ink)),
          ),
        )),
      ]),
    );
  }
}
