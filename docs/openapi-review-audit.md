# OpenAPI設計レビュー Audit Log

## セッション情報
- **日時**: 2026-05-23 22:06〜22:58 (JST)
- **ブランチ**: docs/openapi-review
- **対象ファイル**: docs/openapi.json, docs/asyncapi.yaml

---

## レビュー・変更履歴

### 22:07 - アバター名変更API確認
**User**: ぶたのアバター名の変更はどのAPIでやりますか。
**結論**: アバター名を変更するAPIが存在しなかった。

---

### 22:09 - POST /avatar に名前更新機能追加
**User**: POSTメソッドの /avatar でnameを更新できるようにして
**対応**: POST /avatar のsummaryを「アバターを作成・名前を更新」に変更。未作成なら新規作成、既存なら名前更新する仕様に。

---

### 22:14 - 409レスポンス削除
**User**: 409レスポンスは削除
**対応**: POST /avatar から409（既に存在）レスポンスを削除。

---

### 22:14 - 複数の設計レビュー指摘
**User**:
- ユーザー退会のAPI用意したい
- ヘルスデータ同期自体はスマホに入っているアプリ同士の通信であり、同期処理にサーバーとの通信は発生しない。同期後にステータス更新を行うときだけサーバーとの通信が発生し、その通信は記録のAPIを流用できるはず
- 不健康行動を記録を「行動を記録」という項目にしたい。なぜなら、ヘルスコネクト連携で得られる数値が健康的な値である可能性があるから
- 一括記録ってなんでしたっけ
- 自動検出記録を削除ってなんでしたっけ
- 記録一覧取得とサマリー取得って何の差がありますか？

**回答**:
- 退会API未定義 → 追加必要
- /health-sync は不要（スマホ内完結）
- 「不健康行動を記録」→「行動を記録」にリネーム
- 一括記録 = ヘルスコネクト等から複数データを一度に送る
- 自動検出記録を削除 = 誤検知された自動記録をユーザーが取り消す
- 記録一覧 = 個々のレコード、サマリー = 集計データ

---

### 22:19 - レビュー指摘の確定
**User**: 1はOK.2もOK.3もOK.4は、APIとしては複数個記録できるようにしておいて、1つだけ記録したいときは配列に1つだけ入れる形にしたい。そうすれば1つのAPIで全部賄える。5は「記録の削除」という名前と役割に変えて。6は一覧取得APIにサマリー情報も含めてほしい

**対応**:
1. DELETE /account（ユーザー退会）追加
2. /health-sync 削除
3. 「不健康行動を記録」→「行動を記録」+ records配列形式に統一
4. /activities/batch 削除（POST /activitiesに統合）
5. 「自動検出記録を削除」→「記録の削除」+ 403制限削除
6. /activities/summary 削除（GET /activitiesにサマリー統合）

---

### 22:30 - DELETE /account のタグ変更
**User**: delete /accountはAuthにまとめたい
**対応**: タグを「Account」→「Auth」に変更。

---

### 22:32 - カテゴリバージョン取得の確認
**User**: カテゴリバージョン取得ってなんですか
**回答**: カテゴリマスタのキャッシュ制御用。アプリがバージョン番号を比較してキャッシュ更新判定する軽量チェック。

---

### 22:33 - カテゴリバージョン取得削除
**User**: キャッシュ制御要らないので不要。削除して
**対応**: /categories/version を削除。

---

### 22:35 - Socialタグのリネーム
**User**: 「Social」という名前はX連携と勘違いしそうなので、Friendという名前にしたい
**対応**: タグ「Social」→「Friend」に全置換。

---

### 22:36 - Battle APIの設計確認
**User**: Battleって、マッチングやバトル中の同期や技の取得と発動などいろいろな機能があるけど、APIはこれだけで足りるの？Socket通信だからいらないってこと？
**回答**: リアルタイム処理はWebSocket（API Gateway WebSocket API）で実装済み。REST APIはバトル結果の事後参照用のみ。

---

