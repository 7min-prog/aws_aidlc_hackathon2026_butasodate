# Application Design Plan

## 設計質問

以下の質問に回答してください。[Answer]: の後に回答を記入してください。

---

### コンポーネント構成

**Q1**: フロントエンド（Flutter）のコンポーネント分割方針はどちらが良いですか？

A) Feature-first（機能単位: auth/, recording/, avatar/, battle/, social/, health/）
B) Layer-first（レイヤー単位: screens/, widgets/, services/, models/）
C) Feature-first + 共通レイヤー（Feature単位だが、shared/に共通ウィジェット・モデルを配置）

[Answer]:3たくのどれでもない、クリーンアーキテクチャで進めるべきかどうかで悩んでいます

---

**Q2**: バックエンド（Lambda）の分割粒度はどちらが良いですか？

A) 1 Lambda per API endpoint（エンドポイントごとに1つのLambda）
B) 1 Lambda per domain（ドメインごとに1つのLambda: auth, recording, avatar, battle, social, admin）
C) Monolithic Lambda（1つのLambdaで全APIを処理、ルーティングはコード内）

[Answer]:Lambdaが増えると管理負荷が上がるのでCで進めようかと思うがどう？

---

### サービス層設計

**Q3**: バトルのリアルタイム通信で、ゲームステート（HP、バフ等）の管理はどこで行いますか？

A) サーバー側（Lambda + DynamoDB）で完全管理。クライアントは表示のみ
B) クライアント側で計算し、サーバーは検証のみ
C) サーバー権威型（サーバーが正、クライアントは予測表示して後からサーバー結果で補正）

[Answer]:A

---

**Q4**: AI画像/動画生成のタイミングはどうしますか？

A) リアルタイム生成（進化時にその場で生成）
B) 事前生成（全進化パターンの画像/動画を事前に生成してS3に保存）
C) ハイブリッド（基本パターンは事前生成、カスタム要素はリアルタイム）

[Answer]:B

---

### コンポーネント間通信

**Q5**: フロントエンド ↔ バックエンド間の通信で、認証トークン以外にリアルタイム通知（フレンド申請受信等）は必要ですか？

A) WebSocketはバトル専用。フレンド申請等はアプリ起動時のポーリングで取得
B) WebSocketを常時接続し、バトル以外の通知もリアルタイムで受信

[Answer]:A

---

**Q6**: 管理画面（React）とバックエンドの通信は、プレイヤー向けAPIと同じAPI Gatewayを使いますか？

A) 同じAPI Gateway（パスで分離: /api/player/*, /api/admin/*）
B) 別のAPI Gateway（管理画面専用）

[Answer]:ハッカソン用途で開発するので巣が、この場合はAのほうが楽？

---

### データ設計方針

**Q7**: DynamoDBのテーブル設計方針はどちらですか？

A) Single Table Design（1テーブルに全エンティティ、GSIで検索）
B) Table per Entity（ユーザー、アバター、バトル、フレンド等テーブル分離）

[Answer]:B

---

## 設計アーティファクト生成計画

回答後、以下のアーティファクトを生成します：

- [ ] components.md — コンポーネント定義と責務
- [ ] component-methods.md — メソッドシグネチャ
- [ ] services.md — サービス定義とオーケストレーション
- [ ] component-dependency.md — 依存関係と通信パターン
- [ ] application-design.md — 統合設計ドキュメント
