# Frontend Components - Unit 2: 行動記録 + ヘルスデータ連携

## デザインリファレンス

> **UIデザイン準拠**: `docs/ぶたそだて - ゲーム画面デザイン (standalone).html`
>
> フロントエンド実装時は上記デザインファイルのビジュアル・レイアウト・カラースキーム・コンポーネントスタイルに従うこと。

## コンポーネント階層

```text
lib/features/recording/
├── presentation/
│   ├── pages/
│   │   ├── category_select_page.dart
│   │   ├── record_confirm_page.dart
│   │   ├── record_history_page.dart
│   │   └── weekly_summary_page.dart
│   └── widgets/
│       ├── category_card.dart
│       ├── record_list_item.dart
│       ├── summary_section.dart
│       └── point_animation.dart
├── domain/
│   ├── entities/
│   │   ├── activity_record.dart
│   │   └── activity_category.dart
│   └── repositories/
│       └── recording_repository.dart
├── data/
│   ├── repositories/
│   │   └── recording_repository_impl.dart
│   └── datasources/
│       ├── recording_remote_datasource.dart
│       └── recording_local_datasource.dart
└── application/
    └── providers/
        ├── recording_provider.dart
        └── categories_provider.dart

lib/features/health/
├── presentation/
│   ├── pages/
│   │   ├── health_settings_page.dart
│   │   └── sync_summary_page.dart
│   └── widgets/
│       ├── category_toggle.dart
│       ├── time_picker_setting.dart
│       └── sync_result_card.dart
├── domain/
│   ├── entities/
│   │   ├── health_sync_record.dart
│   │   └── health_sync_settings.dart
│   └── repositories/
│       └── health_repository.dart
├── data/
│   ├── repositories/
│   │   └── health_repository_impl.dart
│   └── datasources/
│       ├── health_platform_datasource.dart
│       ├── health_remote_datasource.dart
│       └── health_local_datasource.dart
└── application/
    └── providers/
        ├── health_sync_provider.dart
        └── health_settings_provider.dart
```

## 画面一覧

### 1. CategorySelectPage（カテゴリ選択画面）

**状態**:
| 状態 | 型 | 初期値 | 説明 |
|------|-----|--------|------|
| categories | List\<ActivityCategory\> | [] | カテゴリ一覧 |
| isLoading | bool | true | 読み込み中フラグ |

**ユーザー操作**:
| 操作 | 動作 |
|------|------|
| カテゴリカード押下 | RecordConfirmPageへ遷移（選択カテゴリ渡し） |
| 戻るボタン | ホーム画面へ戻る |

**API連携**: `GET /categories`（初回取得後キャッシュ）

### 2. RecordConfirmPage（記録確認画面）

**状態**:
| 状態 | 型 | 初期値 | 説明 |
|------|-----|--------|------|
| selectedCategory | ActivityCategory | 前画面から | 選択済みカテゴリ |
| recordedAt | DateTime | DateTime.now() | 記録日時 |
| memo | String | "" | メモ入力値 |
| isLoading | bool | false | 記録処理中フラグ |
| errorMessage | String? | null | エラーメッセージ |

**ユーザー操作**:
| 操作 | 動作 |
|------|------|
| 「記録する」ボタン押下 | 記録API呼び出し→完了演出 |
| 日時変更 | DateTimePickerで変更 |
| メモ入力 | テキストフィールド入力 |

**バリデーション (BR-5)**:
- メモ: 100文字以内

**API連携**: `POST /activities`
**オフライン時**: ローカルDB保存→完了表示（ポイント仮表示）

### 3. RecordHistoryPage（記録履歴画面）

**状態**:
| 状態 | 型 | 初期値 | 説明 |
|------|-----|--------|------|
| records | List\<ActivityRecord\> | [] | 記録一覧 |
| isLoading | bool | true | 読み込み中 |
| hasMore | bool | true | 追加データ有無 |
| cursor | String? | null | ページネーションカーソル |
| filterCategory | String? | null | カテゴリフィルター |
| filterDateFrom | Date? | null | 日付フィルター（開始） |
| filterDateTo | Date? | null | 日付フィルター（終了） |

**ユーザー操作**:
| 操作 | 動作 |
|------|------|
| 「もっと見る」ボタン押下 | 次ページ取得→リストに追記 |
| フィルターアイコン押下 | フィルター条件モーダル表示 |
| 自動検出レコード長押し | 削除確認ダイアログ表示 |
| 削除確認 | DELETE API→リストから除去 |

**API連携**: `GET /activities`, `DELETE /activities/{recordId}`

