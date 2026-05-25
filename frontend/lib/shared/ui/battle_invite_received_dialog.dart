import 'package:flutter/material.dart';
import 'package:buta_app/shared/theme.dart';

/// B-05 バトル招待受信ポップアップ
Future<bool?> showBattleInviteReceived(BuildContext context, {required String fromName}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => Center(child: _BattleInviteReceivedDialog(fromName: fromName)),
  );
}

class _BattleInviteReceivedDialog extends StatelessWidget {
  const _BattleInviteReceivedDialog({required this.fromName});
  final String fromName;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 310, height: 200,
        decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 3)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            height: 32, color: ButaColors.red,
            alignment: Alignment.center,
            child: const Text('たいせん しょうたい', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.paper)),
          ),
          Expanded(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$fromName から', style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
              const Text('たいせんの しょうたいが\nとどきました！', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink), textAlign: TextAlign.center),
            ]),
          )),
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.of(context).pop(true),
              child: Container(height: 40, decoration: BoxDecoration(color: ButaColors.green, border: Border.all(color: ButaColors.ink, width: 2)),
                child: const Center(child: Text('うける！', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper)))),
            )),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () => Navigator.of(context).pop(false),
              child: Container(height: 40, decoration: BoxDecoration(color: ButaColors.gray, border: Border.all(color: ButaColors.ink, width: 2)),
                child: const Center(child: Text('ことわる', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper)))),
            )),
          ])),
        ]),
      ),
    );
  }
}
