interface BattleAction {
    type: 'skill' | 'defend';
    skillId?: string;
    skillPower?: number;
    skillCategory?: 'FOOD' | 'LIFESTYLE';
    skillType?: 'DAMAGE' | 'HEAL' | 'BUFF' | 'DEBUFF';
}
interface Buff {
    type: string;
    value: number;
    remainingTurns: number;
}
interface TurnResult {
    battleState: any;
    battleEnd: boolean;
    winnerId?: string;
    finishReason?: string;
    actions: ActionResult[];
}
interface ActionResult {
    userId: string;
    action: BattleAction;
    damage?: number;
    heal?: number;
    buffApplied?: Buff;
}
export declare function executeTurnLogic(match: any): TurnResult;
export {};
