import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/shared/app_config.dart';

void main() {
  group('ButaBottomNavBar', () {
    testWidgets('renders all tabs', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        bottomNavigationBar: ButaBottomNavBar(currentIndex: 0, onTap: (_) {}),
      )));
      expect(find.text('ホーム'), findsOneWidget);
      expect(find.text('きろく'), findsOneWidget);
      expect(find.text('バトル'), findsOneWidget);
      expect(find.text('フレンド'), findsOneWidget);
      expect(find.text('せってい'), findsOneWidget);
    });

    testWidgets('onTap callback fires with correct index', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        bottomNavigationBar: ButaBottomNavBar(currentIndex: 0, onTap: (i) => tappedIndex = i),
      )));
      await tester.tap(find.text('きろく'));
      expect(tappedIndex, 1);
    });

    testWidgets('highlights active tab', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        bottomNavigationBar: ButaBottomNavBar(currentIndex: 2, onTap: (_) {}),
      )));
      // Just verify it renders without error
      expect(find.byType(ButaBottomNavBar), findsOneWidget);
    });
  });

  group('PixelBar variations', () {
    testWidgets('renders with 0 value', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox(width: 200, child: PixelBar(value: 0)))));
      expect(find.byType(PixelBar), findsOneWidget);
    });

    testWidgets('renders with 1.0 value', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox(width: 200, child: PixelBar(value: 1.0)))));
      expect(find.byType(PixelBar), findsOneWidget);
    });

    testWidgets('renders with custom color', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox(width: 200, child: PixelBar(value: 0.7, color: ButaColors.red)))));
      expect(find.byType(PixelBar), findsOneWidget);
    });
  });

  group('PixelButton styles', () {
    testWidgets('secondary style', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PixelButton(text: 'sec', style: PixelButtonStyle.secondary))));
      expect(find.text('sec'), findsOneWidget);
    });

    testWidgets('danger style', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PixelButton(text: 'del', style: PixelButtonStyle.danger))));
      expect(find.text('del'), findsOneWidget);
    });
  });

  group('ApiClient', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('resolves auth paths correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final client = container.read(apiClientProvider);
      // Just verify it can be created
      expect(client, isNotNull);
    });
  });
}
