# Unit 5: 管理画面 (FR-7) — NFR Design

## 設計パターン

### 認証
| 項目 | 設計 |
|---|---|
| 方式 | Basic認証（ID/PW環境変数管理） |
| セッション | JWTトークン発行（有効期限8時間） |
| フロント保持 | localStorage |

### データ保護
| 項目 | 設計 |
|---|---|
| 削除方式 | 論理削除（deletedAtフラグ） |
| 確認UI | 破壊的操作前に確認ダイアログ表示 |
| 操作ログ | 全操作をDynamoDB操作ログテーブルに記録 |

### アーキテクチャ
| 項目 | 設計 |
|---|---|
| フロントエンド | React + Vite + MUI、S3 + CloudFront で静的ホスティング |
| バックエンド | Hono + Lambda（単一Lambda） |
| API Gateway | REST API Gateway経由でLambdaにルーティング |
| 通信フロー | ブラウザ → API Gateway → Lambda(Hono) → DynamoDB / Cognito |
| API通信 | REST（OpenAPI準拠） |
| 状態管理 | Zustand（グローバル状態）+ useState（ローカル状態） |

### パフォーマンス
| 項目 | 設計 |
|---|---|
| ページネーション | サーバーサイド（20件/ページ） |
| キャッシュ | React Queryのデフォルトキャッシュ（5分） |
| バンドル | Viteによるコード分割 |

---

## 承認

この設計パターンで進めてよいですか？

- [×] 承認する
- [ ] 修正が必要（下記にコメント記入）

コメント:

---
