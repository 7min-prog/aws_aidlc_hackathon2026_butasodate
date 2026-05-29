import 'package:flutter/material.dart';
import 'package:buta_app/shared/theme.dart';

Future<bool?> showBattleInviteDialog(BuildContext context, {String opponent = 'まるまる'}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: ButaColors.paper,
      shape: RoundedRectangleBorder(side: BorderSide(color: ButaColors.ink, width: 2)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('バトル しょうたい！', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.ink)),
          const SizedBox(height: 12),
          Text('$opponent から\nたいせん の しょうたい！', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink2)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(ctx, true),
              child: Container(
                height: 36,
                decoration: BoxDecoration(color: ButaColors.green, border: Border.all(color: ButaColors.ink, width: 1)),
                alignment: Alignment.center,
                child: Text('うける', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink)),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(ctx, false),
              child: Container(
                height: 36,
                decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
                alignment: Alignment.center,
                child: Text('ことわる', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink)),
              ),
            )),
          ]),
        ]),
      ),
    ),
  );
}
