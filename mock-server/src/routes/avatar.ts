import { Router, Request, Response } from 'express';
import { v4 as uuid } from 'uuid';
import { authMiddleware } from '../app';

export const avatarRouter = Router();

// インメモリストア
const avatars: Record<string, any> = {
  'admin': {
    avatarId: 'avatar-admin-001',
    userId: 'admin',
    name: 'ぽんたろう',
    totalPoints: 280,
    level: 3,
    evolutionStage: 2,
    evolutionPathId: 'food-path',
    categoryPoints: { FOOD: 180, LIFESTYLE: 100, MIXED: 0 },
    subCategoryPoints: { 'food-ramen': 100, 'food-snack': 20, 'food-binge': 60, 'life-late-night': 35, 'life-skip-exercise': 40, 'life-gaming': 25 },
    stats: { hp: 100, attack: 25, defense: 18, speed: 15 },
    skillIds: ['skill-1', 'skill-2'],
    spriteSheetKey: 'pocchari-normal',
    createdAt: '2026-05-20T10:00:00Z',
    updatedAt: new Date().toISOString(),
  },
};

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
