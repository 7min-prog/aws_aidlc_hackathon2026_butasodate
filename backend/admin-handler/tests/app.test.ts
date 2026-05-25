import app from '../src/app';

jest.mock('../src/utils/dynamo-client', () => ({
  docClient: { send: jest.fn() },
  AVATAR_TABLE: 'test-avatars',
  PIG_SPECIES_TABLE: 'test-species',
  EVOLUTION_ROUTE_TABLE: 'test-routes',
  SKILL_TABLE: 'test-skills',
  AUDIT_LOG_TABLE: 'test-audit',
  GAME_CONFIG_TABLE: 'test-config',
  ACTIVITY_RECORD_TABLE: 'test-records',
  USER_PROFILES_TABLE: 'test-profiles',
}));

jest.mock('../src/utils/cognito-client', () => ({
  cognitoClient: { send: jest.fn() },
  USER_POOL_ID: 'test-pool',
}));

jest.mock('@aws-sdk/client-s3', () => ({ S3Client: jest.fn().mockImplementation(() => ({})), PutObjectCommand: jest.fn() }));
jest.mock('@aws-sdk/s3-request-presigner', () => ({ getSignedUrl: jest.fn().mockResolvedValue('https://s3.example.com/presigned') }));

import { docClient } from '../src/utils/dynamo-client';
import { cognitoClient } from '../src/utils/cognito-client';
import { generateToken } from '../src/utils/auth';

const mockDocSend = docClient.send as jest.Mock;
const mockCognitoSend = cognitoClient.send as jest.Mock;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const json = async (res: Response): Promise<any> => res.json();

const authHeader = { Authorization: `Bearer ${generateToken('admin')}` };

