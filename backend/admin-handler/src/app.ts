import { OpenAPIHono, createRoute, z } from '@hono/zod-openapi';
import { handle } from 'hono/aws-lambda';
import { cors } from 'hono/cors';

type Env = { Variables: { operator: string } };

import {
  AdminDisableUserCommand, AdminEnableUserCommand,
  AdminDeleteUserCommand, ListUsersCommand, AdminGetUserCommand,
} from '@aws-sdk/client-cognito-identity-provider';
import { ScanCommand, GetCommand, PutCommand, DeleteCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { cognitoClient, USER_POOL_ID } from './utils/cognito-client';
import { docClient, AVATAR_TABLE, EVOLUTION_PATH_TABLE, SKILL_TABLE, AUDIT_LOG_TABLE, GAME_CONFIG_TABLE, RECORDING_TABLE } from './utils/dynamo-client';
import { authMiddleware, validateBasicAuth, generateToken } from './utils/auth';
import { writeAuditLog } from './utils/audit-log';

const s3 = new S3Client({});
const ASSETS_BUCKET = process.env.ASSETS_BUCKET_NAME!;

const app = new OpenAPIHono<Env>();
app.use('*', cors({ origin: '*', allowHeaders: ['Content-Type', 'Authorization'] }));
app.use('/admin/*', authMiddleware);

// --- ログイン ---
const loginRoute = createRoute({
  method: 'post', path: '/admin/login', tags: ['Auth'], summary: 'ログイン',
  request: { body: { content: { 'application/json': { schema: z.object({ user: z.string(), password: z.string() }) } } } },
  responses: {
    200: { description: '成功', content: { 'application/json': { schema: z.object({ token: z.string() }) } } },
    401: { description: '認証失敗', content: { 'application/json': { schema: z.object({ error: z.string() }) } } },
  },
});
app.openapi(loginRoute, async (c) => {
  const { user, password } = c.req.valid('json');
  if (!validateBasicAuth(user, password)) return c.json({ error: 'Invalid credentials' }, 401);
  const token = generateToken(user);
  return c.json({ token }, 200);
});

// --- ユーザー管理 ---
const listUsersRoute = createRoute({
  method: 'get', path: '/admin/users', tags: ['Users'], summary: 'ユーザー一覧',
  request: { query: z.object({ limit: z.string().optional(), token: z.string().optional() }) },
  responses: { 200: { description: '成功', content: { 'application/json': { schema: z.object({ users: z.array(z.any()), nextToken: z.string().nullable() }) } } } },
});
app.openapi(listUsersRoute, async (c) => {
  const { limit, token } = c.req.valid('query');
  const res = await cognitoClient.send(new ListUsersCommand({
    UserPoolId: USER_POOL_ID, Limit: limit ? parseInt(limit) : 20, PaginationToken: token || undefined,
  }));
  const users = (res.Users || []).map(u => ({
    username: u.Username, status: u.UserStatus, enabled: u.Enabled, created: u.UserCreateDate,
    attributes: Object.fromEntries((u.Attributes || []).map(a => [a.Name, a.Value])),
  }));
  return c.json({ users, nextToken: res.PaginationToken || null }, 200);
});

const getUserRoute = createRoute({
  method: 'get', path: '/admin/users/{username}', tags: ['Users'], summary: 'ユーザー詳細',
  request: { params: z.object({ username: z.string() }) },
  responses: { 200: { description: '成功', content: { 'application/json': { schema: z.any() } } } },
});
app.openapi(getUserRoute, async (c) => {
  const { username } = c.req.valid('param');
  const [cognitoUser, avatar] = await Promise.all([
    cognitoClient.send(new AdminGetUserCommand({ UserPoolId: USER_POOL_ID, Username: username })),
    docClient.send(new GetCommand({ TableName: AVATAR_TABLE, Key: { userId: username } })),
  ]);
  return c.json({
    username: cognitoUser.Username, status: cognitoUser.UserStatus, enabled: cognitoUser.Enabled,
    created: cognitoUser.UserCreateDate,
    attributes: Object.fromEntries((cognitoUser.UserAttributes || []).map(a => [a.Name, a.Value])),
    avatar: avatar.Item || null,
  }, 200);
});

const disableUserRoute = createRoute({
  method: 'post', path: '/admin/users/{username}/disable', tags: ['Users'], summary: 'アカウント停止',
  request: { params: z.object({ username: z.string() }) },
  responses: { 200: { description: '成功', content: { 'application/json': { schema: z.object({ message: z.string() }) } } } },
});
app.openapi(disableUserRoute, async (c) => {
  const { username } = c.req.valid('param');
  await cognitoClient.send(new AdminDisableUserCommand({ UserPoolId: USER_POOL_ID, Username: username }));
  await writeAuditLog(c.get('operator'), 'DISABLE', `user:${username}`);
  return c.json({ message: 'User disabled' }, 200);
});

const enableUserRoute = createRoute({
  method: 'post', path: '/admin/users/{username}/enable', tags: ['Users'], summary: 'アカウント復活',
  request: { params: z.object({ username: z.string() }) },
  responses: { 200: { description: '成功', content: { 'application/json': { schema: z.object({ message: z.string() }) } } } },
});
app.openapi(enableUserRoute, async (c) => {
  const { username } = c.req.valid('param');
  await cognitoClient.send(new AdminEnableUserCommand({ UserPoolId: USER_POOL_ID, Username: username }));
  await writeAuditLog(c.get('operator'), 'ENABLE', `user:${username}`);
  return c.json({ message: 'User enabled' }, 200);
});

const deleteUserRoute = createRoute({
  method: 'delete', path: '/admin/users/{username}', tags: ['Users'], summary: 'ユーザー削除',
  request: { params: z.object({ username: z.string() }) },
  responses: { 200: { description: '成功', content: { 'application/json': { schema: z.object({ message: z.string() }) } } } },
});
app.openapi(deleteUserRoute, async (c) => {
  const { username } = c.req.valid('param');
  await cognitoClient.send(new AdminDeleteUserCommand({ UserPoolId: USER_POOL_ID, Username: username }));
  await writeAuditLog(c.get('operator'), 'DELETE', `user:${username}`);
  return c.json({ message: 'User deleted' }, 200);
});

// --- アバターデータ修正 ---
const updateAvatarRoute = createRoute({
  method: 'put', path: '/admin/users/{username}/avatar', tags: ['GameData'], summary: 'アバターデータ修正',
  request: { params: z.object({ username: z.string() }), body: { content: { 'application/json': { schema: z.any() } } } },
  responses: { 200: { description: '成功', content: { 'application/json': { schema: z.object({ message: z.string() }) } } } },
});
app.openapi(updateAvatarRoute, async (c) => {
  const { username } = c.req.valid('param');
  const body = await c.req.json();
  await docClient.send(new PutCommand({ TableName: AVATAR_TABLE, Item: { ...body, userId: username } }));
  await writeAuditLog(c.get('operator'), 'UPDATE', `avatar:${username}`, body);
  return c.json({ message: 'Avatar updated' }, 200);
});

// --- ヘルスデータ手動入力 ---
const healthDataRoute = createRoute({
  method: 'post', path: '/admin/users/{username}/health-data', tags: ['GameData'], summary: 'ヘルスデータ手動入力',
  request: {
    params: z.object({ username: z.string() }),
    body: { content: { 'application/json': { schema: z.object({
      weight: z.number().optional(), bmi: z.number().optional(),
      steps: z.number().optional(), sleepHours: z.number().optional(),
      date: z.string(),
    }) } } },
  },
  responses: { 200: { description: '成功', content: { 'application/json': { schema: z.object({ message: z.string() }) } } } },
});
app.openapi(healthDataRoute, async (c) => {
  const { username } = c.req.valid('param');
  const body = c.req.valid('json');
  await docClient.send(new PutCommand({
    TableName: RECORDING_TABLE,
    Item: { userId: username, recordedAt: body.date, type: 'HEALTH_MANUAL', data: body, source: 'admin' },
  }));
  await writeAuditLog(c.get('operator'), 'CREATE', `health-data:${username}`, body);
  return c.json({ message: 'Health data recorded' }, 200);
});

// --- マスターデータ: 進化パス ---
const listPathsRoute = createRoute({
  method: 'get', path: '/admin/evolution-paths', tags: ['MasterData'], summary: '進化パス一覧',
  responses: { 200: { description: '成功', content: { 'application/json': { schema: z.object({ paths: z.array(z.any()) }) } } } },
});
app.openapi(listPathsRoute, async (c) => {
  const res = await docClient.send(new ScanCommand({ TableName: EVOLUTION_PATH_TABLE }));
  return c.json({ paths: res.Items || [] }, 200);
});

const createPathRoute = createRoute({
  method: 'post', path: '/admin/evolution-paths', tags: ['MasterData'], summary: '進化パス新規登録',
  request: { body: { content: { 'application/json': { schema: z.any() } } } },
  responses: { 201: { description: '作成成功', content: { 'application/json': { schema: z.object({ message: z.string() }) } } } },
});
app.openapi(createPathRoute, async (c) => {
  const body = await c.req.json();
  await docClient.send(new PutCommand({ TableName: EVOLUTION_PATH_TABLE, Item: body }));
  await writeAuditLog(c.get('operator'), 'CREATE', `evolution-path:${body.pathId}`, body);
  return c.json({ message: 'Path created' }, 201);
});

const updatePathRoute = createRoute({
  method: 'put', path: '/admin/evolution-paths/{pathId}', tags: ['MasterData'], summary: '進化パス更新',
  request: { params: z.object({ pathId: z.string() }), body: { content: { 'application/json': { schema: z.any() } } } },
  responses: { 200: { description: '成功', content: { 'application/json': { schema: z.object({ message: z.string() }) } } } },
});
app.openapi(updatePathRoute, async (c) => {
  const { pathId } = c.req.valid('param');
  const body = await c.req.json();
  await docClient.send(new PutCommand({ TableName: EVOLUTION_PATH_TABLE, Item: { ...body, pathId } }));
  await writeAuditLog(c.get('operator'), 'UPDATE', `evolution-path:${pathId}`, body);
  return c.json({ message: 'Path updated' }, 200);
});

const deletePathRoute = createRoute({
  method: 'delete', path: '/admin/evolution-paths/{pathId}', tags: ['MasterData'], summary: '進化パス削除',
  request: { params: z.object({ pathId: z.string() }) },
  responses: { 200: { description: '成功', content: { 'application/json': { schema: z.object({ message: z.string() }) } } } },
});
app.openapi(deletePathRoute, async (c) => {
  const { pathId } = c.req.valid('param');
  await docClient.send(new DeleteCommand({ TableName: EVOLUTION_PATH_TABLE, Key: { pathId } }));
  await writeAuditLog(c.get('operator'), 'DELETE', `evolution-path:${pathId}`);
  return c.json({ message: 'Path deleted' }, 200);
});

// --- マスターデータ: スキル ---
const listSkillsRoute = createRoute({
  method: 'get', path: '/admin/skills', tags: ['MasterData'], summary: 'スキル一覧',
  responses: { 200: { description: '成功', content: { 'application/json': { schema: z.object({ skills: z.array(z.any()) }) } } } },
});
app.openapi(listSkillsRoute, async (c) => {
  const res = await docClient.send(new ScanCommand({ TableName: SKILL_TABLE }));
  return c.json({ skills: res.Items || [] }, 200);
});

const createSkillRoute = createRoute({
  method: 'post', path: '/admin/skills', tags: ['MasterData'], summary: 'スキル新規登録',
  request: { body: { content: { 'application/json': { schema: z.any() } } } },
  responses: { 201: { description: '作成成功', content: { 'application/json': { schema: z.object({ message: z.string() }) } } } },
});
app.openapi(createSkillRoute, async (c) => {
  const body = await c.req.json();
  await docClient.send(new PutCommand({ TableName: SKILL_TABLE, Item: body }));
  await writeAuditLog(c.get('operator'), 'CREATE', `skill:${body.skillId}`, body);
  return c.json({ message: 'Skill created' }, 201);
});

const updateSkillRoute = createRoute({
  method: 'put', path: '/admin/skills/{skillId}', tags: ['MasterData'], summary: 'スキル更新',
  request: { params: z.object({ skillId: z.string() }), body: { content: { 'application/json': { schema: z.any() } } } },
  responses: { 200: { description: '成功', content: { 'application/json': { schema: z.object({ message: z.string() }) } } } },
});
app.openapi(updateSkillRoute, async (c) => {
  const { skillId } = c.req.valid('param');
  const body = await c.req.json();
  await docClient.send(new PutCommand({ TableName: SKILL_TABLE, Item: { ...body, skillId } }));
  await writeAuditLog(c.get('operator'), 'UPDATE', `skill:${skillId}`, body);
  return c.json({ message: 'Skill updated' }, 200);
});

const deleteSkillRoute = createRoute({
  method: 'delete', path: '/admin/skills/{skillId}', tags: ['MasterData'], summary: 'スキル削除',
  request: { params: z.object({ skillId: z.string() }) },
  responses: { 200: { description: '成功', content: { 'application/json': { schema: z.object({ message: z.string() }) } } } },
});
app.openapi(deleteSkillRoute, async (c) => {
  const { skillId } = c.req.valid('param');
  await docClient.send(new DeleteCommand({ TableName: SKILL_TABLE, Key: { skillId } }));
  await writeAuditLog(c.get('operator'), 'DELETE', `skill:${skillId}`);
  return c.json({ message: 'Skill deleted' }, 200);
});

// --- ゲーム設定 ---
const getConfigRoute = createRoute({
  method: 'get', path: '/admin/game-config', tags: ['Config'], summary: 'ゲーム設定取得',
  responses: { 200: { description: '成功', content: { 'application/json': { schema: z.object({ config: z.array(z.any()) }) } } } },
});
app.openapi(getConfigRoute, async (c) => {
  const res = await docClient.send(new ScanCommand({ TableName: GAME_CONFIG_TABLE }));
  return c.json({ config: res.Items || [] }, 200);
});

const updateConfigRoute = createRoute({
  method: 'put', path: '/admin/game-config', tags: ['Config'], summary: 'ゲーム設定更新',
  request: { body: { content: { 'application/json': { schema: z.object({ configKey: z.string(), value: z.any() }) } } } },
  responses: { 200: { description: '成功', content: { 'application/json': { schema: z.object({ message: z.string() }) } } } },
});
app.openapi(updateConfigRoute, async (c) => {
  const { configKey, value } = c.req.valid('json');
  await docClient.send(new PutCommand({
    TableName: GAME_CONFIG_TABLE,
    Item: { configKey, value, updatedAt: new Date().toISOString(), updatedBy: c.get('operator') },
  }));
  await writeAuditLog(c.get('operator'), 'UPDATE', `game-config:${configKey}`, { value });
  return c.json({ message: 'Config updated' }, 200);
});

// --- 操作ログ ---
const getAuditLogRoute = createRoute({
  method: 'get', path: '/admin/audit-log', tags: ['AuditLog'], summary: '操作ログ一覧',
  request: { query: z.object({ limit: z.string().optional() }) },
  responses: { 200: { description: '成功', content: { 'application/json': { schema: z.object({ logs: z.array(z.any()) }) } } } },
});
app.openapi(getAuditLogRoute, async (c) => {
  const { limit } = c.req.valid('query');
  const res = await docClient.send(new ScanCommand({ TableName: AUDIT_LOG_TABLE, Limit: limit ? parseInt(limit) : 50 }));
  const logs = (res.Items || []).sort((a, b) => (b.timestamp as string).localeCompare(a.timestamp as string));
  return c.json({ logs }, 200);
});

// --- ファイルアップロード ---
const uploadUrlRoute = createRoute({
  method: 'post', path: '/admin/upload-url', tags: ['Upload'], summary: 'S3 Presigned URL発行',
  request: { body: { content: { 'application/json': { schema: z.object({ fileName: z.string(), contentType: z.string() }) } } } },
  responses: { 200: { description: '成功', content: { 'application/json': { schema: z.object({ uploadUrl: z.string(), key: z.string() }) } } } },
});
app.openapi(uploadUrlRoute, async (c) => {
  const { fileName, contentType } = c.req.valid('json');
  const key = `assets/sprites/${Date.now()}-${fileName}`;
  const command = new PutObjectCommand({ Bucket: ASSETS_BUCKET, Key: key, ContentType: contentType });
  const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 300 });
  return c.json({ uploadUrl, key }, 200);
});

// --- OpenAPI doc ---
app.doc('/admin/doc', { openapi: '3.1.0', info: { title: 'ぶたそだて Admin API', version: '1.0.0' } });

export default app;
export const handler = handle(app);
