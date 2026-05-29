import { CategoryType, HealthEvaluation } from '../types';
export interface PointResult {
    points: number;
    evaluation: HealthEvaluation;
    label: string;
}
export declare function calculateManualPoints(categoryType: CategoryType): number;
export declare function calculateStepsPoints(steps: number, target?: number): PointResult;
export declare function calculateWeightPoints(currentWeight: number, previousWeight: number | null): PointResult;
export declare function calculateSleepPoints(bedtimeHour: number, // 18:00起点の経過時間 (e.g., 23:00=5, 翌1:00=7)
durationHours: number, targetBedtimeHour?: number, // 23:00 = 18:00から5時間
targetDuration?: number): PointResult;
/**
 * Convert clock time to 18:00-based offset.
 * e.g., 23:00 → 5, 01:00 → 7, 03:00 → 9
 */
export declare function clockToNormalized(hour: number, minute?: number): number;
//# sourceMappingURL=point-calculator.d.ts.map