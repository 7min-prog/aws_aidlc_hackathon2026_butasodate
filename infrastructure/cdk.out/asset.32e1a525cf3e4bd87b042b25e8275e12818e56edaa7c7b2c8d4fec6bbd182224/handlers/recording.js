"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = handler;
const dynamo_client_1 = require("../utils/dynamo-client");
const auth_1 = require("../utils/auth");
const response_1 = require("../utils/response");
const recording_service_1 = require("../services/recording-service");
const service = new recording_service_1.RecordingService(dynamo_client_1.docClient);
async function handler(event) {
    try {
        const userId = (0, auth_1.getUserId)(event);
        const method = event.httpMethod;
        const path = event.resource;
        if (method === 'POST' && path === '/activities') {
            const body = JSON.parse(event.body || '{}');
            // OpenAPI: records[] array - single or batch
            const records = body.records || [body];
            if (records.length === 1) {
                const result = await service.createRecord(userId, records[0]);
                return (0, response_1.success)({ avatar: result.avatarStatus, leveledUp: false, evolved: false, newSkills: [], skippedIds: [] }, 201);
            }
            const result = await service.batchCreateRecords(userId, records);
            return (0, response_1.success)({ avatar: result.avatarStatus, leveledUp: false, evolved: false, newSkills: [], skippedIds: result.skippedIds }, 201);
        }
        if (method === 'POST' && path === '/activities/batch') {
            const body = JSON.parse(event.body || '{}');
            const result = await service.batchCreateRecords(userId, body.records || []);
            return (0, response_1.success)({ avatar: result.avatarStatus, leveledUp: false, evolved: false, newSkills: [], skippedIds: result.skippedIds });
        }
        if (method === 'GET' && path === '/activities') {
            const params = event.queryStringParameters || {};
            const result = await service.getRecords(userId, parseInt(params.limit || '20'), params.cursor || undefined, params.categoryId || undefined, params.from || undefined, params.to || undefined);
            return (0, response_1.success)(result);
        }
        if (method === 'DELETE' && path === '/activities/{recordId}') {
            const recordId = event.pathParameters?.recordId;
            if (!recordId)
                return (0, response_1.error)('recordId required', 400);
            const result = await service.deleteAutoDetectedRecord(userId, recordId);
            return (0, response_1.success)(result);
        }
        if (method === 'GET' && path === '/activities/summary') {
            const period = (event.queryStringParameters?.period || 'today');
            const result = await service.getSummary(userId, period);
            return (0, response_1.success)(result);
        }
        return (0, response_1.error)('Not Found', 404);
    }
    catch (err) {
        console.error(err);
        if (err.message === 'Unauthorized')
            return (0, response_1.error)('Unauthorized', 401);
        if (err.message === 'Record not found')
            return (0, response_1.error)('Record not found', 404);
        if (err.message === 'Only auto-detected records can be deleted')
            return (0, response_1.error)(err.message, 403);
        return (0, response_1.error)('Internal Server Error', 500);
    }
}
//# sourceMappingURL=recording.js.map