# Logical Components - Unit 2: 行動記録 + ヘルスデータ連携

## コンポーネント構成図

```text
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────┐     │
│  │ Recording    │  │ Health Sync  │  │ Offline Sync      │     │
│  │ Provider     │  │ Provider     │  │ Manager           │     │
│  └──────┬───────┘  └──────┬───────┘  └─────────┬─────────┘     │
│         │                  │                    │               │
│  ┌──────┴───────┐  ┌──────┴───────┐  ┌────────┴────────┐     │
│  │ Recording    │  │ Health       │  │ Connectivity     │     │
│  │ Repository   │  │ Repository   │  │ Monitor          │     │
│  └──────┬───────┘  └──────┬───────┘  └─────────────────┘     │
│         │                  │                                    │
│  ┌──────┴─────────────────┴───────────────────────────────┐    │
│  │                    Data Layer                            │    │
│  ├─────────────────┬─────────────────┬────────────────────┤    │
│  │ Remote          │ Local (Hive)    │ Health Platform     │    │
│  │ Datasource      │ Datasource      │ Datasource          │    │
│  │ (API Client)    │ (Cache/Queue)   │ (HealthKit/HC)      │    │
│  └─────────┬───────┴────────┬────────┴────────┬───────────┘    │
│            │                │                  │               │
└────────────┼────────────────┼──────────────────┼───────────────┘
             │                │                  │
             ▼                ▼                  ▼
┌────────────────────┐ ┌──────────┐  ┌──────────────────────┐
│   API Gateway      │ │  Hive    │  │ HealthKit /          │
│   + Lambda         │ │  Box     │  │ Health Connect       │
└────────┬───────────┘ └──────────┘  └──────────────────────┘
         │
         ▼
┌────────────────────────────────────────────┐
│              AWS Backend                    │
├────────────────────────────────────────────┤
│                                            │
│  ┌─────────────────┐  ┌────────────────┐  │
│  │ Recording       │  │ Health Sync    │  │
│  │ Lambda          │  │ Lambda         │  │
│  └────────┬────────┘  └───────┬────────┘  │
│           │                    │           │
│  ┌────────┴────────────────────┴────────┐  │
│  │          Service Layer               │  │
│  ├──────────────────────────────────────┤  │
│  │ RecordingService  │ HealthSyncService│  │
│  │ PointCalculator   │ AvatarConnector  │  │
│  └────────┬──────────┴────────┬─────────┘  │
│           │                    │           │
│  ┌────────┴────────────────────┴────────┐  │
│  │           DynamoDB Tables            │  │
│  ├──────────────────────────────────────┤  │
│  │ ActivityRecord │ HealthSyncRecord    │  │
│  │ ActivityCategory (Master)            │  │
│  └──────────────────────────────────────┘  │
│                                            │
└────────────────────────────────────────────┘
```

## コンポーネント責務

### フロントエンド層

| コンポーネント | 責務 |
|--------------|------|
| RecordingProvider | 記録画面の状態管理、記録操作の実行 |
| HealthSyncProvider | 起動時同期の実行、サマリー状態管理 |
| OfflineSyncManager | 未同期レコードの検出・バッチ送信・リトライ |
| ConnectivityMonitor | ネットワーク状態監視、復帰トリガー発火 |
| RecordingRepository | オンライン/オフライン判定、適切なdatasource振り分け |
| HealthRepository | Health API取得＋リモートAPI送信の統合 |
| RemoteDatasource | API Clientラッパー（リトライ/タイムアウト内包） |
| LocalDatasource | Hive操作（PENDING保存/SYNCED更新/50件制限） |
| HealthPlatformDatasource | HealthKit/HealthConnect APIラッパー（10sタイムアウト） |

### バックエンド層

| コンポーネント | 責務 |
|--------------|------|
| RecordingLambda | /activities, /activities/batch, /activities/summary |
| HealthSyncLambda | /health-sync |
| CategoriesLambda | /categories, /categories/version |
| RecordingService | 記録作成、冪等性チェック、バッチ処理 |
| HealthSyncService | ヘルスデータ評価、ポイント計算 |
| PointCalculator | BR-1/BR-2のポイント計算ロジック集約 |
| AvatarConnector | AvatarService（Unit3）との連携インターフェース |

## DynamoDBテーブル設計（確定）

### ActivityRecordテーブル

```text
PK: userId (String)
SK: recordedAt#recordId (String)  ← ISO8601#UUID で時系列ソート＋一意性

GSI1:
  PK: userId (String)
  SK: categoryId#recordedAt (String)  ← カテゴリ別フィルター

属性: categoryId, source, points, memo, createdAt
```

### HealthSyncRecordテーブル

```text
PK: userId (String)
SK: syncDate#category (String)  ← 日付+カテゴリで一意（冪等性キー）

属性: rawValue, evaluation, points, createdAt
```

### ActivityCategoryテーブル

```text
PK: categoryId (String)

属性: name, type, basePoints, iconKey, sortOrder, isActive, version
```

## ネットワーク復帰時のシーケンス

```text
[ConnectivityMonitor] ─── onConnected ───→ [OfflineSyncManager]
                                                    │
                                            ┌───────┴───────┐
                                            │ PENDING > 0?  │
                                            └───────┬───────┘
                                                    │ YES
                                                    ▼
                                           [POST /activities/batch]
                                                    │
                                            ┌───────┴───────┐
                                            │   成功？       │
                                            ├─── YES ───→ SYNCED更新
                                            └─── NO ────→ リトライ（max 3）
                                                              │ 3回失敗
                                                              ▼
                                                    トースト通知表示
                                                    PENDING保持（次回起動で再試行）
```
