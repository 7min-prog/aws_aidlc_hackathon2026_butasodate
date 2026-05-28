import { Router, Request, Response } from 'express';
import { v4 as uuid } from 'uuid';

export const adminRouter = Router();

const ADMIN_USER = 'admin';
const ADMIN_PASSWORD = 'butasodate2026';
const JWT_SECRET = 'mock-admin-jwt';

// 簡易JWT認証
function adminAuth(req: Request, res: Response, next: () => void) {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ') || auth.replace('Bearer ', '') !== 'mock-admin-token') {
    res.status(401).json({ error: 'Unauthorized' }); return;
  }
  next();
}

// インメモリストア
const evolutionPaths = [
  { pathId: 'food-path', name: 'グルメロード', description: '食の道を極めし者', stages: 3 },
  { pathId: 'lifestyle-path', name: 'ぐうたらロード', description: '怠惰の極みを目指す者', stages: 3 },
  { pathId: 'mixed-path', name: 'バランスロード', description: '全方位にダメな者', stages: 3 },
];

const adminSkills = [
  { skillId: 'skill-1', name: 'ラーメンスプラッシュ', type: 'ATTACK', targetStat: 'attack', multiplier: 1.5, cooldown: 2, spriteAnimationKey: 'ramen-splash', evolutionPathId: 'food-path' },
  { skillId: 'skill-2', name: 'もちもちガード', type: 'DEFENSE', targetStat: 'defense', multiplier: 0.3, cooldown: 3, spriteAnimationKey: 'mochi-guard', evolutionPathId: 'food-path' },
  { skillId: 'skill-3', name: '二度寝バリア', type: 'DEFENSE', targetStat: 'defense', multiplier: 0.3, cooldown: 3, spriteAnimationKey: 'sleep-barrier', evolutionPathId: 'lifestyle-path' },
  { skillId: 'skill-4', name: 'だらだらビーム', type: 'ATTACK', targetStat: 'attack', multiplier: 1.8, cooldown: 2, spriteAnimationKey: 'lazy-beam', evolutionPathId: 'lifestyle-path' },
  { skillId: 'skill-5', name: 'ヒーリングスナック', type: 'HEAL', targetStat: 'hp', multiplier: 0.4, cooldown: 4, spriteAnimationKey: 'heal-snack', evolutionPathId: 'mixed-path' },
];

const gameConfig: Record<string, any> = {
  'points_per_level': { configKey: 'points_per_level', value: 100 },
  'stage2_level': { configKey: 'stage2_level', value: 5 },
  'stage3_level': { configKey: 'stage3_level', value: 15 },
};

const auditLog: any[] = [];

// POST /admin/login
adminRouter.post('/login', (req: Request, res: Response) => {
  const { user, password } = req.body;
  if (user === ADMIN_USER && password === ADMIN_PASSWORD) {
    res.json({ token: 'mock-admin-token' });
  } else {
    res.status(401).json({ error: 'Invalid credentials' });
  }
});

// GET /admin/users
adminRouter.get('/users', adminAuth, (req: Request, res: Response) => {
  res.json({ users: [
    { username: 'admin', email: 'admin@example.com', status: 'CONFIRMED', createdAt: '2026-05-01T00:00:00Z' },
    { username: 'user-1', email: 'user1@example.com', status: 'CONFIRMED', createdAt: '2026-05-10T00:00:00Z' },
  ]});
});

// GET /admin/users/:username
adminRouter.get('/users/:username', adminAuth, (req: Request, res: Response) => {
  const { username } = req.params;
  res.json({ username, email: `${username}@example.com`, status: 'CONFIRMED', createdAt: '2026-05-01T00:00:00Z' });
});

// PUT /admin/users/:username/profile
adminRouter.put('/users/:username/profile', adminAuth, (req: Request, res: Response) => {
  res.json({ message: 'Profile updated', ...req.body });
});

// DELETE /admin/users/:username
adminRouter.delete('/users/:username', adminAuth, (req: Request, res: Response) => {
  res.json({ message: `User ${req.params.username} deleted` });
});

// POST /admin/users/:username/disable
adminRouter.post('/users/:username/disable', adminAuth, (req: Request, res: Response) => {
  res.json({ message: `User ${req.params.username} disabled` });
});

