"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleUpdateProfile = exports.handleCreateProfile = exports.handleGetProfile = void 0;
const dynamo_client_1 = require("../utils/dynamo-client");
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const response_1 = require("../utils/response");
function getUserId(event) {
    return event.requestContext.authorizer?.claims?.sub || null;
}
const handleGetProfile = async (event) => {
    const userId = getUserId(event);
    if (!userId)
        return (0, response_1.errorResponse)(401, 'Unauthorized');
    try {
        const result = await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.GetCommand({
            TableName: dynamo_client_1.USERS_TABLE,
            Key: { userId },
        }));
        if (!result.Item) {
            return (0, response_1.errorResponse)(404, 'Profile not found');
        }
        return (0, response_1.successResponse)(200, result.Item);
    }
    catch (error) {
        console.error('GetProfile error:', error);
        return (0, response_1.errorResponse)(500, 'Internal Server Error');
    }
};
exports.handleGetProfile = handleGetProfile;
const handleCreateProfile = async (event) => {
    const userId = getUserId(event);
    if (!userId)
        return (0, response_1.errorResponse)(401, 'Unauthorized');
    const { nickname } = JSON.parse(event.body || '{}');
    if (!nickname || nickname.length < 2 || nickname.length > 10) {
        return (0, response_1.errorResponse)(400, 'nickname must be 2-10 characters');
    }
    try {
        // Check nickname uniqueness
        const existing = await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.QueryCommand({
            TableName: dynamo_client_1.USERS_TABLE,
            IndexName: 'nickname-index',
            KeyConditionExpression: 'nickname = :n',
            ExpressionAttributeValues: { ':n': nickname },
        }));
        if (existing.Items && existing.Items.length > 0) {
            return (0, response_1.errorResponse)(409, 'This nickname is already taken');
        }
        const now = new Date().toISOString();
        const claims = event.requestContext.authorizer?.claims;
        await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.PutCommand({
            TableName: dynamo_client_1.USERS_TABLE,
            Item: {
                userId,
                email: claims?.email || '',
                nickname,
                authProvider: 'EMAIL',
                linkedProviders: [],
                createdAt: now,
                updatedAt: now,
                lastLoginAt: now,
            },
        }));
        return (0, response_1.successResponse)(201, { message: 'Profile created', nickname });
    }
    catch (error) {
        console.error('CreateProfile error:', error);
        return (0, response_1.errorResponse)(500, 'Internal Server Error');
    }
};
exports.handleCreateProfile = handleCreateProfile;
const handleUpdateProfile = async (event) => {
    const userId = getUserId(event);
    if (!userId)
        return (0, response_1.errorResponse)(401, 'Unauthorized');
    const { nickname } = JSON.parse(event.body || '{}');
    if (!nickname || nickname.length < 2 || nickname.length > 10) {
        return (0, response_1.errorResponse)(400, 'nickname must be 2-10 characters');
    }
    try {
        // Check nickname uniqueness (exclude self)
        const existing = await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.QueryCommand({
            TableName: dynamo_client_1.USERS_TABLE,
            IndexName: 'nickname-index',
            KeyConditionExpression: 'nickname = :n',
            ExpressionAttributeValues: { ':n': nickname },
        }));
        if (existing.Items && existing.Items.some(item => item.userId !== userId)) {
            return (0, response_1.errorResponse)(409, 'This nickname is already taken');
        }
        await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.UpdateCommand({
            TableName: dynamo_client_1.USERS_TABLE,
            Key: { userId },
            UpdateExpression: 'SET nickname = :n, updatedAt = :now',
            ExpressionAttributeValues: {
                ':n': nickname,
                ':now': new Date().toISOString(),
            },
        }));
        return (0, response_1.successResponse)(200, { message: 'Profile updated', nickname });
    }
    catch (error) {
        console.error('UpdateProfile error:', error);
        return (0, response_1.errorResponse)(500, 'Internal Server Error');
    }
};
exports.handleUpdateProfile = handleUpdateProfile;
