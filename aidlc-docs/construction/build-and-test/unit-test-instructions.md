# Unit Test Execution

## テストフレームワーク

- **Backend**: Jest 29 + ts-jest
- **Frontend**: Flutter test (dart test)
- **Infrastructure**: Jest + aws-cdk-lib/assertions

## Backend Unit Tests

### 全ハンドラー一括実行

```bash
cd backend/auth-handler && npm test
cd ../recording-handler && npm test
cd ../avatar-handler && npm test
cd ../battle-ws-handler && npm test
cd ../social-handler && npm test
cd ../admin-handler && npm test
```

### テスト結果サマリー

| ハンドラー | Suites | Tests | Lines Coverage |
|-----------|--------|-------|---------------|
| auth-handler | 7 | 44 | 84.6% |
| recording-handler | 10 | 83 | 90.3% |
| avatar-handler | 7 | 102 | 91.9% |
| battle-ws-handler | 3 | 33 | 90.6% |
| social-handler | 2 | 37 | 95.9% |
| admin-handler | 1 | 30 | 98.6% |
| **合計** | **30** | **329** | — |

### カバレッジ確認

```bash
cd backend/auth-handler && npx jest --coverage
```

## Frontend Unit Tests

```bash
cd frontend
flutter test --coverage \
  test/main_test.dart test/shared/ test/features/ test/screens/ test/unit/ \
  test/pixel_app_bar_test.dart test/router_routes_test.dart \
  test/login_legal_links_test.dart test/router_test.dart
```

- **カバレッジ目標**: 90%+
- **カバレッジ確認**: `frontend/coverage/lcov.info`

## Infrastructure Tests

```bash
cd infrastructure
npm install
npx jest
```

- CDKスタック構成の28アサーション（Lambda数、DynamoDBテーブル数、API Gateway設定等）

## テスト方針

- AWS SDKは `jest.mock()` でモック（外部依存なし）
- Hono系ハンドラー（avatar, admin）は `app.request()` でルーティング込みテスト
- Flutter は `ProviderContainer` + `DioAdapter` でAPI層モック
