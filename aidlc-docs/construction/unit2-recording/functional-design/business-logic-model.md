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
    ├─ トランザクション処理（全件成功 or 全件ロールバック）
    │    ├─ 各レコード: recordIdで存在チェック（冪等性担保）
    │    │    ├─ 既存あり → スキップ（重複排除）
    │    │    └─ 新規 → ActivityRecord作成
    │    ├─ 新規レコード分のポイント合計を算出
    │    └─ AvatarService.addPoints（新規分の合計ポイント）
    ├─ 成功レスポンス: { syncedRecords[], skippedIds[], avatarStatus }
    ├─ 失敗時: 全件ロールバック → エラーレスポンス
    │
    ▼
[フロントエンド]
    ├─ 成功: ローカルDB更新（syncStatus = SYNCED）
    └─ 失敗: syncStatus = PENDING のまま（次回リトライ）
```

**冪等性**: recordIdによる重複排除。リトライ時に同じIDが来たらスキップし、ポイント二重加算を防止。
**トランザクション保証**: DynamoDB TransactWriteItemsで全レコード＋ポイント加算を一括処理。部分的な不整合を排除。

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
    ├─ 冪等性チェック: HealthSyncRecord(userId, syncDate#category)が既存か確認
    │    ├─ 既存あり → スキップ（重複排除、ポイント二重加算防止）
    │    └─ 新規 → 処理続行
    ├─ トランザクション処理（新規レコード分のみ）
    │    ├─ 各レコードのポイント計算 (BR-2)
    │    ├─ HealthSyncRecord作成・保存
    │    ├─ 自動検出ActivityRecord作成（source=AUTO_DETECTED）
    │    └─ AvatarService.addPoints（新規分の合計ポイント、カテゴリ別）
    ├─ レスポンス: { syncResults[], skippedDates[], totalPoints, avatarStatus }
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
[初回判定] previousWeight == null ?
    ├─ YES → NEUTRAL, points = 0（初回は基準値記録のみ、比較しない）
    └─ NO → 差分計算へ
    │
    ▼
[差分計算] diff = currentWeight - previousWeight
    ├─ diff >= 1.0 → UNHEALTHY, points = +20 × floor(diff)
    ├─ diff <= -1.0 → HEALTHY, points = -10 × floor(abs(diff))
    └─ -1.0 < diff < 1.0 → NEUTRAL, points = 0
```

**初回同期**: previousWeightが存在しない場合、currentWeightを基準値として保存し、ポイント変動なし。

### 4.2 歩数評価（日別）

```text
入力: steps（1日の合計歩数）, target（デフォルト8000）
    │
    ▼
[デッドゾーン判定] target × 0.9 <= steps <= target × 1.1 ?
    ├─ YES → NEUTRAL, points = 0（閾値付近は変動なし）
    └─ NO → 評価へ
    │
    ▼
    ├─ steps < target × 0.9（7200歩未満）
    │    → UNHEALTHY
    │    → points = +12 - floor(steps / (target × 0.9) × 7)
    │    （0歩=+12, 4000歩≈+8, 7000歩≈+5）
    │
    └─ steps > target × 1.1（8800歩超過）
         → HEALTHY
         → points = -(3 + floor((steps - target × 1.1) / 7000 × 5))
         → 最大 -8pt（15800歩以上で頭打ち）
```

**デッドゾーン**: target±10%（7200〜8800歩）は NEUTRAL。1歩差で9ptジャンプする不連続を防止。

### 4.3 睡眠評価（1晩=1レコード、就寝時刻 + 睡眠時間の統合評価）

**設計方針**: 就寝時刻と睡眠時間は同一の睡眠セッションから導出される。三重計上を防ぐため、**就寝時刻と睡眠時間のうちポイントが大きい方のみ**を採用する（起床時刻は独立評価しない）。

