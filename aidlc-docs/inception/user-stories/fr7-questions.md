# FR-7 管理画面 ユーザーストーリー確認質問

以下の質問に回答してください。各質問の `[Answer]:` タグの後に選択肢の記号を記入してください。
該当する選択肢がない場合は最後の「Other」を選び、説明を記入してください。

---

## Question 1
管理画面への認証方式はどうしますか？

A) メールアドレス + パスワード（独自認証）
B) AWS Cognito の管理者用ユーザープール（アプリとは別）
C) アプリと同じ Cognito ユーザープールで管理者ロールを付与
D) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 2
管理画面の管理者は複数人を想定しますか？また、管理者間の権限の違いはありますか？

A) 管理者は1人のみ（権限分けなし）
B) 複数人だが全員同じ権限
C) 複数人で権限レベルあり（例: 閲覧のみ / 編集可 / フル権限）
D) Other (please describe after [Answer]: tag below)

[Answer]: B

---

## Question 3
ユーザーデータの「編集」の範囲はどこまでですか？

A) プロフィール情報のみ（ニックネーム、メールアドレス等）
B) プロフィール + ゲームデータ（ぶたのレベル、ポイント等）
C) すべてのユーザー関連データ（プロフィール + ゲームデータ + バトル履歴等）
D) Other (please describe after [Answer]: tag below)

[Answer]: C

---

## Question 4
ユーザーの「削除」は物理削除（完全消去）と論理削除（非表示化）のどちらですか？

A) 物理削除（データベースから完全に削除）
B) 論理削除（削除フラグを立てて非表示にする）
C) 両方対応（論理削除がデフォルト、物理削除も可能）
D) Other (please describe after [Answer]: tag below)

[Answer]: B

---

## Question 5
マスターデータ管理（進化パス、スキル定義）の操作範囲はどこまでですか？

A) 既存データの閲覧・編集のみ
B) 閲覧・編集 + 新規追加
C) 閲覧・編集 + 新規追加 + 削除
D) Other (please describe after [Answer]: tag below)

[Answer]: C

---

## Question 6
個別ユーザーのゲームデータ修正の想定ユースケースは何ですか？（ストーリーの受け入れ基準に反映します）

A) バグによるデータ不整合の修正（ポイント補正、レベル修正等）
B) ユーザーからの問い合わせ対応（誤操作の巻き戻し等）
C) テスト・デバッグ目的（任意の値に変更）
D) A + B + C すべて
E) Other (please describe after [Answer]: tag below)

[Answer]: C

---

## Question 7
管理画面での操作ログ（誰がいつ何を変更したか）の記録は必要ですか？

A) 不要（ハッカソンMVPなので省略）
B) 簡易的なログ（変更日時と操作者のみ）
C) 詳細なログ（変更前後の値、操作者、日時）
D) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 8
既存の管理者ストーリー（US-1.7〜US-1.9: ユーザー一覧、アカウント停止/復活、パスワードリセット）はFR-1の認証文脈で作成済みです。FR-7のストーリーではこれらをどう扱いますか？

A) FR-7のストーリーに統合して再作成（stories-admin.mdの内容をstories-fr7.mdに移動）
B) 既存のまま残し、FR-7では未カバー機能のみ新規作成（参照リンクで紐付け）
C) Other (please describe after [Answer]: tag below)

[Answer]: A
