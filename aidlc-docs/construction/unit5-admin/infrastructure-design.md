# Unit 5: 管理画面 (FR-7) — Infrastructure Design

## AWSリソース構成

```
[ブラウザ]
    ↓
[CloudFront] → [S3] (React SPA 静的ファイル)
    ↓
[API Gateway (REST)]
    ↓
[Lambda: admin-handler] (Hono)
    ↓
[DynamoDB] / [Cognito User Pool]
```

## リソース一覧

| リソース | 用途 | 設定 |
|---|---|---|
| S3 Bucket (既存) | スプライト/アニメーション保存 | butasodate-assets-{accountId}-dev |
| S3 Bucket (新規) | 管理画面SPA静的ホスティング | プライベート、CloudFront経由のみ |
| CloudFront | CDN + HTTPS | S3オリジン、OAC |
| API Gateway | REST API | ステージ: dev |
| Lambda | admin-handler (Hono) | Node.js 20, ARM64, 256MB, 10s |
| DynamoDB (既存) | avatars, evolution-paths, skills | 既存テーブルを参照 |
| DynamoDB (新規) | admin-audit-log | 操作ログ用 |
| Cognito (既存) | User Pool | ユーザー管理操作用 |

## 新規DynamoDBテーブル: admin-audit-log

| キー | 型 | 説明 |
|---|---|---|
| logId (PK) | String | ULID |
| timestamp (SK) | String | ISO 8601 |
| operator | String | 操作者ID |
| action | String | 操作種別 (CREATE/UPDATE/DELETE/DISABLE/ENABLE) |
| target | String | 対象リソース |
| detail | Map | 変更内容 |

## 新規DynamoDBテーブル: game-config

| キー | 型 | 説明 |
|---|---|---|
| configKey (PK) | String | 設定キー (INITIAL_STATS, MAX_LEVEL等) |
| value | Map/Number/String | 設定値 |
| updatedAt | String | 最終更新日時 |
| updatedBy | String | 更新者 |

## 環境変数 (Lambda)

| 変数名 | 値 |
|---|---|
| ADMIN_USER | Basic認証ユーザー名 |
| ADMIN_PASSWORD | Basic認証パスワード |
| USER_POOL_ID | Cognito User Pool ID |
| AVATAR_TABLE_NAME | butasodate-avatars |
| EVOLUTION_PATH_TABLE_NAME | butasodate-evolution-paths |
| SKILL_TABLE_NAME | butasodate-skills |
| AUDIT_LOG_TABLE_NAME | butasodate-admin-audit-log |
| GAME_CONFIG_TABLE_NAME | butasodate-game-config |
| USER_PROFILE_TABLE_NAME | butasodate-user-profiles |
| RECORDING_TABLE_NAME | butasodate-recordings |
| ASSETS_BUCKET_NAME | butasodate-assets-{accountId}-dev |

## ファイルアップロード

管理画面から新規ぶた（進化パス）登録時に、スプライト画像・アニメーションファイルをアップロード可能。

| 項目 | 設計 |
|---|---|
| アップロード先 | S3: butasodate-assets-{accountId}-dev/assets/sprites/ |
| 方式 | S3 Presigned URL（Lambda経由で署名付きURLを発行→フロントから直接S3にアップロード） |
| 対応形式 | PNG, WebP, GIF, MP4 |
| サイズ上限 | 10MB |

---

## 承認

このインフラ構成で進めてよいですか？

- [×] 承認する
- [ ] 修正が必要（下記にコメント記入）

コメント:

---
