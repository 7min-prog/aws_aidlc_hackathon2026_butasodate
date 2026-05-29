import { RecordingService } from '../../src/services/recording-service';
import { CategoryType } from '../../src/types';

// Mock avatar-connector
jest.mock('../../src/connectors/avatar-connector', () => ({
  addPoints: jest.fn().mockResolvedValue({ totalPoints: 100, level: 2 }),
  deductPoints: jest.fn().mockResolvedValue({ avatarStatus: { totalPoints: 50, level: 1 }, devolutionOccurred: false }),
}));

jest.mock('../../src/services/point-config-cache', () => ({
  getPointConfig: jest.fn().mockResolvedValue(require('../../src/types').DEFAULT_POINT_CONFIG),
}));

const mockSend = jest.fn();
const mockClient = { send: mockSend } as any;

// Set env vars
process.env.ACTIVITY_RECORD_TABLE = 'test-records';
process.env.ACTIVITY_CATEGORY_TABLE = 'test-categories';

describe('RecordingService', () => {
  let service: RecordingService;

  beforeEach(() => {
    service = new RecordingService(mockClient);
    mockSend.mockReset();
  });

  describe('createRecord', () => {
    it('creates a record and returns avatar status', async () => {
      // getCategory
      mockSend.mockResolvedValueOnce({ Item: { categoryId: 'cat1', type: 'FOOD', basePoints: 10 } });
      // TransactWriteCommand
      mockSend.mockResolvedValueOnce({});

      const result = await service.createRecord('user-1', {
        categoryId: 'cat1',
        memo: 'テストメモ',
      });

      expect(result.record.userId).toBe('user-1');
      expect(result.record.categoryId).toBe('cat1');
      expect(result.record.memo).toBe('テストメモ');
      expect(result.avatarStatus.totalPoints).toBe(100);
    });

    it('throws when category not found', async () => {
      mockSend.mockResolvedValueOnce({ Item: undefined });

      await expect(
        service.createRecord('user-1', { categoryId: 'invalid' })
      ).rejects.toThrow('Category not found');
    });
  });

  describe('batchCreateRecords', () => {
    it('creates multiple records and sums points', async () => {
      // First record: recordExists check + getCategory + PutCommand
      mockSend.mockResolvedValueOnce({ Items: [] }); // recordExists
      mockSend.mockResolvedValueOnce({ Item: { categoryId: 'cat1', type: 'FOOD' } });
      mockSend.mockResolvedValueOnce({}); // PutCommand
      // Second record
      mockSend.mockResolvedValueOnce({ Items: [] });
      mockSend.mockResolvedValueOnce({ Item: { categoryId: 'cat2', type: 'LIFESTYLE' } });
      mockSend.mockResolvedValueOnce({});

      const result = await service.batchCreateRecords('user-1', [
        { categoryId: 'cat1' },
        { categoryId: 'cat2' },
      ]);

      expect(result.syncedRecords).toHaveLength(2);
      expect(result.skippedIds).toHaveLength(0);
    });

    it('skips duplicate records', async () => {
      // recordExists returns existing
      mockSend.mockResolvedValueOnce({ Items: [{ recordId: 'dup-1' }] });

      const result = await service.batchCreateRecords('user-1', [
        { categoryId: 'cat1', recordId: 'dup-1' },
      ]);

      expect(result.syncedRecords).toHaveLength(0);
      expect(result.skippedIds).toContain('dup-1');
    });
  });

  describe('getRecords', () => {
    it('returns paginated records', async () => {
      mockSend.mockResolvedValue({
        Items: [{ recordId: 'r1', userId: 'user-1', points: 10 }],
        LastEvaluatedKey: { userId: 'user-1', sk: 'cursor-key' },
      });

      const result = await service.getRecords('user-1', 20);

      expect(result.items).toHaveLength(1);
      expect(result.nextCursor).toBeDefined();
    });

    it('returns empty with no cursor when no results', async () => {
      mockSend.mockResolvedValue({ Items: [], LastEvaluatedKey: undefined });

      const result = await service.getRecords('user-1', 20);

      expect(result.items).toHaveLength(0);
      expect(result.nextCursor).toBeUndefined();
    });

    it('filters by categoryId when provided', async () => {
      mockSend.mockResolvedValue({ Items: [] });

      await service.getRecords('user-1', 20, undefined, 'cat1');

      const queryParams = mockSend.mock.calls[0][0].input;
      expect(queryParams.IndexName).toBe('category-index');
    });

    it('applies date filters', async () => {
      mockSend.mockResolvedValue({ Items: [] });

      await service.getRecords('user-1', 20, undefined, undefined, '2026-01-01', '2026-01-31');

      const queryParams = mockSend.mock.calls[0][0].input;
      expect(queryParams.FilterExpression).toContain('recordedAt >= :from');
      expect(queryParams.FilterExpression).toContain('recordedAt <= :to');
    });
  });

  describe('deleteAutoDetectedRecord', () => {
    it('soft-deletes auto-detected record and deducts points', async () => {
      mockSend.mockResolvedValueOnce({
        Items: [{ recordId: 'r1', userId: 'user-1', source: 'AUTO_DETECTED', points: 10, recordedAt: '2026-01-01T00:00:00Z', categoryId: 'auto_steps' }],
      });
      mockSend.mockResolvedValueOnce({}); // UpdateCommand

      const result = await service.deleteAutoDetectedRecord('user-1', 'r1');

      expect(result.success).toBe(true);
      expect(result.devolutionOccurred).toBe(false);
    });

    it('throws when record not found', async () => {
      mockSend.mockResolvedValueOnce({ Items: [] });

      await expect(
        service.deleteAutoDetectedRecord('user-1', 'nonexistent')
      ).rejects.toThrow('Record not found');
    });

    it('throws when record is not auto-detected', async () => {
      mockSend.mockResolvedValueOnce({
        Items: [{ recordId: 'r1', userId: 'user-1', source: 'MANUAL', points: 10, recordedAt: '2026-01-01T00:00:00Z' }],
      });

      await expect(
        service.deleteAutoDetectedRecord('user-1', 'r1')
      ).rejects.toThrow('Only auto-detected records can be deleted');
    });
  });

  describe('getSummary', () => {
    it('returns today summary', async () => {
      const today = new Date().toISOString().split('T')[0];
      mockSend.mockResolvedValue({
        Items: [
          { recordId: 'r1', points: 10, recordedAt: `${today}T10:00:00Z`, categoryId: 'cat1' },
          { recordId: 'r2', points: 15, recordedAt: `${today}T11:00:00Z`, categoryId: 'cat2' },
        ],
      });

      const result = await service.getSummary('user-1', 'today');

      expect(result.todayCount).toBe(2);
      expect(result.todayPoints).toBe(25);
    });

    it('returns week summary with category breakdown', async () => {
      const today = new Date().toISOString().split('T')[0];
      mockSend.mockResolvedValue({
        Items: [
          { recordId: 'r1', points: 10, recordedAt: `${today}T10:00:00Z`, categoryId: 'cat1' },
          { recordId: 'r2', points: 20, recordedAt: `${today}T11:00:00Z`, categoryId: 'cat1' },
          { recordId: 'r3', points: 5, recordedAt: `${today}T12:00:00Z`, categoryId: 'cat2' },
        ],
      });

      const result = await service.getSummary('user-1', 'week');

      expect(result.weekSummary).toBeDefined();
      expect(result.weekSummary).toHaveLength(2);
    });
  });
});
