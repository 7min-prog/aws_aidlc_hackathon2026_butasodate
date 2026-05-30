"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = handler;
const dynamo_client_1 = require("../utils/dynamo-client");
const auth_1 = require("../utils/auth");
const response_1 = require("../utils/response");
const health_sync_service_1 = require("../services/health-sync-service");
const service = new health_sync_service_1.HealthSyncService(dynamo_client_1.docClient);
async function handler(event) {
    try {
        const userId = (0, auth_1.getUserId)(event);
        const body = JSON.parse(event.body || '{}');
        const result = await service.syncHealthData(userId, body.records || []);
        return (0, response_1.success)(result);
    }
    catch (err) {
        console.error(err);
        if (err.message === 'Unauthorized')
            return (0, response_1.error)('Unauthorized', 401);
        return (0, response_1.error)('Internal Server Error', 500);
    }
}
//# sourceMappingURL=health-sync.js.map