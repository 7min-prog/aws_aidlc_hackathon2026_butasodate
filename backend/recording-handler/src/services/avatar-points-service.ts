import { DynamoDBDocumentClient, GetCommand, PutCommand, QueryCommand, ScanCommand } from '@aws-sdk/lib-dynamodb';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { randomUUID } from 'crypto';

const client = DynamoDBDocumentClient.from(new DynamoDBClient({}), { marshallOptions: { removeUndefinedValues: true } });

const AVATAR_TABLE = process.env.AVATAR_TABLE_NAME!;
const EVOLUTION_HISTORY_TABLE = process.env.EVOLUTION_HISTORY_TABLE_NAME!;
const PIG_SPECIES_TABLE = process.env.PIG_SPECIES_TABLE_NAME!;
const EVOLUTION_ROUTE_TABLE = process.env.EVOLUTION_ROUTE_TABLE_NAME!;
const SKILL_TABLE = process.env.SKILL_TABLE_NAME!;
const GAME_CONFIG_TABLE = process.env.GAME_CONFIG_TABLE_NAME!;

// --- Types ---
interface AvatarStats { hp: number; attack: number; defense: number; speed: number; }
interface Avatar { userId: string; avatarId: string; name: string; totalPoints: number; level: number; evolutionStage: number; currentSpeciesId: string | null; categoryPoints: Record<string, number>; subCategoryPoints: Record<string, number>; stats: AvatarStats; skillIds: string[]; createdAt: string; updatedAt: string; }
interface PigSpecies { speciesId: string; name: string; stage: number; dominantCategory: string; statsGrowth: AvatarStats; spriteSheetKey: string; }
interface EvolutionRoute { routeId: string; fromSpeciesId: string; toSpeciesId: string; requiredLevel: number; categoryThreshold: number; conditionCategory: string; subCategoryIds: string[] | null; subCategoryThreshold: number | null; priority: number; }
interface Skill { skillId: string; speciesId: string; requiredLevel: number; }
interface GameConfig { INITIAL_STATS: AvatarStats; MAX_LEVEL: number; EVOLUTION_LEVEL_STAGE2: number; EVOLUTION_LEVEL_STAGE3: number; CATEGORY_THRESHOLD: number; LEVEL_FORMULA_COEFFICIENT: number; }

// --- Cache ---
let cachedSpecies: PigSpecies[] | null = null;
let cachedRoutes: EvolutionRoute[] | null = null;
let cachedSkills: Skill[] | null = null;
let cachedConfig: GameConfig | null = null;

async function getSpecies(): Promise<PigSpecies[]> {
  if (cachedSpecies) return cachedSpecies;
  const r = await client.send(new ScanCommand({ TableName: PIG_SPECIES_TABLE }));
  cachedSpecies = (r.Items || []) as PigSpecies[];
  return cachedSpecies;
}
async function getRoutes(): Promise<EvolutionRoute[]> {
  if (cachedRoutes) return cachedRoutes;
  const r = await client.send(new ScanCommand({ TableName: EVOLUTION_ROUTE_TABLE }));
  cachedRoutes = (r.Items || []) as EvolutionRoute[];
  return cachedRoutes;
}
async function getSkillsData(): Promise<Skill[]> {
  if (cachedSkills) return cachedSkills;
  const r = await client.send(new ScanCommand({ TableName: SKILL_TABLE }));
  cachedSkills = (r.Items || []) as Skill[];
  return cachedSkills;
}
async function getConfig(): Promise<GameConfig> {
  if (cachedConfig) return cachedConfig;
  const defaults: GameConfig = { INITIAL_STATS: { hp: 50, attack: 10, defense: 10, speed: 10 }, MAX_LEVEL: 30, EVOLUTION_LEVEL_STAGE2: 5, EVOLUTION_LEVEL_STAGE3: 15, CATEGORY_THRESHOLD: 0.6, LEVEL_FORMULA_COEFFICIENT: 50 };
  const r = await client.send(new ScanCommand({ TableName: GAME_CONFIG_TABLE }));
  for (const item of r.Items || []) { if (item.configKey in defaults) (defaults as any)[item.configKey] = item.value; }
  cachedConfig = defaults;
  return cachedConfig;
}

