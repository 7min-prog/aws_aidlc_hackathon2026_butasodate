"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.writeAuditLog = writeAuditLog;
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const dynamo_client_1 = require("./dynamo-client");
async function writeAuditLog(operator, action, target, detail) {
    const timestamp = new Date().toISOString();
    const logId = `${timestamp}-${Math.random().toString(36).slice(2, 10)}`;
    await dynamo_client_1.docClient.send(new lib_dynamodb_1.PutCommand({
        TableName: dynamo_client_1.AUDIT_LOG_TABLE,
        Item: { logId, timestamp, operator, action, target, detail: detail || {} },
    }));
}
//# sourceMappingURL=audit-log.js.map