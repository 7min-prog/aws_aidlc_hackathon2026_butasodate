import 'package:flutter/material.dart';
import 'package:buta_app/shared/theme.dart';

/// H-01 ヘルスデータ同期結果ダイアログ
Future<void> showHealthSyncResult(BuildContext context, {List<HealthSyncItem> items = const []}) {
  return showDialog(
    context: context,
    builder: (_) => Center(child: _HealthSyncDialog(items: items)),
  );
}

class HealthSyncItem {
  final String label;
  final int points;
  const HealthSyncItem(this.label, this.points);
}

class _HealthSyncDialog extends StatelessWidget {
  const _HealthSyncDialog({required this.items});
  final List<HealthSyncItem> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (s, i) => s + i.points);
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 310, constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 3)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            height: 32, color: ButaColors.green,
            alignment: Alignment.center,
            child: const Text('ヘルスデータ どうき けっか', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.paper)),
          ),
          Flexible(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final item in items)
                Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
                  Text(item.label, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink)),
                  const Spacer(),
                  Text('+${item.points}pt', style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: Color(0xFFC46A85))),
                ])),
              const Divider(color: ButaColors.ink),
              Row(children: [
                const Text('ごうけい', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
                const Spacer(),
                Text('+${total}pt', style: const TextStyle(fontFamily: kFontPressStart2P, fontSize: 12, color: Color(0xFFC46A85))),
              ]),
            ]),
          )),
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              height: 40,
              decoration: BoxDecoration(color: ButaColors.yellow, border: Border.all(color: ButaColors.ink, width: 2)),
              alignment: Alignment.center,
              child: const Text('やったね！', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
            ),
          )),
        ]),
      ),
    );
  }
}
