import express from 'express';
import cors from 'cors';
import { authRouter } from './routes/auth';
import { recordingRouter } from './routes/recording';
import { avatarRouter } from './routes/avatar';
import { battleSocialRouter } from './routes/battle-social';

const app = express();
app.use(cors());
app.use(express.json());

// 簡易認証ミドルウェア
export function authMiddleware(req: express.Request, res: express.Response, next: express.NextFunction): void {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }
  // mockではトークンからuserIdを抽出（mock-token-{userId}形式）
  const token = auth.replace('Bearer ', '');
  (req as any).userId = token.replace('mock-token-', '') || 'user-1';
  next();
}

app.use('/auth', authRouter);
app.use('/users', authRouter);
app.use('/account', authRouter);
app.use('/activities', recordingRouter);
app.use('/categories', recordingRouter);
app.use('/avatar', avatarRouter);
app.use('/rankings', battleSocialRouter);
app.use('/battles', battleSocialRouter);
app.use('/social', battleSocialRouter);

// ヘルスチェック
app.get('/health', (_req, res) => res.json({ status: 'ok' }));

export default app;
