# Integration Test Instructions

## Purpose

デプロイ後に実際のAWSサービス間の連携を確認する。

## Prerequisites

- `cdk deploy --all` が完了していること
- `infrastructure/cdk-outputs.json` からAPI URLを取得済み

## 環境変数設定

```bash
export AUTH_API="https://ubw8w4wnp7.execute-api.ap-northeast-1.amazonaws.com/dev"
export RECORDING_API="https://tlw1w8knh7.execute-api.ap-northeast-1.amazonaws.com/dev"
export AVATAR_API="https://dgjfsg2e9b.execute-api.ap-northeast-1.amazonaws.com/dev"
```

## テストシナリオ

### Scenario 1: 認証フロー（サインアップ → 確認 → ログイン）

```bash
# サインアップ
curl -s -X POST $AUTH_API/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"inttest@example.com","password":"Test1234!"}' | jq .
# Expected: 201

# ログイン
curl -s -X POST $AUTH_API/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"inttest@example.com","password":"Test1234!"}' | jq .
# Expected: 200, accessToken + refreshToken
export TOKEN=$(curl -s -X POST $AUTH_API/auth/login -H "Content-Type: application/json" -d '{"email":"inttest@example.com","password":"Test1234!"}' | jq -r .idToken)
```

### Scenario 2: 行動記録 → アバターポイント加算

```bash
# 記録作成
curl -s -X POST $RECORDING_API/activities \
  -H "Content-Type: application/json" \
  -H "Authorization: $TOKEN" \
  -d '{"records":[{"categoryId":"food_ramen","memo":"深夜ラーメン"}]}' | jq .
# Expected: 201, avatar.totalPoints が増加

# アバター確認
curl -s -X GET $AVATAR_API/avatar \
  -H "Authorization: $TOKEN" | jq .
# Expected: 200, totalPoints > 0
```

### Scenario 3: ランキング・ソーシャル

```bash
# ランキング取得
curl -s -X GET $AUTH_API/rankings | jq .
# Expected: 200, rankings array

# 自分のランキング
curl -s -X GET $AUTH_API/rankings/me \
  -H "Authorization: $TOKEN" | jq .
# Expected: 200
```

### Scenario 4: エラーケース

```bash
# 認証なしアクセス
curl -s -X GET $RECORDING_API/activities | jq .
# Expected: 401

# 不正パスワード
curl -s -X POST $AUTH_API/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"inttest@example.com","password":"wrong"}' | jq .
# Expected: 401
```

## E2E Tests (Playwright)

```bash
cd frontend/e2e
npm ci
npx playwright install chromium --with-deps
npx playwright test
```

32テストが全画面遷移をカバー。

## Cleanup

```bash
aws cognito-idp admin-delete-user \
  --user-pool-id <USER_POOL_ID> \
  --username inttest@example.com
```