### 22:38 - WebSocket仕様書の記法確認
**User**: 別ドキュメントとしてまとめたい。この手の資料を作るときの記法って一般的なものがありますか？
**回答**: AsyncAPI（業界標準）を推奨。OpenAPIのイベント駆動版。

---

### 22:39 - AsyncAPIドキュメント作成
**User**: AsyncAPI（推奨）で書いて
**対応**: docs/asyncapi.yaml を作成。Client→Server 5アクション、Server→Client 6イベントを定義。

---

### 22:43 - 進化タイミングの確認
**User**: 行動記録後、ある一定の閾値を超えたら進化するのですが、進化するかどうかのT/FはどのタイミングでどのAPIでアプリに送られますか
**回答**: POST /avatar/points のレスポンス内 evolved フィールドで返される。

---

### 22:45 - ポイントAPIの削除
**User**: ポイントの増減は行動記録したタイミングでサーバー側で処理するので、APIとしては不要。行動記録のレスポンスとしてポイントの情報が欲しい
**対応**:
- POST /avatar/points 削除
- POST /avatar/points/deduct 削除
- POST /activities のレスポンスに avatar, leveledUp, evolved, newSkills を追加

---

### 22:47 - Admin ユーザー情報更新の確認
**User**: Adminで、ユーザー情報の更新はできない？
**回答**: 現状は取得・削除・停止/復活・アバターデータ修正のみ。プロフィール更新APIが無い。

---

### 22:48 - Admin ユーザー情報更新API追加
**User**: はい、追加して
**対応**: PUT /admin/users/{username}/profile を追加（nickname, email更新可能）。

---

### 22:50 - Admin APIのリネーム
**User**: ユーザー一覧、ユーザー詳細、ユーザー削除、ユーザー情報更新について。ユーザーという名前をアバターという名前にそれぞれ変更して
**対応**: 4つのsummaryを「ユーザー→アバター」に変更。

---

### 22:51 - アバター情報更新とアバターデータ修正の統合
**User**: アバター情報更新とアバターデータ修正の役割が被っているのでどちらか片方にマージして
**対応**: PUT /admin/users/{username}/profile に統合（nickname, email, totalPoints, level, evolutionStage, evolutionPathId）。/admin/users/{username}/avatar を削除。

---

### 22:53 - スキル割り当ての設計相談
**User**: スキルの追加について悩みがあります。どのぶたにたいして度のスキルを割り当てるかを自在に編集したいが、管理画面でそれらはできそう？
**回答**: 現状はスキル側の evolutionPathId を個別編集する形。専用APIを追加する方が運用しやすい。

---

### 22:55 - スキル割り当て専用API追加
**User**: 2でやりたい。追加して
**対応**:
- GET /admin/evolution-paths/{pathId}/skills（割り当て一覧取得）
- PUT /admin/evolution-paths/{pathId}/skills（割り当て一括更新）

---

## 最終API構成サマリー

### 削除されたAPI
- /activities/batch（POST /activitiesに統合）
- /activities/summary（GET /activitiesに統合）
- /health-sync（不要：スマホ内完結）
- /categories/version（キャッシュ制御不要）
- /avatar/points（POST /activitiesに統合）
- /avatar/points/deduct（POST /activitiesに統合）
- /admin/users/{username}/avatar（profile に統合）

### 追加されたAPI
- DELETE /account（ユーザー退会）
- GET /admin/evolution-paths/{pathId}/skills
- PUT /admin/evolution-paths/{pathId}/skills
- PUT /admin/users/{username}/profile

### 変更されたAPI
- POST /avatar → 名前更新機能追加、409削除
- POST /activities → 「行動を記録」にリネーム、配列形式、レスポンスに進化情報追加
- GET /activities → サマリー情報統合
- DELETE /activities/{recordId} → 「記録の削除」にリネーム、403削除
- タグ: Social → Friend
- Admin summaries: ユーザー → アバター

### 新規ドキュメント
- docs/asyncapi.yaml（Battle WebSocket API仕様）
