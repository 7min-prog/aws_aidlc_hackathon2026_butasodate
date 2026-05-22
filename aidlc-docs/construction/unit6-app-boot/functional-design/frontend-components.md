# Frontend Components - Unit 6: 起動時処理

## デザインリファレンス

> **UIデザイン準拠**: `docs/ぶたそだて - ゲーム画面デザイン (standalone).html`

## コンポーネント階層

```text
lib/
├── shared/
│   ├── router.dart              # 更新: SplashScreen追加、遷移ロジック改修
│   ├── auth_state.dart          # 更新: トークン検証ロジック強化
│   ├── api_client.dart          # 既存
│   ├── cache_service.dart       # 新規: ローカルキャッシュ管理
│   ├── image_cache_service.dart # 新規: アバター画像キャッシュ管理
│   ├── constants.dart           # 新規: S3 URL等の定数
│   └── boot_state.dart          # 新規: 起動時処理の状態管理
├── features/
│   ├── auth/
│   │   └── nickname_screen.dart # 更新: アバター作成呼び出し追加
│   ├── splash/
│   │   └── splash_screen.dart   # 新規: スプラッシュ画面
│   └── home/
│       ├── home_screen.dart     # 新規: ホーム画面骨格
│       └── widgets/
│           ├── avatar_card.dart       # 新規: アバター表示カード（画像付き）
│           ├── summary_card.dart      # 新規: 今日のサマリーカード
│           ├── record_button.dart     # 新規: 行動記録ボタン
│           └── offline_banner.dart    # 新規: オフラインバナー
```

---

## 画面定義

### 1. SplashScreen（スプラッシュ画面）

**状態**:
| 状態 | 型 | 初期値 | 説明 |
|---|---|---|---|
| bootStatus | AppBootStatus | checking | 起動処理の進行状態 |
| errorMessage | String? | null | エラー発生時のメッセージ |

**AppBootStatus enum**:
| 値 | 意味 |
|---|---|
| checking | トークン確認中 |
| loadingData | 初期データ取得中 |
| done | 完了（遷移待ち） |
| error | エラー発生（リトライ可能） |

**UI構成**:
- 中央: アプリロゴ（ぶたアイコン + 「ぶたそだて」テキスト）
- 下部: ローディングインジケーター（checking/loadingData時）
- エラー時: エラーメッセージ + 「リトライ」ボタン

**ユーザー操作**:
| 操作 | 動作 |
|---|---|
| リトライボタン押下 | 起動処理を最初から再実行 |

---

### 2. HomeScreen（ホーム画面骨格）

**状態**:
| 状態 | 型 | 初期値 | 説明 |
|---|---|---|---|
| avatar | Avatar? | null | アバター情報（キャッシュ or API） |
| summary | RecordSummary? | null | 今日のサマリー |
| pendingCount | int | 0 | 未読フレンド申請数 |
| isOffline | bool | false | オフラインモードフラグ |

**UI構成**:
```text
┌─────────────────────────────┐
│ [オフラインバナー]（isOffline時のみ） │
├─────────────────────────────┤
│                             │
│   [AvatarCard]              │
│   アバター画像 + レベル + 名前  │
│                             │
├─────────────────────────────┤
│   [SummaryCard]             │
│   今日の記録数 / ポイント     │
│                             │
├─────────────────────────────┤
│                             │
│   [RecordButton]            │
│   「不健康を記録する」FAB     │
│                             │
├─────────────────────────────┤
│ [BottomNav]                 │
│ ホーム | 記録 | バトル | 設定  │
└─────────────────────────────┘
```

**BottomNavigationBar タブ**:
| タブ | アイコン | 遷移先 | 実装状態 |
|---|---|---|---|
| ホーム | home | / | 今回実装 |
| 記録 | edit_note | /recording | スタブ |
| バトル | sports_mma | /battle | スタブ |
| 設定 | settings | /settings | スタブ |

**ユーザー操作**:
| 操作 | 動作 |
|---|---|
| RecordButton押下 | /recording へ遷移（スタブ） |
| AvatarCard押下 | /avatar/detail へ遷移（スタブ） |
| BottomNavタブ押下 | 各画面へ遷移（スタブ） |

---

## Provider定義

### boot_state.dart

```dart
// 起動処理全体を管理するProvider
final bootProvider = AsyncNotifierProvider<BootNotifier, BootResult>(...);

class BootResult {
  final UserProfile? profile;
  final Avatar? avatar;
  final RecordSummary? summary;
  final int pendingRequestCount;
  final bool isOffline;
  final String? avatarImagePath; // ローカルキャッシュされた画像パス
}
```

### cache_service.dart

```dart
// ローカルキャッシュの読み書き（JSON/テキストデータ）
final cacheServiceProvider = Provider<CacheService>(...);

class CacheService {
  Future<void> saveProfile(UserProfile profile);
  Future<UserProfile?> loadProfile();
  Future<void> saveAvatar(Avatar avatar);
  Future<Avatar?> loadAvatar();
  Future<void> saveSummary(RecordSummary summary);
  Future<RecordSummary?> loadSummary();  // 日付チェック付き
  Future<void> clearAll();  // ログアウト時
}
```

### image_cache_service.dart

```dart
// アバター画像のローカルファイルキャッシュ
final imageCacheServiceProvider = Provider<ImageCacheService>(...);

class ImageCacheService {
  /// spriteSheetKeyからS3 URLを解決
  String resolveImageUrl(String spriteSheetKey);

  /// 画像をキャッシュから取得（なければダウンロード＆保存）
  /// 返り値: ローカルファイルパス or null（失敗時）
  Future<String?> getOrDownload(String spriteSheetKey);

  /// キャッシュ済みか確認
  Future<bool> isCached(String spriteSheetKey);

  /// 全画像キャッシュ削除（ログアウト時）
  Future<void> clearAll();
}
```

### constants.dart

```dart
class AppConstants {
  static const assetsBaseUrl =
    'https://{ASSETS_BUCKET_NAME}.s3.ap-northeast-1.amazonaws.com/assets/';
  static const defaultAvatarAsset = 'assets/images/default_buta.png'; // バンドル内フォールバック
  static const splashMinDuration = Duration(seconds: 1);
}
```

---

## 画面遷移図

```text
[SplashScreen] (初期ルート)
    ├─ トークンなし → [LoginScreen]
    ├─ リフレッシュ失敗 → [LoginScreen]
    ├─ プロフィール未作成 → [NicknameScreen] → POST /avatar → [HomeScreen]
    ├─ オフライン + キャッシュあり → [HomeScreen] (読み取り専用)
    ├─ オフライン + キャッシュなし → [SplashScreen] (エラー + リトライ)
    └─ 正常 → [HomeScreen]

[HomeScreen]
    ├─ RecordButton → [RecordingScreen] (スタブ)
    ├─ AvatarCard → [AvatarDetailScreen] (スタブ)
    ├─ BottomNav:記録 → [RecordingScreen] (スタブ)
    ├─ BottomNav:バトル → [BattleScreen] (スタブ)
    └─ BottomNav:設定 → [SettingsScreen] (スタブ)
```

---

## router.dart 変更点

| 変更 | 内容 |
|---|---|
| initialLocation | `/splash` に変更 |
| /splash ルート追加 | SplashScreen |
| / ルート変更 | HomeScreen（仮実装を差し替え） |
| redirect ロジック | SplashScreenが起動判定を担うため簡素化 |
| スタブルート追加 | /recording, /battle, /settings, /avatar/detail |
