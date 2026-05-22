import { APIGatewayProxyResult } from 'aws-lambda';
import { UpdateCommand, GetCommand } from '@aws-sdk/lib-dynamodb';
import { dynamoClient, MATCHES_TABLE } from '../utils/dynamo-client';
import { sendToConnection } from '../utils/ws-client';
import { getUserIdFromConnection } from '../utils/auth';
import { getConnectionByUserId } from './connection';
import { successResponse } from '../utils/response';

export const handleRespondInvite = async (
  connectionId: string,
  data: { matchId: string; accept: boolean }
): Promise<APIGatewayProxyResult> => {
  const userId = await getUserIdFromConnection(connectionId);
  if (!userId) return successResponse(401);

  if (!data.accept) {
    // Reject - notify inviter
    const match = await getMatch(data.matchId);
    if (match) {
      const inviterConn = await getConnectionByUserId(match.player1Id);
      if (inviterConn) {
        await sendToConnection(inviterConn.connectionId, {
          type: 'inviteRejected',
          data: { matchId: data.matchId },
        });
      }
    }
    return successResponse(200);
  }

  // Accept - update match status
  await dynamoClient.send(new UpdateCommand({
    TableName: MATCHES_TABLE,
    Key: { matchId: data.matchId },
    UpdateExpression: 'SET #s = :status',
    ExpressionAttributeNames: { '#s': 'status' },
    ExpressionAttributeValues: { ':status': 'PREPARING' },
  }));

  // Notify both players
  const match = await getMatch(data.matchId);
  if (match) {
    const p1Conn = await getConnectionByUserId(match.player1Id);
    const p2Conn = await getConnectionByUserId(match.player2Id);
    const msg = { type: 'battleStart', data: { matchId: data.matchId } };
    if (p1Conn) await sendToConnection(p1Conn.connectionId, msg);
    if (p2Conn) await sendToConnection(p2Conn.connectionId, msg);
  }

  return successResponse(200);
};

export const handleSetReady = async (
  connectionId: string,
  data: { matchId: string; skills: string[] }
): Promise<APIGatewayProxyResult> => {
  const userId = await getUserIdFromConnection(connectionId);
  if (!userId) return successResponse(401);

  const match = await getMatch(data.matchId);
  if (!match) return successResponse(404);

  const playerKey = match.player1Id === userId ? 'player1Ready' : 'player2Ready';

  await dynamoClient.send(new UpdateCommand({
    TableName: MATCHES_TABLE,
    Key: { matchId: data.matchId },
    UpdateExpression: `SET ${playerKey} = :ready, ${playerKey}Skills = :skills`,
    ExpressionAttributeValues: {
      ':ready': true,
      ':skills': data.skills,
    },
  }));

  // Check if both ready
  const updated = await getMatch(data.matchId);
  if (updated?.player1Ready && updated?.player2Ready) {
    // Start battle
    await dynamoClient.send(new UpdateCommand({
      TableName: MATCHES_TABLE,
      Key: { matchId: data.matchId },
      UpdateExpression: 'SET #s = :status, currentTurn = :turn, startedAt = :now, turnStartedAt = :now',
      ExpressionAttributeNames: { '#s': 'status' },
      ExpressionAttributeValues: {
        ':status': 'IN_PROGRESS',
        ':turn': 1,
        ':now': new Date().toISOString(),
      },
    }));

    const p1Conn = await getConnectionByUserId(updated.player1Id);
    const p2Conn = await getConnectionByUserId(updated.player2Id);
    const msg = { type: 'battleStart', data: { matchId: data.matchId, turn: 1 } };
    if (p1Conn) await sendToConnection(p1Conn.connectionId, msg);
    if (p2Conn) await sendToConnection(p2Conn.connectionId, msg);
  }

  return successResponse(200);
};

async function getMatch(matchId: string) {
  const result = await dynamoClient.send(new GetCommand({
    TableName: MATCHES_TABLE,
    Key: { matchId },
  }));
  return result.Item as any;
}
