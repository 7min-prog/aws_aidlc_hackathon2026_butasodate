import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { PutCommand, DeleteCommand, QueryCommand, GetCommand, ScanCommand } from '@aws-sdk/lib-dynamodb';
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { successResponse, errorResponse } from './utils/response';
import { ulid } from './utils/ulid';

const client = DynamoDBDocumentClient.from(new DynamoDBClient({ region: 'ap-northeast-1' }));
const FRIENDS_TABLE = process.env.FRIENDS_TABLE || 'buta-friends-dev';
const FRIEND_REQUESTS_TABLE = process.env.FRIEND_REQUESTS_TABLE || 'buta-friend-requests-dev';
const RANKINGS_TABLE = process.env.RANKINGS_TABLE || 'buta-rankings-dev';
const BATTLE_HISTORY_TABLE = process.env.BATTLE_HISTORY_TABLE || 'buta-battle-history-dev';
const USERS_TABLE = process.env.USERS_TABLE || 'buta-users-dev';

function getUserId(event: APIGatewayProxyEvent): string | null {
  return event.requestContext.authorizer?.claims?.sub || null;
}

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const { httpMethod, path } = event;
  const route = `${httpMethod} ${path}`;

  try {
    if (route === 'GET /social/friends') return getFriends(event);
    if (route === 'POST /social/friends/search') return searchUsers(event);
    if (route === 'POST /social/friends/request') return sendFriendRequest(event);
    if (route === 'POST /social/friends/respond') return respondFriendRequest(event);
    if (route.startsWith('DELETE /social/friends/')) return removeFriend(event);
    if (route === 'GET /social/friends/requests') return getPendingRequests(event);
    if (route === 'GET /rankings') return getRankings(event);
    if (route === 'GET /rankings/me') return getMyRanking(event);
    if (route === 'GET /battles/history') return getBattleHistory(event);
    if (route.startsWith('GET /battles/history/')) return getBattleDetail(event);
    return errorResponse(404, 'Not Found');
  } catch (error) {
    console.error('Error:', error);
    return errorResponse(500, 'Internal Server Error');
  }
};

async function getFriends(event: APIGatewayProxyEvent) {
  const userId = getUserId(event);
  if (!userId) return errorResponse(401, 'Unauthorized');

  const result = await client.send(new QueryCommand({
    TableName: FRIENDS_TABLE,
    IndexName: 'userId-index',
    KeyConditionExpression: 'userId = :uid',
    ExpressionAttributeValues: { ':uid': userId },
  }));

  return successResponse(200, { friends: result.Items || [] });
}

async function searchUsers(event: APIGatewayProxyEvent) {
  const { query } = JSON.parse(event.body || '{}');
  if (!query) return errorResponse(400, 'query is required');

  const result = await client.send(new QueryCommand({
    TableName: USERS_TABLE,
    IndexName: 'nickname-index',
    KeyConditionExpression: 'nickname = :n',
    ExpressionAttributeValues: { ':n': query },
  }));

  return successResponse(200, { users: result.Items || [] });
}

async function sendFriendRequest(event: APIGatewayProxyEvent) {
  const userId = getUserId(event);
  if (!userId) return errorResponse(401, 'Unauthorized');

  const { targetUserId } = JSON.parse(event.body || '{}');
  if (!targetUserId) return errorResponse(400, 'targetUserId is required');

  await client.send(new PutCommand({
    TableName: FRIEND_REQUESTS_TABLE,
    Item: {
      requestId: ulid(),
      fromUserId: userId,
      toUserId: targetUserId,
      status: 'PENDING',
      createdAt: new Date().toISOString(),
    },
  }));

  return successResponse(201, { message: 'Friend request sent' });
}

