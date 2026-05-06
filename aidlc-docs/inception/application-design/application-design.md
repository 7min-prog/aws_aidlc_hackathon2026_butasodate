# Application Design

## 設計方針サマリー

| 項目 | 決定事項 |
|------|---------|
| FE構成 | Feature-first + 軽量クリーンアーキテクチャ |
| BE構成 | Monolithic Lambda (REST) + 専用Lambda (WebSocket) |
| バトル状態管理 | サーバー側完全管理 |
| AI画像/動画 | 事前生成（S3保存） |
| リアルタイム通知 | WebSocketはバトル専用、他はポーリング |
| API Gateway | 単一（パスプレフィックスでplayer/admin分離） |
| DB設計 | Table per Entity |

---

## システム構成概要

```text
┌─────────────────┐     ┌─────────────────┐
│  Flutter App    │     │  React Admin    │
│  (iOS/Android)  │     │  (Web)          │
└────────┬────────┘     └────────┬────────┘
         │ REST + WebSocket       │ REST
         ▼                        ▼
┌─────────────────────────────────────────┐
│         API Gateway                     │
│   REST: /player/*  /admin/*             │
│   WebSocket: wss://                     │
└────────┬──────────────────┬─────────────┘
         ▼                  ▼
┌─────────────────┐  ┌─────────────────┐
│  BE-API Lambda  │  │ BE-WS Lambda    │
│  (Monolithic)   │  │ (Battle)        │
└────────┬────────┘  └────────┬────────┘
         │                     │
         ▼                     ▼
┌─────────────────────────────────────────┐
│  DynamoDB (Table per Entity)            │
│  Users|Avatars|Records|Battles|Friends  │
└─────────────────────────────────────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌────────┐ ┌────────┐
│Cognito │ │  S3    │
│(認証)   │ │(Assets)│
└────────┘ └────────┘
```

---

## コンポーネント一覧

### フロントエンド（Flutter）
| ID | コンポーネント | 責務 | 対応FR |
|----|--------------|------|--------|
| FE-AUTH | 認証モジュール | 認証、セッション管理、プロフィール | FR-1 |
| FE-RECORDING | 行動記録モジュール | カテゴリ選択・記録、履歴、サマリー | FR-2 |
| FE-HEALTH | ヘルスデータ連携 | HealthKit/Health Connect連携、同期 | FR-3 |
| FE-AVATAR | アバター育成 | アバター表示、進化演出、ステータス | FR-4 |
| FE-BATTLE | バトル | マッチング、バトルUI、WebSocket通信 | FR-5 |
| FE-SOCIAL | ソーシャル | フレンド管理、SNS共有 | FR-6 |
| FE-SHARED | 共通 | API Client、認証トークン、共通UI | 全体 |

### バックエンド
| ID | コンポーネント | 責務 |
|----|--------------|------|
| BE-API | REST API Lambda | 全REST処理（内部ルーティング） |
| BE-WEBSOCKET | WebSocket Lambda | バトルリアルタイム通信 |
| BE-AUTH | Cognito | 認証・認可 |

### インフラ
| ID | コンポーネント | 責務 |
|----|--------------|------|
| INFRA-DB | DynamoDB | データ永続化（6テーブル） |
| INFRA-S3 | S3 | AI生成アセット保存 |
| INFRA-APIGW | API Gateway | エンドポイント管理 |

### 管理画面
| ID | コンポーネント | 責務 |
|----|--------------|------|
| ADMIN-WEB | React Web | ユーザー/ゲームデータ/マスターデータ管理 |

---

## サービス層

| サービス | 責務 | 主要連携 |
|---------|------|---------|
| RecordingService | 行動記録 + ポイント計算 | → AvatarService |
| AvatarService | アバター状態管理（成長/進化/退化） | ← Recording, HealthSync |
| HealthSyncService | ヘルスデータ同期 + 行動検出 | → Recording, Avatar |
| BattleService | バトルライフサイクル管理 | → AvatarService（参照） |
| SocialService | フレンド関係管理 | 独立 |
| AdminService | 管理CRUD | → Avatar, Recording |

---

## 詳細ドキュメント参照

- [components.md](./components.md) — コンポーネント定義と責務
- [component-methods.md](./component-methods.md) — メソッドシグネチャ
- [services.md](./services.md) — サービス定義とオーケストレーション
- [component-dependency.md](./component-dependency.md) — 依存関係と通信パターン
