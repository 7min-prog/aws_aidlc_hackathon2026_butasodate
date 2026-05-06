# Components

## フロントエンド（Flutter）

構成方針: Feature-first + 軽量クリーンアーキテクチャ（各Feature内に screens/, providers/, models/, repositories/）

### FE-AUTH: 認証モジュール
- **責務**: ユーザー認証（メール、Google、X）、セッション管理、プロフィール設定
- **対応FR**: FR-1

### FE-RECORDING: 行動記録モジュール
- **責務**: 不健康行動のカテゴリ選択・記録、記録履歴表示、サマリー表示
- **対応FR**: FR-2

### FE-HEALTH: ヘルスデータ連携モジュール
- **責務**: HealthKit/Health Connect連携、同期処理、起動時サマリー表示
- **対応FR**: FR-3

### FE-AVATAR: アバター育成モジュール
- **責務**: ぶたアバター表示、進化演出、ステータス表示、スコア表示
- **対応FR**: FR-4

### FE-BATTLE: バトルモジュール
- **責務**: マッチメイキングUI、バトル画面、ターン操作、結果表示、WebSocket通信
- **対応FR**: FR-5

### FE-SOCIAL: ソーシャルモジュール
- **責務**: フレンド検索・申請・一覧、SNS共有（OS共有シート経由）
- **対応FR**: FR-6

### FE-SHARED: 共通モジュール
- **責務**: 共通ウィジェット、API クライアント、認証トークン管理、エラーハンドリング、ルーティング

---

## バックエンド（AWS Lambda）

### BE-API: REST API Lambda（Monolithic）
- **責務**: 全REST APIエンドポイントの処理（認証以外）。内部ルーティングでドメイン振り分け
- **ドメイン**: recording, avatar, health-sync, social, admin
- **対応FR**: FR-1〜FR-7

### BE-WEBSOCKET: WebSocket Lambda
- **責務**: バトル用リアルタイム通信。マッチメイキング、ターン処理、状態同期
- **対応FR**: FR-5

### BE-AUTH: 認証（Amazon Cognito）
- **責務**: ユーザー認証・認可。メール+パスワード、Google、X のソーシャルログイン
- **対応FR**: FR-1

---

## インフラ・ストレージ

### INFRA-DB: DynamoDB（Table per Entity）
- **責務**: データ永続化
- **テーブル**: Users, Avatars, Records, Battles, Friends, MasterData

### INFRA-S3: S3
- **責務**: ドット絵スプライトシート（アバターアニメーション素材）の保存・配信

### INFRA-APIGW: API Gateway
- **責務**: REST API + WebSocket API のエンドポイント管理。パスプレフィックスで player/admin 分離

---

## 管理画面（React）

### ADMIN-WEB: 管理画面Webアプリ
- **責務**: ユーザー管理、ゲームデータ管理、マスターデータ管理
- **対応FR**: FR-7
- **通信**: 同じAPI Gateway の /admin/* パスを使用
