import { Router, Request, Response } from 'express';
import { authMiddleware } from '../app';

export const authRouter = Router();

// インメモリストア
const users: Record<string, { email: string; password: string; nickname?: string; confirmed: boolean }> = {
  'admin@example.com': { email: 'admin@example.com', password: 'password', nickname: 'ぶたマスター', confirmed: true },
};

// POST /auth/signup
authRouter.post('/signup', (req: Request, res: Response) => {
  const { email, password } = req.body;
  if (!email || !password) { res.status(400).json({ error: 'email and password required' }); return; }
  if (users[email]) { res.status(400).json({ error: 'User already exists' }); return; }
  users[email] = { email, password, confirmed: false };
  res.json({ message: 'Confirmation code sent', code: '123456' });
});

// POST /auth/confirm
authRouter.post('/confirm', (req: Request, res: Response) => {
  const { email, code } = req.body;
  if (!email || !code) { res.status(400).json({ error: 'email and code required' }); return; }
  const user = users[email];
  if (!user) { res.status(400).json({ error: 'User not found' }); return; }
  if (code !== '123456') { res.status(400).json({ error: 'Invalid code' }); return; }
  user.confirmed = true;
  res.json({ message: 'Confirmed' });
});

// POST /auth/resend-code
authRouter.post('/resend-code', (req: Request, res: Response) => {
  const { email } = req.body;
  if (!email) { res.status(400).json({ error: 'email required' }); return; }
  res.json({ message: 'Code resent' });
});

// POST /auth/login
authRouter.post('/login', (req: Request, res: Response) => {
  const { email, password } = req.body;
  if (!email || !password) { res.status(401).json({ error: 'email and password required' }); return; }
  const user = users[email];
  if (!user || user.password !== password) { res.status(401).json({ error: 'Invalid credentials' }); return; }
  const userId = email.split('@')[0];
  res.json({
    accessToken: `mock-token-${userId}`,
    refreshToken: `mock-refresh-${userId}`,
    idToken: `mock-id-${userId}`,
  });
});

// POST /auth/logout
authRouter.post('/logout', (_req: Request, res: Response) => {
  res.json({ message: 'Logged out' });
});

// POST /auth/refresh
authRouter.post('/refresh', (req: Request, res: Response) => {
  const { refreshToken } = req.body;
  if (!refreshToken) { res.status(400).json({ error: 'refreshToken required' }); return; }
  const userId = refreshToken.replace('mock-refresh-', '');
  res.json({ accessToken: `mock-token-${userId}`, idToken: `mock-id-${userId}` });
});

// GET /users/me
authRouter.get('/me', authMiddleware, (req: Request, res: Response) => {
  const userId = (req as any).userId;
  res.json({ userId, nickname: userId, email: `${userId}@example.com` });
});

// POST /users/profile
authRouter.post('/profile', authMiddleware, (req: Request, res: Response) => {
  const userId = (req as any).userId;
  const { nickname } = req.body;
  res.status(201).json({ userId, nickname: nickname || userId });
});

// PUT /users/profile
authRouter.put('/profile', authMiddleware, (req: Request, res: Response) => {
  const userId = (req as any).userId;
  const { nickname } = req.body;
  res.json({ userId, nickname: nickname || userId });
});

// DELETE /account
authRouter.delete('/', authMiddleware, (_req: Request, res: Response) => {
  res.json({ message: 'Account deleted' });
});
