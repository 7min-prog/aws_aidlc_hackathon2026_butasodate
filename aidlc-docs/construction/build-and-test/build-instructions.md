# Build Instructions

## Prerequisites

- **Node.js**: 20.x 以上
- **npm**: 10.x 以上
- **Flutter**: 3.44.0
- **AWS CLI**: 設定済み（`aws configure`）
- **AWS CDK CLI**: `npm install -g aws-cdk`

## Build Steps

### 1. Backend (Lambda Handlers)

```bash
# 全ハンドラーの依存関係インストール
for dir in auth-handler recording-handler avatar-handler battle-ws-handler social-handler admin-handler; do
  cd backend/$dir && npm install && cd ../..
done
```

各ハンドラーは CDK の `NodejsFunction` により自動バンドルされるため、個別ビルドは不要。

### 2. Infrastructure (CDK)

```bash
cd infrastructure
npm install
npx cdk synth
```

成功すると `cdk.out/` に5つのCloudFormationテンプレートが生成される：
- `ButaAuthStack.template.json`
- `ButaRecordingStack.template.json`
- `ButaAvatarStack.template.json`
- `ButaBattleSocialStack.template.json`
- `ButaAdminStack.template.json`

### 3. Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter build web -t lib/main_dev.dart
```

### 4. Admin Panel (React)

```bash
cd admin
npm install
npm run build
```

### 5. Mock Server (開発用)

```bash
cd mock-server
npm install
npm run dev
```

## Deploy

```bash
cd infrastructure
npx cdk bootstrap  # 初回のみ
npx cdk deploy --all
```

## Verify Build Success

| コンポーネント | 確認方法 |
|--------------|---------|
| Backend | `cd backend/auth-handler && npm test` がパス |
| CDK | `infrastructure/cdk.out/` にテンプレート生成 |
| Frontend | `frontend/build/web/index.html` が存在 |
| Admin | `admin/dist/index.html` が存在 |
