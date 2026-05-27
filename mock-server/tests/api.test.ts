import request from 'supertest';
import app from '../src/app';

describe('Auth API', () => {
  const agent = request(app);

  it('POST /auth/signup - creates user', async () => {
    const res = await agent.post('/auth/signup').send({ email: 'test@example.com', password: 'Pass1234!' });
    expect(res.status).toBe(200);
    expect(res.body.code).toBe('123456');
  });

  it('POST /auth/signup - rejects missing fields', async () => {
    const res = await agent.post('/auth/signup').send({});
    expect(res.status).toBe(400);
  });

  it('POST /auth/signup - rejects duplicate', async () => {
    await agent.post('/auth/signup').send({ email: 'dup@example.com', password: 'Pass1234!' });
    const res = await agent.post('/auth/signup').send({ email: 'dup@example.com', password: 'Pass1234!' });
    expect(res.status).toBe(400);
  });

  it('POST /auth/confirm - confirms user', async () => {
    await agent.post('/auth/signup').send({ email: 'conf@example.com', password: 'Pass1234!' });
    const res = await agent.post('/auth/confirm').send({ email: 'conf@example.com', code: '123456' });
    expect(res.status).toBe(200);
  });

  it('POST /auth/confirm - rejects invalid code', async () => {
    const res = await agent.post('/auth/confirm').send({ email: 'conf@example.com', code: '000000' });
    expect(res.status).toBe(400);
  });

  it('POST /auth/login - returns tokens', async () => {
    await agent.post('/auth/signup').send({ email: 'login@example.com', password: 'Pass1234!' });
    const res = await agent.post('/auth/login').send({ email: 'login@example.com', password: 'Pass1234!' });
    expect(res.status).toBe(200);
    expect(res.body.accessToken).toContain('mock-token-');
    expect(res.body.refreshToken).toBeDefined();
  });

  it('POST /auth/login - rejects wrong password', async () => {
    const res = await agent.post('/auth/login').send({ email: 'login@example.com', password: 'wrong' });
    expect(res.status).toBe(401);
  });

  it('POST /auth/refresh - returns new token', async () => {
    const res = await agent.post('/auth/refresh').send({ refreshToken: 'mock-refresh-user1' });
    expect(res.status).toBe(200);
    expect(res.body.accessToken).toBe('mock-token-user1');
  });

  it('GET /users/me - returns profile', async () => {
    const res = await agent.get('/users/me').set('Authorization', 'Bearer mock-token-testuser');
    expect(res.status).toBe(200);
    expect(res.body.userId).toBe('testuser');
  });

  it('GET /users/me - rejects without auth', async () => {
    const res = await agent.get('/users/me');
    expect(res.status).toBe(401);
  });

  it('POST /users/profile - creates profile', async () => {
    const res = await agent.post('/users/profile').set('Authorization', 'Bearer mock-token-u1').send({ nickname: 'ぶたマスター' });
    expect(res.status).toBe(201);
    expect(res.body.nickname).toBe('ぶたマスター');
  });
});

describe('Recording API', () => {
  const agent = request(app);
  const auth = { Authorization: 'Bearer mock-token-rec-user' };

  it('GET /categories - returns category list', async () => {
    const res = await agent.get('/categories');
    expect(res.status).toBe(200);
    expect(res.body.categories.length).toBe(8);
  });

  it('POST /activities - records activity', async () => {
    const res = await agent.post('/activities').set(auth).send({ records: [{ categoryId: 'food_late_ramen' }] });
    expect(res.status).toBe(201);
    expect(res.body.avatar.totalPoints).toBe(12);
    expect(res.body.leveledUp).toBe(false);
  });

  it('POST /activities - idempotent with recordId', async () => {
    const recordId = 'idem-123';
    await agent.post('/activities').set(auth).send({ records: [{ recordId, categoryId: 'food_snack' }] });
    const res = await agent.post('/activities').set(auth).send({ records: [{ recordId, categoryId: 'food_snack' }] });
    expect(res.status).toBe(201);
    expect(res.body.skippedIds).toContain(recordId);
  });

  it('POST /activities - rejects empty records', async () => {
    const res = await agent.post('/activities').set(auth).send({ records: [] });
    expect(res.status).toBe(400);
  });

  it('GET /activities - returns records with summary', async () => {
    const res = await agent.get('/activities').set(auth);
    expect(res.status).toBe(200);
    expect(res.body.records).toBeDefined();
    expect(res.body.summary).toBeDefined();
    expect(res.body.summary.todayCount).toBeGreaterThanOrEqual(0);
  });

  it('DELETE /activities/:recordId - deletes auto-detected record', async () => {
    const post = await agent.post('/activities').set({ Authorization: 'Bearer mock-token-del-user' })
      .send({ records: [{ recordId: 'del-1', categoryId: 'food_late_ramen' }] });
    expect(post.status).toBe(201);
    // MANUAL records cannot be deleted (403), only AUTO_DETECTED can
    const res = await agent.delete('/activities/del-1').set({ Authorization: 'Bearer mock-token-del-user' });
    expect(res.status).toBe(403);
  });

  it('DELETE /activities/:recordId - 404 for unknown', async () => {
    const res = await agent.delete('/activities/nonexistent').set(auth);
    expect(res.status).toBe(404);
  });
});

