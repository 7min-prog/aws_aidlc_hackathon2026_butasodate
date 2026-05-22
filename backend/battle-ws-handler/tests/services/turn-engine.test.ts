import { executeTurnLogic } from '../../src/services/turn-engine';

describe('executeTurnLogic', () => {
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

  it('executes damage skill and reduces HP', () => {
    const match = {
      ...baseMatch,
      player1Action: { type: 'skill', skillType: 'DAMAGE', skillPower: 10, skillCategory: 'FOOD' },
      player2Action: { type: 'defend' },
    };

    const result = executeTurnLogic(match);

    // Player 1 is faster (speed 15 > 10), attacks first
    expect(result.battleState.player2.currentHp).toBeLessThan(100);
    expect(result.battleEnd).toBe(false);
  });

  it('defend action adds DEF_UP buff', () => {
    const match = {
      ...baseMatch,
      player1Action: { type: 'defend' },
      player2Action: { type: 'skill', skillType: 'DAMAGE', skillPower: 10, skillCategory: 'LIFESTYLE' },
    };

    const result = executeTurnLogic(match);

    // Player 1 defended, should have DEF_UP buff
    expect(result.battleState.player1.buffs.length).toBeGreaterThan(0);
  });

  it('KO when HP reaches 0', () => {
    const match = {
      ...baseMatch,
      battleState: {
        player1: { maxHp: 100, currentHp: 5, attack: 20, defense: 10, speed: 15, buffs: [] },
        player2: { maxHp: 100, currentHp: 100, attack: 50, defense: 10, speed: 20, buffs: [] },
      },
      player1Action: { type: 'defend' },
      player2Action: { type: 'skill', skillType: 'DAMAGE', skillPower: 30, skillCategory: 'FOOD' },
    };

    const result = executeTurnLogic(match);

    expect(result.battleEnd).toBe(true);
    expect(result.winnerId).toBe('player-2');
    expect(result.finishReason).toBe('KO');
  });

  it('timeout results in higher HP% winning', () => {
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

    const result = executeTurnLogic(match);

    expect(result.battleEnd).toBe(true);
    expect(result.winnerId).toBe('player-1');
    expect(result.finishReason).toBe('TIMEOUT');
  });

  it('heal skill restores HP', () => {
    const match = {
      ...baseMatch,
      battleState: {
        player1: { maxHp: 100, currentHp: 50, attack: 20, defense: 10, speed: 15, buffs: [] },
        player2: { maxHp: 100, currentHp: 100, attack: 18, defense: 12, speed: 10, buffs: [] },
      },
      player1Action: { type: 'skill', skillType: 'HEAL', skillPower: 30 },
      player2Action: { type: 'defend' },
    };

    const result = executeTurnLogic(match);

    expect(result.battleState.player1.currentHp).toBe(80); // 50 + 30
  });

  it('heal does not exceed maxHp', () => {
    const match = {
      ...baseMatch,
      battleState: {
        player1: { maxHp: 100, currentHp: 90, attack: 20, defense: 10, speed: 15, buffs: [] },
        player2: { maxHp: 100, currentHp: 100, attack: 18, defense: 12, speed: 10, buffs: [] },
      },
      player1Action: { type: 'skill', skillType: 'HEAL', skillPower: 30 },
      player2Action: { type: 'defend' },
    };

    const result = executeTurnLogic(match);

    expect(result.battleState.player1.currentHp).toBe(100); // capped at maxHp
  });

  it('minimum damage is 1', () => {
    const match = {
      ...baseMatch,
      battleState: {
        player1: { maxHp: 100, currentHp: 100, attack: 1, defense: 10, speed: 15, buffs: [] },
        player2: { maxHp: 100, currentHp: 100, attack: 18, defense: 999, speed: 10, buffs: [] },
      },
      player1Action: { type: 'skill', skillType: 'DAMAGE', skillPower: 0, skillCategory: 'FOOD' },
      player2Action: { type: 'defend' },
    };

    const result = executeTurnLogic(match);

    // Even with massive defense, minimum 1 damage
    expect(result.battleState.player2.currentHp).toBeLessThanOrEqual(99);
  });

  it('default action is defend when no action provided', () => {
    const match = {
      ...baseMatch,
      player1Action: null,
      player2Action: null,
    };

    const result = executeTurnLogic(match);

    // Both defend, no HP change
    expect(result.battleState.player1.currentHp).toBe(100);
    expect(result.battleState.player2.currentHp).toBe(100);
    expect(result.battleEnd).toBe(false);
  });
});
