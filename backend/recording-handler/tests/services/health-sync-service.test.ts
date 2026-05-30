import { HealthSyncService } from '../../src/services/health-sync-service';
import { HealthCategory, HealthEvaluation, DEFAULT_POINT_CONFIG } from '../../src/types';

jest.mock('../../src/connectors/avatar-connector', () => ({
  addPoints: jest.fn().mockResolvedValue({ totalPoints: 200, level: 3 }),
}));

jest.mock('../../src/services/point-config-cache', () => ({
  getPointConfig: jest.fn().mockResolvedValue(require('../../src/types').DEFAULT_POINT_CONFIG),
}));

const mockSend = jest.fn();
const mockClient = { send: mockSend } as any;

process.env.HEALTH_SYNC_TABLE = 'test-health-sync';
process.env.ACTIVITY_RECORD_TABLE = 'test-records';

describe('HealthSyncService', () => {
  let service: HealthSyncService;

  beforeEach(() => {
    service = new HealthSyncService(mockClient);
    mockSend.mockReset();
  });

  describe('syncHealthData', () => {
    it('syncs steps data and awards points', async () => {
      // recordExists check
      mockSend.mockResolvedValueOnce({ Item: undefined });
      // TransactWriteCommand
      mockSend.mockResolvedValueOnce({});

      const result = await service.syncHealthData('user-1', [
        { category: HealthCategory.STEPS, syncDate: '2026-05-25', rawValue: 10000 },
      ]);

      expect(result.syncResults).toHaveLength(1);
      expect(result.syncResults[0].skipped).toBe(false);
      expect(result.syncResults[0].category).toBe(HealthCategory.STEPS);
      expect(typeof result.totalPoints).toBe('number');
    });

    it('skips already synced dates', async () => {
      // recordExists returns true
      mockSend.mockResolvedValueOnce({ Item: { syncId: 'existing' } });

      const result = await service.syncHealthData('user-1', [
        { category: HealthCategory.STEPS, syncDate: '2026-05-25', rawValue: 8000 },
      ]);

      expect(result.syncResults[0].skipped).toBe(true);
      expect(result.skippedDates).toContain('2026-05-25#STEPS');
      expect(result.totalPoints).toBe(0);
    });

    it('syncs weight data with previous value comparison', async () => {
      // recordExists
      mockSend.mockResolvedValueOnce({ Item: undefined });
      // getPreviousWeight
      mockSend.mockResolvedValueOnce({ Item: { value: 75.0 } });
      // TransactWriteCommand
      mockSend.mockResolvedValueOnce({});

      const result = await service.syncHealthData('user-1', [
        { category: HealthCategory.WEIGHT, syncDate: '2026-05-25', rawValue: 74.5 },
      ]);

      expect(result.syncResults).toHaveLength(1);
      expect(result.syncResults[0].category).toBe(HealthCategory.WEIGHT);
    });

    it('syncs sleep data with secondary value', async () => {
      // recordExists
      mockSend.mockResolvedValueOnce({ Item: undefined });
      // TransactWriteCommand
      mockSend.mockResolvedValueOnce({});

      const result = await service.syncHealthData('user-1', [
        { category: HealthCategory.SLEEP, syncDate: '2026-05-25', rawValue: 23.5, secondaryValue: 7.5 },
      ]);

      expect(result.syncResults).toHaveLength(1);
      expect(result.syncResults[0].category).toBe(HealthCategory.SLEEP);
    });

    it('handles multiple data points with mixed results', async () => {
      // First: steps - new
      mockSend.mockResolvedValueOnce({ Item: undefined });
      mockSend.mockResolvedValueOnce({});
      // Second: weight - already synced
      mockSend.mockResolvedValueOnce({ Item: { syncId: 'existing' } });

      const result = await service.syncHealthData('user-1', [
        { category: HealthCategory.STEPS, syncDate: '2026-05-25', rawValue: 12000 },
        { category: HealthCategory.WEIGHT, syncDate: '2026-05-25', rawValue: 70 },
      ]);

      expect(result.syncResults).toHaveLength(2);
      expect(result.syncResults[0].skipped).toBe(false);
      expect(result.syncResults[1].skipped).toBe(true);
    });

    it('returns zero avatar status when no points awarded', async () => {
      // All skipped
      mockSend.mockResolvedValueOnce({ Item: { syncId: 'existing' } });

      const result = await service.syncHealthData('user-1', [
        { category: HealthCategory.STEPS, syncDate: '2026-05-25', rawValue: 5000 },
      ]);

      expect(result.avatarStatus).toEqual({ totalPoints: 0, level: 1 });
    });
  });
});
