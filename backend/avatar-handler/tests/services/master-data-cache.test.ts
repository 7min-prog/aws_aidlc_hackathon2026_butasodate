const mockSend = jest.fn();
jest.mock('../../src/utils/dynamo-client', () => ({
  docClient: { send: (...args: any[]) => mockSend(...args) },
  PIG_SPECIES_TABLE: 'test-species',
  EVOLUTION_ROUTE_TABLE: 'test-routes',
  SKILL_TABLE: 'test-skills',
  GAME_CONFIG_TABLE: 'test-config',
}));

// Must re-import after mock to reset module-level cache
let getPigSpecies: typeof import('../../src/services/master-data-cache').getPigSpecies;
let getEvolutionRoutes: typeof import('../../src/services/master-data-cache').getEvolutionRoutes;
let getSkills: typeof import('../../src/services/master-data-cache').getSkills;
let getGameConfig: typeof import('../../src/services/master-data-cache').getGameConfig;

beforeEach(() => {
  jest.resetModules();
  jest.mock('../../src/utils/dynamo-client', () => ({
    docClient: { send: (...args: any[]) => mockSend(...args) },
    PIG_SPECIES_TABLE: 'test-species',
    EVOLUTION_ROUTE_TABLE: 'test-routes',
    SKILL_TABLE: 'test-skills',
    GAME_CONFIG_TABLE: 'test-config',
  }));
  mockSend.mockReset();
  const mod = require('../../src/services/master-data-cache');
  getPigSpecies = mod.getPigSpecies;
  getEvolutionRoutes = mod.getEvolutionRoutes;
  getSkills = mod.getSkills;
  getGameConfig = mod.getGameConfig;
});

describe('master-data-cache', () => {
  describe('getPigSpecies', () => {
    it('fetches from DynamoDB on first call', async () => {
      const species = [{ speciesId: 'kobuta', name: 'こぶた' }];
      mockSend.mockResolvedValueOnce({ Items: species });
      const result = await getPigSpecies();
      expect(result).toEqual(species);
      expect(mockSend).toHaveBeenCalledTimes(1);
    });

    it('returns cached data on subsequent calls', async () => {
      mockSend.mockResolvedValueOnce({ Items: [{ speciesId: 'kobuta' }] });
      await getPigSpecies();
      await getPigSpecies();
      expect(mockSend).toHaveBeenCalledTimes(1);
    });

    it('returns empty array when no items', async () => {
      mockSend.mockResolvedValueOnce({ Items: undefined });
      const result = await getPigSpecies();
      expect(result).toEqual([]);
    });
  });

  describe('getEvolutionRoutes', () => {
    it('fetches and caches evolution routes', async () => {
      const routes = [{ routeId: 'r1', fromSpeciesId: 'kobuta', toSpeciesId: 'marumaru' }];
      mockSend.mockResolvedValueOnce({ Items: routes });
      const result = await getEvolutionRoutes();
      expect(result).toEqual(routes);
      await getEvolutionRoutes();
      expect(mockSend).toHaveBeenCalledTimes(1);
    });
  });

  describe('getSkills', () => {
    it('fetches and caches skills', async () => {
      const skills = [{ skillId: 'sk1', name: 'タックル' }];
      mockSend.mockResolvedValueOnce({ Items: skills });
      const result = await getSkills();
      expect(result).toEqual(skills);
      await getSkills();
      expect(mockSend).toHaveBeenCalledTimes(1);
    });
  });

  describe('getGameConfig', () => {
    it('returns default config when no items in DB', async () => {
      mockSend.mockResolvedValueOnce({ Items: [] });
      const config = await getGameConfig();
      expect(config.MAX_LEVEL).toBe(30);
      expect(config.INITIAL_STATS).toEqual({ hp: 50, attack: 10, defense: 10, speed: 10 });
    });

    it('overrides defaults with DB values', async () => {
      mockSend.mockResolvedValueOnce({
        Items: [
          { configKey: 'MAX_LEVEL', value: 50 },
          { configKey: 'CATEGORY_THRESHOLD', value: 0.8 },
        ],
      });
      const config = await getGameConfig();
      expect(config.MAX_LEVEL).toBe(50);
      expect(config.CATEGORY_THRESHOLD).toBe(0.8);
      expect(config.EVOLUTION_LEVEL_STAGE2).toBe(5); // unchanged default
    });

    it('caches config after first call', async () => {
      mockSend.mockResolvedValueOnce({ Items: [] });
      await getGameConfig();
      await getGameConfig();
      expect(mockSend).toHaveBeenCalledTimes(1);
    });
  });
});
