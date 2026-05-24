import { Router, Request, Response } from 'express';
import { v4 as uuid } from 'uuid';
import { authMiddleware } from '../app';

export const recordingRouter = Router();

// インメモリストア
const records: Record<string, any[]> = {};

const categories = [
  { categoryId: 'food-ramen', name: '深夜ラーメン', icon: '🍜', points: 50, group: 'FOOD' },
  { categoryId: 'food-snack', name: '間食した', icon: '🍰', points: 20, group: 'FOOD' },
  { categoryId: 'food-binge', name: '暴飲暴食', icon: '🍺', points: 60, group: 'FOOD' },
  { categoryId: 'life-oversleep', name: '二度寝した', icon: '😴', points: 30, group: 'LIFESTYLE' },
  { categoryId: 'life-skip-exercise', name: '運動サボり', icon: '🛋️', points: 40, group: 'LIFESTYLE' },
  { categoryId: 'life-late-night', name: '夜更かし', icon: '📱', points: 35, group: 'LIFESTYLE' },
  { categoryId: 'life-gaming', name: 'ゲーム三昧', icon: '🎮', points: 25, group: 'LIFESTYLE' },
  { categoryId: 'life-nap', name: '昼寝しすぎ', icon: '💤', points: 30, group: 'LIFESTYLE' },
];

// GET /categories
recordingRouter.get('/', (req: Request, res: Response) => {
  // /categories のルートハンドラ
  if (req.baseUrl === '/categories') {
    res.json({ categories });
    return;
  }
  // /activities のGET
  handleGetActivities(req, res);
});

// POST /activities
recordingRouter.post('/', authMiddleware, (req: Request, res: Response) => {
  if (req.baseUrl === '/categories') { res.status(405).json({ error: 'Method not allowed' }); return; }
  const userId = (req as any).userId;
  const { records: inputRecords } = req.body;
  if (!inputRecords || !Array.isArray(inputRecords) || inputRecords.length === 0) {
    res.status(400).json({ error: 'records array required' }); return;
  }

  if (!records[userId]) records[userId] = [];
  const skippedIds: string[] = [];
  let totalNewPoints = 0;

  for (const rec of inputRecords) {
    const recordId = rec.recordId || uuid();
    // 冪等性チェック
    if (records[userId].find(r => r.recordId === recordId)) {
      skippedIds.push(recordId);
      continue;
    }
    const cat = categories.find(c => c.categoryId === rec.categoryId);
    const points = cat?.points || 10;
    records[userId].push({
      recordId,
      categoryId: rec.categoryId,
      memo: rec.memo || null,
      points,
      recordedAt: rec.recordedAt || new Date().toISOString(),
      source: 'MANUAL',
    });
    totalNewPoints += points;
  }

  const userRecords = records[userId];
  const totalPoints = userRecords.reduce((sum, r) => sum + r.points, 0);
  const level = Math.floor(totalPoints / 500) + 1;

  res.status(201).json({
    avatar: { totalPoints, level, evolutionStage: Math.min(Math.floor(level / 3) + 1, 4), categoryPoints: {} },
    leveledUp: totalNewPoints > 0 && Math.floor((totalPoints - totalNewPoints) / 500) < Math.floor(totalPoints / 500),
    evolved: false,
    newSkills: [],
    skippedIds,
  });
});

// GET /activities
function handleGetActivities(req: Request, res: Response) {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ')) {
    // 認証なしの場合はデモデータを返す
    res.json({ records: [], nextCursor: null, summary: { todayCount: 0, todayPoints: 0, weekByCategory: [] } });
    return;
  }
  const token = auth.replace('Bearer ', '');
  (req as any).userId = token.replace('mock-token-', '') || 'user-1';

  const userId = (req as any).userId;
  const userRecords = records[userId] || [];
  const limit = parseInt(req.query.limit as string) || 20;
  const sliced = userRecords.slice(-limit).reverse();

  const todayStart = new Date(); todayStart.setHours(0, 0, 0, 0);
  const todayRecords = userRecords.filter(r => new Date(r.recordedAt) >= todayStart);

  res.json({
    records: sliced,
    nextCursor: null,
    summary: {
      todayCount: todayRecords.length,
      todayPoints: todayRecords.reduce((s, r) => s + r.points, 0),
      weekByCategory: [],
    },
  });
}

// DELETE /activities/:recordId
recordingRouter.delete('/:recordId', authMiddleware, (req: Request, res: Response) => {
  const userId = (req as any).userId;
  const { recordId } = req.params;
  if (!records[userId]) { res.status(404).json({ error: 'Not found' }); return; }
  const idx = records[userId].findIndex(r => r.recordId === recordId);
  if (idx === -1) { res.status(404).json({ error: 'Not found' }); return; }
  records[userId].splice(idx, 1);
  res.json({ message: 'Deleted' });
});
