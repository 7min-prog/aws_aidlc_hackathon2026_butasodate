import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { dynamoClient, USERS_TABLE } from '../utils/dynamo-client';
import { GetCommand, PutCommand, UpdateCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { successResponse, errorResponse } from '../utils/response';

function getUserId(event: APIGatewayProxyEvent): string | null {
  return event.requestContext.authorizer?.claims?.sub || null;
}

export const handleGetProfile = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const userId = getUserId(event);
  if (!userId) return errorResponse(401, 'Unauthorized');

  try {
    const result = await dynamoClient.send(new GetCommand({
      TableName: USERS_TABLE,
      Key: { userId },
    }));

    if (!result.Item) {
      return errorResponse(404, 'Profile not found');
    }

    return successResponse(200, result.Item);
  } catch (error) {
    console.error('GetProfile error:', error);
    return errorResponse(500, 'Internal Server Error');
  }
};

export const handleCreateProfile = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const userId = getUserId(event);
  if (!userId) return errorResponse(401, 'Unauthorized');

  const { nickname } = JSON.parse(event.body || '{}');
  if (!nickname || nickname.length < 2 || nickname.length > 10) {
    return errorResponse(400, 'nickname must be 2-10 characters');
  }

  try {
    // Check nickname uniqueness
    const existing = await dynamoClient.send(new QueryCommand({
      TableName: USERS_TABLE,
      IndexName: 'nickname-index',
      KeyConditionExpression: 'nickname = :n',
      ExpressionAttributeValues: { ':n': nickname },
    }));

    if (existing.Items && existing.Items.length > 0) {
      return errorResponse(409, 'This nickname is already taken');
    }

    const now = new Date().toISOString();
    const claims = event.requestContext.authorizer?.claims;

    await dynamoClient.send(new PutCommand({
      TableName: USERS_TABLE,
      Item: {
        userId,
        email: claims?.email || '',
        nickname,
        authProvider: 'EMAIL',
        linkedProviders: [],
        createdAt: now,
        updatedAt: now,
        lastLoginAt: now,
      },
    }));

    return successResponse(201, { message: 'Profile created', nickname });
  } catch (error) {
    console.error('CreateProfile error:', error);
    return errorResponse(500, 'Internal Server Error');
  }
};

export const handleUpdateProfile = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const userId = getUserId(event);
  if (!userId) return errorResponse(401, 'Unauthorized');

  const { nickname } = JSON.parse(event.body || '{}');
  if (!nickname || nickname.length < 2 || nickname.length > 10) {
    return errorResponse(400, 'nickname must be 2-10 characters');
  }

  try {
    // Check nickname uniqueness (exclude self)
    const existing = await dynamoClient.send(new QueryCommand({
      TableName: USERS_TABLE,
      IndexName: 'nickname-index',
      KeyConditionExpression: 'nickname = :n',
      ExpressionAttributeValues: { ':n': nickname },
    }));

    if (existing.Items && existing.Items.some(item => item.userId !== userId)) {
      return errorResponse(409, 'This nickname is already taken');
    }

    await dynamoClient.send(new UpdateCommand({
      TableName: USERS_TABLE,
      Key: { userId },
      UpdateExpression: 'SET nickname = :n, updatedAt = :now',
      ExpressionAttributeValues: {
        ':n': nickname,
        ':now': new Date().toISOString(),
      },
    }));

    return successResponse(200, { message: 'Profile updated', nickname });
  } catch (error) {
    console.error('UpdateProfile error:', error);
    return errorResponse(500, 'Internal Server Error');
  }
};
