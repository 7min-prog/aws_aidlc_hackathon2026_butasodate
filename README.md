# ECサイト（シンプル）

デジタル商品を販売するシンプルなECサイトです。

## 機能

- 商品一覧・詳細表示
- ショッピングカート（ローカルストレージ）
- 注文確定（決済なし・注文記録のみ）
- 管理者ダッシュボード（商品CRUD・注文一覧）

## 技術スタック

| 項目 | 技術 |
|---|---|
| フロントエンド | React + TypeScript + Tailwind CSS + React Router v6 |
| バックエンド | Node.js + Express + TypeScript |
| ORM | Prisma |
| データベース | PostgreSQL |

## 前提条件

- Node.js 20.x LTS
- PostgreSQL 15.x

## セットアップ

### 1. データベース作成

```bash
psql -U postgres -c "CREATE DATABASE ec_site;"
```

### 2. バックエンド

```bash
cd backend
npm install
cp .env.example .env
# .env の DATABASE_URL を編集
npx prisma generate
npx prisma migrate dev --name init
npm run db:seed
```

### 3. フロントエンド

```bash
cd frontend
npm install
```

## 起動

```bash
# バックエンド（ターミナル1）
cd backend && npm run dev
# → http://localhost:3001

# フロントエンド（ターミナル2）
cd frontend && npm start
# → http://localhost:3000
```

## テスト

```bash
# フロントエンド
cd frontend && npm run test:ci

# バックエンド
cd backend && npm run test:ci
```

## 画面一覧

| URL | 説明 |
|---|---|
| `/` | 商品一覧 |
| `/products/:id` | 商品詳細 |
| `/cart` | カート |
| `/order-complete` | 注文完了 |
| `/admin` | 管理者: 商品管理 |
| `/admin/orders` | 管理者: 注文一覧 |
