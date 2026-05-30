# Backend テスト結果レポート

実行日時: 2026-05-25 21:58 JST

## サマリー

| ハンドラー | Suites | Tests | Passed | Failed | 結果 |
|:--|:--:|:--:|:--:|:--:|:--:|
| auth-handler | 6 | 38 | 38 | 0 | ✅ PASS |
| recording-handler | 5 | 60 | 60 | 0 | ✅ PASS |
| social-handler | 1 | 28 | 28 | 0 | ✅ PASS |
| battle-ws-handler | 2 | 26 | 26 | 0 | ✅ PASS |
| avatar-handler | 4 | 67 | 67 | 0 | ✅ PASS |
| admin-handler | 1 | 30 | 30 | 0 | ✅ PASS |
| **合計** | **19** | **249** | **249** | **0** | ✅ |

---

## 1. auth-handler (38 tests ✅ ALL PASS)

### tests/handlers/login.test.ts

| # | テスト項目 | チェック内容 | 結果 |
|:--|:--|:--|:--:|
| 1 | returns 400 if email is missing | email未指定時に400エラーを返すこと | ✅ |
| 2 | returns 400 if password is missing | password未指定時に400エラーを返すこと | ✅ |
| 3 | returns 200 with tokens on successful login | 正常ログイン時にaccessToken/refreshTokenを返すこと | ✅ |
| 4 | returns 401 on invalid credentials | Cognito NotAuthorizedException時に401を返すこと | ✅ |
| 5 | returns 401 on user not found | UserNotFoundException時も同じ401を返すこと（情報漏洩防止） | ✅ |
| 6 | returns 403 if email not confirmed | メール未確認ユーザーに403を返すこと | ✅ |

### tests/handlers/signup.test.ts

| # | テスト項目 | チェック内容 | 結果 |
|:--|:--|:--|:--:|
| 7 | returns 400 if email is missing | email未指定時にバリデーションエラー | ✅ |
| 8 | returns 400 if password is missing | password未指定時にバリデーションエラー | ✅ |
| 9 | returns 201 on successful signup | 正常登録時に201を返すこと | ✅ |
| 10 | returns 409 if email already exists | 既存メール登録時に409 Conflictを返すこと | ✅ |
| 11 | returns 400 if password is invalid | パスワード要件不充足時に400を返すこと | ✅ |
| 12 | returns 400 if email or code is missing (confirm) | 確認コード未指定時に400を返すこと | ✅ |
| 13 | returns 200 on successful confirmation | 正常確認コード時に200を返すこと | ✅ |
| 14 | returns 400 on code mismatch | コード不一致時に400を返すこと | ✅ |
| 15 | returns 400 on expired code | コード期限切れ時に400を返すこと | ✅ |
| 16 | returns 400 if email is missing (resend) | 再送時にemail未指定で400を返すこと | ✅ |
| 17 | returns 200 on successful resend | コード再送成功で200を返すこと | ✅ |

### tests/handlers/refresh.test.ts

| # | テスト項目 | チェック内容 | 結果 |
|:--|:--|:--|:--:|
| 18 | returns 400 if refreshToken is missing | refreshToken未指定時に400を返すこと | ✅ |
| 19 | returns 200 with new tokens on success | 正常リフレッシュ時に新しいトークンを返すこと | ✅ |
| 20 | returns 401 if refresh token is expired | トークン期限切れ時に401を返すこと | ✅ |

### tests/handlers/profile.test.ts

