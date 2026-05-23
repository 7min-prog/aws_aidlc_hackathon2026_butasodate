# デプロイ手順書

## 前提条件

- AWS CLI設定済み（`aws sts get-caller-identity` で対象アカウント確認）
- Node.js 20.x 以上
- CDK Bootstrap済み（未実施なら `npx cdk bootstrap`）
- リージョン: ap-northeast-1

## 1. バックエンドビルド

各ハンドラーの依存インストール＋TypeScriptコンパイル:

```bash
cd backend/auth-handler && npm install && npm run build && cd ../..
cd backend/recording-handler && npm install && npm run build && cd ../..
cd backend/avatar-handler && npm install && npm run build && cd ../..
cd backend/battle-ws-handler && npm install && npm run build && cd ../..
cd backend/social-handler && npm install && npm run build && cd ../..
cd backend/admin-handler && npm install && npm run build && cd ../..
```

## 2. CDK Synth（テンプレート生成確認）

```bash
cd infrastructure
npm install
npx cdk synth
```

エラーが出なければOK。生成されるスタック:
- ButaAuthStack
- ButaRecordingStack
- ButaAvatarStack
- ButaBattleSocialStack
- ButaAdminStack

## 3. CDK Deploy

```bash
npx cdk deploy --all --require-approval never
```

初回は10〜15分かかる。デプロイ完了後、Outputsに以下が表示される:

| Output | 用途 |
|---|---|
| ButaAuthStack.ApiUrl | 認証API エンドポイント |
| ButaAuthStack.UserPoolId | Cognito User Pool ID |
| ButaAuthStack.UserPoolClientId | Cognito Client ID |
| ButaRecordingStack.RecordingApiUrl | 記録API エンドポイント |
| ButaAvatarStack.AvatarApiUrl | アバターAPI エンドポイント |
| ButaAvatarStack.AssetsBucketName | スプライトアセットS3バケット |
| ButaBattleSocialStack.WebSocketUrl | バトルWebSocket URL |
| ButaBattleSocialStack.SocialApiUrl | ソーシャルAPI エンドポイント |
| ButaAdminStack.AdminApiUrl | 管理画面API エンドポイント |
| ButaAdminStack.AdminSpaUrl | 管理画面SPA URL |

## 4. マスターデータ投入

デプロイ後、以下のテーブルにデータを投入する。

### 4.1 ActivityCategory（CDKカスタムリソースで自動投入済み）

初回デプロイ時に8件+1件(_meta)が自動投入される。確認:

```bash
aws dynamodb scan --table-name butasodate-activity-categories --region ap-northeast-1
```

### 4.2 PigSpecies（ぶた図鑑）

```bash
aws dynamodb put-item --table-name butasodate-pig-species --region ap-northeast-1 --item '{
  "speciesId": {"S": "species-initial"},
  "name": {"S": "こぶた"},
  "description": {"S": "生まれたばかりのぶた"},
  "stage": {"N": "1"},
  "dominantCategory": {"S": "MIXED"},
  "statsGrowth": {"M": {"hp": {"N": "5"}, "attack": {"N": "3"}, "defense": {"N": "3"}, "speed": {"N": "3"}}},
  "spriteSheetKey": {"S": "sprites/stage1/default"},
  "iconKey": {"S": "pig-baby"},
  "isActive": {"BOOL": true}
}'
```

※ 残りの進化先Speciesも同様に投入（管理画面からも可能）

### 4.3 EvolutionRoute（進化ルート）

```bash
aws dynamodb put-item --table-name butasodate-evolution-routes --region ap-northeast-1 --item '{
  "routeId": {"S": "route-stage1-to-gourmet"},
  "fromSpeciesId": {"S": "species-initial"},
  "toSpeciesId": {"S": "species-gourmet"},
  "requiredLevel": {"N": "5"},
  "categoryThreshold": {"N": "0.6"},
  "conditionCategory": {"S": "FOOD"},
  "priority": {"N": "1"}
}'
```

### 4.4 Skills（スキル定義）

```bash
aws dynamodb put-item --table-name butasodate-skills --region ap-northeast-1 --item '{
  "skillId": {"S": "skill-ramen-throw"},
  "name": {"S": "ラーメン投げ"},
  "type": {"S": "ATTACK"},
  "targetStat": {"S": "hp"},
  "multiplier": {"N": "1.5"},
  "cooldown": {"N": "2"},
  "speciesId": {"S": "species-gourmet"},
  "requiredLevel": {"N": "5"},
  "spriteAnimationKey": {"S": "anim-ramen-throw"}
}'
```

※ 追加スキルも同様に投入。`speciesId` でどのぶたが覚えるか指定。

### 4.5 GameConfig（ゲーム定数）

