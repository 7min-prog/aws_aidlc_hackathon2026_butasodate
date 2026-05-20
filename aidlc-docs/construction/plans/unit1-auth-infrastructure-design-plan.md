# Infrastructure Design Plan - Unit 1: 認証基盤

## 対象
- Unit 1: 認証基盤（FR-1: ユーザー認証）
- NFR Design成果物を基にAWSインフラ構成を具体化

## 計画ステップ

- [x] 1. AWSリソース構成設計（Cognito, API Gateway, Lambda, DynamoDB）
- [x] 2. デプロイアーキテクチャ設計（CDKスタック構成、環境分離）
- [x] 3. モニタリング・ログ設計
- [x] 4. Infrastructure Designドキュメント生成

## 質問

### Q1: IaCツール
インフラのコード管理はAWS CDK (TypeScript) で良いですか？

A) AWS CDK (TypeScript)
B) AWS SAM
C) Terraform

[Answer]:A

### Q2: 環境構成
デプロイ環境はどうしますか？

A) 1環境のみ（dev兼本番、ハッカソン向け最小構成）
B) dev / prod の2環境

[Answer]:A

### Q3: モニタリング
ログ・モニタリングはどの程度必要ですか？

A) CloudWatch Logsのみ（Lambda標準出力、追加設定なし）
B) CloudWatch Logs + アラーム（エラー率監視）

[Answer]:A