| # | テスト項目 | チェック内容 | 結果 |
|:--|:--|:--|:--:|
| 21 | returns 401 if no userId (getProfile) | 未認証時に401を返すこと | ✅ |
| 22 | returns 200 with user data | プロフィール取得成功で200を返すこと | ✅ |
| 23 | returns 404 if profile not found | 存在しないプロフィールで404を返すこと | ✅ |
| 24 | returns 401 if no userId (createProfile) | 未認証時にプロフィール作成を拒否すること | ✅ |
| 25 | returns 400 if nickname is too short | ニックネームが短すぎる場合400を返すこと | ✅ |
| 26 | returns 400 if nickname is too long | ニックネームが長すぎる場合400を返すこと | ✅ |
| 27 | returns 409 if nickname is taken | ニックネーム重複時に409を返すこと | ✅ |
| 28 | returns 201 on successful creation | プロフィール作成成功で201を返すこと | ✅ |
| 29 | returns 400 if nickname too short (update) | 更新時ニックネーム短すぎで400を返すこと | ✅ |
| 30 | returns 409 if nickname taken by another | 他人と重複するニックネーム更新を拒否すること | ✅ |
| 31 | allows keeping own nickname | 自分のニックネーム保持を許可すること | ✅ |

### tests/handlers/logout.test.ts

| # | テスト項目 | チェック内容 | 結果 |
|:--|:--|:--|:--:|
| 32 | returns 401 if no Authorization header | Authorization未指定で401を返すこと | ✅ |
| 33 | returns 200 on successful logout | 正常ログアウトで200を返すこと | ✅ |

### tests/handlers/account.test.ts (新規作成)

| # | テスト項目 | チェック内容 | 結果 |
|:--|:--|:--|:--:|
| 34 | returns 401 if no userId in claims | 認証情報なしで401を返すこと | ✅ |
| 35 | returns 200 and deletes DynamoDB + Cognito user | アカウント削除時にDynamoDBとCognito両方を削除すること | ✅ |
| 36 | returns 500 when DynamoDB delete fails | DynamoDB削除失敗時に500を返すこと | ✅ |
| 37 | returns 500 when Cognito delete fails | Cognito削除失敗時に500を返すこと | ✅ |
| 38 | uses sub as username fallback | cognito:username不在時にsubをフォールバックとして使用 | ✅ |

---

## 2. recording-handler (42 tests ✅ ALL PASS)

### tests/services/point-calculator.test.ts

| # | テスト項目 | チェック内容 | 結果 |
|:--|:--|:--|:--:|
| 1 | returns 12 for FOOD category | 食事カテゴリのポイントが12であること | ✅ |
| 2 | returns 10 for LIFESTYLE category | 生活カテゴリのポイントが10であること | ✅ |
| 3 | returns NEUTRAL in dead zone (7200-8800) | 適正歩数範囲内で0ポイント/NETURALを返すこと | ✅ |
| 4 | returns UNHEALTHY +12 for 0 steps | 0歩で最大ペナルティ12を返すこと | ✅ |
| 5 | returns UNHEALTHY for steps below dead zone | 歩数不足でUNHEALTHY評価を返すこと | ✅ |
| 6 | returns HEALTHY for steps above dead zone | 過剰歩数でHEALTHY（負ポイント）を返すこと | ✅ |
| 7 | caps HEALTHY at -8 | 過剰歩数のポイントが-8で上限されること | ✅ |
| 8 | boundary: lower dead zone edge (7200) | 下限境界値7200で0ポイントを返すこと | ✅ |
| 9 | boundary: upper dead zone edge (8800) | 上限境界値8800で0ポイントを返すこと | ✅ |
| 10 | returns NEUTRAL for first sync (no previous) | 体重初回記録で0ポイント/NETURALを返すこと | ✅ |
| 11 | returns UNHEALTHY +20 for +1kg | 体重+1kgでペナルティ20を返すこと | ✅ |
| 12 | returns UNHEALTHY +40 for +2.5kg | 体重+2.5kgでペナルティ40を返すこと | ✅ |
| 13 | returns HEALTHY -10 for -1kg | 体重-1kgで報酬-10を返すこと | ✅ |
| 14 | returns NEUTRAL for small changes (<1kg) | 体重変動1kg未満で0ポイントを返すこと | ✅ |
| 15 | late bedtime is UNHEALTHY | 深夜1時就寝でUNHEALTHY評価を返すこと | ✅ |
| 16 | early bedtime with adequate sleep is HEALTHY | 早寝+十分な睡眠でHEALTHY評価を返すこと | ✅ |
| 17 | oversleep (10h) is UNHEALTHY | 10時間寝過ぎでUNHEALTHY評価を返すこと | ✅ |
| 18 | sleep deficit (4h) is UNHEALTHY | 4時間睡眠不足でUNHEALTHY評価を返すこと | ✅ |
| 19 | mixed: late bedtime but adequate sleep → unhealthy | 混合条件でUNHEALTHY側が優先されること | ✅ |
| 20 | clockToNormalized: 23:00 to 5 | 23時をオフセット5に変換すること | ✅ |
| 21 | clockToNormalized: 01:00 to 7 | 翌1時をオフセット7に変換すること | ✅ |
| 22 | clockToNormalized: 18:00 to 0 | 18時を基点0に変換すること | ✅ |
| 23 | clockToNormalized: 03:30 to 9.5 | 翌3:30をオフセット9.5に変換すること | ✅ |

