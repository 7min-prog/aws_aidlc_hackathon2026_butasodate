"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.USERS_TABLE = exports.dynamoClient = void 0;
const client_dynamodb_1 = require("@aws-sdk/client-dynamodb");
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const client = new client_dynamodb_1.DynamoDBClient({
    region: process.env.AWS_REGION || 'ap-northeast-1',
});
exports.dynamoClient = lib_dynamodb_1.DynamoDBDocumentClient.from(client);
exports.USERS_TABLE = process.env.USER_PROFILES_TABLE_NAME || 'butasodate-user-profiles';
