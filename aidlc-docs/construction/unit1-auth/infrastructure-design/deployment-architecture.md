# Deployment Architecture - Unit 1: 認証基盤

## CDKスタック構成

```text
aws_aidlc_hackathon/
├── infrastructure/                  # CDKプロジェクト
│   ├── bin/
│   │   └── app.ts                  # CDKエントリポイント
│   ├── lib/
│   │   ├── auth-stack.ts           # 認証基盤スタック
│   │   └── shared-stack.ts         # 共有リソース（将来のUnit用）
│   ├── package.json
│   ├── tsconfig.json
│   └── cdk.json
├── backend/                         # Lambda関数
│   └── auth-handler/
│       ├── src/
│       │   ├── index.ts            # エントリポイント（ルーティング）
│       │   ├── handlers/
│       │   │   ├── signup.ts
│       │   │   ├── confirm.ts
│       │   │   ├── login.ts
│       │   │   ├── logout.ts
│       │   │   ├── refresh.ts
│       │   │   └── profile.ts
│       │   └── utils/
│       │       └── cognito-client.ts
│       ├── package.json
│       └── tsconfig.json
└── frontend/                        # Flutter アプリ（別Unit）
```

## CDK auth-stack.ts 構成

```text
AuthStack
├── CognitoUserPool
│   ├── UserPoolClient (Flutter用)
│   ├── IdentityProvider: Google
│   ├── IdentityProvider: X (Twitter)
│   └── UserPoolDomain
├── DynamoDB UsersTable
│   └── GSI: nickname-index
├── Lambda: auth-handler
│   ├── IAM Role (Cognito + DynamoDB)
│   └── Environment Variables
└── API Gateway (REST)
    ├── CognitoAuthorizer
    ├── Resources: /auth/*, /users/*
    └── Throttling: 100 req/sec
```

## デプロイ手順

```bash
# 1. CDK初期化（初回のみ）
cd infrastructure
npm install
cdk bootstrap

# 2. デプロイ
cdk deploy AuthStack

# 3. 出力値確認（API URL, Cognito設定）
cdk output
```

## 環境

| 項目 | 値 |
|------|-----|
| 環境数 | 1（dev） |
| リージョン | ap-northeast-1（東京） |
| アカウント | 個人AWSアカウント |
| 命名規則 | buta-{リソース名}-dev |
