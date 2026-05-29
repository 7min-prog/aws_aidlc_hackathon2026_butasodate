import {
  calculateLevel, determineEvolution, checkDevolution, recalculateStats,
} from '../../src/services/evolution-engine';
import { Avatar, PigSpecies, EvolutionRoute, GameConfig } from '../../src/types';

const config: GameConfig = {
  INITIAL_STATS: { hp: 50, attack: 10, defense: 10, speed: 10 },
  MAX_LEVEL: 30,
  EVOLUTION_LEVEL_STAGE2: 5,
  EVOLUTION_LEVEL_STAGE3: 15,
  CATEGORY_THRESHOLD: 0.6,
  LEVEL_FORMULA_COEFFICIENT: 50,
};

const species: PigSpecies[] = [
  { speciesId: 'kobuta', name: 'こぶた', description: '', stage: 1, dominantCategory: 'MIXED', statsGrowth: { hp: 5, attack: 3, defense: 3, speed: 3 }, spriteSheetKey: '', iconKey: '', isActive: true },
  { speciesId: 'food_s2', name: 'ぽっちゃり', description: '', stage: 2, dominantCategory: 'FOOD', statsGrowth: { hp: 8, attack: 4, defense: 5, speed: 2 }, spriteSheetKey: '', iconKey: '', isActive: true },
  { speciesId: 'life_s2', name: 'まるまる', description: '', stage: 2, dominantCategory: 'LIFESTYLE', statsGrowth: { hp: 6, attack: 3, defense: 3, speed: 5 }, spriteSheetKey: '', iconKey: '', isActive: true },
  { speciesId: 'food_s3', name: 'メガトン', description: '', stage: 3, dominantCategory: 'FOOD', statsGrowth: { hp: 10, attack: 6, defense: 6, speed: 2 }, spriteSheetKey: '', iconKey: '', isActive: true },
];

const routes: EvolutionRoute[] = [
  { routeId: 'r1', fromSpeciesId: 'kobuta', toSpeciesId: 'food_s2', requiredLevel: 5, categoryThreshold: 0.6, conditionCategory: 'FOOD', subCategoryIds: null, subCategoryThreshold: null, priority: 1 },
  { routeId: 'r2', fromSpeciesId: 'kobuta', toSpeciesId: 'life_s2', requiredLevel: 5, categoryThreshold: 0.6, conditionCategory: 'LIFESTYLE', subCategoryIds: null, subCategoryThreshold: null, priority: 2 },
  { routeId: 'r3', fromSpeciesId: 'food_s2', toSpeciesId: 'food_s3', requiredLevel: 15, categoryThreshold: 0.5, conditionCategory: 'FOOD', subCategoryIds: null, subCategoryThreshold: null, priority: 1 },
];

function makeAvatar(overrides: Partial<Avatar> = {}): Avatar {
  return {
    avatarId: 'av-1', userId: 'u1', name: 'テスト',
    totalPoints: 0, level: 1, evolutionStage: 1, currentSpeciesId: null,
    categoryPoints: { FOOD: 0, LIFESTYLE: 0, MIXED: 0 },
    subCategoryPoints: {}, stats: { hp: 50, attack: 10, defense: 10, speed: 10 },
    skillIds: [], createdAt: '', updatedAt: '',
    ...overrides,
  };
}

