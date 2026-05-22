import { APIGatewayProxyResult } from 'aws-lambda';
import { PutCommand, DeleteCommand, ScanCommand } from '@aws-sdk/lib-dynamodb';
import { dynamoClient, MATCH_QUEUE_TABLE, MATCHES_TABLE } from '../utils/dynamo-client';
import { sendToConnection } from '../utils/ws-client';
import { getUserIdFromConnection } from '../utils/auth';
import { successResponse } from '../utils/response';
import { ulid } from '../utils/ulid';

export const handleRequestMatch = async (
  connectionId: string,
  data: { type: 'random' | 'friend'; targetId?: string; level?: number }
): Promise<APIGatewayProxyResult> => {
  const userId = await getUserIdFromConnection(connectionId);
  if (!userId) return successResponse(401);

  if (data.type === 'friend' && data.targetId) {
    return handleFriendInvite(connectionId, userId, data.targetId);
  }

  // Add to match queue
  await dynamoClient.send(new PutCommand({
    TableName: MATCH_QUEUE_TABLE,
    Item: {
      userId,
      connectionId,
      level: data.level || 1,
      queuedAt: new Date().toISOString(),
    },
  }));

  // Try to find a match (level ±5)
  const playerLevel = data.level || 1;
  const result = await dynamoClient.send(new ScanCommand({
    TableName: MATCH_QUEUE_TABLE,
    FilterExpression: 'userId <> :uid AND #lvl BETWEEN :minLvl AND :maxLvl',
    ExpressionAttributeNames: { '#lvl': 'level' },
    ExpressionAttributeValues: {
      ':uid': userId,
      ':minLvl': playerLevel - 5,
      ':maxLvl': playerLevel + 5,
    },
  }));

  if (result.Items && result.Items.length > 0) {
    const opponent = result.Items[0];
    await createMatch(userId, connectionId, opponent.userId, opponent.connectionId);

    // Remove both from queue
    await dynamoClient.send(new DeleteCommand({ TableName: MATCH_QUEUE_TABLE, Key: { userId } }));
    await dynamoClient.send(new DeleteCommand({ TableName: MATCH_QUEUE_TABLE, Key: { userId: opponent.userId } }));
  }

  return successResponse(200);
};

export const handleCancelMatch = async (connectionId: string): Promise<APIGatewayProxyResult> => {
  const userId = await getUserIdFromConnection(connectionId);
  if (!userId) return successResponse(401);

  await dynamoClient.send(new DeleteCommand({
    TableName: MATCH_QUEUE_TABLE,
    Key: { userId },
  }));

  return successResponse(200);
};

async function handleFriendInvite(connectionId: string, userId: string, targetId: string) {
  const matchId = ulid();

  // Create match in PREPARING state
  await dynamoClient.send(new PutCommand({
    TableName: MATCHES_TABLE,
    Item: {
      matchId,
      player1Id: userId,
      player2Id: targetId,
      type: 'FRIEND',
      status: 'PREPARING',
      currentTurn: 0,
      createdAt: new Date().toISOString(),
    },
  }));

  // Notify target
  const { getConnectionByUserId } = await import('./connection');
  const targetConn = await getConnectionByUserId(targetId);
  if (targetConn) {
    await sendToConnection(targetConn.connectionId, {
      type: 'friendInvite',
      data: { matchId, fromUserId: userId },
    });
  }

  return successResponse(200);
}

async function createMatch(
  player1Id: string, conn1Id: string,
  player2Id: string, conn2Id: string
) {
  const matchId = ulid();

  await dynamoClient.send(new PutCommand({
    TableName: MATCHES_TABLE,
    Item: {
      matchId,
      player1Id,
      player2Id,
      type: 'RANDOM',
      status: 'PREPARING',
      currentTurn: 0,
      createdAt: new Date().toISOString(),
    },
  }));

  const matchData = { type: 'matchFound', data: { matchId, player1Id, player2Id } };
  await sendToConnection(conn1Id, matchData);
  await sendToConnection(conn2Id, matchData);
}
