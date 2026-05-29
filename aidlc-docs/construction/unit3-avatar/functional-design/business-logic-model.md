# Business Logic Model - Unit 3: アバター育成

## 1. 初期アバター生成フロー

```text
[ユーザー] → プロフィール設定完了（Unit 1）
    │
    ▼
[バックエンド] POST /avatar
    ├─ userId重複チェック（既にアバターがあれば409エラー）
    ├─ Avatar生成:
    │    ├─ totalPoints = 0
    │    ├─ level = 1
    │    ├─ evolutionStage = 1
    │    ├─ evolutionPathId = null
    │    ├─ categoryPoints = { FOOD: 0, LIFESTYLE: 0 }
    │    ├─ stats = { hp: 50, attack: 10, defense: 10, speed: 10 }
    │    ├─ skillIds = []
    │    ├─ spriteSheetKey = "sprites/stage1/default"
    │    └─ name = リクエストの名前 or "ぶたさん"
    ├─ DynamoDB保存
    ├─ レスポンス: { avatar }
    │
    ▼
[フロントエンド] ホーム画面にアバター表示
    └─ 初期スプライトシートでアイドルアニメーション開始
```

## 2. ポイント加算フロー（Unit 2 から呼び出し）

```text
[バックエンド] AvatarService.addPoints(userId, points, categoryType)
    │
    ▼
[Step 1] ポイント更新
    ├─ avatar.totalPoints += points
    ├─ avatar.categoryPoints[categoryType] += points
    │
    ▼
[Step 2] レベル再計算
    ├─ newLevel = calculateLevel(avatar.totalPoints)
    │    └─ N×(N+1)×50 の逆算: floor((sqrt(1 + totalPoints/50 × 4) - 1) / 2)
    ├─ leveledUp = (newLevel > avatar.level)
    ├─ avatar.level = newLevel
    │
    ▼
[Step 3] 進化判定（レベルアップ時のみ）
    ├─ leveledUp == false → スキップ
    ├─ 現在stage=1 & newLevel >= 5 → 第2段階進化判定
    ├─ 現在stage=2 & newLevel >= 15 → 第3段階進化判定
    └─ それ以外 → 進化なし
    │
    ├─ [第2段階進化判定ロジック]
    │    ├─ foodRatio = categoryPoints[FOOD] / totalPoints
    │    ├─ lifestyleRatio = categoryPoints[LIFESTYLE] / totalPoints
    │    ├─ foodRatio >= 0.6 → 食事系パス（グルメぶた）
    │    ├─ lifestyleRatio >= 0.6 → 生活系パス（ぐうたらぶた）
    │    └─ どちらも < 0.6 → 混合パス（まんまるぶた）
    │
    ├─ [第3段階進化判定ロジック]
    │    ├─ 現パスの子パス候補を取得（parentPathId = 現パスID）
    │    ├─ 各候補のsubCategoryIdsに該当するサブカテゴリポイント合計を算出
    │    ├─ subCategoryRatio = 該当サブカテゴリ合計 / 現カテゴリ合計
    │    ├─ subCategoryRatio >= subCategoryThreshold → そのパスに進化
    │    └─ どちらも閾値未満 → ランダムで決定
    │
    │    ├─ avatar.evolutionStage = 新段階
    │    ├─ avatar.evolutionPathId = 決定したパスID
    │    ├─ avatar.spriteSheetKey = 新パスのスプライトキー
    │    └─ EvolutionHistory レコード作成（type=EVOLUTION）
    │
    ▼
[Step 4] スキル習得判定
    ├─ 現在のパスに紐づくスキルを取得
    ├─ 各スキル: requiredLevel <= avatar.level & skillId not in avatar.skillIds
    │    → avatar.skillIds に追加
    │
    ▼
[Step 5] ステータス再計算
    ├─ 現在のパスの statsGrowth を取得
    ├─ stats = 初期値 + (level - 1) × statsGrowth
    │    ├─ hp = 50 + (level - 1) × statsGrowth.hp
    │    ├─ attack = 10 + (level - 1) × statsGrowth.attack
    │    ├─ defense = 10 + (level - 1) × statsGrowth.defense
    │    └─ speed = 10 + (level - 1) × statsGrowth.speed
    │
    ▼
[Step 6] 保存 & レスポンス
    ├─ DynamoDB更新（Avatar）
    ├─ レスポンス: { avatar, leveledUp, evolved, newSkills[] }
```

## 3. ポイント減算フロー（Unit 2 から呼び出し）

