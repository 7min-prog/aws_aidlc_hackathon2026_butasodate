import { QueryCommand } from '@aws-sdk/lib-dynamodb';
import { dynamoClient, CONNECTIONS_TABLE } from './dynamo-client';

export async function getUserIdFromConnection(connectionId: string): Promise<string | null> {
  const result = await dynamoClient.send(new QueryCommand({
    TableName: CONNECTIONS_TABLE,
    KeyConditionExpression: 'connectionId = :cid',
    ExpressionAttributeValues: { ':cid': connectionId },
  }));
  return result.Items?.[0]?.userId || null;
}