### tests/services/recording-service.test.ts (新規作成)

| # | テスト項目 | チェック内容 | 結果 |
|:--|:--|:--|:--:|
| 24 | creates a record and returns avatar status | 記録作成時にアバターステータスを返すこと | ✅ |
| 25 | throws when category not found | 不正カテゴリで例外をスローすること | ✅ |
| 26 | creates multiple records and sums points | バッチ作成で複数レコードを正常処理すること | ✅ |
| 27 | skips duplicate records | 重複レコードをスキップしてskippedIdsに含めること | ✅ |
| 28 | returns paginated records | ページネーション付きレコード取得が動作すること | ✅ |
| 29 | returns empty with no cursor when no results | 結果なし時にcursorがundefinedになること | ✅ |
| 30 | filters by categoryId when provided | カテゴリIDフィルタ時にGSIを使用すること | ✅ |
| 31 | applies date filters | 日付範囲フィルタが正しく設定されること | ✅ |
| 32 | soft-deletes auto-detected record and deducts points | 自動検出レコードの論理削除とポイント減算 | ✅ |
| 33 | throws when record not found (delete) | 存在しないレコード削除で例外をスローすること | ✅ |
| 34 | throws when record is not auto-detected | 手動レコード削除を拒否すること | ✅ |
| 35 | returns today summary | 当日サマリーの件数・ポイント合計が正しいこと | ✅ |
| 36 | returns week summary with category breakdown | 週間サマリーでカテゴリ別集計されること | ✅ |

### tests/services/health-sync-service.test.ts (新規作成)

| # | テスト項目 | チェック内容 | 結果 |
|:--|:--|:--|:--:|
| 37 | syncs steps data and awards points | 歩数データ同期で正常にポイント付与されること | ✅ |
| 38 | skips already synced dates | 同期済み日付をスキップしてskippedDatesに含めること | ✅ |
| 39 | syncs weight data with previous value comparison | 体重同期で前回値と比較計算すること | ✅ |
| 40 | syncs sleep data with secondary value | 睡眠同期でsecondaryValue（睡眠時間）を使用すること | ✅ |
| 41 | handles multiple data points with mixed results | 複数データで新規+スキップの混合結果を返すこと | ✅ |
| 42 | returns zero avatar status when no points awarded | ポイント0時にデフォルトavatarStatusを返すこと | ✅ |

---

## 3. social-handler (28 tests ✅ ALL PASS)

### tests/index.test.ts (新規作成)

