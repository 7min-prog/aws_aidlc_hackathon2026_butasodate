import { AvatarStatus } from '../types';

/**
 * Stub for Unit 3 (Avatar) integration.
 * Replace with actual implementation when Unit 3 is complete.
 */
export async function addPoints(
  userId: string,
  points: number,
  categoryType: string
): Promise<AvatarStatus> {
  console.log(`[STUB] addPoints: user=${userId}, points=${points}, type=${categoryType}`);
  return { totalPoints: points, level: 1 };
}

export async function deductPoints(
  userId: string,
  points: number,
  categoryId: string
): Promise<{ avatarStatus: AvatarStatus; devolutionOccurred: boolean }> {
  console.log(`[STUB] deductPoints: user=${userId}, points=${points}, category=${categoryId}`);
  return { avatarStatus: { totalPoints: 0, level: 1 }, devolutionOccurred: false };
}
