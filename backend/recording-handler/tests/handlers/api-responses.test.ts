import { handler as recordingHandler } from '../../src/handlers/recording';
import { handler as categoriesHandler } from '../../src/handlers/categories';
import { handler as healthSyncHandler } from '../../src/handlers/health-sync';
import { APIGatewayProxyEvent } from 'aws-lambda';

jest.mock('../../src/services/point-config-cache', () => ({
  getPointConfig: jest.fn().mockResolvedValue(require('../../src/types').DEFAULT_POINT_CONFIG),
}));

jest.mock('../../src/connectors/avatar-connector', () => ({
  addPoints: jest.fn().mockResolvedValue({ totalPoints: 100, level: 2 }),
  deductPoints: jest.fn().mockResolvedValue({ avatarStatus: {}, devolutionOccurred: false }),
}));

process.env.ACTIVITY_RECORD_TABLE = 'test-records';
process.env.ACTIVITY_CATEGORY_TABLE = 'test-categories';
process.env.HEALTH_SYNC_TABLE = 'test-health-sync';

const CORS_HEADERS = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
};

function makeEvent(overrides: Partial<APIGatewayProxyEvent> = {}): APIGatewayProxyEvent {
  return {
    httpMethod: 'GET',
    resource: '/activities',
    path: '/activities',
    body: null,
    headers: {},
    multiValueHeaders: {},
    queryStringParameters: null,
    multiValueQueryStringParameters: null,
    pathParameters: null,
    stageVariables: null,
    isBase64Encoded: false,
    requestContext: { authorizer: null } as any,
    ...overrides,
  } as APIGatewayProxyEvent;
}

describe('Recording Handler - Status Codes & CORS', () => {
  describe('401 Unauthorized (no auth token)', () => {
    it('GET /activities returns 401 with CORS headers', async () => {
      const res = await recordingHandler(makeEvent());
      expect(res.statusCode).toBe(401);
      expect(res.headers).toMatchObject(CORS_HEADERS);
      expect(JSON.parse(res.body).error).toBe('Unauthorized');
    });

    it('POST /activities returns 401 with CORS headers', async () => {
      const res = await recordingHandler(makeEvent({
        httpMethod: 'POST', resource: '/activities', body: '{}',
      }));
      expect(res.statusCode).toBe(401);
      expect(res.headers).toMatchObject(CORS_HEADERS);
    });

    it('DELETE /activities/{recordId} returns 401 with CORS headers', async () => {
      const res = await recordingHandler(makeEvent({
        httpMethod: 'DELETE', resource: '/activities/{recordId}',
        pathParameters: { recordId: 'test-id' },
      }));
      expect(res.statusCode).toBe(401);
      expect(res.headers).toMatchObject(CORS_HEADERS);
    });

    it('GET /activities/summary returns 401 with CORS headers', async () => {
      const res = await recordingHandler(makeEvent({
        resource: '/activities/summary',
      }));
      expect(res.statusCode).toBe(401);
      expect(res.headers).toMatchObject(CORS_HEADERS);
    });
  });

  describe('404 Not Found', () => {
    it('unknown route returns 404 with CORS headers', async () => {
      const res = await recordingHandler(makeEvent({
        resource: '/unknown',
        requestContext: { authorizer: { claims: { sub: 'user-1' } } } as any,
      }));
      expect(res.statusCode).toBe(404);
      expect(res.headers).toMatchObject(CORS_HEADERS);
    });
  });
});

describe('Categories Handler - Status Codes & CORS', () => {
  it('returns 401 without auth with CORS headers', async () => {
    const res = await categoriesHandler(makeEvent({ resource: '/categories' }));
    expect(res.statusCode).toBe(401);
    expect(res.headers).toMatchObject(CORS_HEADERS);
  });
});

describe('Health Sync Handler - Status Codes & CORS', () => {
  it('returns 401 without auth with CORS headers', async () => {
    const res = await healthSyncHandler(makeEvent({
      httpMethod: 'POST', resource: '/health-sync', body: '{"records":[]}',
    }));
    expect(res.statusCode).toBe(401);
    expect(res.headers).toMatchObject(CORS_HEADERS);
  });
});
