# NFR Design Patterns - Unit 4: バトル + ソーシャル

## 1. WebSocket通信パターン

### 接続ライフサイクル
```text
[Flutter] → wss://xxx.execute-api.../dev
    │
    ▼ $connect（Cognitoトークン付き）
[API Gateway WebSocket] → [Lambda: onConnect]
    │  connectionId + userId を DynamoDB Connections に保存
    ▼
[接続確立] ← 200 OK

[バトル中メッセージ]
    Client → { action: "selectAction", data: {...} } → Lambda処理 → 相手に配信

[切断]
    $disconnect → [Lambda: onDisconnect] → Connections削除 + バトル中なら自動敗北
```

### メッセージタイプ（Client → Server）
| action | 用途 |
|--------|------|
| requestMatch | マッチメイキング申請 |
| cancelMatch | マッチング中止 |
| respondInvite | フレンド対戦招待応答 |
| setReady | バトル準備完了（スキルセット） |
| selectAction | ターン行動選択 |

### メッセージタイプ（Server → Client）
| type | 用途 |
|------|------|
| matchFound | マッチング成立 |
| battleStart | バトル開始 |
| turnResult | ターン実行結果 |
| battleEnd | バトル終了・結果 |
| opponentDisconnected | 相手切断通知 |
| friendInvite | フレンド対戦招待受信 |

## 2. バトル状態管理パターン

### ターンタイムアウト管理
```text
[両者行動選択フェーズ開始]
    │
    ├─ クライアント: 20秒タイマー表示
    │   └─ 時間切れ → 自動で「防御」をselectActionとして送信
    │
    └─ サーバー: ターン開始時刻を記録
        └─ 30秒経過しても片方未選択 → デフォルト「防御」を適用してターン実行
```

### ターン実行フロー
```text
[Player A selectAction] → DynamoDBに保存
[Player B selectAction] → DynamoDBに保存
    │
    ▼ 両者揃った
[Lambda: executeTurn]
    ├─ ★ConditionExpression: turnExecuted = false（2重実行防止）
    ├─ 素早さ比較 → 行動順決定
    ├─ 先攻の行動実行（ダメージ計算、バフ適用）
    ├─ 後攻の行動実行
    ├─ HP/バフ状態更新 → DynamoDB書き込み
    ├─ 勝敗判定
    └─ turnResult を両者に WebSocket配信
    
※ConditionExpressionが失敗（=既に実行済み）→ 処理スキップ
```

### バトル全体タイムアウト（5分）
- バトル開始時刻をMatchレコードに記録
- 各ターン実行時に経過時間チェック
- 5分超過 → 残HP割合で勝敗判定 → battleEnd配信

## 3. セキュリティパターン

| 脅威 | 対策 |
|------|------|
| 不正接続 | $connect時にクエリパラメータのCognitoトークンを検証 |
| 行動改ざん | サーバー側でスキルID有効性・クールダウン検証 |
| ダメージ改ざん | ダメージ計算は100%サーバー側 |
| 連打スパム | 1ターンにつき1回のみ行動受付（重複無視） |
| 切断悪用 | 切断=自動敗北（ランキングポイント減少） |

## 4. コスト保護パターン

| 項目 | 設定 |
|------|------|
| WebSocket idle timeout | 10分（API Gatewayデフォルト） |
| メッセージサイズ上限 | 32KB（API Gatewayデフォルト） |
| Lambda同時実行 | デフォルト（1000） |
| DynamoDB | オンデマンド |
