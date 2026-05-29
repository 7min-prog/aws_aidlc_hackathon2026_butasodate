# Business Logic Model - Unit 1: 認証基盤

## 1. メールサインアップフロー

```text
[ユーザー] → メール+パスワード入力
    │
    ▼
[フロントエンド] バリデーション
    ├─ パスワードポリシーチェック (BR-1)
    ├─ メール形式チェック
    │
    ▼
[Cognito] signUp API
    ├─ 成功 → 確認コードメール送信
    │         └→ 確認コード入力画面へ遷移
    ├─ UsernameExistsException → 「既に登録されています」エラー表示
    └─ InvalidPasswordException → パスワード要件エラー表示
    │
    ▼
[ユーザー] → 6桁確認コード入力
    │
    ▼
[Cognito] confirmSignUp API
    ├─ 成功 → emailVerified = true → ログイン画面へ遷移
    ├─ CodeMismatchException → 「確認コードが正しくありません」
    └─ ExpiredCodeException → 「確認コードの有効期限が切れています」
```

## 2. メールログインフロー

```text
[ユーザー] → メール+パスワード入力
    │
    ▼
[Cognito] initiateAuth API (USER_PASSWORD_AUTH)
    ├─ 成功 → トークン取得 (Access, Refresh, ID)
    │         │
    │         ▼
    │    [バックエンド] ユーザー情報取得 + lastLoginAt更新
    │         ├─ nickname有り → ホーム画面へ
    │         └─ nickname無し → ニックネーム設定画面へ (BR-7)
    │
    ├─ NotAuthorizedException → 「メールアドレスまたはパスワードが正しくありません」
    ├─ UserNotConfirmedException → 「メールアドレスの確認が完了していません」
    └─ UserNotFoundException → 「メールアドレスまたはパスワードが正しくありません」
```

## 3. ソーシャルログインフロー（Google / X共通）

```text
[ユーザー] → 「Google/Xでログイン」ボタン押下
    │
    ▼
[Cognito Hosted UI / OAuth] プロバイダー認証画面表示
    │
    ▼
[プロバイダー] 認証成功 → コールバック
    │
    ▼
[Cognito] トークン発行
    │
    ▼
[アカウントリンク判定] (BR-4)
    ├─ 同一メールの既存ユーザー有り
    │    └→ 自動リンク → linkedProvidersに追加
    └─ 既存ユーザー無し
         └→ 新規Userレコード作成 (DynamoDB)
              authProvider = GOOGLE/X
    │
    ▼
[バックエンド] ユーザー情報取得 + lastLoginAt更新
    ├─ nickname有り → ホーム画面へ
    └─ nickname無し → ニックネーム設定画面へ (BR-7)
```

## 4. ニックネーム設定フロー

```text
[ユーザー] → ニックネーム入力
    │
    ▼
[フロントエンド] バリデーション (BR-2)
    ├─ 文字数チェック (2〜10文字)
    ├─ 文字種チェック (英数字+日本語)
    │
    ▼
[バックエンド] POST /users/profile
    ├─ 一意性チェック (DynamoDB Query on nickname-index)
    │    ├─ 重複有り → 「このニックネームは既に使用されています」
    │    └─ 重複無し → nickname保存 → 成功レスポンス
    │
    ▼
[フロントエンド] ホーム画面へ遷移
```

## 5. ニックネーム変更フロー

```text
[ユーザー] → プロフィール画面 → ニックネーム変更入力
    │
    ▼
[フロントエンド] バリデーション (BR-2)
    │
    ▼
[バックエンド] PUT /users/profile
    ├─ 一意性チェック (現在の自分のnicknameは除外)
    │    ├─ 重複有り → エラー
    │    └─ 重複無し → nickname更新 → updatedAt更新
    │
    ▼
[フロントエンド] 変更完了表示
```

## 6. ログアウトフロー

```text
[ユーザー] → 設定画面 → ログアウトボタン押下
    │
    ▼
[フロントエンド] 確認ダイアログ表示
    ├─ キャンセル → 何もしない
    └─ 確認
         │
         ▼
    [Cognito] globalSignOut API
         └→ リフレッシュトークン無効化
         │
         ▼
    [フロントエンド] ローカルトークン削除 → ログイン画面へ遷移
```

## 7. トークンリフレッシュフロー（自動）

```text
[フロントエンド] APIリクエスト時
    │
    ▼
[API Client] アクセストークン有効期限チェック
    ├─ 有効 → そのままリクエスト送信
    └─ 期限切れ
         │
         ▼
    [Cognito] initiateAuth (REFRESH_TOKEN_AUTH)
         ├─ 成功 → 新アクセストークン取得 → リクエスト再送
         └─ 失敗（リフレッシュトークン期限切れ）
              └→ ログイン画面へ遷移（再認証要求）
```

## API エンドポイント一覧

| メソッド | パス | 認証 | 説明 |
|---------|------|------|------|
| POST | /auth/signup | 不要 | メールサインアップ |
| POST | /auth/confirm | 不要 | 確認コード検証 |
| POST | /auth/resend-code | 不要 | 確認コード再送 |
| POST | /auth/login | 不要 | メールログイン |
| POST | /auth/logout | 必要 | ログアウト |
| POST | /auth/refresh | 不要 | トークンリフレッシュ |
| GET | /users/me | 必要 | 自分のプロフィール取得 |
| POST | /users/profile | 必要 | ニックネーム初期設定 |
| PUT | /users/profile | 必要 | プロフィール更新 |

**備考**: ソーシャルログインはCognito Hosted UIのOAuthフローで処理されるため、独自APIエンドポイントは不要。コールバックURLでトークンを受け取る。
