import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';
import { ActivityRecord, CreateActivityRequest, PaginatedResponse, ActivitySummaryResponse } from '../types';
export declare class RecordingService {
    private readonly client;
    constructor(client: DynamoDBDocumentClient);
    createRecord(userId: string, req: CreateActivityRequest): Promise<{
        record: ActivityRecord;
        avatarStatus: any;
    }>;
    batchCreateRecords(userId: string, requests: CreateActivityRequest[]): Promise<{
        syncedRecords: ActivityRecord[];
        skippedIds: string[];
        avatarStatus: any;
    }>;
    getRecords(userId: string, limit: number, cursor?: string, categoryId?: string, from?: string, to?: string): Promise<PaginatedResponse<ActivityRecord>>;
    deleteAutoDetectedRecord(userId: string, recordId: string): Promise<{
        success: boolean;
        avatarStatus: any;
        devolutionOccurred: boolean;
    }>;
    getSummary(userId: string, period: 'today' | 'week'): Promise<ActivitySummaryResponse>;
    private getCategory;
    private recordExists;
}
//# sourceMappingURL=recording-service.d.ts.map