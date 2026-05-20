# Build and Test Summary

## Build Status
- **Build Tool**: TypeScript Compiler (tsc) + AWS CDK
- **Build Artifacts**: `backend/auth-handler/dist/`, `infrastructure/cdk.out/`

## Test Strategy

### Unit Tests
- **フレームワーク**: Jest + ts-jest
- **対象**: 全ハンドラー（signup, login, logout, refresh, profile）
- **方針**: AWS SDKモックでロジックのみテスト
- **カバレッジ目標**: 80%

### Integration Tests
- **方式**: curl による手動API呼び出し
- **対象シナリオ**:
  1. サインアップ → 確認 → ログイン
  2. プロフィール CRUD
  3. トークンリフレッシュ
  4. エラーケース（不正認証、未認証アクセス）

### Performance Tests
- **N/A**: ハッカソンデモ規模（10人）のため省略

### Security Tests
- **N/A**: Cognitoデフォルト設定に依存、追加テスト不要

## 手順書一覧

| ファイル | 内容 |
|---------|------|
| build-instructions.md | ビルド・デプロイ手順 |
| unit-test-instructions.md | ユニットテスト実行手順 |
| integration-test-instructions.md | 統合テスト（curl）手順 |

## Next Steps
1. `npm install` → `npm run build` でビルド確認
2. ユニットテスト作成・実行
3. `cdk deploy` でAWSにデプロイ
4. 統合テスト（curl）で動作確認
