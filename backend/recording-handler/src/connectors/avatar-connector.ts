import { addPoints as avatarAddPoints, deductPoints as avatarDeductPoints, AvatarPointsResult } from '../services/avatar-points-service';
import { AvatarStatus } from '../types';

export async function addPoints(
  userId: string,
  points: number,
  categoryType: string,
  subCategoryId?: string,
): Promise<AvatarStatus> {
  const result = await avatarAddPoints(userId, points, categoryType, subCategoryId);
  return { totalPoints: result.totalPoints, level: result.level };
}

export async function deductPoints(
  userId: string,
  points: number,
  categoryId: string,
): Promise<{ avatarStatus: AvatarStatus; devolutionOccurred: boolean }> {
  const result = await avatarDeductPoints(userId, points, 'FOOD', categoryId);
  return { avatarStatus: { totalPoints: result.totalPoints, level: result.level }, devolutionOccurred: result.devolved };
}