```text
入力: bedtime, duration, targetBedtime（23:00）, targetDuration（7h）
    │
    ▼
[日付またぎ正規化]
    bedtime を「その日の18:00を起点とした経過時間」に変換
    例: 23:00 → 5h, 翌1:00 → 7h, 翌3:00 → 9h
    target も同様に変換（23:00 → 5h）
    │
    ▼
[就寝時刻ポイント計算]
    ├─ normalizedBedtime > normalizedTarget
    │    → bedtimePoints = +8 + 3 × floor((normalizedBedtime - normalizedTarget) × 2) / 2
    └─ normalizedBedtime <= normalizedTarget
         → bedtimePoints = -4
    │
    ▼
[睡眠時間ポイント計算]
    ├─ duration < targetDuration
    │    → durationPoints = +6 + 2 × floor(targetDuration - duration)
    ├─ targetDuration <= duration < targetDuration + 2h
    │    → durationPoints = -3
    └─ duration >= targetDuration + 2h
         → durationPoints = +4 + 1 × floor(duration - targetDuration - 2)
    │
    ▼
[統合判定] 大きい方を採用
    finalPoints = max(bedtimePoints, durationPoints)  ※符号考慮（加算同士/減算同士の場合）
    │
    ├─ 両方プラス → 大きい方（より不健康な方を採用）
    ├─ 両方マイナス → 絶対値が大きい方（より健康な方を採用）
    └─ 片方プラス/片方マイナス → プラスの方を採用（不健康が優先）
    │
    ▼
[評価決定]
    finalPoints > 0 → UNHEALTHY
    finalPoints < 0 → HEALTHY
    finalPoints == 0 → NEUTRAL

[ラベル決定] 採用された方の行動名をActivityRecordに記録
    就寝側採用: 「夜更かし」or「早寝」
    時間側採用: 「睡眠不足」or「寝すぎ」or「適正睡眠」
```

**日付またぎの扱い**: 18:00を日付境界とする。18:00〜翌17:59を「1晩」として扱う。これにより深夜2:00就寝でも正しく「23:00より遅い」と判定できる。

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
    ├─ 退化リスク判定（削除後ポイントが退化閾値を下回る場合）
    │    → 「削除するとぶたが退化する可能性があります」警告表示
    ├─ キャンセル → 何もしない
    └─ 確認
         │
         ▼
    [バックエンド] DELETE /activities/{recordId}
         ├─ source == AUTO_DETECTED確認（MANUALは削除不可 BR-6）
         ├─ レコード論理削除
         ├─ AvatarService.deductPoints(userId, record.points, categoryType)
         │    ※ deductPointsは退化閾値チェック付き。削除起因の退化は
         │      ポイント減算のみ行い、退化演出はスキップ（ユーザーの意図的操作のため）
         ├─ レスポンス: { success, avatarStatus, devolutionOccurred }
         │
         ▼
    [フロントエンド] 一覧から削除 + アバターステータス更新
         ├─ devolutionOccurred == true → 「ぶたが少し健康になりました」通知
         └─ devolutionOccurred == false → 通常更新
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

## 9. 設計上の保護策

### 冪等性
- `POST /activities/batch`: recordIdで重複排除。同じIDは2回保存されない。
- `POST /health-sync`: userId+syncDate+categoryの複合キーで一意制約。同じ日のデータを再送しても二重処理されない。

### トランザクション保証
- バッチ系API: DynamoDB TransactWriteItemsでレコード保存＋ポイント加算をアトミックに実行。途中失敗時は全件ロールバック。

### カテゴリマスターのキャッシュ整合性
- `GET /categories`レスポンスに`version`フィールドを含む。
- フロントエンドはキャッシュ保存時にversionを記録。
- `POST /activities`（オンライン時）: リクエストに`categoryVersion`を含め、サーバー側で最新basePointsで計算（クライアント計算値は表示用のみ）。
- オフライン仮計算のポイントはあくまで「仮表示」であり、バッチ同期時にサーバーが最新マスターで再計算して確定する。

### 削除時の退化保護
- 自動検出レコード削除でポイントが退化閾値を下回っても、退化演出（コミカル演出）はスキップ。
- 確認ダイアログで退化リスクを事前通知し、ユーザーに判断を委ねる。
