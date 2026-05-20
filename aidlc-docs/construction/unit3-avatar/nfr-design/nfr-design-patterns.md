# NFR Design Patterns - Unit 3: アバター育成

## 1. パフォーマンスパターン

### 1.1 単一テーブル読み書き（DynamoDB）

AvatarService の addPoints/deductPoints は1回のDynamoDB UpdateItem で完結させる。

```text
[addPoints呼び出し]
    │
    ▼
DynamoDB UpdateItem (PK=userId)
    ├─ SET totalPoints = totalPoints + :points
    ├─ SET categoryPoints.#cat = categoryPoints.#cat + :points
    ├─ SET level = :newLevel (条件付き)
    ├─ SET updatedAt = :now
    └─ ReturnValues: ALL_NEW
    │
    ▼
[メモリ内で進化/退化判定]
    ├─ 進化発生時のみ: 追加の UpdateItem + PutItem(EvolutionHistory)
    └─ 通常時: 追加DBアクセスなし
```

**効果**: 通常ケース（進化なし）は1回のDB操作で完了 → 低レイテンシ

### 1.2 マスターデータのメモリキャッシュ（Lambda）

EvolutionPath と Skill のマスターデータは Lambda のグローバル変数にキャッシュ。

```text
[Lambda起動]
    ├─ コールドスタート: DynamoDB Scan → グローバル変数に保存
    └─ ウォームスタート: キャッシュ済みデータを使用（DBアクセスなし）
```

**効果**: ウォーム時はマスターデータ取得のDB呼び出しゼロ

### 1.3 スプライトシートのローカルキャッシュ（Flutter）

```text
[スプライト表示要求]
    │
    ▼
flutter_cache_manager.getSingleFile(url)
    ├─ キャッシュヒット → ローカルファイルから即表示
    └─ キャッシュミス → S3からDL → キャッシュ保存 → 表示
```

**効果**: 2回目以降はネットワーク不要で即表示

## 2. レジリエンスパターン

### 2.1 進化判定の分離（Graceful Degradation）

ポイント更新と進化判定を分離し、進化判定が失敗してもポイントは確実に更新。

```text
[addPoints]
    │
    ├─ Step 1: ポイント更新（必須、失敗時はエラー返却）
    │
    ├─ Step 2: 進化判定（オプショナル）
    │    ├─ 成功 → 進化処理実行
    │    └─ 失敗 → ログ出力、次回呼び出し時に再判定
    │
    └─ レスポンス: ポイント更新結果は必ず返す
```

### 2.2 スプライトシートのフォールバック

```text
[スプライト読み込み]
    ├─ 成功 → 現在の進化段階のスプライト表示
    └─ 失敗（ネットワーク＆キャッシュ両方なし）
         → 初期段階スプライト（アプリバンドル内蔵）を表示
```

**初期段階スプライトのみアプリバンドルに同梱**し、フォールバック用に常に利用可能にする。

### 2.3 演出のスキップ機能

進化/退化演出中に「スキップ」ボタン（演出開始1秒後に出現）でスキップ可能。演出の成否に関わらずデータは既に更新済み。

## 3. セキュリティパターン

### 3.1 ユーザー所有権チェック

全APIで `userId = JWT token の sub` を検証。パスパラメータでのuserId指定は不可。

```text
[APIリクエスト]
    │
    ▼
[認証ミドルウェア] JWT検証 → userId抽出
    │
    ▼
[ハンドラ] userId = token.sub でDB操作（他ユーザーのデータにアクセス不可）
```

### 3.2 S3アセットのパブリック読み取り

スプライトシートは機密データではないため、S3バケットポリシーでパブリック読み取りを許可。

```text
s3:GetObject → Allow * （assets/sprites/ プレフィックスのみ）
```

## 4. データ整合性パターン

### 4.1 レベル・ステータスの再計算保証

レベルとステータスは totalPoints と evolutionPathId から常に再計算可能。DB上の値はキャッシュ。

```text
[整合性チェック（必要時）]
    ├─ level = calculateLevel(totalPoints)
    ├─ stats = calculateStats(level, evolutionPath.statsGrowth)
    └─ 不一致検出時 → 再計算して上書き
```

### 4.2 進化履歴の追記のみ（Append-Only）

EvolutionHistory は追記のみ。更新・削除なし。監査証跡として機能。
