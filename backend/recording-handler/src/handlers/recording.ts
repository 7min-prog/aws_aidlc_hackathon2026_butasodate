import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { docClient } from '../utils/dynamo-client';
import { getUserId } from '../utils/auth';
import { success, error } from '../utils/response';
import { RecordingService } from '../services/recording-service';

const service = new RecordingService(docClient);

export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
  try {
    const userId = getUserId(event);
    const method = event.httpMethod;
    const path = event.resource;

    if (method === 'POST' && path === '/activities') {
      const body = JSON.parse(event.body || '{}');
      const result = await service.createRecord(userId, body);
      return success(result, 201);
    }

    if (method === 'POST' && path === '/activities/batch') {
      const body = JSON.parse(event.body || '{}');
      const result = await service.batchCreateRecords(userId, body.records || []);
      return success(result);
    }

    if (method === 'GET' && path === '/activities') {
      const params = event.queryStringParameters || {};
      const result = await service.getRecords(
        userId,
        parseInt(params.limit || '20'),
        params.cursor || undefined,
        params.categoryId || undefined,
        params.from || undefined,
        params.to || undefined
      );
      return success(result);
    }

    if (method === 'DELETE' && path === '/activities/{recordId}') {
      const recordId = event.pathParameters?.recordId;
      if (!recordId) return error('recordId required', 400);
      const result = await service.deleteAutoDetectedRecord(userId, recordId);
      return success(result);
    }

    if (method === 'GET' && path === '/activities/summary') {
      const period = (event.queryStringParameters?.period || 'today') as 'today' | 'week';
      const result = await service.getSummary(userId, period);
      return success(result);
    }

    return error('Not Found', 404);
  } catch (err: any) {
    console.error(err);
    if (err.message === 'Unauthorized') return error('Unauthorized', 401);
    if (err.message === 'Record not found') return error('Record not found', 404);
    if (err.message === 'Only auto-detected records can be deleted') return error(err.message, 403);
    return error('Internal Server Error', 500);
  }
}