// --- Level calculation ---
function calculateLevel(totalPoints: number, config: GameConfig): number {
  if (totalPoints <= 0) return 1;
  const f = config.LEVEL_FORMULA_COEFFICIENT;
  return Math.max(1, Math.min(config.MAX_LEVEL, Math.floor((-f + Math.sqrt(f * f + 4 * f * totalPoints)) / (2 * f))));
}

// --- Evolution logic ---
function determineEvolution(avatar: Avatar, newLevel: number, species: PigSpecies[], routes: EvolutionRoute[], config: GameConfig): PigSpecies | null {
  if (avatar.evolutionStage === 1 && newLevel >= config.EVOLUTION_LEVEL_STAGE2) return findNext(avatar, null, species, routes, config);
  if (avatar.evolutionStage === 2 && newLevel >= config.EVOLUTION_LEVEL_STAGE3 && avatar.currentSpeciesId) return findNext(avatar, avatar.currentSpeciesId, species, routes, config);
  return null;
}

function findNext(avatar: Avatar, fromId: string | null, species: PigSpecies[], routes: EvolutionRoute[], config: GameConfig): PigSpecies | null {
  const candidates = fromId ? routes.filter(r => r.fromSpeciesId === fromId) : routes.filter(r => { const s = species.find(sp => sp.speciesId === r.fromSpeciesId); return s && s.stage === 1; });
  const sorted = [...candidates].sort((a, b) => a.priority - b.priority);
  for (const route of sorted) {
    const total = avatar.totalPoints;
    if (total === 0) continue;
    if (route.subCategoryIds && route.subCategoryThreshold) {
      const rel = route.subCategoryIds.reduce((sum, id) => sum + (avatar.subCategoryPoints[id] || 0), 0);
      const catTotal = avatar.categoryPoints[route.conditionCategory] || 0;
      if (catTotal > 0 && rel / catTotal >= route.subCategoryThreshold) return species.find(s => s.speciesId === route.toSpeciesId) || null;
    } else {
      const ratio = (avatar.categoryPoints[route.conditionCategory] || 0) / total;
      if (ratio >= route.categoryThreshold) return species.find(s => s.speciesId === route.toSpeciesId) || null;
    }
  }
  return sorted.length > 0 ? species.find(s => s.speciesId === sorted[0].toSpeciesId) || null : null;
}

function checkDevolution(avatar: Avatar, newLevel: number, species: PigSpecies[], routes: EvolutionRoute[], config: GameConfig): { newStage: number; newSpeciesId: string | null } | null {
  if (avatar.evolutionStage === 3 && newLevel < config.EVOLUTION_LEVEL_STAGE3) {
    const incoming = routes.find(r => r.toSpeciesId === avatar.currentSpeciesId);
    return { newStage: 2, newSpeciesId: incoming ? incoming.fromSpeciesId : null };
  }
  if (avatar.evolutionStage === 2 && newLevel < config.EVOLUTION_LEVEL_STAGE2) return { newStage: 1, newSpeciesId: null };
  return null;
}

function recalcStats(level: number, sp: PigSpecies | null, config: GameConfig): AvatarStats {
  const g = sp?.statsGrowth || { hp: 5, attack: 3, defense: 3, speed: 3 };
  const i = config.INITIAL_STATS;
  return { hp: i.hp + (level - 1) * g.hp, attack: i.attack + (level - 1) * g.attack, defense: i.defense + (level - 1) * g.defense, speed: i.speed + (level - 1) * g.speed };
}

// --- Public API ---
export interface AvatarPointsResult { totalPoints: number; level: number; evolutionStage: number; currentSpeciesId: string | null; leveledUp: boolean; evolved: boolean; devolved: boolean; }

