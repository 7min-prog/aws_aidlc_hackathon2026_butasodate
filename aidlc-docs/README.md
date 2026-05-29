# AI-DLC プロセスドキュメント

## プロジェクト概要

**ぶたそだて** — 不健康な行動をポジティブに記録する逆転発想の"ぶた"育成ヘルスケアゲームアプリ

## AI-DLC プロセスの流れ

本プロジェクトでは AI-DLC（AI-Driven Development Life Cycle）に従い、以下の順序で開発を実施。

```
要件定義 → ユーザーストーリー → アプリ設計 → ユニット分割
    → 各ユニットの詳細設計（機能設計 → NFR → インフラ） → コード生成 → ビルド・テスト
```

各フェーズでAIと人間が対話しながら設計判断を行い、その過程を `qa/` フォルダに、成果物を各フォルダ直下に格納。

---

## フォルダ構成

### ルート

| ファイル | 説明 |
|---------|------|
| `aidlc-state.md` | ワークフロー全体の進捗状態 |
| `audit.md` | 全フェーズのユーザー入力・AI応答ログ |

---

### 🔵 inception/ — 企画・要件定義フェーズ

| フォルダ/ファイル | 説明 |
|-----------------|------|
| `requirements/requirements.md` | 機能要件（FR-1〜FR-7）・非機能要件の確定版 |
| `user-stories/personas.md` | ユーザーペルソナ定義 |
| `user-stories/stories-fr1.md` 〜 `fr7.md` | 各機能要件のユーザーストーリー |
| `user-stories/battle-ui-mock.html` | バトルUIのHTMLモック |
| `application-design/application-design.md` | アーキテクチャ方針・全体設計 |
| `application-design/components.md` | コンポーネント一覧 |
| `application-design/component-methods.md` | コンポーネントのメソッド定義 |
| `application-design/component-dependency.md` | コンポーネント間依存関係 |
| `application-design/services.md` | サービス層定義 |
| `application-design/unit-of-work.md` | ユニット分割結果（6ユニット） |
| `application-design/unit-of-work-story-map.md` | ユニットとストーリーの対応 |
| `application-design/unit-of-work-dependency.md` | ユニット間依存関係 |
| `plans/` | AIが各フェーズを進めるための実行計画 |
| `*/qa/` | 各フェーズでのAIとの対話・設計判断Q&A |

---

### 🟢 construction/ — 設計・実装フェーズ

関連性の高い機能をまとめ、6つのユニットに分割して設計・実装を実施。FR-2とFR-3（行動記録＋ヘルスデータ）、FR-5とFR-6（バトル＋ソーシャル）はそれぞれ密結合のため1ユニットに統合。Unit6はFRに対応しないフロントエンド統合・起動処理。

| ユニット | 対象機能 | 対応コード |
|---------|---------|-----------|
| unit1-auth | 認証基盤 (FR-1) | `backend/auth-handler/`, `infrastructure/lib/auth-stack.ts` |
| unit2-recording | 行動記録 + ヘルスデータ連携 (FR-2, FR-3) | `backend/recording-handler/`, `infrastructure/lib/recording-stack.ts` |
| unit3-avatar | アバター育成 (FR-4) | `backend/avatar-handler/`, `infrastructure/lib/avatar-stack.ts` |
| unit4-battle-social | バトル + ソーシャル (FR-5, FR-6) | `backend/battle-ws-handler/`, `backend/social-handler/` |
| unit5-admin | 管理画面 (FR-7) | `backend/admin-handler/`, `admin/` |
| unit6-app-boot | アプリ起動・ブート | `frontend/lib/shared/` |

各ユニットの設計ドキュメント構成:

```
unit*/
├── functional-design/     # 機能設計（ビジネスロジック、ルール、エンティティ、UI）
├── nfr-requirements/      # 非機能要件（性能、スケーラビリティ、セキュリティ）
├── nfr-design/            # NFR設計パターン・論理コンポーネント
├── infrastructure-design/ # AWSインフラ構成
├── code/                  # コード生成サマリ
└── qa/                    # 設計時のAIとの対話記録
```

| その他 | 説明 |
|-------|------|
| `plans/` | 各ユニットの設計・コード生成の段取り計画 |
| `build-and-test/` | ビルド手順・テスト実行手順 |

---

## 工夫した点

### 1. 設計フェーズと実装フェーズの分離

AI-DLCの標準フローを拡張し、3フェーズ構成で開発を実施。

- **Phase 1: Unit of Work** — 各Unitの詳細設計を個別に実施
- **Phase 2: Unification** — 全Unitの設計をBE/FEそれぞれ一本化
  - Backend Design: API定義・データ整合性を全Unit分一括検証・一本化
  - Frontend Design: 画面構成・UI/UX方針を全Unit分一括検証・一本化
- **Phase 3: Implementation** — 一本化された共通仕様に基づきBE/FEを実装・テスト

**効果**:
- ユーザーファーストな機能要件の実現（全体俯瞰で体験設計）
- 実装フェーズでのユニット間衝突の防止（API・DB設計の事前統合）
- 実装速度の加速（共通仕様により迷いなく並行開発）

### 2. HTMLによるUIデザイン定義の共有

AIに対する「UIデザイン定義」をMarkdownではなくHTMLで作成。ブラウザで視覚的に確認できる形式にしたことで、画面遷移や画面デザインを開発者とAI間で正確に認識合わせ。さらにPenpot（デザインツール）のスキルを導入し、デザイン設計書を厳密に作成。

**効果**: 10日間で39画面のフロントエンド実装を達成

### 3. UnitテストとE2Eテストの自動化

AIで生成したコードは人間以上にリグレッションを起こしやすい。テストがなければ「壊れたことに気づけない」が、39画面を毎回手動で確認するのは不可能。そこでUnitテストとE2Eテストを詳細に記述し、バグの蓄積やリグレッションを防止。さらにテスト実行・デプロイ・レポート作成をCI/CDで自動化。

**効果**:
- 機能追加のたびにテストが既存機能を保護
- テストがドキュメント代わりとなり、メンバー間の仕様理解コストを削減
- テストの充実化と自動化により、高速なイテレーションを実現

---

## 関連ドキュメント（aidlc-docs 外）

| ファイル | 説明 |
|---------|------|
| `docs/er-diagram.md` | データベース設計（ER図） |
| `docs/openapi.json` | API仕様（OpenAPI 3.0） |
| `design/` | Penpotデザインファイル・画面デザインルール |
