import { PutCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, AUDIT_LOG_TABLE } from './dynamo-client';

export async function writeAuditLog(
  operator: string, action: string, target: string, detail?: Record<string, unknown>,
): Promise<void> {
  const timestamp = new Date().toISOString();
  const logId = `${timestamp}-${Math.random().toString(36).slice(2, 10)}`;
  await docClient.send(new PutCommand({
    TableName: AUDIT_LOG_TABLE,
    Item: { logId, timestamp, operator, action, target, detail: detail || {} },
  }));
}
