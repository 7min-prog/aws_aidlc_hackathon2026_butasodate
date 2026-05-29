import * as cdk from 'aws-cdk-lib';
import { Template, Match } from 'aws-cdk-lib/assertions';
import { AuthStack } from '../lib/auth-stack';
import { RecordingStack } from '../lib/recording-stack';
import { AvatarStack } from '../lib/avatar-stack';
import { BattleSocialStack } from '../lib/battle-social-stack';
import { AdminStack } from '../lib/admin-stack';

const env = { account: '123456789012', region: 'ap-northeast-1' };

describe('AuthStack', () => {
  let template: Template;

  beforeAll(() => {
    const app = new cdk.App();
    const stack = new AuthStack(app, 'TestAuthStack', { env });
    template = Template.fromStack(stack);
  });

  it('creates a Cognito User Pool with email sign-in', () => {
    template.hasResourceProperties('AWS::Cognito::UserPool', {
      UsernameAttributes: ['email'],
      AutoVerifiedAttributes: ['email'],
    });
  });

  it('creates a User Pool Client without secret', () => {
    template.hasResourceProperties('AWS::Cognito::UserPoolClient', {
      GenerateSecret: false,
      ExplicitAuthFlows: Match.arrayWith([
        'ALLOW_USER_PASSWORD_AUTH',
        'ALLOW_USER_SRP_AUTH',
      ]),
    });
  });

  it('creates DynamoDB user-profiles table with PAY_PER_REQUEST', () => {
    template.hasResourceProperties('AWS::DynamoDB::Table', {
      TableName: 'butasodate-user-profiles',
      BillingMode: 'PAY_PER_REQUEST',
      KeySchema: Match.arrayWith([
        { AttributeName: 'userId', KeyType: 'HASH' },
      ]),
    });
  });

  it('creates nickname-index GSI on user-profiles', () => {
    template.hasResourceProperties('AWS::DynamoDB::Table', {
      TableName: 'butasodate-user-profiles',
      GlobalSecondaryIndexes: Match.arrayWith([
        Match.objectLike({ IndexName: 'nickname-index' }),
      ]),
    });
  });

  it('creates auth Lambda with Node.js 20.x runtime', () => {
    template.hasResourceProperties('AWS::Lambda::Function', {
      Runtime: 'nodejs20.x',
      Handler: Match.stringLikeRegexp('.*handler'),
    });
  });

  it('creates REST API Gateway', () => {
    template.resourceCountIs('AWS::ApiGateway::RestApi', 1);
  });
});

describe('RecordingStack', () => {
  let template: Template;

  beforeAll(() => {
    const app = new cdk.App();
    const stack = new RecordingStack(app, 'TestRecordingStack', { env, userPoolId: 'us-east-1_test' });
    template = Template.fromStack(stack);
  });

  it('creates activity-records table with userId partition key and sk sort key', () => {
    template.hasResourceProperties('AWS::DynamoDB::Table', {
      TableName: 'butasodate-activity-records',
      KeySchema: [
        { AttributeName: 'userId', KeyType: 'HASH' },
        { AttributeName: 'sk', KeyType: 'RANGE' },
      ],
    });
  });

  it('creates activity-categories table', () => {
    template.hasResourceProperties('AWS::DynamoDB::Table', {
      TableName: 'butasodate-activity-categories',
      KeySchema: [{ AttributeName: 'categoryId', KeyType: 'HASH' }],
    });
  });

  it('creates category-index GSI on activity-records', () => {
    template.hasResourceProperties('AWS::DynamoDB::Table', {
      TableName: 'butasodate-activity-records',
      GlobalSecondaryIndexes: Match.arrayWith([
        Match.objectLike({ IndexName: 'category-index' }),
      ]),
    });
  });

  it('creates recording Lambda function', () => {
    template.hasResourceProperties('AWS::Lambda::Function', {
      FunctionName: 'buta-recording-handler',
      Runtime: 'nodejs20.x',
    });
  });

  it('Lambda has correct environment variables', () => {
    template.hasResourceProperties('AWS::Lambda::Function', {
      FunctionName: 'buta-recording-handler',
      Environment: {
        Variables: Match.objectLike({
          AVATAR_TABLE_NAME: 'butasodate-avatars',
          PIG_SPECIES_TABLE_NAME: 'butasodate-pig-species',
        }),
      },
    });
  });
});

