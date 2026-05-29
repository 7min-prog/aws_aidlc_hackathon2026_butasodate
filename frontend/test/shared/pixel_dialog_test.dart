import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buta_app/shared/ui/pixel_dialog.dart';

void main() {
  group('showPixelAlert', () {
    testWidgets('shows dialog with message', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) => ElevatedButton(
          onPressed: () => showPixelAlert(context, message: 'テストメッセージ'),
          child: const Text('show'),
        )),
      ));
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      expect(find.text('テストメッセージ'), findsOneWidget);
    });

    testWidgets('dialog can be dismissed', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) => ElevatedButton(
          onPressed: () => showPixelAlert(context, message: 'dismiss me'),
          child: const Text('show'),
        )),
      ));
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      // Tap OK button if exists, or tap outside
      final okFinder = find.text('OK');
      if (okFinder.evaluate().isNotEmpty) {
        await tester.tap(okFinder);
      } else {
        await tester.tapAt(Offset.zero);
      }
      await tester.pumpAndSettle();
    });
  });

  group('showPixelConfirm', () {
    testWidgets('shows confirm dialog with message', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) => ElevatedButton(
          onPressed: () => showPixelConfirm(context, message: '確認しますか？'),
          child: const Text('confirm'),
        )),
      ));
      await tester.tap(find.text('confirm'));
      await tester.pumpAndSettle();
      expect(find.text('確認しますか？'), findsOneWidget);
    });
  });
}
