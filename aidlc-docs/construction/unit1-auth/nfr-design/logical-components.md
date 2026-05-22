# Logical Components - Unit 1: 認証基盤

## システム構成図

```text
┌─────────────────────────────────────────────────────┐
│                    Flutter App                        │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────┐  │
│  │ AuthScreen  │  │ API Client  │  │ Token Store│  │
│  │ (UI Layer)  │  │ (HTTP+Auth) │  │ (SharedPref)│  │
│  └──────┬──────┘  └──────┬──────┘  └─────┬──────┘  │
└─────────┼────────────────┼────────────────┼─────────┘
          │                │                │
          │    HTTPS       │                │ ローカル保存
          ▼                ▼                ▼
┌─────────────────────────────────────────────────────┐
│              API Gateway (REST)                       │
│  - スロットリング: 100 req/sec                        │
│  - Cognito Authorizer (認証必要エンドポイント)         │
│  - パス: /auth/*, /users/*                           │
└────────────────────────┬────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│           Lambda: auth-handler (Node.js 20.x)        │
│  - メモリ: 256MB                                     │
│  - タイムアウト: 10秒                                 │
│  - 内部ルーティング: /auth/*, /users/*                │
└───────┬─────────────────────────────┬───────────────┘
        │                             │
        ▼                             ▼
┌───────────────────┐    ┌────────────────────────────┐
│  Amazon Cognito   │    │  DynamoDB: Users Table     │
│  - User Pool      │    │  - PK: userId             │
│  - OAuth (Google/X)│    │  - GSI: nickname-index    │
│  - パスワードポリシー│    │  - オンデマンドモード      │
│  - 5回ロック       │    │                            │
└───────────────────┘    └────────────────────────────┘
```

## コンポーネント詳細

### Flutter側

| コンポーネント | 責務 | 技術 |
|--------------|------|------|
| AuthScreen | ログイン/サインアップUI | Flutter Widget |
| API Client | HTTP通信 + トークン自動付与 | http or dio パッケージ |
| Token Store | トークン永続化 | SharedPreferences |
| Auth State | 認証状態管理 | Riverpod/Provider |

### AWS側

| コンポーネント | 設定 | コスト見込み |
|--------------|------|-------------|
| API Gateway | REST API, 100 req/sec制限 | 無料枠内 |
| Lambda | Node.js 20.x, 256MB, 10秒 | 無料枠内 |
| Cognito | User Pool + Identity Pool | 50,000 MAUまで無料 |
| DynamoDB | Users Table, オンデマンド | 無料枠内 |

### DynamoDB Users Table設計

| 属性 | 型 | 説明 |
|------|-----|------|
| userId (PK) | String | Cognito sub |
| email | String | メールアドレス |
| nickname | String | ニックネーム（2-10文字） |
| authProvider | String | EMAIL / GOOGLE / X |
| linkedProviders | List | リンク済みプロバイダー |
| createdAt | String | ISO 8601 |
| updatedAt | String | ISO 8601 |
| lastLoginAt | String | ISO 8601 |

**GSI: nickname-index**
- PK: nickname
- 用途: ニックネーム一意性チェック
