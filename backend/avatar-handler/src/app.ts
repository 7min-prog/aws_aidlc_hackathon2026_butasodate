import { OpenAPIHono, createRoute, z } from '@hono/zod-openapi';
import { handle } from 'hono/aws-lambda';
import { cors } from 'hono/cors';
import * as avatarService from './services/avatar-service';
import { getPigSpecies, getEvolutionRoutes, getSkills, getGameConfig } from './services/master-data-cache';
import { pointsForLevel } from './services/evolution-engine';
import {
  AvatarSchema, SkillSchema, EvolutionHistorySchema,
  CreateAvatarRequestSchema, AddPointsRequestSchema, DeductPointsRequestSchema,
  ErrorResponseSchema,
} from './schemas';

const app = new OpenAPIHono();

app.use('*', cors({
  origin: '*',
  allowHeaders: ['Content-Type', 'Authorization'],
}));

// ユーザーID取得ヘルパー
function getUserId(c: { req: { header: (name: string) => string | undefined; raw: any } }): string | null {
  // Hono aws-lambda adapter: raw event is accessible via c.env.event
  const event = (c as any).env?.event;
  if (event?.requestContext?.authorizer?.claims?.sub) {
    return event.requestContext.authorizer.claims.sub;
  }
  // Fallback for direct header (testing)
  return c.req.header('x-user-id') || null;
}

// POST /avatar - アバター作成
const createAvatarRoute = createRoute({
  method: 'post',
  path: '/avatar',
  tags: ['Avatar'],
  summary: 'アバターを作成',
  request: { body: { content: { 'application/json': { schema: CreateAvatarRequestSchema } } } },
  responses: {
    201: { description: '作成成功', content: { 'application/json': { schema: z.object({ avatar: AvatarSchema }) } } },
    401: { description: '認証エラー', content: { 'application/json': { schema: ErrorResponseSchema } } },
    409: { description: '既に存在', content: { 'application/json': { schema: ErrorResponseSchema } } },
  },
});

app.openapi(createAvatarRoute, async (c) => {
  const userId = getUserId(c);
  if (!userId) return c.json({ error: 'Unauthorized' }, 401);
  const body = c.req.valid('json');
  try {
    const avatar = await avatarService.createAvatar(userId, body.name);
    return c.json({ avatar }, 201);
  } catch (e: unknown) {
    if (e instanceof Error && e.message === 'AVATAR_EXISTS') {
      return c.json({ error: 'Avatar already exists' }, 409);
    }
    throw e;
  }
});

// GET /avatar - アバター取得
const getAvatarRoute = createRoute({
  method: 'get',
  path: '/avatar',
  tags: ['Avatar'],
  summary: 'アバター情報を取得',
  responses: {
    200: {
      description: '取得成功',
      content: { 'application/json': { schema: z.object({
        avatar: AvatarSchema,
        skills: z.array(SkillSchema),
        evolutionPath: z.object({ name: z.string(), description: z.string() }).nullable(),
        progress: z.object({
          nextLevelPoints: z.number(),
          nextEvolutionLevel: z.number().nullable(),
          categoryRatio: z.object({ food: z.number(), lifestyle: z.number() }),
        }),
      }) } },
    },
    401: { description: '認証エラー', content: { 'application/json': { schema: ErrorResponseSchema } } },
    404: { description: '未発見', content: { 'application/json': { schema: ErrorResponseSchema } } },
  },
});

