import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Box, Button, TextField, Typography, Paper, Alert } from '@mui/material';
import { useAuthStore } from '../stores/auth';
import { api } from '../api/client';

export function LoginPage() {
  const [user, setUser] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const login = useAuthStore((s) => s.login);
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    const res = await api.login(user, password);
    if (res.token) { login(res.token); navigate('/'); }
    else { setError('ログインに失敗しました'); }
  };

  return (
    <Box display="flex" justifyContent="center" alignItems="center" minHeight="100vh">
      <Paper sx={{ p: 4, maxWidth: 400, width: '100%' }}>
        <Typography variant="h5" mb={3}>ぶたそだて 管理画面</Typography>
        {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
        <form onSubmit={handleSubmit}>
          <TextField fullWidth label="ユーザー名" value={user} onChange={(e) => setUser(e.target.value)} margin="normal" />
          <TextField fullWidth label="パスワード" type="password" value={password} onChange={(e) => setPassword(e.target.value)} margin="normal" />
          <Button fullWidth variant="contained" type="submit" sx={{ mt: 2 }}>ログイン</Button>
        </form>
      </Paper>
    </Box>
  );
}
