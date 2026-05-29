import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({
  region: process.env.AWS_REGION || 'ap-northeast-1',
});

export const dynamoClient = DynamoDBDocumentClient.from(client);
export const USERS_TABLE = process.env.USERS_TABLE_NAME || 'buta-users-dev';
