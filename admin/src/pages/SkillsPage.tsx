import { useEffect, useState } from 'react';
import { Box, Typography, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, Button, Dialog, DialogTitle, DialogContent, DialogActions, TextField, Stack } from '@mui/material';
import { api } from '../api/client';

export function SkillsPage() {
  const [skills, setSkills] = useState<Array<Record<string, unknown>>>([]);
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<Record<string, unknown> | null>(null);
  const [form, setForm] = useState({ skillId: '', name: '', type: 'ATTACK', multiplier: '1.0', cooldown: '1', speciesId: '', requiredLevel: '5', targetStat: 'hp', duration: '', spriteAnimationKey: '' });

  const load = () => api.getSkills().then((r) => setSkills(r.skills));
  useEffect(() => { load(); }, []);

  const handleSave = async () => {
    const data = { ...form, multiplier: Number(form.multiplier), cooldown: Number(form.cooldown), requiredLevel: Number(form.requiredLevel), duration: form.duration ? Number(form.duration) : null };
    if (editing) { await api.updateSkill(form.skillId, data); }
    else { await api.createSkill(data); }
    setOpen(false); setEditing(null); load();
  };

  const handleDelete = async (skillId: string) => { await api.deleteSkill(skillId); load(); };

  const openNew = () => { setEditing(null); setForm({ skillId: '', name: '', type: 'ATTACK', multiplier: '1.0', cooldown: '1', speciesId: '', requiredLevel: '5', targetStat: 'hp', duration: '', spriteAnimationKey: '' }); setOpen(true); };

  return (
    <Box>
      <Stack direction="row" justifyContent="space-between" mb={2}>
        <Typography variant="h5">スキル管理</Typography>
        <Button variant="contained" onClick={openNew}>新規登録</Button>
      </Stack>
      <TableContainer component={Paper}>
        <Table>
          <TableHead><TableRow><TableCell>ID</TableCell><TableCell>名前</TableCell><TableCell>タイプ</TableCell><TableCell>倍率</TableCell><TableCell>種族</TableCell><TableCell>操作</TableCell></TableRow></TableHead>
          <TableBody>
            {skills.map((s) => (
              <TableRow key={String(s.skillId)}>
                <TableCell>{String(s.skillId)}</TableCell>
                <TableCell>{String(s.name)}</TableCell>
                <TableCell>{String(s.type)}</TableCell>
                <TableCell>{String(s.multiplier ?? '')}</TableCell>
                <TableCell>{String(s.speciesId ?? '')}</TableCell>
                <TableCell>
                  <Button size="small" onClick={() => { setEditing(s); setForm({ skillId: String(s.skillId), name: String(s.name), type: String(s.type), multiplier: String(s.multiplier ?? ''), cooldown: String(s.cooldown ?? ''), speciesId: String(s.speciesId ?? ''), requiredLevel: String(s.requiredLevel ?? ''), targetStat: String(s.targetStat ?? ''), duration: String(s.duration ?? ''), spriteAnimationKey: String(s.spriteAnimationKey ?? '') }); setOpen(true); }}>編集</Button>
                  <Button size="small" color="error" onClick={() => handleDelete(String(s.skillId))}>削除</Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
      <Dialog open={open} onClose={() => setOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editing ? 'スキル編集' : 'スキル新規登録'}</DialogTitle>
        <DialogContent>
          <TextField fullWidth label="スキルID" value={form.skillId} onChange={(e) => setForm({ ...form, skillId: e.target.value })} margin="dense" disabled={!!editing} />
          <TextField fullWidth label="名前" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} margin="dense" />
          <TextField fullWidth label="タイプ" value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value })} margin="dense" />
          <TextField fullWidth label="倍率 (multiplier)" value={form.multiplier} onChange={(e) => setForm({ ...form, multiplier: e.target.value })} margin="dense" />
          <TextField fullWidth label="対象ステータス" value={form.targetStat} onChange={(e) => setForm({ ...form, targetStat: e.target.value })} margin="dense" />
          <TextField fullWidth label="クールダウン" value={form.cooldown} onChange={(e) => setForm({ ...form, cooldown: e.target.value })} margin="dense" />
          <TextField fullWidth label="持続ターン" value={form.duration} onChange={(e) => setForm({ ...form, duration: e.target.value })} margin="dense" />
          <TextField fullWidth label="種族ID (speciesId)" value={form.speciesId} onChange={(e) => setForm({ ...form, speciesId: e.target.value })} margin="dense" />
          <TextField fullWidth label="必要レベル" value={form.requiredLevel} onChange={(e) => setForm({ ...form, requiredLevel: e.target.value })} margin="dense" />
          <TextField fullWidth label="アニメーションキー" value={form.spriteAnimationKey} onChange={(e) => setForm({ ...form, spriteAnimationKey: e.target.value })} margin="dense" />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>キャンセル</Button>
          <Button variant="contained" onClick={handleSave}>保存</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
