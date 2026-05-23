"use strict";
// ダメージ計算式: (攻撃力 - 防御力) ± 10%ランダム幅（最低1ダメージ保証）
// 属性相性: FOOD > LIFESTYLE > FOOD（三すくみではなく、不健康カテゴリ連動）
Object.defineProperty(exports, "__esModule", { value: true });
exports.executeTurnLogic = executeTurnLogic;
function executeTurnLogic(match) {
    const p1 = {
        userId: match.player1Id,
        ...match.battleState?.player1,
        action: match.player1Action || { type: 'defend' },
    };
    const p2 = {
        userId: match.player2Id,
        ...match.battleState?.player2,
        action: match.player2Action || { type: 'defend' },
    };
    // Determine action order by speed
    const [first, second] = p1.speed >= p2.speed ? [p1, p2] : [p2, p1];
    const actions = [];
    // Execute first player's action
    actions.push(executeAction(first, second));
    // Execute second player's action (if still alive)
    if (second.currentHp > 0 && first.currentHp > 0) {
        actions.push(executeAction(second, first));
    }
    // Decrease buff durations
    decreaseBuffs(p1);
    decreaseBuffs(p2);
    // Check battle end
    const battleEnd = p1.currentHp <= 0 || p2.currentHp <= 0 || isBattleTimeout(match);
    let winnerId;
    let finishReason;
    if (battleEnd) {
        if (p1.currentHp <= 0 && p2.currentHp <= 0) {
            finishReason = 'DRAW';
        }
        else if (p1.currentHp <= 0) {
            winnerId = p2.userId;
            finishReason = 'KO';
        }
        else if (p2.currentHp <= 0) {
            winnerId = p1.userId;
            finishReason = 'KO';
        }
        else {
            // Timeout - higher HP% wins
            const p1Ratio = p1.currentHp / p1.maxHp;
            const p2Ratio = p2.currentHp / p2.maxHp;
            if (p1Ratio > p2Ratio) {
                winnerId = p1.userId;
            }
            else if (p2Ratio > p1Ratio) {
                winnerId = p2.userId;
            }
            finishReason = 'TIMEOUT';
        }
    }
    return {
        battleState: {
            player1: { maxHp: p1.maxHp, currentHp: p1.currentHp, attack: p1.attack, defense: p1.defense, speed: p1.speed, buffs: p1.buffs },
            player2: { maxHp: p2.maxHp, currentHp: p2.currentHp, attack: p2.attack, defense: p2.defense, speed: p2.speed, buffs: p2.buffs },
        },
        battleEnd,
        winnerId,
        finishReason,
        actions,
    };
}
function executeAction(attacker, defender) {
    const action = attacker.action;
    if (action.type === 'defend') {
        // Defend: reduce incoming damage by 50% (lasts until end of this turn)
        attacker.buffs.push({ type: 'DEF_UP', value: 50, remainingTurns: 2 });
        return { userId: attacker.userId, action };
    }
    if (action.skillType === 'DAMAGE') {
        const damage = calculateDamage(attacker, defender, action);
        defender.currentHp = Math.max(0, defender.currentHp - damage);
        return { userId: attacker.userId, action, damage };
    }
    if (action.skillType === 'HEAL') {
        const heal = action.skillPower || 0;
        attacker.currentHp = Math.min(attacker.maxHp, attacker.currentHp + heal);
        return { userId: attacker.userId, action, heal };
    }
    if (action.skillType === 'BUFF') {
        const buff = { type: 'ATK_UP', value: action.skillPower || 20, remainingTurns: 3 };
        attacker.buffs.push(buff);
        return { userId: attacker.userId, action, buffApplied: buff };
    }
    if (action.skillType === 'DEBUFF') {
        const debuff = { type: 'DEF_DOWN', value: action.skillPower || 20, remainingTurns: 3 };
        defender.buffs.push(debuff);
        return { userId: attacker.userId, action, buffApplied: debuff };
    }
    return { userId: attacker.userId, action };
}
function calculateDamage(attacker, defender, action) {
    let atk = attacker.attack + getBuffValue(attacker.buffs, 'ATK_UP') - getBuffValue(attacker.buffs, 'ATK_DOWN');
    let def = defender.defense + getBuffValue(defender.buffs, 'DEF_UP') - getBuffValue(defender.buffs, 'DEF_DOWN');
    // Base damage: attack - defense
    let baseDamage = atk - def + (action.skillPower || 0);
    // Category advantage: FOOD > LIFESTYLE (20% bonus)
    if (action.skillCategory === 'FOOD' && hasCategory(defender, 'LIFESTYLE')) {
        baseDamage = Math.floor(baseDamage * 1.2);
    }
    else if (action.skillCategory === 'LIFESTYLE' && hasCategory(defender, 'FOOD')) {
        baseDamage = Math.floor(baseDamage * 1.2);
    }
    // Random ±10%
    const randomFactor = 0.9 + Math.random() * 0.2;
    const finalDamage = Math.floor(baseDamage * randomFactor);
    return Math.max(1, finalDamage); // Minimum 1 damage
}
function getBuffValue(buffs, type) {
    return buffs
        .filter(b => b.type === type && b.remainingTurns > 0)
        .reduce((sum, b) => sum + b.value, 0);
}
function decreaseBuffs(player) {
    player.buffs = player.buffs
        .map(b => ({ ...b, remainingTurns: b.remainingTurns - 1 }))
        .filter(b => b.remainingTurns > 0);
}
function hasCategory(_defender, _category) {
    // Simplified: in full implementation, check defender's avatar category
    return true;
}
function isBattleTimeout(match) {
    if (!match.startedAt)
        return false;
    const elapsed = Date.now() - new Date(match.startedAt).getTime();
    return elapsed >= 5 * 60 * 1000; // 5 minutes
}
