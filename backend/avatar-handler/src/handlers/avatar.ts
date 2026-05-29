import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { getUserId } from '../utils/auth';
import { success, created, error } from '../utils/response';
import * as avatarService from '../services/avatar-service';
import { getEvolutionPaths, getSkills } from '../services/master-data-cache';
import { pointsForLevel } from '../services/evolution-engine';

export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
  const userId = getUserId(event);
  if (!userId) return error(401, 'Unauthorized');

  const method = event.httpMethod;
  const path = event.resource;

  try {
    if (method === 'POST' && path === '/avatar') return await handleCreateAvatar(userId, event);
    if (method === 'GET' && path === '/avatar') return await handleGetAvatar(userId);
    if (method === 'GET' && path === '/avatar/evolution-history') return await handleGetHistory(userId);
    if (method === 'GET' && path === '/avatar/score-detail') return await handleGetScoreDetail(userId);
    return error(404, 'Not found');
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : 'Internal error';
    if (msg === 'AVATAR_EXISTS') return error(409, 'Avatar already exists');
    if (msg === 'AVATAR_NOT_FOUND') return error(404, 'Avatar not found');
    console.error(e);
    return error(500, msg);
  }
}

async function handleCreateAvatar(userId: string, event: APIGatewayProxyEvent) {
  const body = event.body ? JSON.parse(event.body) : {};
  const avatar = await avatarService.createAvatar(userId, body.name);
  return created({ avatar });
}

async function handleGetAvatar(userId: string) {
  const avatar = await avatarService.getAvatar(userId);
  if (!avatar) return error(404, 'Avatar not found');

  const [paths, skills] = await Promise.all([getEvolutionPaths(), getSkills()]);
  const ownedSkills = skills.filter(s => avatar.skillIds.includes(s.skillId));
  const evolutionPath = paths.find(p => p.pathId === avatar.evolutionPathId) || null;

  const nextLevelPoints = pointsForLevel(avatar.level + 1) - avatar.totalPoints;
  let nextEvolutionLevel: number | null = null;
  if (avatar.evolutionStage === 1) nextEvolutionLevel = 5;
  else if (avatar.evolutionStage === 2) nextEvolutionLevel = 15;

  return success({
    avatar,
    skills: ownedSkills,
    evolutionPath: evolutionPath ? { name: evolutionPath.name, description: evolutionPath.description } : null,
    progress: {
      nextLevelPoints: Math.max(0, nextLevelPoints),
      nextEvolutionLevel,
      categoryRatio: {
        food: avatar.totalPoints > 0 ? avatar.categoryPoints.FOOD / avatar.totalPoints : 0,
        lifestyle: avatar.totalPoints > 0 ? avatar.categoryPoints.LIFESTYLE / avatar.totalPoints : 0,
      },
    },
  });
}

async function handleGetHistory(userId: string) {
  const history = await avatarService.getEvolutionHistory(userId);
  return success({ history });
}

async function handleGetScoreDetail(userId: string) {
  const avatar = await avatarService.getAvatar(userId);
  if (!avatar) return error(404, 'Avatar not found');

  let nextEvolutionRequiredLevel: number | null = null;
  if (avatar.evolutionStage === 1) nextEvolutionRequiredLevel = 5;
  else if (avatar.evolutionStage === 2) nextEvolutionRequiredLevel = 15;

  const remainingPoints = nextEvolutionRequiredLevel
    ? Math.max(0, pointsForLevel(nextEvolutionRequiredLevel) - avatar.totalPoints)
    : null;

  return success({
    totalPoints: avatar.totalPoints,
    categoryBreakdown: avatar.categoryPoints,
    categoryRatio: {
      food: avatar.totalPoints > 0 ? avatar.categoryPoints.FOOD / avatar.totalPoints : 0,
      lifestyle: avatar.totalPoints > 0 ? avatar.categoryPoints.LIFESTYLE / avatar.totalPoints : 0,
    },
    nextEvolution: nextEvolutionRequiredLevel ? {
      requiredLevel: nextEvolutionRequiredLevel,
      currentLevel: avatar.level,
      remainingPoints,
    } : null,
  });
}
