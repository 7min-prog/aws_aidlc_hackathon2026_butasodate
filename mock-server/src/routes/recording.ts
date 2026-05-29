import { Router, Request, Response } from 'express';
import { v4 as uuid } from 'uuid';
import { authMiddleware } from '../app';
import { addPointsToAvatar } from '../store';

export const recordingRouter = Router();

// CDK seedデータ準拠のカテゴリ
const categories = [
  { categoryId: 'food_late_ramen', name: '深夜ラーメン', type: 'FOOD', basePoints: 12, iconKey: 'ramen', sortOrder: 1, isActive: true, version: 1 },
  { categoryId: 'food_binge', name: '暴飲暴食', type: 'FOOD', basePoints: 12, iconKey: 'binge', sortOrder: 2, isActive: true, version: 1 },
  { categoryId: 'food_snack', name: '間食', type: 'FOOD', basePoints: 12, iconKey: 'snack', sortOrder: 3, isActive: true, version: 1 },
  { categoryId: 'food_junkfood', name: 'ジャンクフード', type: 'FOOD', basePoints: 12, iconKey: 'junk', sortOrder: 4, isActive: true, version: 1 },
  { categoryId: 'life_stay_up', name: '夜更かし', type: 'LIFESTYLE', basePoints: 10, iconKey: 'night', sortOrder: 5, isActive: true, version: 1 },
  { categoryId: 'life_oversleep', name: '二度寝', type: 'LIFESTYLE', basePoints: 10, iconKey: 'sleep', sortOrder: 6, isActive: true, version: 1 },
  { categoryId: 'life_skip_exercise', name: '運動サボり', type: 'LIFESTYLE', basePoints: 10, iconKey: 'couch', sortOrder: 7, isActive: true, version: 1 },
  { categoryId: 'life_binge_watch', name: 'だらだら動画視聴', type: 'LIFESTYLE', basePoints: 10, iconKey: 'tv', sortOrder: 8, isActive: true, version: 1 },
];

const META_VERSION = 1;

// インメモリストア
const seedRecords: any[] = [];
const memos = ['とんこつ最高', 'ポテチ', '焼肉食べ放題', null, 'Netflix一気見', null, null, '二度寝した'];
for (let i = 0; i < 13; i++) {
  const cat = categories[i % categories.length];
  seedRecords.push({
    recordId: `r-${i + 1}`,
    categoryId: cat.categoryId,
    memo: memos[i % memos.length],
    points: cat.basePoints,
    recordedAt: new Date(Date.now() - i * 3600000 * 6).toISOString(),
    source: i % 5 === 0 ? 'AUTO_DETECTED' : 'MANUAL',
  });
}
const records: Record<string, any[]> = { 'admin': seedRecords };

// GET /categories
recordingRouter.get('/', (req: Request, res: Response) => {
  if (req.baseUrl === '/categories') {
    res.json({ categories, version: META_VERSION });
    return;
  }
  handleGetActivities(req, res);
});

// GET /categories/version
recordingRouter.get('/version', (_req: Request, res: Response) => {
  res.json({ version: META_VERSION });
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
    if (records[userId].find(r => r.recordId === recordId)) {
      skippedIds.push(recordId);
      continue;
    }
    const cat = categories.find(c => c.categoryId === rec.categoryId);
    const points = cat?.basePoints || 10;
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
  const cat0 = categories.find(c => c.categoryId === (req.body.records?.[0]?.categoryId));
  const categoryType = cat0?.type || 'FOOD';
  const result = addPointsToAvatar(userId, totalNewPoints, categoryType, req.body.records?.[0]?.categoryId);

  res.status(201).json({
    ...result,
    skippedIds,
  });
});

// POST /activities/batch
recordingRouter.post('/batch', authMiddleware, (req: Request, res: Response) => {
  const userId = (req as any).userId;
  const { records: inputRecords } = req.body;
  if (!inputRecords || !Array.isArray(inputRecords)) {
    res.status(400).json({ error: 'records array required' }); return;
  }
  if (!records[userId]) records[userId] = [];
  const created: any[] = [];
  for (const rec of inputRecords) {
    const recordId = rec.recordId || uuid();
    if (records[userId].find(r => r.recordId === recordId)) continue;
    const cat = categories.find(c => c.categoryId === rec.categoryId);
    const entry = { recordId, categoryId: rec.categoryId, memo: rec.memo || null, points: cat?.basePoints || 10, recordedAt: rec.recordedAt || new Date().toISOString(), source: 'MANUAL' };
    records[userId].push(entry);
    created.push(entry);
  }
  res.json({ created, count: created.length });
});

// GET /activities/summary
recordingRouter.get('/summary', authMiddleware, (req: Request, res: Response) => {
  const userId = (req as any).userId;
  const userRecords = records[userId] || [];
  const period = (req.query.period as string) || 'today';
  const now = new Date();
  const todayStart = new Date(now); todayStart.setHours(0, 0, 0, 0);
  const weekStart = new Date(now); weekStart.setDate(weekStart.getDate() - 7);

  const todayRecords = userRecords.filter(r => new Date(r.recordedAt) >= todayStart);
  const weekRecords = userRecords.filter(r => new Date(r.recordedAt) >= weekStart);

  const weekByCategory: Record<string, { count: number; points: number }> = {};
  for (const r of weekRecords) {
    if (!weekByCategory[r.categoryId]) weekByCategory[r.categoryId] = { count: 0, points: 0 };
    weekByCategory[r.categoryId].count++;
    weekByCategory[r.categoryId].points += r.points;
  }

  res.json({
    todayCount: todayRecords.length,
    todayPoints: todayRecords.reduce((s, r) => s + r.points, 0),
    weekByCategory: Object.entries(weekByCategory).map(([categoryId, v]) => ({ categoryId, ...v })),
  });
});

// GET /activities
function handleGetActivities(req: Request, res: Response) {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ')) {
    res.json({ records: [], nextCursor: null, summary: { todayCount: 0, todayPoints: 0, weekByCategory: [] } });
    return;
  }
  const token = auth.replace('Bearer ', '');
  const userId = token.replace('mock-token-', '') || 'user-1';

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
  const rec = records[userId][idx];
  if (rec.source === 'MANUAL') { res.status(403).json({ error: 'Only auto-detected records can be deleted' }); return; }
  records[userId].splice(idx, 1);
  res.json({ message: 'Deleted' });
});
