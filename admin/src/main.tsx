import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter, Routes, Route, Navigate, Link, Outlet } from 'react-router-dom';
import { CssBaseline, ThemeProvider, createTheme, AppBar, Toolbar, Typography, Drawer, List, ListItemButton, ListItemText, Box, Button } from '@mui/material';
import { useAuthStore } from './stores/auth';
import { LoginPage } from './pages/LoginPage';
import { UsersPage } from './pages/UsersPage';
import { UserDetailPage } from './pages/UserDetailPage';
import { EvolutionPathsPage } from './pages/EvolutionPathsPage';
import { SkillsPage } from './pages/SkillsPage';
import { GameConfigPage } from './pages/GameConfigPage';
import { AuditLogPage } from './pages/AuditLogPage';

const theme = createTheme({ palette: { mode: 'light', primary: { main: '#e91e63' } } });
const DRAWER_WIDTH = 220;

function ProtectedRoute() {
  const token = useAuthStore((s) => s.token);
  if (!token) return <Navigate to="/login" />;
  return <Layout />;
}

function Layout() {
  const logout = useAuthStore((s) => s.logout);
  const nav = [
    { label: 'ユーザー管理', path: '/users' },
    { label: '進化パス', path: '/evolution-paths' },
    { label: 'スキル', path: '/skills' },
    { label: 'ゲーム設定', path: '/game-config' },
    { label: '操作ログ', path: '/audit-log' },
  ];
  return (
    <Box display="flex">
      <AppBar position="fixed" sx={{ zIndex: (t) => t.zIndex.drawer + 1 }}>
        <Toolbar>
          <Typography variant="h6" flexGrow={1}>ぶたそだて 管理画面</Typography>
          <Button color="inherit" onClick={logout}>ログアウト</Button>
        </Toolbar>
      </AppBar>
      <Drawer variant="permanent" sx={{ width: DRAWER_WIDTH, '& .MuiDrawer-paper': { width: DRAWER_WIDTH, boxSizing: 'border-box' } }}>
        <Toolbar />
        <List>
          {nav.map((n) => (
            <ListItemButton key={n.path} component={Link} to={n.path}>
              <ListItemText primary={n.label} />
            </ListItemButton>
          ))}
        </List>
      </Drawer>
      <Box component="main" sx={{ flexGrow: 1, p: 3, mt: 8 }}>
        <Outlet />
      </Box>
    </Box>
  );
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route element={<ProtectedRoute />}>
            <Route path="/" element={<Navigate to="/users" />} />
            <Route path="/users" element={<UsersPage />} />
            <Route path="/users/:username" element={<UserDetailPage />} />
            <Route path="/evolution-paths" element={<EvolutionPathsPage />} />
            <Route path="/skills" element={<SkillsPage />} />
            <Route path="/game-config" element={<GameConfigPage />} />
            <Route path="/audit-log" element={<AuditLogPage />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </ThemeProvider>
  </React.StrictMode>,
);
