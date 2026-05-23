"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleSetReady = exports.handleRespondInvite = void 0;
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const dynamo_client_1 = require("../utils/dynamo-client");
const ws_client_1 = require("../utils/ws-client");
const auth_1 = require("../utils/auth");
const connection_1 = require("./connection");
const response_1 = require("../utils/response");
const handleRespondInvite = async (connectionId, data) => {
    const userId = await (0, auth_1.getUserIdFromConnection)(connectionId);
    if (!userId)
        return (0, response_1.successResponse)(401);
    if (!data.accept) {
        // Reject - notify inviter
        const match = await getMatch(data.matchId);
        if (match) {
            const inviterConn = await (0, connection_1.getConnectionByUserId)(match.player1Id);
            if (inviterConn) {
                await (0, ws_client_1.sendToConnection)(inviterConn.connectionId, {
                    type: 'inviteRejected',
                    data: { matchId: data.matchId },
                });
            }
        }
        return (0, response_1.successResponse)(200);
    }
    // Accept - update match status
    await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.UpdateCommand({
        TableName: dynamo_client_1.MATCHES_TABLE,
        Key: { matchId: data.matchId },
        UpdateExpression: 'SET #s = :status',
        ExpressionAttributeNames: { '#s': 'status' },
        ExpressionAttributeValues: { ':status': 'PREPARING' },
    }));
    // Notify both players
    const match = await getMatch(data.matchId);
    if (match) {
        const p1Conn = await (0, connection_1.getConnectionByUserId)(match.player1Id);
        const p2Conn = await (0, connection_1.getConnectionByUserId)(match.player2Id);
        const msg = { type: 'battleStart', data: { matchId: data.matchId } };
        if (p1Conn)
            await (0, ws_client_1.sendToConnection)(p1Conn.connectionId, msg);
        if (p2Conn)
            await (0, ws_client_1.sendToConnection)(p2Conn.connectionId, msg);
    }
    return (0, response_1.successResponse)(200);
};
exports.handleRespondInvite = handleRespondInvite;
const handleSetReady = async (connectionId, data) => {
    const userId = await (0, auth_1.getUserIdFromConnection)(connectionId);
    if (!userId)
        return (0, response_1.successResponse)(401);
    const match = await getMatch(data.matchId);
    if (!match)
        return (0, response_1.successResponse)(404);
    const playerKey = match.player1Id === userId ? 'player1Ready' : 'player2Ready';
    await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.UpdateCommand({
        TableName: dynamo_client_1.MATCHES_TABLE,
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
        await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.UpdateCommand({
            TableName: dynamo_client_1.MATCHES_TABLE,
            Key: { matchId: data.matchId },
            UpdateExpression: 'SET #s = :status, currentTurn = :turn, startedAt = :now, turnStartedAt = :now',
            ExpressionAttributeNames: { '#s': 'status' },
            ExpressionAttributeValues: {
                ':status': 'IN_PROGRESS',
                ':turn': 1,
                ':now': new Date().toISOString(),
            },
        }));
        const p1Conn = await (0, connection_1.getConnectionByUserId)(updated.player1Id);
        const p2Conn = await (0, connection_1.getConnectionByUserId)(updated.player2Id);
        const msg = { type: 'battleStart', data: { matchId: data.matchId, turn: 1 } };
        if (p1Conn)
            await (0, ws_client_1.sendToConnection)(p1Conn.connectionId, msg);
        if (p2Conn)
            await (0, ws_client_1.sendToConnection)(p2Conn.connectionId, msg);
    }
    return (0, response_1.successResponse)(200);
};
exports.handleSetReady = handleSetReady;
async function getMatch(matchId) {
    const result = await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.GetCommand({
        TableName: dynamo_client_1.MATCHES_TABLE,
        Key: { matchId },
    }));
    return result.Item;
}
