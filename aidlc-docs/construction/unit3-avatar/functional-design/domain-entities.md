# Domain Entities - Unit 3: アバター育成

## エンティティ一覧

### Avatar（アバター）

| 属性 | 型 | 必須 | 説明 |
|------|-----|------|------|
| avatarId | String (UUID) | ✅ | 一意識別子 |
| userId | String (UUID) | ✅ | 所有者ユーザーID |
| name | String | ✅ | アバター表示名 |
| totalPoints | int | ✅ | 累計不健康ポイント（=レベル計算基準） |
| level | int | ✅ | 現在レベル（totalPointsから算出） |
| evolutionStage | int | ✅ | 現在の進化段階（1: 初期, 2: 第2, 3: 最終） |
| evolutionPathId | String? | ❌ | 現在の進化パスID（第2段階以降） |
| categoryPoints | Map\<CategoryType, int\> | ✅ | カテゴリ別累計ポイント（進化パス判定用） |
| subCategoryPoints | Map\<String, int\> | ✅ | サブカテゴリ別累計ポイント（第3段階分岐判定用） |
| stats | AvatarStats | ✅ | バトル用ステータス |
| skillIds | List\<String\> | ✅ | 習得済みスキルIDリスト |
| spriteSheetKey | String | ✅ | 現在のスプライトシートアセットキー |
| createdAt | DateTime | ✅ | 作成日時 |
| updatedAt | DateTime | ✅ | 最終更新日時 |

### AvatarStats（アバターステータス）

| 属性 | 型 | 必須 | 説明 |
|------|-----|------|------|
| hp | int | ✅ | HP |
| attack | int | ✅ | 攻撃力 |
| defense | int | ✅ | 防御力 |
| speed | int | ✅ | 素早さ |

### EvolutionPath（進化パス - マスターデータ）

| 属性 | 型 | 必須 | 説明 |
|------|-----|------|------|
| pathId | String | ✅ | 進化パスID |
| name | String | ✅ | 進化パス名（例: グルメぶた） |
| stage | int | ✅ | 進化段階（2 or 3） |
| parentPathId | String? | ❌ | 前段階の進化パスID（第3段階用） |
| requiredLevel | int | ✅ | 進化に必要なレベル |
| dominantCategory | CategoryType | ✅ | 優勢カテゴリ（FOOD / LIFESTYLE / MIXED） |
| categoryThreshold | double | ✅ | カテゴリ比率閾値（例: 0.6 = 60%以上） |
| subCategoryIds | List\<String\>? | ❌ | 第3段階分岐判定用サブカテゴリIDリスト |
| subCategoryThreshold | double? | ❌ | サブカテゴリ比率閾値（例: 0.5 = 50%以上） |
| statsGrowth | AvatarStats | ✅ | レベルアップ時のステータス上昇値 |
| spriteSheetKey | String | ✅ | この進化パスのスプライトシートキー |
| description | String | ✅ | 進化パスの説明文 |

### Skill（スキル - マスターデータ）

| 属性 | 型 | 必須 | 説明 |
|------|-----|------|------|
| skillId | String | ✅ | スキルID |
| name | String | ✅ | スキル名 |
| type | Enum (SkillType) | ✅ | スキルタイプ |
| power | int | ✅ | 威力 |
| effect | String | ✅ | 効果説明 |
| cooldown | int | ✅ | クールタイム（ターン数） |
| evolutionPathId | String | ✅ | 習得可能な進化パスID |
| requiredLevel | int | ✅ | 習得レベル |
| spriteAnimationKey | String | ✅ | スキル発動アニメーションキー |

### EvolutionHistory（進化履歴）

| 属性 | 型 | 必須 | 説明 |
|------|-----|------|------|
| historyId | String (UUID) | ✅ | 一意識別子 |
| userId | String (UUID) | ✅ | ユーザーID |
| avatarId | String (UUID) | ✅ | アバターID |
| fromStage | int | ✅ | 変化前の進化段階 |
| toStage | int | ✅ | 変化後の進化段階 |
| fromPathId | String? | ❌ | 変化前の進化パスID |
| toPathId | String? | ❌ | 変化後の進化パスID |
| type | Enum (EvolutionType) | ✅ | 進化 or 退化 |
| triggerPoints | int | ✅ | 発動時の累計ポイント |
| occurredAt | DateTime | ✅ | 発生日時 |

## 列挙型

### CategoryType

| 値 | 説明 |
|----|------|
| FOOD | 食事系 |
| LIFESTYLE | 生活系 |
| MIXED | 混合（どちらも均等） |

### SkillType

| 値 | 説明 |
|----|------|
| ATTACK | 攻撃スキル |
| DEFENSE | 防御スキル |
| DEBUFF | デバフスキル |
| HEAL | 回復スキル |

### EvolutionType

| 値 | 説明 |
|----|------|
| EVOLUTION | 進化（段階が上がる） |
| DEVOLUTION | 退化（段階が下がる） |

## エンティティ関係図

```text
+------------------+
|      User        |
| (Unit1で定義)     |
+------------------+
| userId (PK)      |
+------------------+
        |
        | 1:1
        v
+------------------+        +---------------------+
|     Avatar       |        |   EvolutionPath     |
+------------------+        |   (マスターデータ)    |
| avatarId (PK)    |        +---------------------+
| userId (FK)      |        | pathId (PK)         |
| totalPoints      |        | name                |
| level            |        | stage               |
| evolutionStage   |------->| dominantCategory    |
| evolutionPathId  |  N:1   | categoryThreshold   |
| categoryPoints   |        | statsGrowth         |
| stats            |        | spriteSheetKey      |
| skillIds[]       |        +---------------------+
| spriteSheetKey   |               |
+------------------+               | 1:N
        |                          v
        | 1:N               +---------------------+
        v                   |      Skill          |
+---------------------+     |   (マスターデータ)    |
| EvolutionHistory    |     +---------------------+
+---------------------+     | skillId (PK)        |
| historyId (PK)      |     | name                |
| userId (FK)         |     | type                |
| avatarId (FK)       |     | power               |
| fromStage           |     | evolutionPathId(FK) |
| toStage             |     | requiredLevel       |
| type                |     | cooldown            |
| triggerPoints       |     +---------------------+
| occurredAt          |
+---------------------+
```

## DynamoDB テーブル設計

### Avatar テーブル

| キー | 属性 | 用途 |
|------|------|------|
| PK | userId | パーティションキー（1ユーザー1アバター） |

### EvolutionHistory テーブル

| キー | 属性 | 用途 |
|------|------|------|
| PK | userId | パーティションキー |
| SK | occurredAt#historyId | ソートキー（時系列取得） |

### EvolutionPath テーブル（マスターデータ）

| キー | 属性 | 用途 |
|------|------|------|
| PK | pathId | パーティションキー |

### Skill テーブル（マスターデータ）

| キー | 属性 | 用途 |
|------|------|------|
| PK | skillId | パーティションキー |
| GSI1-PK | evolutionPathId | 進化パス別スキル取得用 |

## 備考

- Avatar は 1ユーザーにつき1体（PK=userId で一意）
- categoryPoints はカテゴリ別の累計を保持し、進化パス判定に使用
- level は totalPoints から算出されるが、キャッシュとしてDBにも保存（毎回計算を避ける）
- EvolutionPath, Skill はマスターデータ。管理画面（Unit 5）から編集可能
- spriteSheetKey は S3 上のアセットパスに対応
