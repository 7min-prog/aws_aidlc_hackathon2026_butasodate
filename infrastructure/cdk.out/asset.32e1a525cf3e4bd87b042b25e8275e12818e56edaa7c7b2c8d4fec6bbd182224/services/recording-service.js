"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RecordingService = void 0;
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const types_1 = require("../types");
const point_calculator_1 = require("./point-calculator");
const avatar_connector_1 = require("../connectors/avatar-connector");
const crypto_1 = require("crypto");
const TABLE_NAME = process.env.ACTIVITY_RECORD_TABLE;
const CATEGORY_TABLE = process.env.ACTIVITY_CATEGORY_TABLE;
class RecordingService {
    client;
    constructor(client) {
        this.client = client;
    }
    async createRecord(userId, req) {
        const recordId = req.recordId || (0, crypto_1.randomUUID)();
        const category = await this.getCategory(req.categoryId);
        if (!category)
            throw new Error('Category not found');
        const points = (0, point_calculator_1.calculateManualPoints)(category.type);
        const now = new Date().toISOString();
        const recordedAt = req.recordedAt || now;
        const record = {
            recordId,
            userId,
            categoryId: req.categoryId,
            source: types_1.RecordSource.MANUAL,
            points,
            memo: req.memo,
            recordedAt,
            createdAt: now,
        };
        await this.client.send(new lib_dynamodb_1.TransactWriteCommand({
            TransactItems: [
                {
                    Put: {
                        TableName: TABLE_NAME,
                        Item: { ...record, sk: `${recordedAt}#${recordId}`, gsi1sk: `${req.categoryId}#${recordedAt}` },
                        ConditionExpression: 'attribute_not_exists(userId)',
                    },
                },
            ],
        }));
        const avatarStatus = await (0, avatar_connector_1.addPoints)(userId, points, category.type);
        return { record, avatarStatus };
    }
    async batchCreateRecords(userId, requests) {
        const syncedRecords = [];
        const skippedIds = [];
        let totalPoints = 0;
        for (const req of requests) {
            const recordId = req.recordId || (0, crypto_1.randomUUID)();
            const existing = await this.recordExists(userId, recordId);
            if (existing) {
                skippedIds.push(recordId);
                continue;
            }
            const category = await this.getCategory(req.categoryId);
            if (!category)
                continue;
            const points = (0, point_calculator_1.calculateManualPoints)(category.type);
            const now = new Date().toISOString();
            const recordedAt = req.recordedAt || now;
            const record = {
                recordId, userId, categoryId: req.categoryId,
                source: types_1.RecordSource.MANUAL, points, memo: req.memo,
                recordedAt, createdAt: now,
            };
            await this.client.send(new lib_dynamodb_1.PutCommand({
                TableName: TABLE_NAME,
                Item: { ...record, sk: `${recordedAt}#${recordId}`, gsi1sk: `${req.categoryId}#${recordedAt}` },
            }));
            syncedRecords.push(record);
            totalPoints += points;
        }
        const avatarStatus = totalPoints > 0 ? await (0, avatar_connector_1.addPoints)(userId, totalPoints, types_1.CategoryType.FOOD) : { totalPoints: 0, level: 1 };
        return { syncedRecords, skippedIds, avatarStatus };
    }
    async getRecords(userId, limit, cursor, categoryId, from, to) {
        const params = {
            TableName: TABLE_NAME,
            KeyConditionExpression: 'userId = :uid',
            ExpressionAttributeValues: { ':uid': userId },
            Limit: limit,
            ScanIndexForward: false,
        };
        if (cursor) {
            params.ExclusiveStartKey = JSON.parse(Buffer.from(cursor, 'base64').toString());
        }
        if (categoryId) {
            params.IndexName = 'category-index';
            params.KeyConditionExpression = 'userId = :uid AND begins_with(gsi1sk, :catPrefix)';
            params.ExpressionAttributeValues[':catPrefix'] = `${categoryId}#`;
        }
        if (from || to) {
            const filters = [];
            if (from) {
                filters.push('recordedAt >= :from');
                params.ExpressionAttributeValues[':from'] = from;
            }
            if (to) {
                filters.push('recordedAt <= :to');
                params.ExpressionAttributeValues[':to'] = to;
            }
            params.FilterExpression = filters.join(' AND ');
        }
        const result = await this.client.send(new lib_dynamodb_1.QueryCommand(params));
        const items = (result.Items || []);
        const nextCursor = result.LastEvaluatedKey
            ? Buffer.from(JSON.stringify(result.LastEvaluatedKey)).toString('base64')
            : undefined;
        return { items, nextCursor };
    }
    async deleteAutoDetectedRecord(userId, recordId) {
        // Find the record first
        const result = await this.client.send(new lib_dynamodb_1.QueryCommand({
            TableName: TABLE_NAME,
            KeyConditionExpression: 'userId = :uid',
            FilterExpression: 'recordId = :rid',
            ExpressionAttributeValues: { ':uid': userId, ':rid': recordId },
        }));
        const record = result.Items?.[0];
        if (!record)
            throw new Error('Record not found');
        if (record.source !== types_1.RecordSource.AUTO_DETECTED)
            throw new Error('Only auto-detected records can be deleted');
        await this.client.send(new lib_dynamodb_1.UpdateCommand({
            TableName: TABLE_NAME,
            Key: { userId, sk: `${record.recordedAt}#${record.recordId}` },
            UpdateExpression: 'SET deleted = :t',
            ExpressionAttributeValues: { ':t': true },
        }));
        const avatarResult = await (0, avatar_connector_1.deductPoints)(userId, record.points, record.categoryId);
        return { success: true, avatarStatus: avatarResult.avatarStatus, devolutionOccurred: avatarResult.devolutionOccurred };
    }
    async getSummary(userId, period) {
        const now = new Date();
        const todayStr = now.toISOString().split('T')[0];
        if (period === 'today') {
            const result = await this.client.send(new lib_dynamodb_1.QueryCommand({
                TableName: TABLE_NAME,
                KeyConditionExpression: 'userId = :uid AND sk >= :today',
                ExpressionAttributeValues: { ':uid': userId, ':today': todayStr },
                FilterExpression: 'attribute_not_exists(deleted)',
            }));
            const items = (result.Items || []);
            return {
                todayCount: items.length,
                todayPoints: items.reduce((sum, r) => sum + r.points, 0),
            };
        }
        // week
        const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
        const result = await this.client.send(new lib_dynamodb_1.QueryCommand({
            TableName: TABLE_NAME,
            KeyConditionExpression: 'userId = :uid AND sk >= :weekAgo',
            ExpressionAttributeValues: { ':uid': userId, ':weekAgo': weekAgo },
            FilterExpression: 'attribute_not_exists(deleted)',
        }));
        const items = (result.Items || []);
        const categoryMap = new Map();
        items.forEach(r => {
            const entry = categoryMap.get(r.categoryId) || { count: 0, points: 0 };
            entry.count++;
            entry.points += r.points;
            categoryMap.set(r.categoryId, entry);
        });
        return {
            todayCount: items.filter(r => r.recordedAt.startsWith(todayStr)).length,
            todayPoints: items.filter(r => r.recordedAt.startsWith(todayStr)).reduce((s, r) => s + r.points, 0),
            weekSummary: Array.from(categoryMap.entries()).map(([categoryId, v]) => ({ categoryId, ...v })),
        };
    }
    async getCategory(categoryId) {
        const result = await this.client.send(new lib_dynamodb_1.GetCommand({
            TableName: CATEGORY_TABLE,
            Key: { categoryId },
        }));
        return result.Item;
    }
    async recordExists(userId, recordId) {
        const result = await this.client.send(new lib_dynamodb_1.QueryCommand({
            TableName: TABLE_NAME,
            KeyConditionExpression: 'userId = :uid',
            FilterExpression: 'recordId = :rid',
            ExpressionAttributeValues: { ':uid': userId, ':rid': recordId },
            Limit: 1,
        }));
        return (result.Items?.length || 0) > 0;
    }
}
exports.RecordingService = RecordingService;
//# sourceMappingURL=recording-service.js.map