# Unit 4: バトル + ソーシャル - ビジネスロジックモデル

## バトルサービス フロー

### 1. マッチメイキングフロー

```mermaid
flowchart TD
    A[requestMatch] --> B{type?}
    B -->|RANDOM| C[MatchQueueに登録]
    C --> D{条件に合う相手を検索 BR-8}
    D -->|見つかった| E[Match作成 PREPARING]
    E --> F[両者にWebSocket通知]
    D -->|見つからない| G[待機継続]
    G --> H{30秒経過?}
    H -->|Yes| I[タイムアウト通知]
    H -->|No| D
    B -->|FRIEND| J[FriendInvite作成 PENDING]
    J --> K[相手にWebSocket通知]
```

### 2. バトル実行フロー

```mermaid
flowchart TD
    Start[バトル開始 PREPARING→IN_PROGRESS] --> TurnLoop

    subgraph TurnLoop[ターンループ 5分制限]
        Select[行動選択フェーズ 20秒] --> TimeCheck{20秒経過?}
        TimeCheck -->|未選択| AutoDefend[自動で防御選択]
        TimeCheck -->|選択済み| BothReady{両者選択完了?}
        AutoDefend --> BothReady
        BothReady -->|Yes| Execute[executeTurn]
        Execute --> SpeedOrder[素早さ順決定 BR-4]
        SpeedOrder --> FirstAction[先攻行動実行]
        FirstAction --> FirstSkill{行動種別?}
        FirstSkill -->|SKILL| DmgCalc[ダメージ計算 BR-1,BR-2 / バフ適用 BR-3]
        FirstSkill -->|DEFEND| DefFlag[被ダメ半減フラグ]
        DmgCalc --> CheckKO1{後攻HP≤0?}
        DefFlag --> CheckKO1
        CheckKO1 -->|Yes| KO[KO判定]
        CheckKO1 -->|No| SecondAction[後攻行動実行]
        SecondAction --> TurnEnd[ターン終了処理: バフ減少, CD減少]
        TurnEnd --> SendResult[TurnResult送信]
        SendResult --> WinCheck{勝敗判定 BR-6}
        WinCheck -->|継続| Select
    end

    WinCheck -->|KO| BattleEnd
    TurnLoop -->|5分経過| Timeout[TIMEOUT判定 BR-6]
    TurnLoop -->|切断検出| Disconnect[DISCONNECT判定 BR-11]
    Timeout --> BattleEnd
    Disconnect --> BattleEnd
    KO --> BattleEnd

    BattleEnd[バトル終了] --> CalcRank[ランキングポイント計算 BR-7]
    CalcRank --> SaveHistory[BattleHistory保存]
    SaveHistory --> UpdateRank[RankingEntry更新]
    UpdateRank --> SendMatchResult[MatchResult送信]
```

### 3. ランキング更新フロー

```mermaid
flowchart TD
    A[updateRanking] --> B{finishReason?}
    B -->|DISCONNECT| C[勝者: ポイント変動なし]
    C --> D[敗者: 通常の敗北ポイント減少]
    B -->|DRAW| E[両者: Elo計算 期待値0.5]
    B -->|KO / TIMEOUT| F[勝者: Elo計算 実績1.0]
    F --> G[敗者: Elo計算 実績0.0]
```

---

## ソーシャルサービス フロー

### 4. フレンド申請フロー

```mermaid
flowchart TD
    A[sendFriendRequest] --> V{バリデーション BR-12}
    V -->|自分自身| Err1[エラー]
    V -->|既にフレンド| Err2[エラー]
    V -->|既に申請済み| Err3[エラー]
    V -->|OK| Check{相手からの申請が存在?}
    Check -->|Yes| Auto[自動承認: Friendship作成, 両申請ACCEPTED]
    Check -->|No| Create[FriendRequest作成 PENDING]
    Auto --> Notify[相手に通知]
    Create --> Notify
```

### 5. フレンド一覧取得フロー

```mermaid
flowchart TD
    A[getFriends] --> B[Friendshipテーブルから全フレンド取得]
    B --> C[各フレンドのUserPresence取得]
    C --> D[isOnline計算 BR-13]
    D --> E[オンライン→オフライン順ソート]
    E --> F[レスポンス返却]
```

### 6. SNS共有フロー（フロントエンド主導）

```mermaid
flowchart TD
    A[share] --> B[テキスト生成 BR-14テンプレート]
    B --> C[アバター画像URL取得]
    C --> D[X Intent URL生成]
    D --> E{Xアプリインストール済み?}
    E -->|Yes| F[X投稿画面起動]
    E -->|No| G[OS共有シート]
```

---

## WebSocket メッセージ定義

### クライアント → サーバー
| type | payload | 説明 |
|------|---------|------|
| REQUEST_MATCH | { type: RANDOM } | ランダムマッチ申請 |
| CANCEL_MATCH | {} | マッチングキャンセル |
| INVITE_FRIEND | { targetUserId } | フレンド対戦招待 |
| RESPOND_INVITE | { inviteId, accept } | 招待応答 |
| SET_READY | { matchId, skills[] } | バトル準備完了 |
| SELECT_ACTION | { matchId, action } | ターン行動選択 |
| HEARTBEAT | {} | 生存確認 |

### サーバー → クライアント
| type | payload | 説明 |
|------|---------|------|
| MATCH_FOUND | { matchId, opponent } | マッチ成立 |
| MATCH_TIMEOUT | {} | マッチングタイムアウト |
| INVITE_RECEIVED | { inviteId, from } | 招待受信 |
| INVITE_RESPONSE | { accepted } | 招待応答結果 |
| BATTLE_START | { matchId, initialState } | バトル開始 |
| TURN_RESULT | { turnResult } | ターン結果 |
| BATTLE_END | { matchResult } | バトル終了 |
| OPPONENT_DISCONNECTED | {} | 相手切断 |
| ACTION_TIMEOUT | {} | 行動選択タイムアウト警告 |
