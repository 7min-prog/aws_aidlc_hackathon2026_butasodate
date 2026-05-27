import app from '../../src/app';

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
  getEvolutionRoutes: jest.fn().mockResolvedValue([]),
  getPigSpecies: jest.fn().mockResolvedValue([]),
  getSkills: jest.fn().mockResolvedValue([]),
  getGameConfig: jest.fn().mockResolvedValue({
    INITIAL_STATS: { hp: 50, attack: 10, defense: 10, speed: 10 },
    MAX_LEVEL: 30, EVOLUTION_LEVEL_STAGE2: 5, EVOLUTION_LEVEL_STAGE3: 15,
    CATEGORY_THRESHOLD: 0.6, LEVEL_FORMULA_COEFFICIENT: 50,
  }),
}));

describe('Avatar Handler - Status Codes & CORS', () => {
  describe('401 Unauthorized (no auth)', () => {
    it('GET /avatar returns 401 with CORS headers', async () => {
      const res = await app.request('/avatar');
      expect(res.status).toBe(401);
      expect(res.headers.get('access-control-allow-origin')).toBe('*');
      const body = await res.json() as any;
      expect(body.error).toBe('Unauthorized');
    });

    it('POST /avatar returns 401 with CORS headers', async () => {
      const res = await app.request('/avatar', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'test' }),
      });
      expect(res.status).toBe(401);
      expect(res.headers.get('access-control-allow-origin')).toBe('*');
    });

    it('GET /avatar/evolution-history returns 401 with CORS headers', async () => {
      const res = await app.request('/avatar/evolution-history');
      expect(res.status).toBe(401);
      expect(res.headers.get('access-control-allow-origin')).toBe('*');
    });

    it('PUT /avatar/name returns 401 with CORS headers', async () => {
      const res = await app.request('/avatar/name', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'test' }),
      });
      expect(res.status).toBe(401);
      expect(res.headers.get('access-control-allow-origin')).toBe('*');
    });

    it('POST /avatar/points returns 401 with CORS headers', async () => {
      const res = await app.request('/avatar/points', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ points: 10, categoryType: 'FOOD' }),
      });
      expect(res.status).toBe(401);
      expect(res.headers.get('access-control-allow-origin')).toBe('*');
    });
  });

  describe('CORS preflight', () => {
    it('OPTIONS /avatar returns CORS headers', async () => {
      const res = await app.request('/avatar', { method: 'OPTIONS' });
      expect(res.headers.get('access-control-allow-origin')).toBe('*');
      expect(res.headers.get('access-control-allow-headers')).toContain('Authorization');
    });
  });
});
