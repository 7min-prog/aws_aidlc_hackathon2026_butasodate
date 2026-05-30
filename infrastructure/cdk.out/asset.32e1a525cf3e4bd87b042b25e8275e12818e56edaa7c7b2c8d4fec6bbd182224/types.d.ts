export declare enum RecordSource {
    MANUAL = "MANUAL",
    AUTO_DETECTED = "AUTO_DETECTED"
}
export declare enum CategoryType {
    FOOD = "FOOD",
    LIFESTYLE = "LIFESTYLE"
}
export declare enum HealthCategory {
    WEIGHT = "WEIGHT",
    STEPS = "STEPS",
    SLEEP = "SLEEP"
}
export declare enum HealthEvaluation {
    UNHEALTHY = "UNHEALTHY",
    HEALTHY = "HEALTHY",
    NEUTRAL = "NEUTRAL"
}
export interface ActivityRecord {
    recordId: string;
    userId: string;
    categoryId: string;
    source: RecordSource;
    points: number;
    memo?: string;
    recordedAt: string;
    createdAt: string;
}
export interface ActivityCategory {
    categoryId: string;
    name: string;
    type: CategoryType;
    basePoints: number;
    iconKey: string;
    sortOrder: number;
    isActive: boolean;
    version: number;
}
export interface HealthSyncRecord {
    syncId: string;
    userId: string;
    syncDate: string;
    category: HealthCategory;
    rawValue: number;
    evaluation: HealthEvaluation;
    points: number;
    createdAt: string;
}
export interface CreateActivityRequest {
    categoryId: string;
    memo?: string;
    recordedAt?: string;
    recordId?: string;
}
export interface BatchCreateActivityRequest {
    records: CreateActivityRequest[];
}
export interface HealthSyncRequest {
    records: HealthSyncDataPoint[];
}
export interface HealthSyncDataPoint {
    category: HealthCategory;
    syncDate: string;
    rawValue: number;
    secondaryValue?: number;
}
export interface ActivitySummaryResponse {
    todayCount: number;
    todayPoints: number;
    weekSummary?: CategorySummaryItem[];
}
export interface CategorySummaryItem {
    categoryId: string;
    count: number;
    points: number;
}
export interface HealthSyncResultItem {
    syncDate: string;
    category: HealthCategory;
    evaluation: HealthEvaluation;
    points: number;
    label: string;
    skipped: boolean;
}
export interface HealthSyncResponse {
    syncResults: HealthSyncResultItem[];
    skippedDates: string[];
    totalPoints: number;
    avatarStatus: AvatarStatus;
}
export interface AvatarStatus {
    totalPoints: number;
    level: number;
    categoryPoints?: Record<string, number>;
}
export interface PaginatedResponse<T> {
    items: T[];
    nextCursor?: string;
}
//# sourceMappingURL=types.d.ts.map