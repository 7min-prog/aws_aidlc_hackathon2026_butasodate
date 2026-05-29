import * as cdk from 'aws-cdk-lib';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as path from 'path';
import { Construct } from 'constructs';

interface AdminStackProps extends cdk.StackProps {
  userPoolId: string;
  assetsBucketName: string;
}

export class AdminStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: AdminStackProps) {
    super(scope, id, props);

    // 新規DynamoDBテーブル: 操作ログ
    const auditLogTable = new dynamodb.Table(this, 'AuditLogTable', {
      tableName: 'butasodate-admin-audit-log',
      partitionKey: { name: 'logId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'timestamp', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // 新規DynamoDBテーブル: ゲーム設定
    const gameConfigTable = new dynamodb.Table(this, 'GameConfigTable', {
      tableName: 'butasodate-game-config',
      partitionKey: { name: 'configKey', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Lambda関数
    const adminHandler = new lambda.Function(this, 'AdminHandler', {
      functionName: 'buta-admin-handler-dev',
      runtime: lambda.Runtime.NODEJS_20_X,
      architecture: lambda.Architecture.ARM_64,
      handler: 'dist/app.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../../backend/admin-handler'), {
        exclude: ['src/**', 'tests/**', 'tsconfig.json', '*.md'],
      }),
      memorySize: 256,
      timeout: cdk.Duration.seconds(10),
      environment: {
        ADMIN_USER: process.env.ADMIN_USER || 'admin',
        ADMIN_PASSWORD: process.env.ADMIN_PASSWORD || 'butasodate2026',
        JWT_SECRET: process.env.JWT_SECRET || 'admin-jwt-secret',
        USER_POOL_ID: props.userPoolId,
        AVATAR_TABLE_NAME: 'butasodate-avatars',
        PIG_SPECIES_TABLE_NAME: 'butasodate-pig-species',
        EVOLUTION_ROUTE_TABLE_NAME: 'butasodate-evolution-routes',
        SKILL_TABLE_NAME: 'butasodate-skills',
        AUDIT_LOG_TABLE_NAME: auditLogTable.tableName,
        GAME_CONFIG_TABLE_NAME: gameConfigTable.tableName,
        USER_PROFILES_TABLE_NAME: 'butasodate-user-profiles',
        ACTIVITY_RECORD_TABLE_NAME: 'butasodate-activity-records',
        ASSETS_BUCKET_NAME: props.assetsBucketName,
      },
    });

    // 新規テーブルへの権限
    auditLogTable.grantReadWriteData(adminHandler);
    gameConfigTable.grantReadWriteData(adminHandler);

    // 既存テーブルへの権限（テーブル名で参照）
    const existingTables = ['butasodate-avatars', 'butasodate-pig-species', 'butasodate-evolution-routes', 'butasodate-skills', 'butasodate-activity-records', 'butasodate-user-profiles'];
    adminHandler.addToRolePolicy(new iam.PolicyStatement({
      actions: ['dynamodb:GetItem', 'dynamodb:PutItem', 'dynamodb:UpdateItem', 'dynamodb:DeleteItem', 'dynamodb:Scan', 'dynamodb:Query'],
      resources: existingTables.flatMap(t => [
        `arn:aws:dynamodb:${this.region}:${this.account}:table/${t}`,
        `arn:aws:dynamodb:${this.region}:${this.account}:table/${t}/index/*`,
      ]),
    }));

    // Cognito権限
    adminHandler.addToRolePolicy(new iam.PolicyStatement({
      actions: ['cognito-idp:ListUsers', 'cognito-idp:AdminGetUser', 'cognito-idp:AdminDisableUser', 'cognito-idp:AdminEnableUser', 'cognito-idp:AdminDeleteUser'],
      resources: [`arn:aws:cognito-idp:${this.region}:${this.account}:userpool/${props.userPoolId}`],
    }));

    // S3アセットバケットへの権限
    adminHandler.addToRolePolicy(new iam.PolicyStatement({
      actions: ['s3:PutObject'],
      resources: [`arn:aws:s3:::${props.assetsBucketName}/*`],
    }));

    // API Gateway
    const api = new apigateway.RestApi(this, 'AdminApi', {
      restApiName: 'buta-admin-api-dev',
      deployOptions: { stageName: 'dev' },
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: ['Content-Type', 'Authorization'],
      },
    });

    const lambdaIntegration = new apigateway.LambdaIntegration(adminHandler);
    api.root.addProxy({ defaultIntegration: lambdaIntegration, anyMethod: true });

    // S3バケット（管理画面SPA）
    const spaBucket = new s3.Bucket(this, 'AdminSpaBucket', {
      bucketName: `butasodate-admin-spa-${this.account}-dev`,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
    });

    // CloudFront
    const distribution = new cloudfront.Distribution(this, 'AdminDistribution', {
      defaultBehavior: { origin: origins.S3BucketOrigin.withOriginAccessControl(spaBucket) },
      defaultRootObject: 'index.html',
      errorResponses: [{ httpStatus: 403, responsePagePath: '/index.html', responseHttpStatus: 200 }],
    });

    // Outputs
    new cdk.CfnOutput(this, 'AdminApiUrl', { value: api.url });
    new cdk.CfnOutput(this, 'AdminSpaUrl', { value: `https://${distribution.distributionDomainName}` });
    new cdk.CfnOutput(this, 'AdminSpaBucketName', { value: spaBucket.bucketName });
  }
}
