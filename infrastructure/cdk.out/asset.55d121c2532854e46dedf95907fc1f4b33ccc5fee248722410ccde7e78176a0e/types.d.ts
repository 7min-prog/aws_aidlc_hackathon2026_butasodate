export type CategoryType = 'FOOD' | 'LIFESTYLE' | 'MIXED';
export type SkillType = 'ATTACK' | 'DEFENSE' | 'DEBUFF' | 'HEAL';
export type EvolutionType = 'EVOLUTION' | 'DEVOLUTION';
export interface AvatarStats {
    hp: number;
    attack: number;
    defense: number;
    speed: number;
}
export interface Avatar {
    avatarId: string;
    userId: string;
    name: string;
    totalPoints: number;
    level: number;
    evolutionStage: number;
    currentSpeciesId: string | null;
    categoryPoints: Record<CategoryType, number>;
    subCategoryPoints: Record<string, number>;
    stats: AvatarStats;
    skillIds: string[];
    createdAt: string;
    updatedAt: string;
}
export interface PigSpecies {
    speciesId: string;
    name: string;
    description: string;
    stage: number;
    dominantCategory: CategoryType;
    statsGrowth: AvatarStats;
    spriteSheetKey: string;
    iconKey: string;
    isActive: boolean;
}
export interface EvolutionRoute {
    routeId: string;
    fromSpeciesId: string;
    toSpeciesId: string;
    requiredLevel: number;
    categoryThreshold: number;
    conditionCategory: CategoryType;
    subCategoryIds: string[] | null;
    subCategoryThreshold: number | null;
    priority: number;
}
export interface Skill {
    skillId: string;
    name: string;
    type: SkillType;
    targetStat: string;
    multiplier: number;
    duration: number | null;
    cooldown: number;
    speciesId: string;
    requiredLevel: number;
    spriteAnimationKey: string;
}
export interface EvolutionHistory {
    historyId: string;
    userId: string;
    avatarId: string;
    fromStage: number;
    toStage: number;
    fromSpeciesId: string | null;
    toSpeciesId: string | null;
    type: EvolutionType;
    triggerPoints: number;
    occurredAt: string;
}
export interface GameConfig {
    INITIAL_STATS: AvatarStats;
    MAX_LEVEL: number;
    EVOLUTION_LEVEL_STAGE2: number;
    EVOLUTION_LEVEL_STAGE3: number;
    CATEGORY_THRESHOLD: number;
    LEVEL_FORMULA_COEFFICIENT: number;
}
export interface AddPointsResult {
    avatar: Avatar;
    leveledUp: boolean;
    evolved: boolean;
    newSkills: Skill[];
}
export interface DeductPointsResult {
    avatar: Avatar;
    leveledDown: boolean;
    devolved: boolean;
    lostSkills: Skill[];
}
//# sourceMappingURL=types.d.ts.map