import { Avatar, AvatarStats, CategoryType, EvolutionPath, Skill } from '../types';

const INITIAL_STATS: AvatarStats = { hp: 50, attack: 10, defense: 10, speed: 10 };
const MAX_LEVEL = 30;
const STAGE2_LEVEL = 5;
const STAGE3_LEVEL = 15;
const CATEGORY_THRESHOLD = 0.6;

/** 累計ポイントからレベルを算出: N×(N+1)×50 <= totalPoints を満たす最大N */
export function calculateLevel(totalPoints: number): number {
  if (totalPoints <= 0) return 1;
  const n = Math.floor((-50 + Math.sqrt(2500 + 200 * totalPoints)) / 100);
  return Math.max(1, Math.min(MAX_LEVEL, n));
}

/** レベルNに必要な累計ポイント */
export function pointsForLevel(level: number): number {
  return level * (level + 1) * 50;
}

/** 第2段階の進化パスを判定 */
export function determineStage2Path(
  categoryPoints: Record<CategoryType, number>,
  totalPoints: number,
  paths: EvolutionPath[],
): EvolutionPath | null {
  const stage2Paths = paths.filter(p => p.stage === 2);
  const foodRatio = totalPoints > 0 ? (categoryPoints.FOOD || 0) / totalPoints : 0;
  const lifestyleRatio = totalPoints > 0 ? (categoryPoints.LIFESTYLE || 0) / totalPoints : 0;

  let dominant: CategoryType;
  if (foodRatio >= CATEGORY_THRESHOLD) dominant = 'FOOD';
  else if (lifestyleRatio >= CATEGORY_THRESHOLD) dominant = 'LIFESTYLE';
  else dominant = 'MIXED';

  return stage2Paths.find(p => p.dominantCategory === dominant) || null;
}

/** 第3段階の進化パスを判定 */
export function determineStage3Path(
  currentPathId: string,
  subCategoryPoints: Record<string, number>,
  paths: EvolutionPath[],
): EvolutionPath | null {
  const candidates = paths.filter(p => p.stage === 3 && p.parentPathId === currentPathId);
  if (candidates.length === 0) return null;

  for (const candidate of candidates) {
    if (!candidate.subCategoryIds || !candidate.subCategoryThreshold) continue;
    const relevantPoints = candidate.subCategoryIds.reduce(
      (sum, id) => sum + (subCategoryPoints[id] || 0), 0,
    );
    const totalSubPoints = Object.values(subCategoryPoints).reduce((a, b) => a + b, 0);
    if (totalSubPoints > 0 && relevantPoints / totalSubPoints >= candidate.subCategoryThreshold) {
      return candidate;
    }
  }

  // どちらも閾値未満 → ランダム
  return candidates[Math.floor(Math.random() * candidates.length)];
}

/** 進化判定 */
export function checkEvolution(
  avatar: Avatar,
  newLevel: number,
  paths: EvolutionPath[],
): EvolutionPath | null {
  if (avatar.evolutionStage === 1 && newLevel >= STAGE2_LEVEL) {
    return determineStage2Path(avatar.categoryPoints, avatar.totalPoints, paths);
  }
  if (avatar.evolutionStage === 2 && newLevel >= STAGE3_LEVEL && avatar.evolutionPathId) {
    return determineStage3Path(avatar.evolutionPathId, avatar.subCategoryPoints, paths);
  }
  return null;
}

/** 退化判定 */
export function checkDevolution(
  avatar: Avatar,
  newLevel: number,
  paths: EvolutionPath[],
): { newStage: number; newPathId: string | null; newSpriteKey: string } | null {
  if (avatar.evolutionStage === 3 && newLevel < STAGE3_LEVEL) {
    const currentPath = paths.find(p => p.pathId === avatar.evolutionPathId);
    const parentPath = currentPath ? paths.find(p => p.pathId === currentPath.parentPathId) : null;
    return {
      newStage: 2,
      newPathId: parentPath?.pathId || null,
      newSpriteKey: parentPath?.spriteSheetKey || 'sprites/stage1/default',
    };
  }
  if (avatar.evolutionStage === 2 && newLevel < STAGE2_LEVEL) {
    return { newStage: 1, newPathId: null, newSpriteKey: 'sprites/stage1/default' };
  }
  return null;
}

/** スキル習得判定 */
export function checkSkillAcquisition(
  avatar: Avatar,
  skills: Skill[],
): Skill[] {
  if (!avatar.evolutionPathId) return [];
  return skills.filter(s =>
    s.evolutionPathId === avatar.evolutionPathId &&
    s.requiredLevel <= avatar.level &&
    !avatar.skillIds.includes(s.skillId),
  );
}

/** 退化時に失うスキル */
export function getSkillsToLose(
  avatar: Avatar,
  lostPathId: string,
  skills: Skill[],
): Skill[] {
  return skills.filter(s =>
    s.evolutionPathId === lostPathId &&
    avatar.skillIds.includes(s.skillId),
  );
}

/** ステータス再計算 */
export function recalculateStats(level: number, path: EvolutionPath | null): AvatarStats {
  const growth = path?.statsGrowth || { hp: 5, attack: 3, defense: 3, speed: 3 };
  return {
    hp: INITIAL_STATS.hp + (level - 1) * growth.hp,
    attack: INITIAL_STATS.attack + (level - 1) * growth.attack,
    defense: INITIAL_STATS.defense + (level - 1) * growth.defense,
    speed: INITIAL_STATS.speed + (level - 1) * growth.speed,
  };
}
