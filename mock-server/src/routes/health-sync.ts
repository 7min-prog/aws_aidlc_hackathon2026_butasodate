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
