import { useEffect, useState } from 'react';
import { Box, Typography, Paper, TextField, Button, Stack } from '@mui/material';
import { api } from '../api/client';

export function GameConfigPage() {
  const [configs, setConfigs] = useState<Array<{ configKey: string; value: unknown }>>([]);
  const [editKey, setEditKey] = useState('');
  const [editValue, setEditValue] = useState('');

  const load = () => api.getConfig().then((r) => setConfigs(r.config));
  useEffect(() => { load(); }, []);

  const handleSave = async () => {
    let parsed: unknown;
    try { parsed = JSON.parse(editValue); } catch { parsed = editValue; }
    await api.updateConfig(editKey, parsed);
    setEditKey(''); setEditValue(''); load();
  };

  return (
    <Box>
      <Typography variant="h5" mb={2}>ゲーム設定</Typography>
      {configs.map((c) => (
        <Paper key={c.configKey} sx={{ p: 2, mb: 1 }}>
          <Typography fontWeight="bold">{c.configKey}</Typography>
          <Typography variant="body2" color="text.secondary">{JSON.stringify(c.value)}</Typography>
          <Button size="small" onClick={() => { setEditKey(c.configKey); setEditValue(JSON.stringify(c.value)); }}>編集</Button>
        </Paper>
      ))}
      {editKey && (
        <Paper sx={{ p: 2, mt: 2 }}>
          <Typography variant="h6">編集: {editKey}</Typography>
          <TextField fullWidth multiline rows={3} value={editValue} onChange={(e) => setEditValue(e.target.value)} margin="dense" />
          <Stack direction="row" spacing={1} mt={1}>
            <Button variant="contained" onClick={handleSave}>保存</Button>
            <Button onClick={() => setEditKey('')}>キャンセル</Button>
          </Stack>
        </Paper>
      )}
    </Box>
  );
}
