"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.addPoints = addPoints;
exports.deductPoints = deductPoints;
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const client_dynamodb_1 = require("@aws-sdk/client-dynamodb");
const crypto_1 = require("crypto");
const client = lib_dynamodb_1.DynamoDBDocumentClient.from(new client_dynamodb_1.DynamoDBClient({}), { marshallOptions: { removeUndefinedValues: true } });
const AVATAR_TABLE = process.env.AVATAR_TABLE_NAME;
const EVOLUTION_HISTORY_TABLE = process.env.EVOLUTION_HISTORY_TABLE_NAME;
const PIG_SPECIES_TABLE = process.env.PIG_SPECIES_TABLE_NAME;
const EVOLUTION_ROUTE_TABLE = process.env.EVOLUTION_ROUTE_TABLE_NAME;
const SKILL_TABLE = process.env.SKILL_TABLE_NAME;
const GAME_CONFIG_TABLE = process.env.GAME_CONFIG_TABLE_NAME;
// --- Cache ---
let cachedSpecies = null;
let cachedRoutes = null;
let cachedSkills = null;
let cachedConfig = null;
async function getSpecies() {
    if (cachedSpecies)
        return cachedSpecies;
    const r = await client.send(new lib_dynamodb_1.ScanCommand({ TableName: PIG_SPECIES_TABLE }));
    cachedSpecies = (r.Items || []);
    return cachedSpecies;
}
async function getRoutes() {
    if (cachedRoutes)
        return cachedRoutes;
    const r = await client.send(new lib_dynamodb_1.ScanCommand({ TableName: EVOLUTION_ROUTE_TABLE }));
    cachedRoutes = (r.Items || []);
    return cachedRoutes;
}
async function getSkillsData() {
    if (cachedSkills)
        return cachedSkills;
    const r = await client.send(new lib_dynamodb_1.ScanCommand({ TableName: SKILL_TABLE }));
    cachedSkills = (r.Items || []);
    return cachedSkills;
}
async function getConfig() {
    if (cachedConfig)
        return cachedConfig;
    const defaults = { INITIAL_STATS: { hp: 50, attack: 10, defense: 10, speed: 10 }, MAX_LEVEL: 30, EVOLUTION_LEVEL_STAGE2: 5, EVOLUTION_LEVEL_STAGE3: 15, CATEGORY_THRESHOLD: 0.6, LEVEL_FORMULA_COEFFICIENT: 50 };
    const r = await client.send(new lib_dynamodb_1.ScanCommand({ TableName: GAME_CONFIG_TABLE }));
    for (const item of r.Items || []) {
        if (item.configKey in defaults)
            defaults[item.configKey] = item.value;
    }
    cachedConfig = defaults;
    return cachedConfig;
}
// --- Level calculation ---
function calculateLevel(totalPoints, config) {
    if (totalPoints <= 0)
        return 1;
    const f = config.LEVEL_FORMULA_COEFFICIENT;
    return Math.max(1, Math.min(config.MAX_LEVEL, Math.floor((-f + Math.sqrt(f * f + 4 * f * totalPoints)) / (2 * f))));
}
// --- Evolution logic ---
function determineEvolution(avatar, newLevel, species, routes, config) {
    if (avatar.evolutionStage === 1 && newLevel >= config.EVOLUTION_LEVEL_STAGE2)
        return findNext(avatar, null, species, routes, config);
    if (avatar.evolutionStage === 2 && newLevel >= config.EVOLUTION_LEVEL_STAGE3 && avatar.currentSpeciesId)
        return findNext(avatar, avatar.currentSpeciesId, species, routes, config);
    return null;
}
function findNext(avatar, fromId, species, routes, config) {
    const candidates = fromId ? routes.filter(r => r.fromSpeciesId === fromId) : routes.filter(r => { const s = species.find(sp => sp.speciesId === r.fromSpeciesId); return s && s.stage === 1; });
    const sorted = [...candidates].sort((a, b) => a.priority - b.priority);
    for (const route of sorted) {
        const total = avatar.totalPoints;
        if (total === 0)
            continue;
        if (route.subCategoryIds && route.subCategoryThreshold) {
            const rel = route.subCategoryIds.reduce((sum, id) => sum + (avatar.subCategoryPoints[id] || 0), 0);
            const catTotal = avatar.categoryPoints[route.conditionCategory] || 0;
            if (catTotal > 0 && rel / catTotal >= route.subCategoryThreshold)
                return species.find(s => s.speciesId === route.toSpeciesId) || null;
        }
        else {
            const ratio = (avatar.categoryPoints[route.conditionCategory] || 0) / total;
            if (ratio >= route.categoryThreshold)
                return species.find(s => s.speciesId === route.toSpeciesId) || null;
        }
    }
    return sorted.length > 0 ? species.find(s => s.speciesId === sorted[0].toSpeciesId) || null : null;
}
function checkDevolution(avatar, newLevel, species, routes, config) {
    if (avatar.evolutionStage === 3 && newLevel < config.EVOLUTION_LEVEL_STAGE3) {
        const incoming = routes.find(r => r.toSpeciesId === avatar.currentSpeciesId);
        return { newStage: 2, newSpeciesId: incoming ? incoming.fromSpeciesId : null };
    }
    if (avatar.evolutionStage === 2 && newLevel < config.EVOLUTION_LEVEL_STAGE2)
        return { newStage: 1, newSpeciesId: null };
    return null;
}
function recalcStats(level, sp, config) {
    const g = sp?.statsGrowth || { hp: 5, attack: 3, defense: 3, speed: 3 };
    const i = config.INITIAL_STATS;
    return { hp: i.hp + (level - 1) * g.hp, attack: i.attack + (level - 1) * g.attack, defense: i.defense + (level - 1) * g.defense, speed: i.speed + (level - 1) * g.speed };
}
async function addPoints(userId, points, categoryType, subCategoryId) {
    const avatar = await getAvatar(userId);
    if (!avatar)
        return { totalPoints: points, level: 1, evolutionStage: 1, currentSpeciesId: null, leveledUp: false, evolved: false, devolved: false };
    const [species, routes, skills, config] = await Promise.all([getSpecies(), getRoutes(), getSkillsData(), getConfig()]);
    avatar.totalPoints += points;
    avatar.categoryPoints[categoryType] = (avatar.categoryPoints[categoryType] || 0) + points;
    if (subCategoryId)
        avatar.subCategoryPoints[subCategoryId] = (avatar.subCategoryPoints[subCategoryId] || 0) + points;
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
    await client.send(new lib_dynamodb_1.PutCommand({ TableName: AVATAR_TABLE, Item: avatar }));
    return { totalPoints: avatar.totalPoints, level: avatar.level, evolutionStage: avatar.evolutionStage, currentSpeciesId: avatar.currentSpeciesId, leveledUp, evolved, devolved: false };
}
async function deductPoints(userId, points, categoryType, subCategoryId) {
    const avatar = await getAvatar(userId);
    if (!avatar)
        return { totalPoints: 0, level: 1, evolutionStage: 1, currentSpeciesId: null, leveledUp: false, evolved: false, devolved: false };
    const [species, routes, skills, config] = await Promise.all([getSpecies(), getRoutes(), getSkillsData(), getConfig()]);
    avatar.totalPoints = Math.max(0, avatar.totalPoints - points);
    avatar.categoryPoints[categoryType] = Math.max(0, (avatar.categoryPoints[categoryType] || 0) - points);
    if (subCategoryId)
        avatar.subCategoryPoints[subCategoryId] = Math.max(0, (avatar.subCategoryPoints[subCategoryId] || 0) - points);
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
    await client.send(new lib_dynamodb_1.PutCommand({ TableName: AVATAR_TABLE, Item: avatar }));
    return { totalPoints: avatar.totalPoints, level: avatar.level, evolutionStage: avatar.evolutionStage, currentSpeciesId: avatar.currentSpeciesId, leveledUp: false, evolved: false, devolved };
}
async function getAvatar(userId) {
    const r = await client.send(new lib_dynamodb_1.GetCommand({ TableName: AVATAR_TABLE, Key: { userId } }));
    return r.Item || null;
}
async function saveHistory(avatar, type, fromStage, toStage, fromSpeciesId, toSpeciesId) {
    const now = new Date().toISOString();
    const historyId = (0, crypto_1.randomUUID)();
    await client.send(new lib_dynamodb_1.PutCommand({
        TableName: EVOLUTION_HISTORY_TABLE,
        Item: { userId: avatar.userId, 'occurredAt#historyId': `${now}#${historyId}`, historyId, avatarId: avatar.avatarId, fromStage, toStage, fromSpeciesId, toSpeciesId, type, triggerPoints: avatar.totalPoints, occurredAt: now },
    }));
}
//# sourceMappingURL=avatar-points-service.js.map