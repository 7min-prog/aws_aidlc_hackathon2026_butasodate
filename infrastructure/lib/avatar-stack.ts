import * as cdk from 'aws-cdk-lib';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as path from 'path';
import { Construct } from 'constructs';

export class AvatarStack extends cdk.Stack {
  public readonly avatarHandler: lambda.Function;

  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // DynamoDB Tables
    const avatarTable = new dynamodb.Table(this, 'AvatarTable', {
      tableName: 'butasodate-avatars',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    const evolutionHistoryTable = new dynamodb.Table(this, 'EvolutionHistoryTable', {
      tableName: 'butasodate-evolution-history',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'occurredAt#historyId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    const evolutionPathTable = new dynamodb.Table(this, 'EvolutionPathTable', {
      tableName: 'butasodate-evolution-paths',
      partitionKey: { name: 'pathId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    const skillTable = new dynamodb.Table(this, 'SkillTable', {
      tableName: 'butasodate-skills',
      partitionKey: { name: 'skillId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    skillTable.addGlobalSecondaryIndex({
      indexName: 'path-index',
      partitionKey: { name: 'evolutionPathId', type: dynamodb.AttributeType.STRING },
    });

    // S3 Bucket for sprite assets
    const assetsBucket = new s3.Bucket(this, 'SpriteAssetsBucket', {
      bucketName: `butasodate-assets-${this.account}-dev`,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      cors: [{
        allowedMethods: [s3.HttpMethods.GET],
        allowedOrigins: ['*'],
        allowedHeaders: ['*'],
      }],
      blockPublicAccess: new s3.BlockPublicAccess({
        blockPublicAcls: false,
        ignorePublicAcls: false,
        blockPublicPolicy: false,
        restrictPublicBuckets: false,
      }),
    });

    assetsBucket.addToResourcePolicy(new cdk.aws_iam.PolicyStatement({
      actions: ['s3:GetObject'],
      resources: [assetsBucket.arnForObjects('assets/sprites/*')],
      principals: [new cdk.aws_iam.AnyPrincipal()],
    }));

    // Lambda Function
    this.avatarHandler = new lambda.Function(this, 'AvatarHandler', {
      functionName: 'buta-avatar-handler-dev',
      runtime: lambda.Runtime.NODEJS_20_X,
      architecture: lambda.Architecture.ARM_64,
      handler: 'handlers/avatar.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../../backend/avatar-handler/dist')),
      memorySize: 256,
      timeout: cdk.Duration.seconds(10),
      environment: {
        AVATAR_TABLE_NAME: avatarTable.tableName,
        EVOLUTION_HISTORY_TABLE_NAME: evolutionHistoryTable.tableName,
        EVOLUTION_PATH_TABLE_NAME: evolutionPathTable.tableName,
        SKILL_TABLE_NAME: skillTable.tableName,
        ASSETS_BUCKET_NAME: assetsBucket.bucketName,
      },
    });

    // Grant permissions
    avatarTable.grantReadWriteData(this.avatarHandler);
    evolutionHistoryTable.grantReadWriteData(this.avatarHandler);
    evolutionPathTable.grantReadData(this.avatarHandler);
    skillTable.grantReadData(this.avatarHandler);

    // API Gateway
    const api = new apigateway.RestApi(this, 'AvatarApi', {
      restApiName: 'buta-avatar-api-dev',
      deployOptions: { stageName: 'dev' },
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: ['Content-Type', 'Authorization'],
      },
    });

    const lambdaIntegration = new apigateway.LambdaIntegration(this.avatarHandler);

    // TODO: Import Cognito authorizer from auth-stack
    // For now, routes without authorizer (add after integration)
    const avatar = api.root.addResource('avatar');
    avatar.addMethod('POST', lambdaIntegration);
    avatar.addMethod('GET', lambdaIntegration);
    avatar.addResource('evolution-history').addMethod('GET', lambdaIntegration);
    avatar.addResource('score-detail').addMethod('GET', lambdaIntegration);

    // Outputs
    new cdk.CfnOutput(this, 'AvatarApiUrl', { value: api.url });
    new cdk.CfnOutput(this, 'AssetsBucketName', { value: assetsBucket.bucketName });
  }
}
