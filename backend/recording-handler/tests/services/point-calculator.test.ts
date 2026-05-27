import {
  calculateManualPoints,
  calculateStepsPoints,
  calculateWeightPoints,
  calculateSleepPoints,
  clockToNormalized,
} from '../../src/services/point-calculator';
import { CategoryType, HealthEvaluation } from '../../src/types';

describe('calculateManualPoints', () => {
  it('returns 12 for FOOD category', () => {
    expect(calculateManualPoints(CategoryType.FOOD)).toBe(12);
  });

  it('returns 10 for LIFESTYLE category', () => {
    expect(calculateManualPoints(CategoryType.LIFESTYLE)).toBe(10);
  });
});

describe('calculateStepsPoints', () => {
  it('returns NEUTRAL in dead zone (7200-8800)', () => {
    const result = calculateStepsPoints(7500);
    expect(result.evaluation).toBe(HealthEvaluation.NEUTRAL);
    expect(result.points).toBe(0);
  });

  it('returns UNHEALTHY +12 for 0 steps', () => {
    const result = calculateStepsPoints(0);
    expect(result.evaluation).toBe(HealthEvaluation.UNHEALTHY);
    expect(result.points).toBe(12);
  });

  it('returns UNHEALTHY for steps below dead zone', () => {
    const result = calculateStepsPoints(4000);
    expect(result.evaluation).toBe(HealthEvaluation.UNHEALTHY);
    expect(result.points).toBeGreaterThan(0);
  });

  it('returns HEALTHY for steps above dead zone', () => {
    const result = calculateStepsPoints(10000);
    expect(result.evaluation).toBe(HealthEvaluation.HEALTHY);
    expect(result.points).toBeLessThan(0);
  });

  it('caps HEALTHY at -8', () => {
    const result = calculateStepsPoints(20000);
    expect(result.points).toBe(-8);
  });

  it('boundary: exactly at lower dead zone edge (7200)', () => {
    const result = calculateStepsPoints(7200);
    expect(result.evaluation).toBe(HealthEvaluation.NEUTRAL);
  });

  it('boundary: exactly at upper dead zone edge (8800)', () => {
    const result = calculateStepsPoints(8800);
    expect(result.evaluation).toBe(HealthEvaluation.NEUTRAL);
  });
});

describe('calculateWeightPoints', () => {
  it('returns NEUTRAL for first sync (no previous weight)', () => {
    const result = calculateWeightPoints(70, null);
    expect(result.evaluation).toBe(HealthEvaluation.NEUTRAL);
    expect(result.points).toBe(0);
  });

  it('returns UNHEALTHY +20 for +1kg', () => {
    const result = calculateWeightPoints(71, 70);
    expect(result.evaluation).toBe(HealthEvaluation.UNHEALTHY);
    expect(result.points).toBe(20);
  });

  it('returns UNHEALTHY +40 for +2.5kg', () => {
    const result = calculateWeightPoints(72.5, 70);
    expect(result.points).toBe(40);
  });

  it('returns HEALTHY -10 for -1kg', () => {
    const result = calculateWeightPoints(69, 70);
    expect(result.evaluation).toBe(HealthEvaluation.HEALTHY);
    expect(result.points).toBe(-10);
  });

  it('returns NEUTRAL for small changes (<1kg)', () => {
    const result = calculateWeightPoints(70.5, 70);
    expect(result.evaluation).toBe(HealthEvaluation.NEUTRAL);
    expect(result.points).toBe(0);
  });
});

describe('calculateSleepPoints', () => {
  it('late bedtime (1:00AM = offset 7) is UNHEALTHY', () => {
    const result = calculateSleepPoints(7, 6);
    expect(result.evaluation).toBe(HealthEvaluation.UNHEALTHY);
    expect(result.points).toBeGreaterThan(0);
  });

  it('early bedtime with adequate sleep is HEALTHY', () => {
    const result = calculateSleepPoints(4, 7.5);
    expect(result.evaluation).toBe(HealthEvaluation.HEALTHY);
    expect(result.points).toBeLessThan(0);
  });

  it('oversleep (10h) is UNHEALTHY', () => {
    const result = calculateSleepPoints(4, 10);
    expect(result.evaluation).toBe(HealthEvaluation.UNHEALTHY);
    expect(result.label).toBe('寝すぎ');
  });

  it('sleep deficit (4h) is UNHEALTHY', () => {
    const result = calculateSleepPoints(7, 4);
    expect(result.evaluation).toBe(HealthEvaluation.UNHEALTHY);
    // Both bedtime(late) and duration(deficit) are unhealthy, picks max
    expect(result.points).toBeGreaterThan(0);
  });

  it('mixed: late bedtime (+) but adequate sleep (-) → unhealthy wins', () => {
    const result = calculateSleepPoints(7, 7.5);
    expect(result.evaluation).toBe(HealthEvaluation.UNHEALTHY);
    expect(result.points).toBeGreaterThan(0);
  });
});

describe('clockToNormalized', () => {
  it('converts 23:00 to 5', () => {
    expect(clockToNormalized(23, 0)).toBe(5);
  });

  it('converts 01:00 to 7', () => {
    expect(clockToNormalized(1, 0)).toBe(7);
  });

  it('converts 18:00 to 0', () => {
    expect(clockToNormalized(18, 0)).toBe(0);
  });

  it('converts 03:30 to 9.5', () => {
    expect(clockToNormalized(3, 30)).toBe(9.5);
  });
});