describe('Admin API', () => {
  beforeEach(() => { mockDocSend.mockReset(); mockCognitoSend.mockReset(); });

  describe('POST /admin/login', () => {
    it('returns token with valid credentials', async () => {
      const res = await app.request('/admin/login', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user: 'admin', password: 'password' }),
      });
      expect(res.status).toBe(200);
      const body = await json(res);
      expect(body.token).toBeDefined();
    });

    it('returns 401 with invalid credentials', async () => {
      const res = await app.request('/admin/login', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user: 'admin', password: 'wrong' }),
      });
      expect(res.status).toBe(401);
    });
  });

  describe('Auth middleware', () => {
    it('returns 401 without token', async () => {
      const res = await app.request('/admin/users');
      expect(res.status).toBe(401);
    });
  });

  describe('GET /admin/users', () => {
    it('returns user list', async () => {
      mockCognitoSend.mockResolvedValueOnce({
        Users: [{ Username: 'user1', UserStatus: 'CONFIRMED', Enabled: true, UserCreateDate: new Date(), Attributes: [] }],
        PaginationToken: null,
      });
      const res = await app.request('/admin/users', { headers: authHeader });
      expect(res.status).toBe(200);
      const body = await json(res);
      expect(body.users).toHaveLength(1);
    });
  });

  describe('GET /admin/users/:username', () => {
    it('returns user detail with avatar', async () => {
      mockCognitoSend.mockResolvedValueOnce({
        Username: 'user1', UserStatus: 'CONFIRMED', Enabled: true, UserCreateDate: new Date(), UserAttributes: [],
      });
      mockDocSend.mockResolvedValueOnce({ Item: { userId: 'user1', level: 5 } });
      const res = await app.request('/admin/users/user1', { headers: authHeader });
      expect(res.status).toBe(200);
      const body = await json(res);
      expect(body.username).toBe('user1');
      expect(body.avatar.level).toBe(5);
    });
  });

  describe('POST /admin/users/:username/disable', () => {
    it('disables user and logs', async () => {
      mockCognitoSend.mockResolvedValueOnce({});
      mockDocSend.mockResolvedValueOnce({}); // audit log
      const res = await app.request('/admin/users/user1/disable', { method: 'POST', headers: authHeader });
      expect(res.status).toBe(200);
    });
  });

  describe('POST /admin/users/:username/enable', () => {
    it('enables user', async () => {
      mockCognitoSend.mockResolvedValueOnce({});
      mockDocSend.mockResolvedValueOnce({});
      const res = await app.request('/admin/users/user1/enable', { method: 'POST', headers: authHeader });
      expect(res.status).toBe(200);
    });
  });

  describe('DELETE /admin/users/:username', () => {
    it('deletes user', async () => {
      mockCognitoSend.mockResolvedValueOnce({});
      mockDocSend.mockResolvedValueOnce({});
      const res = await app.request('/admin/users/user1', { method: 'DELETE', headers: authHeader });
      expect(res.status).toBe(200);
    });
  });

  describe('GET /admin/evolution-paths', () => {
    it('returns paths', async () => {
      mockDocSend.mockResolvedValueOnce({ Items: [{ pathId: 'p1', name: 'グルメぶた' }] });
      const res = await app.request('/admin/evolution-paths', { headers: authHeader });
      expect(res.status).toBe(200);
      const body = await json(res);
      expect(body.paths).toHaveLength(1);
    });
  });

  describe('POST /admin/evolution-paths', () => {
    it('creates path', async () => {
      mockDocSend.mockResolvedValueOnce({}); // put
      mockDocSend.mockResolvedValueOnce({}); // audit
      const res = await app.request('/admin/evolution-paths', {
        method: 'POST', headers: { ...authHeader, 'Content-Type': 'application/json' },
        body: JSON.stringify({ pathId: 'p2', name: '新ぶた' }),
      });
      expect(res.status).toBe(201);
    });
  });

  describe('GET /admin/game-config', () => {
    it('returns config', async () => {
      mockDocSend.mockResolvedValueOnce({ Items: [{ configKey: 'INITIAL_STATS', value: { hp: 50 } }] });
      const res = await app.request('/admin/game-config', { headers: authHeader });
      expect(res.status).toBe(200);
      const body = await json(res);
      expect(body.config).toHaveLength(1);
    });
  });

  describe('GET /admin/audit-log', () => {
    it('returns logs', async () => {
      mockDocSend.mockResolvedValueOnce({ Items: [{ logId: 'l1', action: 'DISABLE', timestamp: '2026-01-01T00:00:00Z' }] });
      const res = await app.request('/admin/audit-log', { headers: authHeader });
      expect(res.status).toBe(200);
      const body = await json(res);
      expect(body.logs).toHaveLength(1);
    });
  });

  describe('POST /admin/upload-url', () => {
    it('returns presigned url', async () => {
      const res = await app.request('/admin/upload-url', {
        method: 'POST', headers: { ...authHeader, 'Content-Type': 'application/json' },
        body: JSON.stringify({ fileName: 'pig.png', contentType: 'image/png' }),
      });
      expect(res.status).toBe(200);
      const body = await json(res);
      expect(body.uploadUrl).toContain('https://');
      expect(body.key).toContain('assets/sprites/');
    });
  });

  describe('GET /admin/doc', () => {
    it('returns OpenAPI doc', async () => {
      const res = await app.request('/admin/doc');
      expect(res.status).toBe(200);
      const body = await json(res);
      expect(body.openapi).toBe('3.1.0');
      expect(body.info.title).toBe('ぶたそだて Admin API');
    });
  });

  // --- 追加テスト: 未カバーエンドポイント ---

  describe('PUT /admin/users/:username/avatar', () => {
    it('updates avatar data', async () => {
      mockDocSend.mockResolvedValueOnce({}); // put avatar
      mockDocSend.mockResolvedValueOnce({}); // audit log
      const res = await app.request('/admin/users/user1/avatar', {
        method: 'PUT', headers: { ...authHeader, 'Content-Type': 'application/json' },
        body: JSON.stringify({ totalPoints: 9999, level: 20 }),
      });
      expect(res.status).toBe(200);
      expect((await json(res)).message).toBe('Avatar updated');
    });
  });

  describe('PUT /admin/users/:username/profile', () => {
    it('updates game data fields', async () => {
      mockDocSend.mockResolvedValueOnce({ Item: { userId: 'user1', totalPoints: 500, level: 3 } }); // get existing
      mockDocSend.mockResolvedValueOnce({}); // put avatar
      mockDocSend.mockResolvedValueOnce({}); // audit log
      const res = await app.request('/admin/users/user1/profile', {
        method: 'PUT', headers: { ...authHeader, 'Content-Type': 'application/json' },
        body: JSON.stringify({ totalPoints: 1000, level: 5 }),
      });
      expect(res.status).toBe(200);
      expect((await json(res)).message).toBe('Profile updated');
    });

    it('returns 404 when avatar not found for game fields update', async () => {
      mockDocSend.mockResolvedValueOnce({ Item: undefined });
      const res = await app.request('/admin/users/user1/profile', {
        method: 'PUT', headers: { ...authHeader, 'Content-Type': 'application/json' },
        body: JSON.stringify({ totalPoints: 1000 }),
      });
      expect(res.status).toBe(404);
    });

    it('updates nickname in user-profiles table', async () => {
      mockDocSend.mockResolvedValueOnce({}); // UpdateCommand for profiles
      mockDocSend.mockResolvedValueOnce({}); // audit log
      const res = await app.request('/admin/users/user1/profile', {
        method: 'PUT', headers: { ...authHeader, 'Content-Type': 'application/json' },
        body: JSON.stringify({ nickname: '新しい名前' }),
      });
      expect(res.status).toBe(200);
    });
  });

  describe('POST /admin/users/:username/health-data', () => {
    it('records health data manually', async () => {
      mockDocSend.mockResolvedValueOnce({}); // put record
      mockDocSend.mockResolvedValueOnce({}); // audit log
      const res = await app.request('/admin/users/user1/health-data', {
        method: 'POST', headers: { ...authHeader, 'Content-Type': 'application/json' },
        body: JSON.stringify({ weight: 70.5, steps: 8000, date: '2026-05-25' }),
      });
      expect(res.status).toBe(200);
      expect((await json(res)).message).toBe('Health data recorded');
    });
  });

  describe('PUT /admin/evolution-paths/:pathId', () => {
    it('updates species', async () => {
      mockDocSend.mockResolvedValueOnce({}); // put
      mockDocSend.mockResolvedValueOnce({}); // audit
      const res = await app.request('/admin/evolution-paths/food_s2', {
        method: 'PUT', headers: { ...authHeader, 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'ぽっちゃり改' }),
      });
      expect(res.status).toBe(200);
      expect((await json(res)).message).toBe('Species updated');
    });
  });

  describe('DELETE /admin/evolution-paths/:pathId', () => {
    it('deletes species', async () => {
      mockDocSend.mockResolvedValueOnce({}); // delete
      mockDocSend.mockResolvedValueOnce({}); // audit
      const res = await app.request('/admin/evolution-paths/food_s2', {
        method: 'DELETE', headers: authHeader,
      });
      expect(res.status).toBe(200);
      expect((await json(res)).message).toBe('Species deleted');
    });
  });

  describe('GET /admin/evolution-routes', () => {
    it('returns routes', async () => {
      mockDocSend.mockResolvedValueOnce({ Items: [{ routeId: 'r1', fromSpeciesId: 'kobuta' }] });
      const res = await app.request('/admin/evolution-routes', { headers: authHeader });
      expect(res.status).toBe(200);
      expect((await json(res)).routes).toHaveLength(1);
    });
  });

  describe('POST /admin/evolution-routes', () => {
    it('creates route', async () => {
      mockDocSend.mockResolvedValueOnce({}); // put
      mockDocSend.mockResolvedValueOnce({}); // audit
      const res = await app.request('/admin/evolution-routes', {
        method: 'POST', headers: { ...authHeader, 'Content-Type': 'application/json' },
        body: JSON.stringify({ routeId: 'r_new', fromSpeciesId: 'kobuta', toSpeciesId: 'food_s2' }),
      });
      expect(res.status).toBe(201);
    });
  });

  describe('PUT /admin/evolution-routes/:routeId', () => {
    it('updates route', async () => {
      mockDocSend.mockResolvedValueOnce({}); // put
      mockDocSend.mockResolvedValueOnce({}); // audit
      const res = await app.request('/admin/evolution-routes/r1', {
        method: 'PUT', headers: { ...authHeader, 'Content-Type': 'application/json' },
        body: JSON.stringify({ categoryThreshold: 0.7 }),
      });
      expect(res.status).toBe(200);
    });
  });

  describe('DELETE /admin/evolution-routes/:routeId', () => {
    it('deletes route', async () => {
      mockDocSend.mockResolvedValueOnce({}); // delete
      mockDocSend.mockResolvedValueOnce({}); // audit
      const res = await app.request('/admin/evolution-routes/r1', {
        method: 'DELETE', headers: authHeader,
      });
      expect(res.status).toBe(200);
    });
  });

  describe('GET /admin/skills', () => {
    it('returns skills', async () => {
      mockDocSend.mockResolvedValueOnce({ Items: [{ skillId: 'sk1', name: '暴食タックル' }] });
      const res = await app.request('/admin/skills', { headers: authHeader });
      expect(res.status).toBe(200);
      expect((await json(res)).skills).toHaveLength(1);
    });
  });

  describe('POST /admin/skills', () => {
    it('creates skill', async () => {
      mockDocSend.mockResolvedValueOnce({}); // put
      mockDocSend.mockResolvedValueOnce({}); // audit
      const res = await app.request('/admin/skills', {
        method: 'POST', headers: { ...authHeader, 'Content-Type': 'application/json' },
        body: JSON.stringify({ skillId: 'sk_new', name: '新スキル', type: 'ATTACK' }),
      });
      expect(res.status).toBe(201);
    });
  });

  describe('PUT /admin/skills/:skillId', () => {
    it('updates skill', async () => {
      mockDocSend.mockResolvedValueOnce({}); // put
      mockDocSend.mockResolvedValueOnce({}); // audit
      const res = await app.request('/admin/skills/sk1', {
        method: 'PUT', headers: { ...authHeader, 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: '暴食タックル改' }),
      });
      expect(res.status).toBe(200);
    });
  });

  describe('DELETE /admin/skills/:skillId', () => {
    it('deletes skill', async () => {
      mockDocSend.mockResolvedValueOnce({}); // delete
      mockDocSend.mockResolvedValueOnce({}); // audit
      const res = await app.request('/admin/skills/sk1', {
        method: 'DELETE', headers: authHeader,
      });
      expect(res.status).toBe(200);
    });
  });

  describe('PUT /admin/game-config', () => {
    it('updates config value', async () => {
      mockDocSend.mockResolvedValueOnce({}); // put
      mockDocSend.mockResolvedValueOnce({}); // audit
      const res = await app.request('/admin/game-config', {
        method: 'PUT', headers: { ...authHeader, 'Content-Type': 'application/json' },
        body: JSON.stringify({ configKey: 'MAX_LEVEL', value: 50 }),
      });
      expect(res.status).toBe(200);
      expect((await json(res)).message).toBe('Config updated');
    });
  });
});
