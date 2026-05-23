"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ErrorResponseSchema = exports.DeductPointsRequestSchema = exports.AddPointsRequestSchema = exports.CreateAvatarRequestSchema = exports.EvolutionHistorySchema = exports.SkillSchema = exports.AvatarSchema = exports.AvatarStatsSchema = exports.CategoryTypeSchema = void 0;
const zod_1 = require("zod");
exports.CategoryTypeSchema = zod_1.z.enum(['FOOD', 'LIFESTYLE', 'MIXED']);
exports.AvatarStatsSchema = zod_1.z.object({
    hp: zod_1.z.number(),
    attack: zod_1.z.number(),
    defense: zod_1.z.number(),
    speed: zod_1.z.number(),
});
exports.AvatarSchema = zod_1.z.object({
    avatarId: zod_1.z.string(),
    userId: zod_1.z.string(),
    name: zod_1.z.string(),
    totalPoints: zod_1.z.number(),
    level: zod_1.z.number(),
    evolutionStage: zod_1.z.number(),
    currentSpeciesId: zod_1.z.string().nullable(),
    categoryPoints: zod_1.z.record(exports.CategoryTypeSchema, zod_1.z.number()),
    subCategoryPoints: zod_1.z.record(zod_1.z.string(), zod_1.z.number()),
    stats: exports.AvatarStatsSchema,
    skillIds: zod_1.z.array(zod_1.z.string()),
    createdAt: zod_1.z.string(),
    updatedAt: zod_1.z.string(),
});
exports.SkillSchema = zod_1.z.object({
    skillId: zod_1.z.string(),
    name: zod_1.z.string(),
    type: zod_1.z.enum(['ATTACK', 'DEFENSE', 'DEBUFF', 'HEAL']),
    targetStat: zod_1.z.string(),
    multiplier: zod_1.z.number(),
    duration: zod_1.z.number().nullable(),
    cooldown: zod_1.z.number(),
    speciesId: zod_1.z.string(),
    requiredLevel: zod_1.z.number(),
    spriteAnimationKey: zod_1.z.string(),
});
exports.EvolutionHistorySchema = zod_1.z.object({
    historyId: zod_1.z.string(),
    userId: zod_1.z.string(),
    avatarId: zod_1.z.string(),
    fromStage: zod_1.z.number(),
    toStage: zod_1.z.number(),
    fromSpeciesId: zod_1.z.string().nullable(),
    toSpeciesId: zod_1.z.string().nullable(),
    type: zod_1.z.enum(['EVOLUTION', 'DEVOLUTION']),
    triggerPoints: zod_1.z.number(),
    occurredAt: zod_1.z.string(),
});
exports.CreateAvatarRequestSchema = zod_1.z.object({
    name: zod_1.z.string().optional(),
});
exports.AddPointsRequestSchema = zod_1.z.object({
    points: zod_1.z.number().min(1),
    categoryType: exports.CategoryTypeSchema,
    subCategoryId: zod_1.z.string().optional(),
});
exports.DeductPointsRequestSchema = zod_1.z.object({
    points: zod_1.z.number().min(1),
    categoryType: exports.CategoryTypeSchema,
    subCategoryId: zod_1.z.string().optional(),
});
exports.ErrorResponseSchema = zod_1.z.object({
    error: zod_1.z.string(),
});
//# sourceMappingURL=schemas.js.map