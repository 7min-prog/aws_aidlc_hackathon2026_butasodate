import app from './app';
import { createServer } from 'http';
import { setupBattleWs } from './routes/battle-ws';

const PORT = process.env.PORT || 3000;

const server = createServer(app);
setupBattleWs(server);

server.listen(Number(PORT), '0.0.0.0', () => {
  console.log(`🐷 ぶたそだて Mock Server running on http://0.0.0.0:${PORT}`);
});
