import { Avatar, AvatarStats, PigSpecies, EvolutionRoute, Skill, GameConfig } from '../types';
export declare function calculateLevel(totalPoints: number, config: GameConfig): number;
export declare function pointsForLevel(level: number, config: GameConfig): number;
/** 進化先のSpeciesを判定（EvolutionRouteベース） */
export declare function determineEvolution(avatar: Avatar, newLevel: number, species: PigSpecies[], routes: EvolutionRoute[], config: GameConfig): PigSpecies | null;
/** 退化判定 */
export declare function checkDevolution(avatar: Avatar, newLevel: number, species: PigSpecies[], routes: EvolutionRoute[], config: GameConfig): {
    newStage: number;
    newSpeciesId: string | null;
    newSpriteKey: string;
} | null;
/** スキル習得判定 */
export declare function checkSkillAcquisition(avatar: Avatar, skills: Skill[]): Skill[];
/** 退化時に失うスキル */
export declare function getSkillsToLose(avatar: Avatar, lostSpeciesId: string, skills: Skill[]): Skill[];
/** ステータス再計算 */
export declare function recalculateStats(level: number, currentSpecies: PigSpecies | null, config: GameConfig): AvatarStats;
//# sourceMappingURL=evolution-engine.d.ts.map