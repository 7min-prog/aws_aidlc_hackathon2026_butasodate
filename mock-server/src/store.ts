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
  // グルメロード (food-path)
  { skillId: 'skill-1', name: 'ラーメンスプラッシュ', type: 'ATTACK', targetStat: 'hp', multiplier: 1.5, duration: null, cooldown: 2, speciesId: null, evolutionPathId: 'food-path', requiredLevel: 3, spriteAnimationKey: 'ramen-splash' },
  { skillId: 'skill-2', name: 'もちもちガード', type: 'DEFENSE', targetStat: 'defense', multiplier: 0.4, duration: 2, cooldown: 3, speciesId: null, evolutionPathId: 'food-path', requiredLevel: 5, spriteAnimationKey: 'mochi-guard' },
  { skillId: 'skill-3', name: '暴食プレス', type: 'ATTACK', targetStat: 'hp', multiplier: 2.0, duration: null, cooldown: 4, speciesId: null, evolutionPathId: 'food-path', requiredLevel: 10, spriteAnimationKey: 'binge-press' },
  { skillId: 'skill-4', name: 'カロリーボム', type: 'ATTACK', targetStat: 'hp', multiplier: 2.5, duration: null, cooldown: 5, speciesId: null, evolutionPathId: 'food-path', requiredLevel: 15, spriteAnimationKey: 'calorie-bomb' },
  // ぐうたらロード (lifestyle-path)
  { skillId: 'skill-5', name: '二度寝バリア', type: 'DEFENSE', targetStat: 'defense', multiplier: 0.3, duration: 2, cooldown: 3, speciesId: null, evolutionPathId: 'lifestyle-path', requiredLevel: 3, spriteAnimationKey: 'sleep-barrier' },
  { skillId: 'skill-6', name: 'だらだらビーム', type: 'ATTACK', targetStat: 'hp', multiplier: 1.5, duration: null, cooldown: 2, speciesId: null, evolutionPathId: 'lifestyle-path', requiredLevel: 5, spriteAnimationKey: 'lazy-beam' },
  { skillId: 'skill-7', name: 'サボりスロー', type: 'DEBUFF', targetStat: 'speed', multiplier: 0.3, duration: 3, cooldown: 4, speciesId: null, evolutionPathId: 'lifestyle-path', requiredLevel: 10, spriteAnimationKey: 'skip-slow' },
  { skillId: 'skill-8', name: '夜更かしカース', type: 'DEBUFF', targetStat: 'attack', multiplier: 0.25, duration: 2, cooldown: 4, speciesId: null, evolutionPathId: 'lifestyle-path', requiredLevel: 15, spriteAnimationKey: 'stayup-curse' },
  // バランスロード (mixed-path)
  { skillId: 'skill-9', name: 'ヒーリングスナック', type: 'HEAL', targetStat: 'hp', multiplier: 0.3, duration: null, cooldown: 4, speciesId: null, evolutionPathId: 'mixed-path', requiredLevel: 4, spriteAnimationKey: 'heal-snack' },
  { skillId: 'skill-10', name: 'ぐーたらスマッシュ', type: 'ATTACK', targetStat: 'hp', multiplier: 1.8, duration: null, cooldown: 3, speciesId: null, evolutionPathId: 'mixed-path', requiredLevel: 8, spriteAnimationKey: 'lazy-smash' },
  { skillId: 'skill-11', name: 'ダメダメオーラ', type: 'DEBUFF', targetStat: 'defense', multiplier: 0.35, duration: 2, cooldown: 4, speciesId: null, evolutionPathId: 'mixed-path', requiredLevel: 12, spriteAnimationKey: 'dame-aura' },
  { skillId: 'skill-12', name: 'ぜんぶのせ', type: 'ATTACK', targetStat: 'hp', multiplier: 3.0, duration: null, cooldown: 6, speciesId: null, evolutionPathId: 'mixed-path', requiredLevel: 15, spriteAnimationKey: 'zenbu-nose' },
];

export const avatars: Record<string, any> = {
  'admin': {
    avatarId: 'avatar-admin-001', userId: 'admin', name: 'ぽんたろう',
    totalPoints: 399, level: 4, evolutionStage: 1, evolutionPathId: 'food-path',
    categoryPoints: { FOOD: 250, LIFESTYLE: 149, MIXED: 0 },
    subCategoryPoints: { 'food_late_ramen': 96, 'food_binge': 84, 'food_snack': 70, 'life_stay_up': 50, 'life_oversleep': 50, 'life_binge_watch': 49 },
    stats: { hp: 100, attack: 40, defense: 45, speed: 35 },
    skillIds: ['skill-1', 'skill-2', 'skill-5', 'skill-6', 'skill-9'],
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
