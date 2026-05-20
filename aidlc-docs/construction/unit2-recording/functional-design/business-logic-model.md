# Business Logic Model - Unit 2: 行動記録 + ヘルスデータ連携

## 1. 手動行動記録フロー

```text
[ユーザー] → ホーム画面「行動を記録」ボタン押下
    │
    ▼
[フロントエンド] カテゴリ一覧画面表示
    │  ← GET /categories （マスターデータ取得、キャッシュ有）
    ▼
[ユーザー] → カテゴリ選択（1タップ目）
    │
    ▼
[フロントエンド] 記録確認画面表示
    │  日時（デフォルト: 現在）、メモ（任意）
    ▼
[ユーザー] → 「記録する」ボタン押下（2-3タップ目）
    │
    ▼
[フロントエンド] バリデーション
    ├─ メモ100文字以内チェック (BR-5)
    │
    ▼
[バックエンド] POST /activities
    ├─ ポイント計算 (BR-1): categoryType→basePoints取得
    ├─ ActivityRecord作成・保存
    ├─ AvatarService.addPoints(userId, points, categoryType) 呼び出し
    ├─ 成功レスポンス: { record, avatarStatus }
    │
    ▼
[フロントエンド] 記録完了演出
    ├─ ぶたの喜びリアクション表示
    ├─ 獲得ポイント表示（+12pt等）
    └─ アバターステータス更新反映
```

## 2. オフライン行動記録フロー

```text
[ユーザー] → オフライン状態で「記録する」押下
    │
    ▼
[フロントエンド] ローカルDB保存
    ├─ recordId生成（UUID）
    ├─ points仮計算（ローカルのcategoryマスターから）
    ├─ syncStatus = PENDING
    │
    ▼
[フロントエンド] 記録完了表示（ポイント仮表示）
    │
    === ネットワーク復帰時 ===
    │
    ▼
[フロントエンド] 未同期レコード検出
    │
    ▼
[バックエンド] POST /activities/batch
    ├─ 各レコードを処理（recordIdで重複排除）
    ├─ AvatarService.addPoints（合計ポイント）
    ├─ レスポンス: { syncedRecords[], avatarStatus }
    │
    ▼
[フロントエンド] ローカルDB更新（syncStatus = SYNCED）
```

## 3. ヘルスデータ起動時同期フロー

```text
[アプリ起動]
    │
    ▼
[フロントエンド] 同期判定
    ├─ isEnabled == false → スキップ → ホーム画面へ
    ├─ オフライン → スキップ → ホーム画面へ
    ├─ 全カテゴリのlastSyncDate == 今日 → スキップ → ホーム画面へ
    └─ 同期対象あり → 続行
    │
    ▼
[フロントエンド] カテゴリ別データ取得（並列）
    ├─ WEIGHT: HealthKit/HealthConnect → 体重データ取得
    ├─ STEPS: HealthKit/HealthConnect → 歩数データ取得
    ├─ SLEEP: HealthKit/HealthConnect → 睡眠データ取得
    │  ※ enabledCategories=falseのカテゴリはスキップ
    │  ※ 各カテゴリ: lastSyncDate翌日〜前日を対象
    │
    ▼
[フロントエンド] 取得結果判定
    ├─ カテゴリ別に成功/失敗を記録 (BR-3)
    ├─ 失敗カテゴリ: lastSyncDate更新しない（次回リトライ）
    ├─ 成功カテゴリ: データ整形してAPIへ送信
    │
    ▼
[バックエンド] POST /health-sync
    ├─ リクエスト: { records: [{ category, syncDate, rawValue }...] }
    ├─ 各レコードのポイント計算 (BR-2)
    ├─ HealthSyncRecord作成・保存
    ├─ 自動検出ActivityRecord作成（source=AUTO_DETECTED）
    ├─ AvatarService.addPoints（合計ポイント、カテゴリ別）
    ├─ レスポンス: { syncResults[], totalPoints, avatarStatus }
    │
    ▼
[フロントエンド] lastSyncDates更新（成功カテゴリのみ）
    │
    ▼
[フロントエンド] サマリー表示判定 (BR-9)
    ├─ 検出行動0件 → ホーム画面へ直行
    └─ 検出行動1件以上 → 起動時サマリー画面表示
         ├─ 行動種類、日時、ポイント増減を一覧表示
         └─ 「確認」ボタン → ホーム画面へ
```

## 4. ヘルスデータ評価ロジック詳細

### 4.1 体重評価

```text
入力: currentWeight, previousWeight（前回同期時）
    │
    ▼
[差分計算] diff = currentWeight - previousWeight
    ├─ diff >= 1.0 → UNHEALTHY, points = +20 × floor(diff)
    ├─ diff <= -1.0 → HEALTHY, points = -10 × floor(abs(diff))
    └─ -1.0 < diff < 1.0 → NEUTRAL, points = 0
```

### 4.2 歩数評価（日別）

```text
入力: steps（1日の合計歩数）, target（デフォルト8000）
    │
    ▼
    ├─ steps < target
    │    → UNHEALTHY
    │    → points = +12 - floor(steps / target × 7)
    │    （0歩=+12, 4000歩≈+8, 7000歩≈+6）
    │
    └─ steps >= target
         → HEALTHY
         → points = -(3 + floor((steps - target) / 7000 × 5))
         → 最大 -8pt（15000歩以上で頭打ち）
```

### 4.3 睡眠評価（就寝時刻）

```text
入力: bedtime, targetBedtime（デフォルト23:00）
    │
    ▼
    ├─ bedtime > targetBedtime
    │    → UNHEALTHY
    │    → excessHours = floor((bedtime - target) × 2) / 2  # 30分単位
    │    → points = +8 + 3 × excessHours
    │
    └─ bedtime <= targetBedtime
         → HEALTHY
         → points = -4
```

