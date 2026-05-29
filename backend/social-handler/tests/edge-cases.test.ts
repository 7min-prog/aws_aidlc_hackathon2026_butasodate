import { APIGatewayProxyEvent } from 'aws-lambda';

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

describe('social-handler edge cases', () => {
  beforeEach(() => mockSend.mockReset());

  describe('POST /social/friends/respond - edge cases', () => {
    it('returns 404 when request belongs to different user', async () => {
      mockSend.mockResolvedValueOnce({ Item: { requestId: 'r1', fromUserId: 'u3', toUserId: 'u2' } });
      const res = await handler(
        mockEvent('POST', '/social/friends/respond', { userId: 'u1', body: { requestId: 'r1', accept: true } })
      );
      expect(res.statusCode).toBe(404);
    });
  });

  describe('DELETE /social/friends/:id - edge cases', () => {
    it('returns 401 without auth even with pathParams', async () => {
      const res = await handler(
        mockEvent('DELETE', '/social/friends/f1', { pathParams: { friendId: 'f1' } })
      );
      expect(res.statusCode).toBe(401);
    });
  });

  describe('GET /battles/history/:id - edge cases', () => {
    it('returns 400 without matchId in path', async () => {
      const res = await handler(
        mockEvent('GET', '/battles/history/', { userId: 'u1', pathParams: {} })
      );
      expect(res.statusCode).toBe(400);
    });
  });

  describe('GET /rankings - DynamoDB returns empty', () => {
    it('returns empty rankings array', async () => {
      mockSend.mockResolvedValue({ Items: [] });
      const res = await handler(mockEvent('GET', '/rankings'));
      expect(res.statusCode).toBe(200);
      expect(JSON.parse(res.body).rankings).toEqual([]);
    });
  });

  describe('GET /rankings/me - no existing record', () => {
    it('returns default ranking with 0 points', async () => {
      mockSend.mockResolvedValue({ Item: undefined });
      const res = await handler(mockEvent('GET', '/rankings/me', { userId: 'new-user' }));
      expect(res.statusCode).toBe(200);
      const { ranking } = JSON.parse(res.body);
      expect(ranking.userId).toBe('new-user');
      expect(ranking.points).toBe(0);
    });
  });

  describe('GET /battles/history - empty history', () => {
    it('returns empty history array', async () => {
      mockSend.mockResolvedValue({ Items: [] });
      const res = await handler(mockEvent('GET', '/battles/history', { userId: 'u1' }));
      expect(res.statusCode).toBe(200);
      expect(JSON.parse(res.body).history).toEqual([]);
    });
  });

  describe('POST /social/friends/search - edge cases', () => {
    it('returns empty when no matches found', async () => {
      mockSend.mockResolvedValue({ Items: [] });
      const res = await handler(
        mockEvent('POST', '/social/friends/search', { userId: 'u1', body: { query: 'nonexistent' } })
      );
      expect(res.statusCode).toBe(200);
      expect(JSON.parse(res.body).users).toEqual([]);
    });
  });

  describe('GET /social/friends/requests - no pending', () => {
    it('returns empty requests when none pending', async () => {
      mockSend
        .mockResolvedValueOnce({ Items: [] });
      const res = await handler(mockEvent('GET', '/social/friends/requests', { userId: 'u1' }));
      expect(res.statusCode).toBe(200);
      expect(JSON.parse(res.body).requests).toEqual([]);
    });
  });
});
