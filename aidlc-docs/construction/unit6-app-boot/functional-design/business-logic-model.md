# Business Logic Model - Unit 6: 起動時処理

## 1. アプリ起動フロー（メインシーケンス）

```text
[アプリ起動]
    │
    ▼
[SplashScreen 表示] ← 最低1秒表示保証
    │
    ▼
[ローカルトークン確認] SharedPreferencesから読み込み
    ├─ トークンなし → /login へ遷移
    └─ トークンあり → [トークン検証]
         │
         ▼
    [GET /users/me] プロフィール取得
         ├─ 200 + nickname有り → [初期データ取得]
         ├─ 200 + nickname無し → /nickname へ遷移
         ├─ 404 → /nickname へ遷移
         └─ 401 → [リフレッシュ試行]
              ├─ 成功 → [GET /users/me] 再実行
              └─ 失敗 → トークン破棄 → /login へ遷移
         │
         ▼
    [初期データ取得]（並列実行）
         ├─ GET /avatar → アバター情報
         │     └─ 404 → POST /avatar（自己修復）→ 再取得
         ├─ GET /records/summary → 今日のサマリー
         ├─ GET /social/pending-requests → 未読フレンド申請数
         └─ POST /health/sync → ヘルスデータ自動同期（バックグラウンド）
         │
         ▼
    [アバター画像プリロード]
         ├─ spriteSheetKey → S3 URL解決
         ├─ ローカルキャッシュ確認
         │     ├─ キャッシュヒット → スキップ
         │     └─ キャッシュミス → 画像ダウンロード＆保存
         └─ 失敗時 → プレースホルダーで続行（非ブロッキング）
         │
         ▼
    [キャッシュ保存] 取得データをローカルに保存
         │
         ▼
    [/ (ホーム画面)] へ遷移
```

## 2. スプラッシュ画面ロジック

```text
[SplashScreen]
    │
    ├─ 表示開始時刻を記録
    ├─ 起動処理を非同期実行
    │
    ▼
[起動処理完了]
    │
    ├─ 経過時間 < 1秒 → 残り時間待機
    └─ 経過時間 >= 1秒 → 即座に遷移
```

## 3. トークン検証フロー

```text
[トークン検証]
    │
    ▼
[GET /users/me] アクセストークンで呼び出し
    ├─ 200 → トークン有効、プロフィール取得成功
    ├─ 401 → アクセストークン期限切れ
    │     │
    │     ▼
    │  [POST /auth/refresh] リフレッシュトークンで更新
    │     ├─ 200 → 新トークン保存 → GET /users/me 再実行
    │     └─ 401/400 → リフレッシュトークンも期限切れ
    │           └→ ローカルトークン全削除 → /login
    ├─ 404 → プロフィール未作成 → /nickname
    └─ ネットワークエラー → [オフラインフォールバック]
```

## 4. 初期データ取得フロー

```text
[初期データ取得] ← 4リクエスト並列実行
    │
    ├─ [GET /avatar]
    │     ├─ 200 → avatarデータをキャッシュ保存
    │     ├─ 404 → [POST /avatar] 自動作成
    │     │         ├─ 201 → 作成されたavatarをキャッシュ保存
    │     │         └─ エラー → avatarデータ = null（ホームで個別エラー表示）
    │     └─ その他エラー → avatarデータ = null
    │
    ├─ [GET /records/summary]
    │     ├─ 200 → summaryデータをキャッシュ保存
    │     └─ エラー → summaryデータ = null（ホームで個別エラー表示）
    │
    ├─ [GET /social/pending-requests]
    │     ├─ 200 → pendingCountをキャッシュ保存
    │     └─ エラー → pendingCount = 0
    │
    └─ [POST /health/sync]（バックグラウンド、結果を待たない）
          ├─ 200 → ヘルスデータ同期完了（ログのみ）
          └─ エラー → 無視（次回起動時にリトライ）
```

## 5. オフラインフォールバック

```text
[ネットワークエラー検出]
    │
    ▼
[ローカルキャッシュ確認]
    ├─ キャッシュあり → キャッシュデータでホーム画面表示（読み取り専用）
    │     └─ 画面上部に「オフラインモード」バナー表示
    └─ キャッシュなし → エラー画面（リトライボタン付き）
```

## 6. ニックネーム設定完了時のアバター作成

```text
[NicknameScreen] ニックネーム保存成功
    │
    ▼
[POST /avatar] 初期アバター作成
    ├─ 201 → アバター作成成功 → ホーム画面へ遷移
    └─ エラー → リトライ（最大3回）
          ├─ リトライ成功 → ホーム画面へ遷移
          └─ リトライ失敗 → ホーム画面へ遷移（起動時の自己修復に委ねる）
```

## 7. キャッシュ戦略

| データ | キャッシュ先 | TTL | 用途 |
|---|---|---|---|
| ユーザープロフィール | SharedPreferences | 無期限（ログアウトで削除） | ニックネーム表示 |
| アバター情報 | SharedPreferences | 無期限（API取得で上書き） | ホーム画面表示 |
| 今日のサマリー | SharedPreferences | 当日中 | ホーム画面表示 |
| 未読フレンド申請数 | メモリのみ | セッション中 | バッジ表示 |
| アバター画像 | ローカルファイル（アプリキャッシュ） | spriteSheetKey変更まで | ホーム画面アバター表示 |

## 8. アバター画像取得フロー

```text
[初期データ取得完了] avatar.spriteSheetKey 取得済み
    │
    ▼
[画像URL解決]
    spriteSheetKey → https://{ASSETS_BUCKET}.s3.ap-northeast-1.amazonaws.com/assets/{spriteSheetKey}.png
    │
    ▼
[ローカルキャッシュ確認]
    ├─ キャッシュあり + spriteSheetKeyが同じ → キャッシュ画像を使用
    └─ キャッシュなし or spriteSheetKey変更 → [S3から画像ダウンロード]
         │
         ▼
    [画像ダウンロード]
         ├─ 成功 → ローカルファイルに保存 → 画像表示
         └─ 失敗 → プレースホルダー画像を表示（デフォルトぶたアイコン）
```

**画像URL構成ルール**:
- ベースURL: `https://{ASSETS_BUCKET_NAME}.s3.ap-northeast-1.amazonaws.com/assets/`
- パス: `{spriteSheetKey}.png`
- 例: `spriteSheetKey = "sprites/stage1/default"` → URL = `https://butasodate-assets-xxx-dev.s3.ap-northeast-1.amazonaws.com/assets/sprites/stage1/default.png`

**キャッシュ無効化条件**:
- `GET /avatar` で取得した `spriteSheetKey` が前回キャッシュ時と異なる場合（進化/退化時）
- ログアウト時（全キャッシュ削除）

## API エンドポイント利用一覧

| メソッド | パス | 用途 | 失敗時 |
|---|---|---|---|
| GET | /users/me | トークン検証 + プロフィール取得 | ログイン画面 or ニックネーム画面 |
| POST | /auth/refresh | トークンリフレッシュ | ログイン画面 |
| GET | /avatar | アバター情報取得 | 自己修復 or null |
| POST | /avatar | アバター自動作成（自己修復） | null（ホームで個別表示） |
| GET | /records/summary | 今日のサマリー | null（ホームで個別表示） |
| GET | /social/pending-requests | 未読フレンド申請数 | 0 |
| POST | /health/sync | ヘルスデータ同期 | 無視 |
