import {
  calculateLevel, pointsForLevel, determineEvolution,
  checkDevolution, checkSkillAcquisition, getSkillsToLose, recalculateStats,
} from '../../src/services/evolution-engine';
import { Avatar, PigSpecies, EvolutionRoute, Skill, GameConfig } from '../../src/types';

const defaultConfig: GameConfig = {
  INITIAL_STATS: { hp: 50, attack: 10, defense: 10, speed: 10 },
  MAX_LEVEL: 30,
  EVOLUTION_LEVEL_STAGE2: 5,
  EVOLUTION_LEVEL_STAGE3: 15,
  CATEGORY_THRESHOLD: 0.6,
  LEVEL_FORMULA_COEFFICIENT: 50,
};

const mockSpecies: PigSpecies[] = [
  { speciesId: 'kobuta', name: 'こぶた', description: '', stage: 1, dominantCategory: 'MIXED', statsGrowth: { hp: 5, attack: 3, defense: 3, speed: 3 }, spriteSheetKey: 'sprites/stage1/default', iconKey: '', isActive: true },
  { speciesId: 'food_s2', name: 'ぽっちゃり', description: '', stage: 2, dominantCategory: 'FOOD', statsGrowth: { hp: 8, attack: 4, defense: 5, speed: 2 }, spriteSheetKey: 'sprites/stage2/food', iconKey: '', isActive: true },
  { speciesId: 'life_s2', name: 'まるまる', description: '', stage: 2, dominantCategory: 'LIFESTYLE', statsGrowth: { hp: 6, attack: 3, defense: 3, speed: 5 }, spriteSheetKey: 'sprites/stage2/life', iconKey: '', isActive: true },
  { speciesId: 'food_s3', name: 'メガトン', description: '', stage: 3, dominantCategory: 'FOOD', statsGrowth: { hp: 10, attack: 6, defense: 6, speed: 2 }, spriteSheetKey: 'sprites/stage3/food', iconKey: '', isActive: true },
];

const mockRoutes: EvolutionRoute[] = [
  { routeId: 'r1', fromSpeciesId: 'kobuta', toSpeciesId: 'food_s2', requiredLevel: 5, categoryThreshold: 0.6, conditionCategory: 'FOOD', subCategoryIds: null, subCategoryThreshold: null, priority: 1 },
  { routeId: 'r2', fromSpeciesId: 'kobuta', toSpeciesId: 'life_s2', requiredLevel: 5, categoryThreshold: 0.6, conditionCategory: 'LIFESTYLE', subCategoryIds: null, subCategoryThreshold: null, priority: 2 },
  { routeId: 'r3', fromSpeciesId: 'food_s2', toSpeciesId: 'food_s3', requiredLevel: 15, categoryThreshold: 0.5, conditionCategory: 'FOOD', subCategoryIds: null, subCategoryThreshold: null, priority: 1 },
];

const mockSkills: Skill[] = [
  { skillId: 'sk1', name: '暴食タックル', type: 'ATTACK', targetStat: 'hp', multiplier: 1.5, duration: null, cooldown: 1, speciesId: 'food_s2', requiredLevel: 5, spriteAnimationKey: '' },
  { skillId: 'sk2', name: '満腹バリア', type: 'DEFENSE', targetStat: 'defense', multiplier: 2, duration: 2, cooldown: 3, speciesId: 'food_s2', requiredLevel: 8, spriteAnimationKey: '' },
];

function makeAvatar(overrides: Partial<Avatar> = {}): Avatar {
  return {
    avatarId: 'av-1', userId: 'user-1', name: 'テスト',
    totalPoints: 0, level: 1, evolutionStage: 1, currentSpeciesId: null,
    categoryPoints: { FOOD: 0, LIFESTYLE: 0, MIXED: 0 },
    subCategoryPoints: {},
    stats: { hp: 50, attack: 10, defense: 10, speed: 10 },
    skillIds: [], createdAt: '2026-01-01T00:00:00Z', updatedAt: '2026-01-01T00:00:00Z',
    ...overrides,
  };
}

