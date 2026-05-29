import { Router, Request, Response } from 'express';
import { v4 as uuid } from 'uuid';
import { authMiddleware } from '../app';

export const battleSocialRouter = Router();

// インメモリストア
const friends: Record<string, string[]> = {
  'admin': ['user-1', 'user-2', 'user-3', 'user-4', 'user-5', 'user-6', 'user-7', 'user-8'],
};
const friendRequests: any[] = [
  { requestId: 'req-1', from: 'user-9', to: 'admin', status: 'PENDING' },
  { requestId: 'req-2', from: 'user-10', to: 'admin', status: 'PENDING' },
];

// フレンドのプロフィールデータ
const friendProfiles: Record<string, { nickname: string; level: number }> = {
  'user-1': { nickname: 'メガトンぶた', level: 8 },
  'user-2': { nickname: 'まるまるキング', level: 6 },
  'user-3': { nickname: 'ぽっちゃり姫', level: 5 },
  'user-4': { nickname: 'こぶたマン', level: 4 },
  'user-5': { nickname: 'デブねこ', level: 7 },
  'user-6': { nickname: 'ねむりぶた', level: 3 },
  'user-7': { nickname: 'はやあしぶた', level: 5 },
  'user-8': { nickname: 'てつぶた', level: 6 },
  'user-9': { nickname: 'ほのおぶた', level: 4 },
  'user-10': { nickname: 'こおりぶた', level: 3 },
};

// --- Rankings ---
// GET /rankings
battleSocialRouter.get('/', (_req: Request, res: Response) => {
  const names = ['メガトンぶた', 'まるまるキング', 'ぽっちゃり姫', 'こぶたマスター', 'デブねこ', 'ねむりぶた', 'はやあしぶた', 'てつぶた', 'ほのおぶた', 'スリムぶた', 'ゴッドぶた', 'にんじゃぶた', 'ドラゴンぶた', 'うちゅうぶた', 'おうさまぶた'];
  const rankings = names.map((name, i) => ({
    userId: `user-${i + 1}`,
    nickname: name,
    points: 9800 - i * 450,
    wins: 42 - i * 2,
    losses: 8 + i * 3,
  }));
  res.json({ rankings });
});

// GET /rankings/me
battleSocialRouter.get('/me', authMiddleware, (req: Request, res: Response) => {
  const userId = (req as any).userId;
  res.json({ userId, rank: 3, points: 3450, wins: 15, losses: 20 });
});

// --- Battles ---
// GET /battles/history (mapped as /history from /battles base)
battleSocialRouter.get('/history', authMiddleware, (_req: Request, res: Response) => {
  const opponents = ['こぶたマン', 'デブねこ', 'スリムぶた', 'メガトンくん', 'ぽっちゃり姫', 'ねむりぶた', 'はやあし', 'てつぶた'];
  const history = [];
  for (let i = 0; i < 30; i++) {
    const win = i % 3 !== 1;
    history.push({
      matchId: `match-${i + 1}`,
      opponentId: `user-${(i % 8) + 1}`,
      opponentNickname: opponents[i % opponents.length],
      result: win ? 'WIN' : 'LOSE',
      pointsChange: win ? 80 + (i % 5) * 20 : -(60 + (i % 4) * 10),
      date: new Date(Date.now() - i * 86400000).toISOString(),
    });
  }
  res.json({ history });
});

// GET /battles/history/:matchId
battleSocialRouter.get('/history/:matchId', authMiddleware, (req: Request, res: Response) => {
  const { matchId } = req.params;
  res.json({
    matchId,
    players: [
      { userId: 'user-1', nickname: 'プレイヤー1', avatar: { level: 3, stats: { hp: 280, attack: 45, defense: 52, speed: 28 } } },
      { userId: 'user-2', nickname: 'プレイヤー2', avatar: { level: 4, stats: { hp: 320, attack: 50, defense: 40, speed: 35 } } },
    ],
    turns: [],
    result: 'WIN',
    duration: 120,
  });
});

// --- Social/Friends ---
// GET /social/friends (mapped as /friends from /social base)
battleSocialRouter.get('/friends', authMiddleware, (req: Request, res: Response) => {
  const userId = (req as any).userId;
  const userFriends = friends[userId] || [];
  res.json({
    friends: userFriends.map(id => ({
      userId: id,
      nickname: friendProfiles[id]?.nickname || id,
      level: friendProfiles[id]?.level || 1,
      online: Math.random() > 0.5,
    })),
  });
});

// POST /social/friends/search
battleSocialRouter.post('/friends/search', authMiddleware, (req: Request, res: Response) => {
  const { query } = req.body;
  res.json({
    users: [
      { userId: `user-${query}`, nickname: query || 'unknown', level: 3 },
    ],
  });
});

// POST /social/friends/request
battleSocialRouter.post('/friends/request', authMiddleware, (req: Request, res: Response) => {
  const userId = (req as any).userId;
  const { targetUserId } = req.body;
  if (!targetUserId) { res.status(400).json({ error: 'targetUserId required' }); return; }
  const requestId = uuid();
  friendRequests.push({ requestId, from: userId, to: targetUserId, status: 'PENDING' });
  res.status(201).json({ requestId, message: 'Friend request sent' });
});

// POST /social/friends/respond
battleSocialRouter.post('/friends/respond', authMiddleware, (req: Request, res: Response) => {
  const userId = (req as any).userId;
  const { requestId, accept } = req.body;
  const request = friendRequests.find(r => r.requestId === requestId);
  if (!request) { res.status(404).json({ error: 'Request not found' }); return; }
  if (accept) {
    if (!friends[userId]) friends[userId] = [];
    if (!friends[request.from]) friends[request.from] = [];
    friends[userId].push(request.from);
    friends[request.from].push(userId);
    request.status = 'ACCEPTED';
  } else {
    request.status = 'REJECTED';
  }
  res.json({ message: accept ? 'Accepted' : 'Rejected' });
});

// GET /social/friends/requests
battleSocialRouter.get('/friends/requests', authMiddleware, (req: Request, res: Response) => {
  const userId = (req as any).userId;
  const pending = friendRequests.filter(r => r.to === userId && r.status === 'PENDING');
  res.json({ requests: pending });
});

// DELETE /social/friends/:friendId
battleSocialRouter.delete('/friends/:friendId', authMiddleware, (req: Request, res: Response) => {
  const userId = (req as any).userId;
  const { friendId } = req.params;
  if (friends[userId]) {
    friends[userId] = friends[userId].filter(id => id !== friendId);
  }
  res.json({ message: 'Friend removed' });
});
