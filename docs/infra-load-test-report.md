# インフラテスト・負荷テスト レポート

実行日時: 2026-05-25 22:58 JST

---

## 1. CDKインフラテスト（CDK Assertions）

### 概要

AWS CDKのStack定義が期待通りのCloudFormationリソースを生成するかを検証。
テストはシンセシス（合成）のみで、実際のデプロイは不要。

### 結果: ✅ 28/28 ALL PASS

| Stack | Tests | 結果 |
|:--|:--:|:--:|
| AuthStack | 6 | ✅ |
| RecordingStack | 5 | ✅ |
| AvatarStack | 6 | ✅ |
| BattleSocialStack | 6 | ✅ |
| AdminStack | 5 | ✅ |

### テスト項目一覧

#### AuthStack
| # | チェック内容 | 結果 |
|:--|:--|:--:|
| 1 | Cognito User Poolがemail sign-inで作成されること | ✅ |
| 2 | User Pool Clientがsecretなし + USER_PASSWORD_AUTH有効 | ✅ |
| 3 | user-profilesテーブルがPAY_PER_REQUESTで作成されること | ✅ |
| 4 | nickname-index GSIが存在すること | ✅ |
| 5 | LambdaがNode.js 20.xで作成されること | ✅ |
| 6 | REST API Gatewayが作成されること | ✅ |

#### RecordingStack
| # | チェック内容 | 結果 |
|:--|:--|:--:|
| 7 | activity-recordsテーブル（userId + sk構成） | ✅ |
| 8 | activity-categoriesテーブル | ✅ |
| 9 | category-index GSI | ✅ |
| 10 | recording Lambda（buta-recording-handler） | ✅ |
| 11 | Lambda環境変数に正しいテーブル名が設定 | ✅ |

#### AvatarStack
| # | チェック内容 | 結果 |
|:--|:--|:--:|
| 12 | avatarsテーブル（userId） | ✅ |
| 13 | evolution-historyテーブル（複合ソートキー） | ✅ |
| 14 | pig-speciesテーブル + stage-index GSI | ✅ |
| 15 | evolution-routesテーブル | ✅ |
| 16 | S3アセットバケット | ✅ |
| 17 | avatar Lambda | ✅ |

#### BattleSocialStack
| # | チェック内容 | 結果 |
|:--|:--|:--:|
| 18 | connectionsテーブル | ✅ |
| 19 | match-queueテーブル | ✅ |
| 20 | connections userId-index GSI | ✅ |
| 21 | WebSocket API (API Gateway V2) | ✅ |
| 22 | battle-ws Lambda | ✅ |
| 23 | 全DynamoDBテーブルがPAY_PER_REQUEST | ✅ |

#### AdminStack
| # | チェック内容 | 結果 |
|:--|:--|:--:|
| 24 | audit-logテーブル（logId + timestamp） | ✅ |
| 25 | game-configテーブル（configKey） | ✅ |
| 26 | admin Lambda（buta-admin-handler-dev） | ✅ |
| 27 | CloudFront Distribution | ✅ |
| 28 | 全DynamoDBテーブルがPAY_PER_REQUEST | ✅ |

---

## 2. 負荷テスト（Artillery）

### 概要

デプロイ済みAPIに対して段階的負荷をかけ、Lambda/DynamoDB/API Gatewayの性能を検証する。

### テストシナリオ

| シナリオ | Weight | 概要 |
|:--|:--:|:--|
| Login flow | 30% | POST /auth/login → トークン取得 |
| Record + Avatar | 50% | ログイン → POST /activities → GET /avatar → GET /score-detail |
| Read summary | 20% | ログイン → GET /activities/summary → GET /activities |

### 負荷プロファイル

```
Phase 1: Warm up     | 30秒 |  5 req/s  (合計 150リクエスト)
Phase 2: Sustained   | 60秒 | 20 req/s  (合計 1200リクエスト)
Phase 3: Peak        | 30秒 | 50 req/s  (合計 1500リクエスト)
─────────────────────────────────────────────
Total                 | 2分  |            合計 約2850リクエスト
```

### 実行方法

```bash
# インストール
npm install -g artillery@latest

# ドライラン（1リクエストのみ）
artillery run --count 1 --num 1 load-tests/scenario.yml

# 本番実行
artillery run --output load-tests/report.json load-tests/scenario.yml
artillery report load-tests/report.json --output load-tests/report.html
```

### 確認ポイント

| 観点 | 閾値 | 確認方法 |
|:--|:--|:--|
| p95レスポンスタイム | < 3000ms | Artillery report |
| p99レスポンスタイム | < 5000ms | Artillery report |
| エラー率 | < 1% | Artillery report |
| Lambda コールドスタート | 初回のみ許容 | CloudWatch Logs |
| DynamoDB スロットリング | 0件 | CloudWatch ThrottledRequests |
| API Gateway 429 | 0件 | Artillery error count |

### 前提条件

- テスト用Cognitoユーザー `loadtest@example.com` が事前登録済みであること
- `infrastructure/cdk-outputs.json` のAPIエンドポイントが有効であること

---

## ファイル構成

```
infrastructure/
├── tests/
│   └── stacks.test.ts          ← CDK Assertionsテスト (28 tests)
├── package.json                ← jest設定追加済み
load-tests/
├── scenario.yml                ← Artillery負荷テストシナリオ
└── README.md                   ← 実行手順
```
