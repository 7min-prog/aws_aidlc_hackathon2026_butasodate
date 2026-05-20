import { ScanCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, EVOLUTION_PATH_TABLE, SKILL_TABLE } from '../utils/dynamo-client';
import { EvolutionPath, Skill } from '../types';

let cachedPaths: EvolutionPath[] | null = null;
let cachedSkills: Skill[] | null = null;

export async function getEvolutionPaths(): Promise<EvolutionPath[]> {
  if (cachedPaths) return cachedPaths;
  const result = await docClient.send(new ScanCommand({ TableName: EVOLUTION_PATH_TABLE }));
  cachedPaths = (result.Items || []) as EvolutionPath[];
  return cachedPaths;
}

export async function getSkills(): Promise<Skill[]> {
  if (cachedSkills) return cachedSkills;
  const result = await docClient.send(new ScanCommand({ TableName: SKILL_TABLE }));
  cachedSkills = (result.Items || []) as Skill[];
  return cachedSkills;
}
