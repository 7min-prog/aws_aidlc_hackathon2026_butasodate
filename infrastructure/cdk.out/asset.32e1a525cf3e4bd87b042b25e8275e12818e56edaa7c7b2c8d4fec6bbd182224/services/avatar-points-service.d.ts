export interface AvatarPointsResult {
    totalPoints: number;
    level: number;
    evolutionStage: number;
    currentSpeciesId: string | null;
    leveledUp: boolean;
    evolved: boolean;
    devolved: boolean;
}
export declare function addPoints(userId: string, points: number, categoryType: string, subCategoryId?: string): Promise<AvatarPointsResult>;
export declare function deductPoints(userId: string, points: number, categoryType: string, subCategoryId?: string): Promise<AvatarPointsResult & {
    devolved: boolean;
}>;
//# sourceMappingURL=avatar-points-service.d.ts.map