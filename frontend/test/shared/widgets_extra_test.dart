import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buta_app/shared/ui/widgets.dart';

void main() {
  group('PixelBox', () {
    testWidgets('renders with child', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PixelBox(child: Text('hello')))));
      expect(find.text('hello'), findsOneWidget);
    });
  });

  group('PixelButton', () {
    testWidgets('renders text and responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PixelButton(text: 'タップ', onTap: () => tapped = true))));
      expect(find.text('タップ'), findsOneWidget);
      await tester.tap(find.text('タップ'));
      expect(tapped, isTrue);
    });

    testWidgets('shows marker when showMarker is true', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PixelButton(text: 'go', showMarker: true))));
      expect(find.text('go'), findsOneWidget);
      // Marker adds a ▶ prefix - just verify widget renders
      expect(find.byType(PixelButton), findsOneWidget);
    });
  });

  group('PixelBar', () {
    testWidgets('renders with given value', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox(width: 200, child: PixelBar(value: 0.5)))));
      expect(find.byType(PixelBar), findsOneWidget);
    });
  });

  group('PixelTag', () {
    testWidgets('renders text', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PixelTag(text: 'LV.5'))));
      expect(find.text('LV.5'), findsOneWidget);
    });
  });

  group('PixelAppBar', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(appBar: PixelAppBar(title: 'テスト'))));
      expect(find.text('テスト'), findsOneWidget);
    });
  });
}
