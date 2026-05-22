import app from '../src/app';

jest.mock('../src/utils/dynamo-client', () => ({
  docClient: { send: jest.fn() },
  AVATAR_TABLE: 'test-avatars',
  EVOLUTION_PATH_TABLE: 'test-paths',
  SKILL_TABLE: 'test-skills',
  AUDIT_LOG_TABLE: 'test-audit',
  GAME_CONFIG_TABLE: 'test-config',
  RECORDING_TABLE: 'test-recordings',
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
});
