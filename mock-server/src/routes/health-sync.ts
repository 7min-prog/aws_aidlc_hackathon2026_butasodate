import { Router, Request, Response } from 'express';
import { authMiddleware } from '../app';

export const healthSyncRouter = Router();

// POST /health-sync
healthSyncRouter.post('/', authMiddleware, (req: Request, res: Response) => {
  const { records } = req.body;
  if (!records || !Array.isArray(records)) {
    res.status(400).json({ error: 'records array required' }); return;
  }
  res.json({ synced: records.length, message: 'Health data synced' });
});

// GET /health-sync/result — アプリ起動時のヘルスデータ同期結果
healthSyncRouter.get('/result', authMiddleware, (_req: Request, res: Response) => {
  res.json({
    hasResults: true,
    syncedAt: new Date().toISOString(),
    items: [
      { category: 'WEIGHT', label: 'たいじゅう', value: '+0.5kg', evaluation: 'UNHEALTHY', points: 30 },
      { category: 'SLEEP', label: 'すいみん', value: '12じかん (ねすぎ！)', evaluation: 'UNHEALTHY', points: 20 },
      { category: 'STEPS', label: 'ほすう', value: '800ほ (すくない！)', evaluation: 'UNHEALTHY', points: 40 },
    ],
    totalPoints: 90,
  });
});
