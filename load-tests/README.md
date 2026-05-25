# 負荷テスト

## セットアップ

```bash
npm install -g artillery@latest
artillery --version
```

## 実行方法

### ドライラン（接続確認）
```bash
artillery run --count 1 --num 1 load-tests/scenario.yml
```

### 本番負荷テスト
```bash
artillery run load-tests/scenario.yml
```

### レポート出力付き
```bash
artillery run --output load-tests/report.json load-tests/scenario.yml
artillery report load-tests/report.json --output load-tests/report.html
```

## 前提条件

- `loadtest@example.com` / `LoadTest1234!` でCognitoユーザーが登録済みであること
- APIがデプロイ済みであること（`infrastructure/cdk-outputs.json` のURLを使用）

## テストシナリオ

| シナリオ | Weight | フロー |
|:--|:--:|:--|
| Login flow | 3 | ログイン → トークン取得 |
| Record + Avatar | 5 | ログイン → 記録作成 → アバター取得 → スコア詳細 |
| Read summary | 2 | ログイン → サマリー取得 → 履歴取得 |

## 負荷プロファイル

| フェーズ | 時間 | リクエスト/秒 |
|:--|:--:|:--:|
| Warm up | 30秒 | 5 req/s |
| Sustained load | 60秒 | 20 req/s |
| Peak load | 30秒 | 50 req/s |

## 確認ポイント

- Lambda コールドスタートによるレイテンシ増加
- DynamoDB PAY_PER_REQUEST のスロットリング発生有無
- API Gateway の429レート制限
- p95/p99 レスポンスタイム
