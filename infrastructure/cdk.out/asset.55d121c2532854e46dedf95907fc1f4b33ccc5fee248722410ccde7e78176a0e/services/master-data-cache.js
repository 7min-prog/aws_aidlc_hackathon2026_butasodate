"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getPigSpecies = getPigSpecies;
exports.getEvolutionRoutes = getEvolutionRoutes;
exports.getSkills = getSkills;
exports.getGameConfig = getGameConfig;
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const dynamo_client_1 = require("../utils/dynamo-client");
let cachedSpecies = null;
let cachedRoutes = null;
let cachedSkills = null;
let cachedConfig = null;
async function getPigSpecies() {
    if (cachedSpecies)
        return cachedSpecies;
    const result = await dynamo_client_1.docClient.send(new lib_dynamodb_1.ScanCommand({ TableName: dynamo_client_1.PIG_SPECIES_TABLE }));
    cachedSpecies = (result.Items || []);
    return cachedSpecies;
}
async function getEvolutionRoutes() {
    if (cachedRoutes)
        return cachedRoutes;
    const result = await dynamo_client_1.docClient.send(new lib_dynamodb_1.ScanCommand({ TableName: dynamo_client_1.EVOLUTION_ROUTE_TABLE }));
    cachedRoutes = (result.Items || []);
    return cachedRoutes;
}
async function getSkills() {
    if (cachedSkills)
        return cachedSkills;
    const result = await dynamo_client_1.docClient.send(new lib_dynamodb_1.ScanCommand({ TableName: dynamo_client_1.SKILL_TABLE }));
    cachedSkills = (result.Items || []);
    return cachedSkills;
}
async function getGameConfig() {
    if (cachedConfig)
        return cachedConfig;
    const result = await dynamo_client_1.docClient.send(new lib_dynamodb_1.ScanCommand({ TableName: dynamo_client_1.GAME_CONFIG_TABLE }));
    const items = result.Items || [];
    const config = {
        INITIAL_STATS: { hp: 50, attack: 10, defense: 10, speed: 10 },
        MAX_LEVEL: 30,
        EVOLUTION_LEVEL_STAGE2: 5,
        EVOLUTION_LEVEL_STAGE3: 15,
        CATEGORY_THRESHOLD: 0.6,
        LEVEL_FORMULA_COEFFICIENT: 50,
    };
    for (const item of items) {
        if (item.configKey in config) {
            config[item.configKey] = item.value;
        }
    }
    cachedConfig = config;
    return cachedConfig;
}
//# sourceMappingURL=master-data-cache.js.map