import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Box, Typography, Button, Paper, Dialog, DialogTitle, DialogActions, TextField, Stack } from '@mui/material';
import { api } from '../api/client';

export function UserDetailPage() {
  const { username } = useParams<{ username: string }>();
  const navigate = useNavigate();
  const [user, setUser] = useState<Record<string, unknown> | null>(null);
  const [confirmAction, setConfirmAction] = useState<string | null>(null);
  const [healthData, setHealthData] = useState({ weight: '', steps: '', sleepHours: '', date: new Date().toISOString().slice(0, 10) });

  useEffect(() => { if (username) api.getUser(username).then(setUser); }, [username]);

  const handleAction = async () => {
    if (!username || !confirmAction) return;
    if (confirmAction === 'disable') await api.disableUser(username);
    if (confirmAction === 'enable') await api.enableUser(username);
    if (confirmAction === 'delete') { await api.deleteUser(username); navigate('/users'); }
    setConfirmAction(null);
    api.getUser(username).then(setUser);
  };

  const handleHealthSubmit = async () => {
    if (!username) return;
    await api.addHealthData(username, {
      weight: healthData.weight ? Number(healthData.weight) : undefined,
      steps: healthData.steps ? Number(healthData.steps) : undefined,
      sleepHours: healthData.sleepHours ? Number(healthData.sleepHours) : undefined,
      date: healthData.date,
    });
    setHealthData({ weight: '', steps: '', sleepHours: '', date: new Date().toISOString().slice(0, 10) });
  };

  if (!user) return <Typography>読み込み中...</Typography>;

  return (
    <Box>
      <Typography variant="h5" mb={2}>ユーザー詳細: {username}</Typography>
      <Paper sx={{ p: 2, mb: 2 }}>
        <Typography>ステータス: {String(user.status)}</Typography>
        <Typography>有効: {String(user.enabled)}</Typography>
        {user.avatar ? <Typography>アバターLv: {String((user.avatar as Record<string, unknown>).level)}</Typography> : null}
        <Stack direction="row" spacing={1} mt={2}>
          <Button variant="outlined" color="warning" onClick={() => setConfirmAction('disable')}>停止</Button>
          <Button variant="outlined" color="success" onClick={() => setConfirmAction('enable')}>復活</Button>
          <Button variant="outlined" color="error" onClick={() => setConfirmAction('delete')}>削除</Button>
        </Stack>
      </Paper>

      <Paper sx={{ p: 2 }}>
        <Typography variant="h6" mb={1}>ヘルスデータ手動入力</Typography>
        <Stack direction="row" spacing={1} alignItems="center">
          <TextField label="体重(kg)" size="small" value={healthData.weight} onChange={(e) => setHealthData({ ...healthData, weight: e.target.value })} />
          <TextField label="歩数" size="small" value={healthData.steps} onChange={(e) => setHealthData({ ...healthData, steps: e.target.value })} />
          <TextField label="睡眠(h)" size="small" value={healthData.sleepHours} onChange={(e) => setHealthData({ ...healthData, sleepHours: e.target.value })} />
          <TextField label="日付" type="date" size="small" value={healthData.date} onChange={(e) => setHealthData({ ...healthData, date: e.target.value })} />
          <Button variant="contained" onClick={handleHealthSubmit}>登録</Button>
        </Stack>
      </Paper>

      <Dialog open={!!confirmAction} onClose={() => setConfirmAction(null)}>
        <DialogTitle>本当に{confirmAction === 'delete' ? '削除' : confirmAction === 'disable' ? '停止' : '復活'}しますか？</DialogTitle>
        <DialogActions>
          <Button onClick={() => setConfirmAction(null)}>キャンセル</Button>
          <Button color="error" onClick={handleAction}>実行</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
