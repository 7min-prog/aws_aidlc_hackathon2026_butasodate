# Infrastructure Design - Unit 4: バトル + ソーシャル

## AWSリソース構成

### API Gateway WebSocket API

| 設定項目 | 値 |
|---------|-----|
| API名 | buta-battle-ws-dev |
| ルートキー | $request.body.action |
| $connect | Lambda: battle-ws-handler |
| $disconnect | Lambda: battle-ws-handler |
| $default | Lambda: battle-ws-handler |
| 認証 | $connect時にクエリパラメータ `token` を検証 |
| idle timeout | 10分 |

### Lambda: battle-ws-handler

| 設定項目 | 値 |
|---------|-----|
| ランタイム | Node.js 24.x |
| メモリ | 256MB |
| タイムアウト | 10秒 |
| アーキテクチャ | arm64 |
| 環境変数 | CONNECTIONS_TABLE, MATCH_QUEUE_TABLE, MATCHES_TABLE, BATTLE_HISTORY_TABLE, RANKINGS_TABLE, WEBSOCKET_ENDPOINT |
| IAMロール | DynamoDB CRUD + API Gateway ManageConnections |

### Lambda: social-handler

| 設定項目 | 値 |
|---------|-----|
| ランタイム | Node.js 24.x |
| メモリ | 256MB |
| タイムアウト | 10秒 |
| アーキテクチャ | arm64 |
| 環境変数 | FRIENDS_TABLE, FRIEND_REQUESTS_TABLE, RANKINGS_TABLE, BATTLE_HISTORY_TABLE, USERS_TABLE |
| IAMロール | DynamoDB CRUD |

### REST API（既存API Gatewayに追加）

| メソッド | パス | 認証 | Lambda |
|---------|------|------|--------|
| GET | /social/friends | Cognito | social-handler |
| POST | /social/friends/search | Cognito | social-handler |
| POST | /social/friends/request | Cognito | social-handler |
| POST | /social/friends/respond | Cognito | social-handler |
| DELETE | /social/friends/{id} | Cognito | social-handler |
| GET | /social/friends/requests | Cognito | social-handler |
| GET | /rankings | Cognito | social-handler |
| GET | /rankings/me | Cognito | social-handler |
| GET | /battles/history | Cognito | social-handler |
| GET | /battles/history/{id} | Cognito | social-handler |

### DynamoDB テーブル

| テーブル名 | PK | GSI | キャパシティ |
|-----------|-----|-----|------------|
| buta-connections-dev | connectionId | userId-index (PK: userId) | オンデマンド |
| buta-match-queue-dev | userId | — | オンデマンド |
| buta-matches-dev | matchId | — | オンデマンド |
| buta-battle-history-dev | odataId | userId-index (PK: userId, SK: finishedAt) | オンデマンド |
| buta-friends-dev | odataId | userId-index (PK: userId) | オンデマンド |
| buta-friend-requests-dev | requestId | toUserId-index (PK: toUserId) | オンデマンド |
| buta-rankings-dev | userId | rank-index (PK: partition, SK: points DESC) | オンデマンド |

## CDKスタック構成

```text
infrastructure/lib/battle-social-stack.ts
├── API Gateway WebSocket API
│   ├── $connect / $disconnect / $default ルート
│   └── Lambda統合: battle-ws-handler
├── Lambda: battle-ws-handler
│   └── IAM: DynamoDB + ManageConnections
├── Lambda: social-handler
│   └── IAM: DynamoDB
├── REST API リソース追加（既存API Gatewayに）
│   └── /social/*, /rankings/*, /battles/*
└── DynamoDB Tables (7テーブル)
    ├── Connections
    ├── MatchQueue
    ├── Matches
    ├── BattleHistory
    ├── Friends
    ├── FriendRequests
    └── Rankings
```

## コスト見積もり（月額）

| サービス | 見積もり |
|---------|---------|
| API Gateway WebSocket | $0（100万メッセージまで無料） |
| API Gateway REST（追加分） | $0（無料枠内） |
| Lambda ×2 | $0（無料枠内） |
| DynamoDB ×7テーブル | $0（無料枠内） |
| **合計** | **$0（無料枠内）** |
