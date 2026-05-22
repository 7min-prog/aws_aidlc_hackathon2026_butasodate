import { z } from 'zod';

export const CategoryTypeSchema = z.enum(['FOOD', 'LIFESTYLE', 'MIXED']);

export const AvatarStatsSchema = z.object({
  hp: z.number(),
  attack: z.number(),
  defense: z.number(),
  speed: z.number(),
});

export const AvatarSchema = z.object({
  avatarId: z.string(),
  userId: z.string(),
  name: z.string(),
  totalPoints: z.number(),
  level: z.number(),
  evolutionStage: z.number(),
  evolutionPathId: z.string().nullable(),
  categoryPoints: z.record(CategoryTypeSchema, z.number()),
  subCategoryPoints: z.record(z.string(), z.number()),
  stats: AvatarStatsSchema,
  skillIds: z.array(z.string()),
  spriteSheetKey: z.string(),
  createdAt: z.string(),
  updatedAt: z.string(),
});

export const SkillSchema = z.object({
  skillId: z.string(),
  name: z.string(),
  type: z.enum(['ATTACK', 'DEFENSE', 'DEBUFF', 'HEAL']),
  power: z.number(),
  cooldown: z.number(),
  evolutionPathId: z.string(),
  requiredLevel: z.number(),
  spriteAnimationKey: z.string(),
});

export const EvolutionHistorySchema = z.object({
  historyId: z.string(),
  userId: z.string(),
  avatarId: z.string(),
  fromStage: z.number(),
  toStage: z.number(),
  fromPathId: z.string().nullable(),
  toPathId: z.string().nullable(),
  type: z.enum(['EVOLUTION', 'DEVOLUTION']),
  triggerPoints: z.number(),
  occurredAt: z.string(),
});

export const CreateAvatarRequestSchema = z.object({
  name: z.string().optional(),
});

export const AddPointsRequestSchema = z.object({
  points: z.number().min(1),
  categoryType: CategoryTypeSchema,
  subCategoryId: z.string().optional(),
});

export const DeductPointsRequestSchema = z.object({
  points: z.number().min(1),
  categoryType: CategoryTypeSchema,
  subCategoryId: z.string().optional(),
});

export const ErrorResponseSchema = z.object({
  error: z.string(),
});