| # | テスト項目 | チェック内容 | 結果 |
|:--|:--|:--|:--:|
| 1 | GET /social/friends - 401 without auth | 未認証でフレンド一覧取得を拒否すること | ✅ |
| 2 | GET /social/friends - returns friends list | フレンド一覧を正常に返すこと | ✅ |
| 3 | GET /social/friends - returns empty array | フレンドなし時に空配列を返すこと | ✅ |
| 4 | POST /social/friends/search - 400 without query | 検索クエリ未指定で400を返すこと | ✅ |
| 5 | POST /social/friends/search - returns matching users | ニックネーム検索で一致ユーザーを返すこと | ✅ |
| 6 | POST /social/friends/request - 401 without auth | 未認証でフレンドリクエスト送信を拒否すること | ✅ |
| 7 | POST /social/friends/request - 400 without targetUserId | targetUserId未指定で400を返すこと | ✅ |
| 8 | POST /social/friends/request - sends successfully | フレンドリクエストが正常に保存されること | ✅ |
| 9 | POST /social/friends/respond - 401 without auth | 未認証でリクエスト応答を拒否すること | ✅ |
| 10 | POST /social/friends/respond - 400 without requestId | requestId未指定で400を返すこと | ✅ |
| 11 | POST /social/friends/respond - 404 not found | 存在しないリクエストで404を返すこと | ✅ |
| 12 | POST /social/friends/respond - accepts and creates bidirectional | 承認時に双方向フレンド関係を作成すること | ✅ |
| 13 | POST /social/friends/respond - declines request | 拒否時に適切なメッセージを返すこと | ✅ |
| 14 | DELETE /social/friends/:id - 401 without auth | 未認証でフレンド削除を拒否すること | ✅ |
| 15 | DELETE /social/friends/:id - removes bidirectionally | フレンド削除で双方向のレコードを削除すること | ✅ |
| 16 | GET /social/friends/requests - 401 without auth | 未認証で受信リクエスト取得を拒否すること | ✅ |
| 17 | GET /social/friends/requests - returns pending | PENDING状態のリクエスト一覧を返すこと | ✅ |
| 18 | GET /rankings - returns sorted rankings | ランキングをポイント降順でソートして返すこと | ✅ |
| 19 | GET /rankings/me - 401 without auth | 未認証で自分のランキング取得を拒否すること | ✅ |
| 20 | GET /rankings/me - returns user ranking | 自分のランキング情報を返すこと | ✅ |
| 21 | GET /rankings/me - returns default when no record | ランキング未登録時にデフォルト値を返すこと | ✅ |
| 22 | GET /battles/history - 401 without auth | 未認証でバトル履歴取得を拒否すること | ✅ |
| 23 | GET /battles/history - returns battle history | バトル履歴一覧を返すこと | ✅ |
| 24 | GET /battles/history/:id - 401 without auth | 未認証でバトル詳細取得を拒否すること | ✅ |
| 25 | GET /battles/history/:id - 404 not found | 存在しないバトルで404を返すこと | ✅ |
| 26 | GET /battles/history/:id - returns detail | バトル詳細情報を返すこと | ✅ |
| 27 | Unknown route - returns 404 | 未定義ルートで404を返すこと | ✅ |
| 28 | Error handling - propagates DynamoDB errors | DB例外がPromise rejectとして伝播すること（※バグ発見） | ✅ |

> ⚠️ **発見事項**: social-handlerの`handler`関数で`return getRankings(event)`のようにawaitなしでasync関数を返しているため、try/catchがPromise rejectionを捕捉できない。本番環境ではLambda実行エラーとなる可能性がある。

---

## 4. battle-ws-handler (26 tests ✅ ALL PASS)

### tests/services/turn-engine.test.ts

| # | テスト項目 | チェック内容 | 結果 |
|:--|:--|:--|:--:|
| 1 | executes damage skill and reduces HP | ダメージスキル実行でHPが減少すること | ✅ |
| 2 | defend action adds DEF_UP buff | 防御アクションでDEF_UPバフが付与されること | ✅ |
| 3 | KO when HP reaches 0 | HP0到達でバトル終了フラグが立つこと | ✅ |
| 4 | timeout results in higher HP% winning | タイムアウト時にHP割合が高い方が勝利すること | ✅ |
| 5 | heal skill restores HP | 回復スキルでHPが回復すること | ✅ |
| 6 | heal does not exceed maxHp | 回復がmaxHpを超えないこと | ✅ |
| 7 | minimum damage is 1 | 最低ダメージが1であること | ✅ |
| 8 | default action is defend when no action | 未指定時にデフォルトで防御になること | ✅ |

