"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleSelectAction = void 0;
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const client_dynamodb_1 = require("@aws-sdk/client-dynamodb");
const dynamo_client_1 = require("../utils/dynamo-client");
const ws_client_1 = require("../utils/ws-client");
const auth_1 = require("../utils/auth");
const connection_1 = require("./connection");
const turn_engine_1 = require("../services/turn-engine");
const response_1 = require("../utils/response");
const handleSelectAction = async (connectionId, data) => {
    const userId = await (0, auth_1.getUserIdFromConnection)(connectionId);
    if (!userId)
        return (0, response_1.successResponse)(401);
    const match = await getMatch(data.matchId);
    if (!match || match.status !== 'IN_PROGRESS')
        return (0, response_1.successResponse)(400);
    const playerKey = match.player1Id === userId ? 'player1Action' : 'player2Action';
    // Save action
    await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.UpdateCommand({
        TableName: dynamo_client_1.MATCHES_TABLE,
        Key: { matchId: data.matchId },
        UpdateExpression: `SET ${playerKey} = :action`,
        ExpressionAttributeValues: { ':action': data.action },
    }));
    // Check if both actions are set
    const updated = await getMatch(data.matchId);
    if (updated?.player1Action && updated?.player2Action) {
        await tryExecuteTurn(updated);
    }
    return (0, response_1.successResponse)(200);
};
exports.handleSelectAction = handleSelectAction;
async function tryExecuteTurn(match) {
    // ★ ConditionExpression: 2重実行防止
    // turnExecuted_N が存在しない場合のみ実行（Nは現在ターン数）
    const turnKey = `turnExecuted_${match.currentTurn}`;
    try {
        await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.UpdateCommand({
            TableName: dynamo_client_1.MATCHES_TABLE,
            Key: { matchId: match.matchId },
            UpdateExpression: `SET ${turnKey} = :true`,
            ConditionExpression: `attribute_not_exists(${turnKey})`,
            ExpressionAttributeValues: { ':true': true },
        }));
    }
    catch (error) {
        if (error instanceof client_dynamodb_1.ConditionalCheckFailedException) {
            // Already executed by another Lambda invocation - skip
            return;
        }
        throw error;
    }
    // Execute turn logic
    const turnResult = (0, turn_engine_1.executeTurnLogic)(match);
    // Update match state
    const updateExpr = turnResult.battleEnd
        ? 'SET #s = :status, currentTurn = :turn, battleState = :state, player1Action = :null, player2Action = :null, winnerId = :winner, finishReason = :reason, finishedAt = :now'
        : 'SET currentTurn = :turn, battleState = :state, player1Action = :null, player2Action = :null, turnStartedAt = :now';
    const exprValues = {
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
    await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.UpdateCommand({
        TableName: dynamo_client_1.MATCHES_TABLE,
        Key: { matchId: match.matchId },
        UpdateExpression: updateExpr,
        ...(turnResult.battleEnd ? { ExpressionAttributeNames: { '#s': 'status' } } : {}),
        ExpressionAttributeValues: exprValues,
    }));
    // Send results to both players
    const p1Conn = await (0, connection_1.getConnectionByUserId)(match.player1Id);
    const p2Conn = await (0, connection_1.getConnectionByUserId)(match.player2Id);
    const msgType = turnResult.battleEnd ? 'battleEnd' : 'turnResult';
    const msg = { type: msgType, data: turnResult };
    if (p1Conn)
        await (0, ws_client_1.sendToConnection)(p1Conn.connectionId, msg);
    if (p2Conn)
        await (0, ws_client_1.sendToConnection)(p2Conn.connectionId, msg);
    // Battle end: update rankings and save history
    if (turnResult.battleEnd) {
        const now = new Date().toISOString();
        const winnerId = turnResult.winnerId;
        const loserId = winnerId === match.player1Id ? match.player2Id : match.player1Id;
        // Upsert rankings (ADD creates item if not exists)
        if (winnerId) {
            await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.UpdateCommand({
                TableName: dynamo_client_1.RANKINGS_TABLE,
                Key: { userId: winnerId },
                UpdateExpression: 'ADD wins :one, points :winPts SET #p = if_not_exists(#p, :defaultPartition), lastBattleAt = :now',
                ExpressionAttributeNames: { '#p': 'partition' },
                ExpressionAttributeValues: { ':one': 1, ':winPts': 25, ':defaultPartition': 'GLOBAL', ':now': now },
            }));
            await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.UpdateCommand({
                TableName: dynamo_client_1.RANKINGS_TABLE,
                Key: { userId: loserId },
                UpdateExpression: 'ADD losses :one, points :losePts SET #p = if_not_exists(#p, :defaultPartition), lastBattleAt = :now',
                ExpressionAttributeNames: { '#p': 'partition' },
                ExpressionAttributeValues: { ':one': 1, ':losePts': -15, ':defaultPartition': 'GLOBAL', ':now': now },
            }));
        }
        // Save battle history for both players
        await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.PutCommand({
            TableName: dynamo_client_1.BATTLE_HISTORY_TABLE,
            Item: {
                compositeId: `${match.player1Id}#${match.matchId}`,
                matchId: match.matchId, userId: match.player1Id, opponentId: match.player2Id,
                result: winnerId === match.player1Id ? 'WIN' : winnerId ? 'LOSE' : 'DRAW',
                pointChange: winnerId === match.player1Id ? 25 : winnerId ? -15 : 0,
                totalTurns: match.currentTurn, finishReason: turnResult.finishReason, playedAt: now,
            },
        }));
        await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.PutCommand({
            TableName: dynamo_client_1.BATTLE_HISTORY_TABLE,
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
async function getMatch(matchId) {
    const result = await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.GetCommand({
        TableName: dynamo_client_1.MATCHES_TABLE,
        Key: { matchId },
    }));
    return result.Item;
}
