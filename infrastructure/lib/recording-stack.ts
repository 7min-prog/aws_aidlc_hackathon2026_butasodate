import * as cdk from 'aws-cdk-lib';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as cr from 'aws-cdk-lib/custom-resources';
import * as path from 'path';
import { Construct } from 'constructs';

interface RecordingStackProps extends cdk.StackProps {
  userPoolId: string;
}

export class RecordingStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: RecordingStackProps) {
    super(scope, id, props);

    // Import existing Cognito User Pool
    const userPool = cognito.UserPool.fromUserPoolId(this, 'ImportedUserPool', props.userPoolId);

    // DynamoDB Tables
    const activityRecordTable = new dynamodb.Table(this, 'ActivityRecordTable', {
      tableName: 'butasodate-activity-records',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'sk', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    activityRecordTable.addGlobalSecondaryIndex({
      indexName: 'category-index',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'gsi1sk', type: dynamodb.AttributeType.STRING },
    });

    const healthSyncTable = new dynamodb.Table(this, 'HealthSyncTable', {
      tableName: 'butasodate-health-sync-records',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'sk', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    const categoryTable = new dynamodb.Table(this, 'ActivityCategoryTable', {
      tableName: 'butasodate-activity-categories',
      partitionKey: { name: 'categoryId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Lambda Functions
    const commonEnv = {
      ACTIVITY_RECORD_TABLE: activityRecordTable.tableName,
      HEALTH_SYNC_TABLE: healthSyncTable.tableName,
      ACTIVITY_CATEGORY_TABLE: categoryTable.tableName,
      AVATAR_FUNCTION_NAME: 'buta-avatar-handler-dev',
    };

    const recordingFn = new lambda.Function(this, 'RecordingFunction', {
      functionName: 'buta-recording-handler',
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'handlers/recording.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../../backend/recording-handler/dist')),
      memorySize: 256,
      timeout: cdk.Duration.seconds(10),
      environment: commonEnv,
    });

    const categoriesFn = new lambda.Function(this, 'CategoriesFunction', {
      functionName: 'buta-categories-handler',
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'handlers/categories.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../../backend/recording-handler/dist')),
      memorySize: 128,
      timeout: cdk.Duration.seconds(5),
      environment: commonEnv,
    });

    // Grant DynamoDB permissions
    activityRecordTable.grantReadWriteData(recordingFn);
    healthSyncTable.grantReadWriteData(recordingFn);
    categoryTable.grantReadData(recordingFn);
    categoryTable.grantReadData(categoriesFn);

    // Grant Lambda invoke permission for avatar-handler
    recordingFn.addToRolePolicy(new cdk.aws_iam.PolicyStatement({
      actions: ['lambda:InvokeFunction'],
      resources: [`arn:aws:lambda:${this.region}:${this.account}:function:buta-avatar-handler-dev`],
    }));

    // API Gateway
    const api = new apigateway.RestApi(this, 'ButaRecordingApi', {
      restApiName: 'buta-recording-api-dev',
      deployOptions: { stageName: 'dev' },
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: ['Content-Type', 'Authorization'],
      },
    });

    const authorizer = new apigateway.CognitoUserPoolsAuthorizer(this, 'RecordingAuthorizer', {
      cognitoUserPools: [userPool as cognito.IUserPool],
    });

    // API Gateway routes
    const authMethodOptions: apigateway.MethodOptions = {
      authorizer,
      authorizationType: apigateway.AuthorizationType.COGNITO,
    };

    const activities = api.root.addResource('activities');
    activities.addMethod('POST', new apigateway.LambdaIntegration(recordingFn), authMethodOptions);
    activities.addMethod('GET', new apigateway.LambdaIntegration(recordingFn), authMethodOptions);

    const activitiesBatch = activities.addResource('batch');
    activitiesBatch.addMethod('POST', new apigateway.LambdaIntegration(recordingFn), authMethodOptions);

    const activitiesSummary = activities.addResource('summary');
    activitiesSummary.addMethod('GET', new apigateway.LambdaIntegration(recordingFn), authMethodOptions);

    const activityById = activities.addResource('{recordId}');
    activityById.addMethod('DELETE', new apigateway.LambdaIntegration(recordingFn), authMethodOptions);

    const categories = api.root.addResource('categories');
    categories.addMethod('GET', new apigateway.LambdaIntegration(categoriesFn), authMethodOptions);

    const categoriesVersion = categories.addResource('version');
    categoriesVersion.addMethod('GET', new apigateway.LambdaIntegration(categoriesFn), authMethodOptions);

    // Output
    new cdk.CfnOutput(this, 'RecordingApiUrl', { value: api.url });

    // Seed default categories via Custom Resource
    const seedData = [
      { categoryId: 'food_late_ramen', name: '深夜ラーメン', type: 'FOOD', basePoints: 12, iconKey: 'ramen', sortOrder: 1, isActive: true, version: 1 },
      { categoryId: 'food_binge', name: '暴飲暴食', type: 'FOOD', basePoints: 12, iconKey: 'binge', sortOrder: 2, isActive: true, version: 1 },
      { categoryId: 'food_snack', name: '間食', type: 'FOOD', basePoints: 12, iconKey: 'snack', sortOrder: 3, isActive: true, version: 1 },
      { categoryId: 'food_junkfood', name: 'ジャンクフード', type: 'FOOD', basePoints: 12, iconKey: 'junk', sortOrder: 4, isActive: true, version: 1 },
      { categoryId: 'life_stay_up', name: '夜更かし', type: 'LIFESTYLE', basePoints: 10, iconKey: 'night', sortOrder: 5, isActive: true, version: 1 },
      { categoryId: 'life_oversleep', name: '二度寝', type: 'LIFESTYLE', basePoints: 10, iconKey: 'sleep', sortOrder: 6, isActive: true, version: 1 },
      { categoryId: 'life_skip_exercise', name: '運動サボり', type: 'LIFESTYLE', basePoints: 10, iconKey: 'couch', sortOrder: 7, isActive: true, version: 1 },
      { categoryId: 'life_binge_watch', name: 'だらだら動画視聴', type: 'LIFESTYLE', basePoints: 10, iconKey: 'tv', sortOrder: 8, isActive: true, version: 1 },
      { categoryId: '_meta', name: '_meta', type: 'SYSTEM', basePoints: 0, iconKey: '', sortOrder: 0, isActive: false, version: 1 },
    ];

    for (const item of seedData) {
      new cr.AwsCustomResource(this, `Seed-${item.categoryId}`, {
        onCreate: {
          service: 'DynamoDB',
          action: 'putItem',
          parameters: {
            TableName: categoryTable.tableName,
            Item: Object.fromEntries(
              Object.entries(item).map(([k, v]) => [k, typeof v === 'number' ? { N: String(v) } : typeof v === 'boolean' ? { BOOL: v } : { S: String(v) }])
            ),
            ConditionExpression: 'attribute_not_exists(categoryId)',
          },
          physicalResourceId: cr.PhysicalResourceId.of(`seed-${item.categoryId}`),
        },
        policy: cr.AwsCustomResourcePolicy.fromSdkCalls({ resources: [categoryTable.tableArn] }),
      });
    }
  }
}
