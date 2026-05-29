import { handler } from '../../src/handlers/categories';
import { APIGatewayProxyEvent } from 'aws-lambda';

const mockSend = jest.fn();
jest.mock('../../src/utils/dynamo-client', () => ({
  docClient: { send: (...args: any[]) => mockSend(...args) },
}));

process.env.ACTIVITY_CATEGORY_TABLE = 'test-categories';

function makeEvent(overrides: Partial<APIGatewayProxyEvent> = {}): APIGatewayProxyEvent {
  return {
    httpMethod: 'GET',
    resource: '/categories',
    path: '/categories',
    body: null,
    headers: {},
    multiValueHeaders: {},
    queryStringParameters: null,
    multiValueQueryStringParameters: null,
    pathParameters: null,
    stageVariables: null,
    isBase64Encoded: false,
    requestContext: { authorizer: { claims: { sub: 'user-1' } } } as any,
    ...overrides,
  } as APIGatewayProxyEvent;
}

describe('categories handler', () => {
  beforeEach(() => mockSend.mockReset());

  it('returns 401 without auth', async () => {
    const res = await handler(makeEvent({ requestContext: { authorizer: null } as any }));
    expect(res.statusCode).toBe(401);
  });

  describe('GET /categories', () => {
    it('returns categories sorted by sortOrder', async () => {
      // ScanCommand (categories)
      mockSend.mockResolvedValueOnce({
        Items: [
          { categoryId: 'c2', name: 'Sleep', isActive: true, sortOrder: 2 },
          { categoryId: 'c1', name: 'Food', isActive: true, sortOrder: 1 },
        ],
      });
      // GetCommand (version meta)
      mockSend.mockResolvedValueOnce({ Item: { categoryId: '_meta', version: 3 } });

      const res = await handler(makeEvent());
      expect(res.statusCode).toBe(200);
      const body = JSON.parse(res.body);
      expect(body.categories).toHaveLength(2);
      expect(body.categories[0].categoryId).toBe('c1');
      expect(body.version).toBe(3);
    });

    it('returns empty categories when none exist', async () => {
      mockSend.mockResolvedValueOnce({ Items: [] });
      mockSend.mockResolvedValueOnce({ Item: undefined });
      const res = await handler(makeEvent());
      expect(res.statusCode).toBe(200);
      const body = JSON.parse(res.body);
      expect(body.categories).toEqual([]);
      expect(body.version).toBe(1);
    });
  });

  describe('GET /categories/version', () => {
    it('returns version number', async () => {
      mockSend.mockResolvedValueOnce({ Item: { categoryId: '_meta', version: 5 } });
      const res = await handler(makeEvent({ resource: '/categories/version' }));
      expect(res.statusCode).toBe(200);
      expect(JSON.parse(res.body).version).toBe(5);
    });

    it('returns default version 1 when meta not found', async () => {
      mockSend.mockResolvedValueOnce({ Item: undefined });
      const res = await handler(makeEvent({ resource: '/categories/version' }));
      expect(res.statusCode).toBe(200);
      expect(JSON.parse(res.body).version).toBe(1);
    });
  });

  it('returns 500 on DynamoDB error', async () => {
    mockSend.mockRejectedValue(new Error('DDB failure'));
    const res = await handler(makeEvent());
    expect(res.statusCode).toBe(500);
  });
});
