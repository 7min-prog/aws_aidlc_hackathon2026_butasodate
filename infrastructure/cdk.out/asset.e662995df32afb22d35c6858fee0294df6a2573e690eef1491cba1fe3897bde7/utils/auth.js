"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getUserIdFromConnection = getUserIdFromConnection;
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const dynamo_client_1 = require("./dynamo-client");
async function getUserIdFromConnection(connectionId) {
    const result = await dynamo_client_1.dynamoClient.send(new lib_dynamodb_1.QueryCommand({
        TableName: dynamo_client_1.CONNECTIONS_TABLE,
        KeyConditionExpression: 'connectionId = :cid',
        ExpressionAttributeValues: { ':cid': connectionId },
    }));
    return result.Items?.[0]?.userId || null;
}
