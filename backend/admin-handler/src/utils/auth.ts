import { Context, Next } from 'hono';
import { createMiddleware } from 'hono/factory';

const ADMIN_USER = process.env.ADMIN_USER || 'admin';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'password';
const JWT_SECRET = process.env.JWT_SECRET || 'admin-secret-key';

export function generateToken(username: string): string {
  const payload = { sub: username, iat: Date.now(), exp: Date.now() + 8 * 60 * 60 * 1000 };
  return Buffer.from(JSON.stringify(payload)).toString('base64url');
}

export function verifyToken(token: string): { sub: string } | null {
  try {
    const payload = JSON.parse(Buffer.from(token, 'base64url').toString());
    if (payload.exp < Date.now()) return null;
    return payload;
  } catch { return null; }
}

export function validateBasicAuth(user: string, password: string): boolean {
  return user === ADMIN_USER && password === ADMIN_PASSWORD;
}

export const authMiddleware = createMiddleware(async (c: Context, next: Next) => {
  const path = c.req.path;
  if (path === '/admin/login' || path === '/admin/doc') return next();

  const authHeader = c.req.header('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return c.json({ error: 'Unauthorized' }, 401);
  }
  const token = authHeader.slice(7);
  const payload = verifyToken(token);
  if (!payload) return c.json({ error: 'Token expired or invalid' }, 401);
  c.set('operator', payload.sub);
  return next();
});
