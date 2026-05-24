import { Router, Request, Response } from 'express';
import { v4 as uuid } from 'uuid';
import { authMiddleware } from '../app';

export const battleSocialRouter = Router();

// インメモリストア
const friends: Record<string, string[]> = {};
const friendRequests: any[] = [];

// --- Rankings ---
// GET /rankings
battleSocialRouter.get('/', (_req: Request, res: Response) => {
  res.json({
    rankings: [
      { userId: 'user-1', nickname: 'メガトンぶた', points: 9800, wins: 42, losses: 8 },
      { userId: 'user-2', nickname: 'まるまるキング', points: 8500, wins: 35, losses: 12 },
      { userId: 'user-3', nickname: 'ぽっちゃり', points: 3450, wins: 15, losses: 20 },
    ],
  });
});

// GET /rankings/me
battleSocialRouter.get('/me', authMiddleware, (req: Request, res: Response) => {
  const userId = (req as any).userId;
  res.json({ userId, rank: 3, points: 3450, wins: 15, losses: 20 });
});

// --- Battles ---
// GET /battles/history (mapped as /history from /battles base)
battleSocialRouter.get('/history', authMiddleware, (_req: Request, res: Response) => {
  res.json({
    history: [
      { matchId: 'match-1', opponentId: 'user-1', opponentNickname: 'こぶたマン', result: 'WIN', pointsChange: 120, date: '2026-05-23T18:00:00Z' },
      { matchId: 'match-2', opponentId: 'user-2', opponentNickname: 'デブねこ', result: 'LOSE', pointsChange: -80, date: '2026-05-22T20:00:00Z' },
      { matchId: 'match-3', opponentId: 'user-3', opponentNickname: 'スリムぶた', result: 'WIN', pointsChange: 100, date: '2026-05-21T15:00:00Z' },
    ],
  });
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
    friends: userFriends.map(id => ({ userId: id, nickname: id, online: Math.random() > 0.5 })),
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
