# Frontend Components - Unit 1: 認証基盤

## デザインリファレンス

> **UIデザイン準拠**: `docs/ぶたそだて - ゲーム画面デザイン (standalone).html`
>
> フロントエンド実装時は上記デザインファイルのビジュアル・レイアウト・カラースキーム・コンポーネントスタイルに従うこと。

## コンポーネント階層

```text
lib/features/auth/
├── presentation/
│   ├── pages/
│   │   ├── login_page.dart
│   │   ├── signup_page.dart
│   │   ├── email_confirm_page.dart
│   │   ├── nickname_setup_page.dart
│   │   └── profile_page.dart
│   └── widgets/
│       ├── auth_text_field.dart
│       ├── social_login_button.dart
│       └── password_strength_indicator.dart
├── domain/
│   ├── entities/
│   │   └── user.dart
│   └── repositories/
│       └── auth_repository.dart
├── data/
│   ├── repositories/
│   │   └── auth_repository_impl.dart
│   └── datasources/
│       └── auth_remote_datasource.dart
└── application/
    └── providers/
        ├── auth_provider.dart
        └── user_provider.dart
```

## 画面一覧

### 1. LoginPage（ログイン画面）

**状態**:
| 状態 | 型 | 初期値 | 説明 |
|------|-----|--------|------|
| email | String | "" | メール入力値 |
| password | String | "" | パスワード入力値 |
| isLoading | bool | false | ログイン処理中フラグ |
| errorMessage | String? | null | エラーメッセージ |

**ユーザー操作**:
| 操作 | 動作 |
|------|------|
| ログインボタン押下 | メールログインフロー実行 |
| 「Googleでログイン」押下 | Cognito OAuth (Google) 起動 |
| 「Xでログイン」押下 | Cognito OAuth (X) 起動 |
| 「アカウント作成」リンク押下 | SignupPageへ遷移 |

**バリデーション**:
- メール: 空でないこと、メール形式であること
- パスワード: 空でないこと

**API連携**: `POST /auth/login`

### 2. SignupPage（サインアップ画面）

**状態**:
| 状態 | 型 | 初期値 | 説明 |
|------|-----|--------|------|
| email | String | "" | メール入力値 |
| password | String | "" | パスワード入力値 |
| passwordConfirm | String | "" | パスワード確認入力値 |
| isLoading | bool | false | 処理中フラグ |
| errorMessage | String? | null | エラーメッセージ |
| passwordStrength | int | 0 | パスワード強度 (0-4) |

**ユーザー操作**:
| 操作 | 動作 |
|------|------|
| サインアップボタン押下 | サインアップフロー実行 → EmailConfirmPageへ |
| 「ログインへ戻る」押下 | LoginPageへ遷移 |

**バリデーション (BR-1)**:
- メール: 空でない、メール形式
- パスワード: 8文字以上、大文字・小文字・数字・特殊文字各1文字以上
- パスワード確認: passwordと一致

**API連携**: `POST /auth/signup`

### 3. EmailConfirmPage（メール確認画面）

**状態**:
| 状態 | 型 | 初期値 | 説明 |
|------|-----|--------|------|
| confirmCode | String | "" | 6桁確認コード |
| isLoading | bool | false | 処理中フラグ |
| errorMessage | String? | null | エラーメッセージ |
| canResend | bool | true | 再送可能フラグ |
| resendCooldown | int | 0 | 再送クールダウン秒数 |

**ユーザー操作**:
| 操作 | 動作 |
|------|------|
| 確認ボタン押下 | 確認コード検証 → 成功でLoginPageへ |
| 「コードを再送」押下 | 確認コード再送（60秒クールダウン） |

**バリデーション**:
- confirmCode: 6桁数字

**API連携**: `POST /auth/confirm`, `POST /auth/resend-code`

### 4. NicknameSetupPage（ニックネーム設定画面）

**状態**:
| 状態 | 型 | 初期値 | 説明 |
|------|-----|--------|------|
| nickname | String | "" | ニックネーム入力値 |
| isLoading | bool | false | 処理中フラグ |
| errorMessage | String? | null | エラーメッセージ |
| isAvailable | bool? | null | 使用可能チェック結果 |

**ユーザー操作**:
| 操作 | 動作 |
|------|------|
| 保存ボタン押下 | ニックネーム設定 → ホーム画面へ |
| ニックネーム入力（デバウンス） | リアルタイム使用可能チェック |

**バリデーション (BR-2)**:
- 2〜10文字
- 英数字・ひらがな・カタカナ・漢字のみ
- 一意性（API問い合わせ）

**API連携**: `POST /users/profile`

**備考**: スキップ不可。戻るボタン非表示。

### 5. ProfilePage（プロフィール画面）

**状態**:
| 状態 | 型 | 初期値 | 説明 |
|------|-----|--------|------|
| nickname | String | 現在値 | ニックネーム |
| email | String | 現在値 | メール（表示のみ） |
| authProvider | String | 現在値 | 認証方法（表示のみ） |
| linkedProviders | List | 現在値 | リンク済みプロバイダー |
| isEditing | bool | false | 編集モードフラグ |
| isLoading | bool | false | 処理中フラグ |

**ユーザー操作**:
| 操作 | 動作 |
|------|------|
| 編集ボタン押下 | 編集モードON |
| 保存ボタン押下 | ニックネーム更新 |
| ログアウトボタン押下 | 確認ダイアログ → ログアウト |

**API連携**: `GET /users/me`, `PUT /users/profile`, `POST /auth/logout`

## 共通ウィジェット

### AuthTextField
- テキスト入力フィールド（メール/パスワード/ニックネーム共通）
- Props: label, obscureText, validator, onChanged, errorText

### SocialLoginButton
- ソーシャルログインボタン（Google / X）
- Props: provider (google/x), onPressed, isLoading

### PasswordStrengthIndicator
- パスワード強度インジケーター（4段階バー表示）
- Props: password

## 画面遷移図

```text
[LoginPage]
    ├─ ログイン成功 + nickname有り → [HomePage]
    ├─ ログイン成功 + nickname無し → [NicknameSetupPage] → [HomePage]
    ├─ ソーシャルログイン → OAuth → 同上判定
    └─ 「アカウント作成」 → [SignupPage]
                              └─ サインアップ成功 → [EmailConfirmPage]
                                                     └─ 確認成功 → [LoginPage]

[ProfilePage] (設定画面内)
    └─ ログアウト → [LoginPage]
```
