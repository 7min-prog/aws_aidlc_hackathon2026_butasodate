import { handleLogout } from '../../src/handlers/logout';
import { cognitoClient } from '../../src/utils/cognito-client';
import { APIGatewayProxyEvent } from 'aws-lambda';

jest.mock('../../src/utils/cognito-client', () => ({
  cognitoClient: { send: jest.fn() },
  CLIENT_ID: 'test-client-id',
}));

describe('handleLogout', () => {
  it('returns 401 if no Authorization header', async () => {
    const event = { headers: {} } as any;
    const result = await handleLogout(event);
    expect(result.statusCode).toBe(401);
  });

  it('returns 200 on successful logout', async () => {
    (cognitoClient.send as jest.Mock).mockResolvedValue({});
    const event = { headers: { Authorization: 'Bearer valid-token' } } as any;
    const result = await handleLogout(event);
    expect(result.statusCode).toBe(200);
  });
});
