import { APIGatewayProxyEvent } from 'aws-lambda';

// Mock must be defined before import (jest hoists jest.mock)
const mockSend = jest.fn();
jest.mock('@aws-sdk/client-dynamodb', () => ({
  DynamoDBClient: jest.fn(() => ({})),
}));
jest.mock('@aws-sdk/lib-dynamodb', () => ({
  DynamoDBDocumentClient: { from: () => ({ send: mockSend }) },
  PutCommand: jest.fn((input: any) => ({ input })),
  DeleteCommand: jest.fn((input: any) => ({ input })),
  QueryCommand: jest.fn((input: any) => ({ input })),
  GetCommand: jest.fn((input: any) => ({ input })),
  ScanCommand: jest.fn((input: any) => ({ input })),
  UpdateCommand: jest.fn((input: any) => ({ input })),
  BatchGetCommand: jest.fn((input: any) => ({ input })),
}));

import { handler } from '../src/index';

function mockEvent(
  method: string,
  path: string,
  opts: { userId?: string; body?: object; pathParams?: Record<string, string> } = {}
): APIGatewayProxyEvent {
  return {
    httpMethod: method,
    path,
    body: opts.body ? JSON.stringify(opts.body) : null,
    pathParameters: opts.pathParams || null,
    queryStringParameters: null,
    requestContext: {
      authorizer: opts.userId ? { claims: { sub: opts.userId } } : undefined,
    },
  } as any;
}

