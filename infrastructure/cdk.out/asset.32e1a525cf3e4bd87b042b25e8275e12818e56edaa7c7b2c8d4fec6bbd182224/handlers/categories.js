"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = handler;
const dynamo_client_1 = require("../utils/dynamo-client");
const auth_1 = require("../utils/auth");
const response_1 = require("../utils/response");
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const CATEGORY_TABLE = process.env.ACTIVITY_CATEGORY_TABLE;
async function handler(event) {
    try {
        (0, auth_1.getUserId)(event); // auth check
        const path = event.resource;
        if (path === '/categories/version') {
            const result = await dynamo_client_1.docClient.send(new lib_dynamodb_1.GetCommand({
                TableName: CATEGORY_TABLE,
                Key: { categoryId: '_meta' },
            }));
            return (0, response_1.success)({ version: result.Item?.version || 1 });
        }
        // GET /categories
        const result = await dynamo_client_1.docClient.send(new lib_dynamodb_1.ScanCommand({
            TableName: CATEGORY_TABLE,
            FilterExpression: 'isActive = :t AND categoryId <> :meta',
            ExpressionAttributeValues: { ':t': true, ':meta': '_meta' },
        }));
        const items = (result.Items || []).sort((a, b) => (a.sortOrder || 0) - (b.sortOrder || 0));
        const version = (await dynamo_client_1.docClient.send(new lib_dynamodb_1.GetCommand({
            TableName: CATEGORY_TABLE,
            Key: { categoryId: '_meta' },
        }))).Item?.version || 1;
        return (0, response_1.success)({ categories: items, version });
    }
    catch (err) {
        console.error(err);
        if (err.message === 'Unauthorized')
            return (0, response_1.error)('Unauthorized', 401);
        return (0, response_1.error)('Internal Server Error', 500);
    }
}
//# sourceMappingURL=categories.js.map