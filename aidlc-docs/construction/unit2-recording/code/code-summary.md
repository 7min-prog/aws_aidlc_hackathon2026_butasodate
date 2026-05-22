# Code Summary - Unit 2: 行動記録 + ヘルスデータ連携

## 生成済みファイル

### バックエンド（backend/recording-handler/）

| ファイル | 責務 |
|---------|------|
| package.json | プロジェクト設定、依存関係 |
| tsconfig.json | TypeScript設定 |
| src/types.ts | エンティティ型、リクエスト/レスポンス型、Enum |
| src/services/point-calculator.ts | ポイント計算ロジック（手動/歩数/体重/睡眠） |
| src/services/recording-service.ts | 記録CRUD、バッチ、サマリー |
| src/services/health-sync-service.ts | ヘルスデータ評価・同期処理 |
| src/connectors/avatar-connector.ts | Unit3アバター連携スタブ |
| src/handlers/recording.ts | /activities API ハンドラ |
| src/handlers/health-sync.ts | /health-sync API ハンドラ |
| src/handlers/categories.ts | /categories API ハンドラ |
| src/utils/dynamo-client.ts | DynamoDB DocumentClient |
| src/utils/response.ts | APIレスポンスヘルパー |
| src/utils/auth.ts | JWT userId抽出 |
| tests/services/point-calculator.test.ts | ポイント計算ユニットテスト |

### インフラ（infrastructure/）

| ファイル | 責務 |
|---------|------|
| lib/recording-stack.ts | DynamoDB 3テーブル + Lambda 3関数 + API Gateway + カテゴリシード |
| bin/app.ts | RecordingStack追加（更新） |

## ⚠️ フロントエンド未実装

**Flutterフロントエンドは本ユニットでは未実装です。Unit1.5で一括実装予定。**

### Unit1.5が引き継ぐべき情報

| 参照先 | 内容 |
|--------|------|
| `backend/recording-handler/src/types.ts` | API型定義（リクエスト/レスポンス型） |
| `aidlc-docs/construction/unit2-recording/functional-design/frontend-components.md` | 画面設計、コンポーネント階層、状態定義 |
| `aidlc-docs/construction/unit2-recording/nfr-design/nfr-design-patterns.md` | 楽観的UI、オフラインファースト、リトライパターン |
| `aidlc-docs/construction/unit2-recording/nfr-requirements/nfr-requirements.md` | Hive、connectivity_plus、healthパッケージ選定 |

### Unit1.5で実装が必要なFlutterコード

```text
flutter_app/lib/features/recording/   # 行動記録（カテゴリ選択、記録確認、履歴、サマリー）
flutter_app/lib/features/health/       # ヘルスデータ連携（設定、同期サマリー）
```

## APIエンドポイント

| メソッド | パス | 説明 |
|---------|------|------|
| GET | /categories | カテゴリ一覧取得 |
| GET | /categories/version | カテゴリバージョン取得 |
| POST | /activities | 行動記録（単件） |
| POST | /activities/batch | 行動記録（バッチ） |
| GET | /activities | 記録履歴取得 |
| DELETE | /activities/{recordId} | 自動検出レコード削除 |
| GET | /activities/summary | サマリー取得 |
| POST | /health-sync | ヘルスデータ同期 |

## ビルド・デプロイ手順

```bash
# バックエンドビルド
cd backend/recording-handler
npm install
npm run build

# テスト実行
npm test

# CDKデプロイ（AWS環境必要）
cd infrastructure
npm install
COGNITO_USER_POOL_ID=<AuthStackのOutput> npx cdk deploy ButaRecordingStack
```