### 4. SyncSummaryPage（起動時同期サマリー画面）

**状態**:
| 状態 | 型 | 初期値 | 説明 |
|------|-----|--------|------|
| syncResults | List\<SyncResult\> | [] | 同期結果一覧 |
| totalPoints | int | 0 | 合計ポイント増減 |
| avatarStatus | AvatarStatus | - | 更新後アバター状態 |

**ユーザー操作**:
| 操作 | 動作 |
|------|------|
| 「確認」ボタン押下 | ホーム画面へ遷移 |

**表示内容**: 検出行動ごとに種類、日時、ポイント（+/-）、評価アイコン

### 5. HealthSettingsPage（ヘルスデータ連携設定画面）

**状態**:
| 状態 | 型 | 初期値 | 説明 |
|------|-----|--------|------|
| isEnabled | bool | SharedPrefsから | 連携有効フラグ |
| weightEnabled | bool | SharedPrefsから | 体重カテゴリ有効 |
| stepsEnabled | bool | SharedPrefsから | 歩数カテゴリ有効 |
| sleepEnabled | bool | SharedPrefsから | 睡眠カテゴリ有効 |
| bedtimeTarget | TimeOfDay | 23:00 | 就寝基準値 |
| wakeTarget | TimeOfDay | 7:00 | 起床基準値 |
| sleepDurationTarget | int | 7 | 睡眠時間基準値（時間） |
| stepsTarget | int | 8000 | 歩数目標 |

**ユーザー操作**:
| 操作 | 動作 |
|------|------|
| 「連携を有効にする」押下 | OS許可ダイアログ→許可でisEnabled=true |
| カテゴリトグル切り替え | enabledCategories更新 |
| 基準値変更 | TimePicker/NumberPickerで変更→即保存 |
| 「連携を解除」押下 | 確認ダイアログ→全カテゴリOFF |

**データ保存先**: SharedPreferences（デバイスローカル）

### 6. WeeklySummaryPage（週間サマリー画面）

**状態**:
| 状態 | 型 | 初期値 | 説明 |
|------|-----|--------|------|
| weekSummary | List\<CategorySummary\> | [] | カテゴリ別集計 |
| isLoading | bool | true | 読み込み中 |

**ユーザー操作**:
| 操作 | 動作 |
|------|------|
| 戻るボタン | ホーム画面へ戻る |

**API連携**: `GET /activities/summary?period=week`

## 共通ウィジェット

### CategoryCard
- カテゴリ選択用カード（アイコン + カテゴリ名）
- Props: category, onTap

### RecordListItem
- 履歴一覧の各行（カテゴリ名、日時、ポイント、sourceラベル）
- Props: record, onLongPress（自動検出時のみ有効）

### SummarySection
- ホーム画面内のサマリー表示部品
- Props: todayCount, todayPoints, onTap

### PointAnimation
- ポイント加算時のアニメーション演出（+12pt ↑ 表示）
- Props: points, onComplete

### CategoryToggle
- ヘルス設定のカテゴリON/OFFトグル
- Props: label, value, onChanged

### TimePickerSetting
- 基準値設定のタイムピッカー行
- Props: label, value, onChanged

### SyncResultCard
- 同期サマリーの各結果カード
- Props: syncResult（種類、日時、ポイント、評価）

## 画面遷移図

```text
[HomePage]
    ├─ 「行動を記録」ボタン → [CategorySelectPage]
    │                           └─ カテゴリ選択 → [RecordConfirmPage]
    │                                              └─ 記録完了 → [HomePage]（演出付き）
    ├─ サマリーセクションタップ → [WeeklySummaryPage]
    ├─ 「記録履歴」メニュー → [RecordHistoryPage]
    └─ 設定 → ヘルスデータ連携 → [HealthSettingsPage]

[アプリ起動時]
    ├─ 同期実行 + 検出あり → [SyncSummaryPage] → 「確認」 → [HomePage]
    └─ 同期不要 or 検出なし → [HomePage]
```

## 起動時フロー（同期判定）

```text
[App起動]
    │
    ├─ 認証チェック（Unit1）
    │    ├─ 未認証 → [LoginPage]
    │    └─ 認証済み
    │         │
    │         ▼
    │    ヘルスデータ同期判定
    │         ├─ 同期不要 → [HomePage]
    │         ├─ 同期実行 → ローディング表示
    │         │    ├─ 検出あり → [SyncSummaryPage]
    │         │    └─ 検出なし → [HomePage]
    │         └─ 同期失敗（部分含む） → [HomePage]（エラートースト表示）
```
