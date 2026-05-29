import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/router.dart';
import 'package:buta_app/shared/state/boot_state.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'access_token': 'a', 'refresh_token': 'r'}));

  testWidgets('PixelTabBar renders all tabs on home', (tester) async {
    tester.view.physicalSize = const Size(390, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final c = ProviderContainer(overrides: [
      initialRouteProvider.overrideWithValue('/home'),
      bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
    ]);
    addTearDown(c.dispose);
    final router = c.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
    for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 100)); }

    expect(find.text('ホーム'), findsWidgets);
    expect(find.text('きろく'), findsWidgets);
    expect(find.text('バトル'), findsWidgets);
    expect(find.text('フレンド'), findsWidgets);
    expect(find.text('せってい'), findsWidgets);
  });

  testWidgets('PixelTabBar navigates to recording tab', (tester) async {
    tester.view.physicalSize = const Size(390, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final c = ProviderContainer(overrides: [
      initialRouteProvider.overrideWithValue('/home'),
      bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
    ]);
    addTearDown(c.dispose);
    final router = c.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
    for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 100)); }

    await tester.tap(find.text('きろく').last);
    for (var i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 100)); }
    expect(router.state.uri.toString(), '/recording');
  });
}
