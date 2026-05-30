import * as cdk from 'aws-cdk-lib';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as path from 'path';
import { Construct } from 'constructs';

export class AuthStack extends cdk.Stack {
  public readonly userPoolId: string;

  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Cognito User Pool
    const userPool = new cognito.UserPool(this, 'ButaUserPool', {
      userPoolName: 'buta-user-pool-dev',
      selfSignUpEnabled: true,
      signInAliases: { email: true },
      autoVerify: { email: true },
      passwordPolicy: {
        minLength: 8,
        requireLowercase: true,
        requireUppercase: true,
        requireDigits: true,
        requireSymbols: true,
      },
      accountRecovery: cognito.AccountRecovery.EMAIL_ONLY,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    this.userPoolId = userPool.userPoolId;

    const userPoolClient = new cognito.UserPoolClient(this, 'ButaUserPoolClient', {
      userPool,
      userPoolClientName: 'buta-app-client-dev',
      authFlows: {
        userPassword: true,
        userSrp: true,
      },
      generateSecret: false,
      accessTokenValidity: cdk.Duration.hours(1),
      refreshTokenValidity: cdk.Duration.days(30),
    });

    // DynamoDB User Profiles Table (ER図準拠: butasodate-user-profiles)
    const userProfilesTable = new dynamodb.Table(this, 'UserProfilesTable', {
      tableName: 'butasodate-user-profiles',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    userProfilesTable.addGlobalSecondaryIndex({
      indexName: 'nickname-index',
      partitionKey: { name: 'nickname', type: dynamodb.AttributeType.STRING },
    });

    // Lambda Function
    const authHandler = new lambda.Function(this, 'AuthHandler', {
      functionName: 'buta-auth-handler-dev',
      runtime: lambda.Runtime.NODEJS_20_X,
      architecture: lambda.Architecture.ARM_64,
      handler: 'dist/index.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../../backend/auth-handler'), {
        exclude: ['src/**', 'tests/**', 'tsconfig.json', '*.md'],
      }),
      memorySize: 256,
      timeout: cdk.Duration.seconds(10),
      environment: {
        COGNITO_USER_POOL_ID: userPool.userPoolId,
        COGNITO_CLIENT_ID: userPoolClient.userPoolClientId,
        USER_PROFILES_TABLE_NAME: userProfilesTable.tableName,
      },
    });

    // Grant permissions
    userProfilesTable.grantReadWriteData(authHandler);
    userPool.grant(authHandler,
      'cognito-idp:AdminGetUser',
      'cognito-idp:AdminUpdateUserAttributes',
      'cognito-idp:AdminDeleteUser',
    );

    // API Gateway
    const api = new apigateway.RestApi(this, 'ButaAuthApi', {
      restApiName: 'buta-auth-api-dev',
      deployOptions: {
        stageName: 'dev',
        throttlingRateLimit: 100,
        throttlingBurstLimit: 50,
      },
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: ['Content-Type', 'Authorization'],
      },
    });

    const lambdaIntegration = new apigateway.LambdaIntegration(authHandler);

    // Gateway Responses: 4XX/5XXにCORSヘッダーを付与
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

    // Cognito Authorizer
    const authorizer = new apigateway.CognitoUserPoolsAuthorizer(this, 'ButaAuthorizer', {
      cognitoUserPools: [userPool],
    });

    const authMethodOptions: apigateway.MethodOptions = {
      authorizer,
      authorizationType: apigateway.AuthorizationType.COGNITO,
    };

    // /auth routes (no auth required)
    const auth = api.root.addResource('auth');
    auth.addResource('signup').addMethod('POST', lambdaIntegration);
    auth.addResource('confirm').addMethod('POST', lambdaIntegration);
    auth.addResource('resend-code').addMethod('POST', lambdaIntegration);
    auth.addResource('login').addMethod('POST', lambdaIntegration);
    auth.addResource('logout').addMethod('POST', lambdaIntegration, authMethodOptions);
    auth.addResource('refresh').addMethod('POST', lambdaIntegration);

    // /users routes (auth required)
    const users = api.root.addResource('users');
    users.addResource('me').addMethod('GET', lambdaIntegration, authMethodOptions);

    const profile = users.addResource('profile');
    profile.addMethod('POST', lambdaIntegration, authMethodOptions);
    profile.addMethod('PUT', lambdaIntegration, authMethodOptions);

    // DELETE /account (auth required) - ユーザー退会
    api.root.addResource('account').addMethod('DELETE', lambdaIntegration, authMethodOptions);

    // Outputs
    new cdk.CfnOutput(this, 'ApiUrl', { value: api.url });
    new cdk.CfnOutput(this, 'UserPoolId', { value: userPool.userPoolId });
    new cdk.CfnOutput(this, 'UserPoolClientId', { value: userPoolClient.userPoolClientId });
  }
}
