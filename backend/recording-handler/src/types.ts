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

// === Point Calculation Config ===

export interface PointConfig {
  MANUAL_FOOD_POINTS: number;
  MANUAL_LIFESTYLE_POINTS: number;
  STEPS_TARGET: number;
  STEPS_TOLERANCE: number;
  STEPS_UNHEALTHY_BASE: number;
  STEPS_UNHEALTHY_SCALE: number;
  STEPS_HEALTHY_BASE: number;
  STEPS_HEALTHY_SCALE: number;
  STEPS_HEALTHY_DIVISOR: number;
  STEPS_HEALTHY_MIN: number;
  WEIGHT_GAIN_POINTS_PER_KG: number;
  WEIGHT_LOSS_POINTS_PER_KG: number;
  SLEEP_TARGET_BEDTIME_HOUR: number;
  SLEEP_TARGET_DURATION: number;
  SLEEP_LATE_BASE: number;
  SLEEP_LATE_SCALE: number;
  SLEEP_EARLY_POINTS: number;
  SLEEP_SHORT_BASE: number;
  SLEEP_SHORT_SCALE: number;
  SLEEP_GOOD_POINTS: number;
  SLEEP_OVER_BASE: number;
  SLEEP_OVER_SCALE: number;
  SLEEP_OVER_THRESHOLD: number;
}

export const DEFAULT_POINT_CONFIG: PointConfig = {
  MANUAL_FOOD_POINTS: 12,
  MANUAL_LIFESTYLE_POINTS: 10,
  STEPS_TARGET: 8000,
  STEPS_TOLERANCE: 0.1,
  STEPS_UNHEALTHY_BASE: 12,
  STEPS_UNHEALTHY_SCALE: 7,
  STEPS_HEALTHY_BASE: 3,
  STEPS_HEALTHY_SCALE: 5,
  STEPS_HEALTHY_DIVISOR: 7000,
  STEPS_HEALTHY_MIN: -8,
  WEIGHT_GAIN_POINTS_PER_KG: 20,
  WEIGHT_LOSS_POINTS_PER_KG: 10,
  SLEEP_TARGET_BEDTIME_HOUR: 5,
  SLEEP_TARGET_DURATION: 7,
  SLEEP_LATE_BASE: 8,
  SLEEP_LATE_SCALE: 3,
  SLEEP_EARLY_POINTS: -4,
  SLEEP_SHORT_BASE: 6,
  SLEEP_SHORT_SCALE: 2,
  SLEEP_GOOD_POINTS: -3,
  SLEEP_OVER_BASE: 4,
  SLEEP_OVER_SCALE: 1,
  SLEEP_OVER_THRESHOLD: 2,
};
