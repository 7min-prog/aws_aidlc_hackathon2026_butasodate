# Flutter Testing Rules

Use when modifying any Dart file under `frontend/lib/`.

## Mandatory: Run Tests After Changes

Every code change MUST be verified with tests before completion:

```bash
cd frontend && flutter test test/main_test.dart test/shared/ test/features/ test/screens/ test/golden/ test/unit/ test/pixel_app_bar_test.dart test/router_routes_test.dart test/login_legal_links_test.dart test/router_test.dart
```

## Coverage Target

- Maintain **90%+ line coverage**
- Check with: `flutter test --coverage` then parse `coverage/lcov.info`

## When Adding New Features

1. Write or update tests covering the new code
2. If adding a new screen, add a render test in `test/screens/`
3. If adding a new provider/service, add a unit test in `test/unit/` or `test/shared/`
4. If modifying routing, update `test/router_routes_test.dart`

## Test Structure

| Directory | Purpose |
|---|---|
| `test/unit/` | Pure unit tests (no Flutter widget binding, no asset loading) |
| `test/shared/` | Tests for shared services, models, theme, widgets |
| `test/features/` | Per-feature widget tests |
| `test/screens/` | Screen render tests, coverage boost tests |
| `test/golden/` | Golden image comparison tests |

## Key Patterns

### Mocking Dio (for API tests)
```dart
final dio = Dio(BaseOptions(baseUrl: 'http://mock'));
final adapter = DioAdapter(dio: dio);
adapter.onPost('/path', (s) => s.reply(200, {...}), data: Matchers.any);
final c = ProviderContainer(overrides: [authDioProvider.overrideWithValue(dio)]);
```

### Screen render tests (with animations)
```dart
// Use pump loops instead of pumpAndSettle for screens with ongoing animations
for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 100)); }
```

### AppConfig in tests
```dart
// Use setUpAll (not setUp) because AppConfig.flavor is late final
setUpAll(() => AppConfig.init(Flavor.dev));
```

## Golden Tests

After UI changes, update goldens:
```bash
flutter test --update-goldens test/golden/
```

## Do NOT

- Skip tests when modifying code
- Use `pumpAndSettle` on screens with `CloudAnimation` or `StarryBackground` (they never settle)
- Call `AppConfig.init()` in `setUp` (use `setUpAll`)
- Rely on network in unit tests — always mock Dio via `authDioProvider`