// POST /admin/users/:username/enable
adminRouter.post('/users/:username/enable', adminAuth, (req: Request, res: Response) => {
  res.json({ message: `User ${req.params.username} enabled` });
});

// POST /admin/users/:username/health-data
adminRouter.post('/users/:username/health-data', adminAuth, (req: Request, res: Response) => {
  res.json({ message: 'Health data recorded', ...req.body });
});

// --- Evolution Paths ---
adminRouter.get('/evolution-paths', adminAuth, (_req: Request, res: Response) => {
  res.json({ evolutionPaths });
});

adminRouter.post('/evolution-paths', adminAuth, (req: Request, res: Response) => {
  const path = { pathId: uuid(), ...req.body };
  evolutionPaths.push(path);
  res.status(201).json(path);
});

adminRouter.put('/evolution-paths/:pathId', adminAuth, (req: Request, res: Response) => {
  const idx = evolutionPaths.findIndex(p => p.pathId === req.params.pathId);
  if (idx === -1) { res.status(404).json({ error: 'Not found' }); return; }
  Object.assign(evolutionPaths[idx], req.body);
  res.json(evolutionPaths[idx]);
});

adminRouter.delete('/evolution-paths/:pathId', adminAuth, (req: Request, res: Response) => {
  const idx = evolutionPaths.findIndex(p => p.pathId === req.params.pathId);
  if (idx === -1) { res.status(404).json({ error: 'Not found' }); return; }
  evolutionPaths.splice(idx, 1);
  res.json({ message: 'Deleted' });
});

// GET/PUT /admin/evolution-paths/:pathId/skills
adminRouter.get('/evolution-paths/:pathId/skills', adminAuth, (req: Request, res: Response) => {
  const pathSkills = adminSkills.filter(s => s.evolutionPathId === req.params.pathId);
  res.json({ skillIds: pathSkills.map(s => s.skillId) });
});

adminRouter.put('/evolution-paths/:pathId/skills', adminAuth, (req: Request, res: Response) => {
  res.json({ message: 'Skills updated', skillIds: req.body.skillIds });
});

// --- Skills ---
adminRouter.get('/skills', adminAuth, (_req: Request, res: Response) => {
  res.json({ skills: adminSkills });
});

adminRouter.post('/skills', adminAuth, (req: Request, res: Response) => {
  const skill = { skillId: uuid(), ...req.body };
  adminSkills.push(skill);
  res.status(201).json(skill);
});

adminRouter.put('/skills/:skillId', adminAuth, (req: Request, res: Response) => {
  const idx = adminSkills.findIndex(s => s.skillId === req.params.skillId);
  if (idx === -1) { res.status(404).json({ error: 'Not found' }); return; }
  Object.assign(adminSkills[idx], req.body);
  res.json(adminSkills[idx]);
});

adminRouter.delete('/skills/:skillId', adminAuth, (req: Request, res: Response) => {
  const idx = adminSkills.findIndex(s => s.skillId === req.params.skillId);
  if (idx === -1) { res.status(404).json({ error: 'Not found' }); return; }
  adminSkills.splice(idx, 1);
  res.json({ message: 'Deleted' });
});

// --- Game Config ---
adminRouter.get('/game-config', adminAuth, (_req: Request, res: Response) => {
  res.json({ configs: Object.values(gameConfig) });
});

adminRouter.put('/game-config', adminAuth, (req: Request, res: Response) => {
  const { configKey, value } = req.body;
  gameConfig[configKey] = { configKey, value };
  res.json({ message: 'Updated', configKey, value });
});

// --- Audit Log ---
adminRouter.get('/audit-log', adminAuth, (req: Request, res: Response) => {
  const limit = parseInt(req.query.limit as string) || 50;
  res.json({ logs: auditLog.slice(-limit) });
});

// --- Upload URL ---
adminRouter.post('/upload-url', adminAuth, (req: Request, res: Response) => {
  const { fileName, contentType } = req.body;
  const key = `assets/sprites/${uuid()}-${fileName}`;
  res.json({ uploadUrl: `https://mock-s3.example.com/${key}?presigned=true`, key });
});
