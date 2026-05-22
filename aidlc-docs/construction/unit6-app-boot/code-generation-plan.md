# Unit 6: 起動時処理 — Code Generation Plan

## ユニットコンテキスト
- **対象**: フロントエンド（Flutter）のみ
- **バックエンド変更**: なし（既存APIを利用）
- **依存Unit**: Unit 1（認証）, Unit 2（記録）, Unit 3（アバター）, Unit 4（ソーシャル）
- **新規パッケージ**: `path_provider`（画像キャッシュ用）, `connectivity_plus`（オフライン検出）

## 実装ステップ

### Step 1: pubspec.yaml 依存追加
- [x] `path_provider` 追加（ファイルキャッシュ用）
- [x] `connectivity_plus` 追加（ネットワーク状態検出）
- [x] `cached_network_image` 追加（画像キャッシュ表示）

### Step 2: 定数・モデル定義
- [x] `lib/shared/constants.dart` — S3 URL、スプラッシュ最低時間等
- [x] `lib/shared/models/` — Avatar, RecordSummary, UserProfile のデータクラス

### Step 3: キャッシュサービス
- [x] `lib/shared/cache_service.dart` — SharedPreferencesベースのJSON/テキストキャッシュ
- [x] `lib/shared/image_cache_service.dart` — アバター画像のファイルキャッシュ

### Step 4: 起動処理Provider
- [x] `lib/shared/boot_state.dart` — BootNotifier（起動フロー全体を管理）

### Step 5: auth_state.dart 更新
- [x] ニックネーム設定完了後に `POST /avatar` を呼ぶロジック追加
- [x] リトライ（最大3回）

### Step 6: router.dart 更新
- [x] initialLocation を `/splash` に変更
- [x] `/splash` ルート追加
- [x] `/` を HomeScreen に差し替え
- [x] スタブルート追加（/recording, /battle, /settings）
- [x] redirect ロジック簡素化（SplashScreenが判定を担う）

### Step 7: SplashScreen 実装
- [x] `lib/features/splash/splash_screen.dart`

### Step 8: HomeScreen + ウィジェット実装
- [x] `lib/features/home/home_screen.dart` — ホーム画面骨格 + BottomNavigationBar
- [x] `lib/features/home/widgets/avatar_card.dart` — アバター画像 + レベル + 名前
- [x] `lib/features/home/widgets/summary_card.dart` — 今日の記録数・ポイント
- [x] `lib/features/home/widgets/record_button.dart` — FAB「不健康を記録する」
- [x] `lib/features/home/widgets/offline_banner.dart` — オフラインモードバナー

### Step 9: nickname_screen.dart 更新
- [x] ニックネーム保存成功後に `POST /avatar` 呼び出し追加

### Step 10: スタブ画面
- [x] `lib/features/recording/recording_screen.dart` — スタブ
- [x] `lib/features/battle/battle_screen.dart` — スタブ
- [x] `lib/features/settings/settings_screen.dart` — スタブ（ログアウトボタン付き）

---

## 承認

この実装計画で進めてよいですか？

- [ ] 承認する
- [ ] 修正が必要（下記にコメント記入）

コメント:

---
