"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createAvatar = createAvatar;
exports.getAvatar = getAvatar;
exports.addPoints = addPoints;
exports.deductPoints = deductPoints;
exports.getEvolutionHistory = getEvolutionHistory;
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const crypto_1 = require("crypto");
const dynamo_client_1 = require("../utils/dynamo-client");
const master_data_cache_1 = require("./master-data-cache");
const evolution_engine_1 = require("./evolution-engine");
const DEFAULT_AVATAR_NAME = 'ぶたさん';
async function createAvatar(userId, name) {
    const existing = await getAvatar(userId);
    if (existing)
        throw new Error('AVATAR_EXISTS');
    const config = await (0, master_data_cache_1.getGameConfig)();
    const avatar = {
        avatarId: (0, crypto_1.randomUUID)(),
        userId,
        name: name || DEFAULT_AVATAR_NAME,
        totalPoints: 0,
        level: 1,
        evolutionStage: 1,
        currentSpeciesId: null,
        categoryPoints: { FOOD: 0, LIFESTYLE: 0, MIXED: 0 },
        subCategoryPoints: {},
        stats: config.INITIAL_STATS,
        skillIds: [],
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
    };
    await dynamo_client_1.docClient.send(new lib_dynamodb_1.PutCommand({ TableName: dynamo_client_1.AVATAR_TABLE, Item: avatar }));
    return avatar;
}
async function getAvatar(userId) {
    const result = await dynamo_client_1.docClient.send(new lib_dynamodb_1.GetCommand({
        TableName: dynamo_client_1.AVATAR_TABLE, Key: { userId },
    }));
    return result.Item || null;
}
async function addPoints(userId, points, categoryType, subCategoryId) {
    const avatar = await getAvatar(userId);
    if (!avatar)
        throw new Error('AVATAR_NOT_FOUND');
    const [species, routes, skills, config] = await Promise.all([
        (0, master_data_cache_1.getPigSpecies)(), (0, master_data_cache_1.getEvolutionRoutes)(), (0, master_data_cache_1.getSkills)(), (0, master_data_cache_1.getGameConfig)(),
    ]);
    // Step 1: ポイント更新
    avatar.totalPoints += points;
    avatar.categoryPoints[categoryType] = (avatar.categoryPoints[categoryType] || 0) + points;
    if (subCategoryId) {
        avatar.subCategoryPoints[subCategoryId] = (avatar.subCategoryPoints[subCategoryId] || 0) + points;
    }
    // Step 2: レベル再計算
    const oldLevel = avatar.level;
    avatar.level = (0, evolution_engine_1.calculateLevel)(avatar.totalPoints, config);
    const leveledUp = avatar.level > oldLevel;
    // Step 3: 進化判定
    let evolved = false;
    if (leveledUp) {
        const target = (0, evolution_engine_1.determineEvolution)(avatar, avatar.level, species, routes, config);
        if (target) {
            const oldSpeciesId = avatar.currentSpeciesId;
            avatar.evolutionStage = target.stage;
            avatar.currentSpeciesId = target.speciesId;
            evolved = true;
            await saveEvolutionHistory(avatar, 'EVOLUTION', target.stage - 1, target.stage, oldSpeciesId, target.speciesId);
        }
    }
    // Step 4: スキル習得
    const newSkills = (0, evolution_engine_1.checkSkillAcquisition)(avatar, skills);
    avatar.skillIds.push(...newSkills.map(s => s.skillId));
    // Step 5: ステータス再計算
    const currentSpecies = species.find(s => s.speciesId === avatar.currentSpeciesId) || null;
    avatar.stats = (0, evolution_engine_1.recalculateStats)(avatar.level, currentSpecies, config);
    avatar.updatedAt = new Date().toISOString();
    await saveAvatar(avatar);
    return { avatar, leveledUp, evolved, newSkills };
}
async function deductPoints(userId, points, categoryType, subCategoryId) {
    const avatar = await getAvatar(userId);
    if (!avatar)
        throw new Error('AVATAR_NOT_FOUND');
    const [species, routes, skills, config] = await Promise.all([
        (0, master_data_cache_1.getPigSpecies)(), (0, master_data_cache_1.getEvolutionRoutes)(), (0, master_data_cache_1.getSkills)(), (0, master_data_cache_1.getGameConfig)(),
    ]);
    // Step 1: ポイント更新
    avatar.totalPoints = Math.max(0, avatar.totalPoints - points);
    avatar.categoryPoints[categoryType] = Math.max(0, (avatar.categoryPoints[categoryType] || 0) - points);
    if (subCategoryId) {
        avatar.subCategoryPoints[subCategoryId] = Math.max(0, (avatar.subCategoryPoints[subCategoryId] || 0) - points);
    }
    // Step 2: レベル再計算
    const oldLevel = avatar.level;
    avatar.level = (0, evolution_engine_1.calculateLevel)(avatar.totalPoints, config);
    const leveledDown = avatar.level < oldLevel;
    // Step 3: 退化判定
    let devolved = false;
    let lostSkills = [];
    const devolution = (0, evolution_engine_1.checkDevolution)(avatar, avatar.level, species, routes, config);
    if (devolution) {
        const oldSpeciesId = avatar.currentSpeciesId;
        lostSkills = oldSpeciesId ? (0, evolution_engine_1.getSkillsToLose)(avatar, oldSpeciesId, skills) : [];
        avatar.skillIds = avatar.skillIds.filter(id => !lostSkills.some(s => s.skillId === id));
        avatar.evolutionStage = devolution.newStage;
        avatar.currentSpeciesId = devolution.newSpeciesId;
        devolved = true;
        await saveEvolutionHistory(avatar, 'DEVOLUTION', devolution.newStage + 1, devolution.newStage, oldSpeciesId, devolution.newSpeciesId);
    }
    // Step 4: ステータス再計算
    const currentSpecies = species.find(s => s.speciesId === avatar.currentSpeciesId) || null;
    avatar.stats = (0, evolution_engine_1.recalculateStats)(avatar.level, currentSpecies, config);
    avatar.updatedAt = new Date().toISOString();
    await saveAvatar(avatar);
    return { avatar, leveledDown, devolved, lostSkills };
}
async function getEvolutionHistory(userId) {
    const result = await dynamo_client_1.docClient.send(new lib_dynamodb_1.QueryCommand({
        TableName: dynamo_client_1.EVOLUTION_HISTORY_TABLE,
        KeyConditionExpression: 'userId = :uid',
        ExpressionAttributeValues: { ':uid': userId },
        ScanIndexForward: false,
    }));
    return (result.Items || []);
}
async function saveAvatar(avatar) {
    await dynamo_client_1.docClient.send(new lib_dynamodb_1.PutCommand({ TableName: dynamo_client_1.AVATAR_TABLE, Item: avatar }));
}
async function saveEvolutionHistory(avatar, type, fromStage, toStage, fromSpeciesId, toSpeciesId) {
    const now = new Date().toISOString();
    const history = {
        historyId: (0, crypto_1.randomUUID)(),
        userId: avatar.userId,
        avatarId: avatar.avatarId,
        fromStage, toStage, fromSpeciesId, toSpeciesId, type,
        triggerPoints: avatar.totalPoints,
        occurredAt: now,
    };
    await dynamo_client_1.docClient.send(new lib_dynamodb_1.PutCommand({
        TableName: dynamo_client_1.EVOLUTION_HISTORY_TABLE,
        Item: { ...history, 'occurredAt#historyId': `${now}#${history.historyId}` },
    }));
}
//# sourceMappingURL=avatar-service.js.map