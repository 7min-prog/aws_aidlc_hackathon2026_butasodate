"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = void 0;
const zod_openapi_1 = require("@hono/zod-openapi");
const aws_lambda_1 = require("hono/aws-lambda");
const cors_1 = require("hono/cors");
const avatarService = __importStar(require("./services/avatar-service"));
const master_data_cache_1 = require("./services/master-data-cache");
const evolution_engine_1 = require("./services/evolution-engine");
const schemas_1 = require("./schemas");
const app = new zod_openapi_1.OpenAPIHono();
app.use('*', (0, cors_1.cors)({
    origin: '*',
    allowHeaders: ['Content-Type', 'Authorization'],
}));
// ユーザーID取得ヘルパー
function getUserId(c) {
    // Hono aws-lambda adapter: raw event is accessible via c.env.event
    const event = c.env?.event;
    if (event?.requestContext?.authorizer?.claims?.sub) {
        return event.requestContext.authorizer.claims.sub;
    }
    // Fallback for direct header (testing)
    return c.req.header('x-user-id') || null;
}
// POST /avatar - アバター作成
const createAvatarRoute = (0, zod_openapi_1.createRoute)({
    method: 'post',
    path: '/avatar',
    tags: ['Avatar'],
    summary: 'アバターを作成',
    request: { body: { content: { 'application/json': { schema: schemas_1.CreateAvatarRequestSchema } } } },
    responses: {
        201: { description: '作成成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ avatar: schemas_1.AvatarSchema }) } } },
        401: { description: '認証エラー', content: { 'application/json': { schema: schemas_1.ErrorResponseSchema } } },
        409: { description: '既に存在', content: { 'application/json': { schema: schemas_1.ErrorResponseSchema } } },
    },
});
app.openapi(createAvatarRoute, async (c) => {
    const userId = getUserId(c);
    if (!userId)
        return c.json({ error: 'Unauthorized' }, 401);
    const body = c.req.valid('json');
    try {
        const avatar = await avatarService.createAvatar(userId, body.name);
        return c.json({ avatar }, 201);
    }
    catch (e) {
        if (e instanceof Error && e.message === 'AVATAR_EXISTS') {
            return c.json({ error: 'Avatar already exists' }, 409);
        }
        throw e;
    }
});
// GET /avatar - アバター取得
const getAvatarRoute = (0, zod_openapi_1.createRoute)({
    method: 'get',
    path: '/avatar',
    tags: ['Avatar'],
    summary: 'アバター情報を取得',
    responses: {
        200: {
            description: '取得成功',
            content: { 'application/json': { schema: zod_openapi_1.z.object({
                        avatar: schemas_1.AvatarSchema,
                        skills: zod_openapi_1.z.array(schemas_1.SkillSchema),
                        evolutionPath: zod_openapi_1.z.object({ name: zod_openapi_1.z.string(), description: zod_openapi_1.z.string() }).nullable(),
                        progress: zod_openapi_1.z.object({
                            nextLevelPoints: zod_openapi_1.z.number(),
                            nextEvolutionLevel: zod_openapi_1.z.number().nullable(),
                            categoryRatio: zod_openapi_1.z.object({ food: zod_openapi_1.z.number(), lifestyle: zod_openapi_1.z.number() }),
                        }),
                    }) } },
        },
        401: { description: '認証エラー', content: { 'application/json': { schema: schemas_1.ErrorResponseSchema } } },
        404: { description: '未発見', content: { 'application/json': { schema: schemas_1.ErrorResponseSchema } } },
    },
});
app.openapi(getAvatarRoute, async (c) => {
    const userId = getUserId(c);
    if (!userId)
        return c.json({ error: 'Unauthorized' }, 401);
    const avatar = await avatarService.getAvatar(userId);
    if (!avatar)
        return c.json({ error: 'Avatar not found' }, 404);
    const [species, skills, config] = await Promise.all([(0, master_data_cache_1.getPigSpecies)(), (0, master_data_cache_1.getSkills)(), (0, master_data_cache_1.getGameConfig)()]);
    const ownedSkills = skills.filter(s => avatar.skillIds.includes(s.skillId));
    const currentSpecies = species.find(s => s.speciesId === avatar.currentSpeciesId) || null;
    const nextLevelPoints = (0, evolution_engine_1.pointsForLevel)(avatar.level + 1, config) - avatar.totalPoints;
    let nextEvolutionLevel = null;
    if (avatar.evolutionStage === 1)
        nextEvolutionLevel = config.EVOLUTION_LEVEL_STAGE2;
    else if (avatar.evolutionStage === 2)
        nextEvolutionLevel = config.EVOLUTION_LEVEL_STAGE3;
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
const getHistoryRoute = (0, zod_openapi_1.createRoute)({
    method: 'get',
    path: '/avatar/evolution-history',
    tags: ['Avatar'],
    summary: '進化履歴を取得',
    responses: {
        200: { description: '取得成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ history: zod_openapi_1.z.array(schemas_1.EvolutionHistorySchema) }) } } },
        401: { description: '認証エラー', content: { 'application/json': { schema: schemas_1.ErrorResponseSchema } } },
    },
});
app.openapi(getHistoryRoute, async (c) => {
    const userId = getUserId(c);
    if (!userId)
        return c.json({ error: 'Unauthorized' }, 401);
    const history = await avatarService.getEvolutionHistory(userId);
    return c.json({ history }, 200);
});
// GET /avatar/score-detail - スコア詳細取得
const getScoreDetailRoute = (0, zod_openapi_1.createRoute)({
    method: 'get',
    path: '/avatar/score-detail',
    tags: ['Avatar'],
    summary: 'スコア詳細を取得',
    responses: {
        200: {
            description: '取得成功',
            content: { 'application/json': { schema: zod_openapi_1.z.object({
                        totalPoints: zod_openapi_1.z.number(),
                        categoryBreakdown: zod_openapi_1.z.record(zod_openapi_1.z.string(), zod_openapi_1.z.number()),
                        categoryRatio: zod_openapi_1.z.object({ food: zod_openapi_1.z.number(), lifestyle: zod_openapi_1.z.number() }),
                        nextEvolution: zod_openapi_1.z.object({
                            requiredLevel: zod_openapi_1.z.number(),
                            currentLevel: zod_openapi_1.z.number(),
                            remainingPoints: zod_openapi_1.z.number().nullable(),
                        }).nullable(),
                    }) } },
        },
        401: { description: '認証エラー', content: { 'application/json': { schema: schemas_1.ErrorResponseSchema } } },
        404: { description: '未発見', content: { 'application/json': { schema: schemas_1.ErrorResponseSchema } } },
    },
});
app.openapi(getScoreDetailRoute, async (c) => {
    const userId = getUserId(c);
    if (!userId)
        return c.json({ error: 'Unauthorized' }, 401);
    const avatar = await avatarService.getAvatar(userId);
    if (!avatar)
        return c.json({ error: 'Avatar not found' }, 404);
    const config = await (0, master_data_cache_1.getGameConfig)();
    let nextEvolutionRequiredLevel = null;
    if (avatar.evolutionStage === 1)
        nextEvolutionRequiredLevel = config.EVOLUTION_LEVEL_STAGE2;
    else if (avatar.evolutionStage === 2)
        nextEvolutionRequiredLevel = config.EVOLUTION_LEVEL_STAGE3;
    const remainingPoints = nextEvolutionRequiredLevel
        ? Math.max(0, (0, evolution_engine_1.pointsForLevel)(nextEvolutionRequiredLevel, config) - avatar.totalPoints)
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
const addPointsRoute = (0, zod_openapi_1.createRoute)({
    method: 'post',
    path: '/avatar/points',
    tags: ['Avatar'],
    summary: 'ポイントを加算',
    request: { body: { content: { 'application/json': { schema: schemas_1.AddPointsRequestSchema } } } },
    responses: {
        200: { description: '加算成功', content: { 'application/json': { schema: zod_openapi_1.z.object({
                        avatar: schemas_1.AvatarSchema,
                        leveledUp: zod_openapi_1.z.boolean(),
                        evolved: zod_openapi_1.z.boolean(),
                        newSkills: zod_openapi_1.z.array(schemas_1.SkillSchema),
                    }) } } },
        401: { description: '認証エラー', content: { 'application/json': { schema: schemas_1.ErrorResponseSchema } } },
        404: { description: '未発見', content: { 'application/json': { schema: schemas_1.ErrorResponseSchema } } },
    },
});
app.openapi(addPointsRoute, async (c) => {
    const userId = getUserId(c);
    if (!userId)
        return c.json({ error: 'Unauthorized' }, 401);
    const body = c.req.valid('json');
    try {
        const result = await avatarService.addPoints(userId, body.points, body.categoryType, body.subCategoryId);
        return c.json(result, 200);
    }
    catch (e) {
        if (e instanceof Error && e.message === 'AVATAR_NOT_FOUND') {
            return c.json({ error: 'Avatar not found' }, 404);
        }
        throw e;
    }
});
// POST /avatar/points/deduct - ポイント減算
const deductPointsRoute = (0, zod_openapi_1.createRoute)({
    method: 'post',
    path: '/avatar/points/deduct',
    tags: ['Avatar'],
    summary: 'ポイントを減算',
    request: { body: { content: { 'application/json': { schema: schemas_1.DeductPointsRequestSchema } } } },
    responses: {
        200: { description: '減算成功', content: { 'application/json': { schema: zod_openapi_1.z.object({
                        avatar: schemas_1.AvatarSchema,
                        leveledDown: zod_openapi_1.z.boolean(),
                        devolved: zod_openapi_1.z.boolean(),
                        lostSkills: zod_openapi_1.z.array(schemas_1.SkillSchema),
                    }) } } },
        401: { description: '認証エラー', content: { 'application/json': { schema: schemas_1.ErrorResponseSchema } } },
        404: { description: '未発見', content: { 'application/json': { schema: schemas_1.ErrorResponseSchema } } },
    },
});
app.openapi(deductPointsRoute, async (c) => {
    const userId = getUserId(c);
    if (!userId)
        return c.json({ error: 'Unauthorized' }, 401);
    const body = c.req.valid('json');
    try {
        const result = await avatarService.deductPoints(userId, body.points, body.categoryType, body.subCategoryId);
        return c.json(result, 200);
    }
    catch (e) {
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
exports.default = app;
exports.handler = (0, aws_lambda_1.handle)(app);
//# sourceMappingURL=app.js.map