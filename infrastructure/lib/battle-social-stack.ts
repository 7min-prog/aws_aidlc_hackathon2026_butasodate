import * as cdk from 'aws-cdk-lib';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigatewayv2 from 'aws-cdk-lib/aws-apigatewayv2';
import * as apigatewayv2Integrations from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as path from 'path';
import { Construct } from 'constructs';

export class BattleSocialStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // ===== DynamoDB Tables =====

    const connectionsTable = new dynamodb.Table(this, 'ConnectionsTable', {
      tableName: 'buta-connections-dev',
      partitionKey: { name: 'connectionId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });
    connectionsTable.addGlobalSecondaryIndex({
      indexName: 'userId-index',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
    });

    const matchQueueTable = new dynamodb.Table(this, 'MatchQueueTable', {
      tableName: 'buta-match-queue-dev',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    const matchesTable = new dynamodb.Table(this, 'MatchesTable', {
      tableName: 'buta-matches-dev',
      partitionKey: { name: 'matchId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    const battleHistoryTable = new dynamodb.Table(this, 'BattleHistoryTable', {
      tableName: 'buta-battle-history-dev',
      partitionKey: { name: 'odataId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });
    battleHistoryTable.addGlobalSecondaryIndex({
      indexName: 'userId-index',
      partitionKey: { name: 'odataUserId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'finishedAt', type: dynamodb.AttributeType.STRING },
    });

    const friendsTable = new dynamodb.Table(this, 'FriendsTable', {
      tableName: 'buta-friends-dev',
      partitionKey: { name: 'odataId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });
    friendsTable.addGlobalSecondaryIndex({
      indexName: 'userId-index',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
    });

    const friendRequestsTable = new dynamodb.Table(this, 'FriendRequestsTable', {
      tableName: 'buta-friend-requests-dev',
      partitionKey: { name: 'requestId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });
    friendRequestsTable.addGlobalSecondaryIndex({
      indexName: 'toUserId-index',
      partitionKey: { name: 'toUserId', type: dynamodb.AttributeType.STRING },
    });

    const rankingsTable = new dynamodb.Table(this, 'RankingsTable', {
      tableName: 'buta-rankings-dev',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // ===== WebSocket API + Lambda =====

    const battleWsHandler = new lambda.Function(this, 'BattleWsHandler', {
      functionName: 'buta-battle-ws-handler-dev',
      runtime: lambda.Runtime.NODEJS_LATEST,
      architecture: lambda.Architecture.ARM_64,
      handler: 'index.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../../backend/battle-ws-handler/dist')),
      memorySize: 256,
      timeout: cdk.Duration.seconds(10),
      environment: {
        CONNECTIONS_TABLE: connectionsTable.tableName,
        MATCH_QUEUE_TABLE: matchQueueTable.tableName,
        MATCHES_TABLE: matchesTable.tableName,
        BATTLE_HISTORY_TABLE: battleHistoryTable.tableName,
        RANKINGS_TABLE: rankingsTable.tableName,
      },
    });

    connectionsTable.grantReadWriteData(battleWsHandler);
    matchQueueTable.grantReadWriteData(battleWsHandler);
    matchesTable.grantReadWriteData(battleWsHandler);
    battleHistoryTable.grantReadWriteData(battleWsHandler);
    rankingsTable.grantReadWriteData(battleWsHandler);

    const webSocketApi = new apigatewayv2.WebSocketApi(this, 'BattleWebSocketApi', {
      apiName: 'buta-battle-ws-dev',
      connectRouteOptions: {
        integration: new apigatewayv2Integrations.WebSocketLambdaIntegration('ConnectIntegration', battleWsHandler),
      },
      disconnectRouteOptions: {
        integration: new apigatewayv2Integrations.WebSocketLambdaIntegration('DisconnectIntegration', battleWsHandler),
      },
      defaultRouteOptions: {
        integration: new apigatewayv2Integrations.WebSocketLambdaIntegration('DefaultIntegration', battleWsHandler),
      },
    });

    const wsStage = new apigatewayv2.WebSocketStage(this, 'BattleWsStage', {
      webSocketApi,
      stageName: 'dev',
      autoDeploy: true,
    });

    // Grant ManageConnections permission
    battleWsHandler.addEnvironment('WEBSOCKET_ENDPOINT', wsStage.callbackUrl);
    battleWsHandler.addToRolePolicy(new iam.PolicyStatement({
      actions: ['execute-api:ManageConnections'],
      resources: [`arn:aws:execute-api:${this.region}:${this.account}:${webSocketApi.apiId}/dev/*`],
    }));

    // ===== Social REST Lambda =====

    const socialHandler = new lambda.Function(this, 'SocialHandler', {
      functionName: 'buta-social-handler-dev',
      runtime: lambda.Runtime.NODEJS_LATEST,
      architecture: lambda.Architecture.ARM_64,
      handler: 'index.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../../backend/social-handler/dist')),
      memorySize: 256,
      timeout: cdk.Duration.seconds(10),
      environment: {
        FRIENDS_TABLE: friendsTable.tableName,
        FRIEND_REQUESTS_TABLE: friendRequestsTable.tableName,
        RANKINGS_TABLE: rankingsTable.tableName,
        BATTLE_HISTORY_TABLE: battleHistoryTable.tableName,
        USERS_TABLE: 'buta-users-dev',
      },
    });

    friendsTable.grantReadWriteData(socialHandler);
    friendRequestsTable.grantReadWriteData(socialHandler);
    rankingsTable.grantReadData(socialHandler);
    battleHistoryTable.grantReadData(socialHandler);

    // ===== Outputs =====

    new cdk.CfnOutput(this, 'WebSocketUrl', { value: wsStage.url });
    new cdk.CfnOutput(this, 'WebSocketCallbackUrl', { value: wsStage.callbackUrl });
  }
}
