import * as avatarService from '../../src/services/avatar-service';
import { docClient } from '../../src/utils/dynamo-client';

jest.mock('../../src/utils/dynamo-client', () => ({
  docClient: { send: jest.fn() },
  AVATAR_TABLE: 'test-avatar',
  EVOLUTION_HISTORY_TABLE: 'test-history',
  PIG_SPECIES_TABLE: 'test-species',
  EVOLUTION_ROUTE_TABLE: 'test-routes',
  SKILL_TABLE: 'test-skills',
  GAME_CONFIG_TABLE: 'test-config',
}));

jest.mock('../../src/services/master-data-cache', () => ({
  getPigSpecies: jest.fn().mockResolvedValue([
    { speciesId: 'kobuta', name: 'こぶた', stage: 1, dominantCategory: 'MIXED', statsGrowth: { hp: 5, attack: 3, defense: 3, speed: 3 }, spriteSheetKey: '', iconKey: '', isActive: true },
    { speciesId: 'food_s2', name: 'ぽっちゃり', stage: 2, dominantCategory: 'FOOD', statsGrowth: { hp: 8, attack: 4, defense: 5, speed: 2 }, spriteSheetKey: '', iconKey: '', isActive: true },
    { speciesId: 'food_s3', name: 'メガトン', stage: 3, dominantCategory: 'FOOD', statsGrowth: { hp: 10, attack: 6, defense: 6, speed: 2 }, spriteSheetKey: '', iconKey: '', isActive: true },
  ]),
  getEvolutionRoutes: jest.fn().mockResolvedValue([
    { routeId: 'r1', fromSpeciesId: 'kobuta', toSpeciesId: 'food_s2', requiredLevel: 5, categoryThreshold: 0.6, conditionCategory: 'FOOD', subCategoryIds: null, subCategoryThreshold: null, priority: 1 },
    { routeId: 'r3', fromSpeciesId: 'food_s2', toSpeciesId: 'food_s3', requiredLevel: 15, categoryThreshold: 0.5, conditionCategory: 'FOOD', subCategoryIds: null, subCategoryThreshold: null, priority: 1 },
  ]),
  getSkills: jest.fn().mockResolvedValue([
    { skillId: 'sk1', name: '暴食タックル', type: 'ATTACK', speciesId: 'food_s2', requiredLevel: 5, targetStat: 'hp', multiplier: 1.5, duration: null, cooldown: 1, spriteAnimationKey: '' },
    { skillId: 'sk2', name: '満腹バリア', type: 'DEFENSE', speciesId: 'food_s2', requiredLevel: 8, targetStat: 'defense', multiplier: 2, duration: 2, cooldown: 3, spriteAnimationKey: '' },
  ]),
  getGameConfig: jest.fn().mockResolvedValue({
    INITIAL_STATS: { hp: 50, attack: 10, defense: 10, speed: 10 },
    MAX_LEVEL: 30, EVOLUTION_LEVEL_STAGE2: 5, EVOLUTION_LEVEL_STAGE3: 15,
    CATEGORY_THRESHOLD: 0.6, LEVEL_FORMULA_COEFFICIENT: 50,
  }),
}));

const mockSend = docClient.send as jest.Mock;

const baseAvatar = {
  avatarId: 'av-1', userId: 'user-1', name: 'テスト',
  totalPoints: 500, level: 3, evolutionStage: 1, currentSpeciesId: null,
  categoryPoints: { FOOD: 300, LIFESTYLE: 200, MIXED: 0 },
  subCategoryPoints: {},
  stats: { hp: 60, attack: 16, defense: 16, speed: 16 },
  skillIds: [], createdAt: '2026-01-01T00:00:00Z', updatedAt: '2026-01-01T00:00:00Z',
};

