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
  evolutionPathId: string | null;
  categoryPoints: Record<CategoryType, number>;
  subCategoryPoints: Record<string, number>;
  stats: AvatarStats;
  skillIds: string[];
  spriteSheetKey: string;
  createdAt: string;
  updatedAt: string;
}

export interface EvolutionPath {
  pathId: string;
  name: string;
  stage: number;
  parentPathId: string | null;
  requiredLevel: number;
  dominantCategory: CategoryType;
  categoryThreshold: number;
  subCategoryIds: string[] | null;
  subCategoryThreshold: number | null;
  statsGrowth: AvatarStats;
  spriteSheetKey: string;
  description: string;
}

export interface Skill {
  skillId: string;
  name: string;
  type: SkillType;
  power: number;
  cooldown: number;
  evolutionPathId: string;
  requiredLevel: number;
  spriteAnimationKey: string;
}

export interface EvolutionHistory {
  historyId: string;
  userId: string;
  avatarId: string;
  fromStage: number;
  toStage: number;
  fromPathId: string | null;
  toPathId: string | null;
  type: EvolutionType;
  triggerPoints: number;
  occurredAt: string;
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
