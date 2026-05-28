import { Router, Request, Response } from 'express';
import { v4 as uuid } from 'uuid';
import { authMiddleware } from '../app';
import {
  avatars, evolutionHistory, evolutionPaths, skills,
  createDefaultAvatar, addPointsToAvatar,
  STAGE2_LEVEL, STAGE3_LEVEL, pointsForLevel,
} from '../store';

export const avatarRouter = Router();

function getAvatarResponse(avatar: any) {
  const ownedSkills = skills.filter(s => avatar.skillIds.includes(s.skillId));
  const evoPath = evolutionPaths.find(p => p.pathId === avatar.evolutionPathId) || null;
  const nextLevelPoints = Math.max(0, pointsForLevel(avatar.level + 1) - avatar.totalPoints);
  let nextEvolutionLevel: number | null = null;
  if (avatar.evolutionStage === 1) nextEvolutionLevel = STAGE2_LEVEL;
  else if (avatar.evolutionStage === 2) nextEvolutionLevel = STAGE3_LEVEL;
  const total = avatar.totalPoints || 1;

  return {
    avatar,
    skills: ownedSkills,
    evolutionPath: evoPath ? { name: evoPath.name, description: evoPath.description } : null,
    progress: {
      nextLevelPoints,
      nextEvolutionLevel,
      categoryRatio: {
        food: avatar.categoryPoints.FOOD / total,
        lifestyle: avatar.categoryPoints.LIFESTYLE / total,
      },
    },
  };
}

// POST /avatar
avatarRouter.post('/', authMiddleware, (req: Request, res: Response) => {
  const userId = (req as any).userId;
  const { name } = req.body;
  if (avatars[userId]) {
    if (name) { avatars[userId].name = name; avatars[userId].updatedAt = new Date().toISOString(); }
    res.status(201).json({ avatar: avatars[userId] });
    return;
  }
  avatars[userId] = createDefaultAvatar(userId, name);
  res.status(201).json({ avatar: avatars[userId] });
});

// GET /avatar
avatarRouter.get('/', (req: Request, res: Response) => {
  const auth = req.headers.authorization;
  if (!auth) {
    const demo = createDefaultAvatar('demo');
    res.json(getAvatarResponse(demo));
    return;
  }
  const token = auth.startsWith('Bearer ') ? auth.replace('Bearer ', '') : auth;
  const userId = token.replace('mock-token-', '').replace('mock-id-', '') || 'user-1';
  if (!avatars[userId]) avatars[userId] = createDefaultAvatar(userId);
  res.json(getAvatarResponse(avatars[userId]));
});

// PUT /avatar/name
avatarRouter.put('/name', authMiddleware, (req: Request, res: Response) => {
  const userId = (req as any).userId;
  const { name } = req.body;
  if (!avatars[userId]) { res.status(404).json({ error: 'Avatar not found' }); return; }
  if (name) { avatars[userId].name = name; avatars[userId].updatedAt = new Date().toISOString(); }
  res.json({ avatar: avatars[userId] });
});

// GET /avatar/evolution-history
avatarRouter.get('/evolution-history', authMiddleware, (req: Request, res: Response) => {
  const userId = (req as any).userId;
  res.json({ history: evolutionHistory[userId] || [] });
});

// GET /avatar/score-detail
avatarRouter.get('/score-detail', authMiddleware, (req: Request, res: Response) => {
  const userId = (req as any).userId;
  const avatar = avatars[userId];
  if (!avatar) { res.status(404).json({ error: 'Avatar not found' }); return; }

  let nextEvolutionRequiredLevel: number | null = null;
  if (avatar.evolutionStage === 1) nextEvolutionRequiredLevel = STAGE2_LEVEL;
  else if (avatar.evolutionStage === 2) nextEvolutionRequiredLevel = STAGE3_LEVEL;

  const remainingPoints = nextEvolutionRequiredLevel
    ? Math.max(0, pointsForLevel(nextEvolutionRequiredLevel) - avatar.totalPoints)
    : null;
  const total = avatar.totalPoints || 1;

  res.json({
    totalPoints: avatar.totalPoints,
    categoryBreakdown: avatar.categoryPoints,
    categoryRatio: { food: avatar.categoryPoints.FOOD / total, lifestyle: avatar.categoryPoints.LIFESTYLE / total },
    nextEvolution: nextEvolutionRequiredLevel ? { requiredLevel: nextEvolutionRequiredLevel, currentLevel: avatar.level, remainingPoints } : null,
  });
});

// POST /avatar/points
avatarRouter.post('/points', authMiddleware, (req: Request, res: Response) => {
  const userId = (req as any).userId;
  const { points, categoryType, subCategoryId } = req.body;
  if (!avatars[userId]) { res.status(404).json({ error: 'Avatar not found' }); return; }
  const result = addPointsToAvatar(userId, points, categoryType, subCategoryId);
  res.json(result);
});

// POST /avatar/points/deduct
avatarRouter.post('/points/deduct', authMiddleware, (req: Request, res: Response) => {
  const userId = (req as any).userId;
  const { points, categoryType, subCategoryId } = req.body;
  const avatar = avatars[userId];
  if (!avatar) { res.status(404).json({ error: 'Avatar not found' }); return; }

  avatar.totalPoints = Math.max(0, avatar.totalPoints - points);
  if (categoryType && avatar.categoryPoints[categoryType] !== undefined) {
    avatar.categoryPoints[categoryType] = Math.max(0, avatar.categoryPoints[categoryType] - points);
  }
  if (subCategoryId) {
    avatar.subCategoryPoints[subCategoryId] = Math.max(0, (avatar.subCategoryPoints[subCategoryId] || 0) - points);
  }

  const oldLevel = avatar.level;
  avatar.level = Math.max(1, Math.floor(avatar.totalPoints / 100) + 1);
  const leveledDown = avatar.level < oldLevel;

  const oldStage = avatar.evolutionStage;
  if (avatar.level < STAGE2_LEVEL) avatar.evolutionStage = 1;
  else if (avatar.level < STAGE3_LEVEL) avatar.evolutionStage = 2;
  const devolved = avatar.evolutionStage < oldStage;

  if (devolved) {
    if (!evolutionHistory[userId]) evolutionHistory[userId] = [];
    evolutionHistory[userId].push({
      historyId: uuid(), userId, avatarId: avatar.avatarId,
      fromStage: oldStage, toStage: avatar.evolutionStage,
      fromPathId: avatar.evolutionPathId, toPathId: avatar.evolutionPathId,
      type: 'DEVOLUTION', triggerPoints: avatar.totalPoints, occurredAt: new Date().toISOString(),
    });
  }

  avatar.updatedAt = new Date().toISOString();
  res.json({ avatar, leveledDown, devolved, lostSkills: [] });
});
