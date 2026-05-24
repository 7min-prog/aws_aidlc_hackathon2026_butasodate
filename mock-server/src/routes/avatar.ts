import { Router, Request, Response } from 'express';
import { v4 as uuid } from 'uuid';
import { authMiddleware } from '../app';

export const avatarRouter = Router();

// インメモリストア
const avatars: Record<string, any> = {};

function createDefaultAvatar(userId: string, name?: string) {
  return {
    avatarId: uuid(),
    userId,
    name: name || 'こぶた',
    totalPoints: 0,
    level: 1,
    evolutionStage: 1,
    evolutionPathId: null,
    categoryPoints: { FOOD: 0, LIFESTYLE: 0, MIXED: 0 },
    subCategoryPoints: {},
    stats: { hp: 100, attack: 10, defense: 10, speed: 10 },
    skillIds: [],
    spriteSheetKey: 'kobuta-normal',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
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
  if (!auth || !auth.startsWith('Bearer ')) {
    res.json({ avatar: createDefaultAvatar('demo') });
    return;
  }
  const token = auth.replace('Bearer ', '');
  const userId = token.replace('mock-token-', '') || 'user-1';
  (req as any).userId = userId;
  if (!avatars[userId]) {
    avatars[userId] = createDefaultAvatar(userId);
  }
  res.json({ avatar: avatars[userId] });
});
