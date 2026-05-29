# 🐷 ぶたそだて 〜人をダメにする育成RPG〜

「不健康な行動」をポジティブに記録できる、逆転発想の"ぶた"育成ヘルスケアゲームアプリです。

## コンセプト

従来のヘルスケアアプリは「正しい行動」を求めるため、多くのユーザーが数ヶ月以内に離脱してしまいます。

本アプリは発想を転換し、**ダメな自分を愛せる**仕組みを提供します：

- 🍜 深夜ラーメンを食べたら → ぶたが喜ぶ
- 😴 運動をサボるほど → ぶたがまるまると成長
- ⚖️ 体重・BMIが大きくなるほど → アバターが進化
- ⚔️ 育てたぶたをユーザー同士で戦わせることも可能

**食べて、寝て、サボって、育てる。**

## 主な機能

| 機能 | 説明 |
|------|------|
| 記録 | 不健康な行動（深夜飯、運動サボりなど）を記録 |
| 育成 | 記録に応じてぶたアバターが成長・進化 |
| バトル | 育てたぶたで他ユーザーとリアルタイム対戦 |
| ヘルスケア連携 | Apple Health / Google Fit からデータ連携 |
| フレンド | フレンド検索・追加でソーシャル要素 |

## 技術スタック

### フロントエンド

- **Flutter** (Dart) — iOS / Android / Web 対応
- 状態管理: Riverpod
- ルーティング: GoRouter
- ピクセルアートUI（DotGothic16 / PressStart2P フォント）

### バックエンド

- **AWS Lambda** (TypeScript / Node.js)
  - auth-handler — 認証
  - avatar-handler — アバター管理
  - recording-handler — 記録管理
  - battle-ws-handler — バトル (WebSocket)
  - social-handler — フレンド機能
  - admin-handler — 管理機能

### インフラ

- **AWS CDK** (TypeScript)
- Amazon Cognito（認証）
- Amazon DynamoDB（データストア）
- Amazon API Gateway（REST / WebSocket）
- AWS Lambda

## プロジェクト構成

```text
├── frontend/          # Flutter アプリ
├── backend/           # Lambda ハンドラー群
├── infrastructure/    # AWS CDK スタック
├── mock-server/       # 開発用モックサーバー (Hono)
├── admin/             # 管理画面 (Vite + TypeScript)
└── design/            # デザイン資料
```

## セットアップ

### フロントエンド

```bash
cd frontend
flutter pub get
flutter run
```

### モックサーバー

```bash
cd mock-server
npm install
npm run dev
```

### インフラ（デプロイ）

```bash
cd infrastructure
npm install
npx cdk deploy --all
```

## 開発環境

- Flutter SDK >= 3.9.0
- Node.js >= 18
- AWS CDK CLI

## 注意事項

本リポジトリはドキュメント提出用です。CI/CD パイプラインは動作しません。

開発用リポジトリ: https://github.com/furanobo/aws_aidlc_hackathon

## ライセンス

MIT License
