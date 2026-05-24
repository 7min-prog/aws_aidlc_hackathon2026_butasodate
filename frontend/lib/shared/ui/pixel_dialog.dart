import 'package:flutter/material.dart';
import 'package:buta_app/shared/theme.dart';

/// Penpot "PixelDialog / Alert" に準拠したエラーダイアログ
Future<void> showPixelAlert(BuildContext context, {required String message, String title = 'けいこく'}) {
  return showDialog(
    context: context,
    builder: (_) => Center(
      child: _PixelAlertDialog(title: title, message: message),
    ),
  );
}

class _PixelAlertDialog extends StatelessWidget {
  const _PixelAlertDialog({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280, height: 150,
        decoration: BoxDecoration(
          color: ButaColors.paper,
          border: Border.all(color: ButaColors.ink, width: 3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: ButaColors.paper, width: 3)),
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: ButaColors.ink, width: 3)),
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // タイトルバー（赤）
                    Container(
                      height: 28, color: ButaColors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      child: Text(title, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper)),
                    ),
                    // メッセージ
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(11, 10, 11, 0),
                        child: Text(message, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
                      ),
                    ),
                    // OKボタン
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 100, height: 32,
                            decoration: BoxDecoration(color: ButaColors.red, border: Border.all(color: ButaColors.ink, width: 2)),
                            child: const Center(child: Text('わかった', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper))),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// Penpot "D-03 記録削除確認" に準拠した確認ダイアログ
Future<bool?> showPixelConfirm(BuildContext context, {required String message, String title = 'かくにん', String confirmLabel = 'けす', String cancelLabel = 'やめる'}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => Center(
      child: _PixelConfirmDialog(title: title, message: message, confirmLabel: confirmLabel, cancelLabel: cancelLabel),
    ),
  );
}

class _PixelConfirmDialog extends StatelessWidget {
  const _PixelConfirmDialog({required this.title, required this.message, required this.confirmLabel, required this.cancelLabel});
  final String title, message, confirmLabel, cancelLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 310, height: 200,
        decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 3)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // タイトルバー
          Container(
            height: 32, color: const Color(0xFFE8485A).withValues(alpha: 0.15),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(children: [
              Container(width: 24, height: 24, color: ButaColors.red, child: const Center(child: Text('！', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper)))),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
            ]),
          ),
          Container(height: 3, color: ButaColors.red),
          // メッセージ
          Expanded(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(message, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
          )),
          // ボタン
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.of(context).pop(true),
              child: Container(height: 40, decoration: BoxDecoration(color: ButaColors.red, border: Border.all(color: ButaColors.ink, width: 2)),
                child: Center(child: Text(confirmLabel, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper)))),
            )),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () => Navigator.of(context).pop(false),
              child: Container(height: 40, decoration: BoxDecoration(color: const Color(0xFFB8A99A), border: Border.all(color: ButaColors.ink, width: 2)),
                child: Center(child: Text(cancelLabel, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper)))),
            )),
          ])),
        ]),
      ),
    );
  }
}
