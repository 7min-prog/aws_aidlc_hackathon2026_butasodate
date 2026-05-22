import { DynamoDBDocumentClient, TransactWriteCommand, GetCommand } from '@aws-sdk/lib-dynamodb';
import { HealthSyncDataPoint, HealthSyncRecord, HealthSyncResultItem, HealthCategory, HealthEvaluation, RecordSource, AvatarStatus } from '../types';
import { calculateStepsPoints, calculateWeightPoints, calculateSleepPoints, clockToNormalized, PointResult } from './point-calculator';
import { addPoints } from '../connectors/avatar-connector';
import { randomUUID } from 'crypto';

const HEALTH_SYNC_TABLE = process.env.HEALTH_SYNC_TABLE!;
const ACTIVITY_RECORD_TABLE = process.env.ACTIVITY_RECORD_TABLE!;

export class HealthSyncService {
  constructor(private readonly client: DynamoDBDocumentClient) {}

  async syncHealthData(userId: string, dataPoints: HealthSyncDataPoint[]): Promise<{ syncResults: HealthSyncResultItem[]; skippedDates: string[]; totalPoints: number; avatarStatus: AvatarStatus }> {
    const syncResults: HealthSyncResultItem[] = [];
    const skippedDates: string[] = [];
    let totalPoints = 0;

    for (const dp of dataPoints) {
      const exists = await this.recordExists(userId, dp.syncDate, dp.category);
      if (exists) {
        skippedDates.push(`${dp.syncDate}#${dp.category}`);
        syncResults.push({ syncDate: dp.syncDate, category: dp.category, evaluation: HealthEvaluation.NEUTRAL, points: 0, label: 'スキップ（処理済み）', skipped: true });
        continue;
      }

      const result = await this.evaluate(userId, dp);

      const syncId = randomUUID();
      const now = new Date().toISOString();
      const recordId = randomUUID();

      const syncRecord: HealthSyncRecord = {
        syncId, userId, syncDate: dp.syncDate,
        category: dp.category, rawValue: dp.rawValue,
        evaluation: result.evaluation, points: result.points, createdAt: now,
      };

      await this.client.send(new TransactWriteCommand({
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
                source: RecordSource.AUTO_DETECTED,
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
      ? await addPoints(userId, totalPoints, 'HEALTH_AUTO')
      : { totalPoints: 0, level: 1 };

    return { syncResults, skippedDates, totalPoints, avatarStatus };
  }

  private async evaluate(userId: string, dp: HealthSyncDataPoint): Promise<PointResult> {
    switch (dp.category) {
      case HealthCategory.STEPS:
        return calculateStepsPoints(dp.rawValue);

      case HealthCategory.WEIGHT: {
        const prevWeight = await this.getPreviousWeight(userId);
        return calculateWeightPoints(dp.rawValue, prevWeight);
      }

      case HealthCategory.SLEEP: {
        // rawValue = bedtime as clock hour (e.g., 1.5 = 1:30AM)
        // secondaryValue = duration in hours
        const bedtimeNormalized = clockToNormalized(Math.floor(dp.rawValue), (dp.rawValue % 1) * 60);
        const duration = dp.secondaryValue || 7;
        return calculateSleepPoints(bedtimeNormalized, duration);
      }

      default:
        return { points: 0, evaluation: HealthEvaluation.NEUTRAL, label: '不明' };
    }
  }

  private async getPreviousWeight(userId: string): Promise<number | null> {
    const result = await this.client.send(new GetCommand({
      TableName: HEALTH_SYNC_TABLE,
      Key: { userId, sk: `PREV_WEIGHT` },
    }));
    return result.Item?.value ?? null;
  }

  private async recordExists(userId: string, syncDate: string, category: HealthCategory): Promise<boolean> {
    const result = await this.client.send(new GetCommand({
      TableName: HEALTH_SYNC_TABLE,
      Key: { userId, sk: `${syncDate}#${category}` },
    }));
    return !!result.Item;
  }
}
