# Code Generation Plan - Unit 1: 認証基盤

## ユニットコンテキスト
- **対象ストーリー**: FR-1（ユーザー認証）
- **依存**: なし（最初のユニット）
- **インターフェース**: REST API（/auth/*, /users/*）
- **DBエンティティ**: Users Table
- **サービス境界**: 認証・ユーザープロフィール管理

## コード生成ステップ

### Phase A: プロジェクト構造セットアップ

- [x] Step 1: CDKプロジェクト初期化（`infrastructure/`）
- [x] Step 2: Lambdaプロジェクト初期化（`backend/auth-handler/`）

### Phase B: バックエンド実装

- [x] Step 3: Lambda エントリポイント + ルーティング（`backend/auth-handler/src/index.ts`）
- [x] Step 4: サインアップハンドラー（`backend/auth-handler/src/handlers/signup.ts`）
- [x] Step 5: ログイン/ログアウトハンドラー（`backend/auth-handler/src/handlers/login.ts`, `logout.ts`）
- [x] Step 6: トークンリフレッシュハンドラー（`backend/auth-handler/src/handlers/refresh.ts`）
- [x] Step 7: プロフィールハンドラー（`backend/auth-handler/src/handlers/profile.ts`）
- [x] Step 8: ユーティリティ（`backend/auth-handler/src/utils/`）

### Phase C: インフラ（CDK）

- [x] Step 9: Auth Stack（Cognito + DynamoDB + Lambda + API Gateway）

### Phase D: ドキュメント

- [x] Step 10: コード生成サマリー（`aidlc-docs/construction/unit1-auth/code/`）

## 生成ファイル一覧

```text
infrastructure/
├── bin/app.ts
├── lib/auth-stack.ts
├── package.json
├── tsconfig.json
└── cdk.json

backend/auth-handler/
├── src/
│   ├── index.ts
│   ├── handlers/
│   │   ├── signup.ts
│   │   ├── confirm.ts
│   │   ├── login.ts
│   │   ├── logout.ts
│   │   ├── refresh.ts
│   │   └── profile.ts
│   └── utils/
│       ├── cognito-client.ts
│       ├── dynamo-client.ts
│       └── response.ts
├── package.json
└── tsconfig.json
```
