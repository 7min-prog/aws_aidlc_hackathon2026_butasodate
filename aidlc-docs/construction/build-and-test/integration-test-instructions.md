# Integration Test Instructions

## Purpose
デプロイ後に実際のAWSサービス間の連携を確認する。

## Prerequisites
- `cdk deploy` が完了していること
- デプロイ出力からAPI URL、UserPoolId、ClientIdを取得済み

## テストシナリオ

### Scenario 1: サインアップ → 確認 → ログイン フロー

```bash
# 環境変数設定（cdk deploy出力から）
export API_URL="https://xxxxx.execute-api.ap-northeast-1.amazonaws.com/dev"

# 1. サインアップ
curl -X POST $API_URL/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test1234!"}'
# Expected: 201, confirmation code sent

# 2. 確認コード入力（メールで届いたコードを使用）
curl -X POST $API_URL/auth/confirm \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","code":"123456"}'
# Expected: 200, email confirmed

# 3. ログイン
curl -X POST $API_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test1234!"}'
# Expected: 200, tokens returned
```

### Scenario 2: プロフィール作成 → 取得 → 更新

```bash
# TOKEN=ログインで取得したaccessToken

# 1. プロフィール作成
curl -X POST $API_URL/users/profile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"nickname":"テスト太郎"}'
# Expected: 201, profile created

# 2. プロフィール取得
curl -X GET $API_URL/users/me \
  -H "Authorization: Bearer $TOKEN"
# Expected: 200, user data returned

# 3. プロフィール更新
curl -X PUT $API_URL/users/profile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"nickname":"テスト次郎"}'
# Expected: 200, profile updated
```

### Scenario 3: トークンリフレッシュ

```bash
# REFRESH_TOKEN=ログインで取得したrefreshToken

curl -X POST $API_URL/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\":\"$REFRESH_TOKEN\"}"
# Expected: 200, new access token returned
```

### Scenario 4: エラーケース確認

```bash
# 不正なパスワードでログイン
curl -X POST $API_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"wrong"}'
# Expected: 401, "Invalid email or password"

# 認証なしでプロフィール取得
curl -X GET $API_URL/users/me
# Expected: 401, Unauthorized
```

## Cleanup

```bash
# テストユーザー削除（AWS CLIで）
aws cognito-idp admin-delete-user \
  --user-pool-id <USER_POOL_ID> \
  --username test@example.com
```
