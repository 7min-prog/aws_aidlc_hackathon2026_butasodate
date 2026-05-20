# Domain Entities - Unit 2: 行動記録 + ヘルスデータ連携

## エンティティ一覧

### ActivityRecord（行動記録）

| 属性 | 型 | 必須 | 説明 |
|------|-----|------|------|
| recordId | String (UUID) | ✅ | 一意識別子 |
| userId | String (UUID) | ✅ | 記録者のユーザーID |
| categoryId | String | ✅ | カテゴリID（マスターデータ参照） |
| source | Enum (RecordSource) | ✅ | 記録元（MANUAL / AUTO_DETECTED） |
| points | int | ✅ | 獲得ポイント |
| memo | String? | ❌ | メモ（最大100文字） |
| recordedAt | DateTime | ✅ | 行動発生日時 |
| createdAt | DateTime | ✅ | レコード作成日時 |

### ActivityCategory（行動カテゴリ - マスターデータ）

| 属性 | 型 | 必須 | 説明 |
|------|-----|------|------|
| categoryId | String | ✅ | カテゴリID |
| name | String | ✅ | カテゴリ名 |
| type | Enum (CategoryType) | ✅ | 食事系 / 生活系 |
| basePoints | int | ✅ | 基本付与ポイント |
| iconKey | String | ✅ | アイコン識別キー |
| sortOrder | int | ✅ | 表示順 |
| isActive | bool | ✅ | 有効フラグ |
| version | int | ✅ | マスターデータバージョン（キャッシュ整合性用） |

### HealthSyncRecord（ヘルスデータ同期記録）

| 属性 | 型 | 必須 | 説明 |
|------|-----|------|------|
| syncId | String (UUID) | ✅ | 一意識別子 |
| userId | String (UUID) | ✅ | ユーザーID |
| syncDate | Date | ✅ | 同期対象日 |
| category | Enum (HealthCategory) | ✅ | データカテゴリ |
| rawValue | double | ✅ | 取得した生値 |
| evaluation | Enum (HealthEvaluation) | ✅ | 評価結果 |
| points | int | ✅ | 算出ポイント（正:加算/負:減算） |
| createdAt | DateTime | ✅ | レコード作成日時 |

### HealthSyncSettings（ヘルスデータ連携設定 - デバイスローカル）

| 属性 | 型 | 必須 | 説明 |
|------|-----|------|------|
| isEnabled | bool | ✅ | 連携有効フラグ |
| enabledCategories | Map\<HealthCategory, bool\> | ✅ | カテゴリ別有効設定 |
| lastSyncDates | Map\<HealthCategory, Date\> | ✅ | カテゴリ別最終同期日 |
| sleepBedtimeTarget | TimeOfDay | ✅ | 就寝基準値（デフォルト23:00） |
| sleepDurationTarget | Duration | ✅ | 睡眠時間基準値（デフォルト7h） |
| stepsTarget | int | ✅ | 歩数目標（デフォルト8000） |
| previousWeight | double? | ❌ | 前回体重値（初回はnull） |

## 列挙型

### RecordSource

| 値 | 説明 |
|----|------|
| MANUAL | 手動記録 |
| AUTO_DETECTED | ヘルスデータから自動検出 |

### CategoryType

| 値 | 説明 |
|----|------|
| FOOD | 食事系（深夜ラーメン、暴飲暴食、間食等） |
| LIFESTYLE | 生活系（夜更かし、二度寝、運動サボり等） |

### HealthCategory

| 値 | 説明 |
|----|------|
| WEIGHT | 体重・BMI |
| STEPS | 歩数 |
| SLEEP | 睡眠（就寝・起床・睡眠時間） |

### HealthEvaluation

| 値 | 説明 |
|----|------|
| UNHEALTHY | 不健康（ポイント加算） |
| HEALTHY | 健康（ポイント減算） |
| NEUTRAL | 変動なし |

## デフォルトカテゴリ（マスターデータ初期値）

| categoryId | name | type | basePoints |
|------------|------|------|-----------|
| food_late_ramen | 深夜ラーメン | FOOD | 12 |
| food_binge | 暴飲暴食 | FOOD | 12 |
| food_snack | 間食 | FOOD | 12 |
| food_junkfood | ジャンクフード | FOOD | 12 |
| life_stay_up | 夜更かし | LIFESTYLE | 10 |
| life_oversleep | 二度寝 | LIFESTYLE | 10 |
| life_skip_exercise | 運動サボり | LIFESTYLE | 10 |
| life_binge_watch | だらだら動画視聴 | LIFESTYLE | 10 |

## エンティティ関係図

```text
+------------------+        +---------------------+
|      User        |        | ActivityCategory    |
| (Unit1で定義)     |        | (マスターデータ)      |
+------------------+        +---------------------+
| userId (PK)      |        | categoryId (PK)     |
+------------------+        | name                |
        |                   | type (FOOD/LIFESTYLE)|
        | 1:N               | basePoints          |
        v                   | isActive            |
+------------------+        +---------------------+
| ActivityRecord   |               |
+------------------+               | N:1
| recordId (PK)    |<--------------+
| userId (FK)      |
| categoryId (FK)  |
| source           |
| points           |
| memo             |
| recordedAt       |
+------------------+
        |
        | (userId + syncDate)
        |
+---------------------+
| HealthSyncRecord    |
+---------------------+
| syncId (PK)         |
| userId (FK)         |
| syncDate            |
| category            |
| rawValue            |
| evaluation          |
| points              |
+---------------------+

[デバイスローカル]
+---------------------+
| HealthSyncSettings  |
+---------------------+
| isEnabled           |
| enabledCategories   |
| lastSyncDates       |
| sleepBedtimeTarget  |
| sleepWakeTarget     |
| sleepDurationTarget |
| stepsTarget         |
+---------------------+
```

## DynamoDBテーブル設計

### ActivityRecordテーブル

| キー | 属性 | 用途 |
|------|------|------|
| PK | userId | パーティションキー |
| SK | recordedAt#recordId | ソートキー（日時順取得） |
| GSI1-PK | userId | カテゴリフィルター用 |
| GSI1-SK | categoryId#recordedAt | カテゴリ別日時順 |

### HealthSyncRecordテーブル

| キー | 属性 | 用途 |
|------|------|------|
| PK | userId | パーティションキー |
| SK | syncDate#category | ソートキー（日付+カテゴリで一意） |

### ActivityCategoryテーブル

| キー | 属性 | 用途 |
|------|------|------|
| PK | categoryId | パーティションキー |

## 備考

- ActivityRecordの`points`は記録時に計算し保存（再計算不要）
- HealthSyncSettingsはSharedPreferences（デバイスローカル）に保持
- オフライン時のActivityRecordはローカルDB（SQLite/Hive）にキャッシュ→オンライン復帰時に同期
- ActivityCategoryは管理画面（Unit5）から追加・変更可能