```text
[バックエンド] AvatarService.deductPoints(userId, points, categoryType)
    │
    ▼
[Step 1] ポイント更新
    ├─ avatar.totalPoints -= points（最低0）
    ├─ avatar.categoryPoints[categoryType] -= points（最低0）
    │
    ▼
[Step 2] レベル再計算
    ├─ newLevel = max(1, calculateLevel(avatar.totalPoints))
    ├─ leveledDown = (newLevel < avatar.level)
    ├─ avatar.level = newLevel
    │
    ▼
[Step 3] 退化判定
    ├─ 現在stage=3 & newLevel < 15 → 第2段階へ退化
    ├─ 現在stage=2 & newLevel < 5 → 第1段階へ退化
    └─ それ以外 → 退化なし
    │
    ├─ [退化処理]
    │    ├─ 現在stage=3 → stage=2:
    │    │    ├─ avatar.evolutionPathId = 現パスのparentPathId
    │    │    └─ 第3段階スキルを skillIds から除去
    │    ├─ 現在stage=2 → stage=1:
    │    │    ├─ avatar.evolutionPathId = null
    │    │    └─ 第2段階スキルを skillIds から除去
    │    ├─ avatar.evolutionStage = 新段階
    │    ├─ avatar.spriteSheetKey = 退化先のスプライトキー
    │    └─ EvolutionHistory レコード作成（type=DEVOLUTION）
    │
    ▼
[Step 4] ステータス再計算（退化後のパスで再計算）
    ├─ 退化後パスの statsGrowth で再計算
    │
    ▼
[Step 5] 保存 & レスポンス
    ├─ DynamoDB更新（Avatar）
    ├─ レスポンス: { avatar, leveledDown, devolved, lostSkills[] }
```

## 4. アバター情報取得フロー

```text
[フロントエンド] ホーム画面表示 or ステータス画面表示
    │
    ▼
[バックエンド] GET /avatar
    ├─ DynamoDB: PK=userId でAvatar取得
    ├─ スキル詳細: skillIds から Skill マスターデータ取得
    ├─ 進化パス詳細: evolutionPathId から EvolutionPath 取得
    ├─ 次レベルまでのポイント計算:
    │    └─ nextLevelPoints = (level+1) × (level+2) × 50 - totalPoints
    ├─ 次進化までのレベル計算:
    │    └─ stage=1: 5-level, stage=2: 15-level, stage=3: null
    │
    ▼
[レスポンス]
    {
      avatar,
      skills: [{ skillId, name, type, power, cooldown }...],
      evolutionPath: { name, description },
      progress: {
        nextLevelPoints,
        nextEvolutionLevel,
        categoryRatio: { food: 0.xx, lifestyle: 0.xx }
      }
    }
```

## 5. 進化履歴取得フロー

```text
[フロントエンド] ステータス画面 → 進化履歴タブ
    │
    ▼
[バックエンド] GET /avatar/evolution-history
    ├─ DynamoDB Query: PK=userId, SK降順
    ├─ レスポンス: { history: [{ type, fromStage, toStage, fromPath, toPath, occurredAt }...] }
    │
    ▼
[フロントエンド] 進化履歴タイムライン表示
```

## 6. 不健康スコア詳細取得フロー

```text
[フロントエンド] ホーム画面スコアセクション → タップ
    │
    ▼
[バックエンド] GET /avatar/score-detail
    ├─ Avatar から取得:
    │    ├─ totalPoints（不健康スコア）
    │    ├─ categoryPoints（カテゴリ別内訳）
    │    ├─ 次進化までの残りポイント計算
    │    └─ カテゴリ比率計算
    │
    ▼
[レスポンス]
    {
      totalPoints,
      categoryBreakdown: { food: xxx, lifestyle: xxx },
      categoryRatio: { food: 0.xx, lifestyle: 0.xx },
      nextEvolution: {
        requiredLevel,
        currentLevel,
        remainingPoints
      }
    }
```

## 7. レベル計算ロジック詳細

```text
入力: totalPoints
    │
    ▼
[計算] 必要ポイント = N × (N+1) × 50 を逆算
    │
    ├─ N × (N+1) × 50 <= totalPoints を満たす最大のN
    ├─ 二次方程式: 50N² + 50N - totalPoints <= 0
    ├─ N = floor((-50 + sqrt(2500 + 200 × totalPoints)) / 100)
    ├─ 最低1、最大30
    │
    ▼
出力: level = max(1, min(30, N))
```

## API エンドポイント一覧

| メソッド | パス | 認証 | 説明 |
|---------|------|------|------|
| POST | /avatar | 必要 | 初期アバター生成 |
| GET | /avatar | 必要 | アバター情報取得 |
| GET | /avatar/evolution-history | 必要 | 進化履歴取得 |
| GET | /avatar/score-detail | 必要 | 不健康スコア詳細取得 |

**内部API（Unit 2 から呼び出し）**:
| メソッド | 内部呼び出し | 説明 |
|---------|-------------|------|
| - | AvatarService.addPoints(userId, points, categoryType) | ポイント加算 |
| - | AvatarService.deductPoints(userId, points, categoryType) | ポイント減算 |

**注**: addPoints / deductPoints は同一Lambda内のサービス層メソッドとして実装。Unit 2 のAPI（POST /activities, POST /health-sync等）のハンドラ内から直接呼び出す。
