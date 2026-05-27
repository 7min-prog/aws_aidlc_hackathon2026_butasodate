import { RecordingService } from '../../src/services/recording-service';

jest.mock('../../src/connectors/avatar-connector', () => ({
  addPoints: jest.fn().mockResolvedValue({ totalPoints: 100, level: 2 }),
  deductPoints: jest.fn().mockResolvedValue({ avatarStatus: { totalPoints: 50, level: 1 }, devolutionOccurred: false }),
}));

jest.mock('../../src/services/point-config-cache', () => ({
  getPointConfig: jest.fn().mockResolvedValue(require('../../src/types').DEFAULT_POINT_CONFIG),
}));

const mockSend = jest.fn();
const mockClient = { send: mockSend } as any;

process.env.ACTIVITY_RECORD_TABLE = 'test-records';
process.env.ACTIVITY_CATEGORY_TABLE = 'test-categories';

describe('Recording concurrency (TransactWrite)', () => {
  let service: RecordingService;

  beforeEach(() => {
    service = new RecordingService(mockClient);
    mockSend.mockReset();
  });

  describe('createRecord idempotency via ConditionExpression', () => {
    it('rejects duplicate write with TransactionCanceledException', async () => {
      // getCategory
      mockSend.mockResolvedValueOnce({ Item: { categoryId: 'cat1', type: 'FOOD' } });
      // TransactWriteCommand fails due to condition
      const txError = new Error('ConditionalCheckFailed');
      (txError as any).name = 'TransactionCanceledException';
      mockSend.mockRejectedValueOnce(txError);

      await expect(
        service.createRecord('user-1', { categoryId: 'cat1', recordId: 'dup-id' })
      ).rejects.toThrow();
    });

    it('succeeds on first write (condition met)', async () => {
      mockSend.mockResolvedValueOnce({ Item: { categoryId: 'cat1', type: 'FOOD' } });
      mockSend.mockResolvedValueOnce({}); // TransactWrite success

      const result = await service.createRecord('user-1', { categoryId: 'cat1', recordId: 'new-id' });
      expect(result.record.recordId).toBe('new-id');
    });
  });

  describe('batchCreateRecords duplicate detection', () => {
    it('concurrent duplicate records are skipped via recordExists check', async () => {
      // First record: exists
      mockSend.mockResolvedValueOnce({ Items: [{ recordId: 'r1' }] });
      // Second record: not exists
      mockSend.mockResolvedValueOnce({ Items: [] });
      mockSend.mockResolvedValueOnce({ Item: { categoryId: 'cat1', type: 'FOOD' } });
      mockSend.mockResolvedValueOnce({});

      const result = await service.batchCreateRecords('user-1', [
        { categoryId: 'cat1', recordId: 'r1' },
        { categoryId: 'cat1', recordId: 'r2' },
      ]);

      expect(result.skippedIds).toContain('r1');
      expect(result.syncedRecords).toHaveLength(1);
      expect(result.syncedRecords[0].recordId).toBe('r2');
    });

    it('all duplicates results in zero points awarded', async () => {
      mockSend.mockResolvedValueOnce({ Items: [{ recordId: 'r1' }] });
      mockSend.mockResolvedValueOnce({ Items: [{ recordId: 'r2' }] });

      const result = await service.batchCreateRecords('user-1', [
        { categoryId: 'cat1', recordId: 'r1' },
        { categoryId: 'cat1', recordId: 'r2' },
      ]);

      expect(result.skippedIds).toHaveLength(2);
      expect(result.syncedRecords).toHaveLength(0);
      // avatarStatus returns default when no points added
      expect(result.avatarStatus.totalPoints).toBe(0);
    });
  });

  describe('deleteAutoDetectedRecord concurrency guard', () => {
    it('soft-delete uses UpdateCommand (not Delete) to preserve audit trail', async () => {
      mockSend.mockResolvedValueOnce({
        Items: [{ recordId: 'r1', userId: 'user-1', source: 'AUTO_DETECTED', points: 10, recordedAt: '2026-01-01T00:00:00Z', categoryId: 'auto_steps' }],
      });
      mockSend.mockResolvedValueOnce({}); // UpdateCommand

      const result = await service.deleteAutoDetectedRecord('user-1', 'r1');
      expect(result.success).toBe(true);

      // Verify UpdateCommand was called (not DeleteCommand)
      const updateCall = mockSend.mock.calls[1][0];
      expect(updateCall.input.UpdateExpression).toContain('deleted');
    });
  });
});
