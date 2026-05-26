import { GetCommand, PutCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { randomUUID } from 'crypto';
import { docClient, AVATAR_TABLE, EVOLUTION_HISTORY_TABLE } from '../utils/dynamo-client';
import { getPigSpecies, getEvolutionRoutes, getSkills, getGameConfig } from './master-data-cache';
import {
  calculateLevel, determineEvolution, checkDevolution,
  checkSkillAcquisition, getSkillsToLose, recalculateStats,
} from './evolution-engine';
import { Avatar, AddPointsResult, DeductPointsResult, CategoryType, EvolutionHistory } from '../types';

const DEFAULT_AVATAR_NAME = 'ぶたさん';

export async function createAvatar(userId: string, name?: string): Promise<Avatar> {
  const existing = await getAvatar(userId);
  if (existing) throw new Error('AVATAR_EXISTS');

  const config = await getGameConfig();

  const avatar: Avatar = {
    avatarId: randomUUID(),
    userId,
    name: name || DEFAULT_AVATAR_NAME,
    totalPoints: 0,
    level: 1,
    evolutionStage: 1,
    currentSpeciesId: null,
    categoryPoints: { FOOD: 0, LIFESTYLE: 0, MIXED: 0 },
    subCategoryPoints: {},
    stats: config.INITIAL_STATS,
    skillIds: [],
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

  const [species, routes, skills, config] = await Promise.all([
    getPigSpecies(), getEvolutionRoutes(), getSkills(), getGameConfig(),
  ]);

  // Step 1: ポイント更新
  avatar.totalPoints += points;
  avatar.categoryPoints[categoryType] = (avatar.categoryPoints[categoryType] || 0) + points;
  if (subCategoryId) {
    avatar.subCategoryPoints[subCategoryId] = (avatar.subCategoryPoints[subCategoryId] || 0) + points;
  }

  // Step 2: レベル再計算
  const oldLevel = avatar.level;
  avatar.level = calculateLevel(avatar.totalPoints, config);
  const leveledUp = avatar.level > oldLevel;

  // Step 3: 進化判定
  let evolved = false;
  if (leveledUp) {
    const target = determineEvolution(avatar, avatar.level, species, routes, config);
    if (target) {
      const oldSpeciesId = avatar.currentSpeciesId;
      avatar.evolutionStage = target.stage;
      avatar.currentSpeciesId = target.speciesId;
      evolved = true;
      await saveEvolutionHistory(avatar, 'EVOLUTION', target.stage - 1, target.stage, oldSpeciesId, target.speciesId);
    }
  }

  // Step 4: スキル習得
  const newSkills = checkSkillAcquisition(avatar, skills);
  avatar.skillIds.push(...newSkills.map(s => s.skillId));

  // Step 5: ステータス再計算
  const currentSpecies = species.find(s => s.speciesId === avatar.currentSpeciesId) || null;
  avatar.stats = recalculateStats(avatar.level, currentSpecies, config);
  avatar.updatedAt = new Date().toISOString();

  await saveAvatar(avatar);
  return { avatar, leveledUp, evolved, newSkills };
}

export async function deductPoints(
  userId: string, points: number, categoryType: CategoryType, subCategoryId?: string,
): Promise<DeductPointsResult> {
  const avatar = await getAvatar(userId);
  if (!avatar) throw new Error('AVATAR_NOT_FOUND');

  const [species, routes, skills, config] = await Promise.all([
    getPigSpecies(), getEvolutionRoutes(), getSkills(), getGameConfig(),
  ]);

  // Step 1: ポイント更新
  avatar.totalPoints = Math.max(0, avatar.totalPoints - points);
  avatar.categoryPoints[categoryType] = Math.max(0, (avatar.categoryPoints[categoryType] || 0) - points);
  if (subCategoryId) {
    avatar.subCategoryPoints[subCategoryId] = Math.max(0, (avatar.subCategoryPoints[subCategoryId] || 0) - points);
  }

  // Step 2: レベル再計算
  const oldLevel = avatar.level;
  avatar.level = calculateLevel(avatar.totalPoints, config);
  const leveledDown = avatar.level < oldLevel;

  // Step 3: 退化判定
  let devolved = false;
  let lostSkills: typeof skills = [];
  const devolution = checkDevolution(avatar, avatar.level, species, routes, config);
  if (devolution) {
    const oldSpeciesId = avatar.currentSpeciesId;
    lostSkills = oldSpeciesId ? getSkillsToLose(avatar, oldSpeciesId, skills) : [];
    avatar.skillIds = avatar.skillIds.filter(id => !lostSkills.some(s => s.skillId === id));
    avatar.evolutionStage = devolution.newStage;
    avatar.currentSpeciesId = devolution.newSpeciesId;
    devolved = true;
    await saveEvolutionHistory(avatar, 'DEVOLUTION', devolution.newStage + 1, devolution.newStage, oldSpeciesId, devolution.newSpeciesId);
  }

  // Step 4: ステータス再計算
  const currentSpecies = species.find(s => s.speciesId === avatar.currentSpeciesId) || null;
  avatar.stats = recalculateStats(avatar.level, currentSpecies, config);
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
  fromSpeciesId: string | null, toSpeciesId: string | null,
): Promise<void> {
  const now = new Date().toISOString();
  const history: EvolutionHistory = {
    historyId: randomUUID(),
    userId: avatar.userId,
    avatarId: avatar.avatarId,
    fromStage, toStage, fromSpeciesId, toSpeciesId, type,
    triggerPoints: avatar.totalPoints,
    occurredAt: now,
  };
  await docClient.send(new PutCommand({
    TableName: EVOLUTION_HISTORY_TABLE,
    Item: { ...history, 'occurredAt#historyId': `${now}#${history.historyId}` },
  }));
}
