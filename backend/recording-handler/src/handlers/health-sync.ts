import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { docClient } from '../utils/dynamo-client';
import { getUserId } from '../utils/auth';
import { success, error } from '../utils/response';
import { HealthSyncService } from '../services/health-sync-service';

const service = new HealthSyncService(docClient);

export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
  try {
    const userId = getUserId(event);
    const body = JSON.parse(event.body || '{}');
    const result = await service.syncHealthData(userId, body.records || []);
    return success(result);
  } catch (err: any) {
    console.error(err);
    if (err.message === 'Unauthorized') return error('Unauthorized', 401);
    return error('Internal Server Error', 500);
  }
}
