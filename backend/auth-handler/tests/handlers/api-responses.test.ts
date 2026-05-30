import { handler } from '../../src/index';
import { APIGatewayProxyEvent } from 'aws-lambda';

// Mock cognito and dynamo to prevent real calls
jest.mock('../../src/utils/cognito-client', () => ({
  cognitoClient: { send: jest.fn() },
  CLIENT_ID: 'test-client-id',
}));
jest.mock('../../src/utils/dynamo-client', () => ({
  dynamoClient: { send: jest.fn() },
  USERS_TABLE: 'test-users',
}));

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,OPTIONS',
};

function makeEvent(method: string, path: string, overrides: Partial<APIGatewayProxyEvent> = {}): APIGatewayProxyEvent {
  return {
    httpMethod: method,
    path,
    resource: path,
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

describe('Auth Handler - Status Codes & CORS', () => {
  describe('401 Unauthorized (protected routes without token)', () => {
    it('GET /users/me returns 401 with CORS headers', async () => {
      const res = await handler(makeEvent('GET', '/users/me'));
      expect(res.statusCode).toBe(401);
      expect(res.headers).toMatchObject(CORS_HEADERS);
      expect(JSON.parse(res.body).error).toBe('Unauthorized');
    });

    it('PUT /users/profile returns 401 with CORS headers', async () => {
      const res = await handler(makeEvent('PUT', '/users/profile', { body: '{"nickname":"test"}' }));
      expect(res.statusCode).toBe(401);
      expect(res.headers).toMatchObject(CORS_HEADERS);
    });

    it('DELETE /account returns 401 with CORS headers', async () => {
      const res = await handler(makeEvent('DELETE', '/account'));
      expect(res.statusCode).toBe(401);
      expect(res.headers).toMatchObject(CORS_HEADERS);
    });
  });

  describe('400 Bad Request (public routes with missing params)', () => {
    it('POST /auth/login without body returns 400 with CORS headers', async () => {
      const res = await handler(makeEvent('POST', '/auth/login', { body: '{}' }));
      expect(res.statusCode).toBe(400);
      expect(res.headers).toMatchObject(CORS_HEADERS);
    });

    it('POST /auth/signup without body returns 400 with CORS headers', async () => {
      const res = await handler(makeEvent('POST', '/auth/signup', { body: '{}' }));
      expect(res.statusCode).toBe(400);
      expect(res.headers).toMatchObject(CORS_HEADERS);
    });
  });

  describe('404 Not Found', () => {
    it('unknown route returns 404 with CORS headers', async () => {
      const res = await handler(makeEvent('GET', '/nonexistent'));
      expect(res.statusCode).toBe(404);
      expect(res.headers).toMatchObject(CORS_HEADERS);
      expect(JSON.parse(res.body).error).toBe('Not Found');
    });
  });
});
