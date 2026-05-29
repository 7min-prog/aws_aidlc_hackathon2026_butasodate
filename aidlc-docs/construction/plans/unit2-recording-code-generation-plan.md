# Code Generation Plan - Unit 2: 行動記録 + ヘルスデータ連携

## ユニットコンテキスト

- **対象ストーリー**: US-2.1〜US-2.5, US-3.1〜US-3.11
- **依存**: Unit 1（認証 - Cognito JWT、UserPoolテーブル）
- **スコープ**: バックエンド（Lambda + サービス層）+ インフラ（CDK）のみ。フロントエンドはUnit1.5で実装。
- **コード配置**: `backend/recording-handler/` + `infrastructure/lib/recording-stack.ts`

## 生成ステップ

### バックエンド

- [ ] Step 1: プロジェクト初期化（backend/recording-handler/）
  - package.json, tsconfig.json, jest設定
  - 依存: @aws-sdk/client-dynamodb, @aws-sdk/lib-dynamodb

- [ ] Step 2: 型定義（src/types.ts）
  - ActivityRecord, ActivityCategory, HealthSyncRecord エンティティ型
  - リクエスト/レスポンス型
  - Enum（RecordSource, CategoryType, HealthCategory, HealthEvaluation）

- [ ] Step 3: ポイント計算ロジック（src/services/point-calculator.ts）
  - calculateManualPoints(): カテゴリ→basePoints
  - calculateStepsPoints(): 歩数評価（デッドゾーン付き）
  - calculateSleepPoints(): 睡眠統合評価（就寝+睡眠時間のmax）
  - calculateWeightPoints(): 体重変動評価（初回対応）

- [ ] Step 4: ポイント計算ユニットテスト（tests/services/point-calculator.test.ts）
  - 各計算式の境界値テスト（デッドゾーン、初回体重、日付またぎ）

- [ ] Step 5: 記録サービス（src/services/recording-service.ts）
  - createRecord(): 単件記録（冪等性チェック付き）
  - batchCreateRecords(): バッチ記録（TransactWriteItems）
  - getRecords(): カーソルページネーション取得
  - deleteAutoDetectedRecord(): 自動検出レコード削除
  - getSummary(): 今日/週間サマリー集計

- [ ] Step 6: ヘルス同期サービス（src/services/health-sync-service.ts）
  - syncHealthData(): 冪等性チェック + ポイント計算 + トランザクション保存

- [ ] Step 7: アバターコネクタ スタブ（src/connectors/avatar-connector.ts）
  - addPoints(): Unit3実装までのスタブ
  - deductPoints(): Unit3実装までのスタブ

- [ ] Step 8: Lambdaハンドラ - recording（src/handlers/recording.ts）
  - POST /activities, POST /activities/batch
  - GET /activities（カーソルページネーション）
  - DELETE /activities/{recordId}
  - GET /activities/summary

- [ ] Step 9: Lambdaハンドラ - health-sync（src/handlers/health-sync.ts）
  - POST /health-sync

- [ ] Step 10: Lambdaハンドラ - categories（src/handlers/categories.ts）
  - GET /categories
  - GET /categories/version

- [ ] Step 11: 共通ユーティリティ（src/utils/）
  - dynamo-client.ts（DynamoDB DocumentClient）
  - response.ts（APIレスポンスヘルパー）
  - auth.ts（JWT userId抽出）

- [ ] Step 12: ハンドラユニットテスト（tests/handlers/）
  - recording.test.ts, health-sync.test.ts, categories.test.ts

### インフラ

- [ ] Step 13: CDKスタック（infrastructure/lib/recording-stack.ts）
  - DynamoDB 3テーブル（ActivityRecord, HealthSyncRecord, ActivityCategory）
  - Lambda 3関数
  - API Gatewayリソース追加（Cognito Authorizer参照）
  - デフォルトカテゴリ投入用カスタムリソース

- [ ] Step 14: CDK app.ts更新（infrastructure/bin/app.ts）
  - RecordingStack追加

### ドキュメント

- [ ] Step 15: コード生成サマリー（aidlc-docs/construction/unit2-recording/code/code-summary.md）
  - 生成済みファイル一覧
  - **フロントエンド未実装の明記**（Unit1.5で実装予定）
  - Unit1.5が引き継ぐべき情報（API仕様、型定義、エンドポイント一覧）

## フロントエンド引き継ぎ事項（Unit1.5向け）

**本ユニットではFlutterフロントエンドは未実装**。以下をUnit1.5で実装する：

- `flutter_app/lib/features/recording/` — 行動記録画面群
- `flutter_app/lib/features/health/` — ヘルスデータ連携画面群
- Hive（オフラインキャッシュ）、connectivity_plus（ネットワーク監視）、healthパッケージ連携
- 詳細設計: `aidlc-docs/construction/unit2-recording/functional-design/frontend-components.md`
- NFRパターン: `aidlc-docs/construction/unit2-recording/nfr-design/nfr-design-patterns.md`（楽観的UI、オフラインファースト）
- API仕様: 本ユニットで生成した `backend/recording-handler/src/types.ts` の型定義を参照
