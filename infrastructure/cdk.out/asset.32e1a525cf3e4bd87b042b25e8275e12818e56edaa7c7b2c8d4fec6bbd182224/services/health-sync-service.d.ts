import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';
import { HealthSyncDataPoint, HealthSyncResultItem, AvatarStatus } from '../types';
export declare class HealthSyncService {
    private readonly client;
    constructor(client: DynamoDBDocumentClient);
    syncHealthData(userId: string, dataPoints: HealthSyncDataPoint[]): Promise<{
        syncResults: HealthSyncResultItem[];
        skippedDates: string[];
        totalPoints: number;
        avatarStatus: AvatarStatus;
    }>;
    private evaluate;
    private getPreviousWeight;
    private recordExists;
}
//# sourceMappingURL=health-sync-service.d.ts.map