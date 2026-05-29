import {
  calculateLevel, pointsForLevel, determineStage2Path,
  determineStage3Path, checkEvolution, checkDevolution,
  checkSkillAcquisition, getSkillsToLose, recalculateStats,
} from '../../src/services/evolution-engine';
import { Avatar, EvolutionPath, Skill } from '../../src/types';

const mockPaths: EvolutionPath[] = [
  { pathId: 'food_stage2', name: 'グルメぶた', stage: 2, parentPathId: null, requiredLevel: 5, dominantCategory: 'FOOD', categoryThreshold: 0.6, subCategoryIds: null, subCategoryThreshold: null, statsGrowth: { hp: 8, attack: 5, defense: 4, speed: 2 }, spriteSheetKey: 'sprites/stage2/food', description: '' },
  { pathId: 'lifestyle_stage2', name: 'ぐうたらぶた', stage: 2, parentPathId: null, requiredLevel: 5, dominantCategory: 'LIFESTYLE', categoryThreshold: 0.6, subCategoryIds: null, subCategoryThreshold: null, statsGrowth: { hp: 4, attack: 2, defense: 3, speed: 7 }, spriteSheetKey: 'sprites/stage2/lifestyle', description: '' },
  { pathId: 'mixed_stage2', name: 'まんまるぶた', stage: 2, parentPathId: null, requiredLevel: 5, dominantCategory: 'MIXED', categoryThreshold: 0.6, subCategoryIds: null, subCategoryThreshold: null, statsGrowth: { hp: 6, attack: 4, defense: 5, speed: 3 }, spriteSheetKey: 'sprites/stage2/mixed', description: '' },
  { pathId: 'food_gorge_stage3', name: '暴食帝ぶた', stage: 3, parentPathId: 'food_stage2', requiredLevel: 15, dominantCategory: 'FOOD', categoryThreshold: 0.6, subCategoryIds: ['food_binge', 'food_junkfood'], subCategoryThreshold: 0.5, statsGrowth: { hp: 10, attack: 6, defense: 4, speed: 2 }, spriteSheetKey: 'sprites/stage3/food_gorge', description: '' },
  { pathId: 'food_gourmet_stage3', name: '夜食神ぶた', stage: 3, parentPathId: 'food_stage2', requiredLevel: 15, dominantCategory: 'FOOD', categoryThreshold: 0.6, subCategoryIds: ['food_late_ramen', 'food_snack'], subCategoryThreshold: 0.5, statsGrowth: { hp: 7, attack: 7, defense: 3, speed: 4 }, spriteSheetKey: 'sprites/stage3/food_gourmet', description: '' },
];

const mockSkills: Skill[] = [
  { skillId: 'food_s2_1', name: '暴食タックル', type: 'ATTACK', power: 40, cooldown: 1, evolutionPathId: 'food_stage2', requiredLevel: 5, spriteAnimationKey: '' },
  { skillId: 'food_s2_2', name: '満腹バリア', type: 'DEFENSE', power: 0, cooldown: 3, evolutionPathId: 'food_stage2', requiredLevel: 8, spriteAnimationKey: '' },
];

function makeAvatar(overrides: Partial<Avatar> = {}): Avatar {
  return {
    avatarId: 'test-id', userId: 'user-1', name: 'テスト',
    totalPoints: 0, level: 1, evolutionStage: 1, evolutionPathId: null,
    categoryPoints: { FOOD: 0, LIFESTYLE: 0, MIXED: 0 },
    subCategoryPoints: {},
    stats: { hp: 50, attack: 10, defense: 10, speed: 10 },
    skillIds: [], spriteSheetKey: 'sprites/stage1/default',
    createdAt: '', updatedAt: '',
    ...overrides,
  };
}

describe('calculateLevel', () => {
  it('returns 1 for 0 points', () => {
    expect(calculateLevel(0)).toBe(1);
  });

  it('returns 1 for 100 points (exactly level 1 threshold)', () => {
    expect(calculateLevel(100)).toBe(1);
  });

  it('returns 2 for 300 points', () => {
    expect(calculateLevel(300)).toBe(2);
  });

  it('returns 5 for 1500 points', () => {
    expect(calculateLevel(1500)).toBe(5);
  });

  it('caps at 30', () => {
    expect(calculateLevel(999999)).toBe(30);
  });

  it('returns 1 for negative points', () => {
    expect(calculateLevel(-100)).toBe(1);
  });
});