```bash
aws dynamodb put-item --table-name butasodate-game-config --region ap-northeast-1 --item '{"configKey":{"S":"INITIAL_STATS"},"value":{"M":{"hp":{"N":"50"},"attack":{"N":"10"},"defense":{"N":"10"},"speed":{"N":"10"}}},"updatedAt":{"S":"2026-05-24T00:00:00Z"},"updatedBy":{"S":"deploy"}}'
aws dynamodb put-item --table-name butasodate-game-config --region ap-northeast-1 --item '{"configKey":{"S":"MAX_LEVEL"},"value":{"N":"30"},"updatedAt":{"S":"2026-05-24T00:00:00Z"},"updatedBy":{"S":"deploy"}}'
aws dynamodb put-item --table-name butasodate-game-config --region ap-northeast-1 --item '{"configKey":{"S":"EVOLUTION_LEVEL_STAGE2"},"value":{"N":"5"},"updatedAt":{"S":"2026-05-24T00:00:00Z"},"updatedBy":{"S":"deploy"}}'
aws dynamodb put-item --table-name butasodate-game-config --region ap-northeast-1 --item '{"configKey":{"S":"EVOLUTION_LEVEL_STAGE3"},"value":{"N":"15"},"updatedAt":{"S":"2026-05-24T00:00:00Z"},"updatedBy":{"S":"deploy"}}'
aws dynamodb put-item --table-name butasodate-game-config --region ap-northeast-1 --item '{"configKey":{"S":"CATEGORY_THRESHOLD"},"value":{"N":"0.6"},"updatedAt":{"S":"2026-05-24T00:00:00Z"},"updatedBy":{"S":"deploy"}}'
aws dynamodb put-item --table-name butasodate-game-config --region ap-northeast-1 --item '{"configKey":{"S":"LEVEL_FORMULA_COEFFICIENT"},"value":{"N":"50"},"updatedAt":{"S":"2026-05-24T00:00:00Z"},"updatedBy":{"S":"deploy"}}'
aws dynamodb put-item --table-name butasodate-game-config --region ap-northeast-1 --item '{"configKey":{"S":"BATTLE_TURN_TIMEOUT_SEC"},"value":{"N":"20"},"updatedAt":{"S":"2026-05-24T00:00:00Z"},"updatedBy":{"S":"deploy"}}'
aws dynamodb put-item --table-name butasodate-game-config --region ap-northeast-1 --item '{"configKey":{"S":"BATTLE_TOTAL_TIMEOUT_SEC"},"value":{"N":"300"},"updatedAt":{"S":"2026-05-24T00:00:00Z"},"updatedBy":{"S":"deploy"}}'
aws dynamodb put-item --table-name butasodate-game-config --region ap-northeast-1 --item '{"configKey":{"S":"MATCH_QUEUE_TIMEOUT_SEC"},"value":{"N":"30"},"updatedAt":{"S":"2026-05-24T00:00:00Z"},"updatedBy":{"S":"deploy"}}'
aws dynamodb put-item --table-name butasodate-game-config --region ap-northeast-1 --item '{"configKey":{"S":"ELO_K_FACTOR"},"value":{"N":"32"},"updatedAt":{"S":"2026-05-24T00:00:00Z"},"updatedBy":{"S":"deploy"}}'
aws dynamodb put-item --table-name butasodate-game-config --region ap-northeast-1 --item '{"configKey":{"S":"ELO_INITIAL_POINTS"},"value":{"N":"1000"},"updatedAt":{"S":"2026-05-24T00:00:00Z"},"updatedBy":{"S":"deploy"}}'
```

## 5. Flutter接続設定

`frontend/lib/shared/constants.dart` のプレースホルダーをデプロイ出力値に差し替え:

```dart
static const authApiBase = 'https://{ButaAuthStack.ApiUrl}';
static const recordingApiBase = 'https://{ButaRecordingStack.RecordingApiUrl}';
static const avatarApiBase = 'https://{ButaAvatarStack.AvatarApiUrl}';
static const socialApiBase = 'https://{ButaBattleSocialStack.SocialApiUrl}';
static const battleWsUrl = 'wss://{ButaBattleSocialStack.WebSocketUrl}';
static const assetsBaseUrl = 'https://{ButaAvatarStack.AssetsBucketName}.s3.ap-northeast-1.amazonaws.com/assets/';
```

CDK Output値の確認コマンド:

```bash
aws cloudformation describe-stacks --region ap-northeast-1 \
  --query "Stacks[].Outputs[].[OutputKey,OutputValue]" --output table
```

## 6. 疎通テスト

```bash
# サインアップ
curl -X POST https://{AuthApiUrl}/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test1234!"}'

# ログイン
curl -X POST https://{AuthApiUrl}/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test1234!"}'

# アバター作成（要Bearer token）
curl -X POST https://{AvatarApiUrl}/avatar \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {idToken}" \
  -d '{"name":"テストぶた"}'

# 行動記録
curl -X POST https://{RecordingApiUrl}/activities \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {idToken}" \
  -d '{"records":[{"categoryId":"food_late_ramen"}]}'
```

## 7. 削除（クリーンアップ）

```bash
cd infrastructure
npx cdk destroy --all
```

全リソースが削除される（DynamoDBはRemovalPolicy.DESTROYで設定済み）。