describe('social-handler', () => {
  beforeEach(() => mockSend.mockReset());

  describe('GET /social/friends', () => {
    it('returns 401 without auth', async () => {
      const res = await handler(mockEvent('GET', '/social/friends'));
      expect(res.statusCode).toBe(401);
    });

    it('returns friends list', async () => {
      mockSend
        .mockResolvedValueOnce({ Items: [{ userId: 'u1', friendId: 'f1' }] })
        .mockResolvedValueOnce({ Responses: { 'butasodate-user-profiles': [{ userId: 'f1', nickname: 'taro' }] } });
      const res = await handler(mockEvent('GET', '/social/friends', { userId: 'u1' }));
      expect(res.statusCode).toBe(200);
      const { friends } = JSON.parse(res.body);
      expect(friends).toHaveLength(1);
      expect(friends[0].nickname).toBe('taro');
    });

    it('returns empty array when no friends', async () => {
      mockSend.mockResolvedValue({ Items: [] });
      const res = await handler(mockEvent('GET', '/social/friends', { userId: 'u1' }));
      expect(res.statusCode).toBe(200);
      expect(JSON.parse(res.body).friends).toEqual([]);
    });
  });

  describe('POST /social/friends/search', () => {
    it('returns 400 without query', async () => {
      const res = await handler(mockEvent('POST', '/social/friends/search', { body: {} }));
      expect(res.statusCode).toBe(400);
    });

    it('returns matching users', async () => {
      mockSend.mockResolvedValue({ Items: [{ userId: 'u2', nickname: 'taro' }] });
      const res = await handler(
        mockEvent('POST', '/social/friends/search', { body: { query: 'taro' } })
      );
      expect(res.statusCode).toBe(200);
      expect(JSON.parse(res.body).users).toHaveLength(1);
    });

    it('excludes the requesting user from search results', async () => {
      mockSend.mockResolvedValue({
        Items: [
          { userId: 'u1', nickname: 'taro' },
          { userId: 'u2', nickname: 'taro' },
        ],
      });
      const res = await handler(
        mockEvent('POST', '/social/friends/search', { userId: 'u1', body: { query: 'taro' } })
      );
      expect(res.statusCode).toBe(200);
      const { users } = JSON.parse(res.body);
      expect(users).toHaveLength(1);
      expect(users[0].userId).toBe('u2');
    });
  });

  describe('POST /social/friends/request', () => {
    it('returns 401 without auth', async () => {
      const res = await handler(
        mockEvent('POST', '/social/friends/request', { body: { targetUserId: 'u2' } })
      );
      expect(res.statusCode).toBe(401);
    });

    it('returns 400 without targetUserId', async () => {
      const res = await handler(
        mockEvent('POST', '/social/friends/request', { userId: 'u1', body: {} })
      );
      expect(res.statusCode).toBe(400);
    });

    it('sends friend request successfully', async () => {
      mockSend.mockResolvedValue({});
      const res = await handler(
        mockEvent('POST', '/social/friends/request', { userId: 'u1', body: { targetUserId: 'u2' } })
      );
      expect(res.statusCode).toBe(201);
      expect(mockSend).toHaveBeenCalledTimes(1);
    });
  });

  describe('POST /social/friends/respond', () => {
    it('returns 401 without auth', async () => {
      const res = await handler(
        mockEvent('POST', '/social/friends/respond', { body: { requestId: 'r1', accept: true } })
      );
      expect(res.statusCode).toBe(401);
    });

    it('returns 400 without requestId', async () => {
      const res = await handler(
        mockEvent('POST', '/social/friends/respond', { userId: 'u1', body: {} })
      );
      expect(res.statusCode).toBe(400);
    });

    it('returns 404 when request not found', async () => {
      mockSend.mockResolvedValue({ Item: undefined });
      const res = await handler(
        mockEvent('POST', '/social/friends/respond', { userId: 'u1', body: { requestId: 'r1', accept: true } })
      );
      expect(res.statusCode).toBe(404);
    });

    it('accepts friend request and creates bidirectional relationship', async () => {
      mockSend
        .mockResolvedValueOnce({ Item: { requestId: 'r1', fromUserId: 'u2', toUserId: 'u1' } })
        .mockResolvedValue({});
      const res = await handler(
        mockEvent('POST', '/social/friends/respond', { userId: 'u1', body: { requestId: 'r1', accept: true } })
      );
      expect(res.statusCode).toBe(200);
      expect(JSON.parse(res.body).message).toBe('Friend added');
    });

    it('declines friend request', async () => {
      mockSend
        .mockResolvedValueOnce({ Item: { requestId: 'r1', fromUserId: 'u2', toUserId: 'u1' } })
        .mockResolvedValue({});
      const res = await handler(
        mockEvent('POST', '/social/friends/respond', { userId: 'u1', body: { requestId: 'r1', accept: false } })
      );
      expect(res.statusCode).toBe(200);
      expect(JSON.parse(res.body).message).toBe('Request rejected');
    });
  });

  describe('DELETE /social/friends/:id', () => {
    it('returns 401 without auth', async () => {
      const res = await handler(
        mockEvent('DELETE', '/social/friends/f1', { pathParams: { id: 'f1' } })
      );
      expect(res.statusCode).toBe(401);
    });

    it('removes friend bidirectionally', async () => {
      mockSend.mockResolvedValue({});
      const res = await handler(
        mockEvent('DELETE', '/social/friends/f1', { userId: 'u1', pathParams: { id: 'f1' } })
      );
      expect(res.statusCode).toBe(200);
      expect(mockSend).toHaveBeenCalledTimes(2);
    });
  });

  describe('GET /social/friends/requests', () => {
    it('returns 401 without auth', async () => {
      const res = await handler(mockEvent('GET', '/social/friends/requests'));
      expect(res.statusCode).toBe(401);
    });

    it('returns pending requests', async () => {
      mockSend
        .mockResolvedValueOnce({ Items: [{ requestId: 'r1', fromUserId: 'u2', status: 'PENDING' }] })
        .mockResolvedValueOnce({ Responses: { 'butasodate-user-profiles': [{ userId: 'u2', nickname: 'hanako' }] } });
      const res = await handler(mockEvent('GET', '/social/friends/requests', { userId: 'u1' }));
      expect(res.statusCode).toBe(200);
      const { requests } = JSON.parse(res.body);
      expect(requests).toHaveLength(1);
      expect(requests[0].fromNickname).toBe('hanako');
    });
  });

  describe('GET /rankings', () => {
    it('returns sorted rankings', async () => {
      mockSend.mockResolvedValue({
        Items: [{ userId: 'u1', points: 100 }, { userId: 'u2', points: 200 }],
      });
      const res = await handler(mockEvent('GET', '/rankings'));
      expect(res.statusCode).toBe(200);
      const body = JSON.parse(res.body);
      expect(body.rankings[0].points).toBe(200);
      expect(body.rankings[1].points).toBe(100);
    });
  });

  describe('GET /rankings/me', () => {
    it('returns 401 without auth', async () => {
      const res = await handler(mockEvent('GET', '/rankings/me'));
      expect(res.statusCode).toBe(401);
    });

    it('returns user ranking', async () => {
      mockSend.mockResolvedValue({ Item: { userId: 'u1', points: 150, wins: 5, losses: 2 } });
      const res = await handler(mockEvent('GET', '/rankings/me', { userId: 'u1' }));
      expect(res.statusCode).toBe(200);
      expect(JSON.parse(res.body).ranking.points).toBe(150);
    });

    it('returns default ranking when no record', async () => {
      mockSend.mockResolvedValue({ Item: undefined });
      const res = await handler(mockEvent('GET', '/rankings/me', { userId: 'u1' }));
      expect(res.statusCode).toBe(200);
      expect(JSON.parse(res.body).ranking.points).toBe(0);
    });
  });

  describe('GET /battles/history', () => {
    it('returns 401 without auth', async () => {
      const res = await handler(mockEvent('GET', '/battles/history'));
      expect(res.statusCode).toBe(401);
    });

    it('returns battle history', async () => {
      mockSend.mockResolvedValue({ Items: [{ matchId: 'm1', result: 'WIN' }] });
      const res = await handler(mockEvent('GET', '/battles/history', { userId: 'u1' }));
      expect(res.statusCode).toBe(200);
      expect(JSON.parse(res.body).history).toHaveLength(1);
    });
  });

  describe('GET /battles/history/:id', () => {
    it('returns 401 without auth', async () => {
      const res = await handler(mockEvent('GET', '/battles/history/m1', { pathParams: { id: 'm1' } }));
      expect(res.statusCode).toBe(401);
    });

    it('returns 404 when battle not found', async () => {
      mockSend.mockResolvedValue({ Item: undefined });
      const res = await handler(
        mockEvent('GET', '/battles/history/m1', { userId: 'u1', pathParams: { id: 'm1' } })
      );
      expect(res.statusCode).toBe(404);
    });

    it('returns battle detail', async () => {
      mockSend.mockResolvedValue({ Item: { matchId: 'm1', userId: 'u1', result: 'WIN' } });
      const res = await handler(
        mockEvent('GET', '/battles/history/m1', { userId: 'u1', pathParams: { id: 'm1' } })
      );
      expect(res.statusCode).toBe(200);
      expect(JSON.parse(res.body).matchId).toBe('m1');
    });
  });

  describe('Unknown route', () => {
    it('returns 404', async () => {
      const res = await handler(mockEvent('GET', '/unknown'));
      expect(res.statusCode).toBe(404);
    });
  });

  describe('Error handling', () => {
    it('propagates DynamoDB errors (try/catch does not catch returned promises without await)', async () => {
      mockSend.mockImplementation(() => Promise.reject(new Error('DDB failure')));
      await expect(handler(mockEvent('GET', '/rankings'))).rejects.toThrow('DDB failure');
    });
  });
});
