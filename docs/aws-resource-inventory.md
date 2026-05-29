# AWSリソース一覧

## Cognito

| リソース名 | 種別 | 設定 | 投入データ |
|---|---|---|---|
| buta-user-pool-dev | User Pool | メール認証、パスワードポリシー(8文字/大小英数記号) | ユーザー登録はアプリから |
| buta-app-client-dev | App Client | SRP+パスワード認証、secret無し、アクセス1h/リフレッシュ30d | — |

## API Gateway (REST)

| リソース名 | スタック | ルート | 認証 |
|---|---|---|---|
| buta-auth-api-dev | AuthStack | /auth/signup, /auth/confirm, /auth/resend-code, /auth/login, /auth/logout, /auth/refresh, /users/me, /users/profile, /account | 一部Cognito |
| buta-recording-api-dev | RecordingStack | /activities, /activities/batch, /activities/summary, /activities/{recordId}, /categories, /categories/version | Cognito |
| buta-avatar-api-dev | AvatarStack | /avatar, /avatar/evolution-history, /avatar/score-detail | Cognito |
| buta-social-api-dev | BattleSocialStack | /social/friends/*, /rankings, /rankings/me, /battles/history, /battles/history/{matchId} | Cognito |
| buta-admin-api-dev | AdminStack | /admin/* (proxy) | Basic認証(JWT) |

## API Gateway (WebSocket)

| リソース名 | スタック | ルート | 認証 |
|---|---|---|---|
| buta-battle-ws-dev | BattleSocialStack | $connect, $disconnect, $default | tokenクエリパラメータ |

## Lambda

| 関数名 | スタック | ランタイム | メモリ | タイムアウト | 入力元 |
|---|---|---|---|---|---|
| buta-auth-handler-dev | AuthStack | Node.js 20.x ARM64 | 256MB | 10s | API Gateway REST |
| buta-recording-handler | RecordingStack | Node.js 20.x | 256MB | 10s | API Gateway REST |
| buta-categories-handler | RecordingStack | Node.js 20.x | 128MB | 5s | API Gateway REST |
| buta-avatar-handler-dev | AvatarStack | Node.js 20.x ARM64 | 256MB | 10s | API Gateway REST + Lambda Invoke |
| buta-battle-ws-handler-dev | BattleSocialStack | Node.js 20.x ARM64 | 256MB | 10s | API Gateway WebSocket |
| buta-social-handler-dev | BattleSocialStack | Node.js 20.x ARM64 | 256MB | 10s | API Gateway REST |
| buta-admin-handler-dev | AdminStack | Node.js 20.x ARM64 | 256MB | 10s | API Gateway REST |

## DynamoDB

| テーブル名 | PK | SK | GSI | スタック | 初期データ投入 |
|---|---|---|---|---|---|
| butasodate-user-profiles | userId | — | nickname-index (PK: nickname) | AuthStack | アプリからのユーザー登録で自動作成 |
| butasodate-activity-records | userId | sk (recordedAt#recordId) | category-index (PK: userId, SK: gsi1sk) | RecordingStack | アプリからの行動記録で自動作成 |
| butasodate-health-sync-records | userId | sk (syncDate#category) | — | RecordingStack | アプリからの記録で自動作成 |
| butasodate-activity-categories | categoryId | — | — | RecordingStack | **CDKカスタムリソースで8件+1件自動投入** |
| butasodate-avatars | userId | — | — | AvatarStack | アプリからのアバター作成で自動作成 |
| butasodate-evolution-history | userId | occurredAt#historyId | — | AvatarStack | 進化/退化時に自動作成 |
| butasodate-pig-species | speciesId | — | stage-index (PK: stage) | AvatarStack | **手動投入必要（ぶた図鑑）** |
| butasodate-evolution-routes | routeId | — | fromSpecies-index (PK: fromSpeciesId) | AvatarStack | **手動投入必要（進化条件）** |
| butasodate-skills | skillId | — | speciesId-index (PK: speciesId) | AvatarStack | **手動投入必要（スキル定義）** |
| buta-connections-dev | connectionId | — | userId-index (PK: userId) | BattleSocialStack | WebSocket接続時に自動作成/削除 |
| buta-match-queue-dev | userId | — | — | BattleSocialStack | マッチメイキング時に自動作成/削除 |
| buta-matches-dev | matchId | — | — | BattleSocialStack | バトル開始時に自動作成（TTLで削除） |
| buta-battle-history-dev | compositeId (userId#matchId) | — | userId-index (PK: userId, SK: playedAt) | BattleSocialStack | バトル終了時に自動作成 |
| buta-friends-dev | compositeId (min#max userId) | — | userId-index (PK: userId) | BattleSocialStack | フレンド承認時に自動作成 |
| buta-friend-requests-dev | requestId | — | toUserId-index (PK: toUserId) | BattleSocialStack | フレンド申請時に自動作成 |
| buta-rankings-dev | userId | — | rank-index (PK: partition, SK: points) | BattleSocialStack | 初回バトル終了時にUpsertで自動作成 |
| butasodate-admin-audit-log | logId | timestamp | — | AdminStack | 管理画面操作時に自動作成 |
| butasodate-game-config | configKey | — | — | AdminStack | **手動投入必要（ゲーム定数11件）** |

## S3

| バケット名 | スタック | 用途 | 初期データ |
|---|---|---|---|
| butasodate-assets-{accountId}-dev | AvatarStack | スプライト画像/アニメーション | **手動アップロード必要（ぶた画像）** |
| butasodate-admin-spa-{accountId}-dev | AdminStack | 管理画面SPA静的ファイル | **`admin/` ビルド後にアップロード** |

## CloudFront

| リソース名 | スタック | オリジン | 用途 |
|---|---|---|---|
| AdminDistribution | AdminStack | butasodate-admin-spa S3 | 管理画面HTTPS配信 |

## 手動投入が必要なデータまとめ

| 対象 | 件数 | 投入方法 | 手順書 |
|---|---|---|---|
| PigSpecies（ぶた図鑑） | 最低1件（初期ぶた）+ 進化先 | AWS CLI or 管理画面 | deploy-guide.md §4.2 |
| EvolutionRoute（進化条件） | Speciesの関係数分 | AWS CLI or 管理画面 | deploy-guide.md §4.3 |
| Skills（スキル定義） | 進化先ごとに2〜4件 | AWS CLI or 管理画面 | deploy-guide.md §4.4 |
| GameConfig（ゲーム定数） | 11件 | AWS CLI | deploy-guide.md §4.5 |
| スプライト画像 | Species数分 | 管理画面(Presigned URL) or AWS CLI | S3に直接アップロード |
| 管理画面SPAビルド | 1回 | `cd admin && npm run build && aws s3 sync dist/ s3://...` | — |