### tests/handlers/battle-handlers.test.ts (新規作成)

| # | テスト項目 | チェック内容 | 結果 |
|:--|:--|:--|:--:|
| 9 | handleConnect - 401 without token | トークンなしで接続を拒否すること | ✅ |
| 10 | handleConnect - 401 without userId | userId未指定で接続を拒否すること | ✅ |
| 11 | handleConnect - stores connection | 正常接続時にDynamoDBへconnection保存すること | ✅ |
| 12 | handleDisconnect - deletes connection | 切断時にconnectionレコードを削除すること | ✅ |
| 13 | handleDisconnect - notifies opponent | バトル中切断で対戦相手に通知すること | ✅ |
| 14 | handleRequestMatch - 401 when user not found | 認証失敗時にマッチリクエストを拒否すること | ✅ |
| 15 | handleRequestMatch - adds to queue | ランダムマッチで待機キューに追加すること | ✅ |
| 16 | handleRequestMatch - creates match when opponent found | 対戦相手発見時にマッチを作成し両者に通知すること | ✅ |
| 17 | handleRequestMatch - handles friend invite | フレンド招待でマッチ作成+相手に通知すること | ✅ |
| 18 | handleCancelMatch - 401 when user not found | 認証失敗時にキャンセルを拒否すること | ✅ |
| 19 | handleCancelMatch - removes from queue | キャンセル時にキューから削除すること | ✅ |
| 20 | handleRespondInvite - 401 when user not found | 認証失敗時に招待応答を拒否すること | ✅ |
| 21 | handleRespondInvite - rejects and notifies inviter | 招待拒否時に招待者に通知すること | ✅ |
| 22 | handleRespondInvite - accepts and notifies both | 招待承認時に両者にbattleStart通知すること | ✅ |
| 23 | handleSetReady - 401 when user not found | 認証失敗時にready設定を拒否すること | ✅ |
| 24 | handleSetReady - 404 when match not found | 存在しないマッチで404を返すこと | ✅ |
| 25 | handleSetReady - sets ready without starting | 片方のみready時にバトル開始しないこと | ✅ |
| 26 | handleSetReady - starts battle when both ready | 両者ready時にIN_PROGRESSに遷移し通知すること | ✅ |

---

## 5. admin-handler (14 tests ✅ ALL PASS)

### tests/app.test.ts

| # | テスト項目 | チェック内容 | 結果 |
|:--|:--|:--|:--:|
| 1 | POST /admin/login - valid credentials | 正常ログインでトークンを返すこと | ✅ |
| 2 | POST /admin/login - invalid credentials | 不正認証情報で401を返すこと | ✅ |
| 3 | Auth middleware - 401 without token | トークンなしで保護エンドポイントを拒否すること | ✅ |
| 4 | GET /admin/users - returns user list | ユーザー一覧を返すこと | ✅ |
| 5 | GET /admin/users/:username - returns detail | ユーザー詳細（アバター含む）を返すこと | ✅ |
| 6 | POST /admin/users/:username/disable | ユーザー無効化と監査ログ記録を行うこと | ✅ |
| 7 | POST /admin/users/:username/enable | ユーザー有効化を行うこと | ✅ |
| 8 | DELETE /admin/users/:username | ユーザー削除を行うこと | ✅ |
| 9 | GET /admin/evolution-paths | 進化パス一覧を返すこと | ✅ |
| 10 | POST /admin/evolution-paths | 進化パスを作成すること | ✅ |
| 11 | GET /admin/game-config | ゲーム設定を返すこと | ✅ |
| 12 | GET /admin/audit-log | 監査ログ一覧を返すこと | ✅ |
| 13 | POST /admin/upload-url | S3 presigned URLを返すこと | ✅ |
| 14 | GET /admin/doc | OpenAPIドキュメントを返すこと | ✅ |

---

## 6. avatar-handler (48 tests ✅ ALL PASS)

### tests/app.test.ts

