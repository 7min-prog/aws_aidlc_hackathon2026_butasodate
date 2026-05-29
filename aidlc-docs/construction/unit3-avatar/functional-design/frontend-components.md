# Frontend Components - Unit 3: アバター育成

## デザインリファレンス

> **UIデザイン準拠**: `docs/ぶたそだて - ゲーム画面デザイン (standalone).html`
>
> フロントエンド実装時は上記デザインファイルのビジュアル・レイアウト・カラースキーム・コンポーネントスタイルに従うこと。

## コンポーネント階層

```text
lib/features/avatar/
├── presentation/
│   ├── pages/
│   │   ├── avatar_status_page.dart
│   │   ├── evolution_history_page.dart
│   │   └── score_detail_page.dart
│   └── widgets/
│       ├── avatar_sprite_widget.dart
│       ├── stats_radar_chart.dart
│       ├── level_progress_bar.dart
│       ├── skill_list_item.dart
│       ├── evolution_animation.dart
│       └── score_summary_card.dart
├── domain/
│   ├── entities/
│   │   ├── avatar.dart
│   │   ├── avatar_stats.dart
│   │   ├── evolution_path.dart
│   │   └── skill.dart
│   └── repositories/
│       └── avatar_repository.dart
├── data/
│   ├── repositories/
│   │   └── avatar_repository_impl.dart
│   └── datasources/
│       └── avatar_remote_datasource.dart
└── application/
    └── providers/
        ├── avatar_provider.dart
        └── evolution_provider.dart
```

## 画面一覧

### 1. ホーム画面アバターセクション（HomePage内ウィジェット）

**状態**:
| 状態 | 型 | 初期値 | 説明 |
|------|-----|--------|------|
| avatar | Avatar? | null | アバター情報 |
| isLoading | bool | true | 読み込み中 |
| showLevelUpAnimation | bool | false | レベルアップ演出フラグ |
| showEvolutionAnimation | bool | false | 進化演出フラグ |

**表示内容**:
- AvatarSpriteWidget（ドット絵アイドルアニメーション）
- レベル表示（Lv.XX）
- 不健康スコア表示（累計ポイント）
- 次レベルまでのプログレスバー

**ユーザー操作**:
| 操作 | 動作 |
|------|------|
| アバタータップ | AvatarStatusPageへ遷移 |
| スコアセクションタップ | ScoreDetailPageへ遷移 |

**API連携**: `GET /avatar`（ホーム画面表示時）

### 2. AvatarStatusPage（アバターステータス画面）

**状態**:
| 状態 | 型 | 初期値 | 説明 |
|------|-----|--------|------|
| avatar | Avatar | 前画面から | アバター情報 |
| skills | List\<Skill\> | [] | 習得済みスキル一覧 |
| evolutionPath | EvolutionPath? | null | 現在の進化パス情報 |
| progress | AvatarProgress | - | 進捗情報 |
| selectedTab | int | 0 | タブ選択（0:ステータス, 1:スキル, 2:進化履歴） |

**タブ構成**:
- **ステータスタブ**: レーダーチャート（HP/攻撃/防御/素早さ）、レベル、進化段階
- **スキルタブ**: 習得済みスキル一覧（名前、タイプ、威力、クールタイム）
- **進化履歴タブ**: EvolutionHistoryPageへ遷移

**ユーザー操作**:
| 操作 | 動作 |
|------|------|
| タブ切り替え | 表示内容切り替え |
| 進化履歴タブ選択 | EvolutionHistoryPage表示 |
| 戻るボタン | ホーム画面へ戻る |

**API連携**: `GET /avatar`（詳細情報取得）

### 3. EvolutionHistoryPage（進化履歴画面）

**状態**:
| 状態 | 型 | 初期値 | 説明 |
|------|-----|--------|------|
| history | List\<EvolutionHistory\> | [] | 進化履歴一覧 |
| isLoading | bool | true | 読み込み中 |

**表示内容**:
- タイムライン形式で進化/退化の履歴を表示
- 各エントリ: 日時、進化/退化アイコン、変化前→変化後のパス名

**ユーザー操作**:
| 操作 | 動作 |
|------|------|
| 戻るボタン | AvatarStatusPageへ戻る |

