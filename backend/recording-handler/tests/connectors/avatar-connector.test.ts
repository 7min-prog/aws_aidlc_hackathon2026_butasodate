jest.mock('../../src/services/avatar-points-service', () => ({
  addPoints: jest.fn(),
  deductPoints: jest.fn(),
}));

import { addPoints, deductPoints } from '../../src/connectors/avatar-connector';
import { addPoints as mockAddPoints, deductPoints as mockDeductPoints } from '../../src/services/avatar-points-service';

describe('avatar-connector', () => {
  beforeEach(() => jest.clearAllMocks());

  describe('addPoints', () => {
    it('delegates to avatar-points-service and returns mapped result', async () => {
      (mockAddPoints as jest.Mock).mockResolvedValue({ totalPoints: 250, level: 5 });
      const result = await addPoints('user-1', 50, 'FOOD', 'ramen');
      expect(mockAddPoints).toHaveBeenCalledWith('user-1', 50, 'FOOD', 'ramen');
      expect(result).toEqual({ totalPoints: 250, level: 5 });
    });

    it('works without subCategoryId', async () => {
      (mockAddPoints as jest.Mock).mockResolvedValue({ totalPoints: 100, level: 2 });
      const result = await addPoints('user-1', 10, 'LIFESTYLE');
      expect(mockAddPoints).toHaveBeenCalledWith('user-1', 10, 'LIFESTYLE', undefined);
      expect(result).toEqual({ totalPoints: 100, level: 2 });
    });

    it('propagates errors from service', async () => {
      (mockAddPoints as jest.Mock).mockRejectedValue(new Error('DDB failure'));
      await expect(addPoints('user-1', 10, 'FOOD')).rejects.toThrow('DDB failure');
    });
  });

  describe('deductPoints', () => {
    it('delegates to avatar-points-service and maps result', async () => {
      (mockDeductPoints as jest.Mock).mockResolvedValue({ totalPoints: 80, level: 3, devolved: false });
      const result = await deductPoints('user-1', 20, 'food_rice');
      expect(mockDeductPoints).toHaveBeenCalledWith('user-1', 20, 'FOOD', 'food_rice');
      expect(result).toEqual({ avatarStatus: { totalPoints: 80, level: 3 }, devolutionOccurred: false });
    });

    it('returns devolutionOccurred true when devolution happens', async () => {
      (mockDeductPoints as jest.Mock).mockResolvedValue({ totalPoints: 10, level: 1, devolved: true });
      const result = await deductPoints('user-1', 100, 'food_snack');
      expect(result.devolutionOccurred).toBe(true);
    });

    it('propagates errors from service', async () => {
      (mockDeductPoints as jest.Mock).mockRejectedValue(new Error('timeout'));
      await expect(deductPoints('user-1', 10, 'cat1')).rejects.toThrow('timeout');
    });
  });
});