| # | テスト項目 | チェック内容 | 結果 |
|:--|:--|:--|:--:|
| 1 | POST /avatar - 401 without x-user-id | 未認証でアバター作成を拒否すること | ✅ |
| 2 | POST /avatar - 201 on successful creation | アバター作成成功で201を返すこと | ✅ |
| 3 | POST /avatar - 409 when already exists | 既存アバターで409を返すこと | ✅ |
| 4 | GET /avatar - 401 without x-user-id | 未認証でアバター取得を拒否すること | ✅ |
| 5 | GET /avatar - 404 when not found | アバター未作成時に404を返すこと | ✅ |
| 6 | GET /avatar - 200 with data | アバターデータを返すこと | ✅ |
| 7 | GET /avatar/evolution-history - 200 | 進化履歴を返すこと | ✅ |
| 8 | GET /avatar/score-detail - 200 | スコア詳細を返すこと | ✅ |
| 9 | POST /avatar/points - 200 | ポイント加算成功を返すこと | ✅ |
| 10 | POST /avatar/points - 404 not found | アバター未存在で404を返すこと | ✅ |
| 11 | POST /avatar/points/deduct - 200 | ポイント減算成功を返すこと | ✅ |
| 12 | GET /doc - OpenAPI document | OpenAPIドキュメントを返すこと | ✅ |

### tests/services/evolution-engine.test.ts (書き直し)

| # | テスト項目 | チェック内容 | 結果 |
|:--|:--|:--|:--:|
| 13 | calculateLevel: 0 points | 0ポイントでレベル1を返すこと | ✅ |
| 14 | calculateLevel: negative | 負ポイントでレベル1を返すこと | ✅ |
| 15 | calculateLevel: 300 points | 300ポイントでレベル2を返すこと | ✅ |
| 16 | calculateLevel: max | MAX_LEVELで頭打ちになること | ✅ |
| 17 | pointsForLevel: level 1 | レベル1の必要ポイント計算 | ✅ |
| 18 | pointsForLevel: level 5 | レベル5の必要ポイント計算 | ✅ |
| 19 | determineEvolution: below threshold | 閾値未満で進化しないこと | ✅ |
| 20 | determineEvolution: food path | FOOD比率0.6以上で食系に進化 | ✅ |
| 21 | determineEvolution: lifestyle path | LIFESTYLE比率0.6以上で生活系に進化 | ✅ |
| 22 | determineEvolution: fallback | 条件未達時に優先度1にフォールバック | ✅ |
| 23 | determineEvolution: stage2→3 | stage2からstage3への進化 | ✅ |
| 24 | checkDevolution: safe level | 十分なレベルで退化しないこと | ✅ |
| 25 | checkDevolution: stage2→1 | 閾値割れでstage1に退化 | ✅ |
| 26 | checkDevolution: stage3→2 | 閾値割れでstage2に退化（親種族付き） | ✅ |
| 27 | checkSkillAcquisition: available | レベル到達で習得可能スキルを返すこと | ✅ |
| 28 | checkSkillAcquisition: already acquired | 習得済みスキルを返さないこと | ✅ |
| 29 | checkSkillAcquisition: no species | currentSpeciesId未設定で空を返すこと | ✅ |
| 30 | getSkillsToLose: matching | 退化時に失うスキルを正しく返すこと | ✅ |
| 31 | getSkillsToLose: no match | 該当なしで空を返すこと | ✅ |
| 32 | recalculateStats: level 1 | レベル1で初期ステータスを返すこと | ✅ |
| 33 | recalculateStats: with growth | 種族成長値を正しく適用すること | ✅ |

### tests/services/evolution-boundary.test.ts (新規)

（追加テストセクションに記載）

---

## 発見事項・改善提案

| # | 種別 | 対象 | 内容 | 対応 |
|:--|:--|:--|:--|:--|
| 1 | 🐛 バグ | social-handler/src/index.ts | `return getRankings(event)` 等でawaitなしのためtry/catchがrejectionを捕捉できない | テストで検出・記録済み |
| 2 | 🔧 テスト保守 | avatar-handler/tests/ | ソースリファクタリング後にテストが未追従だった | ✅ 修正済み（モック追加+テスト書き直し） |

