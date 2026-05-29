# Penpot MCP Server

Penpot の REST API を使ってデザインの読み書きを行う MCP サーバー。  
Kiro 起動時に自動で立ち上がるため、手動起動は不要。

## セットアップ

1. 依存関係をインストール:
   ```
   cd penpot-mcp-server
   npm install
   ```

2. プロジェクトルートの `.env` に自分の Penpot アクセストークンを設定:
   ```
   PENPOT_ACCESS_TOKEN=your-token-here
   ```

3. Kiro を再起動すれば自動的に接続される

## アクセストークンの発行方法

1. https://design.penpot.app にログイン
2. 左下アイコン → **Your account** → **Access tokens**
3. 「Generate new token」→ 名前をつけて作成
4. 表示されたトークンをコピーして `.env` に貼り付け

## 利用可能なツール

| ツール | 説明 |
|--------|------|
| `get_profile` | ユーザー情報を取得 |
| `list_projects` | プロジェクト一覧 |
| `get_project_files` | プロジェクト内のファイル一覧 |
| `get_file_summary` | ファイルのページ・コンポーネント一覧 |
| `get_page_shapes` | ページ内の全シェイプ一覧 |
| `create_page` | 新規ページ作成 |
| `create_frame` | フレーム（アートボード）作成 |
| `create_rect` | 矩形作成 |
| `create_text` | テキスト作成 |
| `create_circle` | 円/楕円作成 |
| `delete_shape` | シェイプ削除 |

## 注意事項

- `.env` は `.gitignore` に含まれているためコミットされない
- トークンは個人ごとに発行すること（共有しない）
- ブラウザで Penpot を開く必要はない（REST API 直接通信）
