import express from 'express';
import cors from 'cors';
import { authRouter } from './routes/auth';
import { recordingRouter } from './routes/recording';
import { avatarRouter } from './routes/avatar';
import { battleSocialRouter } from './routes/battle-social';
import { healthSyncRouter } from './routes/health-sync';
import { adminRouter } from './routes/admin';

const app = express();
app.use(cors());
app.use(express.json());

// リクエストログ
app.use((req, _res, next) => {
  const ts = new Date().toISOString();
  console.log(`[${ts}] ${req.method} ${req.originalUrl} | Auth: ${req.headers.authorization || '(none)'}`);
  if (req.method === 'POST' || req.method === 'PUT') {
    console.log(`  Body: ${JSON.stringify(req.body)}`);
  }
  next();
});

// 簡易認証ミドルウェア
export function authMiddleware(req: express.Request, res: express.Response, next: express.NextFunction): void {
  const auth = req.headers.authorization;
  if (!auth) {
    console.log(`  ❌ AUTH FAILED: No Authorization header`);
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }
  // Bearer付きでもなしでも許容
  const token = auth.startsWith('Bearer ') ? auth.replace('Bearer ', '') : auth;
  const userId = token.replace('mock-token-', '').replace('mock-id-', '') || 'user-1';
  console.log(`  ✅ AUTH OK: userId="${userId}" token="${token}"`);
  (req as any).userId = userId;
  next();
}

// レスポンスログ
app.use((req, res, next) => {
  const originalJson = res.json.bind(res);
  res.json = (body: any) => {
    console.log(`  → ${res.statusCode} ${req.method} ${req.originalUrl}`);
    return originalJson(body);
  };
  next();
});

app.use('/auth', authRouter);
app.use('/users', authRouter);
app.use('/account', authRouter);
app.use('/activities', recordingRouter);
app.use('/categories', recordingRouter);
app.use('/health-sync', healthSyncRouter);
app.use('/avatar', avatarRouter);
app.use('/rankings', battleSocialRouter);
app.use('/battles', battleSocialRouter);
app.use('/social', battleSocialRouter);
app.use('/admin', adminRouter);

// ヘルスチェック
app.get('/health', (_req, res) => res.json({ status: 'ok' }));

export default app;
