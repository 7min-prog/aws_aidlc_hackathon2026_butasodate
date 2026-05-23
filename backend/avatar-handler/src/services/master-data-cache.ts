import { ScanCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, PIG_SPECIES_TABLE, EVOLUTION_ROUTE_TABLE, SKILL_TABLE, GAME_CONFIG_TABLE } from '../utils/dynamo-client';
import { PigSpecies, EvolutionRoute, Skill, GameConfig } from '../types';

let cachedSpecies: PigSpecies[] | null = null;
let cachedRoutes: EvolutionRoute[] | null = null;
let cachedSkills: Skill[] | null = null;
let cachedConfig: GameConfig | null = null;

export async function getPigSpecies(): Promise<PigSpecies[]> {
  if (cachedSpecies) return cachedSpecies;
  const result = await docClient.send(new ScanCommand({ TableName: PIG_SPECIES_TABLE }));
  cachedSpecies = (result.Items || []) as PigSpecies[];
  return cachedSpecies;
}

export async function getEvolutionRoutes(): Promise<EvolutionRoute[]> {
  if (cachedRoutes) return cachedRoutes;
  const result = await docClient.send(new ScanCommand({ TableName: EVOLUTION_ROUTE_TABLE }));
  cachedRoutes = (result.Items || []) as EvolutionRoute[];
  return cachedRoutes;
}

export async function getSkills(): Promise<Skill[]> {
  if (cachedSkills) return cachedSkills;
  const result = await docClient.send(new ScanCommand({ TableName: SKILL_TABLE }));
  cachedSkills = (result.Items || []) as Skill[];
  return cachedSkills;
}

export async function getGameConfig(): Promise<GameConfig> {
  if (cachedConfig) return cachedConfig;
  const result = await docClient.send(new ScanCommand({ TableName: GAME_CONFIG_TABLE }));
  const items = result.Items || [];
  const config: GameConfig = {
    INITIAL_STATS: { hp: 50, attack: 10, defense: 10, speed: 10 },
    MAX_LEVEL: 30,
    EVOLUTION_LEVEL_STAGE2: 5,
    EVOLUTION_LEVEL_STAGE3: 15,
    CATEGORY_THRESHOLD: 0.6,
    LEVEL_FORMULA_COEFFICIENT: 50,
  };
  for (const item of items) {
    if (item.configKey in config) {
      (config as Record<string, unknown>)[item.configKey] = item.value;
    }
  }
  cachedConfig = config;
  return cachedConfig;
}
