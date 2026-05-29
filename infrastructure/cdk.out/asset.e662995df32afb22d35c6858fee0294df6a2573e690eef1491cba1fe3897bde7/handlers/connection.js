"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleDisconnect = exports.handleConnect = void 0;
exports.getConnectionByUserId = getConnectionByUserId;
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const dynamo_client_1 = require("../utils/dynamo-client");
const ws_client_1 = require("../utils/ws-client");
const response_1 = require("../utils/response");
const handleConnect = async (event) => {
    const connectionId = event.requestContext.connectionId;
    const token = event.queryStringParameters?.token;
    if (!token) {
        return (0, response_1.errorResponse)(401, 'Token required');
    }
    // TODO: Cognitoトークン検証（デモではuserIdをクエリパラメータから取得）
    const userId = event.queryStringParameters?.userId;
    if (!userId) {
        return (0, response_1.errorResponse)(401, 'userId required');
    }
    await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.PutCommand({
        TableName: dynamo_client_1.CONNECTIONS_TABLE,
        Item: {
            connectionId,
            userId,
            connectedAt: new Date().toISOString(),
        },
    }));
    return (0, response_1.successResponse)(200);
};
exports.handleConnect = handleConnect;
const handleDisconnect = async (connectionId) => {
    // Get userId from connection
    const conn = await getConnectionByConnectionId(connectionId);
    // Delete connection record
    await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.DeleteCommand({
        TableName: dynamo_client_1.CONNECTIONS_TABLE,
        Key: { connectionId },
    }));
    // If in active battle, auto-lose
    if (conn?.userId) {
        await handleBattleDisconnect(conn.userId, connectionId);
    }
    return (0, response_1.successResponse)(200);
};
exports.handleDisconnect = handleDisconnect;
async function getConnectionByConnectionId(connectionId) {
    const result = await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.QueryCommand({
        TableName: dynamo_client_1.CONNECTIONS_TABLE,
        KeyConditionExpression: 'connectionId = :cid',
        ExpressionAttributeValues: { ':cid': connectionId },
    }));
    return result.Items?.[0];
}
async function handleBattleDisconnect(userId, _connectionId) {
    // Find active match for this user
    // For simplicity, we scan matches with status IN_PROGRESS
    // In production, use a GSI on userId
    const result = await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.QueryCommand({
        TableName: dynamo_client_1.MATCHES_TABLE,
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
            await (0, ws_client_1.sendToConnection)(opponentConn.connectionId, {
                type: 'opponentDisconnected',
                data: { matchId: match.matchId },
            });
        }
    }
}
async function getConnectionByUserId(userId) {
    const result = await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.QueryCommand({
        TableName: dynamo_client_1.CONNECTIONS_TABLE,
        IndexName: 'userId-index',
        KeyConditionExpression: 'userId = :uid',
        ExpressionAttributeValues: { ':uid': userId },
    }));
    return result.Items?.[0];
}
