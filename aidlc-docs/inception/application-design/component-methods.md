# Component Methods

## BE-API: REST API Lambda

### Recording Domain
| メソッド | 入力 | 出力 | 概要 |
|---------|------|------|------|
| createRecord | { userId, categoryId, memo?, recordedAt } | { recordId, points } | 不健康行動を記録しポイント加算 |
| getRecords | { userId, dateFrom?, dateTo?, category? } | { records[] } | 記録履歴取得（フィルタ対応） |
| deleteRecord | { userId, recordId } | { success, pointsDeducted } | 記録削除とポイント減算 |
| getSummary | { userId } | { today: {count, points}, week: {byCategory[]} } | 今日・今週のサマリー |

### Avatar Domain
| メソッド | 入力 | 出力 | 概要 |
|---------|------|------|------|
| createAvatar | { userId } | { avatar } | 初期アバター生成 |
| getAvatar | { userId } | { avatar, stats, skills[] } | アバター情報取得 |
| addPoints | { userId, points, category } | { avatar, leveledUp?, evolved?, devolved? } | ポイント加算・レベル/進化判定 |
| deductPoints | { userId, points, category } | { avatar, leveledDown?, devolved? } | ポイント減算・退化判定 |
| getEvolutionHistory | { userId } | { history[] } | 進化履歴取得 |

### Health Sync Domain
| メソッド | 入力 | 出力 | 概要 |
|---------|------|------|------|
| syncHealthData | { userId, data: {weight?, steps?, sleep?} } | { detectedActions[], pointChanges } | ヘルスデータ同期・行動検出 |
| getHealthSettings | { userId } | { settings } | ヘルス連携設定取得 |
| updateHealthSettings | { userId, settings } | { success } | 基準値・カテゴリON/OFF更新 |

### Social Domain
| メソッド | 入力 | 出力 | 概要 |
|---------|------|------|------|
| searchUsers | { query } | { users[] } | ニックネーム検索 |
| sendFriendRequest | { userId, targetUserId } | { success } | フレンド申請送信 |
| respondFriendRequest | { userId, requestId, accept } | { success } | 申請承認/拒否 |
| getFriends | { userId } | { friends[] } | フレンド一覧（オンライン状態付き） |
| removeFriend | { userId, friendId } | { success } | フレンド削除 |
| getPendingRequests | { userId } | { requests[] } | 未処理申請一覧 |

### Admin Domain
| メソッド | 入力 | 出力 | 概要 |
|---------|------|------|------|
| listUsers | { page, pageSize, filter? } | { users[], total } | ユーザー一覧 |
| getUser | { userId } | { user, gameData } | ユーザー詳細 |
| updateUser | { userId, data } | { success } | プロフィール編集 |
| suspendUser | { userId } | { success } | アカウント停止 |
| restoreUser | { userId } | { success } | アカウント復活 |
| deleteUser | { userId } | { success } | 論理削除 |
| updateGameData | { userId, gameData } | { success } | ゲームデータ修正 |
| listMasterData | { type } | { items[] } | マスターデータ一覧 |
| updateMasterData | { type, id, data } | { success } | マスターデータ更新 |

---

## BE-WEBSOCKET: WebSocket Lambda

| メソッド | 入力 | 出力 | 概要 |
|---------|------|------|------|
| onConnect | { connectionId, userId } | - | WebSocket接続確立 |
| onDisconnect | { connectionId } | - | 切断処理（バトル中なら自動敗北） |
| requestMatch | { userId, type: random/friend, targetId? } | { matchId? / waiting } | マッチメイキング申請 |
| cancelMatch | { userId } | { success } | マッチング中止 |
| respondInvite | { userId, matchId, accept } | { success } | フレンド対戦招待応答 |
| setReady | { userId, matchId, skills[], items[] } | - | バトル準備完了 |
| selectAction | { userId, matchId, action } | - | ターン行動選択 |
| executeTurn | { matchId } | { turnResult } | ターン実行（両者選択完了時） |

---

## フロントエンド（Flutter）共通

### FE-SHARED: API Client
| メソッド | 概要 |
|---------|------|
| get(path, params?) | REST GET リクエスト |
| post(path, body) | REST POST リクエスト |
| put(path, body) | REST PUT リクエスト |
| delete(path) | REST DELETE リクエスト |
| connectWebSocket(matchId) | WebSocket接続開始 |
| sendWsMessage(type, data) | WebSocket メッセージ送信 |
| onWsMessage(handler) | WebSocket メッセージ受信ハンドラ |

注: 各Feature内のRepositoryがAPI Clientを使用してバックエンドと通信する。詳細なビジネスロジックはFunctional Designで定義。
