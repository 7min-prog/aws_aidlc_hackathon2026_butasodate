import 'package:flutter/material.dart';
import 'package:buta_app/shared/theme.dart';

class HealthSyncResultDialog extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final int totalPoints;
  final String avatarName;

  const HealthSyncResultDialog({
    super.key,
    required this.items,
    required this.totalPoints,
    required this.avatarName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 35),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: ButaColors.paper,
          border: Border.all(color: ButaColors.ink, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // タイトル
            const Text(
              'ヘルスデータ けっか',
              style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.ink),
            ),
            const SizedBox(height: 8),
            Container(height: 2, color: ButaColors.ink2),
            const SizedBox(height: 12),
            // ぶたメッセージ
            Text(
              '🐷 $avatarNameが よろこんでいるよ！',
              style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.pinkDk),
            ),
            const SizedBox(height: 16),
            // データ行
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item['label']} ${item['value']}',
                      style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink2),
                    ),
                  ),
                  Text(
                    '+${item['points']}pt',
                    style: const TextStyle(fontFamily: kFontPressStart2P, fontSize: 11, color: ButaColors.red),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 4),
            Container(height: 2, color: ButaColors.yellow),
            const SizedBox(height: 12),
            // 合計
            Text(
              'ごうけい  +${totalPoints}pt!',
              style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.red),
            ),
            const SizedBox(height: 20),
            // ボタン
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 200,
                height: 44,
                decoration: BoxDecoration(
                  color: ButaColors.red,
                  border: Border.all(color: ButaColors.ink, width: 2),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'やったね！',
                  style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.paper),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
