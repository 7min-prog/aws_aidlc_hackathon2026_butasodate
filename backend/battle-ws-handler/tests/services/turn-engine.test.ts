const mockSend = jest.fn();
jest.mock('@aws-sdk/client-dynamodb', () => ({
  DynamoDBClient: jest.fn(() => ({})),
}));
jest.mock('@aws-sdk/lib-dynamodb', () => ({
  DynamoDBDocumentClient: { from: () => ({ send: mockSend }) },
  GetCommand: jest.fn((input: any) => ({ input })),
}));

import { executeTurnLogic } from '../../src/services/turn-engine';

describe('executeTurnLogic', () => {
  beforeEach(() => {
    mockSend.mockReset();
    // Default: スキル解決時にDBから返すモック
    mockSend.mockResolvedValue({ Item: { skillId: 'test', skillType: 'DAMAGE', power: 10, category: 'FOOD' } });
  });

  const baseMatch = {
    matchId: 'match-1',
    player1Id: 'player-1',
    player2Id: 'player-2',
    startedAt: new Date().toISOString(),
    currentTurn: 1,
    battleState: {
      player1: { maxHp: 100, currentHp: 100, attack: 20, defense: 10, speed: 15, buffs: [] },
      player2: { maxHp: 100, currentHp: 100, attack: 18, defense: 12, speed: 10, buffs: [] },
    },
  };

  it('executes damage skill and reduces HP', async () => {
    const match = {
      ...baseMatch,
      player1Action: { type: 'skill', skillType: 'DAMAGE', skillPower: 10, skillCategory: 'FOOD' },
      player2Action: { type: 'defend' },
    };

    const result = await executeTurnLogic(match);

    expect(result.battleState.player2.currentHp).toBeLessThan(100);
    expect(result.battleEnd).toBe(false);
  });

  it('defend action adds DEF_UP buff', async () => {
    const match = {
      ...baseMatch,
      player1Action: { type: 'defend' },
      player2Action: { type: 'skill', skillType: 'DAMAGE', skillPower: 10, skillCategory: 'LIFESTYLE' },
    };

    const result = await executeTurnLogic(match);

    expect(result.battleState.player1.buffs.length).toBeGreaterThan(0);
  });

  it('KO when HP reaches 0', async () => {
    const match = {
      ...baseMatch,
      battleState: {
        player1: { maxHp: 100, currentHp: 5, attack: 20, defense: 10, speed: 15, buffs: [] },
        player2: { maxHp: 100, currentHp: 100, attack: 50, defense: 10, speed: 20, buffs: [] },
      },
      player1Action: { type: 'defend' },
      player2Action: { type: 'skill', skillType: 'DAMAGE', skillPower: 30, skillCategory: 'FOOD' },
    };

    const result = await executeTurnLogic(match);

    expect(result.battleEnd).toBe(true);
    expect(result.winnerId).toBe('player-2');
    expect(result.finishReason).toBe('KO');
  });

  it('timeout results in higher HP% winning', async () => {
    const fiveMinutesAgo = new Date(Date.now() - 6 * 60 * 1000).toISOString();
    const match = {
      ...baseMatch,
      startedAt: fiveMinutesAgo,
      battleState: {
        player1: { maxHp: 100, currentHp: 80, attack: 20, defense: 10, speed: 15, buffs: [] },
        player2: { maxHp: 100, currentHp: 50, attack: 18, defense: 12, speed: 10, buffs: [] },
      },
      player1Action: { type: 'defend' },
      player2Action: { type: 'defend' },
    };

    const result = await executeTurnLogic(match);

    expect(result.battleEnd).toBe(true);
    expect(result.winnerId).toBe('player-1');
    expect(result.finishReason).toBe('TIMEOUT');
  });

  it('heal skill restores HP', async () => {
    const match = {
      ...baseMatch,
      battleState: {
        player1: { maxHp: 100, currentHp: 50, attack: 20, defense: 10, speed: 15, buffs: [] },
        player2: { maxHp: 100, currentHp: 100, attack: 18, defense: 12, speed: 10, buffs: [] },
      },
      player1Action: { type: 'skill', skillType: 'HEAL', skillPower: 30 },
      player2Action: { type: 'defend' },
    };

    const result = await executeTurnLogic(match);

    expect(result.battleState.player1.currentHp).toBe(80); // 50 + 30
  });

  it('heal does not exceed maxHp', async () => {
    const match = {
      ...baseMatch,
      battleState: {
        player1: { maxHp: 100, currentHp: 90, attack: 20, defense: 10, speed: 15, buffs: [] },
        player2: { maxHp: 100, currentHp: 100, attack: 18, defense: 12, speed: 10, buffs: [] },
      },
      player1Action: { type: 'skill', skillType: 'HEAL', skillPower: 30 },
      player2Action: { type: 'defend' },
    };

    const result = await executeTurnLogic(match);

    expect(result.battleState.player1.currentHp).toBe(100);
  });

  it('minimum damage is 1', async () => {
    const match = {
      ...baseMatch,
      battleState: {
        player1: { maxHp: 100, currentHp: 100, attack: 1, defense: 10, speed: 15, buffs: [] },
        player2: { maxHp: 100, currentHp: 100, attack: 18, defense: 999, speed: 10, buffs: [] },
      },
      player1Action: { type: 'skill', skillType: 'DAMAGE', skillPower: 0, skillCategory: 'FOOD' },
      player2Action: { type: 'defend' },
    };

    const result = await executeTurnLogic(match);

    expect(result.battleState.player2.currentHp).toBeLessThanOrEqual(99);
  });

  it('default action is defend when no action provided', async () => {
    const match = {
      ...baseMatch,
      player1Action: null,
      player2Action: null,
    };

    const result = await executeTurnLogic(match);

    expect(result.battleState.player1.currentHp).toBe(100);
    expect(result.battleState.player2.currentHp).toBe(100);
    expect(result.battleEnd).toBe(false);
  });

  it('resolves skillId from DynamoDB when skillType not provided', async () => {
    mockSend.mockResolvedValue({ Item: { skillId: 'にくあつプレス', skillType: 'DAMAGE', power: 15, category: 'FOOD' } });

    const match = {
      ...baseMatch,
      player1Action: { type: 'skill', skillId: 'にくあつプレス' },
      player2Action: { type: 'defend' },
    };

    const result = await executeTurnLogic(match);

    expect(mockSend).toHaveBeenCalled();
    expect(result.battleState.player2.currentHp).toBeLessThan(100);
  });
});