describe('AvatarStack', () => {
  let template: Template;

  beforeAll(() => {
    const app = new cdk.App();
    const stack = new AvatarStack(app, 'TestAvatarStack', { env, userPoolId: 'us-east-1_test' });
    template = Template.fromStack(stack);
  });

  it('creates avatars table', () => {
    template.hasResourceProperties('AWS::DynamoDB::Table', {
      TableName: 'butasodate-avatars',
      KeySchema: [{ AttributeName: 'userId', KeyType: 'HASH' }],
    });
  });

  it('creates evolution-history table with composite sort key', () => {
    template.hasResourceProperties('AWS::DynamoDB::Table', {
      TableName: 'butasodate-evolution-history',
      KeySchema: [
        { AttributeName: 'userId', KeyType: 'HASH' },
        { AttributeName: 'occurredAt#historyId', KeyType: 'RANGE' },
      ],
    });
  });

  it('creates pig-species table with stage-index GSI', () => {
    template.hasResourceProperties('AWS::DynamoDB::Table', {
      TableName: 'butasodate-pig-species',
      GlobalSecondaryIndexes: Match.arrayWith([
        Match.objectLike({ IndexName: 'stage-index' }),
      ]),
    });
  });

  it('creates evolution-routes table', () => {
    template.hasResourceProperties('AWS::DynamoDB::Table', {
      TableName: 'butasodate-evolution-routes',
      KeySchema: [{ AttributeName: 'routeId', KeyType: 'HASH' }],
    });
  });

  it('creates S3 assets bucket', () => {
    template.resourceCountIs('AWS::S3::Bucket', 1);
  });

  it('creates avatar Lambda function', () => {
    template.hasResourceProperties('AWS::Lambda::Function', {
      Runtime: 'nodejs20.x',
      Handler: Match.stringLikeRegexp('.*handler'),
    });
  });
});

describe('BattleSocialStack', () => {
  let template: Template;

  beforeAll(() => {
    const app = new cdk.App();
    const stack = new BattleSocialStack(app, 'TestBattleSocialStack', { env, userPoolId: 'us-east-1_test' });
    template = Template.fromStack(stack);
  });

  it('creates connections table', () => {
    template.hasResourceProperties('AWS::DynamoDB::Table', {
      TableName: 'buta-connections-dev',
      KeySchema: [{ AttributeName: 'connectionId', KeyType: 'HASH' }],
    });
  });

  it('creates match-queue table', () => {
    template.hasResourceProperties('AWS::DynamoDB::Table', {
      TableName: 'buta-match-queue-dev',
      KeySchema: [{ AttributeName: 'userId', KeyType: 'HASH' }],
    });
  });

  it('connections table has userId-index GSI', () => {
    template.hasResourceProperties('AWS::DynamoDB::Table', {
      TableName: 'buta-connections-dev',
      GlobalSecondaryIndexes: Match.arrayWith([
        Match.objectLike({ IndexName: 'userId-index' }),
      ]),
    });
  });

  it('creates WebSocket API (API Gateway V2)', () => {
    template.resourceCountIs('AWS::ApiGatewayV2::Api', 1);
  });

  it('creates battle-ws Lambda', () => {
    template.hasResourceProperties('AWS::Lambda::Function', {
      Runtime: 'nodejs20.x',
    });
  });

  it('all DynamoDB tables use PAY_PER_REQUEST', () => {
    const tables = template.findResources('AWS::DynamoDB::Table');
    Object.values(tables).forEach((table: any) => {
      expect(table.Properties.BillingMode).toBe('PAY_PER_REQUEST');
    });
  });
});

describe('AdminStack', () => {
  let template: Template;

  beforeAll(() => {
    const app = new cdk.App();
    const stack = new AdminStack(app, 'TestAdminStack', {
      env, userPoolId: 'us-east-1_test', assetsBucketName: 'test-assets',
    });
    template = Template.fromStack(stack);
  });

  it('creates audit-log table with logId + timestamp keys', () => {
    template.hasResourceProperties('AWS::DynamoDB::Table', {
      TableName: 'butasodate-admin-audit-log',
      KeySchema: [
        { AttributeName: 'logId', KeyType: 'HASH' },
        { AttributeName: 'timestamp', KeyType: 'RANGE' },
      ],
    });
  });

  it('creates game-config table', () => {
    template.hasResourceProperties('AWS::DynamoDB::Table', {
      TableName: 'butasodate-game-config',
      KeySchema: [{ AttributeName: 'configKey', KeyType: 'HASH' }],
    });
  });

  it('creates admin Lambda function', () => {
    template.hasResourceProperties('AWS::Lambda::Function', {
      FunctionName: 'buta-admin-handler-dev',
      Runtime: 'nodejs20.x',
    });
  });

  it('creates CloudFront distribution for admin SPA', () => {
    template.resourceCountIs('AWS::CloudFront::Distribution', 1);
  });

  it('all DynamoDB tables use PAY_PER_REQUEST', () => {
    const tables = template.findResources('AWS::DynamoDB::Table');
    Object.values(tables).forEach((table: any) => {
      expect(table.Properties.BillingMode).toBe('PAY_PER_REQUEST');
    });
  });
});