describe('avatar-service', () => {
  beforeEach(() => mockSend.mockReset());

  describe('createAvatar', () => {
    it('creates avatar with default name when name not provided', async () => {
      mockSend.mockResolvedValueOnce({ Item: undefined }); // getAvatar
      mockSend.mockResolvedValueOnce({}); // PutCommand

      const result = await avatarService.createAvatar('user-new');
      expect(result.name).toBe('ぶたさん');
      expect(result.level).toBe(1);
      expect(result.evolutionStage).toBe(1);
    });

    it('creates avatar with custom name', async () => {
      mockSend.mockResolvedValueOnce({ Item: undefined });
      mockSend.mockResolvedValueOnce({});

      const result = await avatarService.createAvatar('user-new', 'マイぶた');
      expect(result.name).toBe('マイぶた');
    });

    it('throws AVATAR_EXISTS when avatar already exists', async () => {
      mockSend.mockResolvedValueOnce({ Item: baseAvatar });

      await expect(avatarService.createAvatar('user-1')).rejects.toThrow('AVATAR_EXISTS');
    });
  });

  describe('addPoints', () => {
    it('throws AVATAR_NOT_FOUND for missing avatar', async () => {
      mockSend.mockResolvedValueOnce({ Item: undefined });
      await expect(avatarService.addPoints('ghost', 100, 'FOOD')).rejects.toThrow('AVATAR_NOT_FOUND');
    });

    it('adds points without level up', async () => {
      mockSend.mockResolvedValueOnce({ Item: { ...baseAvatar, totalPoints: 50, level: 1 } });
      mockSend.mockResolvedValueOnce({}); // saveAvatar

      const result = await avatarService.addPoints('user-1', 10, 'FOOD');
      expect(result.leveledUp).toBe(false);
      expect(result.evolved).toBe(false);
      expect(result.avatar.totalPoints).toBe(60);
      expect(result.avatar.categoryPoints.FOOD).toBe(310);
    });

    it('levels up and evolves to stage 2 when reaching level 5 with FOOD dominance', async () => {
      // totalPoints 1400 + 200 = 1600 → level 5, FOOD ratio = 1200/1600 = 0.75
      mockSend.mockResolvedValueOnce({ Item: { ...baseAvatar, totalPoints: 1400, level: 4, categoryPoints: { FOOD: 1000, LIFESTYLE: 400, MIXED: 0 } } });
      mockSend.mockResolvedValueOnce({}); // saveHistory
      mockSend.mockResolvedValueOnce({}); // saveAvatar

      const result = await avatarService.addPoints('user-1', 200, 'FOOD');
      expect(result.leveledUp).toBe(true);
      expect(result.evolved).toBe(true);
      expect(result.avatar.evolutionStage).toBe(2);
      expect(result.avatar.currentSpeciesId).toBe('food_s2');
    });

    it('acquires skill when level >= requiredLevel after evolution', async () => {
      mockSend.mockResolvedValueOnce({ Item: { ...baseAvatar, totalPoints: 1400, level: 4, categoryPoints: { FOOD: 1000, LIFESTYLE: 400, MIXED: 0 }, skillIds: [] } });
      mockSend.mockResolvedValueOnce({}); // saveHistory
      mockSend.mockResolvedValueOnce({}); // saveAvatar

      const result = await avatarService.addPoints('user-1', 200, 'FOOD');
      expect(result.newSkills.length).toBeGreaterThanOrEqual(1);
      expect(result.avatar.skillIds).toContain('sk1');
    });

    it('accumulates subCategoryPoints when provided', async () => {
      mockSend.mockResolvedValueOnce({ Item: { ...baseAvatar, subCategoryPoints: { sub_ramen: 50 } } });
      mockSend.mockResolvedValueOnce({});

      const result = await avatarService.addPoints('user-1', 12, 'FOOD', 'sub_ramen');
      expect(result.avatar.subCategoryPoints.sub_ramen).toBe(62);
    });

    it('recalculates stats with species growth after evolution', async () => {
      mockSend.mockResolvedValueOnce({ Item: { ...baseAvatar, totalPoints: 1400, level: 4, categoryPoints: { FOOD: 1000, LIFESTYLE: 400, MIXED: 0 } } });
      mockSend.mockResolvedValueOnce({});
      mockSend.mockResolvedValueOnce({});

      const result = await avatarService.addPoints('user-1', 200, 'FOOD');
      // food_s2 growth: {hp:8, attack:4, defense:5, speed:2}, level 5
      // stats = INITIAL + (5-1) * growth
      expect(result.avatar.stats.hp).toBe(50 + 4 * 8);       // 82
      expect(result.avatar.stats.attack).toBe(10 + 4 * 4);   // 26
      expect(result.avatar.stats.defense).toBe(10 + 4 * 5);  // 30
      expect(result.avatar.stats.speed).toBe(10 + 4 * 2);    // 18
    });
  });

  describe('deductPoints', () => {
    it('throws AVATAR_NOT_FOUND for missing avatar', async () => {
      mockSend.mockResolvedValueOnce({ Item: undefined });
      await expect(avatarService.deductPoints('ghost', 100, 'FOOD')).rejects.toThrow('AVATAR_NOT_FOUND');
    });

    it('deducts points without devolution', async () => {
      mockSend.mockResolvedValueOnce({ Item: { ...baseAvatar, totalPoints: 2000, level: 6, evolutionStage: 2, currentSpeciesId: 'food_s2', categoryPoints: { FOOD: 1500, LIFESTYLE: 500, MIXED: 0 } } });
      mockSend.mockResolvedValueOnce({});

      const result = await avatarService.deductPoints('user-1', 100, 'FOOD');
      expect(result.devolved).toBe(false);
      expect(result.avatar.totalPoints).toBe(1900);
      expect(result.avatar.categoryPoints.FOOD).toBe(1400);
    });

    it('does not go below 0', async () => {
      mockSend.mockResolvedValueOnce({ Item: { ...baseAvatar, totalPoints: 30, level: 1, categoryPoints: { FOOD: 20, LIFESTYLE: 10, MIXED: 0 } } });
      mockSend.mockResolvedValueOnce({});

      const result = await avatarService.deductPoints('user-1', 100, 'FOOD');
      expect(result.avatar.totalPoints).toBe(0);
      expect(result.avatar.categoryPoints.FOOD).toBe(0);
    });

    it('triggers devolution and loses skills when level drops below stage2 threshold', async () => {
      mockSend.mockResolvedValueOnce({
        Item: { ...baseAvatar, totalPoints: 1600, level: 5, evolutionStage: 2, currentSpeciesId: 'food_s2', categoryPoints: { FOOD: 1200, LIFESTYLE: 400, MIXED: 0 }, skillIds: ['sk1'] },
      });
      mockSend.mockResolvedValueOnce({}); // saveHistory
      mockSend.mockResolvedValueOnce({}); // saveAvatar

      const result = await avatarService.deductPoints('user-1', 1300, 'FOOD');
      expect(result.devolved).toBe(true);
      expect(result.avatar.evolutionStage).toBe(1);
      expect(result.avatar.currentSpeciesId).toBeNull();
      expect(result.lostSkills).toHaveLength(1);
      expect(result.lostSkills[0].skillId).toBe('sk1');
      expect(result.avatar.skillIds).not.toContain('sk1');
    });

    it('deducts subCategoryPoints when provided', async () => {
      mockSend.mockResolvedValueOnce({ Item: { ...baseAvatar, subCategoryPoints: { sub_ramen: 80 } } });
      mockSend.mockResolvedValueOnce({});

      const result = await avatarService.deductPoints('user-1', 30, 'FOOD', 'sub_ramen');
      expect(result.avatar.subCategoryPoints.sub_ramen).toBe(50);
    });
  });

  describe('getEvolutionHistory', () => {
    it('returns history sorted desc', async () => {
      mockSend.mockResolvedValueOnce({
        Items: [
          { historyId: 'h2', type: 'EVOLUTION', fromStage: 2, toStage: 3 },
          { historyId: 'h1', type: 'EVOLUTION', fromStage: 1, toStage: 2 },
        ],
      });

      const result = await avatarService.getEvolutionHistory('user-1');
      expect(result).toHaveLength(2);
      expect(result[0].historyId).toBe('h2');
    });
  });
});