describe('evolution-engine boundary values', () => {
  describe('level boundary: exactly level 5 (stage2 evolution threshold)', () => {
    // pointsForLevel(5) = 5*6*50 = 1500
    it('level 4 → no evolution', () => {
      const avatar = makeAvatar({ totalPoints: 1499, level: 4, categoryPoints: { FOOD: 1000, LIFESTYLE: 499, MIXED: 0 } });
      expect(determineEvolution(avatar, 4, species, routes, config)).toBeNull();
    });

    it('level 5 → triggers stage2 evolution', () => {
      const avatar = makeAvatar({ totalPoints: 1500, level: 5, categoryPoints: { FOOD: 1000, LIFESTYLE: 500, MIXED: 0 } });
      const result = determineEvolution(avatar, 5, species, routes, config);
      expect(result).not.toBeNull();
      expect(result!.stage).toBe(2);
    });
  });

  describe('level boundary: exactly level 15 (stage3 evolution threshold)', () => {
    it('level 14 → no evolution from stage2', () => {
      const avatar = makeAvatar({ evolutionStage: 2, currentSpeciesId: 'food_s2', totalPoints: 10000, level: 14, categoryPoints: { FOOD: 7000, LIFESTYLE: 3000, MIXED: 0 } });
      expect(determineEvolution(avatar, 14, species, routes, config)).toBeNull();
    });

    it('level 15 → triggers stage3 evolution', () => {
      const avatar = makeAvatar({ evolutionStage: 2, currentSpeciesId: 'food_s2', totalPoints: 12000, level: 15, categoryPoints: { FOOD: 8000, LIFESTYLE: 4000, MIXED: 0 } });
      const result = determineEvolution(avatar, 15, species, routes, config);
      expect(result).not.toBeNull();
      expect(result!.speciesId).toBe('food_s3');
    });
  });

  describe('category ratio boundary: exactly 0.6 (60%)', () => {
    it('ratio 0.599 → falls back to first priority (no condition met)', () => {
      // 599/1000 = 0.599
      const avatar = makeAvatar({ totalPoints: 1000, level: 5, categoryPoints: { FOOD: 599, LIFESTYLE: 401, MIXED: 0 } });
      const result = determineEvolution(avatar, 5, species, routes, config);
      // Neither meets 0.6 → fallback to priority 1 (food_s2)
      expect(result!.speciesId).toBe('food_s2');
    });

    it('ratio exactly 0.6 → meets condition', () => {
      // 600/1000 = 0.6
      const avatar = makeAvatar({ totalPoints: 1000, level: 5, categoryPoints: { FOOD: 600, LIFESTYLE: 400, MIXED: 0 } });
      const result = determineEvolution(avatar, 5, species, routes, config);
      expect(result!.speciesId).toBe('food_s2');
    });

    it('LIFESTYLE at exactly 0.6 → evolves to lifestyle path', () => {
      const avatar = makeAvatar({ totalPoints: 1000, level: 5, categoryPoints: { FOOD: 400, LIFESTYLE: 600, MIXED: 0 } });
      const result = determineEvolution(avatar, 5, species, routes, config);
      expect(result!.speciesId).toBe('life_s2');
    });
  });

  describe('devolution boundary', () => {
    it('stage2 at level 5 → no devolution', () => {
      const avatar = makeAvatar({ evolutionStage: 2, currentSpeciesId: 'food_s2', level: 5 });
      expect(checkDevolution(avatar, 5, species, routes, config)).toBeNull();
    });

    it('stage2 at level 4 → devolves to stage1', () => {
      const avatar = makeAvatar({ evolutionStage: 2, currentSpeciesId: 'food_s2', level: 4 });
      const result = checkDevolution(avatar, 4, species, routes, config);
      expect(result!.newStage).toBe(1);
      expect(result!.newSpeciesId).toBeNull();
    });

    it('stage3 at level 15 → no devolution', () => {
      const avatar = makeAvatar({ evolutionStage: 3, currentSpeciesId: 'food_s3', level: 15 });
      expect(checkDevolution(avatar, 15, species, routes, config)).toBeNull();
    });

    it('stage3 at level 14 → devolves to stage2', () => {
      const avatar = makeAvatar({ evolutionStage: 3, currentSpeciesId: 'food_s3', level: 14 });
      const result = checkDevolution(avatar, 14, species, routes, config);
      expect(result!.newStage).toBe(2);
      expect(result!.newSpeciesId).toBe('food_s2');
    });
  });

  describe('subcategory condition path', () => {
    const subRoutes: EvolutionRoute[] = [
      ...routes,
      { routeId: 'r_sub', fromSpeciesId: 'food_s2', toSpeciesId: 'food_s3', requiredLevel: 15, categoryThreshold: 0.5, conditionCategory: 'FOOD', subCategoryIds: ['sub_ramen', 'sub_udon'], subCategoryThreshold: 0.7, priority: 0 },
    ];

    it('evolves via subcategory route when subCategory ratio >= threshold', () => {
      const avatar = makeAvatar({
        totalPoints: 12000, level: 15, evolutionStage: 2, currentSpeciesId: 'food_s2',
        categoryPoints: { FOOD: 8000, LIFESTYLE: 4000, MIXED: 0 },
        subCategoryPoints: { sub_ramen: 4000, sub_udon: 2000 }, // 6000/8000 = 0.75 >= 0.7
      });
      const result = determineEvolution(avatar, 15, species, subRoutes, config);
      expect(result!.speciesId).toBe('food_s3');
    });

    it('does not match subcategory route when ratio below threshold', () => {
      const avatar = makeAvatar({
        totalPoints: 12000, level: 15, evolutionStage: 2, currentSpeciesId: 'food_s2',
        categoryPoints: { FOOD: 8000, LIFESTYLE: 4000, MIXED: 0 },
        subCategoryPoints: { sub_ramen: 2000, sub_udon: 1000 }, // 3000/8000 = 0.375 < 0.7
      });
      // Falls through to next route (r3) which uses category ratio
      const result = determineEvolution(avatar, 15, species, subRoutes, config);
      expect(result!.speciesId).toBe('food_s3'); // still evolves via r3 fallback
    });

    it('does not match subcategory route when categoryTotal is 0', () => {
      const avatar = makeAvatar({
        totalPoints: 12000, level: 15, evolutionStage: 2, currentSpeciesId: 'food_s2',
        categoryPoints: { FOOD: 0, LIFESTYLE: 12000, MIXED: 0 },
        subCategoryPoints: { sub_ramen: 0 },
      });
      // categoryTotal for FOOD = 0, so subcategory condition returns false
      const result = determineEvolution(avatar, 15, species, subRoutes, config);
      // r_sub fails (FOOD=0), r3 fails (FOOD ratio = 0), fallback to priority 0 route
      expect(result).not.toBeNull();
    });

    it('returns false for subcategory when totalPoints is 0', () => {
      const avatar = makeAvatar({
        totalPoints: 0, level: 15, evolutionStage: 2, currentSpeciesId: 'food_s2',
        categoryPoints: { FOOD: 0, LIFESTYLE: 0, MIXED: 0 },
        subCategoryPoints: {},
      });
      // totalPoints === 0 → meetsCondition returns false for all routes → fallback
      const result = determineEvolution(avatar, 15, species, subRoutes, config);
      expect(result!.speciesId).toBe('food_s3'); // fallback to first priority route
    });
  });

  describe('calculateLevel boundary', () => {
    it('1 point → level 1', () => {
      expect(calculateLevel(1, config)).toBe(1);
    });

    it('points exactly at level 2 threshold', () => {
      // level n requires n*(n+1)*50 cumulative → level 2 = 2*3*50 = 300
      expect(calculateLevel(300, config)).toBe(2);
    });

    it('points just below level 2', () => {
      expect(calculateLevel(299, config)).toBe(1);
    });

    it('max level boundary', () => {
      expect(calculateLevel(30 * 31 * 50, config)).toBe(30);
      expect(calculateLevel(30 * 31 * 50 + 10000, config)).toBe(30);
    });
  });
});