export async function addPoints(userId: string, points: number, categoryType: string, subCategoryId?: string): Promise<AvatarPointsResult> {
  const avatar = await getAvatar(userId);
  if (!avatar) return { totalPoints: points, level: 1, evolutionStage: 1, currentSpeciesId: null, leveledUp: false, evolved: false, devolved: false };

  const [species, routes, skills, config] = await Promise.all([getSpecies(), getRoutes(), getSkillsData(), getConfig()]);

  avatar.totalPoints += points;
  avatar.categoryPoints[categoryType] = (avatar.categoryPoints[categoryType] || 0) + points;
  if (subCategoryId) avatar.subCategoryPoints[subCategoryId] = (avatar.subCategoryPoints[subCategoryId] || 0) + points;

  const oldLevel = avatar.level;
  avatar.level = calculateLevel(avatar.totalPoints, config);
  const leveledUp = avatar.level > oldLevel;

  let evolved = false;
  if (leveledUp) {
    const target = determineEvolution(avatar, avatar.level, species, routes, config);
    if (target) {
      const oldSpeciesId = avatar.currentSpeciesId;
      avatar.evolutionStage = target.stage;
      avatar.currentSpeciesId = target.speciesId;
      evolved = true;
      await saveHistory(avatar, 'EVOLUTION', target.stage - 1, target.stage, oldSpeciesId, target.speciesId);
    }
  }

  // Skill acquisition
  const newSkills = skills.filter(s => s.speciesId === avatar.currentSpeciesId && s.requiredLevel <= avatar.level && !avatar.skillIds.includes(s.skillId));
  avatar.skillIds.push(...newSkills.map(s => s.skillId));

  const currentSp = species.find(s => s.speciesId === avatar.currentSpeciesId) || null;
  avatar.stats = recalcStats(avatar.level, currentSp, config);
  avatar.updatedAt = new Date().toISOString();
  await client.send(new PutCommand({ TableName: AVATAR_TABLE, Item: avatar }));

  return { totalPoints: avatar.totalPoints, level: avatar.level, evolutionStage: avatar.evolutionStage, currentSpeciesId: avatar.currentSpeciesId, leveledUp, evolved, devolved: false };
}

export async function deductPoints(userId: string, points: number, categoryType: string, subCategoryId?: string): Promise<AvatarPointsResult & { devolved: boolean }> {
  const avatar = await getAvatar(userId);
  if (!avatar) return { totalPoints: 0, level: 1, evolutionStage: 1, currentSpeciesId: null, leveledUp: false, evolved: false, devolved: false };

  const [species, routes, skills, config] = await Promise.all([getSpecies(), getRoutes(), getSkillsData(), getConfig()]);

  avatar.totalPoints = Math.max(0, avatar.totalPoints - points);
  avatar.categoryPoints[categoryType] = Math.max(0, (avatar.categoryPoints[categoryType] || 0) - points);
  if (subCategoryId) avatar.subCategoryPoints[subCategoryId] = Math.max(0, (avatar.subCategoryPoints[subCategoryId] || 0) - points);

  const oldLevel = avatar.level;
  avatar.level = calculateLevel(avatar.totalPoints, config);

  let devolved = false;
  const dev = checkDevolution(avatar, avatar.level, species, routes, config);
  if (dev) {
    const oldSpeciesId = avatar.currentSpeciesId;
    const lostSkills = skills.filter(s => s.speciesId === oldSpeciesId && avatar.skillIds.includes(s.skillId));
    avatar.skillIds = avatar.skillIds.filter(id => !lostSkills.some(s => s.skillId === id));
    avatar.evolutionStage = dev.newStage;
    avatar.currentSpeciesId = dev.newSpeciesId;
    devolved = true;
    await saveHistory(avatar, 'DEVOLUTION', dev.newStage + 1, dev.newStage, oldSpeciesId, dev.newSpeciesId);
  }

  const currentSp = species.find(s => s.speciesId === avatar.currentSpeciesId) || null;
  avatar.stats = recalcStats(avatar.level, currentSp, config);
  avatar.updatedAt = new Date().toISOString();
  await client.send(new PutCommand({ TableName: AVATAR_TABLE, Item: avatar }));

  return { totalPoints: avatar.totalPoints, level: avatar.level, evolutionStage: avatar.evolutionStage, currentSpeciesId: avatar.currentSpeciesId, leveledUp: false, evolved: false, devolved };
}

async function getAvatar(userId: string): Promise<Avatar | null> {
  const r = await client.send(new GetCommand({ TableName: AVATAR_TABLE, Key: { userId } }));
  return (r.Item as Avatar) || null;
}

async function saveHistory(avatar: Avatar, type: string, fromStage: number, toStage: number, fromSpeciesId: string | null, toSpeciesId: string | null) {
  const now = new Date().toISOString();
  const historyId = randomUUID();
  await client.send(new PutCommand({
    TableName: EVOLUTION_HISTORY_TABLE,
    Item: { userId: avatar.userId, 'occurredAt#historyId': `${now}#${historyId}`, historyId, avatarId: avatar.avatarId, fromStage, toStage, fromSpeciesId, toSpeciesId, type, triggerPoints: avatar.totalPoints, occurredAt: now },
  }));
}
