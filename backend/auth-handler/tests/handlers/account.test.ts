import { handleDeleteAccount } from '../../src/handlers/account';
import { dynamoClient } from '../../src/utils/dynamo-client';
import { cognitoClient } from '../../src/utils/cognito-client';
import { APIGatewayProxyEvent } from 'aws-lambda';

jest.mock('../../src/utils/dynamo-client', () => ({
  dynamoClient: { send: jest.fn() },
  USERS_TABLE: 'test-users-table',
}));

jest.mock('../../src/utils/cognito-client', () => ({
  cognitoClient: { send: jest.fn() },
  USER_POOL_ID: 'test-pool-id',
}));

const mockEvent = (claims: Record<string, string> | null): APIGatewayProxyEvent =>
  ({
    requestContext: {
      authorizer: claims ? { claims } : undefined,
    },
  } as any);

describe('handleDeleteAccount', () => {
  it('returns 401 if no userId in claims', async () => {
    const result = await handleDeleteAccount(mockEvent(null));
    expect(result.statusCode).toBe(401);
  });

  it('returns 200 and deletes DynamoDB + Cognito user on success', async () => {
    (dynamoClient.send as jest.Mock).mockResolvedValue({});
    (cognitoClient.send as jest.Mock).mockResolvedValue({});

    const result = await handleDeleteAccount(
      mockEvent({ sub: 'user-123', 'cognito:username': 'testuser' })
    );

    expect(result.statusCode).toBe(200);
    expect(JSON.parse(result.body).message).toBe('Account deleted');
    expect(dynamoClient.send).toHaveBeenCalledTimes(1);
    expect(cognitoClient.send).toHaveBeenCalledTimes(1);
  });

  it('returns 500 when DynamoDB delete fails', async () => {
    (dynamoClient.send as jest.Mock).mockRejectedValue(new Error('DynamoDB error'));

    const result = await handleDeleteAccount(
      mockEvent({ sub: 'user-123', 'cognito:username': 'testuser' })
    );

    expect(result.statusCode).toBe(500);
  });

  it('returns 500 when Cognito delete fails', async () => {
    (dynamoClient.send as jest.Mock).mockResolvedValue({});
    (cognitoClient.send as jest.Mock).mockRejectedValue(new Error('Cognito error'));

    const result = await handleDeleteAccount(
      mockEvent({ sub: 'user-123', 'cognito:username': 'testuser' })
    );

    expect(result.statusCode).toBe(500);
  });

  it('uses sub as username fallback when cognito:username is missing', async () => {
    (dynamoClient.send as jest.Mock).mockResolvedValue({});
    (cognitoClient.send as jest.Mock).mockResolvedValue({});

    const result = await handleDeleteAccount(mockEvent({ sub: 'user-123' }));

    expect(result.statusCode).toBe(200);
    // Cognito should have been called with 'user-123' as Username
    const cognitoCall = (cognitoClient.send as jest.Mock).mock.calls[0][0];
    expect(cognitoCall.input.Username).toBe('user-123');
  });
});