**API連携**: `GET /avatar/evolution-history`

### 4. ScoreDetailPage（不健康スコア詳細画面）

**状態**:
| 状態 | 型 | 初期値 | 説明 |
|------|-----|--------|------|
| totalPoints | int | 0 | 累計不健康スコア |
| categoryBreakdown | Map | {} | カテゴリ別内訳 |
| categoryRatio | Map | {} | カテゴリ比率 |
| nextEvolution | NextEvolutionInfo? | null | 次進化までの情報 |
| isLoading | bool | true | 読み込み中 |

**表示内容**:
- 不健康スコア（大きく表示）
- カテゴリ別ポイント内訳（円グラフ or バー）
- 次の進化までの残りポイント・レベル
- 現在のカテゴリ比率（→ 進化パス予測表示）

**ユーザー操作**:
| 操作 | 動作 |
|------|------|
| 戻るボタン | ホーム画面へ戻る |

**API連携**: `GET /avatar/score-detail`

## 共通ウィジェット

### AvatarSpriteWidget
- Flameエンジンでスプライトシートアニメーションを再生
- Props: spriteSheetKey, animationType (idle/happy/sad/evolve), size
- S3からスプライトシートをダウンロード＆キャッシュ

### StatsRadarChart
- HP/攻撃/防御/素早さの4軸レーダーチャート
- Props: stats (AvatarStats)

### LevelProgressBar
- 現在のポイント / 次レベル必要ポイントのプログレスバー
- Props: currentPoints, nextLevelPoints, level

### SkillListItem
- スキル1件の表示（アイコン、名前、タイプ、威力、クールタイム）
- Props: skill (Skill)

### EvolutionAnimation
- 進化/退化時のフルスクリーン演出
- Props: type (evolution/devolution), fromSpriteKey, toSpriteKey, onComplete
- 進化: 光のエフェクト → 新しい姿のスプライト表示
- 退化: 暗転 → 前の姿に戻る演出
- 「スキップ」ボタン: 演出開始1秒後に画面右下に出現、タップで演出終了しonComplete発火

### ScoreSummaryCard
- ホーム画面内のスコア表示カード
- Props: totalPoints, level, onTap

## 画面遷移図

```text
[HomePage]
    ├─ アバタースプライトタップ → [AvatarStatusPage]
    │                              ├─ ステータスタブ（デフォルト）
    │                              ├─ スキルタブ
    │                              └─ 進化履歴タブ → [EvolutionHistoryPage]
    │
    └─ スコアセクションタップ → [ScoreDetailPage]

[演出（オーバーレイ）]
    ├─ レベルアップ → LevelProgressBar アニメーション + 数字カウントアップ
    ├─ 進化 → [EvolutionAnimation] フルスクリーン演出
    └─ 退化 → [EvolutionAnimation] フルスクリーン演出（暗転版）
```

## 演出トリガーフロー

```text
[行動記録完了 or ヘルスデータ同期完了]（Unit 2）
    │
    ▼
[APIレスポンス] avatarStatus を受信
    │
    ├─ leveledUp == true
    │    → showLevelUpAnimation = true
    │    → LevelProgressBar アニメーション再生
    │    → 新レベル表示
    │
    ├─ evolved == true
    │    → showEvolutionAnimation = true
    │    → EvolutionAnimation（進化）再生
    │    → 新スプライトシートに切り替え
    │    → スキル習得通知表示
    │
    ├─ devolved == true
    │    → showEvolutionAnimation = true
    │    → EvolutionAnimation（退化）再生
    │    → 前スプライトシートに切り替え
    │    → スキル喪失通知表示
    │
    └─ いずれもfalse
         → アバターステータス静かに更新
```

## スプライトシートキャッシュ戦略

```text
[アプリ起動時]
    │
    ▼
[キャッシュ確認] ローカルに現在のspriteSheetKeyのアセットがあるか
    ├─ あり → ローカルから読み込み
    └─ なし → S3からダウンロード → ローカルキャッシュに保存
    │
    ▼
[進化/退化時]
    ├─ 新しいspriteSheetKeyのアセットをS3から取得
    ├─ ローカルキャッシュに保存
    └─ 古いアセットはキャッシュに残す（退化時に再利用）
```
