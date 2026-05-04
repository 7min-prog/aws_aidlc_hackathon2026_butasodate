# Story Generation Plan: ぶた育成ヘルスケアゲームアプリ

## 実行チェックリスト

### Part 1: Planning
- [x] Step 1: User Stories必要性の評価
- [x] Step 2: ストーリープラン作成
- [x] Step 3: コンテキスト適切な質問の生成
- [x] Step 4: 必須成果物の定義
- [x] Step 5: ストーリー分解アプローチの提示
- [x] Step 6: プランの保存
- [x] Step 7: ユーザー入力の収集
- [x] Step 8: 回答の収集
- [x] Step 9: 回答の分析
- [x] Step 10: フォローアップ質問（CQ1:BDD形式、CQ2:バトルは抽象記述）
- [x] Step 11: プランの承認（スコープをFR-1に絞って進行）

### Part 2: Generation
- [x] Step 12: ペルソナの生成（personas.md）
- [x] Step 13: ユーザーストーリーの生成（stories.md）
- [x] Step 14: ストーリーとペルソナのマッピング
- [x] Step 15: INVEST基準の検証
- [ ] Step 16: 最終レビューと承認

---

## ストーリー分解アプローチの選択肢

以下のアプローチから選択してください：

| アプローチ | 説明 | メリット | デメリット |
|-----------|------|---------|-----------|
| **User Journey-Based** | ユーザーの行動フローに沿って分解 | 体験設計に最適、UXの一貫性 | 技術的な横断機能が見落とされやすい |
| **Feature-Based** | FR-1〜FR-7の機能単位で分解 | 要件との対応が明確、実装しやすい | ユーザー視点が薄くなりがち |
| **Persona-Based** | ユーザータイプごとに分解 | ペルソナのニーズが明確 | 共通機能が重複しやすい |
| **Epic-Based** | 大きなエピックから階層的に分解 | 優先度管理しやすい | 粒度の統一が難しい |
| **Hybrid** | 上記の組み合わせ | 柔軟性が高い | 一貫性の維持が必要 |

---

## 質問

以下の質問に回答してください。各質問の `[Answer]:` タグの後に選択肢の文字を記入してください。

### ペルソナに関する質問

#### Question 1
一般ユーザー（プレイヤー）のペルソナをどの程度細分化しますか？

A) 1種類（一般プレイヤー）
B) 2種類（カジュアルプレイヤー / ヘビープレイヤー）
C) 3種類（カジュアル / ヘビー / ソーシャル重視）
D) Other (please describe after [Answer]: tag below)

[Answer]: A

#### Question 2
管理者ペルソナの想定ユーザーは？

A) 開発者のみ（技術的な操作が中心）
B) 開発者 + 運用担当者（非技術者も含む）
C) Other (please describe after [Answer]: tag below)

[Answer]: A

### ストーリー構造に関する質問

#### Question 3
ストーリーの分解アプローチはどれを採用しますか？（上記の表を参照）

A) User Journey-Based（ユーザー行動フロー基準）
B) Feature-Based（機能要件FR-1〜FR-7基準）
C) Persona-Based（ユーザータイプ基準）
D) Epic-Based（エピック階層基準）
E) Hybrid（組み合わせ）
F) Other (please describe after [Answer]: tag below)

[Answer]: B

#### Question 4
ストーリーの粒度（サイズ）はどの程度が望ましいですか？

A) 大きめ（エピックレベル、1ストーリー = 1機能要件程度）
B) 中程度（1ストーリー = 1〜3日で実装可能な単位）
C) 細かめ（1ストーリー = 数時間〜1日で実装可能な単位）
D) Other (please describe after [Answer]: tag below)

[Answer]: C

### 受け入れ基準に関する質問

#### Question 5
受け入れ基準のフォーマットはどれを使用しますか？

A) Given-When-Then形式（BDD形式）
B) チェックリスト形式（箇条書き）
C) シナリオベース（ユーザー操作の流れ）
D) Other (please describe after [Answer]: tag below)

[Answer]: BDDとは？他のやり方と比較してメリデメ教えてほしい

### ユーザージャーニーに関する質問

#### Question 6
アプリの主要なユーザージャーニーとして最も重視するフローは？

A) 初回登録 → 初めての行動記録 → アバター成長を見る
B) 日常の行動記録 → アバター育成 → バトル参加
C) ソーシャル（フレンド追加 → バトル → 結果共有）
D) 全フローを均等に重視
E) Other (please describe after [Answer]: tag below)

[Answer]: B

#### Question 7
ヘルスデータ連携の自動検出について、ユーザーへの通知・確認フローはどうしますか？

A) 自動検出したら即座に記録（通知のみ）
B) 自動検出後にユーザー確認を求めてから記録
C) 自動検出の結果をまとめて表示し、ユーザーが選択して記録
D) Other (please describe after [Answer]: tag below)

[Answer]: 自動で連携したあとアプリ起動時に教えてほしい。通知は不要。

### バトルシステムに関する質問

#### Question 8
バトルの操作方法はどのようなイメージですか？

A) 完全自動（ステータス・スキルに基づく自動バトル、観戦のみ）
B) ターン制（プレイヤーがスキルを選択して交互に行動）
C) リアルタイム操作（タイミングやアクションをリアルタイムで入力）
D) Other (please describe after [Answer]: tag below)

[Answer]: FR-5で検討します

---

## 必須成果物

- [ ] `aidlc-docs/inception/user-stories/personas.md` — ユーザーペルソナ定義
- [ ] `aidlc-docs/inception/user-stories/stories.md` — ユーザーストーリー（INVEST基準準拠、受け入れ基準付き）
