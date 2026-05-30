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
exports.handler = void 0;
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const lib_dynamodb_2 = require("@aws-sdk/lib-dynamodb");
const client_dynamodb_1 = require("@aws-sdk/client-dynamodb");
const response_1 = require("./utils/response");
const ulid_1 = require("./utils/ulid");
const client = lib_dynamodb_2.DynamoDBDocumentClient.from(new client_dynamodb_1.DynamoDBClient({ region: 'ap-northeast-1' }));
const FRIENDS_TABLE = process.env.FRIENDS_TABLE || 'buta-friends-dev';
const FRIEND_REQUESTS_TABLE = process.env.FRIEND_REQUESTS_TABLE || 'buta-friend-requests-dev';
const RANKINGS_TABLE = process.env.RANKINGS_TABLE || 'buta-rankings-dev';
const BATTLE_HISTORY_TABLE = process.env.BATTLE_HISTORY_TABLE || 'buta-battle-history-dev';
const USER_PROFILES_TABLE = process.env.USER_PROFILES_TABLE || 'butasodate-user-profiles';
function getUserId(event) {
    return event.requestContext.authorizer?.claims?.sub || null;
}
const handler = async (event) => {
    const { httpMethod, path } = event;
    const route = `${httpMethod} ${path}`;
    try {
        if (route === 'GET /social/friends')
            return getFriends(event);
        if (route === 'POST /social/friends/search')
            return searchUsers(event);
        if (route === 'POST /social/friends/request')
            return sendFriendRequest(event);
        if (route === 'POST /social/friends/respond')
            return respondFriendRequest(event);
        if (route.startsWith('DELETE /social/friends/'))
            return removeFriend(event);
        if (route === 'GET /social/friends/requests')
            return getPendingRequests(event);
        if (route === 'GET /rankings')
            return getRankings(event);
        if (route === 'GET /rankings/me')
            return getMyRanking(event);
        if (route === 'GET /battles/history')
            return getBattleHistory(event);
        if (route.startsWith('GET /battles/history/'))
            return getBattleDetail(event);
        return (0, response_1.errorResponse)(404, 'Not Found');
    }
    catch (error) {
        console.error('Error:', error);
        return (0, response_1.errorResponse)(500, 'Internal Server Error');
    }
};
exports.handler = handler;
async function getFriends(event) {
    const userId = getUserId(event);
    if (!userId)
        return (0, response_1.errorResponse)(401, 'Unauthorized');
    const result = await client.send(new lib_dynamodb_1.QueryCommand({
        TableName: FRIENDS_TABLE,
        IndexName: 'userId-index',
        KeyConditionExpression: 'userId = :uid',
        ExpressionAttributeValues: { ':uid': userId },
    }));
    return (0, response_1.successResponse)(200, { friends: result.Items || [] });
}
async function searchUsers(event) {
    const { query } = JSON.parse(event.body || '{}');
    if (!query)
        return (0, response_1.errorResponse)(400, 'query is required');
    const result = await client.send(new lib_dynamodb_1.QueryCommand({
        TableName: USER_PROFILES_TABLE,
        IndexName: 'nickname-index',
        KeyConditionExpression: 'nickname = :n',
        ExpressionAttributeValues: { ':n': query },
    }));
    return (0, response_1.successResponse)(200, { users: result.Items || [] });
}
async function sendFriendRequest(event) {
    const userId = getUserId(event);
    if (!userId)
        return (0, response_1.errorResponse)(401, 'Unauthorized');
    const { targetUserId } = JSON.parse(event.body || '{}');
    if (!targetUserId)
        return (0, response_1.errorResponse)(400, 'targetUserId is required');
    await client.send(new lib_dynamodb_1.PutCommand({
        TableName: FRIEND_REQUESTS_TABLE,
        Item: {
            requestId: (0, ulid_1.ulid)(),
            fromUserId: userId,
            toUserId: targetUserId,
            status: 'PENDING',
            createdAt: new Date().toISOString(),
        },
    }));
    return (0, response_1.successResponse)(201, { message: 'Friend request sent' });
}
async function respondFriendRequest(event) {
    const userId = getUserId(event);
    if (!userId)
        return (0, response_1.errorResponse)(401, 'Unauthorized');
    const { requestId, accept } = JSON.parse(event.body || '{}');
    if (!requestId)
        return (0, response_1.errorResponse)(400, 'requestId is required');
    const req = await client.send(new lib_dynamodb_1.GetCommand({
        TableName: FRIEND_REQUESTS_TABLE,
        Key: { requestId },
    }));
    if (!req.Item || req.Item.toUserId !== userId)
        return (0, response_1.errorResponse)(404, 'Request not found');
    if (accept) {
        // Create bidirectional friend relationship
        const now = new Date().toISOString();
        await client.send(new lib_dynamodb_1.PutCommand({
            TableName: FRIENDS_TABLE,
            Item: { compositeId: `${userId}#${req.Item.fromUserId}`, userId, friendId: req.Item.fromUserId, createdAt: now },
        }));
        await client.send(new lib_dynamodb_1.PutCommand({
            TableName: FRIENDS_TABLE,
            Item: { compositeId: `${req.Item.fromUserId}#${userId}`, userId: req.Item.fromUserId, friendId: userId, createdAt: now },
        }));
    }
    // Update request status
    const { UpdateCommand } = await Promise.resolve().then(() => __importStar(require('@aws-sdk/lib-dynamodb')));
    await client.send(new UpdateCommand({
        TableName: FRIEND_REQUESTS_TABLE,
        Key: { requestId },
        UpdateExpression: 'SET #s = :status, updatedAt = :now',
        ExpressionAttributeNames: { '#s': 'status' },
        ExpressionAttributeValues: { ':status': accept ? 'ACCEPTED' : 'DECLINED', ':now': new Date().toISOString() },
    }));
    return (0, response_1.successResponse)(200, { message: accept ? 'Friend added' : 'Request rejected' });
}
async function removeFriend(event) {
    const userId = getUserId(event);
    if (!userId)
        return (0, response_1.errorResponse)(401, 'Unauthorized');
    const friendId = event.pathParameters?.id;
    if (!friendId)
        return (0, response_1.errorResponse)(400, 'friendId is required');
    await client.send(new lib_dynamodb_1.DeleteCommand({ TableName: FRIENDS_TABLE, Key: { compositeId: `${userId}#${friendId}` } }));
    await client.send(new lib_dynamodb_1.DeleteCommand({ TableName: FRIENDS_TABLE, Key: { compositeId: `${friendId}#${userId}` } }));
    return (0, response_1.successResponse)(200, { message: 'Friend removed' });
}
async function getPendingRequests(event) {
    const userId = getUserId(event);
    if (!userId)
        return (0, response_1.errorResponse)(401, 'Unauthorized');
    const result = await client.send(new lib_dynamodb_1.QueryCommand({
        TableName: FRIEND_REQUESTS_TABLE,
        IndexName: 'toUserId-index',
        KeyConditionExpression: 'toUserId = :uid',
        FilterExpression: '#s = :pending',
        ExpressionAttributeNames: { '#s': 'status' },
        ExpressionAttributeValues: { ':uid': userId, ':pending': 'PENDING' },
    }));
    return (0, response_1.successResponse)(200, { requests: result.Items || [] });
}
async function getRankings(_event) {
    const result = await client.send(new lib_dynamodb_1.ScanCommand({
        TableName: RANKINGS_TABLE,
        Limit: 100,
    }));
    const sorted = (result.Items || []).sort((a, b) => (b.points || 0) - (a.points || 0));
    return (0, response_1.successResponse)(200, { rankings: sorted });
}
async function getMyRanking(event) {
    const userId = getUserId(event);
    if (!userId)
        return (0, response_1.errorResponse)(401, 'Unauthorized');
    const result = await client.send(new lib_dynamodb_1.GetCommand({
        TableName: RANKINGS_TABLE,
        Key: { userId },
    }));
    return (0, response_1.successResponse)(200, { ranking: result.Item || { userId, points: 0, wins: 0, losses: 0 } });
}
async function getBattleHistory(event) {
    const userId = getUserId(event);
    if (!userId)
        return (0, response_1.errorResponse)(401, 'Unauthorized');
    const result = await client.send(new lib_dynamodb_1.QueryCommand({
        TableName: BATTLE_HISTORY_TABLE,
        IndexName: 'userId-index',
        KeyConditionExpression: 'userId = :uid',
        ScanIndexForward: false,
        Limit: 50,
        ExpressionAttributeValues: { ':uid': userId },
    }));
    return (0, response_1.successResponse)(200, { history: result.Items || [] });
}
async function getBattleDetail(event) {
    const userId = getUserId(event);
    if (!userId)
        return (0, response_1.errorResponse)(401, 'Unauthorized');
    const matchId = event.pathParameters?.id;
    if (!matchId)
        return (0, response_1.errorResponse)(400, 'matchId is required');
    const result = await client.send(new lib_dynamodb_1.GetCommand({
        TableName: BATTLE_HISTORY_TABLE,
        Key: { compositeId: `${userId}#${matchId}` },
    }));
    if (!result.Item)
        return (0, response_1.errorResponse)(404, 'Battle not found');
    return (0, response_1.successResponse)(200, result.Item);
}