app.openapi(getAvatarRoute, async (c) => {
  const userId = getUserId(c);
  if (!userId) return c.json({ error: 'Unauthorized' }, 401);

  const avatar = await avatarService.getAvatar(userId);
  if (!avatar) return c.json({ error: 'Avatar not found' }, 404);

  const [species, skills, config] = await Promise.all([getPigSpecies(), getSkills(), getGameConfig()]);
  const ownedSkills = skills.filter(s => avatar.skillIds.includes(s.skillId));
  const currentSpecies = species.find(s => s.speciesId === avatar.currentSpeciesId) || null;

  const nextLevelPoints = pointsForLevel(avatar.level + 1, config) - avatar.totalPoints;
  let nextEvolutionLevel: number | null = null;
  if (avatar.evolutionStage === 1) nextEvolutionLevel = config.EVOLUTION_LEVEL_STAGE2;
  else if (avatar.evolutionStage === 2) nextEvolutionLevel = config.EVOLUTION_LEVEL_STAGE3;

  return c.json({
    avatar,
    skills: ownedSkills,
    evolutionPath: currentSpecies ? { name: currentSpecies.name, description: currentSpecies.description } : null,
    progress: {
      nextLevelPoints: Math.max(0, nextLevelPoints),
      nextEvolutionLevel,
      categoryRatio: {
        food: avatar.totalPoints > 0 ? avatar.categoryPoints.FOOD / avatar.totalPoints : 0,
        lifestyle: avatar.totalPoints > 0 ? avatar.categoryPoints.LIFESTYLE / avatar.totalPoints : 0,
      },
    },
  }, 200);
});

// GET /avatar/evolution-history - 進化履歴取得
const getHistoryRoute = createRoute({
  method: 'get',
  path: '/avatar/evolution-history',
  tags: ['Avatar'],
  summary: '進化履歴を取得',
  responses: {
    200: { description: '取得成功', content: { 'application/json': { schema: z.object({ history: z.array(EvolutionHistorySchema) }) } } },
    401: { description: '認証エラー', content: { 'application/json': { schema: ErrorResponseSchema } } },
  },
});

app.openapi(getHistoryRoute, async (c) => {
  const userId = getUserId(c);
  if (!userId) return c.json({ error: 'Unauthorized' }, 401);
  const history = await avatarService.getEvolutionHistory(userId);
  return c.json({ history }, 200);
});

// PUT /avatar/name - アバター名変更
const updateNameRoute = createRoute({
  method: 'put',
  path: '/avatar/name',
  tags: ['Avatar'],
  summary: 'アバター名を変更',
  request: { body: { content: { 'application/json': { schema: z.object({ name: z.string().min(1).max(20) }) } } } },
  responses: {
    200: { description: '変更成功', content: { 'application/json': { schema: z.object({ avatar: AvatarSchema }) } } },
    401: { description: '認証エラー', content: { 'application/json': { schema: ErrorResponseSchema } } },
    404: { description: '未発見', content: { 'application/json': { schema: ErrorResponseSchema } } },
  },
});

app.openapi(updateNameRoute, async (c) => {
  const userId = getUserId(c);
  if (!userId) return c.json({ error: 'Unauthorized' }, 401);
  const { name } = c.req.valid('json');
  try {
    const avatar = await avatarService.updateAvatarName(userId, name);
    return c.json({ avatar }, 200);
  } catch (e: unknown) {
    if (e instanceof Error && e.message === 'AVATAR_NOT_FOUND') {
      return c.json({ error: 'Avatar not found' }, 404);
    }
    throw e;
  }
});

// GET /avatar/score-detail - スコア詳細取得
const getScoreDetailRoute = createRoute({
  method: 'get',
  path: '/avatar/score-detail',
  tags: ['Avatar'],
  summary: 'スコア詳細を取得',
  responses: {
    200: {
      description: '取得成功',
      content: { 'application/json': { schema: z.object({
        totalPoints: z.number(),
        categoryBreakdown: z.record(z.string(), z.number()),
        categoryRatio: z.object({ food: z.number(), lifestyle: z.number() }),
        nextEvolution: z.object({
          requiredLevel: z.number(),
          currentLevel: z.number(),
          remainingPoints: z.number().nullable(),
        }).nullable(),
      }) } },
    },
    401: { description: '認証エラー', content: { 'application/json': { schema: ErrorResponseSchema } } },
    404: { description: '未発見', content: { 'application/json': { schema: ErrorResponseSchema } } },
  },
});

