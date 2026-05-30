import { ScanCommand } from '@aws-sdk/lib-dynamodb';
import { docClient } from '../utils/dynamo-client';
import { PointConfig, DEFAULT_POINT_CONFIG } from '../types';

const GAME_CONFIG_TABLE = process.env.GAME_CONFIG_TABLE_NAME;

let cached: PointConfig | null = null;

export async function getPointConfig(): Promise<PointConfig> {
  if (cached) return cached;
  const config = { ...DEFAULT_POINT_CONFIG };
  if (GAME_CONFIG_TABLE) {
    const result = await docClient.send(new ScanCommand({ TableName: GAME_CONFIG_TABLE }));
    for (const item of result.Items || []) {
      if (item.configKey in config) {
        (config as any)[item.configKey] = item.value;
      }
    }
  }
  cached = config;
  return cached;
}

export function resetPointConfigCache(): void {
  cached = null;
}
