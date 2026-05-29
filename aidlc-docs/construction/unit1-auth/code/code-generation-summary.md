# Code Generation Summary - Unit 1: 認証基盤

## 生成ファイル一覧

### infrastructure/ (CDK)
| ファイル | 説明 |
|---------|------|
| bin/app.ts | CDKエントリポイント |
| lib/auth-stack.ts | 認証基盤スタック（Cognito+DynamoDB+Lambda+API GW） |
| package.json | CDK依存関係 |
| tsconfig.json | TypeScript設定 |
| cdk.json | CDK設定 |

### backend/auth-handler/ (Lambda)
| ファイル | 説明 |
|---------|------|
| src/index.ts | エントリポイント（パスベースルーティング） |
| src/handlers/signup.ts | サインアップ + 確認コード + 再送 |
| src/handlers/login.ts | ログイン（トークン返却+lastLoginAt更新） |
| src/handlers/logout.ts | ログアウト（globalSignOut） |
| src/handlers/refresh.ts | トークンリフレッシュ |
| src/handlers/profile.ts | プロフィール GET/POST/PUT |
| src/utils/cognito-client.ts | Cognito SDKクライアント |
| src/utils/dynamo-client.ts | DynamoDB Documentクライアント |
| src/utils/response.ts | レスポンスヘルパー（CORS対応） |
| package.json | Lambda依存関係 |
| tsconfig.json | TypeScript設定 |

## APIエンドポイント

| メソッド | パス | 認証 | 機能 |
|---------|------|------|------|
| POST | /auth/signup | なし | メールサインアップ |
| POST | /auth/confirm | なし | 確認コード検証 |
| POST | /auth/resend-code | なし | 確認コード再送 |
| POST | /auth/login | なし | ログイン |
| POST | /auth/logout | Cognito | ログアウト |
| POST | /auth/refresh | なし | トークンリフレッシュ |
| GET | /users/me | Cognito | プロフィール取得 |
| POST | /users/profile | Cognito | ニックネーム初期設定 |
| PUT | /users/profile | Cognito | プロフィール更新 |

## インフラ構成
- Cognito UserPool（メール認証、パスワードポリシー）
- DynamoDB Users Table（オンデマンド、nickname-index GSI）
- Lambda（Node.js 20.x、ARM64、256MB）
- API Gateway REST（100 req/sec制限、Cognito Authorizer）
