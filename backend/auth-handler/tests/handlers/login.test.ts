import { handleLogin } from '../../src/handlers/login';
import { cognitoClient } from '../../src/utils/cognito-client';
import { dynamoClient } from '../../src/utils/dynamo-client';
import { APIGatewayProxyEvent } from 'aws-lambda';

jest.mock('../../src/utils/cognito-client', () => ({
  cognitoClient: { send: jest.fn() },
  CLIENT_ID: 'test-client-id',
}));

jest.mock('../../src/utils/dynamo-client', () => ({
  dynamoClient: { send: jest.fn() },
  USERS_TABLE: 'test-users-table',
}));

const mockEvent = (body: object): APIGatewayProxyEvent =>
  ({ body: JSON.stringify(body) } as any);

// Base64 encode a fake JWT payload
const fakeIdToken = `header.${Buffer.from(JSON.stringify({ sub: 'user-123' })).toString('base64')}.signature`;

describe('handleLogin', () => {
  it('returns 400 if email is missing', async () => {
    const result = await handleLogin(mockEvent({ password: 'Test1234!' }));
    expect(result.statusCode).toBe(400);
  });

  it('returns 400 if password is missing', async () => {
    const result = await handleLogin(mockEvent({ email: 'test@example.com' }));
    expect(result.statusCode).toBe(400);
  });

  it('returns 200 with tokens on successful login', async () => {
    (cognitoClient.send as jest.Mock).mockResolvedValue({
      AuthenticationResult: {
        AccessToken: 'access-token',
        RefreshToken: 'refresh-token',
        IdToken: fakeIdToken,
        ExpiresIn: 3600,
      },
    });
    (dynamoClient.send as jest.Mock).mockResolvedValue({});

    const result = await handleLogin(mockEvent({ email: 'test@example.com', password: 'Test1234!' }));
    expect(result.statusCode).toBe(200);

    const body = JSON.parse(result.body);
    expect(body.accessToken).toBe('access-token');
    expect(body.refreshToken).toBe('refresh-token');
  });

  it('returns 401 on invalid credentials', async () => {
    (cognitoClient.send as jest.Mock).mockRejectedValue({ name: 'NotAuthorizedException' });
    const result = await handleLogin(mockEvent({ email: 'test@example.com', password: 'wrong' }));
    expect(result.statusCode).toBe(401);
  });

  it('returns 401 on user not found (same message as invalid password)', async () => {
    (cognitoClient.send as jest.Mock).mockRejectedValue({ name: 'UserNotFoundException' });
    const result = await handleLogin(mockEvent({ email: 'noone@example.com', password: 'Test1234!' }));
    expect(result.statusCode).toBe(401);
  });

  it('returns 403 if email not confirmed', async () => {
    (cognitoClient.send as jest.Mock).mockRejectedValue({ name: 'UserNotConfirmedException' });
    const result = await handleLogin(mockEvent({ email: 'test@example.com', password: 'Test1234!' }));
    expect(result.statusCode).toBe(403);
  });
});
