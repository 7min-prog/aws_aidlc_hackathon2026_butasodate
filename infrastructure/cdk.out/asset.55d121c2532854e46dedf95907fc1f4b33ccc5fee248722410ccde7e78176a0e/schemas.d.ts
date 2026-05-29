import { z } from 'zod';
export declare const CategoryTypeSchema: z.ZodEnum<["FOOD", "LIFESTYLE", "MIXED"]>;
export declare const AvatarStatsSchema: z.ZodObject<{
    hp: z.ZodNumber;
    attack: z.ZodNumber;
    defense: z.ZodNumber;
    speed: z.ZodNumber;
}, "strip", z.ZodTypeAny, {
    hp: number;
    attack: number;
    defense: number;
    speed: number;
}, {
    hp: number;
    attack: number;
    defense: number;
    speed: number;
}>;
export declare const AvatarSchema: z.ZodObject<{
    avatarId: z.ZodString;
    userId: z.ZodString;
    name: z.ZodString;
    totalPoints: z.ZodNumber;
    level: z.ZodNumber;
    evolutionStage: z.ZodNumber;
    currentSpeciesId: z.ZodNullable<z.ZodString>;
    categoryPoints: z.ZodRecord<z.ZodEnum<["FOOD", "LIFESTYLE", "MIXED"]>, z.ZodNumber>;
    subCategoryPoints: z.ZodRecord<z.ZodString, z.ZodNumber>;
    stats: z.ZodObject<{
        hp: z.ZodNumber;
        attack: z.ZodNumber;
        defense: z.ZodNumber;
        speed: z.ZodNumber;
    }, "strip", z.ZodTypeAny, {
        hp: number;
        attack: number;
        defense: number;
        speed: number;
    }, {
        hp: number;
        attack: number;
        defense: number;
        speed: number;
    }>;
    skillIds: z.ZodArray<z.ZodString, "many">;
    createdAt: z.ZodString;
    updatedAt: z.ZodString;
}, "strip", z.ZodTypeAny, {
    name: string;
    userId: string;
    currentSpeciesId: string | null;
    avatarId: string;
    totalPoints: number;
    level: number;
    evolutionStage: number;
    categoryPoints: Partial<Record<"FOOD" | "LIFESTYLE" | "MIXED", number>>;
    subCategoryPoints: Record<string, number>;
    stats: {
        hp: number;
        attack: number;
        defense: number;
        speed: number;
    };
    skillIds: string[];
    createdAt: string;
    updatedAt: string;
}, {
    name: string;
    userId: string;
    currentSpeciesId: string | null;
    avatarId: string;
    totalPoints: number;
    level: number;
    evolutionStage: number;
    categoryPoints: Partial<Record<"FOOD" | "LIFESTYLE" | "MIXED", number>>;
    subCategoryPoints: Record<string, number>;
    stats: {
        hp: number;
        attack: number;
        defense: number;
        speed: number;
    };
    skillIds: string[];
    createdAt: string;
    updatedAt: string;
}>;
export declare const SkillSchema: z.ZodObject<{
    skillId: z.ZodString;
    name: z.ZodString;
    type: z.ZodEnum<["ATTACK", "DEFENSE", "DEBUFF", "HEAL"]>;
    targetStat: z.ZodString;
    multiplier: z.ZodNumber;
    duration: z.ZodNullable<z.ZodNumber>;
    cooldown: z.ZodNumber;
    speciesId: z.ZodString;
    requiredLevel: z.ZodNumber;
    spriteAnimationKey: z.ZodString;
}, "strip", z.ZodTypeAny, {
    name: string;
    type: "ATTACK" | "DEFENSE" | "DEBUFF" | "HEAL";
    skillId: string;
    targetStat: string;
    multiplier: number;
    duration: number | null;
    cooldown: number;
    speciesId: string;
    requiredLevel: number;
    spriteAnimationKey: string;
}, {
    name: string;
    type: "ATTACK" | "DEFENSE" | "DEBUFF" | "HEAL";
    skillId: string;
    targetStat: string;
    multiplier: number;
    duration: number | null;
    cooldown: number;
    speciesId: string;
    requiredLevel: number;
    spriteAnimationKey: string;
}>;
export declare const EvolutionHistorySchema: z.ZodObject<{
    historyId: z.ZodString;
    userId: z.ZodString;
    avatarId: z.ZodString;
    fromStage: z.ZodNumber;
    toStage: z.ZodNumber;
    fromSpeciesId: z.ZodNullable<z.ZodString>;
    toSpeciesId: z.ZodNullable<z.ZodString>;
    type: z.ZodEnum<["EVOLUTION", "DEVOLUTION"]>;
    triggerPoints: z.ZodNumber;
    occurredAt: z.ZodString;
}, "strip", z.ZodTypeAny, {
    userId: string;
    type: "EVOLUTION" | "DEVOLUTION";
    avatarId: string;
    historyId: string;
    fromStage: number;
    toStage: number;
    fromSpeciesId: string | null;
    toSpeciesId: string | null;
    triggerPoints: number;
    occurredAt: string;
}, {
    userId: string;
    type: "EVOLUTION" | "DEVOLUTION";
    avatarId: string;
    historyId: string;
    fromStage: number;
    toStage: number;
    fromSpeciesId: string | null;
    toSpeciesId: string | null;
    triggerPoints: number;
    occurredAt: string;
}>;
export declare const CreateAvatarRequestSchema: z.ZodObject<{
    name: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    name?: string | undefined;
}, {
    name?: string | undefined;
}>;
export declare const AddPointsRequestSchema: z.ZodObject<{
    points: z.ZodNumber;
    categoryType: z.ZodEnum<["FOOD", "LIFESTYLE", "MIXED"]>;
    subCategoryId: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    points: number;
    categoryType: "FOOD" | "LIFESTYLE" | "MIXED";
    subCategoryId?: string | undefined;
}, {
    points: number;
    categoryType: "FOOD" | "LIFESTYLE" | "MIXED";
    subCategoryId?: string | undefined;
}>;
export declare const DeductPointsRequestSchema: z.ZodObject<{
    points: z.ZodNumber;
    categoryType: z.ZodEnum<["FOOD", "LIFESTYLE", "MIXED"]>;
    subCategoryId: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    points: number;
    categoryType: "FOOD" | "LIFESTYLE" | "MIXED";
    subCategoryId?: string | undefined;
}, {
    points: number;
    categoryType: "FOOD" | "LIFESTYLE" | "MIXED";
    subCategoryId?: string | undefined;
}>;
export declare const ErrorResponseSchema: z.ZodObject<{
    error: z.ZodString;
}, "strip", z.ZodTypeAny, {
    error: string;
}, {
    error: string;
}>;
//# sourceMappingURL=schemas.d.ts.map