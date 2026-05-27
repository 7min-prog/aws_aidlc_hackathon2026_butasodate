import { v4 as uuid } from 'uuid';

// 進化レベル定数（avatar-handler準拠）
export const STAGE2_LEVEL = 5;
export const STAGE3_LEVEL = 15;
export function pointsForLevel(level: number): number { return level * (level + 1) * 5; }

export const evolutionPaths = [
  { pathId: 'food-path', name: 'グルメロード', description: '食の道を極めし者' },
  { pathId: 'lifestyle-path', name: 'ぐうたらロード', description: '怠惰の極みを目指す者' },
  { pathId: 'mixed-path', name: 'バランスロード', description: '全方位にダメな者' },
];

export const skills = [
  { skillId: 'skill-1', name: 'ラーメンスプラッシュ', type: 'ATTACK', power: 30, cooldown: 2, evolutionPathId: 'food-path', requiredLevel: 3, spriteAnimationKey: 'ramen-splash' },
  { skillId: 'skill-2', name: 'もちもちガード', type: 'DEFENSE', power: 20, cooldown: 3, evolutionPathId: 'food-path', requiredLevel: 5, spriteAnimationKey: 'mochi-guard' },
  { skillId: 'skill-3', name: '二度寝バリア', type: 'DEFENSE', power: 25, cooldown: 3, evolutionPathId: 'lifestyle-path', requiredLevel: 3, spriteAnimationKey: 'sleep-barrier' },
  { skillId: 'skill-4', name: 'だらだらビーム', type: 'ATTACK', power: 35, cooldown: 2, evolutionPathId: 'lifestyle-path', requiredLevel: 5, spriteAnimationKey: 'lazy-beam' },
  { skillId: 'skill-5', name: 'ヒーリングスナック', type: 'HEAL', power: 40, cooldown: 4, evolutionPathId: 'mixed-path', requiredLevel: 4, spriteAnimationKey: 'heal-snack' },
];

export const avatars: Record<string, any> = {
  'admin': {
    avatarId: 'avatar-admin-001', userId: 'admin', name: 'ぽんたろう',
    totalPoints: 399, level: 4, evolutionStage: 1, evolutionPathId: 'food-path',
    categoryPoints: { FOOD: 250, LIFESTYLE: 149, MIXED: 0 },
    subCategoryPoints: { 'food_late_ramen': 96, 'food_binge': 84, 'food_snack': 70, 'life_stay_up': 50, 'life_oversleep': 50, 'life_binge_watch': 49 },
    stats: { hp: 100, attack: 40, defense: 45, speed: 35 },
    skillIds: ['skill-1', 'skill-2', 'skill-3', 'skill-4', 'skill-5'],
    spriteSheetKey: 'kobuta-normal',
    createdAt: '2026-05-20T10:00:00Z', updatedAt: new Date().toISOString(),
  },
};

export const evolutionHistory: Record<string, any[]> = { 'admin': [] };

export function createDefaultAvatar(userId: string, name?: string) {
  return {
    avatarId: uuid(), userId, name: name || 'こぶた',
    totalPoints: 0, level: 1, evolutionStage: 1, evolutionPathId: null,
    categoryPoints: { FOOD: 0, LIFESTYLE: 0, MIXED: 0 },
    subCategoryPoints: {},
    stats: { hp: 100, attack: 10, defense: 10, speed: 10 },
    skillIds: [], spriteSheetKey: 'kobuta-normal',
    createdAt: new Date().toISOString(), updatedAt: new Date().toISOString(),
  };
}

/** ポイント加算してavatar更新。進化判定も行う */
export function addPointsToAvatar(userId: string, points: number, categoryType?: string, subCategoryId?: string) {
  if (!avatars[userId]) avatars[userId] = createDefaultAvatar(userId);
  const avatar = avatars[userId];

  avatar.totalPoints += points;
  if (categoryType && avatar.categoryPoints[categoryType] !== undefined) {
    avatar.categoryPoints[categoryType] += points;
  }
  if (subCategoryId) {
    avatar.subCategoryPoints[subCategoryId] = (avatar.subCategoryPoints[subCategoryId] || 0) + points;
  }

  const oldLevel = avatar.level;
  avatar.level = Math.floor(avatar.totalPoints / 100) + 1;
  const leveledUp = avatar.level > oldLevel;

  const oldStage = avatar.evolutionStage;
  if (avatar.level >= STAGE3_LEVEL) avatar.evolutionStage = 3;
  else if (avatar.level >= STAGE2_LEVEL) avatar.evolutionStage = 2;
  const evolved = avatar.evolutionStage > oldStage;

  if (evolved) {
    if (!evolutionHistory[userId]) evolutionHistory[userId] = [];
    evolutionHistory[userId].push({
      historyId: uuid(), userId, avatarId: avatar.avatarId,
      fromStage: oldStage, toStage: avatar.evolutionStage,
      fromPathId: avatar.evolutionPathId, toPathId: avatar.evolutionPathId,
      type: 'EVOLUTION', triggerPoints: avatar.totalPoints, occurredAt: new Date().toISOString(),
    });
  }

  avatar.updatedAt = new Date().toISOString();
  return { avatar, leveledUp, evolved, newSkills: [] };
}
