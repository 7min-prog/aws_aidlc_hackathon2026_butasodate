import { CategoryType, HealthCategory, HealthEvaluation, HealthSyncDataPoint } from '../types';

export interface PointResult {
  points: number;
  evaluation: HealthEvaluation;
  label: string;
}

export function calculateManualPoints(categoryType: CategoryType): number {
  return categoryType === CategoryType.FOOD ? 12 : 10;
}

export function calculateStepsPoints(steps: number, target = 8000): PointResult {
  const lowerBound = target * 0.9;
  const upperBound = target * 1.1;

  if (steps >= lowerBound && steps <= upperBound) {
    return { points: 0, evaluation: HealthEvaluation.NEUTRAL, label: '適正歩数' };
  }

  if (steps < lowerBound) {
    const points = 12 - Math.floor((steps / lowerBound) * 7);
    return { points, evaluation: HealthEvaluation.UNHEALTHY, label: '運動不足' };
  }

  // steps > upperBound
  const excess = steps - upperBound;
  const points = -(3 + Math.floor((excess / 7000) * 5));
  const clampedPoints = Math.max(points, -8);
  return { points: clampedPoints, evaluation: HealthEvaluation.HEALTHY, label: '十分な運動' };
}

export function calculateWeightPoints(
  currentWeight: number,
  previousWeight: number | null
): PointResult {
  if (previousWeight === null) {
    return { points: 0, evaluation: HealthEvaluation.NEUTRAL, label: '初回記録' };
  }

  const diff = currentWeight - previousWeight;

  if (diff >= 1.0) {
    const points = 20 * Math.floor(diff);
    return { points, evaluation: HealthEvaluation.UNHEALTHY, label: '体重増加' };
  }

  if (diff <= -1.0) {
    const points = -10 * Math.floor(Math.abs(diff));
    return { points, evaluation: HealthEvaluation.HEALTHY, label: '体重減少' };
  }

  return { points: 0, evaluation: HealthEvaluation.NEUTRAL, label: '体重維持' };
}

export function calculateSleepPoints(
  bedtimeHour: number, // 18:00起点の経過時間 (e.g., 23:00=5, 翌1:00=7)
  durationHours: number,
  targetBedtimeHour = 5, // 23:00 = 18:00から5時間
  targetDuration = 7
): PointResult {
  // Bedtime points
  let bedtimePoints: number;
  let bedtimeLabel: string;

  if (bedtimeHour > targetBedtimeHour) {
    const excessHours = Math.floor((bedtimeHour - targetBedtimeHour) * 2) / 2;
    bedtimePoints = 8 + 3 * excessHours;
    bedtimeLabel = '夜更かし';
  } else {
    bedtimePoints = -4;
    bedtimeLabel = '早寝';
  }

  // Duration points
  let durationPoints: number;
  let durationLabel: string;

  if (durationHours < targetDuration) {
    const deficit = targetDuration - durationHours;
    durationPoints = 6 + 2 * Math.floor(deficit);
    durationLabel = '睡眠不足';
  } else if (durationHours < targetDuration + 2) {
    durationPoints = -3;
    durationLabel = '適正睡眠';
  } else {
    const excess = durationHours - (targetDuration + 2);
    durationPoints = 4 + Math.floor(excess);
    durationLabel = '寝すぎ';
  }

  // Unified evaluation: pick the one with higher impact
  if (bedtimePoints > 0 && durationPoints > 0) {
    // Both unhealthy: pick larger
    return bedtimePoints >= durationPoints
      ? { points: bedtimePoints, evaluation: HealthEvaluation.UNHEALTHY, label: bedtimeLabel }
      : { points: durationPoints, evaluation: HealthEvaluation.UNHEALTHY, label: durationLabel };
  }

  if (bedtimePoints < 0 && durationPoints < 0) {
    // Both healthy: pick larger absolute
    return Math.abs(bedtimePoints) >= Math.abs(durationPoints)
      ? { points: bedtimePoints, evaluation: HealthEvaluation.HEALTHY, label: bedtimeLabel }
      : { points: durationPoints, evaluation: HealthEvaluation.HEALTHY, label: durationLabel };
  }

  // Mixed: unhealthy wins
  if (bedtimePoints > 0) {
    return { points: bedtimePoints, evaluation: HealthEvaluation.UNHEALTHY, label: bedtimeLabel };
  }
  return { points: durationPoints, evaluation: HealthEvaluation.UNHEALTHY, label: durationLabel };
}

/**
 * Convert clock time to 18:00-based offset.
 * e.g., 23:00 → 5, 01:00 → 7, 03:00 → 9
 */
export function clockToNormalized(hour: number, minute = 0): number {
  const totalMinutes = hour * 60 + minute;
  const offset = totalMinutes - 18 * 60;
  return offset >= 0 ? offset / 60 : (offset + 24 * 60) / 60;
}
