import { Avatar, AddPointsResult, DeductPointsResult, CategoryType, EvolutionHistory } from '../types';
export declare function createAvatar(userId: string, name?: string): Promise<Avatar>;
export declare function getAvatar(userId: string): Promise<Avatar | null>;
export declare function addPoints(userId: string, points: number, categoryType: CategoryType, subCategoryId?: string): Promise<AddPointsResult>;
export declare function deductPoints(userId: string, points: number, categoryType: CategoryType, subCategoryId?: string): Promise<DeductPointsResult>;
export declare function getEvolutionHistory(userId: string): Promise<EvolutionHistory[]>;
//# sourceMappingURL=avatar-service.d.ts.map