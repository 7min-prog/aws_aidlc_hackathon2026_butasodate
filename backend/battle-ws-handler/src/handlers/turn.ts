import { APIGatewayProxyResult } from 'aws-lambda';
import { UpdateCommand, GetCommand, PutCommand } from '@aws-sdk/lib-dynamodb';
import { ConditionalCheckFailedException } from '@aws-sdk/client-dynamodb';
import { dynamoClient, MATCHES_TABLE, RANKINGS_TABLE, BATTLE_HISTORY_TABLE } from '../utils/dynamo-client';
import { sendToConnection } from '../utils/ws-client';
import { getUserIdFromConnection } from '../utils/auth';
import { getConnectionByUserId } from './connection';
import { executeTurnLogic } from '../services/turn-engine';
import { successResponse } from '../utils/response';

export const handleSelectAction = async (
  connectionId: string,
  data: { matchId: string; action: { type: string; skillId?: string } }
): Promise<APIGatewayProxyResult> => {
  const userId = await getUserIdFromConnection(connectionId);
  if (!userId) return successResponse(401);

  const match = await getMatch(data.matchId);
  if (!match || match.status !== 'IN_PROGRESS') return successResponse(400);

  const playerKey = match.player1Id === userId ? 'player1Action' : 'player2Action';

  // Save action
  await dynamoClient.send(new UpdateCommand({
    TableName: MATCHES_TABLE,
    Key: { matchId: data.matchId },
    UpdateExpression: `SET ${playerKey} = :action`,
    ExpressionAttributeValues: { ':action': data.action },
  }));

  // Check if both actions are set
  const updated = await getMatch(data.matchId);
  if (updated?.player1Action && updated?.player2Action) {
    await tryExecuteTurn(updated);
  }

  return successResponse(200);
};

async function tryExecuteTurn(match: any) {
  // ★ ConditionExpression: 2重実行防止
  // turnExecuted_N が存在しない場合のみ実行（Nは現在ターン数）
  const turnKey = `turnExecuted_${match.currentTurn}`;

  try {
    await dynamoClient.send(new UpdateCommand({
      TableName: MATCHES_TABLE,
      Key: { matchId: match.matchId },
      UpdateExpression: `SET ${turnKey} = :true`,
      ConditionExpression: `attribute_not_exists(${turnKey})`,
      ExpressionAttributeValues: { ':true': true },
    }));
  } catch (error) {
    if (error instanceof ConditionalCheckFailedException) {
      // Already executed by another Lambda invocation - skip
      return;
    }
    throw error;
  }

  // Execute turn logic
  const turnResult = await executeTurnLogic(match);

  // Update match state
  const updateExpr = turnResult.battleEnd
    ? 'SET #s = :status, currentTurn = :turn, battleState = :state, player1Action = :null, player2Action = :null, winnerId = :winner, finishReason = :reason, finishedAt = :now'
    : 'SET currentTurn = :turn, battleState = :state, player1Action = :null, player2Action = :null, turnStartedAt = :now';

  const exprValues: any = {
    ':turn': match.currentTurn + 1,
    ':state': turnResult.battleState,
    ':null': null,
    ':now': new Date().toISOString(),
  };

  if (turnResult.battleEnd) {
    exprValues[':status'] = 'FINISHED';
    exprValues[':winner'] = turnResult.winnerId || null;
    exprValues[':reason'] = turnResult.finishReason;
  }

  await dynamoClient.send(new UpdateCommand({
    TableName: MATCHES_TABLE,
    Key: { matchId: match.matchId },
    UpdateExpression: updateExpr,
    ...(turnResult.battleEnd ? { ExpressionAttributeNames: { '#s': 'status' } } : {}),
    ExpressionAttributeValues: exprValues,
  }));

  // Send results to both players
  const p1Conn = await getConnectionByUserId(match.player1Id);
  const p2Conn = await getConnectionByUserId(match.player2Id);

  const msgType = turnResult.battleEnd ? 'battleEnd' : 'turnResult';
  const msg = { type: msgType, data: turnResult };

  if (p1Conn) await sendToConnection(p1Conn.connectionId, msg);
  if (p2Conn) await sendToConnection(p2Conn.connectionId, msg);

  // Battle end: update rankings and save history
  if (turnResult.battleEnd) {
    const now = new Date().toISOString();
    const winnerId = turnResult.winnerId;
    const loserId = winnerId === match.player1Id ? match.player2Id : match.player1Id;

    // Upsert rankings (ADD creates item if not exists)
    if (winnerId) {
      await dynamoClient.send(new UpdateCommand({
        TableName: RANKINGS_TABLE,
        Key: { userId: winnerId },
        UpdateExpression: 'ADD wins :one, points :winPts SET #p = if_not_exists(#p, :defaultPartition), lastBattleAt = :now',
        ExpressionAttributeNames: { '#p': 'partition' },
        ExpressionAttributeValues: { ':one': 1, ':winPts': 25, ':defaultPartition': 'GLOBAL', ':now': now },
      }));
      await dynamoClient.send(new UpdateCommand({
        TableName: RANKINGS_TABLE,
        Key: { userId: loserId },
        UpdateExpression: 'ADD losses :one, points :losePts SET #p = if_not_exists(#p, :defaultPartition), lastBattleAt = :now',
        ExpressionAttributeNames: { '#p': 'partition' },
        ExpressionAttributeValues: { ':one': 1, ':losePts': -15, ':defaultPartition': 'GLOBAL', ':now': now },
      }));
    }

    // Save battle history for both players
    await dynamoClient.send(new PutCommand({
      TableName: BATTLE_HISTORY_TABLE,
      Item: {
        compositeId: `${match.player1Id}#${match.matchId}`,
        matchId: match.matchId, userId: match.player1Id, opponentId: match.player2Id,
        result: winnerId === match.player1Id ? 'WIN' : winnerId ? 'LOSE' : 'DRAW',
        pointChange: winnerId === match.player1Id ? 25 : winnerId ? -15 : 0,
        totalTurns: match.currentTurn, finishReason: turnResult.finishReason, playedAt: now,
      },
    }));
    await dynamoClient.send(new PutCommand({
      TableName: BATTLE_HISTORY_TABLE,
      Item: {
        compositeId: `${match.player2Id}#${match.matchId}`,
        matchId: match.matchId, userId: match.player2Id, opponentId: match.player1Id,
        result: winnerId === match.player2Id ? 'WIN' : winnerId ? 'LOSE' : 'DRAW',
        pointChange: winnerId === match.player2Id ? 25 : winnerId ? -15 : 0,
        totalTurns: match.currentTurn, finishReason: turnResult.finishReason, playedAt: now,
      },
    }));
  }
}

async function getMatch(matchId: string) {
  const result = await dynamoClient.send(new GetCommand({
    TableName: MATCHES_TABLE,
    Key: { matchId },
  }));
  return result.Item as any;
}
