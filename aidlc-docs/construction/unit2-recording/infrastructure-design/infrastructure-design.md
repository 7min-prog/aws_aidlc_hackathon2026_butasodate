# Infrastructure Design - Unit 2: 行動記録 + ヘルスデータ連携

## AWSサービスマッピング

| 論理コンポーネント | AWSサービス | 設定 |
|-----------------|-----------|------|
| RecordingLambda | Lambda (Node.js 20.x) | メモリ256MB, タイムアウト10s |
| HealthSyncLambda | Lambda (Node.js 20.x) | メモリ256MB, タイムアウト15s |
| CategoriesLambda | Lambda (Node.js 20.x) | メモリ128MB, タイムアウト5s |
| API Gateway | REST API | Cognito Authorizer |
| ActivityRecordテーブル | DynamoDB (オンデマンド) | PK: userId, SK: recordedAt#recordId |
| HealthSyncRecordテーブル | DynamoDB (オンデマンド) | PK: userId, SK: syncDate#category |
| ActivityCategoryテーブル | DynamoDB (オンデマンド) | PK: categoryId |

## APIルーティング

| メソッド | パス | Lambda | 認証 |
|---------|------|--------|------|
| GET | /categories | CategoriesLambda | Cognito |
| GET | /categories/version | CategoriesLambda | Cognito |
| POST | /activities | RecordingLambda | Cognito |
| POST | /activities/batch | RecordingLambda | Cognito |
| GET | /activities | RecordingLambda | Cognito |
| DELETE | /activities/{recordId} | RecordingLambda | Cognito |
| GET | /activities/summary | RecordingLambda | Cognito |
| POST | /health-sync | HealthSyncLambda | Cognito |

## DynamoDBテーブル詳細

### ActivityRecordテーブル

| 項目 | 設定 |
|------|------|
| テーブル名 | butasodate-activity-records |
| 課金モード | オンデマンド（PAY_PER_REQUEST） |
| PK | userId (S) |
| SK | recordedAt#recordId (S) |
| GSI1名 | category-index |
| GSI1 PK | userId (S) |
| GSI1 SK | categoryId#recordedAt (S) |

### HealthSyncRecordテーブル

| 項目 | 設定 |
|------|------|
| テーブル名 | butasodate-health-sync-records |
| 課金モード | オンデマンド（PAY_PER_REQUEST） |
| PK | userId (S) |
| SK | syncDate#category (S) |

### ActivityCategoryテーブル

| 項目 | 設定 |
|------|------|
| テーブル名 | butasodate-activity-categories |
| 課金モード | オンデマンド（PAY_PER_REQUEST） |
| PK | categoryId (S) |
| 初期データ | CDKカスタムリソースでデフォルトカテゴリ8件投入 |

## Lambda構成

```text
backend/src/
├── handlers/
│   ├── recording.ts       # POST/GET/DELETE /activities, /activities/batch, /activities/summary
│   ├── health-sync.ts     # POST /health-sync
│   └── categories.ts      # GET /categories, /categories/version
├── services/
│   ├── recording-service.ts
│   ├── health-sync-service.ts
│   └── point-calculator.ts
├── connectors/
│   └── avatar-connector.ts    # Unit3 AvatarServiceへの連携IF
└── shared/
    ├── dynamo-client.ts
    ├── auth-middleware.ts     # Unit1で定義済み
    └── types.ts
```

## CDKスタック構成

```text
infra/lib/
├── stacks/
│   ├── auth-stack.ts          # Unit1（既存）
│   └── recording-stack.ts     # Unit2（新規）
│       ├─ DynamoDB: ActivityRecord, HealthSyncRecord, ActivityCategory
│       ├─ Lambda: Recording, HealthSync, Categories
│       ├─ API Gateway: /activities/*, /health-sync, /categories/*
│       └─ カスタムリソース: デフォルトカテゴリ投入
└── app.ts
```

## Unit3連携インターフェース（スタブ）

Unit3（アバター育成）が未実装の間、AvatarConnectorはスタブ実装とする：

```typescript
// avatar-connector.ts (スタブ)
export async function addPoints(userId: string, points: number, categoryType: string) {
  // Unit3実装後に実コネクタに差し替え
  console.log(`[STUB] addPoints: user=${userId}, points=${points}, type=${categoryType}`);
  return { totalPoints: points, level: 1 };
}
```

## コスト見積（ハッカソン規模）

| サービス | 推定月額 | 根拠 |
|---------|---------|------|
| Lambda | $0 | 無料枠内（100万リクエスト/月） |
| DynamoDB | $0 | 無料枠内（25GB, 25WCU/25RCU相当） |
| API Gateway | $0 | 無料枠内（100万API呼び出し/月） |
| **合計** | **$0** | ハッカソンデモ規模 |
