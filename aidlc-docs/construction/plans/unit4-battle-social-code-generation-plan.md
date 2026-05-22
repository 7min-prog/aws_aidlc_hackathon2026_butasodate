# Code Generation Plan - Unit 4: バトル + ソーシャル

## ユニットコンテキスト
- **対象ストーリー**: FR-5（バトル）, FR-6（ソーシャル）
- **依存**: Unit 1（認証）, Unit 3（アバター - ステータス参照）
- **インターフェース**: WebSocket API + REST API
- **DBエンティティ**: Connections, MatchQueue, Matches, BattleHistory, Friends, FriendRequests, Rankings
- **パッケージバージョン**: AWS SDK 3.989.0, aws-cdk-lib 2.240.0, TypeScript 5.8.3

## コード生成ステップ

### Phase A: プロジェクト構造

- [ ] Step 1: battle-ws-handler プロジェクト初期化
- [ ] Step 2: social-handler プロジェクト初期化

### Phase B: バトルWebSocket実装

- [ ] Step 3: WebSocket接続管理（onConnect, onDisconnect）
- [ ] Step 4: マッチメイキング（requestMatch, cancelMatch）
- [ ] Step 5: バトル準備（respondInvite, setReady）
- [ ] Step 6: ターン実行エンジン（selectAction, executeTurn + ConditionExpression 2重実行防止）
- [ ] Step 7: ダメージ計算・勝敗判定ロジック

### Phase C: ソーシャルREST実装

- [ ] Step 8: フレンド管理（検索、申請、承認/拒否、一覧、削除）
- [ ] Step 9: ランキング・バトル履歴

### Phase D: インフラ（CDK）

- [ ] Step 10: Battle Social Stack（WebSocket API + REST + DynamoDB 7テーブル）

### Phase E: テスト

- [ ] Step 11: ターン実行エンジン単体テスト
- [ ] Step 12: ダメージ計算単体テスト
