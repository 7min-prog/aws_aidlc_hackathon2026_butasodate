import { APIGatewayProxyResult } from 'aws-lambda';
import { UpdateCommand, GetCommand } from '@aws-sdk/lib-dynamodb';
import { dynamoClient, MATCHES_TABLE } from '../utils/dynamo-client';
import { sendToConnection } from '../utils/ws-client';
import { getUserIdFromConnection } from '../utils/auth';
import { getConnectionByUserId } from './connection';
import { successResponse } from '../utils/response';

const AVATAR_TABLE = process.env.AVATAR_TABLE || 'butasodate-avatars';

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
    // Fetch avatar stats from DB
    const [p1Avatar, p2Avatar] = await Promise.all([
      dynamoClient.send(new GetCommand({ TableName: AVATAR_TABLE, Key: { userId: updated.player1Id } })),
      dynamoClient.send(new GetCommand({ TableName: AVATAR_TABLE, Key: { userId: updated.player2Id } })),
    ]);

    const p1Stats = p1Avatar.Item?.stats || { hp: 50, attack: 10, defense: 10, speed: 10 };
    const p2Stats = p2Avatar.Item?.stats || { hp: 50, attack: 10, defense: 10, speed: 10 };

    const battleState = {
      player1: { maxHp: p1Stats.hp, currentHp: p1Stats.hp, attack: p1Stats.attack, defense: p1Stats.defense, speed: p1Stats.speed, buffs: [] },
      player2: { maxHp: p2Stats.hp, currentHp: p2Stats.hp, attack: p2Stats.attack, defense: p2Stats.defense, speed: p2Stats.speed, buffs: [] },
    };

    // Start battle
    await dynamoClient.send(new UpdateCommand({
      TableName: MATCHES_TABLE,
      Key: { matchId: data.matchId },
      UpdateExpression: 'SET #s = :status, currentTurn = :turn, startedAt = :now, turnStartedAt = :now, battleState = :state',
      ExpressionAttributeNames: { '#s': 'status' },
      ExpressionAttributeValues: {
        ':status': 'IN_PROGRESS',
        ':turn': 1,
        ':now': new Date().toISOString(),
        ':state': battleState,
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
