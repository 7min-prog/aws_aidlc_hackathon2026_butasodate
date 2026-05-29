const API_BASE = import.meta.env.VITE_API_BASE || '/api';

async function request(path: string, options: RequestInit = {}) {
  const token = localStorage.getItem('admin_token');
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });
  if (res.status === 401) {
    localStorage.removeItem('admin_token');
    window.location.href = '/login';
  }
  return res.json();
}

export const api = {
  login: (user: string, password: string) => request('/admin/login', { method: 'POST', body: JSON.stringify({ user, password }) }),
  getUsers: (limit?: number, token?: string) => request(`/admin/users?limit=${limit || 20}${token ? `&token=${token}` : ''}`),
  getUser: (username: string) => request(`/admin/users/${username}`),
  disableUser: (username: string) => request(`/admin/users/${username}/disable`, { method: 'POST' }),
  enableUser: (username: string) => request(`/admin/users/${username}/enable`, { method: 'POST' }),
  deleteUser: (username: string) => request(`/admin/users/${username}`, { method: 'DELETE' }),
  updateAvatar: (username: string, data: unknown) => request(`/admin/users/${username}/avatar`, { method: 'PUT', body: JSON.stringify(data) }),
  addHealthData: (username: string, data: unknown) => request(`/admin/users/${username}/health-data`, { method: 'POST', body: JSON.stringify(data) }),
  getPaths: () => request('/admin/evolution-paths'),
  createPath: (data: unknown) => request('/admin/evolution-paths', { method: 'POST', body: JSON.stringify(data) }),
  updatePath: (pathId: string, data: unknown) => request(`/admin/evolution-paths/${pathId}`, { method: 'PUT', body: JSON.stringify(data) }),
  deletePath: (pathId: string) => request(`/admin/evolution-paths/${pathId}`, { method: 'DELETE' }),
  getSkills: () => request('/admin/skills'),
  createSkill: (data: unknown) => request('/admin/skills', { method: 'POST', body: JSON.stringify(data) }),
  updateSkill: (skillId: string, data: unknown) => request(`/admin/skills/${skillId}`, { method: 'PUT', body: JSON.stringify(data) }),
  deleteSkill: (skillId: string) => request(`/admin/skills/${skillId}`, { method: 'DELETE' }),
  getRoutes: () => request('/admin/evolution-routes'),
  createRoute: (data: unknown) => request('/admin/evolution-routes', { method: 'POST', body: JSON.stringify(data) }),
  updateRoute: (routeId: string, data: unknown) => request(`/admin/evolution-routes/${routeId}`, { method: 'PUT', body: JSON.stringify(data) }),
  deleteRoute: (routeId: string) => request(`/admin/evolution-routes/${routeId}`, { method: 'DELETE' }),
  getConfig: () => request('/admin/game-config'),
  updateConfig: (configKey: string, value: unknown) => request('/admin/game-config', { method: 'PUT', body: JSON.stringify({ configKey, value }) }),
  getAuditLog: (limit?: number) => request(`/admin/audit-log?limit=${limit || 50}`),
  getUploadUrl: (fileName: string, contentType: string) => request('/admin/upload-url', { method: 'POST', body: JSON.stringify({ fileName, contentType }) }),
};
