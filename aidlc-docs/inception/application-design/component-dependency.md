# Component Dependency

## 依存関係マトリクス

### バックエンド内部依存

| コンポーネント | 依存先 | 関係 |
|--------------|--------|------|
| Recording Domain | Avatar Domain | ポイント加算時にアバター更新 |
| Health Sync Domain | Recording Domain | 不健康行動検出時に記録作成 |
| Health Sync Domain | Avatar Domain | 健康行動検出時にポイント減算 |
| Battle (WebSocket) | Avatar Domain | バトル時にステータス・スキル参照 |
| Admin Domain | Avatar Domain | ゲームデータ修正 |
| Admin Domain | Recording Domain | 記録データ参照 |

### フロントエンド → バックエンド依存

| FEモジュール | 通信先 | プロトコル |
|-------------|--------|-----------|
| FE-AUTH | Cognito | Cognito SDK |
| FE-RECORDING | BE-API (Recording) | REST |
| FE-HEALTH | BE-API (Health Sync) | REST |
| FE-AVATAR | BE-API (Avatar) | REST |
| FE-BATTLE | BE-WEBSOCKET | WebSocket |
| FE-BATTLE | BE-API (Avatar) | REST（準備時ステータス取得） |
| FE-SOCIAL | BE-API (Social) | REST |
| ADMIN-WEB | BE-API (Admin) | REST |

### フロントエンド内部依存

| モジュール | 依存先 | 理由 |
|-----------|--------|------|
| FE-RECORDING | FE-SHARED | API Client、認証トークン |
| FE-HEALTH | FE-SHARED | API Client |
| FE-AVATAR | FE-SHARED | API Client、共通ウィジェット |
| FE-BATTLE | FE-SHARED | API Client、WebSocket Client |
| FE-SOCIAL | FE-SHARED | API Client、OS共有シート |
| FE-AUTH | FE-SHARED | ルーティング、トークン保存 |

---

## データフロー

```text
┌─────────────────────────────────────────────────────────┐
│ Flutter App                                             │
│  ┌──────┐ ┌─────────┐ ┌──────┐ ┌──────┐ ┌──────┐     │
│  │ AUTH │ │RECORDING│ │AVATAR│ │BATTLE│ │SOCIAL│     │
│  └──┬───┘ └────┬────┘ └──┬───┘ └──┬───┘ └──┬───┘     │
│     │          │          │        │        │          │
│     └──────────┴──────────┴────────┴────────┘          │
│                        │ FE-SHARED (API Client)        │
└────────────────────────┼───────────────────────────────┘
                         │ REST              │ WebSocket
                         ▼                   ▼
┌────────────────────────────────┐  ┌───────────────────┐
│ API Gateway (REST)             │  │ API Gateway (WS)  │
│  /player/*  /admin/*           │  │                   │
└────────────┬───────────────────┘  └────────┬──────────┘
             ▼                               ▼
┌────────────────────────────────┐  ┌───────────────────┐
│ BE-API Lambda (Monolithic)     │  │ BE-WEBSOCKET      │
│  ┌─────────┐ ┌──────┐         │  │ Lambda            │
│  │Recording│ │Avatar│         │  │  ┌─────────────┐  │
│  │ Domain  │→│Domain│         │  │  │BattleService│  │
│  └─────────┘ └──────┘         │  │  └─────────────┘  │
│  ┌──────────┐ ┌──────┐        │  └────────┬──────────┘
│  │HealthSync│→│Social│        │           │
│  │  Domain  │ │Domain│        │           │
│  └──────────┘ └──────┘        │           │
│  ┌───────┐                    │           │
│  │ Admin │                    │           │
│  │Domain │                    │           │
│  └───────┘                    │           │
└────────────┬───────────────────┘           │
             ▼                               ▼
┌────────────────────────────────────────────────────────┐
│ DynamoDB                                               │
│  Users | Avatars | Records | Battles | Friends | Master│
└────────────────────────────────────────────────────────┘
             │
             ▼
┌────────────────────┐    ┌─────────────────┐
│ Amazon Cognito     │    │ S3 (Assets)     │
│ (認証・認可)        │    │ (AI生成画像/動画)│
└────────────────────┘    └─────────────────┘
```

---

## 通信パターン詳細

| 通信 | プロトコル | 認証 | 用途 |
|------|-----------|------|------|
| Flutter → REST API | HTTPS | Cognito JWT | 通常CRUD操作 |
| Flutter → WebSocket | WSS | Cognito JWT（接続時） | バトルリアルタイム |
| Admin → REST API | HTTPS | Cognito JWT（admin group） | 管理操作 |
| Lambda → DynamoDB | AWS SDK | IAM Role | データ永続化 |
| Lambda → S3 | AWS SDK | IAM Role | アセット取得 |
