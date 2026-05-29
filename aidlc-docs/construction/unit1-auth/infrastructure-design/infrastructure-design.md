# Infrastructure Design - Unit 1: 認証基盤

## AWSリソース構成

### Amazon Cognito User Pool

| 設定項目 | 値 |
|---------|-----|
| サインイン属性 | email |
| パスワードポリシー | 8文字以上、大小英数字+記号 |
| MFA | なし（ハッカソン向け） |
| メール確認 | Cognito標準メール送信 |
| OAuth プロバイダー | Google, X (Twitter) |
| コールバックURL | アプリのディープリンク |
| トークン有効期限 | Access: 1時間, Refresh: 30日 |
| アカウントロック | 5回失敗で一時ロック（デフォルト） |

### API Gateway (REST API)

| 設定項目 | 値 |
|---------|-----|
| タイプ | REST API |
| 認証 | Cognito Authorizer（/users/* のみ） |
| スロットリング | 100 req/sec |
| ステージ | dev（1環境のみ） |
| CORS | Flutter アプリ向け有効化 |

**エンドポイント:**

| メソッド | パス | 認証 | Lambda統合 |
|---------|------|------|-----------|
| POST | /auth/signup | なし | auth-handler |
| POST | /auth/confirm | なし | auth-handler |
| POST | /auth/resend-code | なし | auth-handler |
| POST | /auth/login | なし | auth-handler |
| POST | /auth/logout | Cognito | auth-handler |
| POST | /auth/refresh | なし | auth-handler |
| GET | /users/me | Cognito | auth-handler |
| POST | /users/profile | Cognito | auth-handler |
| PUT | /users/profile | Cognito | auth-handler |

### Lambda: auth-handler

| 設定項目 | 値 |
|---------|-----|
| ランタイム | Node.js 20.x |
| メモリ | 256MB |
| タイムアウト | 10秒 |
| アーキテクチャ | arm64（コスト最適） |
| 環境変数 | COGNITO_USER_POOL_ID, COGNITO_CLIENT_ID, USERS_TABLE_NAME |
| IAMロール | Cognito AdminAPI + DynamoDB CRUD |

### DynamoDB: Users Table

| 設定項目 | 値 |
|---------|-----|
| テーブル名 | buta-users-dev |
| パーティションキー | userId (String) |
| キャパシティ | オンデマンド |
| GSI | nickname-index (PK: nickname) |
| TTL | なし |
| バックアップ | なし（ハッカソン向け） |

## モニタリング

| 項目 | 設定 |
|------|------|
| Lambda ログ | CloudWatch Logs（自動、保持期間7日） |
| API Gateway ログ | アクセスログ有効化 |
| アラーム | なし |
| X-Ray | なし |

## コスト見積もり（月額）

| サービス | 見積もり |
|---------|---------|
| Cognito | $0（50,000 MAUまで無料） |
| API Gateway | $0（100万リクエストまで無料） |
| Lambda | $0（100万リクエスト/40万GB秒まで無料） |
| DynamoDB | $0（25GB/25WCU/25RCUまで無料） |
| CloudWatch | $0（5GB/月まで無料） |
| **合計** | **$0（無料枠内）** |