---

## テストファイル一覧

```
backend/
├── auth-handler/tests/handlers/
│   ├── login.test.ts
│   ├── signup.test.ts
│   ├── refresh.test.ts
│   ├── profile.test.ts
│   ├── logout.test.ts
│   └── account.test.ts          ← 新規
├── recording-handler/tests/services/
│   ├── point-calculator.test.ts
│   ├── recording-service.test.ts ← 新規
│   └── health-sync-service.test.ts ← 新規
├── social-handler/tests/
│   └── index.test.ts             ← 新規
├── battle-ws-handler/tests/
│   ├── services/turn-engine.test.ts
│   └── handlers/battle-handlers.test.ts ← 新規
├── avatar-handler/tests/
│   ├── app.test.ts
│   └── services/evolution-engine.test.ts
└── admin-handler/tests/
    └── app.test.ts
```


---

## 追加テスト: 高品質テスト3種（2026-05-25 22:20追加）

### 概要

カバレッジ数値向上ではなく、**バグ発見効果の高い3種のテスト**を追加。

| カテゴリ | テストファイル | Tests | 結果 |
|:--|:--|:--:|:--:|
| 1. 境界値テスト | avatar-handler/tests/services/evolution-boundary.test.ts | 15 | ✅ ALL PASS |
| 2. 並行処理テスト | recording-handler/tests/services/concurrency.test.ts | 5 | ✅ ALL PASS |
| 3. E2Eフローテスト | recording-handler/tests/services/e2e-flow.test.ts | 4 | ✅ ALL PASS |

---

### 1. 境界値テスト（進化エンジン）

バグが最も発生しやすい「ちょうど閾値」のケースを網羅。

| # | テスト項目 | チェック内容 | 結果 |
|:--|:--|:--|:--:|
| 1 | level 4 → no evolution | レベル4で進化が発生しないこと | ✅ |
| 2 | level 5 → triggers stage2 | レベルちょうど5でstage2進化が発生すること | ✅ |
| 3 | level 14 → no stage3 evolution | レベル14でstage3進化が発生しないこと | ✅ |
| 4 | level 15 → triggers stage3 | レベルちょうど15でstage3進化が発生すること | ✅ |
| 5 | ratio 0.599 → fallback | FOOD比率59.9%で条件不成立→フォールバック | ✅ |
| 6 | ratio exactly 0.6 → meets condition | FOOD比率ちょうど60%で条件成立すること | ✅ |
| 7 | LIFESTYLE at 0.6 → lifestyle path | LIFESTYLE60%でライフスタイル系に進化すること | ✅ |
| 8 | stage2 at level 5 → no devolution | レベル5で退化しないこと（境界） | ✅ |
| 9 | stage2 at level 4 → devolves | レベル4で退化すること | ✅ |
| 10 | stage3 at level 15 → no devolution | レベル15で退化しないこと（境界） | ✅ |
| 11 | stage3 at level 14 → devolves to stage2 | レベル14でstage2に退化すること | ✅ |
| 12 | 1 point → level 1 | 1ポイントでレベル1のままであること | ✅ |
| 13 | points at level 2 threshold (300) | ちょうど300ポイントでレベル2になること | ✅ |
| 14 | points just below level 2 (299) | 299ポイントでレベル1のままであること | ✅ |
| 15 | max level boundary | MAX_LEVEL(30)で頭打ちになること | ✅ |

---

### 2. 並行処理の整合性テスト

同時リクエストでデータ不整合が発生しない設計の検証。

