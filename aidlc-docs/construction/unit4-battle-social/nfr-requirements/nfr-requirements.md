# NFR Requirements - Unit 4: バトル + ソーシャル

## 1. パフォーマンス要件

| ID | 要件 | 目標値 | 根拠 |
|----|------|--------|------|
| PERF-1 | WebSocketメッセージ配信遅延 | 1秒以内 | ハッカソンデモ向け |
| PERF-2 | ターン実行処理（ダメージ計算+結果配信） | 1秒以内 | 両者選択完了→結果表示 |
| PERF-3 | マッチメイキング応答 | 2秒以内 | 待機中プレイヤー検索 |
| PERF-4 | フレンド一覧取得 | 500ms以内 | REST API |
| PERF-5 | ランキング取得 | 500ms以内 | REST API |

## 2. スケーラビリティ要件

| ID | 要件 | 目標値 | 根拠 |
|----|------|--------|------|
| SCALE-1 | 同時バトル数 | 〜5試合 | ハッカソンデモ規模 |
| SCALE-2 | 同時WebSocket接続数 | 〜10 | 5試合×2人 |
| SCALE-3 | フレンド上限 | 無制限 | ユーザー要件 |
| SCALE-4 | バトル履歴保存 | 無期限 | ユーザー要件 |

## 3. 可用性要件

| ID | 要件 | 目標値 | 根拠 |
|----|------|--------|------|
| AVAIL-1 | WebSocket接続安定性 | API Gatewayマネージド依存 | 自動再接続はクライアント側で実装 |
| AVAIL-2 | 切断検出 | 10秒以内 | API Gateway idle timeout |
| AVAIL-3 | バトル中データ永続性 | DynamoDB即時書き込み | ターンごとに状態保存 |

## 4. セキュリティ要件

| ID | 要件 | 実装方針 | 根拠 |
|----|------|----------|------|
| SEC-1 | WebSocket認証 | 接続時にCognitoトークン検証 | 不正接続防止 |
| SEC-2 | 行動選択の改ざん防止 | サーバー側でバリデーション | クライアント信頼しない |
| SEC-3 | ターン実行はサーバー側のみ | ダメージ計算をクライアントに委ねない | チート防止 |
| SEC-4 | レート制限 | 1接続あたり10msg/sec | スパム防止 |

## 5. テックスタック

| レイヤー | 技術 | 選定理由 |
|---------|------|----------|
| WebSocket | API Gateway WebSocket API | サーバーレス、コスト最小、他ユニットと統一 |
| バトルロジック | Lambda (Node.js 20.x) | ターン実行、ダメージ計算 |
| 接続管理 | DynamoDB (Connections Table) | connectionId ↔ userId マッピング |
| バトル状態 | DynamoDB (Matches Table) | バトル中の状態保存 |
| マッチメイキング | DynamoDB (MatchQueue Table) | 待機中プレイヤーキュー |
| ソーシャルAPI | Lambda (REST、既存API Gatewayに追加) | フレンド管理 |
| ランキング | DynamoDB (Rankings Table) | ポイント順GSI |
| フロントWebSocket | web_socket_channel (Flutter) | Flutter標準WebSocketパッケージ |

## 6. コスト見積もり（月額）

| サービス | 見積もり |
|---------|---------|
| API Gateway WebSocket | $0（100万メッセージまで無料） |
| Lambda | $0（無料枠内） |
| DynamoDB（追加テーブル） | $0（無料枠内） |
| **合計** | **$0（無料枠内）** |
