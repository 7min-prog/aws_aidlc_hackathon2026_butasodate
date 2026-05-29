import { AvatarStatus } from '../types';
export declare function addPoints(userId: string, points: number, categoryType: string, subCategoryId?: string): Promise<AvatarStatus>;
export declare function deductPoints(userId: string, points: number, categoryId: string): Promise<{
    avatarStatus: AvatarStatus;
    devolutionOccurred: boolean;
}>;
//# sourceMappingURL=avatar-connector.d.ts.map