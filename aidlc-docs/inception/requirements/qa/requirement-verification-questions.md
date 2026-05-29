# 要件確認質問

以下の質問に回答してください。各質問の [Answer]: タグの後に選択肢の文字を記入してください。
該当する選択肢がない場合は、最後の選択肢（Other）を選び、[Answer]: タグの後に詳細を記述してください。

---

## Question 1
このアプリのターゲットプラットフォームは何ですか？

A) iOS のみ
B) Android のみ
C) iOS と Android の両方（クロスプラットフォーム）
D) Web アプリケーション
E) Web + モバイル（レスポンシブ Web またはPWA）
X) Other (please describe after [Answer]: tag below)

[Answer]: C

## Question 2
使用したい技術スタック / フレームワークの希望はありますか？

A) React Native（クロスプラットフォームモバイル）
B) Flutter（クロスプラットフォームモバイル）
C) Next.js / React（Web アプリ）
D) Swift (iOS) + Kotlin (Android) のネイティブ開発
E) 特に希望なし（最適なものを提案してほしい）
X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 3
バックエンド / サーバーサイドの構成について希望はありますか？

A) AWS サーバーレス（Lambda + API Gateway + DynamoDB）
B) AWS コンテナ（ECS/Fargate + RDS）
C) Firebase（Authentication + Firestore + Cloud Functions）
D) 特に希望なし（最適なものを提案してほしい）
X) Other (please describe after [Answer]: tag below)

[Answer]: それぞれのメリデメ教えてください

## Question 4
Apple Health / Google Fit との連携について、どのデータを取得したいですか？

A) 体重・BMI のみ
B) 体重・BMI + 歩数・運動データ
C) 体重・BMI + 歩数・運動データ + 睡眠データ
D) 体重・BMI + 歩数・運動データ + 睡眠データ + 食事データ
E) 可能な限り多くのヘルスデータ
X) Other (please describe after [Answer]: tag below)

[Answer]: Eと可能であればスマホのスクリーンタイムや動画視聴時間などもほしい

## Question 5
"ぶた"アバターの進化システムについて、どの程度の複雑さを想定していますか？

A) シンプル（3〜5段階の進化、見た目の変化のみ）
B) 中程度（5〜10段階の進化、見た目 + ステータス変化）
C) 複雑（多数の進化パス、見た目 + ステータス + スキル）
D) 特に希望なし（提案してほしい）
X) Other (please describe after [Answer]: tag below)

[Answer]: C

## Question 6
ユーザー同士のバトルシステムについて、どのような形式を想定していますか？

A) 非同期バトル（相手のアバターデータと自動対戦）
B) リアルタイム対戦（同時接続での対戦）
C) ランキング形式（スコアベースの順位付け）
D) 非同期バトル + ランキング形式の組み合わせ
X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 7
「不健康な行動」の記録方法について、どのような入力方式を想定していますか？

A) 手動入力のみ（ユーザーが行動を選択・記録）
B) ヘルスデータからの自動検出のみ（運動不足、体重増加等）
C) 手動入力 + ヘルスデータからの自動検出の組み合わせ
D) 特に希望なし（提案してほしい）
X) Other (please describe after [Answer]: tag below)

[Answer]: C

## Question 8
ユーザー認証方式について、どれを希望しますか？

A) メールアドレス + パスワード
B) ソーシャルログイン（Google, Apple, LINE 等）
C) メール + ソーシャルログインの両方
D) 特に希望なし（提案してほしい）
X) Other (please describe after [Answer]: tag below)

[Answer]: C

## Question 9
ハッカソンの期間・スケジュールを考慮して、MVP（最小限の実用的な製品）の範囲をどう考えていますか？

A) コア機能のみ（行動記録 + アバター育成）
B) コア機能 + ヘルスデータ連携
C) コア機能 + ヘルスデータ連携 + バトルシステム
D) フル機能（すべての機能を含む）
X) Other (please describe after [Answer]: tag below)

[Answer]: C

## Question 10
アバターの画像・グラフィックスについて、どのように対応する予定ですか？

A) プレースホルダー画像（シンプルな図形やアイコン）で進める
B) AI 生成画像を使用する
C) デザイナーが別途作成する（開発では仮画像を使用）
D) 特に希望なし（提案してほしい）
X) Other (please describe after [Answer]: tag below)

[Answer]: 画像と動画がいい

## Question 11: Security Extensions
このプロジェクトにセキュリティ拡張ルールを適用しますか？

A) はい — すべてのセキュリティルールをブロッキング制約として適用する（本番グレードのアプリケーション向け推奨）
B) いいえ — セキュリティルールをスキップする（PoC、プロトタイプ、実験的プロジェクト向け）
X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 12: Property-Based Testing Extension
このプロジェクトにプロパティベーステスト（PBT）ルールを適用しますか？

A) はい — すべてのPBTルールをブロッキング制約として適用する（ビジネスロジック、データ変換、シリアライゼーション、ステートフルコンポーネントを含むプロジェクト向け推奨）
B) 部分的 — 純粋関数とシリアライゼーションのラウンドトリップにのみPBTルールを適用する
C) いいえ — PBTルールをスキップする（シンプルなCRUDアプリ、UIのみのプロジェクト向け）
X) Other (please describe after [Answer]: tag below)

[Answer]: プロパティベーステストって何？
