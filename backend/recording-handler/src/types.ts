// === Enums ===

export enum RecordSource {
  MANUAL = 'MANUAL',
  AUTO_DETECTED = 'AUTO_DETECTED',
}

export enum CategoryType {
  FOOD = 'FOOD',
  LIFESTYLE = 'LIFESTYLE',
}

export enum HealthCategory {
  WEIGHT = 'WEIGHT',
  STEPS = 'STEPS',
  SLEEP = 'SLEEP',
}

export enum HealthEvaluation {
  UNHEALTHY = 'UNHEALTHY',
  HEALTHY = 'HEALTHY',
  NEUTRAL = 'NEUTRAL',
}

// === Entities ===

export interface ActivityRecord {
  recordId: string;
  userId: string;
  categoryId: string;
  source: RecordSource;
  points: number;
  memo?: string;
  recordedAt: string; // ISO 8601
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
  syncDate: string; // YYYY-MM-DD
  category: HealthCategory;
  rawValue: number;
  evaluation: HealthEvaluation;
  points: number;
  createdAt: string;
}

// === Request/Response Types ===

export interface CreateActivityRequest {
  categoryId: string;
  memo?: string;
  recordedAt?: string;
  recordId?: string; // client-generated UUID for idempotency
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
  secondaryValue?: number; // e.g., sleep duration for SLEEP category
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
