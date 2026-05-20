# Domain Entities - Unit 1: 認証基盤

## エンティティ一覧

### User（ユーザー）

| 属性 | 型 | 必須 | 説明 |
|------|-----|------|------|
| userId | String (UUID) | ✅ | 一意識別子（Cognito sub） |
| email | String | ✅ | メールアドレス |
| nickname | String | ✅ | 表示名（2〜10文字） |
| authProvider | Enum | ✅ | 認証プロバイダー（EMAIL, GOOGLE, X） |
| linkedProviders | List\<Enum\> | ✅ | リンク済みプロバイダー一覧 |
| status | Enum | ✅ | アカウント状態（ACTIVE, SUSPENDED, DELETED） |
| emailVerified | Boolean | ✅ | メール確認済みフラグ |
| createdAt | DateTime | ✅ | 作成日時 |
| updatedAt | DateTime | ✅ | 更新日時 |
| lastLoginAt | DateTime | ❌ | 最終ログイン日時 |

### AuthProvider（認証プロバイダー列挙）

| 値 | 説明 |
|----|------|
| EMAIL | メール+パスワード認証 |
| GOOGLE | Googleソーシャルログイン |
| X | X（旧Twitter）ソーシャルログイン |

### UserStatus（ユーザー状態列挙）

| 値 | 説明 |
|----|------|
| ACTIVE | 有効 |
| SUSPENDED | 停止中 |
| DELETED | 論理削除済み |

## エンティティ関係図

```text
+------------------+
|      User        |
+------------------+
| userId (PK)      |
| email            |
| nickname         |
| authProvider     |
| linkedProviders  |
| status           |
| emailVerified    |
| createdAt        |
| updatedAt        |
| lastLoginAt      |
+------------------+
        |
        | 1:1 (Cognito管理)
        v
+------------------+
| Cognito UserPool |
+------------------+
| sub = userId     |
| email            |
| password (hash)  |
| providers[]      |
| tokens           |
+------------------+
```

## 備考

- パスワードはCognitoが管理（DynamoDBには保存しない）
- トークン（アクセス/リフレッシュ）はCognitoが発行・管理
- ユーザープロフィール（nickname等）はDynamoDBに保存
- Cognito subをuserIdとして使用し、DynamoDBのパーティションキーとする