describe('evolution-engine', () => {
  describe('calculateLevel', () => {
    it('returns 1 for 0 points', () => {
      expect(calculateLevel(0, defaultConfig)).toBe(1);
    });

    it('returns 1 for negative points', () => {
      expect(calculateLevel(-100, defaultConfig)).toBe(1);
    });

    it('calculates correct level for 300 points', () => {
      expect(calculateLevel(300, defaultConfig)).toBe(2);
    });

    it('caps at MAX_LEVEL', () => {
      expect(calculateLevel(999999, defaultConfig)).toBe(30);
    });
  });

  describe('pointsForLevel', () => {
    it('returns points needed for level 1', () => {
      expect(pointsForLevel(1, defaultConfig)).toBe(100);
    });

    it('returns points for level 5', () => {
      expect(pointsForLevel(5, defaultConfig)).toBe(1500);
    });
  });

  describe('determineEvolution', () => {
    it('returns null when level < EVOLUTION_LEVEL_STAGE2', () => {
      const avatar = makeAvatar({ totalPoints: 500, level: 4, categoryPoints: { FOOD: 400, LIFESTYLE: 100, MIXED: 0 } });
      expect(determineEvolution(avatar, 4, mockSpecies, mockRoutes, defaultConfig)).toBeNull();
    });

    it('evolves to stage 2 food when FOOD ratio >= 0.6', () => {
      const avatar = makeAvatar({ totalPoints: 1500, level: 5, categoryPoints: { FOOD: 1000, LIFESTYLE: 500, MIXED: 0 } });
      const result = determineEvolution(avatar, 5, mockSpecies, mockRoutes, defaultConfig);
      expect(result?.speciesId).toBe('food_s2');
    });

    it('evolves to stage 2 lifestyle when LIFESTYLE ratio >= 0.6', () => {
      const avatar = makeAvatar({ totalPoints: 1500, level: 5, categoryPoints: { FOOD: 300, LIFESTYLE: 1200, MIXED: 0 } });
      const result = determineEvolution(avatar, 5, mockSpecies, mockRoutes, defaultConfig);
      expect(result?.speciesId).toBe('life_s2');
    });

    it('falls back to first priority route when no threshold met', () => {
      const avatar = makeAvatar({ totalPoints: 1500, level: 5, categoryPoints: { FOOD: 500, LIFESTYLE: 500, MIXED: 500 } });
      const result = determineEvolution(avatar, 5, mockSpecies, mockRoutes, defaultConfig);
      expect(result?.speciesId).toBe('food_s2'); // priority 1
    });

    it('evolves from stage 2 to stage 3', () => {
      const avatar = makeAvatar({
        totalPoints: 12000, level: 15, evolutionStage: 2, currentSpeciesId: 'food_s2',
        categoryPoints: { FOOD: 8000, LIFESTYLE: 4000, MIXED: 0 },
      });
      const result = determineEvolution(avatar, 15, mockSpecies, mockRoutes, defaultConfig);
      expect(result?.speciesId).toBe('food_s3');
    });
  });

  describe('checkDevolution', () => {
    it('returns null when level is sufficient', () => {
      const avatar = makeAvatar({ evolutionStage: 2, currentSpeciesId: 'food_s2', level: 6 });
      expect(checkDevolution(avatar, 6, mockSpecies, mockRoutes, defaultConfig)).toBeNull();
    });

    it('devolves stage 2 to stage 1 when below threshold', () => {
      const avatar = makeAvatar({ evolutionStage: 2, currentSpeciesId: 'food_s2', level: 4 });
      const result = checkDevolution(avatar, 4, mockSpecies, mockRoutes, defaultConfig);
      expect(result?.newStage).toBe(1);
      expect(result?.newSpeciesId).toBeNull();
    });

    it('devolves stage 3 to stage 2 with parent species', () => {
      const avatar = makeAvatar({ evolutionStage: 3, currentSpeciesId: 'food_s3', level: 14 });
      const result = checkDevolution(avatar, 14, mockSpecies, mockRoutes, defaultConfig);
      expect(result?.newStage).toBe(2);
      expect(result?.newSpeciesId).toBe('food_s2');
    });
  });

  describe('checkSkillAcquisition', () => {
    it('returns skills available at current level', () => {
      const avatar = makeAvatar({ level: 5, currentSpeciesId: 'food_s2', skillIds: [] });
      const result = checkSkillAcquisition(avatar, mockSkills);
      expect(result).toHaveLength(1);
      expect(result[0].skillId).toBe('sk1');
    });

    it('returns no skills if already acquired', () => {
      const avatar = makeAvatar({ level: 10, currentSpeciesId: 'food_s2', skillIds: ['sk1', 'sk2'] });
      expect(checkSkillAcquisition(avatar, mockSkills)).toHaveLength(0);
    });

    it('returns empty if no currentSpeciesId', () => {
      const avatar = makeAvatar({ level: 10, currentSpeciesId: null });
      expect(checkSkillAcquisition(avatar, mockSkills)).toHaveLength(0);
    });
  });

  describe('getSkillsToLose', () => {
    it('returns skills from lost species', () => {
      const avatar = makeAvatar({ skillIds: ['sk1', 'sk2'] });
      const result = getSkillsToLose(avatar, 'food_s2', mockSkills);
      expect(result).toHaveLength(2);
    });

    it('returns empty if no matching skills', () => {
      const avatar = makeAvatar({ skillIds: ['sk1'] });
      const result = getSkillsToLose(avatar, 'life_s2', mockSkills);
      expect(result).toHaveLength(0);
    });
  });

  describe('recalculateStats', () => {
    it('returns initial stats at level 1', () => {
      const result = recalculateStats(1, null, defaultConfig);
      expect(result).toEqual({ hp: 50, attack: 10, defense: 10, speed: 10 });
    });

    it('applies species growth at higher levels', () => {
      const result = recalculateStats(5, mockSpecies[1], defaultConfig); // food_s2: growth {8,4,5,2}
      expect(result.hp).toBe(50 + 4 * 8);     // 82
      expect(result.attack).toBe(10 + 4 * 4);  // 26
      expect(result.defense).toBe(10 + 4 * 5); // 30
      expect(result.speed).toBe(10 + 4 * 2);   // 18
    });
  });
});
