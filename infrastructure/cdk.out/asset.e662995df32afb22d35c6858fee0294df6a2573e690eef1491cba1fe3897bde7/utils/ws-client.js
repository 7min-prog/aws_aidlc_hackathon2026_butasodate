"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendToConnection = sendToConnection;
const client_apigatewaymanagementapi_1 = require("@aws-sdk/client-apigatewaymanagementapi");
const ENDPOINT = process.env.WEBSOCKET_ENDPOINT || '';
const wsClient = new client_apigatewaymanagementapi_1.ApiGatewayManagementApiClient({
    region: 'ap-northeast-1',
    endpoint: ENDPOINT,
});
async function sendToConnection(connectionId, data) {
    try {
        await wsClient.send(new client_apigatewaymanagementapi_1.PostToConnectionCommand({
            ConnectionId: connectionId,
            Data: Buffer.from(JSON.stringify(data)),
        }));
    }
    catch (error) {
        if (error.statusCode === 410) {
            // Connection is gone - ignore
            console.log(`Connection ${connectionId} is stale`);
        }
        else {
            throw error;
        }
    }
}
