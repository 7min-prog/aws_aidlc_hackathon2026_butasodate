"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleCancelMatch = exports.handleRequestMatch = void 0;
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const dynamo_client_1 = require("../utils/dynamo-client");
const ws_client_1 = require("../utils/ws-client");
const auth_1 = require("../utils/auth");
const response_1 = require("../utils/response");
const ulid_1 = require("../utils/ulid");
const handleRequestMatch = async (connectionId, data) => {
    const userId = await (0, auth_1.getUserIdFromConnection)(connectionId);
    if (!userId)
        return (0, response_1.successResponse)(401);
    if (data.type === 'friend' && data.targetId) {
        return handleFriendInvite(connectionId, userId, data.targetId);
    }
    // Add to match queue
    await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.PutCommand({
        TableName: dynamo_client_1.MATCH_QUEUE_TABLE,
        Item: {
            userId,
            connectionId,
            level: data.level || 1,
            queuedAt: new Date().toISOString(),
        },
    }));
    // Try to find a match (level ±5)
    const playerLevel = data.level || 1;
    const result = await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.ScanCommand({
        TableName: dynamo_client_1.MATCH_QUEUE_TABLE,
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
        await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.DeleteCommand({ TableName: dynamo_client_1.MATCH_QUEUE_TABLE, Key: { userId } }));
        await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.DeleteCommand({ TableName: dynamo_client_1.MATCH_QUEUE_TABLE, Key: { userId: opponent.userId } }));
    }
    return (0, response_1.successResponse)(200);
};
exports.handleRequestMatch = handleRequestMatch;
const handleCancelMatch = async (connectionId) => {
    const userId = await (0, auth_1.getUserIdFromConnection)(connectionId);
    if (!userId)
        return (0, response_1.successResponse)(401);
    await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.DeleteCommand({
        TableName: dynamo_client_1.MATCH_QUEUE_TABLE,
        Key: { userId },
    }));
    return (0, response_1.successResponse)(200);
};
exports.handleCancelMatch = handleCancelMatch;
async function handleFriendInvite(connectionId, userId, targetId) {
    const matchId = (0, ulid_1.ulid)();
    // Create match in PREPARING state
    await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.PutCommand({
        TableName: dynamo_client_1.MATCHES_TABLE,
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
    const { getConnectionByUserId } = await Promise.resolve().then(() => __importStar(require('./connection')));
    const targetConn = await getConnectionByUserId(targetId);
    if (targetConn) {
        await (0, ws_client_1.sendToConnection)(targetConn.connectionId, {
            type: 'friendInvite',
            data: { matchId, fromUserId: userId },
        });
    }
    return (0, response_1.successResponse)(200);
}
async function createMatch(player1Id, conn1Id, player2Id, conn2Id) {
    const matchId = (0, ulid_1.ulid)();
    await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.PutCommand({
        TableName: dynamo_client_1.MATCHES_TABLE,
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
    await (0, ws_client_1.sendToConnection)(conn1Id, matchData);
    await (0, ws_client_1.sendToConnection)(conn2Id, matchData);
}
