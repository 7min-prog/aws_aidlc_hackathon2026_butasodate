import { DynamoDBDocumentClient, PutCommand, QueryCommand, GetCommand, UpdateCommand, TransactWriteCommand } from '@aws-sdk/lib-dynamodb';
import { ActivityRecord, CreateActivityRequest, RecordSource, CategoryType, PaginatedResponse, ActivitySummaryResponse } from '../types';
import { calculateManualPoints } from './point-calculator';
import { addPoints, deductPoints } from '../connectors/avatar-connector';
import { randomUUID } from 'crypto';

const TABLE_NAME = process.env.ACTIVITY_RECORD_TABLE!;
const CATEGORY_TABLE = process.env.ACTIVITY_CATEGORY_TABLE!;

export class RecordingService {
  constructor(private readonly client: DynamoDBDocumentClient) {}

  async createRecord(userId: string, req: CreateActivityRequest): Promise<{ record: ActivityRecord; avatarStatus: any }> {
    const recordId = req.recordId || randomUUID();
    const category = await this.getCategory(req.categoryId);
    if (!category) throw new Error('Category not found');

    const points = calculateManualPoints(category.type as CategoryType);
    const now = new Date().toISOString();
    const recordedAt = req.recordedAt || now;

    const record: ActivityRecord = {
      recordId,
      userId,
      categoryId: req.categoryId,
      source: RecordSource.MANUAL,
      points,
      memo: req.memo,
      recordedAt,
      createdAt: now,
    };

    await this.client.send(new TransactWriteCommand({
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

    const avatarStatus = await addPoints(userId, points, category.type);
    return { record, avatarStatus };
  }

  async batchCreateRecords(userId: string, requests: CreateActivityRequest[]): Promise<{ syncedRecords: ActivityRecord[]; skippedIds: string[]; avatarStatus: any }> {
    const syncedRecords: ActivityRecord[] = [];
    const skippedIds: string[] = [];
    let totalPoints = 0;

    for (const req of requests) {
      const recordId = req.recordId || randomUUID();
      const existing = await this.recordExists(userId, recordId);
      if (existing) {
        skippedIds.push(recordId);
        continue;
      }

      const category = await this.getCategory(req.categoryId);
      if (!category) continue;

      const points = calculateManualPoints(category.type as CategoryType);
      const now = new Date().toISOString();
      const recordedAt = req.recordedAt || now;

      const record: ActivityRecord = {
        recordId, userId, categoryId: req.categoryId,
        source: RecordSource.MANUAL, points, memo: req.memo,
        recordedAt, createdAt: now,
      };

      await this.client.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: { ...record, sk: `${recordedAt}#${recordId}`, gsi1sk: `${req.categoryId}#${recordedAt}` },
      }));

      syncedRecords.push(record);
      totalPoints += points;
    }

    const avatarStatus = totalPoints > 0 ? await addPoints(userId, totalPoints, CategoryType.FOOD) : { totalPoints: 0, level: 1 };
    return { syncedRecords, skippedIds, avatarStatus };
  }

  async getRecords(userId: string, limit: number, cursor?: string, categoryId?: string, from?: string, to?: string): Promise<PaginatedResponse<ActivityRecord>> {
    const params: any = {
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
      const filters: string[] = [];
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

    const result = await this.client.send(new QueryCommand(params));
    const items = (result.Items || []) as ActivityRecord[];
    const nextCursor = result.LastEvaluatedKey
      ? Buffer.from(JSON.stringify(result.LastEvaluatedKey)).toString('base64')
      : undefined;

    return { items, nextCursor };
  }

  async deleteAutoDetectedRecord(userId: string, recordId: string): Promise<{ success: boolean; avatarStatus: any; devolutionOccurred: boolean }> {
    // Find the record first
    const result = await this.client.send(new QueryCommand({
      TableName: TABLE_NAME,
      KeyConditionExpression: 'userId = :uid',
      FilterExpression: 'recordId = :rid',
      ExpressionAttributeValues: { ':uid': userId, ':rid': recordId },
    }));

    const record = result.Items?.[0] as ActivityRecord | undefined;
    if (!record) throw new Error('Record not found');
    if (record.source !== RecordSource.AUTO_DETECTED) throw new Error('Only auto-detected records can be deleted');

    await this.client.send(new UpdateCommand({
      TableName: TABLE_NAME,
      Key: { userId, sk: `${record.recordedAt}#${record.recordId}` },
      UpdateExpression: 'SET deleted = :t',
      ExpressionAttributeValues: { ':t': true },
    }));

    const avatarResult = await deductPoints(userId, record.points, record.categoryId);
    return { success: true, avatarStatus: avatarResult.avatarStatus, devolutionOccurred: avatarResult.devolutionOccurred };
  }

  async getSummary(userId: string, period: 'today' | 'week'): Promise<ActivitySummaryResponse> {
    const now = new Date();
    const todayStr = now.toISOString().split('T')[0];

    if (period === 'today') {
      const result = await this.client.send(new QueryCommand({
        TableName: TABLE_NAME,
        KeyConditionExpression: 'userId = :uid AND sk >= :today',
        ExpressionAttributeValues: { ':uid': userId, ':today': todayStr },
        FilterExpression: 'attribute_not_exists(deleted)',
      }));
      const items = (result.Items || []) as ActivityRecord[];
      return {
        todayCount: items.length,
        todayPoints: items.reduce((sum, r) => sum + r.points, 0),
      };
    }

    // week
    const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const result = await this.client.send(new QueryCommand({
      TableName: TABLE_NAME,
      KeyConditionExpression: 'userId = :uid AND sk >= :weekAgo',
      ExpressionAttributeValues: { ':uid': userId, ':weekAgo': weekAgo },
      FilterExpression: 'attribute_not_exists(deleted)',
    }));
    const items = (result.Items || []) as ActivityRecord[];

    const categoryMap = new Map<string, { count: number; points: number }>();
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

  private async getCategory(categoryId: string) {
    const result = await this.client.send(new GetCommand({
      TableName: CATEGORY_TABLE,
      Key: { categoryId },
    }));
    return result.Item;
  }

  private async recordExists(userId: string, recordId: string): Promise<boolean> {
    const result = await this.client.send(new QueryCommand({
      TableName: TABLE_NAME,
      KeyConditionExpression: 'userId = :uid',
      FilterExpression: 'recordId = :rid',
      ExpressionAttributeValues: { ':uid': userId, ':rid': recordId },
      Limit: 1,
    }));
    return (result.Items?.length || 0) > 0;
  }
}
