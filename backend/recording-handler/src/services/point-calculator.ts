import { CategoryType, HealthEvaluation, PointConfig, DEFAULT_POINT_CONFIG } from '../types';

export interface PointResult {
  points: number;
  evaluation: HealthEvaluation;
  label: string;
}

export function calculateManualPoints(categoryType: CategoryType, config: PointConfig = DEFAULT_POINT_CONFIG): number {
  return categoryType === CategoryType.FOOD ? config.MANUAL_FOOD_POINTS : config.MANUAL_LIFESTYLE_POINTS;
}

export function calculateStepsPoints(steps: number, config: PointConfig = DEFAULT_POINT_CONFIG): PointResult {
  const target = config.STEPS_TARGET;
  const lowerBound = target * (1 - config.STEPS_TOLERANCE);
  const upperBound = target * (1 + config.STEPS_TOLERANCE);

  if (steps >= lowerBound && steps <= upperBound) {
    return { points: 0, evaluation: HealthEvaluation.NEUTRAL, label: '適正歩数' };
  }

  if (steps < lowerBound) {
    const points = config.STEPS_UNHEALTHY_BASE - Math.floor((steps / lowerBound) * config.STEPS_UNHEALTHY_SCALE);
    return { points, evaluation: HealthEvaluation.UNHEALTHY, label: '運動不足' };
  }

  // steps > upperBound
  const excess = steps - upperBound;
  const points = -(config.STEPS_HEALTHY_BASE + Math.floor((excess / config.STEPS_HEALTHY_DIVISOR) * config.STEPS_HEALTHY_SCALE));
  const clampedPoints = Math.max(points, config.STEPS_HEALTHY_MIN);
  return { points: clampedPoints, evaluation: HealthEvaluation.HEALTHY, label: '十分な運動' };
}

export function calculateWeightPoints(
  currentWeight: number,
  previousWeight: number | null,
  config: PointConfig = DEFAULT_POINT_CONFIG,
): PointResult {
  if (previousWeight === null) {
    return { points: 0, evaluation: HealthEvaluation.NEUTRAL, label: '初回記録' };
  }

  const diff = currentWeight - previousWeight;

  if (diff >= 1.0) {
    const points = config.WEIGHT_GAIN_POINTS_PER_KG * Math.floor(diff);
    return { points, evaluation: HealthEvaluation.UNHEALTHY, label: '体重増加' };
  }

  if (diff <= -1.0) {
    const points = -(config.WEIGHT_LOSS_POINTS_PER_KG * Math.floor(Math.abs(diff)));
    return { points, evaluation: HealthEvaluation.HEALTHY, label: '体重減少' };
  }

  return { points: 0, evaluation: HealthEvaluation.NEUTRAL, label: '体重維持' };
}

export function calculateSleepPoints(
  bedtimeHour: number,
  durationHours: number,
  config: PointConfig = DEFAULT_POINT_CONFIG,
): PointResult {
  const targetBedtimeHour = config.SLEEP_TARGET_BEDTIME_HOUR;
  const targetDuration = config.SLEEP_TARGET_DURATION;

  // Bedtime points
  let bedtimePoints: number;
  let bedtimeLabel: string;

  if (bedtimeHour > targetBedtimeHour) {
    const excessHours = Math.floor((bedtimeHour - targetBedtimeHour) * 2) / 2;
    bedtimePoints = config.SLEEP_LATE_BASE + config.SLEEP_LATE_SCALE * excessHours;
    bedtimeLabel = '夜更かし';
  } else {
    bedtimePoints = config.SLEEP_EARLY_POINTS;
    bedtimeLabel = '早寝';
  }

  // Duration points
  let durationPoints: number;
  let durationLabel: string;

  if (durationHours < targetDuration) {
    const deficit = targetDuration - durationHours;
    durationPoints = config.SLEEP_SHORT_BASE + config.SLEEP_SHORT_SCALE * Math.floor(deficit);
    durationLabel = '睡眠不足';
  } else if (durationHours < targetDuration + config.SLEEP_OVER_THRESHOLD) {
    durationPoints = config.SLEEP_GOOD_POINTS;
    durationLabel = '適正睡眠';
  } else {
    const excess = durationHours - (targetDuration + config.SLEEP_OVER_THRESHOLD);
    durationPoints = config.SLEEP_OVER_BASE + config.SLEEP_OVER_SCALE * Math.floor(excess);
    durationLabel = '寝すぎ';
  }

  // Unified evaluation: pick the one with higher impact
  if (bedtimePoints > 0 && durationPoints > 0) {
    return bedtimePoints >= durationPoints
      ? { points: bedtimePoints, evaluation: HealthEvaluation.UNHEALTHY, label: bedtimeLabel }
      : { points: durationPoints, evaluation: HealthEvaluation.UNHEALTHY, label: durationLabel };
  }

  if (bedtimePoints < 0 && durationPoints < 0) {
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
