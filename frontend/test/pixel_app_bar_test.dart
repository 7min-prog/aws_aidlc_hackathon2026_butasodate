import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buta_app/shared/ui/widgets.dart';

void main() {
  group('PixelAppBar', () {
    testWidgets('displays title', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(appBar: PixelAppBar(title: 'テスト')),
      ));
      expect(find.text('テスト'), findsOneWidget);
    });

    testWidgets('shows back button when showBack is true', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(appBar: PixelAppBar(title: 'タイトル', showBack: true)),
      ));
      // Back button is a GestureDetector with ◀ text
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('hides back button when showBack is false', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(appBar: PixelAppBar(title: 'タイトル')),
      ));
      // No ◀ character when showBack is false
      expect(find.text('◀'), findsNothing);
    });

    testWidgets('preferredSize is 48', (tester) async {
      const appBar = PixelAppBar(title: 'サイズ');
      expect(appBar.preferredSize.height, 48);
    });
  });
}