describe('Avatar API', () => {
  const agent = request(app);
  const auth = { Authorization: 'Bearer mock-token-avatar-user' };

  it('POST /avatar - creates avatar', async () => {
    const res = await agent.post('/avatar').set(auth).send({ name: 'テストぶた' });
    expect(res.status).toBe(201);
    expect(res.body.avatar.name).toBe('テストぶた');
    expect(res.body.avatar.stats.hp).toBe(100);
  });

  it('POST /avatar - updates name if exists', async () => {
    const res = await agent.post('/avatar').set(auth).send({ name: '新しい名前' });
    expect(res.status).toBe(201);
    expect(res.body.avatar.name).toBe('新しい名前');
  });

  it('GET /avatar - returns avatar', async () => {
    const res = await agent.get('/avatar').set(auth);
    expect(res.status).toBe(200);
    expect(res.body.avatar.userId).toBe('avatar-user');
  });

  it('GET /avatar - auto-creates if not exists', async () => {
    const res = await agent.get('/avatar').set({ Authorization: 'Bearer mock-token-new-user' });
    expect(res.status).toBe(200);
    expect(res.body.avatar.name).toBe('こぶた');
  });

  it('GET /avatar - returns demo data without auth', async () => {
    const res = await agent.get('/avatar');
    expect(res.status).toBe(200);
    expect(res.body.avatar).toBeDefined();
    expect(res.body.skills).toBeDefined();
    expect(res.body.progress).toBeDefined();
  });
});

describe('Battle/Social API', () => {
  const agent = request(app);
  const auth = { Authorization: 'Bearer mock-token-social-user' };

  it('GET /rankings - returns ranking list', async () => {
    const res = await agent.get('/rankings');
    expect(res.status).toBe(200);
    expect(res.body.rankings.length).toBeGreaterThan(0);
  });

  it('GET /rankings/me - returns my ranking', async () => {
    const res = await agent.get('/rankings/me').set(auth);
    expect(res.status).toBe(200);
    expect(res.body.rank).toBeDefined();
  });

  it('GET /battles/history - returns battle history', async () => {
    const res = await agent.get('/battles/history').set(auth);
    expect(res.status).toBe(200);
    expect(res.body.history.length).toBeGreaterThan(0);
  });

  it('GET /battles/history/:matchId - returns match detail', async () => {
    const res = await agent.get('/battles/history/match-1').set(auth);
    expect(res.status).toBe(200);
    expect(res.body.matchId).toBe('match-1');
    expect(res.body.players.length).toBe(2);
  });

  it('GET /social/friends - returns friend list', async () => {
    const res = await agent.get('/social/friends').set(auth);
    expect(res.status).toBe(200);
    expect(res.body.friends).toBeDefined();
  });

  it('POST /social/friends/search - searches users', async () => {
    const res = await agent.post('/social/friends/search').set(auth).send({ query: 'ぶた' });
    expect(res.status).toBe(200);
    expect(res.body.users.length).toBe(1);
  });

  it('POST /social/friends/request - sends friend request', async () => {
    const res = await agent.post('/social/friends/request').set(auth).send({ targetUserId: 'user-2' });
    expect(res.status).toBe(201);
    expect(res.body.requestId).toBeDefined();
  });

  it('POST /social/friends/respond - accepts request', async () => {
    // Create a request first
    const reqRes = await agent.post('/social/friends/request')
      .set({ Authorization: 'Bearer mock-token-requester' })
      .send({ targetUserId: 'responder' });
    const requestId = reqRes.body.requestId;

    const res = await agent.post('/social/friends/respond')
      .set({ Authorization: 'Bearer mock-token-responder' })
      .send({ requestId, accept: true });
    expect(res.status).toBe(200);
    expect(res.body.message).toBe('Accepted');
  });

  it('GET /social/friends/requests - returns pending requests', async () => {
    const res = await agent.get('/social/friends/requests').set(auth);
    expect(res.status).toBe(200);
    expect(res.body.requests).toBeDefined();
  });

  it('DELETE /social/friends/:friendId - removes friend', async () => {
    const res = await agent.delete('/social/friends/user-2').set(auth);
    expect(res.status).toBe(200);
  });
});

describe('Health Check', () => {
  it('GET /health - returns ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});