### 4.4 睡眠評価（睡眠時間）

```text
入力: duration, targetDuration（デフォルト7h）
    │
    ▼
    ├─ duration < targetDuration
    │    → UNHEALTHY（睡眠不足）
    │    → deficit = targetDuration - duration
    │    → points = +6 + 2 × floor(deficit)
    │
    ├─ targetDuration <= duration < targetDuration + 2h
    │    → HEALTHY（適正睡眠）
    │    → points = -3
    │
    └─ duration >= targetDuration + 2h
         → UNHEALTHY（寝すぎ）
         → excess = duration - (targetDuration + 2)
         → points = +4 + 1 × floor(excess)
```

### 4.5 起床時刻評価

```text
入力: wakeTime, targetWake（デフォルト7:00）
    │
    ▼
    ├─ wakeTime > targetWake
    │    → UNHEALTHY（寝坊）
    │    → excessHours = floor((wakeTime - targetWake) × 2) / 2
    │    → points = +6 + 2 × excessHours
    │
    └─ wakeTime <= targetWake
         → HEALTHY（早起き）
         → points = -3
```

## 5. 記録履歴取得フロー

```text
[ユーザー] → 記録履歴画面を開く
    │
    ▼
[フロントエンド] GET /activities?limit=20&cursor=null
    │  オプション: &categoryId=xxx, &from=yyyy-mm-dd, &to=yyyy-mm-dd
    │
    ▼
[バックエンド] DynamoDB Query
    ├─ PK=userId, SK降順（新しい順）
    ├─ フィルター適用（カテゴリ、日付範囲）
    ├─ limit=20 + nextCursor生成
    │
    ▼
[フロントエンド] 一覧表示
    │  各レコード: カテゴリ名、日時、ポイント、source（手動/自動検出ラベル）
    │
    ▼
[ユーザー] → 「もっと見る」ボタン押下
    │
    ▼
[フロントエンド] GET /activities?limit=20&cursor={nextCursor}
    └─ 既存リストに追記
```

## 6. 自動検出レコード削除フロー

```text
[ユーザー] → 履歴一覧で自動検出レコードを選択 → 削除ボタン
    │
    ▼
[フロントエンド] 確認ダイアログ表示
    ├─ キャンセル → 何もしない
    └─ 確認
         │
         ▼
    [バックエンド] DELETE /activities/{recordId}
         ├─ source == AUTO_DETECTED確認（MANUALは削除不可 BR-6）
         ├─ レコード論理削除
         ├─ AvatarService.deductPoints(userId, record.points, categoryType)
         ├─ レスポンス: { success, avatarStatus }
         │
         ▼
    [フロントエンド] 一覧から削除 + アバターステータス更新
```

## 7. ヘルスデータ連携設定フロー

```text
[ユーザー] → 設定画面 → ヘルスデータ連携セクション
    │
    ▼
[フロントエンド] 現在の設定表示（SharedPreferencesから）
    │
    === 初回有効化 ===
    ├─ 「連携を有効にする」ボタン押下
    │    → OS許可ダイアログ表示（HealthKit/HealthConnect）
    │    ├─ 許可 → isEnabled=true, 全カテゴリON → 即同期開始
    │    └─ 拒否 → isEnabled=false のまま
    │
    === カテゴリ個別設定 ===
    ├─ トグル切り替え（体重/歩数/睡眠）
    │    → enabledCategories更新
    │    → OFF時: lastSyncDate保持（再ONで復帰タイミングから同期）
    │
    === 基準値変更 ===
    ├─ 就寝基準値変更（タイムピッカー）
    ├─ 起床基準値変更（タイムピッカー）
    ├─ 睡眠時間基準値変更（時間選択）
    ├─ 歩数目標変更（数値入力）
    │    → 次回同期から新基準値で評価
    │
    === 連携解除 ===
    └─ 「連携を解除」ボタン押下
         → 確認ダイアログ
         → isEnabled=false, enabledCategories全OFF
         → 既存データ保持、自動検出のみ停止
```

## 8. ホーム画面サマリー取得フロー

```text
[ホーム画面表示時]
    │
    ▼
[フロントエンド] GET /activities/summary?period=today
    │
    ▼
[バックエンド] 集計
    ├─ 今日のActivityRecord集計: 件数、合計ポイント
    ├─ レスポンス: { todayCount, todayPoints }
    │
    ▼
[フロントエンド] サマリーセクション表示
    │  「今日: X件 / +Ypt」
    │
    ▼
[ユーザー] → サマリーセクションタップ
    │
    ▼
[フロントエンド] GET /activities/summary?period=week
    │
    ▼
[バックエンド] 週間集計
    ├─ 今週のカテゴリ別: 件数、ポイント
    ├─ レスポンス: { weekSummary: [{ categoryId, count, points }...] }
    │
    ▼
[フロントエンド] 週間サマリー展開表示
```

## API エンドポイント一覧

| メソッド | パス | 認証 | 説明 |
|---------|------|------|------|
| GET | /categories | 必要 | カテゴリ一覧取得 |
| POST | /activities | 必要 | 行動記録（単件） |
| POST | /activities/batch | 必要 | 行動記録（オフライン同期用バッチ） |
| GET | /activities | 必要 | 記録履歴取得（カーソルページネーション） |
| DELETE | /activities/{recordId} | 必要 | 自動検出レコード削除 |
| GET | /activities/summary | 必要 | サマリー取得（today/week） |
| POST | /health-sync | 必要 | ヘルスデータ同期 |
