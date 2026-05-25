import { handleConnect, handleDisconnect } from '../../src/handlers/connection';
import { handleRequestMatch, handleCancelMatch } from '../../src/handlers/matchmaking';
import { handleRespondInvite, handleSetReady } from '../../src/handlers/battle-prep';
import { APIGatewayProxyEvent } from 'aws-lambda';

// Mock all dependencies
const mockSend = jest.fn();
jest.mock('../../src/utils/dynamo-client', () => ({
  dynamoClient: { send: (...args: any[]) => mockSend(...args) },
  CONNECTIONS_TABLE: 'test-connections',
  MATCH_QUEUE_TABLE: 'test-queue',
  MATCHES_TABLE: 'test-matches',
  BATTLE_HISTORY_TABLE: 'test-history',
  RANKINGS_TABLE: 'test-rankings',
}));

const mockSendToConnection = jest.fn().mockResolvedValue(undefined);
jest.mock('../../src/utils/ws-client', () => ({
  sendToConnection: (...args: any[]) => mockSendToConnection(...args),
}));

const mockGetUserIdFromConnection = jest.fn();
jest.mock('../../src/utils/auth', () => ({
  getUserIdFromConnection: (...args: any[]) => mockGetUserIdFromConnection(...args),
}));

describe('battle-ws-handler', () => {
  beforeEach(() => {
    mockSend.mockReset();
    mockSendToConnection.mockReset();
    mockGetUserIdFromConnection.mockReset();
  });

  describe('connection handler', () => {
    describe('handleConnect', () => {
      const baseEvent = (qs: Record<string, string> | null) =>
        ({
          requestContext: { connectionId: 'conn-1' },
          queryStringParameters: qs,
        } as unknown as APIGatewayProxyEvent);

      it('returns 401 without token', async () => {
        const res = await handleConnect(baseEvent(null));
        expect(res.statusCode).toBe(401);
      });

      it('returns 401 without userId', async () => {
        const res = await handleConnect(baseEvent({ token: 'some-token' }));
        expect(res.statusCode).toBe(401);
      });

      it('stores connection and returns 200', async () => {
        mockSend.mockResolvedValue({});
        const res = await handleConnect(baseEvent({ token: 'valid', userId: 'user-1' }));
        expect(res.statusCode).toBe(200);
        expect(mockSend).toHaveBeenCalledTimes(1);
      });
    });

    describe('handleDisconnect', () => {
      it('deletes connection record', async () => {
        // getConnectionByConnectionId
        mockSend.mockResolvedValueOnce({ Items: [{ connectionId: 'conn-1', userId: 'user-1' }] });
        // DeleteCommand
        mockSend.mockResolvedValueOnce({});
        // handleBattleDisconnect -> QueryCommand (no active matches)
        mockSend.mockResolvedValueOnce({ Items: [] });

        const res = await handleDisconnect('conn-1');
        expect(res.statusCode).toBe(200);
      });

      it('notifies opponent on disconnect during active battle', async () => {
        // getConnectionByConnectionId
        mockSend.mockResolvedValueOnce({ Items: [{ connectionId: 'conn-1', userId: 'user-1' }] });
        // DeleteCommand
        mockSend.mockResolvedValueOnce({});
        // handleBattleDisconnect -> find active match
        mockSend.mockResolvedValueOnce({
          Items: [{ matchId: 'm1', player1Id: 'user-1', player2Id: 'user-2', status: 'IN_PROGRESS' }],
        });
        // getConnectionByUserId (opponent)
        mockSend.mockResolvedValueOnce({ Items: [{ connectionId: 'conn-2', userId: 'user-2' }] });

        await handleDisconnect('conn-1');
        expect(mockSendToConnection).toHaveBeenCalledWith('conn-2', expect.objectContaining({ type: 'opponentDisconnected' }));
      });
    });
  });

  describe('matchmaking handler', () => {
    describe('handleRequestMatch', () => {
      it('returns 401 when user not found for connection', async () => {
        mockGetUserIdFromConnection.mockResolvedValue(null);
        const res = await handleRequestMatch('conn-1', { type: 'random' });
        expect(res.statusCode).toBe(401);
      });

      it('adds user to queue for random match', async () => {
        mockGetUserIdFromConnection.mockResolvedValue('user-1');
        // PutCommand (add to queue)
        mockSend.mockResolvedValueOnce({});
        // ScanCommand (no opponents)
        mockSend.mockResolvedValueOnce({ Items: [] });

        const res = await handleRequestMatch('conn-1', { type: 'random', level: 5 });
        expect(res.statusCode).toBe(200);
        expect(mockSend).toHaveBeenCalledTimes(2);
      });

      it('creates match when opponent found in queue', async () => {
        mockGetUserIdFromConnection.mockResolvedValue('user-1');
        // PutCommand (add to queue)
        mockSend.mockResolvedValueOnce({});
        // ScanCommand (opponent found)
        mockSend.mockResolvedValueOnce({
          Items: [{ userId: 'user-2', connectionId: 'conn-2', level: 5 }],
        });
        // PutCommand (create match)
        mockSend.mockResolvedValueOnce({});
        // DeleteCommand (remove user-1 from queue)
        mockSend.mockResolvedValueOnce({});
        // DeleteCommand (remove user-2 from queue)
        mockSend.mockResolvedValueOnce({});

        const res = await handleRequestMatch('conn-1', { type: 'random', level: 5 });
        expect(res.statusCode).toBe(200);
        expect(mockSendToConnection).toHaveBeenCalledTimes(2); // both players notified
      });

      it('handles friend invite', async () => {
        mockGetUserIdFromConnection.mockResolvedValue('user-1');
        // PutCommand (create match)
        mockSend.mockResolvedValueOnce({});
        // getConnectionByUserId for target
        mockSend.mockResolvedValueOnce({ Items: [{ connectionId: 'conn-2', userId: 'user-2' }] });

        const res = await handleRequestMatch('conn-1', { type: 'friend', targetId: 'user-2' });
        expect(res.statusCode).toBe(200);
        expect(mockSendToConnection).toHaveBeenCalledWith(
          'conn-2',
          expect.objectContaining({ type: 'friendInvite' })
        );
      });
    });

    describe('handleCancelMatch', () => {
      it('returns 401 when user not found', async () => {
        mockGetUserIdFromConnection.mockResolvedValue(null);
        const res = await handleCancelMatch('conn-1');
        expect(res.statusCode).toBe(401);
      });

      it('removes user from queue', async () => {
        mockGetUserIdFromConnection.mockResolvedValue('user-1');
        mockSend.mockResolvedValue({});

        const res = await handleCancelMatch('conn-1');
        expect(res.statusCode).toBe(200);
        expect(mockSend).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('battle-prep handler', () => {
    describe('handleRespondInvite', () => {
      it('returns 401 when user not found', async () => {
        mockGetUserIdFromConnection.mockResolvedValue(null);
        const res = await handleRespondInvite('conn-1', { matchId: 'm1', accept: true });
        expect(res.statusCode).toBe(401);
      });

      it('rejects invite and notifies inviter', async () => {
        mockGetUserIdFromConnection.mockResolvedValue('user-2');
        // getMatch
        mockSend.mockResolvedValueOnce({
          Item: { matchId: 'm1', player1Id: 'user-1', player2Id: 'user-2' },
        });
        // getConnectionByUserId (inviter)
        mockSend.mockResolvedValueOnce({ Items: [{ connectionId: 'conn-1', userId: 'user-1' }] });

        const res = await handleRespondInvite('conn-2', { matchId: 'm1', accept: false });
        expect(res.statusCode).toBe(200);
        expect(mockSendToConnection).toHaveBeenCalledWith(
          'conn-1',
          expect.objectContaining({ type: 'inviteRejected' })
        );
      });

      it('accepts invite and notifies both players', async () => {
        mockGetUserIdFromConnection.mockResolvedValue('user-2');
        // UpdateCommand
        mockSend.mockResolvedValueOnce({});
        // getMatch
        mockSend.mockResolvedValueOnce({
          Item: { matchId: 'm1', player1Id: 'user-1', player2Id: 'user-2' },
        });
        // getConnectionByUserId (player1)
        mockSend.mockResolvedValueOnce({ Items: [{ connectionId: 'conn-1', userId: 'user-1' }] });
        // getConnectionByUserId (player2)
        mockSend.mockResolvedValueOnce({ Items: [{ connectionId: 'conn-2', userId: 'user-2' }] });

        const res = await handleRespondInvite('conn-2', { matchId: 'm1', accept: true });
        expect(res.statusCode).toBe(200);
        expect(mockSendToConnection).toHaveBeenCalledTimes(2);
      });
    });

    describe('handleSetReady', () => {
      it('returns 401 when user not found', async () => {
        mockGetUserIdFromConnection.mockResolvedValue(null);
        const res = await handleSetReady('conn-1', { matchId: 'm1', skills: ['s1'] });
        expect(res.statusCode).toBe(401);
      });

      it('returns 404 when match not found', async () => {
        mockGetUserIdFromConnection.mockResolvedValue('user-1');
        mockSend.mockResolvedValueOnce({ Item: undefined });

        const res = await handleSetReady('conn-1', { matchId: 'invalid', skills: [] });
        expect(res.statusCode).toBe(404);
      });

      it('sets player ready without starting if opponent not ready', async () => {
        mockGetUserIdFromConnection.mockResolvedValue('user-1');
        // getMatch (first call)
        mockSend.mockResolvedValueOnce({
          Item: { matchId: 'm1', player1Id: 'user-1', player2Id: 'user-2' },
        });
        // UpdateCommand
        mockSend.mockResolvedValueOnce({});
        // getMatch (check both ready)
        mockSend.mockResolvedValueOnce({
          Item: { matchId: 'm1', player1Id: 'user-1', player2Id: 'user-2', player1Ready: true, player2Ready: false },
        });

        const res = await handleSetReady('conn-1', { matchId: 'm1', skills: ['s1', 's2'] });
        expect(res.statusCode).toBe(200);
        expect(mockSendToConnection).not.toHaveBeenCalled();
      });

      it('starts battle when both players ready', async () => {
        mockGetUserIdFromConnection.mockResolvedValue('user-2');
        // getMatch
        mockSend.mockResolvedValueOnce({
          Item: { matchId: 'm1', player1Id: 'user-1', player2Id: 'user-2' },
        });
        // UpdateCommand (set ready)
        mockSend.mockResolvedValueOnce({});
        // getMatch (both ready)
        mockSend.mockResolvedValueOnce({
          Item: { matchId: 'm1', player1Id: 'user-1', player2Id: 'user-2', player1Ready: true, player2Ready: true },
        });
        // UpdateCommand (start battle)
        mockSend.mockResolvedValueOnce({});
        // getConnectionByUserId (player1)
        mockSend.mockResolvedValueOnce({ Items: [{ connectionId: 'conn-1' }] });
        // getConnectionByUserId (player2)
        mockSend.mockResolvedValueOnce({ Items: [{ connectionId: 'conn-2' }] });

        const res = await handleSetReady('conn-2', { matchId: 'm1', skills: ['s3'] });
        expect(res.statusCode).toBe(200);
        expect(mockSendToConnection).toHaveBeenCalledTimes(2);
        expect(mockSendToConnection).toHaveBeenCalledWith(
          'conn-1',
          expect.objectContaining({ type: 'battleStart' })
        );
      });
    });
  });
});
