import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({ region: 'ap-northeast-1' });
export const dynamoClient = DynamoDBDocumentClient.from(client);

export const CONNECTIONS_TABLE = process.env.CONNECTIONS_TABLE || 'buta-connections-dev';
export const MATCH_QUEUE_TABLE = process.env.MATCH_QUEUE_TABLE || 'buta-match-queue-dev';
export const MATCHES_TABLE = process.env.MATCHES_TABLE || 'buta-matches-dev';
export const BATTLE_HISTORY_TABLE = process.env.BATTLE_HISTORY_TABLE || 'buta-battle-history-dev';
export const RANKINGS_TABLE = process.env.RANKINGS_TABLE || 'buta-rankings-dev';
export const SKILLS_TABLE = process.env.SKILLS_TABLE || 'butasodate-skills';
