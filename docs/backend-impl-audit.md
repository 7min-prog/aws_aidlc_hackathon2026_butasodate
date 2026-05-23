# Backend Implementation Audit

バックエンド実装フェーズの設計判断ログ。各判断の根拠を記録。

---

## 1. CDKスタック整合（ER図/OpenAPIをマスターとして突合）

### 判断: 全5スタックを bin/app.ts に登録

**根拠**: app.ts に AuthStack と RecordingStack しかなく、Avatar/BattleSocial/Admin の3スタックがデプロイ不可能だった。ER図で定義した18テーブルのうち大半が作成されない状態。

### 判断: テーブル名を `butasodate-user-profiles` に統一

**根拠**: auth-stack が `buta-users-dev` を使っていたが、ER図では `butasodate-user-profiles`。social-handler も同テーブルを参照するため、名前の不一致は実行時エラーに直結。ER図をマスターとした。

### 判断: EvolutionPath → PigSpecies + EvolutionRoute に分離

**根拠**: ユーザーが「同じぶたに複数ルートから到達したい」と明確に要望。旧モデル（1パス=1種）ではN:Nの関係を表現できない。分離により図鑑エントリと進化条件を独立管理可能に。

### 判断: avatar-stack から mTLS クライアント証明書を削除、Cognito認証に変更

**根拠**: 他の全スタックがCognito Authorizerを使用。avatar-stack だけmTLSだとフロントエンドの認証フローが分岐して複雑化。統一した。

### 判断: avatar-stack に GameConfig テーブル参照を追加

**根拠**: ER図レビューで「GameConfigが設計通りに使われるか不安」との指摘があり、「ゲームバランス定数は必ずこのテーブルから読む」ルールを定めた。avatar-handlerが進化判定でこれらの定数を使うため必須。

---

## 2. /health-sync ルート削除

**根拠**: ヘルスデータ同期はスマホ内のアプリ間通信（HealthKit/Health Connect → アプリ）で完結し、サーバー通信は不要。同期後の記録は既存の POST /activities で十分カバーできるとユーザーと合意。不要なLambda + APIルートを残すと混乱の元。

---

## 3. /activities/batch と /activities/summary を残す判断

**根拠**:
- `/batch`: OpenAPIでは POST /activities が配列対応で統合されているが、CDK側にルートが既にあり、フロントが直接叩いている可能性を排除できない。破壊的変更回避のため残置。
- `/summary`: GET /activities にsummary同梱（OpenAPI設計）だと一覧取得のたびに集計計算が走る。ホーム画面でsummaryだけ欲しいユースケースに対して非効率。パフォーマンスの観点から分離維持が合理的。

---

## 4. Lambda Invoke 廃止 → recording-handler に avatar-service 統合

**根拠**: 
- avatar-handler を「API Gateway経由」と「Lambda Invoke経由」の2通りで呼ぶのはアンチパターン。認証方式が異なり（Cognito vs ヘッダー）、getUserId のロジックが分岐する。
- Lambda Invoke はコールドスタート+ネットワークレイテンシが追加される。ポイント加算は記録のたびに発生する高頻度処理。
- recording-handler に avatar-points-service を内包すれば同一プロセスで完結し、DynamoDB直アクセスのみ。IAM権限も単純化。
- avatar-handler はAPI Gateway経由の「アバター情報取得」専用に専念でき、責務が明確になる。

---

## 5. avatar-handler の getUserId 修正

**根拠**: Honoのaws-lambdaアダプター経由でAPI Gatewayから呼ばれると、Cognito Authorizerの検証結果は `event.requestContext.authorizer.claims.sub` に入る。元のコードは `c.req.header('x-user-id')` のみ参照していたため、正規のAPI Gateway経由リクエストで常にuserIdがnull → 401エラー。致命的バグ。

---

## 6. Flutter モデル修正

### Avatar.fromJson: evolutionPathId → currentSpeciesId

**根拠**: バックエンドがER図準拠で `currentSpeciesId` を返すように変更済み。旧フィールド名のままだとJSONパースで値が取れずnull。`spriteSheetKey` はAvatarテーブルから削除（PigSpeciesテーブルに移動）されたため、requiredフィールドとして残すとパースエラー。

### ApiClient: 単一baseUrl → サービス別メソッド

**根拠**: 5つの独立したAPI Gatewayがそれぞれ異なるURLを持つ。カスタムドメインで統合する工数（Route53 + ACM + API Gatewayマッピング）はハッカソンのタイムボックスに収まらない。サービス別メソッドが最小工数。

### accessToken → idToken

**根拠**: Cognito User Pools Authorizer は仕様上 ID Token を検証する。Access Token を送ると `Unauthorized` が返る。AWS公式ドキュメント準拠。

---

## 7. RankingEntry 自動作成（Upsert）

**根拠**: ランキングテーブルに初期エントリがないと、初バトル終了時の UpdateCommand（ADD演算）が対象アイテムなしでエラーになる可能性。DynamoDB の ADD 演算は存在しないアイテムに対して自動作成するが、SET 句で `if_not_exists` を使って `partition` フィールドも確実に初期化。これにより専用の初期化処理が不要。

---

## 8. healthSyncTable 削除

**根拠**: /health-sync ルートを削除した時点でこのテーブルに書き込む処理がどこにも存在しない。残しても使われないデッドリソース。CDKからの削除で次回デプロイ時にテーブルも消える（RemovalPolicy.DESTROY）。

---

## 9. PUT /admin/users/{username}/profile 追加

**根拠**: OpenAPIに定義済み（管理者がニックネーム・メール + ゲームデータを修正するAPI）だがadmin-handlerに実装がなかった。管理画面のユーザー詳細画面から編集操作を行うために必要。既存の `/avatar` PUT はアバターデータの全置換であり、プロフィール（nickname/email）の更新を含まない。分けることで部分更新が可能。

---

## 10. admin SPA デプロイ手順追記

**根拠**: deploy-guide.md に管理画面SPAのビルド・S3アップロード手順がなかった。CloudFrontは作成されてもS3が空なら403。手順がないと「デプロイしたのに管理画面が開けない」問題が発生する。

---

## アーキテクチャ最終形

```
Flutter App
  ├─→ API GW (auth)     → Lambda auth-handler     → Cognito + DynamoDB(user-profiles)
  ├─→ API GW (recording)→ Lambda recording-handler → DynamoDB(activity-records, categories, avatars, species, routes, skills, game-config)
  ├─→ API GW (avatar)   → Lambda avatar-handler   → DynamoDB(avatars, species, routes, skills, evolution-history, game-config)
  ├─→ API GW (social)   → Lambda social-handler   → DynamoDB(friends, friend-requests, rankings, battle-history, user-profiles)
  ├─→ WebSocket (battle) → Lambda battle-ws-handler → DynamoDB(connections, match-queue, matches, battle-history, rankings)
  └─→ CloudFront → S3(admin-spa)

Admin SPA
  └─→ API GW (admin)    → Lambda admin-handler    → Cognito + DynamoDB(avatars, species, routes, skills, audit-log, game-config, activity-records, user-profiles)
```

recording-handler が avatar 関連テーブルに直接アクセスする設計（Lambda Invoke廃止）により、ポイント加算のレイテンシが低減し、認証の一貫性が確保された。
