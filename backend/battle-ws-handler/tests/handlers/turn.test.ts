import { handleSelectAction } from '../../src/handlers/turn';

const mockSend = jest.fn();
jest.mock('../../src/utils/dynamo-client', () => ({
  dynamoClient: { send: (...args: any[]) => mockSend(...args) },
  CONNECTIONS_TABLE: 'test-connections',
  MATCH_QUEUE_TABLE: 'test-queue',
  MATCHES_TABLE: 'test-matches',
  BATTLE_HISTORY_TABLE: 'test-history',
  RANKINGS_TABLE: 'test-rankings',
  SKILLS_TABLE: 'test-skills',
}));

const mockSendToConnection = jest.fn().mockResolvedValue(undefined);
jest.mock('../../src/utils/ws-client', () => ({
  sendToConnection: (...args: any[]) => mockSendToConnection(...args),
}));

const mockGetUserIdFromConnection = jest.fn();
jest.mock('../../src/utils/auth', () => ({
  getUserIdFromConnection: (...args: any[]) => mockGetUserIdFromConnection(...args),
}));

// Mock connection lookup
jest.mock('../../src/handlers/connection', () => ({
  getConnectionByUserId: jest.fn().mockImplementation(async (userId: string) => {
    if (userId === 'user-1') return { connectionId: 'conn-1', userId: 'user-1' };
    if (userId === 'user-2') return { connectionId: 'conn-2', userId: 'user-2' };
    return undefined;
  }),
}));

describe('handleSelectAction', () => {
  beforeEach(() => {
    mockSend.mockReset();
    mockSendToConnection.mockReset();
    mockGetUserIdFromConnection.mockReset();
  });

  it('returns 401 when user not found for connection', async () => {
    mockGetUserIdFromConnection.mockResolvedValue(null);
    const res = await handleSelectAction('conn-1', { matchId: 'm1', action: { type: 'defend' } });
    expect(res.statusCode).toBe(401);
  });

  it('returns 400 when match not found', async () => {
    mockGetUserIdFromConnection.mockResolvedValue('user-1');
    mockSend.mockResolvedValueOnce({ Item: undefined }); // getMatch
    const res = await handleSelectAction('conn-1', { matchId: 'm1', action: { type: 'defend' } });
    expect(res.statusCode).toBe(400);
  });

  it('returns 400 when match is not IN_PROGRESS', async () => {
    mockGetUserIdFromConnection.mockResolvedValue('user-1');
    mockSend.mockResolvedValueOnce({ Item: { matchId: 'm1', status: 'FINISHED', player1Id: 'user-1' } });
    const res = await handleSelectAction('conn-1', { matchId: 'm1', action: { type: 'defend' } });
    expect(res.statusCode).toBe(400);
  });

  it('saves player1 action and returns 200 when opponent has not acted', async () => {
    mockGetUserIdFromConnection.mockResolvedValue('user-1');
    // getMatch (first)
    mockSend.mockResolvedValueOnce({
      Item: { matchId: 'm1', status: 'IN_PROGRESS', player1Id: 'user-1', player2Id: 'user-2' },
    });
    // UpdateCommand (save action)
    mockSend.mockResolvedValueOnce({});
    // getMatch (check both actions) - only player1 acted
    mockSend.mockResolvedValueOnce({
      Item: { matchId: 'm1', player1Action: { type: 'defend' }, player2Action: null },
    });

    const res = await handleSelectAction('conn-1', { matchId: 'm1', action: { type: 'defend' } });
    expect(res.statusCode).toBe(200);
    expect(mockSendToConnection).not.toHaveBeenCalled();
  });

  it('executes turn when both players have acted', async () => {
    mockGetUserIdFromConnection.mockResolvedValue('user-2');
    // getMatch (first)
    mockSend.mockResolvedValueOnce({
      Item: { matchId: 'm1', status: 'IN_PROGRESS', player1Id: 'user-1', player2Id: 'user-2', currentTurn: 1 },
    });
    // UpdateCommand (save action)
    mockSend.mockResolvedValueOnce({});
    // getMatch (check both actions)
    mockSend.mockResolvedValueOnce({
      Item: {
        matchId: 'm1', player1Id: 'user-1', player2Id: 'user-2', currentTurn: 1,
        player1Action: { type: 'skill', skillId: 's1' },
        player2Action: { type: 'defend' },
        battleState: {
          player1: { maxHp: 80, currentHp: 80, attack: 15, defense: 12, speed: 11, buffs: [] },
          player2: { maxHp: 90, currentHp: 90, attack: 18, defense: 10, speed: 13, buffs: [] },
        },
        startedAt: new Date().toISOString(),
      },
    });
    // tryExecuteTurn: UpdateCommand (conditional lock)
    mockSend.mockResolvedValueOnce({});
    // resolveSkill: GetCommand (skill lookup)
    mockSend.mockResolvedValueOnce({ Item: { skillId: 's1', skillType: 'DAMAGE', power: 15, category: 'FOOD' } });
    // UpdateCommand (update match state)
    mockSend.mockResolvedValueOnce({});

    const res = await handleSelectAction('conn-2', { matchId: 'm1', action: { type: 'defend' } });
    expect(res.statusCode).toBe(200);
    // Both players should receive turnResult
    expect(mockSendToConnection).toHaveBeenCalledTimes(2);
    expect(mockSendToConnection).toHaveBeenCalledWith('conn-1', expect.objectContaining({ type: 'turnResult' }));
    expect(mockSendToConnection).toHaveBeenCalledWith('conn-2', expect.objectContaining({ type: 'turnResult' }));
  });

  it('skips turn execution on ConditionalCheckFailedException (double execution prevention)', async () => {
    mockGetUserIdFromConnection.mockResolvedValue('user-1');
    // getMatch
    mockSend.mockResolvedValueOnce({
      Item: { matchId: 'm1', status: 'IN_PROGRESS', player1Id: 'user-1', player2Id: 'user-2', currentTurn: 1 },
    });
    // UpdateCommand (save action)
    mockSend.mockResolvedValueOnce({});
    // getMatch (both acted)
    mockSend.mockResolvedValueOnce({
      Item: {
        matchId: 'm1', player1Id: 'user-1', player2Id: 'user-2', currentTurn: 1,
        player1Action: { type: 'defend' }, player2Action: { type: 'defend' },
        battleState: {
          player1: { maxHp: 50, currentHp: 50, attack: 10, defense: 10, speed: 10, buffs: [] },
          player2: { maxHp: 50, currentHp: 50, attack: 10, defense: 10, speed: 10, buffs: [] },
        },
        startedAt: new Date().toISOString(),
      },
    });
    // tryExecuteTurn: conditional check fails (already executed)
    const { ConditionalCheckFailedException } = require('@aws-sdk/client-dynamodb');
    const err = new ConditionalCheckFailedException({ message: 'condition failed', $metadata: {} });
    mockSend.mockRejectedValueOnce(err);

    const res = await handleSelectAction('conn-1', { matchId: 'm1', action: { type: 'defend' } });
    expect(res.statusCode).toBe(200);
    // No messages sent since turn was already executed
    expect(mockSendToConnection).not.toHaveBeenCalled();
  });
});
