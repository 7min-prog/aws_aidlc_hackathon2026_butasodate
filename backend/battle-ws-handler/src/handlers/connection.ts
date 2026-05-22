import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { PutCommand, DeleteCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { dynamoClient, CONNECTIONS_TABLE, MATCHES_TABLE } from '../utils/dynamo-client';
import { sendToConnection } from '../utils/ws-client';
import { successResponse, errorResponse } from '../utils/response';

export const handleConnect = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const connectionId = event.requestContext.connectionId!;
  const token = event.queryStringParameters?.token;

  if (!token) {
    return errorResponse(401, 'Token required');
  }

  // TODO: Cognitoトークン検証（デモではuserIdをクエリパラメータから取得）
  const userId = event.queryStringParameters?.userId;
  if (!userId) {
    return errorResponse(401, 'userId required');
  }

  await dynamoClient.send(new PutCommand({
    TableName: CONNECTIONS_TABLE,
    Item: {
      connectionId,
      userId,
      connectedAt: new Date().toISOString(),
    },
  }));

  return successResponse(200);
};

export const handleDisconnect = async (connectionId: string): Promise<APIGatewayProxyResult> => {
  // Get userId from connection
  const conn = await getConnectionByConnectionId(connectionId);

  // Delete connection record
  await dynamoClient.send(new DeleteCommand({
    TableName: CONNECTIONS_TABLE,
    Key: { connectionId },
  }));

  // If in active battle, auto-lose
  if (conn?.userId) {
    await handleBattleDisconnect(conn.userId, connectionId);
  }

  return successResponse(200);
};

async function getConnectionByConnectionId(connectionId: string) {
  const result = await dynamoClient.send(new QueryCommand({
    TableName: CONNECTIONS_TABLE,
    KeyConditionExpression: 'connectionId = :cid',
    ExpressionAttributeValues: { ':cid': connectionId },
  }));
  return result.Items?.[0] as { connectionId: string; userId: string } | undefined;
}

async function handleBattleDisconnect(userId: string, _connectionId: string) {
  // Find active match for this user
  // For simplicity, we scan matches with status IN_PROGRESS
  // In production, use a GSI on userId
  const result = await dynamoClient.send(new QueryCommand({
    TableName: MATCHES_TABLE,
    IndexName: 'player-index',
    KeyConditionExpression: 'player1Id = :uid OR player2Id = :uid',
    FilterExpression: '#s = :status',
    ExpressionAttributeNames: { '#s': 'status' },
    ExpressionAttributeValues: { ':uid': userId, ':status': 'IN_PROGRESS' },
  }));

  if (result.Items && result.Items.length > 0) {
    const match = result.Items[0];
    const opponentId = match.player1Id === userId ? match.player2Id : match.player1Id;

    // Notify opponent
    const opponentConn = await getConnectionByUserId(opponentId);
    if (opponentConn) {
      await sendToConnection(opponentConn.connectionId, {
        type: 'opponentDisconnected',
        data: { matchId: match.matchId },
      });
    }
  }
}

async function getConnectionByUserId(userId: string) {
  const result = await dynamoClient.send(new QueryCommand({
    TableName: CONNECTIONS_TABLE,
    IndexName: 'userId-index',
    KeyConditionExpression: 'userId = :uid',
    ExpressionAttributeValues: { ':uid': userId },
  }));
  return result.Items?.[0] as { connectionId: string; userId: string } | undefined;
}

export { getConnectionByUserId };