describe('pointsForLevel', () => {
  it('level 1 requires 100 points', () => {
    expect(pointsForLevel(1)).toBe(100);
  });

  it('level 5 requires 1500 points', () => {
    expect(pointsForLevel(5)).toBe(1500);
  });
});

describe('determineStage2Path', () => {
  it('returns FOOD path when food ratio >= 60%', () => {
    const result = determineStage2Path({ FOOD: 700, LIFESTYLE: 300, MIXED: 0 }, 1000, mockPaths);
    expect(result?.pathId).toBe('food_stage2');
  });

  it('returns LIFESTYLE path when lifestyle ratio >= 60%', () => {
    const result = determineStage2Path({ FOOD: 200, LIFESTYLE: 800, MIXED: 0 }, 1000, mockPaths);
    expect(result?.pathId).toBe('lifestyle_stage2');
  });

  it('returns MIXED path when neither >= 60%', () => {
    const result = determineStage2Path({ FOOD: 500, LIFESTYLE: 500, MIXED: 0 }, 1000, mockPaths);
    expect(result?.pathId).toBe('mixed_stage2');
  });
});

describe('checkEvolution', () => {
  it('returns null when level < 5 at stage 1', () => {
    const avatar = makeAvatar({ totalPoints: 500, level: 3, categoryPoints: { FOOD: 400, LIFESTYLE: 100, MIXED: 0 } });
    expect(checkEvolution(avatar, 3, mockPaths)).toBeNull();
  });

  it('returns food path when level >= 5 at stage 1 with food dominant', () => {
    const avatar = makeAvatar({ totalPoints: 1500, level: 5, categoryPoints: { FOOD: 1000, LIFESTYLE: 500, MIXED: 0 } });
    const result = checkEvolution(avatar, 5, mockPaths);
    expect(result?.pathId).toBe('food_stage2');
  });
});

describe('checkDevolution', () => {
  it('returns null when level still meets stage requirement', () => {
    const avatar = makeAvatar({ evolutionStage: 2, evolutionPathId: 'food_stage2', level: 6 });
    expect(checkDevolution(avatar, 6, mockPaths)).toBeNull();
  });

  it('devolves from stage 2 to stage 1 when level < 5', () => {
    const avatar = makeAvatar({ evolutionStage: 2, evolutionPathId: 'food_stage2', level: 4 });
    const result = checkDevolution(avatar, 4, mockPaths);
    expect(result).toEqual({ newStage: 1, newPathId: null, newSpriteKey: 'sprites/stage1/default' });
  });

  it('devolves from stage 3 to stage 2 when level < 15', () => {
    const avatar = makeAvatar({ evolutionStage: 3, evolutionPathId: 'food_gorge_stage3', level: 14 });
    const result = checkDevolution(avatar, 14, mockPaths);
    expect(result?.newStage).toBe(2);
    expect(result?.newPathId).toBe('food_stage2');
  });
});

describe('checkSkillAcquisition', () => {
  it('returns skills that meet level requirement', () => {
    const avatar = makeAvatar({ level: 5, evolutionPathId: 'food_stage2', skillIds: [] });
    const result = checkSkillAcquisition(avatar, mockSkills);
    expect(result).toHaveLength(1);
    expect(result[0].skillId).toBe('food_s2_1');
  });

  it('does not return already acquired skills', () => {
    const avatar = makeAvatar({ level: 10, evolutionPathId: 'food_stage2', skillIds: ['food_s2_1', 'food_s2_2'] });
    const result = checkSkillAcquisition(avatar, mockSkills);
    expect(result).toHaveLength(0);
  });
});

describe('getSkillsToLose', () => {
  it('returns skills belonging to lost path', () => {
    const avatar = makeAvatar({ skillIds: ['food_s2_1', 'food_s2_2'] });
    const result = getSkillsToLose(avatar, 'food_stage2', mockSkills);
    expect(result).toHaveLength(2);
  });
});

describe('recalculateStats', () => {
  it('returns initial stats at level 1', () => {
    const result = recalculateStats(1, null);
    expect(result).toEqual({ hp: 50, attack: 10, defense: 10, speed: 10 });
  });

  it('applies growth per level with path', () => {
    const path = mockPaths[0]; // food_stage2: hp+8, atk+5, def+4, spd+2
    const result = recalculateStats(5, path);
    expect(result).toEqual({ hp: 50 + 4 * 8, attack: 10 + 4 * 5, defense: 10 + 4 * 4, speed: 10 + 4 * 2 });
  });
});
