import {
  AvatarSchema,
  AvatarStatsSchema,
  SkillSchema,
  CategoryTypeSchema,
  CreateAvatarRequestSchema,
  AddPointsRequestSchema,
  DeductPointsRequestSchema,
  EvolutionHistorySchema,
} from '../src/schemas';

describe('schemas validation', () => {
  describe('CategoryTypeSchema', () => {
    it('accepts valid types', () => {
      expect(CategoryTypeSchema.parse('FOOD')).toBe('FOOD');
      expect(CategoryTypeSchema.parse('LIFESTYLE')).toBe('LIFESTYLE');
      expect(CategoryTypeSchema.parse('MIXED')).toBe('MIXED');
    });

    it('rejects invalid type', () => {
      expect(() => CategoryTypeSchema.parse('INVALID')).toThrow();
    });
  });

  describe('AvatarStatsSchema', () => {
    it('accepts valid stats', () => {
      const stats = { hp: 50, attack: 10, defense: 10, speed: 10 };
      expect(AvatarStatsSchema.parse(stats)).toEqual(stats);
    });

    it('rejects missing fields', () => {
      expect(() => AvatarStatsSchema.parse({ hp: 50 })).toThrow();
    });

    it('rejects non-number values', () => {
      expect(() => AvatarStatsSchema.parse({ hp: 'high', attack: 10, defense: 10, speed: 10 })).toThrow();
    });
  });

  describe('CreateAvatarRequestSchema', () => {
    it('accepts empty object (name is optional)', () => {
      expect(CreateAvatarRequestSchema.parse({})).toEqual({});
    });

    it('accepts with name', () => {
      expect(CreateAvatarRequestSchema.parse({ name: 'ぶーちゃん' })).toEqual({ name: 'ぶーちゃん' });
    });
  });

  describe('AddPointsRequestSchema', () => {
    it('accepts valid request', () => {
      const req = { points: 10, categoryType: 'FOOD' };
      expect(AddPointsRequestSchema.parse(req)).toMatchObject(req);
    });

    it('rejects points < 1', () => {
      expect(() => AddPointsRequestSchema.parse({ points: 0, categoryType: 'FOOD' })).toThrow();
    });

    it('rejects missing categoryType', () => {
      expect(() => AddPointsRequestSchema.parse({ points: 10 })).toThrow();
    });

    it('accepts optional subCategoryId', () => {
      const req = { points: 5, categoryType: 'LIFESTYLE', subCategoryId: 'sleep_late' };
      expect(AddPointsRequestSchema.parse(req).subCategoryId).toBe('sleep_late');
    });
  });

  describe('DeductPointsRequestSchema', () => {
    it('accepts valid request', () => {
      const req = { points: 5, categoryType: 'FOOD' };
      expect(DeductPointsRequestSchema.parse(req)).toMatchObject(req);
    });

    it('rejects points < 1', () => {
      expect(() => DeductPointsRequestSchema.parse({ points: -1, categoryType: 'FOOD' })).toThrow();
    });
  });

  describe('AvatarSchema', () => {
    const validAvatar = {
      avatarId: 'av-1',
      userId: 'user-1',
      name: 'ぶーちゃん',
      totalPoints: 100,
      level: 3,
      evolutionStage: 1,
      currentSpeciesId: 'kobuta',
      categoryPoints: { FOOD: 60, LIFESTYLE: 40 },
      subCategoryPoints: { ramen: 30 },
      stats: { hp: 60, attack: 12, defense: 11, speed: 10 },
      skillIds: ['sk1'],
      createdAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-05-01T00:00:00Z',
    };

    it('accepts valid avatar', () => {
      expect(AvatarSchema.parse(validAvatar)).toMatchObject({ avatarId: 'av-1' });
    });

    it('accepts null currentSpeciesId', () => {
      expect(AvatarSchema.parse({ ...validAvatar, currentSpeciesId: null })).toBeTruthy();
    });

    it('rejects missing required fields', () => {
      expect(() => AvatarSchema.parse({ avatarId: 'av-1' })).toThrow();
    });
  });

  describe('SkillSchema', () => {
    const validSkill = {
      skillId: 'sk1',
      name: 'タックル',
      type: 'ATTACK',
      targetStat: 'hp',
      multiplier: 1.5,
      duration: null,
      cooldown: 2,
      speciesId: 'kobuta',
      requiredLevel: 3,
      spriteAnimationKey: 'tackle',
    };

    it('accepts valid skill', () => {
      expect(SkillSchema.parse(validSkill)).toMatchObject({ skillId: 'sk1' });
    });

    it('rejects invalid type', () => {
      expect(() => SkillSchema.parse({ ...validSkill, type: 'INVALID' })).toThrow();
    });
  });

  describe('EvolutionHistorySchema', () => {
    const valid = {
      historyId: 'h1',
      userId: 'user-1',
      avatarId: 'av-1',
      fromStage: 1,
      toStage: 2,
      fromSpeciesId: 'kobuta',
      toSpeciesId: 'marumaru',
      type: 'EVOLUTION',
      triggerPoints: 500,
      occurredAt: '2026-05-01T00:00:00Z',
    };

    it('accepts valid evolution history', () => {
      expect(EvolutionHistorySchema.parse(valid)).toMatchObject({ historyId: 'h1' });
    });

    it('accepts DEVOLUTION type', () => {
      expect(EvolutionHistorySchema.parse({ ...valid, type: 'DEVOLUTION' })).toBeTruthy();
    });

    it('rejects invalid type', () => {
      expect(() => EvolutionHistorySchema.parse({ ...valid, type: 'MUTATION' })).toThrow();
    });
  });
});