async function respondFriendRequest(event: APIGatewayProxyEvent) {
  const userId = getUserId(event);
  if (!userId) return errorResponse(401, 'Unauthorized');

  const { requestId, accept } = JSON.parse(event.body || '{}');
  if (!requestId) return errorResponse(400, 'requestId is required');

  const req = await client.send(new GetCommand({
    TableName: FRIEND_REQUESTS_TABLE,
    Key: { requestId },
  }));

  if (!req.Item || req.Item.toUserId !== userId) return errorResponse(404, 'Request not found');

  if (accept) {
    // Create bidirectional friend relationship
    const now = new Date().toISOString();
    await client.send(new PutCommand({
      TableName: FRIENDS_TABLE,
      Item: { odataId: `${userId}#${req.Item.fromUserId}`, userId, friendId: req.Item.fromUserId, createdAt: now },
    }));
    await client.send(new PutCommand({
      TableName: FRIENDS_TABLE,
      Item: { odataId: `${req.Item.fromUserId}#${userId}`, userId: req.Item.fromUserId, friendId: userId, createdAt: now },
    }));
  }

  // Update request status
  const { UpdateCommand } = await import('@aws-sdk/lib-dynamodb');
  await client.send(new UpdateCommand({
    TableName: FRIEND_REQUESTS_TABLE,
    Key: { requestId },
    UpdateExpression: 'SET #s = :status',
    ExpressionAttributeNames: { '#s': 'status' },
    ExpressionAttributeValues: { ':status': accept ? 'ACCEPTED' : 'REJECTED' },
  }));

  return successResponse(200, { message: accept ? 'Friend added' : 'Request rejected' });
}

async function removeFriend(event: APIGatewayProxyEvent) {
  const userId = getUserId(event);
  if (!userId) return errorResponse(401, 'Unauthorized');

  const friendId = event.pathParameters?.id;
  if (!friendId) return errorResponse(400, 'friendId is required');

  await client.send(new DeleteCommand({ TableName: FRIENDS_TABLE, Key: { odataId: `${userId}#${friendId}` } }));
  await client.send(new DeleteCommand({ TableName: FRIENDS_TABLE, Key: { odataId: `${friendId}#${userId}` } }));

  return successResponse(200, { message: 'Friend removed' });
}

async function getPendingRequests(event: APIGatewayProxyEvent) {
  const userId = getUserId(event);
  if (!userId) return errorResponse(401, 'Unauthorized');

  const result = await client.send(new QueryCommand({
    TableName: FRIEND_REQUESTS_TABLE,
    IndexName: 'toUserId-index',
    KeyConditionExpression: 'toUserId = :uid',
    FilterExpression: '#s = :pending',
    ExpressionAttributeNames: { '#s': 'status' },
    ExpressionAttributeValues: { ':uid': userId, ':pending': 'PENDING' },
  }));

  return successResponse(200, { requests: result.Items || [] });
}

async function getRankings(_event: APIGatewayProxyEvent) {
  const result = await client.send(new ScanCommand({
    TableName: RANKINGS_TABLE,
    Limit: 100,
  }));

  const sorted = (result.Items || []).sort((a, b) => (b.points || 0) - (a.points || 0));
  return successResponse(200, { rankings: sorted });
}

async function getMyRanking(event: APIGatewayProxyEvent) {
  const userId = getUserId(event);
  if (!userId) return errorResponse(401, 'Unauthorized');

  const result = await client.send(new GetCommand({
    TableName: RANKINGS_TABLE,
    Key: { userId },
  }));

  return successResponse(200, { ranking: result.Item || { userId, points: 0, wins: 0, losses: 0 } });
}

async function getBattleHistory(event: APIGatewayProxyEvent) {
  const userId = getUserId(event);
  if (!userId) return errorResponse(401, 'Unauthorized');

  const result = await client.send(new QueryCommand({
    TableName: BATTLE_HISTORY_TABLE,
    IndexName: 'userId-index',
    KeyConditionExpression: 'odataUserId = :uid',
    ScanIndexForward: false,
    Limit: 50,
    ExpressionAttributeValues: { ':uid': userId },
  }));

  return successResponse(200, { history: result.Items || [] });
}

async function getBattleDetail(event: APIGatewayProxyEvent) {
  const userId = getUserId(event);
  if (!userId) return errorResponse(401, 'Unauthorized');

  const matchId = event.pathParameters?.id;
  if (!matchId) return errorResponse(400, 'matchId is required');

  const result = await client.send(new GetCommand({
    TableName: BATTLE_HISTORY_TABLE,
    Key: { odataId: `${userId}#${matchId}` },
  }));

  if (!result.Item) return errorResponse(404, 'Battle not found');
  return successResponse(200, result.Item);
}
