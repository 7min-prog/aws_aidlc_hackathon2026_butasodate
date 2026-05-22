import { useEffect, useState } from 'react';
import { Box, Typography, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, Button, Dialog, DialogTitle, DialogContent, DialogActions, TextField, Stack } from '@mui/material';
import { api } from '../api/client';

export function SkillsPage() {
  const [skills, setSkills] = useState<Array<Record<string, unknown>>>([]);
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<Record<string, unknown> | null>(null);
  const [form, setForm] = useState({ skillId: '', name: '', type: 'ATTACK', power: '40', cooldown: '1', evolutionPathId: '', requiredLevel: '5' });

  const load = () => api.getSkills().then((r) => setSkills(r.skills));
  useEffect(() => { load(); }, []);

  const handleSave = async () => {
    const data = { ...form, power: Number(form.power), cooldown: Number(form.cooldown), requiredLevel: Number(form.requiredLevel) };
    if (editing) { await api.updateSkill(form.skillId, data); }
    else { await api.createSkill(data); }
    setOpen(false); setEditing(null); load();
  };

  const handleDelete = async (skillId: string) => { await api.deleteSkill(skillId); load(); };

  const openNew = () => { setEditing(null); setForm({ skillId: '', name: '', type: 'ATTACK', power: '40', cooldown: '1', evolutionPathId: '', requiredLevel: '5' }); setOpen(true); };

  return (
    <Box>
      <Stack direction="row" justifyContent="space-between" mb={2}>
        <Typography variant="h5">スキル管理</Typography>
        <Button variant="contained" onClick={openNew}>新規登録</Button>
      </Stack>
      <TableContainer component={Paper}>
        <Table>
          <TableHead><TableRow><TableCell>ID</TableCell><TableCell>名前</TableCell><TableCell>タイプ</TableCell><TableCell>威力</TableCell><TableCell>操作</TableCell></TableRow></TableHead>
          <TableBody>
            {skills.map((s) => (
              <TableRow key={String(s.skillId)}>
                <TableCell>{String(s.skillId)}</TableCell>
                <TableCell>{String(s.name)}</TableCell>
                <TableCell>{String(s.type)}</TableCell>
                <TableCell>{String(s.power)}</TableCell>
                <TableCell>
                  <Button size="small" onClick={() => { setEditing(s); setForm({ skillId: String(s.skillId), name: String(s.name), type: String(s.type), power: String(s.power), cooldown: String(s.cooldown), evolutionPathId: String(s.evolutionPathId), requiredLevel: String(s.requiredLevel) }); setOpen(true); }}>編集</Button>
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
          <TextField fullWidth label="威力" value={form.power} onChange={(e) => setForm({ ...form, power: e.target.value })} margin="dense" />
          <TextField fullWidth label="クールダウン" value={form.cooldown} onChange={(e) => setForm({ ...form, cooldown: e.target.value })} margin="dense" />
          <TextField fullWidth label="進化パスID" value={form.evolutionPathId} onChange={(e) => setForm({ ...form, evolutionPathId: e.target.value })} margin="dense" />
          <TextField fullWidth label="必要レベル" value={form.requiredLevel} onChange={(e) => setForm({ ...form, requiredLevel: e.target.value })} margin="dense" />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>キャンセル</Button>
          <Button variant="contained" onClick={handleSave}>保存</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
