import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/main.dart';
import 'package:buta_app/shared/router.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/state/boot_state.dart';

import 'helpers/test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('ButaApp renders MaterialApp.router', (t) async {
    t.view.physicalSize = const Size(390, 740);
    t.view.devicePixelRatio = 1.0;
    addTearDown(() => t.view.resetPhysicalSize());
    await t.pumpWidget(ProviderScope(
      overrides: [
        initialRouteProvider.overrideWithValue('/login'),
        authStateProvider.overrideWith(() => FakeAuthNotifier(null)),
        bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.login))),
      ],
      child: const ButaApp(),
    ));
    await t.pump();
    final app = t.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'ぶたそだて');
    expect(app.debugShowCheckedModeBanner, false);
    expect(app.routerConfig, isNotNull);
  });
}
