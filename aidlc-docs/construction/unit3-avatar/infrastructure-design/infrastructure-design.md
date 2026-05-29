# Infrastructure Design - Unit 3: アバター育成

## AWSサービスマッピング

| 論理コンポーネント | AWSサービス | 設定 |
|-----------------|-----------|------|
| AvatarLambda | Lambda (Node.js 20.x) | メモリ256MB, タイムアウト10s |
| API Gateway | REST API（Unit 1/2と共有） | Cognito Authorizer |
| Avatarテーブル | DynamoDB (オンデマンド) | PK: userId |
| EvolutionHistoryテーブル | DynamoDB (オンデマンド) | PK: userId, SK: occurredAt#historyId |
| EvolutionPathテーブル | DynamoDB (オンデマンド) | PK: pathId |
| Skillテーブル | DynamoDB (オンデマンド) | PK: skillId, GSI: evolutionPathId |
| SpriteAssetsBucket | S3 | パブリック読み取り（assets/sprites/） |

## APIルーティング

| メソッド | パス | Lambda | 認証 |
|---------|------|--------|------|
| POST | /avatar | AvatarLambda | Cognito |
| GET | /avatar | AvatarLambda | Cognito |
| GET | /avatar/evolution-history | AvatarLambda | Cognito |
| GET | /avatar/score-detail | AvatarLambda | Cognito |

**内部呼び出し（Unit 2 Lambda から直接 import）**:
- AvatarService.addPoints() — RecordingLambda / HealthSyncLambda 内で使用
- AvatarService.deductPoints() — RecordingLambda 内で使用

## DynamoDBテーブル詳細

### Avatar テーブル

| 項目 | 設定 |
|------|------|
| テーブル名 | butasodate-avatars |
| 課金モード | オンデマンド（PAY_PER_REQUEST） |
| PK | userId (S) |
| SK | なし（1ユーザー1アバター） |

### EvolutionHistory テーブル

| 項目 | 設定 |
|------|------|
| テーブル名 | butasodate-evolution-history |
| 課金モード | オンデマンド（PAY_PER_REQUEST） |
| PK | userId (S) |
| SK | occurredAt#historyId (S) |

### EvolutionPath テーブル（マスターデータ）

| 項目 | 設定 |
|------|------|
| テーブル名 | butasodate-evolution-paths |
| 課金モード | オンデマンド（PAY_PER_REQUEST） |
| PK | pathId (S) |
| 初期データ | CDKカスタムリソースで9件投入 |

### Skill テーブル（マスターデータ）

| 項目 | 設定 |
|------|------|
| テーブル名 | butasodate-skills |
| 課金モード | オンデマンド（PAY_PER_REQUEST） |
| PK | skillId (S) |
| GSI1名 | path-index |
| GSI1 PK | evolutionPathId (S) |
| 初期データ | CDKカスタムリソースで12件投入 |

## S3バケット

| 項目 | 設定 |
|------|------|
| バケット名 | butasodate-assets-{accountId}-dev |
| パブリックアクセス | assets/sprites/* のみ読み取り許可 |
| バケットポリシー | s3:GetObject Allow * (prefix: assets/sprites/) |
| CORS | Flutter アプリからのGET許可 |
| バージョニング | 無効（ハッカソン向け） |
| ライフサイクル | なし |

**アセット構成**:

```text
assets/sprites/
├── stage1/
│   └── default.png          # 初期段階スプライトシート
├── stage2/
│   ├── food.png             # グルメぶた
│   ├── lifestyle.png        # ぐうたらぶた
│   └── mixed.png            # まんまるぶた
└── stage3/
    ├── food_gorge.png       # 暴食帝ぶた
    ├── food_gourmet.png     # 夜食神ぶた
    ├── life_night.png       # 不夜城ぶた
    ├── life_sloth.png       # 万年床ぶた
    ├── mixed_chaos.png      # 大魔王ぶた
    └── mixed_entropy.png    # 混沌王ぶた
```

## Lambda構成

```text
backend/src/
├── handlers/
│   └── avatar.ts            # POST/GET /avatar, /avatar/*
├── services/
│   ├── avatar-service.ts    # addPoints, deductPoints, createAvatar, getAvatar
│   └── evolution-engine.ts  # calculateLevel, checkEvolution, checkDevolution, recalculateStats
├── data/
│   └── master-data-cache.ts # EvolutionPath/Skill インメモリキャッシュ
└── shared/
    ├── dynamo-client.ts     # Unit 1/2 と共有
    └── types.ts
```

## CDKスタック構成

```text
infra/lib/
├── stacks/
│   ├── auth-stack.ts          # Unit 1（既存）
│   ├── recording-stack.ts     # Unit 2（既存）
│   └── avatar-stack.ts        # Unit 3（新規）
│       ├─ DynamoDB: Avatar, EvolutionHistory, EvolutionPath, Skill
│       ├─ Lambda: AvatarLambda
│       ├─ S3: SpriteAssetsBucket
│       ├─ API Gateway: /avatar/*
│       └─ カスタムリソース: マスターデータ投入（9パス + 12スキル）
└── app.ts
```

## Unit 2 連携（スタブ差し替え）

Unit 2 の `avatar-connector.ts`（スタブ）を実コネクタに差し替え：

```typescript
// avatar-connector.ts (実装)
import { AvatarService } from '../services/avatar-service';

export async function addPoints(userId: string, points: number, categoryType: string) {
  return AvatarService.addPoints(userId, points, categoryType);
}

export async function deductPoints(userId: string, points: number, categoryType: string) {
  return AvatarService.deductPoints(userId, points, categoryType);
}
```

**注**: Unit 2 と Unit 3 は同一Lambdaパッケージ内に配置するか、共有レイヤーで AvatarService を参照する。ハッカソン規模では単一Lambda（モノリシック）で十分。

## コスト見積（ハッカソン規模）

| サービス | 推定月額 | 根拠 |
|---------|---------|------|
| Lambda | $0 | 無料枠内 |
| DynamoDB (4テーブル) | $0 | 無料枠内（25GB） |
| S3 | $0 | 5GB無料枠内、スプライト7枚で数MB |
| API Gateway | $0 | 無料枠内 |
| **合計** | **$0** | ハッカソンデモ規模 |