app.openapi(getScoreDetailRoute, async (c) => {
  const userId = getUserId(c);
  if (!userId) return c.json({ error: 'Unauthorized' }, 401);

  const avatar = await avatarService.getAvatar(userId);
  if (!avatar) return c.json({ error: 'Avatar not found' }, 404);

  const config = await getGameConfig();
  let nextEvolutionRequiredLevel: number | null = null;
  if (avatar.evolutionStage === 1) nextEvolutionRequiredLevel = config.EVOLUTION_LEVEL_STAGE2;
  else if (avatar.evolutionStage === 2) nextEvolutionRequiredLevel = config.EVOLUTION_LEVEL_STAGE3;

  const remainingPoints = nextEvolutionRequiredLevel
    ? Math.max(0, pointsForLevel(nextEvolutionRequiredLevel, config) - avatar.totalPoints)
    : null;

  return c.json({
    totalPoints: avatar.totalPoints,
    categoryBreakdown: avatar.categoryPoints,
    categoryRatio: {
      food: avatar.totalPoints > 0 ? avatar.categoryPoints.FOOD / avatar.totalPoints : 0,
      lifestyle: avatar.totalPoints > 0 ? avatar.categoryPoints.LIFESTYLE / avatar.totalPoints : 0,
    },
    nextEvolution: nextEvolutionRequiredLevel ? {
      requiredLevel: nextEvolutionRequiredLevel,
      currentLevel: avatar.level,
      remainingPoints,
    } : null,
  }, 200);
});

// POST /avatar/points - ポイント加算
const addPointsRoute = createRoute({
  method: 'post',
  path: '/avatar/points',
  tags: ['Avatar'],
  summary: 'ポイントを加算',
  request: { body: { content: { 'application/json': { schema: AddPointsRequestSchema } } } },
  responses: {
    200: { description: '加算成功', content: { 'application/json': { schema: z.object({
      avatar: AvatarSchema,
      leveledUp: z.boolean(),
      evolved: z.boolean(),
      newSkills: z.array(SkillSchema),
    }) } } },
    401: { description: '認証エラー', content: { 'application/json': { schema: ErrorResponseSchema } } },
    404: { description: '未発見', content: { 'application/json': { schema: ErrorResponseSchema } } },
  },
});

app.openapi(addPointsRoute, async (c) => {
  const userId = getUserId(c);
  if (!userId) return c.json({ error: 'Unauthorized' }, 401);
  const body = c.req.valid('json');
  try {
    const result = await avatarService.addPoints(userId, body.points, body.categoryType, body.subCategoryId);
    return c.json(result, 200);
  } catch (e: unknown) {
    if (e instanceof Error && e.message === 'AVATAR_NOT_FOUND') {
      return c.json({ error: 'Avatar not found' }, 404);
    }
    throw e;
  }
});

// POST /avatar/points/deduct - ポイント減算
const deductPointsRoute = createRoute({
  method: 'post',
  path: '/avatar/points/deduct',
  tags: ['Avatar'],
  summary: 'ポイントを減算',
  request: { body: { content: { 'application/json': { schema: DeductPointsRequestSchema } } } },
  responses: {
    200: { description: '減算成功', content: { 'application/json': { schema: z.object({
      avatar: AvatarSchema,
      leveledDown: z.boolean(),
      devolved: z.boolean(),
      lostSkills: z.array(SkillSchema),
    }) } } },
    401: { description: '認証エラー', content: { 'application/json': { schema: ErrorResponseSchema } } },
    404: { description: '未発見', content: { 'application/json': { schema: ErrorResponseSchema } } },
  },
});

app.openapi(deductPointsRoute, async (c) => {
  const userId = getUserId(c);
  if (!userId) return c.json({ error: 'Unauthorized' }, 401);
  const body = c.req.valid('json');
  try {
    const result = await avatarService.deductPoints(userId, body.points, body.categoryType, body.subCategoryId);
    return c.json(result, 200);
  } catch (e: unknown) {
    if (e instanceof Error && e.message === 'AVATAR_NOT_FOUND') {
      return c.json({ error: 'Avatar not found' }, 404);
    }
    throw e;
  }
});

// GET /doc - OpenAPIドキュメント
app.doc('/doc', {
  openapi: '3.1.0',
  info: { title: 'ぶたそだて Avatar API', version: '1.0.0' },
});

export default app;
export const handler = handle(app);
