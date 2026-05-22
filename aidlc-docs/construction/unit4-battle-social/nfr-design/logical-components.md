# Logical Components - Unit 4: バトル + ソーシャル

## システム構成図

```text
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ BattleScreen │  │ FriendScreen │  │ RankingScreen│  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │ WebSocket        │ REST             │ REST     │
└─────────┼──────────────────┼─────────────────┼──────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────┐  ┌─────────────────────────────────┐
│ API Gateway     │  │ API Gateway (REST)               │
│ WebSocket API   │  │ /social/*, /rankings/*           │
└────────┬────────┘  └──────────────┬──────────────────┘
         │                          │
         ▼                          ▼
┌─────────────────┐  ┌─────────────────────────────────┐
│ Lambda:         │  │ Lambda: social-handler           │
│ battle-ws       │  │ (フレンド管理、ランキング)         │
│ (onConnect,     │  └──────────────┬──────────────────┘
│  onDisconnect,  │                 │
│  onMessage)     │                 ▼
└────────┬────────┘  ┌─────────────────────────────────┐
         │           │ DynamoDB                         │
         ▼           │ - Friends Table                  │
┌─────────────────┐  │ - FriendRequests Table           │
│ DynamoDB        │  │ - Rankings Table (GSI: points)   │
│ - Connections   │  └─────────────────────────────────┘
│ - MatchQueue    │
│ - Matches       │
│ - BattleHistory │
└─────────────────┘
```

## Lambda構成

### battle-ws（WebSocket Lambda）
| ルート | 処理 |
|--------|------|
| $connect | トークン検証、Connectionsテーブルに保存 |
| $disconnect | Connections削除、バトル中なら自動敗北処理 |
| requestMatch | MatchQueueに追加、マッチング試行 |
| cancelMatch | MatchQueueから削除 |
| respondInvite | フレンド対戦招待の承諾/拒否 |
| setReady | スキル・アイテムセット保存 |
| selectAction | 行動選択保存、両者揃ったらターン実行 |

### social-handler（REST Lambda）
| エンドポイント | 処理 |
|--------------|------|
| GET /social/friends | フレンド一覧（オンライン状態付き） |
| POST /social/friends/search | ニックネーム検索 |
| POST /social/friends/request | フレンド申請送信 |
| POST /social/friends/respond | 申請承認/拒否 |
| DELETE /social/friends/:id | フレンド削除 |
| GET /social/friends/requests | 未処理申請一覧 |
| GET /rankings | ランキング取得 |
| GET /rankings/me | 自分の順位取得 |
| GET /battles/history | バトル履歴一覧 |
| GET /battles/history/:id | バトル詳細 |

## DynamoDBテーブル設計

### Connections Table
| 属性 | 型 | 説明 |
|------|-----|------|
| connectionId (PK) | String | WebSocket接続ID |
| userId | String | ユーザーID |
| connectedAt | String | 接続時刻 |

### MatchQueue Table
| 属性 | 型 | 説明 |
|------|-----|------|
| userId (PK) | String | 待機中ユーザーID |
| level | Number | プレイヤーレベル（マッチング条件） |
| connectionId | String | WebSocket接続ID |
| queuedAt | String | キュー登録時刻 |

### Matches Table
| 属性 | 型 | 説明 |
|------|-----|------|
| matchId (PK) | String | 対戦ID (ULID) |
| player1Id | String | プレイヤー1 |
| player2Id | String | プレイヤー2 |
| status | String | PREPARING / IN_PROGRESS / FINISHED |
| currentTurn | Number | 現在ターン |
| battleState | Map | 両者のHP/バフ/スキル状態 |
| startedAt | String | 開始時刻 |
| turnStartedAt | String | 現ターン開始時刻 |

### BattleHistory Table
| 属性 | 型 | 説明 |
|------|-----|------|
| odataId (PK) | String | `{userId}#{matchId}` |
| matchId | String | 対戦ID |
| odataUserId (GSI PK) | String | ユーザーID |
| opponentId | String | 対戦相手 |
| result | String | WIN / LOSE / DRAW |
| pointChange | Number | ランキングポイント増減 |
| finishedAt | String | 終了時刻 |

### Friends Table
| 属性 | 型 | 説明 |
|------|-----|------|
| odataId (PK) | String | `{userId}#{friendId}` |
| userId (GSI PK) | String | ユーザーID |
| friendId | String | フレンドID |
| createdAt | String | フレンド成立日時 |

### FriendRequests Table
| 属性 | 型 | 説明 |
|------|-----|------|
| requestId (PK) | String | 申請ID (ULID) |
| fromUserId | String | 申請者 |
| toUserId (GSI PK) | String | 被申請者 |
| status | String | PENDING / ACCEPTED / REJECTED |
| createdAt | String | 申請日時 |

### Rankings Table
| 属性 | 型 | 説明 |
|------|-----|------|
| userId (PK) | String | ユーザーID |
| points | Number | ランキングポイント |
| wins | Number | 勝利数 |
| losses | Number | 敗北数 |
| updatedAt | String | 最終更新 |

**GSI: points-index** (PK: fixed partition key, SK: points DESC) → ランキング順取得
