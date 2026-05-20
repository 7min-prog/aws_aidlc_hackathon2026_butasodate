import app from '../src/app';

// DynamoDBモック
jest.mock('../src/utils/dynamo-client', () => ({
  docClient: { send: jest.fn() },
  AVATAR_TABLE: 'test-avatar',
  EVOLUTION_HISTORY_TABLE: 'test-history',
  EVOLUTION_PATH_TABLE: 'test-paths',
  SKILL_TABLE: 'test-skills',
}));

jest.mock('../src/services/master-data-cache', () => ({
  getEvolutionPaths: jest.fn().mockResolvedValue([]),
  getSkills: jest.fn().mockResolvedValue([]),
}));

import { docClient } from '../src/utils/dynamo-client';

const mockSend = docClient.send as jest.Mock;

const mockAvatar = {
  avatarId: 'av-1', userId: 'user-1', name: 'テスト',
  totalPoints: 500, level: 3, evolutionStage: 1, evolutionPathId: null,
  categoryPoints: { FOOD: 300, LIFESTYLE: 200, MIXED: 0 },
  subCategoryPoints: {},
  stats: { hp: 60, attack: 16, defense: 16, speed: 16 },
  skillIds: [], spriteSheetKey: 'sprites/stage1/default',
  createdAt: '2026-01-01T00:00:00Z', updatedAt: '2026-01-01T00:00:00Z',
};

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const getJson = async (res: Response): Promise<any> => res.json();

describe('API Endpoints', () => {
  beforeEach(() => { mockSend.mockReset(); });

  describe('POST /avatar', () => {
    it('returns 401 without x-user-id header', async () => {
      const res = await app.request('/avatar', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({}) });
      expect(res.status).toBe(401);
    });

    it('returns 201 on successful creation', async () => {
      mockSend.mockResolvedValueOnce({ Item: undefined });
      mockSend.mockResolvedValueOnce({});
      const res = await app.request('/avatar', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': 'user-1' },
        body: JSON.stringify({ name: 'マイぶた' }),
      });
      expect(res.status).toBe(201);
      const body = await getJson(res);
      expect(body.avatar.name).toBe('マイぶた');
    });

    it('returns 409 when avatar already exists', async () => {
      mockSend.mockResolvedValueOnce({ Item: mockAvatar });
      const res = await app.request('/avatar', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': 'user-1' },
        body: JSON.stringify({}),
      });
      expect(res.status).toBe(409);
    });
  });

  describe('GET /avatar', () => {
    it('returns 401 without x-user-id header', async () => {
      const res = await app.request('/avatar');
      expect(res.status).toBe(401);
    });

    it('returns 404 when avatar not found', async () => {
      mockSend.mockResolvedValueOnce({ Item: undefined });
      const res = await app.request('/avatar', { headers: { 'x-user-id': 'user-1' } });
      expect(res.status).toBe(404);
    });

    it('returns 200 with avatar data', async () => {
      mockSend.mockResolvedValueOnce({ Item: mockAvatar });
      const res = await app.request('/avatar', { headers: { 'x-user-id': 'user-1' } });
      expect(res.status).toBe(200);
      const body = await getJson(res);
      expect(body.avatar.userId).toBe('user-1');
      expect(body.progress).toBeDefined();
      expect(body.progress.nextEvolutionLevel).toBe(5);
    });
  });

  describe('GET /avatar/evolution-history', () => {
    it('returns 200 with history', async () => {
      mockSend.mockResolvedValueOnce({ Items: [] });
      const res = await app.request('/avatar/evolution-history', { headers: { 'x-user-id': 'user-1' } });
      expect(res.status).toBe(200);
      const body = await getJson(res);
      expect(body.history).toEqual([]);
    });
  });

  describe('GET /avatar/score-detail', () => {
    it('returns 200 with score detail', async () => {
      mockSend.mockResolvedValueOnce({ Item: mockAvatar });
      const res = await app.request('/avatar/score-detail', { headers: { 'x-user-id': 'user-1' } });
      expect(res.status).toBe(200);
      const body = await getJson(res);
      expect(body.totalPoints).toBe(500);
      expect(body.nextEvolution.requiredLevel).toBe(5);
    });
  });

  describe('POST /avatar/points', () => {
    it('returns 200 on successful point addition', async () => {
      mockSend.mockResolvedValueOnce({ Item: mockAvatar });
      mockSend.mockResolvedValueOnce({});
      const res = await app.request('/avatar/points', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': 'user-1' },
        body: JSON.stringify({ points: 100, categoryType: 'FOOD' }),
      });
      expect(res.status).toBe(200);
      const body = await getJson(res);
      expect(body.avatar).toBeDefined();
      expect(body.leveledUp).toBeDefined();
    });

    it('returns 404 when avatar not found', async () => {
      mockSend.mockResolvedValueOnce({ Item: undefined });
      const res = await app.request('/avatar/points', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': 'user-1' },
        body: JSON.stringify({ points: 100, categoryType: 'FOOD' }),
      });
      expect(res.status).toBe(404);
    });
  });

  describe('POST /avatar/points/deduct', () => {
    it('returns 200 on successful point deduction', async () => {
      mockSend.mockResolvedValueOnce({ Item: mockAvatar });
      mockSend.mockResolvedValueOnce({});
      const res = await app.request('/avatar/points/deduct', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': 'user-1' },
        body: JSON.stringify({ points: 50, categoryType: 'LIFESTYLE' }),
      });
      expect(res.status).toBe(200);
      const body = await getJson(res);
      expect(body.avatar).toBeDefined();
      expect(body.devolved).toBeDefined();
    });
  });

  describe('GET /doc', () => {
    it('returns OpenAPI document', async () => {
      const res = await app.request('/doc');
      expect(res.status).toBe(200);
      const body = await getJson(res);
      expect(body.openapi).toBe('3.1.0');
      expect(body.info.title).toBe('ぶたそだて Avatar API');
      expect(body.paths['/avatar']).toBeDefined();
    });
  });
});
