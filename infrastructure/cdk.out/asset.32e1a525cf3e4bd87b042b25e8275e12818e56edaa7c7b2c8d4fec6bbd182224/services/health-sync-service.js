"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.HealthSyncService = void 0;
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const types_1 = require("../types");
const point_calculator_1 = require("./point-calculator");
const avatar_connector_1 = require("../connectors/avatar-connector");
const crypto_1 = require("crypto");
const HEALTH_SYNC_TABLE = process.env.HEALTH_SYNC_TABLE;
const ACTIVITY_RECORD_TABLE = process.env.ACTIVITY_RECORD_TABLE;
class HealthSyncService {
    client;
    constructor(client) {
        this.client = client;
    }
    async syncHealthData(userId, dataPoints) {
        const syncResults = [];
        const skippedDates = [];
        let totalPoints = 0;
        for (const dp of dataPoints) {
            const exists = await this.recordExists(userId, dp.syncDate, dp.category);
            if (exists) {
                skippedDates.push(`${dp.syncDate}#${dp.category}`);
                syncResults.push({ syncDate: dp.syncDate, category: dp.category, evaluation: types_1.HealthEvaluation.NEUTRAL, points: 0, label: 'スキップ（処理済み）', skipped: true });
                continue;
            }
            const result = await this.evaluate(userId, dp);
            const syncId = (0, crypto_1.randomUUID)();
            const now = new Date().toISOString();
            const recordId = (0, crypto_1.randomUUID)();
            const syncRecord = {
                syncId, userId, syncDate: dp.syncDate,
                category: dp.category, rawValue: dp.rawValue,
                evaluation: result.evaluation, points: result.points, createdAt: now,
            };
            await this.client.send(new lib_dynamodb_1.TransactWriteCommand({
                TransactItems: [
                    {
                        Put: {
                            TableName: HEALTH_SYNC_TABLE,
                            Item: { ...syncRecord, sk: `${dp.syncDate}#${dp.category}` },
                            ConditionExpression: 'attribute_not_exists(userId)',
                        },
                    },
                    {
                        Put: {
                            TableName: ACTIVITY_RECORD_TABLE,
                            Item: {
                                userId,
                                sk: `${dp.syncDate}T00:00:00.000Z#${recordId}`,
                                gsi1sk: `auto_${dp.category.toLowerCase()}#${dp.syncDate}`,
                                recordId, categoryId: `auto_${dp.category.toLowerCase()}`,
                                source: types_1.RecordSource.AUTO_DETECTED,
                                points: result.points, recordedAt: `${dp.syncDate}T00:00:00.000Z`,
                                createdAt: now,
                            },
                        },
                    },
                ],
            }));
            totalPoints += result.points;
            syncResults.push({ syncDate: dp.syncDate, category: dp.category, evaluation: result.evaluation, points: result.points, label: result.label, skipped: false });
        }
        const avatarStatus = totalPoints !== 0
            ? await (0, avatar_connector_1.addPoints)(userId, totalPoints, 'HEALTH_AUTO')
            : { totalPoints: 0, level: 1 };
        return { syncResults, skippedDates, totalPoints, avatarStatus };
    }
    async evaluate(userId, dp) {
        switch (dp.category) {
            case types_1.HealthCategory.STEPS:
                return (0, point_calculator_1.calculateStepsPoints)(dp.rawValue);
            case types_1.HealthCategory.WEIGHT: {
                const prevWeight = await this.getPreviousWeight(userId);
                return (0, point_calculator_1.calculateWeightPoints)(dp.rawValue, prevWeight);
            }
            case types_1.HealthCategory.SLEEP: {
                // rawValue = bedtime as clock hour (e.g., 1.5 = 1:30AM)
                // secondaryValue = duration in hours
                const bedtimeNormalized = (0, point_calculator_1.clockToNormalized)(Math.floor(dp.rawValue), (dp.rawValue % 1) * 60);
                const duration = dp.secondaryValue || 7;
                return (0, point_calculator_1.calculateSleepPoints)(bedtimeNormalized, duration);
            }
            default:
                return { points: 0, evaluation: types_1.HealthEvaluation.NEUTRAL, label: '不明' };
        }
    }
    async getPreviousWeight(userId) {
        const result = await this.client.send(new lib_dynamodb_1.GetCommand({
            TableName: HEALTH_SYNC_TABLE,
            Key: { userId, sk: `PREV_WEIGHT` },
        }));
        return result.Item?.value ?? null;
    }
    async recordExists(userId, syncDate, category) {
        const result = await this.client.send(new lib_dynamodb_1.GetCommand({
            TableName: HEALTH_SYNC_TABLE,
            Key: { userId, sk: `${syncDate}#${category}` },
        }));
        return !!result.Item;
    }
}
exports.HealthSyncService = HealthSyncService;
//# sourceMappingURL=health-sync-service.js.map