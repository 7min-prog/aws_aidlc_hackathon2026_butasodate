# Code Generation Plan - Unit F: Flutter共通基盤

## ユニットコンテキスト
- **目的**: 全ユニットで共通利用するFlutterの基盤を構築
- **依存**: Unit 1（認証バックエンド）のAPI仕様
- **成果物**: Flutterプロジェクト、共通テーマ、APIクライアント、ルーティング、認証画面

## コード生成ステップ

### Phase A: プロジェクト構造

- [x] Step 1: Flutterプロジェクト初期化（pubspec.yaml、ディレクトリ構成）
- [x] Step 2: 共通テーマ定義（カラー、フォント、共通Widget）

### Phase B: 共通基盤

- [x] Step 3: APIクライアント（HTTP通信 + トークン自動付与）
- [x] Step 4: 認証状態管理（Riverpod + SharedPreferences）
- [x] Step 5: ルーティング（GoRouter、認証ガード）

### Phase C: 認証画面（Unit 1フロント）

- [x] Step 6: ログイン画面
- [x] Step 7: サインアップ画面 + 確認コード画面
- [x] Step 8: ニックネーム設定画面

## 質問

### Q1: 状態管理
FlutterのState管理はどれを使いますか？

A) Riverpod（推奨、モダン）
B) Provider（シンプル）
C) おまかせ

[Answer]:A
