import * as cdk from 'aws-cdk-lib';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as path from 'path';
import { Construct } from 'constructs';

export class AuthStack extends cdk.Stack {
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

    // DynamoDB Users Table
    const usersTable = new dynamodb.Table(this, 'ButaUsersTable', {
      tableName: 'buta-users-dev',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    usersTable.addGlobalSecondaryIndex({
      indexName: 'nickname-index',
      partitionKey: { name: 'nickname', type: dynamodb.AttributeType.STRING },
    });

    // Lambda Function
    const authHandler = new lambda.Function(this, 'AuthHandler', {
      functionName: 'buta-auth-handler-dev',
      runtime: lambda.Runtime.NODEJS_20_X,
      architecture: lambda.Architecture.ARM_64,
      handler: 'index.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../../backend/auth-handler/dist')),
      memorySize: 256,
      timeout: cdk.Duration.seconds(10),
      environment: {
        COGNITO_USER_POOL_ID: userPool.userPoolId,
        COGNITO_CLIENT_ID: userPoolClient.userPoolClientId,
        USERS_TABLE_NAME: usersTable.tableName,
      },
    });

    // Grant permissions
    usersTable.grantReadWriteData(authHandler);
    userPool.grant(authHandler,
      'cognito-idp:AdminGetUser',
      'cognito-idp:AdminUpdateUserAttributes',
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

    // Cognito Authorizer
    const authorizer = new apigateway.CognitoUserPoolsAuthorizer(this, 'ButaAuthorizer', {
      cognitoUserPools: [userPool],
    });

    // /auth routes (no auth required)
    const auth = api.root.addResource('auth');
    auth.addResource('signup').addMethod('POST', lambdaIntegration);
    auth.addResource('confirm').addMethod('POST', lambdaIntegration);
    auth.addResource('resend-code').addMethod('POST', lambdaIntegration);
    auth.addResource('login').addMethod('POST', lambdaIntegration);
    auth.addResource('logout').addMethod('POST', lambdaIntegration, {
      authorizer,
      authorizationType: apigateway.AuthorizationType.COGNITO,
    });
    auth.addResource('refresh').addMethod('POST', lambdaIntegration);

    // /users routes (auth required)
    const users = api.root.addResource('users');
    const me = users.addResource('me');
    me.addMethod('GET', lambdaIntegration, {
      authorizer,
      authorizationType: apigateway.AuthorizationType.COGNITO,
    });

    const profile = users.addResource('profile');
    profile.addMethod('POST', lambdaIntegration, {
      authorizer,
      authorizationType: apigateway.AuthorizationType.COGNITO,
    });
    profile.addMethod('PUT', lambdaIntegration, {
      authorizer,
      authorizationType: apigateway.AuthorizationType.COGNITO,
    });

    // Outputs
    new cdk.CfnOutput(this, 'ApiUrl', { value: api.url });
    new cdk.CfnOutput(this, 'UserPoolId', { value: userPool.userPoolId });
    new cdk.CfnOutput(this, 'UserPoolClientId', { value: userPoolClient.userPoolClientId });
  }
}
