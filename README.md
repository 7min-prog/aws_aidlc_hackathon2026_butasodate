# 🐷 ぶたそだて 〜人をダメにする育成RPG〜

不健康な行動をポジティブに記録する、逆転発想の"ぶた"育成ヘルスケアゲームアプリ。

## コンセプト

従来のヘルスケアアプリは「正しい行動」を求めるため、多くのユーザーが数ヶ月以内に離脱します。本アプリは発想を転換し、**深夜ラーメン・運動サボり・夜更かし**などの「ダメな行動」を記録すると、自分の分身である"ぶた"キャラクターが喜び、まるまると成長します。

- 🍜 食べて、寝て、サボって、育てる
- 🐖 ダメな自分を映したアバターが進化
- ⚔️ 育てたアバター同士でリアルタイムバトル
- 📊 Apple Health / Google Fit 連携で自動記録

## アーキテクチャ

```
┌─────────────┐     ┌──────────────────────────────────────┐
│  Flutter App │────▶│  API Gateway (REST / WebSocket)       │
│  (iOS/Android/Web) │     ├── Auth Lambda (Cognito)         │
└─────────────┘     │     ├── Recording Lambda (DynamoDB)    │
                    │     ├── Avatar Lambda (DynamoDB)       │
┌─────────────┐     │     ├── Battle WebSocket Lambda        │
│  Admin Panel │────▶│     ├── Social Lambda                 │
│  (React SPA) │     │     └── Admin Lambda (S3)             │
└─────────────┘     └──────────────────────────────────────┘
```

**AWS サービス**: API Gateway, Lambda, DynamoDB, Cognito, S3, CloudFront

## ディレクトリ構造

```
├── frontend/          # Flutter アプリ (iOS/Android/Web)
├── backend/           # Lambda ハンドラー (TypeScript)
│   ├── auth-handler/
│   ├── recording-handler/
│   ├── avatar-handler/
│   ├── battle-ws-handler/
│   ├── social-handler/
│   └── admin-handler/
├── infrastructure/    # AWS CDK (5 stacks)
├── admin/             # 管理画面 (React + Vite)
├── mock-server/       # 開発用モックサーバー
├── design/            # Penpot デザインファイル
├── docs/              # 技術ドキュメント (OpenAPI, ER図)
├── aidlc-docs/        # AI-DLC ワークフロードキュメント
└── tools/             # 開発ツール
```

## セットアップ

### Backend

```bash
cd backend/auth-handler && npm install
cd ../recording-handler && npm install
cd ../avatar-handler && npm install
cd ../battle-ws-handler && npm install
cd ../social-handler && npm install
cd ../admin-handler && npm install
```

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

### Infrastructure

```bash
cd infrastructure
npm install
npx cdk synth
npx cdk deploy --all
```

## テスト

```bash
# Backend (329 tests, 90%+ coverage)
cd backend/auth-handler && npm test

# Frontend (90%+ coverage)
cd frontend && flutter test

# Infrastructure (28 assertions)
cd infrastructure && npx jest

# E2E (32 tests)
cd frontend/e2e && npx playwright test
```

## 技術スタック

| レイヤー | 技術 |
|---------|------|
| Frontend | Flutter 3.44, Riverpod, GoRouter, Dio |
| Backend | TypeScript, Hono, AWS SDK v3 |
| Infrastructure | AWS CDK (TypeScript) |
| Database | DynamoDB (PAY_PER_REQUEST) |
| Auth | Amazon Cognito |
| CI/CD | GitHub Actions |
| Design | Penpot (ピクセルアート) |

## 開発手法

本プロジェクトは [AI-DLC (AI-Driven Development Life Cycle)](https://github.com/awslabs/aidlc-workflows) に基づき、AIエージェントと協調して設計・実装を行いました。

## License

MIT
