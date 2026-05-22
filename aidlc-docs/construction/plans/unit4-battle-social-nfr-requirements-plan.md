# NFR Requirements Plan - Unit 4: バトル + ソーシャル

## 対象
- Unit 4: バトル + ソーシャル（FR-5, FR-6）
- Functional Design成果物を基にNFR要件を定義

## 計画ステップ

- [x] 1. パフォーマンス要件定義（WebSocket遅延、ターン実行速度）
- [x] 2. スケーラビリティ要件定義（同時バトル数、WebSocket接続数）
- [x] 3. 可用性要件定義（バトル中の接続安定性）
- [x] 4. セキュリティ要件定義（不正行為防止、WebSocket認証）
- [x] 5. テックスタック詳細決定（WebSocket実装方式）
- [x] 6. NFR要件ドキュメント生成

## 質問

### Q1: WebSocketのレイテンシ目標
バトル中のターン結果通知の遅延許容はどの程度ですか？

A) 1秒以内（ハッカソンデモ向け、緩め）
B) 500ms以内（快適なリアルタイム体験）
C) 200ms以内（格闘ゲーム並み）

[Answer]:A

### Q2: 同時バトル数の想定
同時に行われるバトルの最大数は？

A) 〜5試合（ハッカソンデモ規模）
B) 〜50試合（小規模リリース）

[Answer]:特に考慮不要、懸念を教えてください

### Q3: WebSocket実装方式
WebSocketの実装方式はどうしますか？

A) API Gateway WebSocket + Lambda（サーバーレス、コスト最小）
B) AppSync（GraphQL Subscriptions、マネージド）
C) おすすめを教えて

[Answer]:A