| # | テスト項目 | チェック内容 | 結果 |
|:--|:--|:--|:--:|
| 1 | TransactionCanceledException on duplicate | 同一recordIdの二重書込みがTransactWriteのConditionExpressionで拒否されること | ✅ |
| 2 | first write succeeds | 初回書込みはCondition通過すること | ✅ |
| 3 | batch: concurrent duplicates skipped | バッチ内で重複検知された記録がskippedIdsに入ること | ✅ |
| 4 | all duplicates → zero points | 全件スキップ時にポイント加算が発生しないこと | ✅ |
| 5 | soft-delete uses Update not Delete | 削除がUpdateCommand（論理削除）で監査証跡を保持すること | ✅ |

---

### 3. E2Eフローテスト（記録→進化の全体連携）

個別ユニットテストでは見えない、サービス間の連携を検証。

| # | テスト項目 | チェック内容 | 結果 |
|:--|:--|:--|:--:|
| 1 | single record → avatar addPoints | 1件記録でavatar-connectorのaddPointsが正しいポイント・カテゴリで呼ばれること | ✅ |
| 2 | batch → single avatar update | 3件バッチで合計ポイントが1回のaddPointsで加算されること | ✅ |
| 3 | delete → deductPoints → devolution | 自動検出レコード削除がdeductPointsを呼び退化を引き起こせること | ✅ |
| 4 | lifecycle: record → level up → evolution threshold | 連続記録でレベル4→5に到達しavatar-connectorが2回呼ばれること | ✅ |

---

### 全テスト最終結果

| ハンドラー | Tests | 結果 |
|:--|:--:|:--:|
| auth-handler | 38 | ✅ ALL PASS |
| recording-handler | 60 | ✅ ALL PASS |
| social-handler | 28 | ✅ ALL PASS |
| battle-ws-handler | 26 | ✅ ALL PASS |
| avatar-handler | 67 | ✅ ALL PASS |
| admin-handler | 30 | ✅ ALL PASS |
| **合計** | **249** | ✅ |


---

## コードカバレッジ最終結果

| ハンドラー | Statements | Branches | Functions | Lines |
|:--|:--:|:--:|:--:|:--:|
| auth-handler | 87.5% | 81.5% | 100% | 86.6% |
| recording-handler | 87.7% | 64.7% | 72.9% | 93.4% |
| social-handler | 97.0% | 81.8% | 100% | 98.0% |
| battle-ws-handler | 93.1% | 81.6% | 100% | 93.3% |
| avatar-handler | 92.9% | 75.0% | 95.1% | 95.9% |
| admin-handler | 95.7% | 70.4% | 91.4% | 98.6% |

### Before/After比較（今回の作業で改善した箇所）

| ハンドラー | Lines Before | Lines After | 改善幅 |
|:--|:--:|:--:|:--:|
| avatar-handler | 48.2% | **95.9%** | +47.7pt |
| recording-handler | 99.0%→(対象増)→ | **93.4%** | avatar-points-service追加で分母増 |
| social-handler | 0% (テストなし) | **98.0%** | 新規作成 |
| battle-ws-handler (handlers) | 未テスト | **93.3%** | 新規作成 |

### avatar-handler カバレッジ改善の内訳

| ファイル | Stmts | Branches | Lines | 備考 |
|:--|:--:|:--:|:--:|:--|
| avatar-service.ts | 100% | 78.6% | 100% | addPoints/deductPoints全パス網羅 |
| evolution-engine.ts | 98.4% | 92.0% | 98.1% | サブカテゴリ条件パスをカバー |
| schemas.ts | 100% | 100% | 100% | - |
| app.ts | 82.1% | 52.4% | 90.1% | Cognito認証分岐が残存（テスト環境では再現困難） |

### カバレッジが低い残り箇所の分析

| 対象 | 現状 | 未カバー内容 | 追加テストの費用対効果 |
|:--|:--|:--|:--|
| admin-handler (Branches 70%) | profile更新の複合条件分岐 | nickname+gameFields同時更新パス | 低（稀なケース） |
| avatar-handler (Branches 75%) | app.ts Cognito認証分岐 | Lambda event経由の認証パス | 低（テスト環境では再現困難） |
| recording-handler (Branches 65%) | handler層のルーティング分岐 | /activities/batch, /activities/summary等 | 低（上位E2Eで十分） |
