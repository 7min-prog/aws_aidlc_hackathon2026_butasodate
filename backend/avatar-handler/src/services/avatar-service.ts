import { GetCommand, PutCommand, UpdateCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { randomUUID } from 'crypto';
import { docClient, AVATAR_TABLE, EVOLUTION_HISTORY_TABLE } from '../utils/dynamo-client';
import { getEvolutionPaths, getSkills } from './master-data-cache';
import {
  calculateLevel, checkEvolution, checkDevolution,
  checkSkillAcquisition, getSkillsToLose, recalculateStats,
  INITIAL_STATS, DEFAULT_SPRITE_KEY, DEFAULT_AVATAR_NAME,
} from './evolution-engine';
import { Avatar, AddPointsResult, DeductPointsResult, CategoryType, EvolutionHistory } from '../types';

export async function createAvatar(userId: string, name?: string): Promise<Avatar> {
  const existing = await getAvatar(userId);
  if (existing) throw new Error('AVATAR_EXISTS');

  const avatar: Avatar = {
    avatarId: randomUUID(),
    userId,
    name: name || DEFAULT_AVATAR_NAME,
    totalPoints: 0,
    level: 1,
    evolutionStage: 1,
    evolutionPathId: null,
    categoryPoints: { FOOD: 0, LIFESTYLE: 0, MIXED: 0 },
    subCategoryPoints: {},
    stats: INITIAL_STATS,
    skillIds: [],
    spriteSheetKey: DEFAULT_SPRITE_KEY,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  await docClient.send(new PutCommand({ TableName: AVATAR_TABLE, Item: avatar }));
  return avatar;
}

export async function getAvatar(userId: string): Promise<Avatar | null> {
  const result = await docClient.send(new GetCommand({
    TableName: AVATAR_TABLE, Key: { userId },
  }));
  return (result.Item as Avatar) || null;
}

export async function addPoints(
  userId: string, points: number, categoryType: CategoryType, subCategoryId?: string,
): Promise<AddPointsResult> {
  const avatar = await getAvatar(userId);
  if (!avatar) throw new Error('AVATAR_NOT_FOUND');

  const [paths, skills] = await Promise.all([getEvolutionPaths(), getSkills()]);

  // Step 1: ポイント更新
  avatar.totalPoints += points;
  avatar.categoryPoints[categoryType] = (avatar.categoryPoints[categoryType] || 0) + points;
  if (subCategoryId) {
    avatar.subCategoryPoints[subCategoryId] = (avatar.subCategoryPoints[subCategoryId] || 0) + points;
  }

  // Step 2: レベル再計算
  const oldLevel = avatar.level;
  avatar.level = calculateLevel(avatar.totalPoints);
  const leveledUp = avatar.level > oldLevel;

  // Step 3: 進化判定
  let evolved = false;
  if (leveledUp) {
    const evolutionTarget = checkEvolution(avatar, avatar.level, paths);
    if (evolutionTarget) {
      avatar.evolutionStage = evolutionTarget.stage;
      avatar.evolutionPathId = evolutionTarget.pathId;
      avatar.spriteSheetKey = evolutionTarget.spriteSheetKey;
      evolved = true;
      await saveEvolutionHistory(avatar, 'EVOLUTION', evolutionTarget.stage - 1, evolutionTarget.stage, null, evolutionTarget.pathId);
    }
  }

  // Step 4: スキル習得
  const newSkills = checkSkillAcquisition(avatar, skills);
  avatar.skillIds.push(...newSkills.map(s => s.skillId));

  // Step 5: ステータス再計算
  const currentPath = paths.find(p => p.pathId === avatar.evolutionPathId) || null;
  avatar.stats = recalculateStats(avatar.level, currentPath);
  avatar.updatedAt = new Date().toISOString();

  await saveAvatar(avatar);
  return { avatar, leveledUp, evolved, newSkills };
}

export async function deductPoints(
  userId: string, points: number, categoryType: CategoryType, subCategoryId?: string,
): Promise<DeductPointsResult> {
  const avatar = await getAvatar(userId);
  if (!avatar) throw new Error('AVATAR_NOT_FOUND');

  const [paths, skills] = await Promise.all([getEvolutionPaths(), getSkills()]);

  // Step 1: ポイント更新
  avatar.totalPoints = Math.max(0, avatar.totalPoints - points);
  avatar.categoryPoints[categoryType] = Math.max(0, (avatar.categoryPoints[categoryType] || 0) - points);
  if (subCategoryId) {
    avatar.subCategoryPoints[subCategoryId] = Math.max(0, (avatar.subCategoryPoints[subCategoryId] || 0) - points);
  }

  // Step 2: レベル再計算
  const oldLevel = avatar.level;
  avatar.level = calculateLevel(avatar.totalPoints);
  const leveledDown = avatar.level < oldLevel;

  // Step 3: 退化判定
  let devolved = false;
  let lostSkills: typeof skills = [];
  const devolution = checkDevolution(avatar, avatar.level, paths);
  if (devolution) {
    const oldPathId = avatar.evolutionPathId;
    lostSkills = oldPathId ? getSkillsToLose(avatar, oldPathId, skills) : [];
    avatar.skillIds = avatar.skillIds.filter(id => !lostSkills.some(s => s.skillId === id));
    avatar.evolutionStage = devolution.newStage;
    avatar.evolutionPathId = devolution.newPathId;
    avatar.spriteSheetKey = devolution.newSpriteKey;
    devolved = true;
    await saveEvolutionHistory(avatar, 'DEVOLUTION', devolution.newStage + 1, devolution.newStage, oldPathId, devolution.newPathId);
  }

  // Step 4: ステータス再計算
  const currentPath = paths.find(p => p.pathId === avatar.evolutionPathId) || null;
  avatar.stats = recalculateStats(avatar.level, currentPath);
  avatar.updatedAt = new Date().toISOString();

  await saveAvatar(avatar);
  return { avatar, leveledDown, devolved, lostSkills };
}

export async function updateAvatarName(userId: string, name: string): Promise<Avatar> {
  const avatar = await getAvatar(userId);
  if (!avatar) throw new Error('AVATAR_NOT_FOUND');
  avatar.name = name;
  avatar.updatedAt = new Date().toISOString();
  await saveAvatar(avatar);
  return avatar;
}

export async function getEvolutionHistory(userId: string): Promise<EvolutionHistory[]> {
  const result = await docClient.send(new QueryCommand({
    TableName: EVOLUTION_HISTORY_TABLE,
    KeyConditionExpression: 'userId = :uid',
    ExpressionAttributeValues: { ':uid': userId },
    ScanIndexForward: false,
  }));
  return (result.Items || []) as EvolutionHistory[];
}

async function saveAvatar(avatar: Avatar): Promise<void> {
  await docClient.send(new PutCommand({ TableName: AVATAR_TABLE, Item: avatar }));
}

async function saveEvolutionHistory(
  avatar: Avatar, type: 'EVOLUTION' | 'DEVOLUTION',
  fromStage: number, toStage: number,
  fromPathId: string | null, toPathId: string | null,
): Promise<void> {
  const history: EvolutionHistory = {
    historyId: randomUUID(),
    userId: avatar.userId,
    avatarId: avatar.avatarId,
    fromStage, toStage, fromPathId, toPathId, type,
    triggerPoints: avatar.totalPoints,
    occurredAt: new Date().toISOString(),
  };
  await docClient.send(new PutCommand({ TableName: EVOLUTION_HISTORY_TABLE, Item: history }));
}
