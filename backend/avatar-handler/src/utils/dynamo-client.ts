import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
export const docClient = DynamoDBDocumentClient.from(client, {
  marshallOptions: { removeUndefinedValues: true },
});

export const AVATAR_TABLE = process.env.AVATAR_TABLE_NAME!;
export const EVOLUTION_HISTORY_TABLE = process.env.EVOLUTION_HISTORY_TABLE_NAME!;
export const EVOLUTION_PATH_TABLE = process.env.EVOLUTION_PATH_TABLE_NAME!;
export const SKILL_TABLE = process.env.SKILL_TABLE_NAME!;
