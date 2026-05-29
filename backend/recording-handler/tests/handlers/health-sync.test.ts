import { handler } from '../../src/handlers/health-sync';
import { APIGatewayProxyEvent } from 'aws-lambda';

const mockSyncHealthData = jest.fn();
jest.mock('../../src/services/health-sync-service', () => ({
  HealthSyncService: jest.fn().mockImplementation(() => ({
    syncHealthData: (...args: any[]) => mockSyncHealthData(...args),
  })),
}));

jest.mock('../../src/utils/dynamo-client', () => ({
  docClient: {},
}));

function makeEvent(overrides: Partial<APIGatewayProxyEvent> = {}): APIGatewayProxyEvent {
  return {
    httpMethod: 'POST',
    resource: '/health-sync',
    path: '/health-sync',
    body: JSON.stringify({ records: [] }),
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

describe('health-sync handler', () => {
  beforeEach(() => mockSyncHealthData.mockReset());

  it('returns 401 without auth', async () => {
    const res = await handler(makeEvent({ requestContext: { authorizer: null } as any }));
    expect(res.statusCode).toBe(401);
  });

  it('calls syncHealthData with userId and records', async () => {
    const records = [{ type: 'weight', value: 75, date: '2026-05-01' }];
    mockSyncHealthData.mockResolvedValue({ synced: 1, skipped: 0 });

    const res = await handler(makeEvent({ body: JSON.stringify({ records }) }));
    expect(res.statusCode).toBe(200);
    expect(mockSyncHealthData).toHaveBeenCalledWith('user-1', records);
    expect(JSON.parse(res.body)).toEqual({ synced: 1, skipped: 0 });
  });

  it('handles empty records array', async () => {
    mockSyncHealthData.mockResolvedValue({ synced: 0, skipped: 0 });
    const res = await handler(makeEvent({ body: JSON.stringify({}) }));
    expect(res.statusCode).toBe(200);
    expect(mockSyncHealthData).toHaveBeenCalledWith('user-1', []);
  });

  it('returns 500 on service error', async () => {
    mockSyncHealthData.mockRejectedValue(new Error('service failure'));
    const res = await handler(makeEvent());
    expect(res.statusCode).toBe(500);
  });
});
