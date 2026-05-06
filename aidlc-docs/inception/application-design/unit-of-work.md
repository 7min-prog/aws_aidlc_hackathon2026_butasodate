# Unit of Work

## 分割方針
- **粒度**: 機能グループ単位（5ユニット）
- **チーム**: 4人
- **開発方式**: ユニット1→2→3→4は全員集中の順次開発。ユニット5は1人がユニット2以降で並行着手
- **コード構成**: モノレポ（flutter_app/, backend/, admin_web/, infra/）

---

## ユニット定義

### ユニット1: 認証基盤
- **対応FR**: FR-1
- **責務**: ユーザー認証（メール、Google、X）、セッション管理、プロフィール設定
- **コンポーネント**: FE-AUTH, BE-AUTH(Cognito), BE-API(Auth routing)
- **成果物**: ログイン/サインアップ画面、Cognito設定、認証ミドルウェア
- **完了条件**: ログイン→トークン取得→認証付きAPI呼び出しが動作する

### ユニット2: 行動記録 + ヘルスデータ連携
- **対応FR**: FR-2, FR-3
- **責務**: 不健康行動の手動記録、ヘルスデータ同期、自動検出、ポイント計算
- **コンポーネント**: FE-RECORDING, FE-HEALTH, BE-API(Recording/HealthSync Domain)
- **成果物**: 記録画面、履歴画面、ヘルス設定画面、起動時サマリー、RecordingService, HealthSyncService
- **完了条件**: 行動記録→ポイント加算、ヘルスデータ同期→自動検出が動作する

### ユニット3: アバター育成
- **対応FR**: FR-4
- **責務**: アバター生成、成長・進化・退化、スキル習得、ステータス管理、AI画像表示
- **コンポーネント**: FE-AVATAR, BE-API(Avatar Domain), INFRA-S3
- **成果物**: ホーム画面（アバター表示）、進化演出、ステータス画面、AvatarService、ドット絵スプライトシート（Flameで再生）
- **完了条件**: ポイント加算→レベルアップ→進化、ポイント減算→退化が動作する

### ユニット4: バトル + ソーシャル
- **対応FR**: FR-5, FR-6
- **責務**: リアルタイムバトル、マッチメイキング、フレンド管理、SNS共有
- **コンポーネント**: FE-BATTLE, FE-SOCIAL, BE-WEBSOCKET, BE-API(Social Domain)
- **成果物**: バトル画面、フレンド画面、WebSocket Lambda、BattleService, SocialService
- **完了条件**: マッチング→バトル→結果表示、フレンド申請→承認→対戦が動作する

### ユニット5: 管理画面
- **対応FR**: FR-7
- **責務**: ユーザー管理、ゲームデータ管理、マスターデータ管理
- **コンポーネント**: ADMIN-WEB, BE-API(Admin Domain)
- **成果物**: React管理画面、Admin API
- **完了条件**: ユーザー一覧/詳細/編集/停止、マスターデータCRUDが動作する
- **備考**: ユニット2以降で1人が並行着手

---

## コード構成（モノレポ）

```text
/
├── flutter_app/          # Flutter モバイルアプリ
│   └── lib/
│       ├── features/
│       │   ├── auth/         # ユニット1
│       │   ├── recording/    # ユニット2
│       │   ├── health/       # ユニット2
│       │   ├── avatar/       # ユニット3
│       │   ├── battle/       # ユニット4
│       │   └── social/       # ユニット4
│       └── shared/           # 共通（API Client等）
├── backend/              # Lambda バックエンド
│   ├── src/
│   │   ├── domains/
│   │   │   ├── auth/         # ユニット1
│   │   │   ├── recording/    # ユニット2
│   │   │   ├── health_sync/  # ユニット2
│   │   │   ├── avatar/       # ユニット3
│   │   │   ├── battle/       # ユニット4
│   │   │   ├── social/       # ユニット4
│   │   │   └── admin/        # ユニット5
│   │   ├── services/         # サービス層
│   │   └── shared/           # 共通ユーティリティ
│   └── websocket/            # WebSocket Lambda（ユニット4）
├── admin_web/            # React 管理画面（ユニット5）
├── infra/                # IaC（CDK等）
└── aidlc-docs/           # ドキュメント
```
