import { handleRefresh } from '../../src/handlers/refresh';
import { cognitoClient } from '../../src/utils/cognito-client';
import { APIGatewayProxyEvent } from 'aws-lambda';

jest.mock('../../src/utils/cognito-client', () => ({
  cognitoClient: { send: jest.fn() },
  CLIENT_ID: 'test-client-id',
}));

const mockEvent = (body: object): APIGatewayProxyEvent =>
  ({ body: JSON.stringify(body) } as any);

describe('handleRefresh', () => {
  it('returns 400 if refreshToken is missing', async () => {
    const result = await handleRefresh(mockEvent({}));
    expect(result.statusCode).toBe(400);
  });

  it('returns 200 with new tokens on success', async () => {
    (cognitoClient.send as jest.Mock).mockResolvedValue({
      AuthenticationResult: {
        AccessToken: 'new-access-token',
        IdToken: 'new-id-token',
        ExpiresIn: 3600,
      },
    });
    const result = await handleRefresh(mockEvent({ refreshToken: 'valid-refresh-token' }));
    expect(result.statusCode).toBe(200);

    const body = JSON.parse(result.body);
    expect(body.accessToken).toBe('new-access-token');
  });

  it('returns 401 if refresh token is expired', async () => {
    (cognitoClient.send as jest.Mock).mockRejectedValue({ name: 'NotAuthorizedException' });
    const result = await handleRefresh(mockEvent({ refreshToken: 'expired-token' }));
    expect(result.statusCode).toBe(401);
  });
});
