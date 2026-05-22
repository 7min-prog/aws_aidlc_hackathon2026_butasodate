# Unit 5: 管理画面 (FR-7) — Code Generation Plan

## 実装ステップ

### Step 1: バックエンドAPI (backend/admin-handler/)
- [ ] package.json, tsconfig.json
- [ ] src/utils/ (dynamo-client, cognito-client, auth-middleware)
- [ ] src/app.ts (Hono + OpenAPI)
  - POST /admin/login — Basic認証 → JWT発行
  - GET /admin/users — ユーザー一覧
  - GET /admin/users/:username — ユーザー詳細
  - POST /admin/users/:username/disable — アカウント停止
  - POST /admin/users/:username/enable — アカウント復活
  - DELETE /admin/users/:username — ユーザー削除（論理削除）
  - GET /admin/evolution-paths — 進化パス一覧
  - POST /admin/evolution-paths — 進化パス新規登録
  - PUT /admin/evolution-paths/:pathId — 進化パス更新
  - DELETE /admin/evolution-paths/:pathId — 進化パス削除
  - GET /admin/skills — スキル一覧
  - POST /admin/skills — スキル新規登録
  - PUT /admin/skills/:skillId — スキル更新
  - DELETE /admin/skills/:skillId — スキル削除
  - PUT /admin/users/:username/avatar — アバターデータ修正
  - POST /admin/users/:username/health-data — ヘルスデータ手動入力
  - GET /admin/game-config — ゲーム設定取得
  - PUT /admin/game-config — ゲーム設定更新
  - GET /admin/audit-log — 操作ログ一覧
  - POST /admin/upload-url — S3 Presigned URL発行
  - GET /admin/doc — OpenAPIドキュメント

### Step 2: バックエンドテスト
- [ ] tests/app.test.ts — 主要エンドポイントのテスト

### Step 3: フロントエンド (admin/)
- [ ] Vite + React + MUI + Zustand プロジェクト初期化
- [ ] src/stores/ — Zustand ストア（auth, users, masterData）
- [ ] src/api/ — APIクライアント
- [ ] src/pages/LoginPage — ログイン画面
- [ ] src/pages/UsersPage — ユーザー一覧・検索
- [ ] src/pages/UserDetailPage — ユーザー詳細・停止/復活/削除・ヘルスデータ入力
- [ ] src/pages/EvolutionPathsPage — 進化パス一覧・新規登録・編集・削除（画像アップロード付き）
- [ ] src/pages/SkillsPage — スキル一覧・新規登録・編集・削除
- [ ] src/pages/GameConfigPage — ゲーム設定編集
- [ ] src/pages/AuditLogPage — 操作ログ閲覧
- [ ] src/components/ — 共通コンポーネント（確認ダイアログ、テーブル、フォーム等）

### Step 4: CDKインフラ (infrastructure/lib/admin-stack.ts)
- [ ] S3バケット（管理画面SPA）
- [ ] CloudFront ディストリビューション
- [ ] Lambda関数（admin-handler）
- [ ] API Gateway（REST）
- [ ] DynamoDB テーブル（admin-audit-log, game-config）※新規2テーブルのみ。既存テーブルは環境変数で参照
- [ ] IAMロール（Lambda → 新規テーブル読み書き, 既存テーブル読み書き, Cognito, S3）

### Step 5: ビルド・テスト確認
- [ ] backend: npm install → tsc → jest
- [ ] frontend: npm install → vite build
- [ ] draw.io構成図との整合性確認

---

## 承認

この実装計画で進めてよいですか？

- [×] 承認する
- [ ] 修正が必要（下記にコメント記入）

コメント:

---
