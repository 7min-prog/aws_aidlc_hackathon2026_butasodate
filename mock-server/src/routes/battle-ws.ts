import { WebSocketServer, WebSocket } from 'ws';
import { Server } from 'http';
import { v4 as uuid } from 'uuid';
import { skills } from '../store';

interface Player {
  ws: WebSocket;
  userId: string;
  hp: number;
  maxHp: number;
  attack: number;
  defense: number;
  speed: number;
  skills: string[];
}

let waitingPlayer: Player | null = null;

export function setupBattleWs(server: Server) {
  const wss = new WebSocketServer({ server, path: '/ws' });

  wss.on('connection', (ws, req) => {
    const url = new URL(req.url || '', 'http://localhost');
    const userId = url.searchParams.get('userId') || `user-${uuid().slice(0, 4)}`;
    console.log(`[WS] Connected: ${userId}`);

    let player: Player = {
      ws, userId,
      hp: 300, maxHp: 300,
      attack: 40, defense: 30, speed: 25,
      skills: [],
    };

    ws.on('message', (raw) => {
      try {
        const msg = JSON.parse(raw.toString());
        handleMessage(player, msg);
      } catch (e) {
        console.log('[WS] Parse error:', e);
      }
    });

    ws.on('close', () => {
      console.log(`[WS] Disconnected: ${userId}`);
      if (waitingPlayer?.userId === userId) waitingPlayer = null;
    });
  });

  console.log('🎮 Battle WebSocket ready on /ws');
}

function handleMessage(player: Player, msg: any) {
  const { action, data } = msg;

  switch (action) {
    case 'requestMatch':
      handleMatchRequest(player);
      break;
    case 'cancelMatch':
      if (waitingPlayer?.userId === player.userId) waitingPlayer = null;
      break;
    case 'setReady':
      player.skills = data?.skills || [];
      // バトル開始を送信
      sendTo(player.ws, { type: 'battleStart', data: { opponentName: 'AIぶた', turn: 1 } });
      break;
    case 'selectAction':
      handleAction(player, data);
      break;
  }
}

function handleMatchRequest(player: Player) {
  // シングルプレイヤーモック: 即座にAI対戦マッチ
  const matchId = `match-${uuid().slice(0, 8)}`;
  sendTo(player.ws, {
    type: 'matchFound',
    data: {
      matchId,
      player1Id: player.userId,
      player2Id: 'ai-opponent',
      player1Name: 'じぶん',
      player2Name: 'AIぶた',
    },
  });
}

// バトルステート（簡易）
const battles = new Map<string, { player: Player; oppHp: number; oppMaxHp: number; turn: number }>();

function handleAction(player: Player, data: any) {
  const skillId = data?.skillId || 'skill-basic-attack';
  const isDefend = skillId === 'defend';

  // バトルステート取得or作成
  if (!battles.has(player.userId)) {
    battles.set(player.userId, { player, oppHp: 300, oppMaxHp: 300, turn: 1 });
  }
  const state = battles.get(player.userId)!;

  // プレイヤーのダメージ計算
  let playerDmg = 0;
  let oppDmg = 0;

  if (!isDefend) {
    const skill = skills.find(s => s.skillId === skillId);
    const multiplier = skill?.multiplier ?? 1.2;
    playerDmg = Math.round(player.attack * multiplier * (0.8 + Math.random() * 0.4));
  }

  // AI行動（ランダム）
  const aiDefends = Math.random() < 0.2;
  if (!aiDefends) {
    oppDmg = Math.round(35 * 1.3 * (0.8 + Math.random() * 0.4));
    if (isDefend) oppDmg = Math.round(oppDmg * 0.4); // 防御で軽減
  }

  state.oppHp = Math.max(0, state.oppHp - playerDmg);
  player.hp = Math.max(0, player.hp - oppDmg);
  state.turn++;

  const description = isDefend
    ? `ぼうぎょ した！ あいて の こうげき ${oppDmg} ダメージ`
    : `${skills.find(s => s.skillId === skillId)?.name || 'こうげき'} で ${playerDmg} ダメージ！`;

  // ターン結果送信
  sendTo(player.ws, {
    type: 'turnResult',
    data: {
      description,
      battleState: {
        player1: { currentHp: player.hp, maxHp: player.maxHp, hp: player.hp },
        player2: { currentHp: state.oppHp, maxHp: state.oppMaxHp, hp: state.oppHp },
      },
    },
  });

  // 勝敗判定
  if (state.oppHp <= 0) {
    setTimeout(() => {
      sendTo(player.ws, { type: 'battleEnd', data: { winnerId: player.userId, reason: 'KO' } });
      battles.delete(player.userId);
      player.hp = player.maxHp; // リセット
    }, 800);
  } else if (player.hp <= 0) {
    setTimeout(() => {
      sendTo(player.ws, { type: 'battleEnd', data: { winnerId: 'ai-opponent', reason: 'KO' } });
      battles.delete(player.userId);
      player.hp = player.maxHp;
    }, 800);
  } else if (state.turn > 15) {
    setTimeout(() => {
      const winnerId = player.hp >= state.oppHp ? player.userId : 'ai-opponent';
      sendTo(player.ws, { type: 'battleEnd', data: { winnerId, reason: 'TIMEOUT' } });
      battles.delete(player.userId);
      player.hp = player.maxHp;
    }, 800);
  }
}

function sendTo(ws: WebSocket, msg: any) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(msg));
  }
}
