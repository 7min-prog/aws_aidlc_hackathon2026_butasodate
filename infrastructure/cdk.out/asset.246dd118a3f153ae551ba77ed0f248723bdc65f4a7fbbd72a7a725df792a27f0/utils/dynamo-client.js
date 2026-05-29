"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ACTIVITY_RECORD_TABLE = exports.USER_PROFILES_TABLE = exports.GAME_CONFIG_TABLE = exports.AUDIT_LOG_TABLE = exports.SKILL_TABLE = exports.EVOLUTION_ROUTE_TABLE = exports.PIG_SPECIES_TABLE = exports.AVATAR_TABLE = exports.docClient = void 0;
const client_dynamodb_1 = require("@aws-sdk/client-dynamodb");
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const client = new client_dynamodb_1.DynamoDBClient({});
exports.docClient = lib_dynamodb_1.DynamoDBDocumentClient.from(client, {
    marshallOptions: { removeUndefinedValues: true },
});
exports.AVATAR_TABLE = process.env.AVATAR_TABLE_NAME;
exports.PIG_SPECIES_TABLE = process.env.PIG_SPECIES_TABLE_NAME;
exports.EVOLUTION_ROUTE_TABLE = process.env.EVOLUTION_ROUTE_TABLE_NAME;
exports.SKILL_TABLE = process.env.SKILL_TABLE_NAME;
exports.AUDIT_LOG_TABLE = process.env.AUDIT_LOG_TABLE_NAME;
exports.GAME_CONFIG_TABLE = process.env.GAME_CONFIG_TABLE_NAME;
exports.USER_PROFILES_TABLE = process.env.USER_PROFILES_TABLE_NAME;
exports.ACTIVITY_RECORD_TABLE = process.env.ACTIVITY_RECORD_TABLE_NAME;
//# sourceMappingURL=dynamo-client.js.map