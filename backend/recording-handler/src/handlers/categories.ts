import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { docClient } from '../utils/dynamo-client';
import { getUserId } from '../utils/auth';
import { success, error } from '../utils/response';
import { ScanCommand, GetCommand } from '@aws-sdk/lib-dynamodb';

const CATEGORY_TABLE = process.env.ACTIVITY_CATEGORY_TABLE!;

export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
  try {
    getUserId(event); // auth check
    const path = event.resource;

    if (path === '/categories/version') {
      const result = await docClient.send(new GetCommand({
        TableName: CATEGORY_TABLE,
        Key: { categoryId: '_meta' },
      }));
      return success({ version: result.Item?.version || 1 });
    }

    // GET /categories
    const result = await docClient.send(new ScanCommand({
      TableName: CATEGORY_TABLE,
      FilterExpression: 'isActive = :t AND categoryId <> :meta',
      ExpressionAttributeValues: { ':t': true, ':meta': '_meta' },
    }));

    const items = (result.Items || []).sort((a, b) => (a.sortOrder || 0) - (b.sortOrder || 0));
    const version = (await docClient.send(new GetCommand({
      TableName: CATEGORY_TABLE,
      Key: { categoryId: '_meta' },
    }))).Item?.version || 1;

    return success({ categories: items, version });
  } catch (err: any) {
    console.error(err);
    if (err.message === 'Unauthorized') return error('Unauthorized', 401);
    return error('Internal Server Error', 500);
  }
}
