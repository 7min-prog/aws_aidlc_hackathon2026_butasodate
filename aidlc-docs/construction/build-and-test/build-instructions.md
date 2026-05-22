# Build Instructions

## Prerequisites
- **Node.js**: 20.x 以上
- **npm**: 10.x 以上
- **AWS CLI**: 設定済み（`aws configure`）
- **AWS CDK CLI**: `npm install -g aws-cdk@2.240.0`

## Build Steps

### 1. Install Dependencies

```bash
# Lambda関数の依存関係
cd backend/auth-handler
npm install

# CDKの依存関係
cd ../../infrastructure
npm install
```

### 2. Build Lambda Function

```bash
cd backend/auth-handler
npm run build
```

成功すると `dist/` ディレクトリにコンパイル済みJSが生成される。

### 3. Build CDK

```bash
cd infrastructure
npm run build
```

### 4. CDK Synth（テンプレート生成確認）

```bash
cd infrastructure
npx cdk synth
```

CloudFormationテンプレートが `cdk.out/` に生成されれば成功。

### 5. Deploy（AWSアカウント必要）

```bash
# 初回のみ
cd infrastructure
npx cdk bootstrap

# デプロイ
npx cdk deploy ButaAuthStack
```

## Verify Build Success
- `backend/auth-handler/dist/` にJSファイルが生成されている
- `infrastructure/cdk.out/` にCloudFormationテンプレートが生成されている
- `cdk synth` がエラーなく完了する

## Troubleshooting

### `Cannot find module` エラー
- **原因**: `npm install` が未実行
- **解決**: 各ディレクトリで `npm install` を実行

### CDK `--app` エラー
- **原因**: `infrastructure/` ディレクトリ外で `cdk` コマンドを実行
- **解決**: `cd infrastructure` してから実行

### TypeScript コンパイルエラー
- **原因**: Node.js バージョンが古い
- **解決**: Node.js 20.x 以上にアップデート
