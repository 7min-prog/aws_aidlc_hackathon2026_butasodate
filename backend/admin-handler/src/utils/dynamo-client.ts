import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
export const docClient = DynamoDBDocumentClient.from(client, {
  marshallOptions: { removeUndefinedValues: true },
});

export const AVATAR_TABLE = process.env.AVATAR_TABLE_NAME!;
export const EVOLUTION_PATH_TABLE = process.env.EVOLUTION_PATH_TABLE_NAME!;
export const SKILL_TABLE = process.env.SKILL_TABLE_NAME!;
export const AUDIT_LOG_TABLE = process.env.AUDIT_LOG_TABLE_NAME!;
export const GAME_CONFIG_TABLE = process.env.GAME_CONFIG_TABLE_NAME!;
export const RECORDING_TABLE = process.env.RECORDING_TABLE_NAME!;
