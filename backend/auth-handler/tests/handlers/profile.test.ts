import { handleGetProfile, handleCreateProfile, handleUpdateProfile } from '../../src/handlers/profile';
import { dynamoClient } from '../../src/utils/dynamo-client';
import { APIGatewayProxyEvent } from 'aws-lambda';

jest.mock('../../src/utils/dynamo-client', () => ({
  dynamoClient: { send: jest.fn() },
  USERS_TABLE: 'test-users-table',
}));

const mockAuthEvent = (body: object | null, userId: string = 'user-123'): APIGatewayProxyEvent =>
  ({
    body: body ? JSON.stringify(body) : null,
    requestContext: {
      authorizer: { claims: { sub: userId, email: 'test@example.com' } },
    },
  } as any);

const mockUnauthEvent = (body: object | null): APIGatewayProxyEvent =>
  ({
    body: body ? JSON.stringify(body) : null,
    requestContext: { authorizer: null },
  } as any);

describe('handleGetProfile', () => {
  it('returns 401 if no userId', async () => {
    const result = await handleGetProfile(mockUnauthEvent(null));
    expect(result.statusCode).toBe(401);
  });

  it('returns 200 with user data', async () => {
    (dynamoClient.send as jest.Mock).mockResolvedValue({
      Item: { userId: 'user-123', nickname: 'テスト太郎' },
    });
    const result = await handleGetProfile(mockAuthEvent(null));
    expect(result.statusCode).toBe(200);
    expect(JSON.parse(result.body).nickname).toBe('テスト太郎');
  });

  it('returns 404 if profile not found', async () => {
    (dynamoClient.send as jest.Mock).mockResolvedValue({ Item: undefined });
    const result = await handleGetProfile(mockAuthEvent(null));
    expect(result.statusCode).toBe(404);
  });
});

describe('handleCreateProfile', () => {
  it('returns 401 if no userId', async () => {
    const result = await handleCreateProfile(mockUnauthEvent({ nickname: 'テスト' }));
    expect(result.statusCode).toBe(401);
  });

  it('returns 400 if nickname is too short', async () => {
    const result = await handleCreateProfile(mockAuthEvent({ nickname: 'あ' }));
    expect(result.statusCode).toBe(400);
  });

  it('returns 400 if nickname is too long', async () => {
    const result = await handleCreateProfile(mockAuthEvent({ nickname: 'あいうえおかきくけこさ' }));
    expect(result.statusCode).toBe(400);
  });

  it('returns 409 if nickname is taken', async () => {
    (dynamoClient.send as jest.Mock).mockResolvedValueOnce({
      Items: [{ userId: 'other-user', nickname: 'テスト太郎' }],
    });
    const result = await handleCreateProfile(mockAuthEvent({ nickname: 'テスト太郎' }));
    expect(result.statusCode).toBe(409);
  });

  it('returns 201 on successful creation', async () => {
    (dynamoClient.send as jest.Mock)
      .mockResolvedValueOnce({ Items: [] })  // nickname check
      .mockResolvedValueOnce({});            // put item
    const result = await handleCreateProfile(mockAuthEvent({ nickname: 'テスト太郎' }));
    expect(result.statusCode).toBe(201);
  });
});

describe('handleUpdateProfile', () => {
  it('returns 400 if nickname is too short', async () => {
    const result = await handleUpdateProfile(mockAuthEvent({ nickname: 'あ' }));
    expect(result.statusCode).toBe(400);
  });

  it('returns 409 if nickname is taken by another user', async () => {
    (dynamoClient.send as jest.Mock).mockResolvedValueOnce({
      Items: [{ userId: 'other-user', nickname: 'テスト次郎' }],
    });
    const result = await handleUpdateProfile(mockAuthEvent({ nickname: 'テスト次郎' }));
    expect(result.statusCode).toBe(409);
  });

  it('allows keeping own nickname', async () => {
    (dynamoClient.send as jest.Mock)
      .mockResolvedValueOnce({ Items: [{ userId: 'user-123', nickname: 'テスト太郎' }] })
      .mockResolvedValueOnce({});
    const result = await handleUpdateProfile(mockAuthEvent({ nickname: 'テスト太郎' }));
    expect(result.statusCode).toBe(200);
  });
});
