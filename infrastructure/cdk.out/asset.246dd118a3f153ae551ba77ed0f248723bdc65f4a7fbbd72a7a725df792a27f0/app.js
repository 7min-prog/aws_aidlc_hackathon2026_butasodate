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
const client_cognito_identity_provider_1 = require("@aws-sdk/client-cognito-identity-provider");
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const client_s3_1 = require("@aws-sdk/client-s3");
const s3_request_presigner_1 = require("@aws-sdk/s3-request-presigner");
const cognito_client_1 = require("./utils/cognito-client");
const dynamo_client_1 = require("./utils/dynamo-client");
const auth_1 = require("./utils/auth");
const audit_log_1 = require("./utils/audit-log");
const s3 = new client_s3_1.S3Client({});
const ASSETS_BUCKET = process.env.ASSETS_BUCKET_NAME;
const app = new zod_openapi_1.OpenAPIHono();
app.use('*', (0, cors_1.cors)({ origin: '*', allowHeaders: ['Content-Type', 'Authorization'] }));
app.use('/admin/*', auth_1.authMiddleware);
// --- ログイン ---
const loginRoute = (0, zod_openapi_1.createRoute)({
    method: 'post', path: '/admin/login', tags: ['Auth'], summary: 'ログイン',
    request: { body: { content: { 'application/json': { schema: zod_openapi_1.z.object({ user: zod_openapi_1.z.string(), password: zod_openapi_1.z.string() }) } } } },
    responses: {
        200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ token: zod_openapi_1.z.string() }) } } },
        401: { description: '認証失敗', content: { 'application/json': { schema: zod_openapi_1.z.object({ error: zod_openapi_1.z.string() }) } } },
    },
});
app.openapi(loginRoute, async (c) => {
    const { user, password } = c.req.valid('json');
    if (!(0, auth_1.validateBasicAuth)(user, password))
        return c.json({ error: 'Invalid credentials' }, 401);
    const token = (0, auth_1.generateToken)(user);
    return c.json({ token }, 200);
});
// --- ユーザー管理 ---
const listUsersRoute = (0, zod_openapi_1.createRoute)({
    method: 'get', path: '/admin/users', tags: ['Users'], summary: 'ユーザー一覧',
    request: { query: zod_openapi_1.z.object({ limit: zod_openapi_1.z.string().optional(), token: zod_openapi_1.z.string().optional() }) },
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ users: zod_openapi_1.z.array(zod_openapi_1.z.any()), nextToken: zod_openapi_1.z.string().nullable() }) } } } },
});
app.openapi(listUsersRoute, async (c) => {
    const { limit, token } = c.req.valid('query');
    const res = await cognito_client_1.cognitoClient.send(new client_cognito_identity_provider_1.ListUsersCommand({
        UserPoolId: cognito_client_1.USER_POOL_ID, Limit: limit ? parseInt(limit) : 20, PaginationToken: token || undefined,
    }));
    const users = (res.Users || []).map(u => ({
        username: u.Username, status: u.UserStatus, enabled: u.Enabled, created: u.UserCreateDate,
        attributes: Object.fromEntries((u.Attributes || []).map(a => [a.Name, a.Value])),
    }));
    return c.json({ users, nextToken: res.PaginationToken || null }, 200);
});
const getUserRoute = (0, zod_openapi_1.createRoute)({
    method: 'get', path: '/admin/users/{username}', tags: ['Users'], summary: 'ユーザー詳細',
    request: { params: zod_openapi_1.z.object({ username: zod_openapi_1.z.string() }) },
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.any() } } } },
});
app.openapi(getUserRoute, async (c) => {
    const { username } = c.req.valid('param');
    const [cognitoUser, avatar] = await Promise.all([
        cognito_client_1.cognitoClient.send(new client_cognito_identity_provider_1.AdminGetUserCommand({ UserPoolId: cognito_client_1.USER_POOL_ID, Username: username })),
        dynamo_client_1.docClient.send(new lib_dynamodb_1.GetCommand({ TableName: dynamo_client_1.AVATAR_TABLE, Key: { userId: username } })),
    ]);
    return c.json({
        username: cognitoUser.Username, status: cognitoUser.UserStatus, enabled: cognitoUser.Enabled,
        created: cognitoUser.UserCreateDate,
        attributes: Object.fromEntries((cognitoUser.UserAttributes || []).map(a => [a.Name, a.Value])),
        avatar: avatar.Item || null,
    }, 200);
});
const disableUserRoute = (0, zod_openapi_1.createRoute)({
    method: 'post', path: '/admin/users/{username}/disable', tags: ['Users'], summary: 'アカウント停止',
    request: { params: zod_openapi_1.z.object({ username: zod_openapi_1.z.string() }) },
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ message: zod_openapi_1.z.string() }) } } } },
});
app.openapi(disableUserRoute, async (c) => {
    const { username } = c.req.valid('param');
    await cognito_client_1.cognitoClient.send(new client_cognito_identity_provider_1.AdminDisableUserCommand({ UserPoolId: cognito_client_1.USER_POOL_ID, Username: username }));
    await (0, audit_log_1.writeAuditLog)(c.get('operator'), 'DISABLE', `user:${username}`);
    return c.json({ message: 'User disabled' }, 200);
});
const enableUserRoute = (0, zod_openapi_1.createRoute)({
    method: 'post', path: '/admin/users/{username}/enable', tags: ['Users'], summary: 'アカウント復活',
    request: { params: zod_openapi_1.z.object({ username: zod_openapi_1.z.string() }) },
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ message: zod_openapi_1.z.string() }) } } } },
});
app.openapi(enableUserRoute, async (c) => {
    const { username } = c.req.valid('param');
    await cognito_client_1.cognitoClient.send(new client_cognito_identity_provider_1.AdminEnableUserCommand({ UserPoolId: cognito_client_1.USER_POOL_ID, Username: username }));
    await (0, audit_log_1.writeAuditLog)(c.get('operator'), 'ENABLE', `user:${username}`);
    return c.json({ message: 'User enabled' }, 200);
});
const deleteUserRoute = (0, zod_openapi_1.createRoute)({
    method: 'delete', path: '/admin/users/{username}', tags: ['Users'], summary: 'ユーザー削除',
    request: { params: zod_openapi_1.z.object({ username: zod_openapi_1.z.string() }) },
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ message: zod_openapi_1.z.string() }) } } } },
});
app.openapi(deleteUserRoute, async (c) => {
    const { username } = c.req.valid('param');
    await cognito_client_1.cognitoClient.send(new client_cognito_identity_provider_1.AdminDeleteUserCommand({ UserPoolId: cognito_client_1.USER_POOL_ID, Username: username }));
    await (0, audit_log_1.writeAuditLog)(c.get('operator'), 'DELETE', `user:${username}`);
    return c.json({ message: 'User deleted' }, 200);
});
// --- アバターデータ修正 ---
const updateAvatarRoute = (0, zod_openapi_1.createRoute)({
    method: 'put', path: '/admin/users/{username}/avatar', tags: ['GameData'], summary: 'アバターデータ修正',
    request: { params: zod_openapi_1.z.object({ username: zod_openapi_1.z.string() }), body: { content: { 'application/json': { schema: zod_openapi_1.z.any() } } } },
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ message: zod_openapi_1.z.string() }) } } } },
});
app.openapi(updateAvatarRoute, async (c) => {
    const { username } = c.req.valid('param');
    const body = await c.req.json();
    await dynamo_client_1.docClient.send(new lib_dynamodb_1.PutCommand({ TableName: dynamo_client_1.AVATAR_TABLE, Item: { ...body, userId: username } }));
    await (0, audit_log_1.writeAuditLog)(c.get('operator'), 'UPDATE', `avatar:${username}`, body);
    return c.json({ message: 'Avatar updated' }, 200);
});
// --- プロフィール+ゲームデータ修正 (OpenAPI準拠) ---
const updateProfileRoute = (0, zod_openapi_1.createRoute)({
    method: 'put', path: '/admin/users/{username}/profile', tags: ['GameData'], summary: 'アバター情報更新',
    request: { params: zod_openapi_1.z.object({ username: zod_openapi_1.z.string() }), body: { content: { 'application/json': { schema: zod_openapi_1.z.object({
                        nickname: zod_openapi_1.z.string().optional(), email: zod_openapi_1.z.string().optional(),
                        totalPoints: zod_openapi_1.z.number().optional(), level: zod_openapi_1.z.number().optional(),
                        evolutionStage: zod_openapi_1.z.number().optional(), evolutionPathId: zod_openapi_1.z.string().optional(),
                    }) } } } },
    responses: {
        200: { description: '更新成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ message: zod_openapi_1.z.string() }) } } },
        404: { description: '未発見', content: { 'application/json': { schema: zod_openapi_1.z.object({ error: zod_openapi_1.z.string() }) } } },
    },
});
app.openapi(updateProfileRoute, async (c) => {
    const { username } = c.req.valid('param');
    const body = c.req.valid('json');
    // Update avatar game data if provided
    const gameFields = {};
    if (body.totalPoints !== undefined)
        gameFields.totalPoints = body.totalPoints;
    if (body.level !== undefined)
        gameFields.level = body.level;
    if (body.evolutionStage !== undefined)
        gameFields.evolutionStage = body.evolutionStage;
    if (body.evolutionPathId !== undefined)
        gameFields.currentSpeciesId = body.evolutionPathId;
    if (Object.keys(gameFields).length > 0) {
        const existing = await dynamo_client_1.docClient.send(new lib_dynamodb_1.GetCommand({ TableName: dynamo_client_1.AVATAR_TABLE, Key: { userId: username } }));
        if (!existing.Item)
            return c.json({ error: 'Avatar not found' }, 404);
        await dynamo_client_1.docClient.send(new lib_dynamodb_1.PutCommand({ TableName: dynamo_client_1.AVATAR_TABLE, Item: { ...existing.Item, ...gameFields, updatedAt: new Date().toISOString() } }));
    }
    // Update profile (nickname/email) in user-profiles table
    if (body.nickname || body.email) {
        const { UpdateCommand } = await Promise.resolve().then(() => __importStar(require('@aws-sdk/lib-dynamodb')));
        const exprs = [];
        const values = {};
        if (body.nickname) {
            exprs.push('nickname = :n');
            values[':n'] = body.nickname;
        }
        if (body.email) {
            exprs.push('email = :e');
            values[':e'] = body.email;
        }
        exprs.push('updatedAt = :now');
        values[':now'] = new Date().toISOString();
        await dynamo_client_1.docClient.send(new UpdateCommand({
            TableName: dynamo_client_1.USER_PROFILES_TABLE, Key: { userId: username },
            UpdateExpression: `SET ${exprs.join(', ')}`, ExpressionAttributeValues: values,
        }));
    }
    await (0, audit_log_1.writeAuditLog)(c.get('operator'), 'UPDATE', `profile:${username}`, body);
    return c.json({ message: 'Profile updated' }, 200);
});
// --- ヘルスデータ手動入力 ---
const healthDataRoute = (0, zod_openapi_1.createRoute)({
    method: 'post', path: '/admin/users/{username}/health-data', tags: ['GameData'], summary: 'ヘルスデータ手動入力',
    request: {
        params: zod_openapi_1.z.object({ username: zod_openapi_1.z.string() }),
        body: { content: { 'application/json': { schema: zod_openapi_1.z.object({
                        weight: zod_openapi_1.z.number().optional(), bmi: zod_openapi_1.z.number().optional(),
                        steps: zod_openapi_1.z.number().optional(), sleepHours: zod_openapi_1.z.number().optional(),
                        date: zod_openapi_1.z.string(),
                    }) } } },
    },
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ message: zod_openapi_1.z.string() }) } } } },
});
app.openapi(healthDataRoute, async (c) => {
    const { username } = c.req.valid('param');
    const body = c.req.valid('json');
    await dynamo_client_1.docClient.send(new lib_dynamodb_1.PutCommand({
        TableName: dynamo_client_1.ACTIVITY_RECORD_TABLE,
        Item: { userId: username, recordedAt: body.date, type: 'HEALTH_MANUAL', data: body, source: 'admin' },
    }));
    await (0, audit_log_1.writeAuditLog)(c.get('operator'), 'CREATE', `health-data:${username}`, body);
    return c.json({ message: 'Health data recorded' }, 200);
});
// --- マスターデータ: 進化パス ---
const listPathsRoute = (0, zod_openapi_1.createRoute)({
    method: 'get', path: '/admin/evolution-paths', tags: ['MasterData'], summary: '進化パス一覧',
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ paths: zod_openapi_1.z.array(zod_openapi_1.z.any()) }) } } } },
});
app.openapi(listPathsRoute, async (c) => {
    const res = await dynamo_client_1.docClient.send(new lib_dynamodb_1.ScanCommand({ TableName: dynamo_client_1.PIG_SPECIES_TABLE }));
    return c.json({ paths: res.Items || [] }, 200);
});
const createPathRoute = (0, zod_openapi_1.createRoute)({
    method: 'post', path: '/admin/evolution-paths', tags: ['MasterData'], summary: '進化パス新規登録',
    request: { body: { content: { 'application/json': { schema: zod_openapi_1.z.any() } } } },
    responses: { 201: { description: '作成成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ message: zod_openapi_1.z.string() }) } } } },
});
app.openapi(createPathRoute, async (c) => {
    const body = await c.req.json();
    await dynamo_client_1.docClient.send(new lib_dynamodb_1.PutCommand({ TableName: dynamo_client_1.PIG_SPECIES_TABLE, Item: body }));
    await (0, audit_log_1.writeAuditLog)(c.get('operator'), 'CREATE', `pig-species:${body.speciesId}`, body);
    return c.json({ message: 'Species created' }, 201);
});
const updatePathRoute = (0, zod_openapi_1.createRoute)({
    method: 'put', path: '/admin/evolution-paths/{pathId}', tags: ['MasterData'], summary: '進化パス更新',
    request: { params: zod_openapi_1.z.object({ pathId: zod_openapi_1.z.string() }), body: { content: { 'application/json': { schema: zod_openapi_1.z.any() } } } },
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ message: zod_openapi_1.z.string() }) } } } },
});
app.openapi(updatePathRoute, async (c) => {
    const { pathId } = c.req.valid('param');
    const body = await c.req.json();
    await dynamo_client_1.docClient.send(new lib_dynamodb_1.PutCommand({ TableName: dynamo_client_1.PIG_SPECIES_TABLE, Item: { ...body, speciesId: pathId } }));
    await (0, audit_log_1.writeAuditLog)(c.get('operator'), 'UPDATE', `pig-species:${pathId}`, body);
    return c.json({ message: 'Species updated' }, 200);
});
const deletePathRoute = (0, zod_openapi_1.createRoute)({
    method: 'delete', path: '/admin/evolution-paths/{pathId}', tags: ['MasterData'], summary: '進化パス削除',
    request: { params: zod_openapi_1.z.object({ pathId: zod_openapi_1.z.string() }) },
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ message: zod_openapi_1.z.string() }) } } } },
});
app.openapi(deletePathRoute, async (c) => {
    const { pathId } = c.req.valid('param');
    await dynamo_client_1.docClient.send(new lib_dynamodb_1.DeleteCommand({ TableName: dynamo_client_1.PIG_SPECIES_TABLE, Key: { speciesId: pathId } }));
    await (0, audit_log_1.writeAuditLog)(c.get('operator'), 'DELETE', `pig-species:${pathId}`);
    return c.json({ message: 'Species deleted' }, 200);
});
// --- マスターデータ: 進化ルート ---
const listRoutesRoute = (0, zod_openapi_1.createRoute)({
    method: 'get', path: '/admin/evolution-routes', tags: ['MasterData'], summary: '進化ルート一覧',
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ routes: zod_openapi_1.z.array(zod_openapi_1.z.any()) }) } } } },
});
app.openapi(listRoutesRoute, async (c) => {
    const res = await dynamo_client_1.docClient.send(new lib_dynamodb_1.ScanCommand({ TableName: dynamo_client_1.EVOLUTION_ROUTE_TABLE }));
    return c.json({ routes: res.Items || [] }, 200);
});
const createRouteRoute = (0, zod_openapi_1.createRoute)({
    method: 'post', path: '/admin/evolution-routes', tags: ['MasterData'], summary: '進化ルート作成',
    request: { body: { content: { 'application/json': { schema: zod_openapi_1.z.any() } } } },
    responses: { 201: { description: '作成成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ message: zod_openapi_1.z.string() }) } } } },
});
app.openapi(createRouteRoute, async (c) => {
    const body = await c.req.json();
    await dynamo_client_1.docClient.send(new lib_dynamodb_1.PutCommand({ TableName: dynamo_client_1.EVOLUTION_ROUTE_TABLE, Item: body }));
    await (0, audit_log_1.writeAuditLog)(c.get('operator'), 'CREATE', `evolution-route:${body.routeId}`, body);
    return c.json({ message: 'Route created' }, 201);
});
const updateRouteRoute = (0, zod_openapi_1.createRoute)({
    method: 'put', path: '/admin/evolution-routes/{routeId}', tags: ['MasterData'], summary: '進化ルート更新',
    request: { params: zod_openapi_1.z.object({ routeId: zod_openapi_1.z.string() }), body: { content: { 'application/json': { schema: zod_openapi_1.z.any() } } } },
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ message: zod_openapi_1.z.string() }) } } } },
});
app.openapi(updateRouteRoute, async (c) => {
    const { routeId } = c.req.valid('param');
    const body = await c.req.json();
    await dynamo_client_1.docClient.send(new lib_dynamodb_1.PutCommand({ TableName: dynamo_client_1.EVOLUTION_ROUTE_TABLE, Item: { ...body, routeId } }));
    await (0, audit_log_1.writeAuditLog)(c.get('operator'), 'UPDATE', `evolution-route:${routeId}`, body);
    return c.json({ message: 'Route updated' }, 200);
});
const deleteRouteRoute = (0, zod_openapi_1.createRoute)({
    method: 'delete', path: '/admin/evolution-routes/{routeId}', tags: ['MasterData'], summary: '進化ルート削除',
    request: { params: zod_openapi_1.z.object({ routeId: zod_openapi_1.z.string() }) },
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ message: zod_openapi_1.z.string() }) } } } },
});
app.openapi(deleteRouteRoute, async (c) => {
    const { routeId } = c.req.valid('param');
    await dynamo_client_1.docClient.send(new lib_dynamodb_1.DeleteCommand({ TableName: dynamo_client_1.EVOLUTION_ROUTE_TABLE, Key: { routeId } }));
    await (0, audit_log_1.writeAuditLog)(c.get('operator'), 'DELETE', `evolution-route:${routeId}`);
    return c.json({ message: 'Route deleted' }, 200);
});
// --- マスターデータ: スキル ---
const listSkillsRoute = (0, zod_openapi_1.createRoute)({
    method: 'get', path: '/admin/skills', tags: ['MasterData'], summary: 'スキル一覧',
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ skills: zod_openapi_1.z.array(zod_openapi_1.z.any()) }) } } } },
});
app.openapi(listSkillsRoute, async (c) => {
    const res = await dynamo_client_1.docClient.send(new lib_dynamodb_1.ScanCommand({ TableName: dynamo_client_1.SKILL_TABLE }));
    return c.json({ skills: res.Items || [] }, 200);
});
const createSkillRoute = (0, zod_openapi_1.createRoute)({
    method: 'post', path: '/admin/skills', tags: ['MasterData'], summary: 'スキル新規登録',
    request: { body: { content: { 'application/json': { schema: zod_openapi_1.z.any() } } } },
    responses: { 201: { description: '作成成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ message: zod_openapi_1.z.string() }) } } } },
});
app.openapi(createSkillRoute, async (c) => {
    const body = await c.req.json();
    await dynamo_client_1.docClient.send(new lib_dynamodb_1.PutCommand({ TableName: dynamo_client_1.SKILL_TABLE, Item: body }));
    await (0, audit_log_1.writeAuditLog)(c.get('operator'), 'CREATE', `skill:${body.skillId}`, body);
    return c.json({ message: 'Skill created' }, 201);
});
const updateSkillRoute = (0, zod_openapi_1.createRoute)({
    method: 'put', path: '/admin/skills/{skillId}', tags: ['MasterData'], summary: 'スキル更新',
    request: { params: zod_openapi_1.z.object({ skillId: zod_openapi_1.z.string() }), body: { content: { 'application/json': { schema: zod_openapi_1.z.any() } } } },
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ message: zod_openapi_1.z.string() }) } } } },
});
app.openapi(updateSkillRoute, async (c) => {
    const { skillId } = c.req.valid('param');
    const body = await c.req.json();
    await dynamo_client_1.docClient.send(new lib_dynamodb_1.PutCommand({ TableName: dynamo_client_1.SKILL_TABLE, Item: { ...body, skillId } }));
    await (0, audit_log_1.writeAuditLog)(c.get('operator'), 'UPDATE', `skill:${skillId}`, body);
    return c.json({ message: 'Skill updated' }, 200);
});
const deleteSkillRoute = (0, zod_openapi_1.createRoute)({
    method: 'delete', path: '/admin/skills/{skillId}', tags: ['MasterData'], summary: 'スキル削除',
    request: { params: zod_openapi_1.z.object({ skillId: zod_openapi_1.z.string() }) },
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ message: zod_openapi_1.z.string() }) } } } },
});
app.openapi(deleteSkillRoute, async (c) => {
    const { skillId } = c.req.valid('param');
    await dynamo_client_1.docClient.send(new lib_dynamodb_1.DeleteCommand({ TableName: dynamo_client_1.SKILL_TABLE, Key: { skillId } }));
    await (0, audit_log_1.writeAuditLog)(c.get('operator'), 'DELETE', `skill:${skillId}`);
    return c.json({ message: 'Skill deleted' }, 200);
});
// --- ゲーム設定 ---
const getConfigRoute = (0, zod_openapi_1.createRoute)({
    method: 'get', path: '/admin/game-config', tags: ['Config'], summary: 'ゲーム設定取得',
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ config: zod_openapi_1.z.array(zod_openapi_1.z.any()) }) } } } },
});
app.openapi(getConfigRoute, async (c) => {
    const res = await dynamo_client_1.docClient.send(new lib_dynamodb_1.ScanCommand({ TableName: dynamo_client_1.GAME_CONFIG_TABLE }));
    return c.json({ config: res.Items || [] }, 200);
});
const updateConfigRoute = (0, zod_openapi_1.createRoute)({
    method: 'put', path: '/admin/game-config', tags: ['Config'], summary: 'ゲーム設定更新',
    request: { body: { content: { 'application/json': { schema: zod_openapi_1.z.object({ configKey: zod_openapi_1.z.string(), value: zod_openapi_1.z.any() }) } } } },
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ message: zod_openapi_1.z.string() }) } } } },
});
app.openapi(updateConfigRoute, async (c) => {
    const { configKey, value } = c.req.valid('json');
    await dynamo_client_1.docClient.send(new lib_dynamodb_1.PutCommand({
        TableName: dynamo_client_1.GAME_CONFIG_TABLE,
        Item: { configKey, value, updatedAt: new Date().toISOString(), updatedBy: c.get('operator') },
    }));
    await (0, audit_log_1.writeAuditLog)(c.get('operator'), 'UPDATE', `game-config:${configKey}`, { value });
    return c.json({ message: 'Config updated' }, 200);
});
// --- 操作ログ ---
const getAuditLogRoute = (0, zod_openapi_1.createRoute)({
    method: 'get', path: '/admin/audit-log', tags: ['AuditLog'], summary: '操作ログ一覧',
    request: { query: zod_openapi_1.z.object({ limit: zod_openapi_1.z.string().optional() }) },
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ logs: zod_openapi_1.z.array(zod_openapi_1.z.any()) }) } } } },
});
app.openapi(getAuditLogRoute, async (c) => {
    const { limit } = c.req.valid('query');
    const res = await dynamo_client_1.docClient.send(new lib_dynamodb_1.ScanCommand({ TableName: dynamo_client_1.AUDIT_LOG_TABLE, Limit: limit ? parseInt(limit) : 50 }));
    const logs = (res.Items || []).sort((a, b) => b.timestamp.localeCompare(a.timestamp));
    return c.json({ logs }, 200);
});
// --- ファイルアップロード ---
const uploadUrlRoute = (0, zod_openapi_1.createRoute)({
    method: 'post', path: '/admin/upload-url', tags: ['Upload'], summary: 'S3 Presigned URL発行',
    request: { body: { content: { 'application/json': { schema: zod_openapi_1.z.object({ fileName: zod_openapi_1.z.string(), contentType: zod_openapi_1.z.string() }) } } } },
    responses: { 200: { description: '成功', content: { 'application/json': { schema: zod_openapi_1.z.object({ uploadUrl: zod_openapi_1.z.string(), key: zod_openapi_1.z.string() }) } } } },
});
app.openapi(uploadUrlRoute, async (c) => {
    const { fileName, contentType } = c.req.valid('json');
    const key = `assets/sprites/${Date.now()}-${fileName}`;
    const command = new client_s3_1.PutObjectCommand({ Bucket: ASSETS_BUCKET, Key: key, ContentType: contentType });
    const uploadUrl = await (0, s3_request_presigner_1.getSignedUrl)(s3, command, { expiresIn: 300 });
    return c.json({ uploadUrl, key }, 200);
});
// --- OpenAPI doc ---
app.doc('/admin/doc', { openapi: '3.1.0', info: { title: 'ぶたそだて Admin API', version: '1.0.0' } });
exports.default = app;
exports.handler = (0, aws_lambda_1.handle)(app);
//# sourceMappingURL=app.js.map