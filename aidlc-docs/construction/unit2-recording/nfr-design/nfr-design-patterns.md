# NFR Design Patterns - Unit 2: 行動記録 + ヘルスデータ連携

## 1. レジリエンスパターン

### 1.1 オフラインファースト + キュー同期

```text
[記録操作]
    │
    ├─ オンライン → API即時呼び出し → 成功 → 完了
    │                              → 失敗 → ローカル保存（PENDING）
    └─ オフライン → ローカル保存（PENDING）

[ネットワーク復帰トリガー]
    │
    ▼
[同期キュー処理]
    ├─ PENDING件数 > 0 → POST /activities/batch
    ├─ 成功 → SYNCED更新
    └─ 失敗 → リトライ（指数バックオフ: 1s, 2s, 4s）
         ├─ 3回失敗 → トースト通知「同期に失敗しました。次回起動時に再試行します」
         └─ PENDINGのまま保持 → 次回起動時に再試行
```

### 1.2 ヘルスデータ取得のカテゴリ別フォールト分離

```text
[起動時同期]
    │
    ├─ WEIGHT取得（10sタイムアウト）
    │    ├─ 成功 → データ送信対象に追加
    │    └─ 失敗/タイムアウト → スキップ（lastSyncDate更新しない）
    │
    ├─ STEPS取得（10sタイムアウト）
    │    ├─ 成功 → データ送信対象に追加
    │    └─ 失敗/タイムアウト → スキップ
    │
    └─ SLEEP取得（10sタイムアウト）
         ├─ 成功 → データ送信対象に追加
         └─ 失敗/タイムアウト → スキップ

[部分成功で続行] → 成功カテゴリ分のみAPIに送信
```

**設計原則**: 1カテゴリの障害が他カテゴリに波及しない。バルクヘッドパターン。

### 1.3 API呼び出しリトライ

| API | リトライ回数 | バックオフ | タイムアウト |
|-----|------------|-----------|------------|
| POST /activities | 1回 | なし | 5s |
| POST /activities/batch | 3回 | 指数（1s,2s,4s） | 10s |
| POST /health-sync | 2回 | 指数（1s,2s） | 10s |
| GET /activities | 1回 | なし | 5s |
| GET /categories | 1回 | なし | 3s |

## 2. パフォーマンスパターン

### 2.1 カテゴリマスターキャッシュ（起動時バージョンチェック）

```text
[アプリ起動]
    │
    ▼
[キャッシュ確認] ローカルにcategoriesキャッシュあり？
    ├─ なし → GET /categories → キャッシュ保存（version付き）
    └─ あり → GET /categories/version → バージョン比較
                  ├─ 同一 → キャッシュ使用（追加通信なし）
                  └─ 差異 → GET /categories → キャッシュ更新
```

- `GET /categories/version`: バージョン番号のみ返す軽量API（レスポンス数バイト）
- カテゴリ一覧画面表示時はキャッシュから即描画

### 2.2 楽観的UI更新（記録時）

```text
[記録ボタン押下]
    │
    ▼
[即座にUI更新]
    ├─ ぶた喜びアニメーション開始
    ├─ ポイント仮表示（ローカル計算）
    │
    ▼（並行でAPI呼び出し）
[POST /activities]
    ├─ 成功 → 確定値でUI微調整（差分があれば）
    └─ 失敗 → ローカル保存 + 「オフライン保存しました」トースト
```

**UX効果**: API応答を待たずにぶたの反応が見える。体感0ms。

### 2.3 ページネーション（カーソル方式）

- DynamoDB LastEvaluatedKeyをBase64エンコードしてcursorとして返却
- 20件ずつ取得（1ページあたり）
- フィルター（日付/カテゴリ）はGSI + FilterExpressionで実装

## 3. セキュリティパターン

### 3.1 ユーザーデータ分離

```text
[全APIリクエスト]
    │
    ▼
[認証ミドルウェア] JWT検証 → userId = token.sub 抽出
    │
    ▼
[データアクセス層] PK = userId を強制
    → 他ユーザーのデータに物理的にアクセス不可能
```

### 3.2 ヘルスデータ最小化

```text
[端末側]                         [サーバー側]
HealthKit/HealthConnect          受け取るのは:
  → 歩数(個別記録多数)    →→→    dailySteps: 8234
  → 睡眠(複数セッション)  →→→    bedtime: "01:30", duration: 5.5
  → 体重(直近値)         →→→    weight: 72.5

生データは端末内で集計し破棄。サーバーは集計値のみ保持。
```

## 4. データ整合性パターン

### 4.1 トランザクション境界

```text
[POST /activities] 単件記録
    TransactWriteItems:
      - Put: ActivityRecord
      - Update: Avatar.totalPoints += points
      - Update: Avatar.categoryPoints[type] += points

[POST /activities/batch] バッチ同期
    TransactWriteItems:（25件制限/バッチ）
      - Put: ActivityRecord × N（新規分のみ）
      - Update: Avatar.totalPoints += sum(points)
      - Update: Avatar.categoryPoints[type] += sum(points)
    ※ 25件超過時はバッチを分割し、各バッチをトランザクション実行

[POST /health-sync] ヘルスデータ同期
    TransactWriteItems:
      - Put: HealthSyncRecord × N
      - Put: ActivityRecord × N（AUTO_DETECTED）
      - Update: Avatar ポイント加算
```

### 4.2 冪等性キー

| API | 冪等性キー | 重複時の挙動 |
|-----|-----------|-------------|
| POST /activities | recordId | ConditionalCheck → スキップ |
| POST /activities/batch | 各recordId | 既存スキップ、新規のみ処理 |
| POST /health-sync | userId+syncDate+category | 既存スキップ |
