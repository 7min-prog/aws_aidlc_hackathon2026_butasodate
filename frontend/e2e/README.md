# E2E Tests (Playwright)

Flutter web の prod ビルドに対する E2E テスト。

## セットアップ

```bash
cd frontend/e2e
npm install
npx playwright install chromium
```

## 前提: Flutter web ビルド

```bash
cd frontend
flutter build web -t lib/main_prod.dart
```

## テスト実行

### ヘッドレス（CI向け）

```bash
E2E_EMAIL="your@email.com" E2E_PASSWORD="yourpass" npx playwright test
```

### ヘッドフル（デバッグ向け）

```bash
E2E_EMAIL="your@email.com" E2E_PASSWORD="yourpass" HEADED=true npx playwright test
```

### UI モード

```bash
E2E_EMAIL="your@email.com" E2E_PASSWORD="yourpass" npx playwright test --ui
```

### 認証なしテストのみ

```bash
npx playwright test --grep "Login flow"
```

## 環境変数

| 変数 | 必須 | 説明 |
|------|------|------|
| `E2E_EMAIL` | 認証テスト時 | ログイン用メールアドレス |
| `E2E_PASSWORD` | 認証テスト時 | ログイン用パスワード |
| `HEADED` | No | `true` でブラウザ表示（デフォルト: ヘッドレス） |

## テスト一覧

| テスト | 認証 | 内容 |
|--------|------|------|
| shows login form | 不要 | ログインフォーム表示確認 |
| login button disabled | 不要 | 未入力時ボタン非表示 |
| login button appears | 不要 | 入力後ボタン表示 |
| failed login | 不要 | 認証失敗時の挙動 |
| login navigates to home | 必要 | ログイン→ホーム遷移 |
| home shows tab bar | 必要 | タブバー表示 |
| navigate to recording | 必要 | きろく画面 |
| navigate to category | 必要 | カテゴリ選択（API確認） |
| navigate to battle | 必要 | バトル画面 |
| navigate to friend | 必要 | フレンド画面 |
| navigate to settings | 必要 | せってい画面 |
| navigate to avatar | 必要 | アバター詳細 |

## 注意事項

- Flutter web はセマンティクスを有効化しないとアクセシビリティツリーが使えない（ヘルパーで自動対応済み）
- `fill()` ではなく `pressSequentially()` を使用（Flutter の TextEditingController のリスナーを発火させるため）
- 認証テストは prod API に対して実行されるため、有効なアカウントが必要
