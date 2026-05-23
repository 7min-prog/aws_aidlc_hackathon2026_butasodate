import { Avatar, AvatarStats, CategoryType, PigSpecies, EvolutionRoute, Skill, GameConfig } from '../types';

const DEFAULT_STATS_GROWTH: AvatarStats = { hp: 5, attack: 3, defense: 3, speed: 3 };
const DEFAULT_SPRITE_KEY = 'sprites/stage1/default';

export function calculateLevel(totalPoints: number, config: GameConfig): number {
  if (totalPoints <= 0) return 1;
  const f = config.LEVEL_FORMULA_COEFFICIENT;
  const n = Math.floor((-f + Math.sqrt(f * f + 4 * f * totalPoints)) / (2 * f));
  return Math.max(1, Math.min(config.MAX_LEVEL, n));
}

export function pointsForLevel(level: number, config: GameConfig): number {
  return level * (level + 1) * config.LEVEL_FORMULA_COEFFICIENT;
}

/** 進化先のSpeciesを判定（EvolutionRouteベース） */
export function determineEvolution(
  avatar: Avatar,
  newLevel: number,
  species: PigSpecies[],
  routes: EvolutionRoute[],
  config: GameConfig,
): PigSpecies | null {
  if (avatar.evolutionStage === 1 && newLevel >= config.EVOLUTION_LEVEL_STAGE2) {
    return findNextSpecies(avatar, null, species, routes, config);
  }
  if (avatar.evolutionStage === 2 && newLevel >= config.EVOLUTION_LEVEL_STAGE3 && avatar.currentSpeciesId) {
    return findNextSpecies(avatar, avatar.currentSpeciesId, species, routes, config);
  }
  return null;
}

function findNextSpecies(
  avatar: Avatar,
  fromSpeciesId: string | null,
  species: PigSpecies[],
  routes: EvolutionRoute[],
  config: GameConfig,
): PigSpecies | null {
  // ルートを探す: fromSpeciesId=null (stage1はspecies未設定) の場合はstage=1からのルートを検索
  const candidates = fromSpeciesId
    ? routes.filter(r => r.fromSpeciesId === fromSpeciesId)
    : routes.filter(r => {
        const fromSpecies = species.find(s => s.speciesId === r.fromSpeciesId);
        return fromSpecies && fromSpecies.stage === 1;
      });

  // 条件に合うルートを優先度順にチェック
  const sorted = [...candidates].sort((a, b) => a.priority - b.priority);

  for (const route of sorted) {
    if (meetsCondition(avatar, route, config)) {
      return species.find(s => s.speciesId === route.toSpeciesId) || null;
    }
  }

  // どれも閾値未満 → 最初の候補にフォールバック
  if (sorted.length > 0) {
    return species.find(s => s.speciesId === sorted[0].toSpeciesId) || null;
  }
  return null;
}

function meetsCondition(avatar: Avatar, route: EvolutionRoute, config: GameConfig): boolean {
  const total = avatar.totalPoints;
  if (total === 0) return false;

  // サブカテゴリ条件がある場合
  if (route.subCategoryIds && route.subCategoryThreshold) {
    const relevantPoints = route.subCategoryIds.reduce(
      (sum, id) => sum + (avatar.subCategoryPoints[id] || 0), 0,
    );
    const categoryTotal = avatar.categoryPoints[route.conditionCategory] || 0;
    return categoryTotal > 0 && relevantPoints / categoryTotal >= route.subCategoryThreshold;
  }

  // カテゴリ比率条件
  const ratio = (avatar.categoryPoints[route.conditionCategory] || 0) / total;
  return ratio >= route.categoryThreshold;
}

/** 退化判定 */
export function checkDevolution(
  avatar: Avatar,
  newLevel: number,
  species: PigSpecies[],
  routes: EvolutionRoute[],
  config: GameConfig,
): { newStage: number; newSpeciesId: string | null; newSpriteKey: string } | null {
  if (avatar.evolutionStage === 3 && newLevel < config.EVOLUTION_LEVEL_STAGE3) {
    // 逆引き: 現在のspeciesに到達するルートのfromSpeciesIdに戻る
    const incomingRoute = routes.find(r => r.toSpeciesId === avatar.currentSpeciesId);
    const parentSpecies = incomingRoute ? species.find(s => s.speciesId === incomingRoute.fromSpeciesId) : null;
    return {
      newStage: 2,
      newSpeciesId: parentSpecies?.speciesId || null,
      newSpriteKey: parentSpecies?.spriteSheetKey || DEFAULT_SPRITE_KEY,
    };
  }
  if (avatar.evolutionStage === 2 && newLevel < config.EVOLUTION_LEVEL_STAGE2) {
    return { newStage: 1, newSpeciesId: null, newSpriteKey: DEFAULT_SPRITE_KEY };
  }
  return null;
}

/** スキル習得判定 */
export function checkSkillAcquisition(avatar: Avatar, skills: Skill[]): Skill[] {
  if (!avatar.currentSpeciesId) return [];
  return skills.filter(s =>
    s.speciesId === avatar.currentSpeciesId &&
    s.requiredLevel <= avatar.level &&
    !avatar.skillIds.includes(s.skillId),
  );
}

/** 退化時に失うスキル */
export function getSkillsToLose(avatar: Avatar, lostSpeciesId: string, skills: Skill[]): Skill[] {
  return skills.filter(s =>
    s.speciesId === lostSpeciesId &&
    avatar.skillIds.includes(s.skillId),
  );
}

/** ステータス再計算 */
export function recalculateStats(level: number, currentSpecies: PigSpecies | null, config: GameConfig): AvatarStats {
  const growth = currentSpecies?.statsGrowth || DEFAULT_STATS_GROWTH;
  const initial = config.INITIAL_STATS;
  return {
    hp: initial.hp + (level - 1) * growth.hp,
    attack: initial.attack + (level - 1) * growth.attack,
    defense: initial.defense + (level - 1) * growth.defense,
    speed: initial.speed + (level - 1) * growth.speed,
  };
}
