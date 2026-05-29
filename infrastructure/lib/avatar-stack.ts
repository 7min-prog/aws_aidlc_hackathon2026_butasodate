import * as cdk from 'aws-cdk-lib';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as lambdaNodejs from 'aws-cdk-lib/aws-lambda-nodejs';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as path from 'path';
import { Construct } from 'constructs';

interface AvatarStackProps extends cdk.StackProps {
  userPoolId: string;
}

export class AvatarStack extends cdk.Stack {
  public readonly assetsBucketName: string;

  constructor(scope: Construct, id: string, props: AvatarStackProps) {
    super(scope, id, props);

    const userPool = cognito.UserPool.fromUserPoolId(this, 'ImportedUserPool', props.userPoolId);

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

    // ER図準拠: PigSpecies (旧 evolution-paths)
    const pigSpeciesTable = new dynamodb.Table(this, 'PigSpeciesTable', {
      tableName: 'butasodate-pig-species',
      partitionKey: { name: 'speciesId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    pigSpeciesTable.addGlobalSecondaryIndex({
      indexName: 'stage-index',
      partitionKey: { name: 'stage', type: dynamodb.AttributeType.NUMBER },
    });

    // ER図準拠: EvolutionRoute (新規)
    const evolutionRouteTable = new dynamodb.Table(this, 'EvolutionRouteTable', {
      tableName: 'butasodate-evolution-routes',
      partitionKey: { name: 'routeId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    evolutionRouteTable.addGlobalSecondaryIndex({
      indexName: 'fromSpecies-index',
      partitionKey: { name: 'fromSpeciesId', type: dynamodb.AttributeType.STRING },
    });

    const skillTable = new dynamodb.Table(this, 'SkillTable', {
      tableName: 'butasodate-skills',
      partitionKey: { name: 'skillId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    skillTable.addGlobalSecondaryIndex({
      indexName: 'speciesId-index',
      partitionKey: { name: 'speciesId', type: dynamodb.AttributeType.STRING },
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

    this.assetsBucketName = assetsBucket.bucketName;

    // Lambda Function (esbuild bundled)
    const avatarHandler = new lambdaNodejs.NodejsFunction(this, 'AvatarHandler', {
      functionName: 'buta-avatar-handler-dev',
      runtime: lambda.Runtime.NODEJS_22_X,
      architecture: lambda.Architecture.ARM_64,
      entry: path.join(__dirname, '../../backend/avatar-handler/src/app.ts'),
      handler: 'handler',
      projectRoot: path.join(__dirname, '../../'),
      bundling: {
        minify: true,
        sourceMap: false,
        target: 'node22',
        format: lambdaNodejs.OutputFormat.CJS,
        externalModules: ['@aws-sdk/*'],
        forceDockerBundling: false,
      },
      memorySize: 256,
      timeout: cdk.Duration.seconds(10),
      environment: {
        AVATAR_TABLE_NAME: avatarTable.tableName,
        EVOLUTION_HISTORY_TABLE_NAME: evolutionHistoryTable.tableName,
        PIG_SPECIES_TABLE_NAME: pigSpeciesTable.tableName,
        EVOLUTION_ROUTE_TABLE_NAME: evolutionRouteTable.tableName,
        SKILL_TABLE_NAME: skillTable.tableName,
        GAME_CONFIG_TABLE_NAME: 'butasodate-game-config',
        ASSETS_BUCKET_NAME: assetsBucket.bucketName,
      },
    });

    // Grant permissions
    avatarTable.grantReadWriteData(avatarHandler);
    evolutionHistoryTable.grantReadWriteData(avatarHandler);
    pigSpeciesTable.grantReadData(avatarHandler);
    evolutionRouteTable.grantReadData(avatarHandler);
    skillTable.grantReadData(avatarHandler);

    // GameConfig read access
    avatarHandler.addToRolePolicy(new cdk.aws_iam.PolicyStatement({
      actions: ['dynamodb:GetItem', 'dynamodb:Scan'],
      resources: [`arn:aws:dynamodb:${this.region}:${this.account}:table/butasodate-game-config`],
    }));

    // API Gateway with Cognito auth
    const api = new apigateway.RestApi(this, 'AvatarApi', {
      restApiName: 'buta-avatar-api-dev',
      deployOptions: { stageName: 'dev' },
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: ['Content-Type', 'Authorization'],
      },
    });

    const authorizer = new apigateway.CognitoUserPoolsAuthorizer(this, 'AvatarAuthorizer', {
      cognitoUserPools: [userPool as cognito.IUserPool],
    });

    // Gateway Responses: 4XX/5XXにCORSヘッダーを付与（Authorizer 401対策）
    api.addGatewayResponse('Default4xx', {
      type: apigateway.ResponseType.DEFAULT_4XX,
      responseHeaders: {
        'Access-Control-Allow-Origin': "'*'",
        'Access-Control-Allow-Headers': "'Content-Type,Authorization'",
      },
    });
    api.addGatewayResponse('Default5xx', {
      type: apigateway.ResponseType.DEFAULT_5XX,
      responseHeaders: {
        'Access-Control-Allow-Origin': "'*'",
        'Access-Control-Allow-Headers': "'Content-Type,Authorization'",
      },
    });

    const authMethodOptions: apigateway.MethodOptions = {
      authorizer,
      authorizationType: apigateway.AuthorizationType.COGNITO,
    };

    const lambdaIntegration = new apigateway.LambdaIntegration(avatarHandler);

    // Routes (OpenAPI準拠)
    const avatar = api.root.addResource('avatar');
    avatar.addMethod('POST', lambdaIntegration, authMethodOptions);
    avatar.addMethod('GET', lambdaIntegration, authMethodOptions);
    avatar.addResource('evolution-history').addMethod('GET', lambdaIntegration, authMethodOptions);
    avatar.addResource('score-detail').addMethod('GET', lambdaIntegration, authMethodOptions);

    // Outputs
    new cdk.CfnOutput(this, 'AvatarApiUrl', { value: api.url });
    new cdk.CfnOutput(this, 'AssetsBucketName', { value: assetsBucket.bucketName });
  }
}
