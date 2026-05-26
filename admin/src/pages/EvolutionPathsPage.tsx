import { useEffect, useState } from 'react';
import { Box, Typography, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, Button, Dialog, DialogTitle, DialogContent, DialogActions, TextField, Stack, Switch, FormControlLabel } from '@mui/material';
import { api } from '../api/client';

export function EvolutionPathsPage() {
  const [paths, setPaths] = useState<Array<Record<string, unknown>>>([]);
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<Record<string, unknown> | null>(null);
  const [form, setForm] = useState({ speciesId: '', name: '', stage: '1', dominantCategory: 'FOOD', spriteSheetKey: '', iconKey: '', description: '', isActive: true, hp: '5', attack: '3', defense: '3', speed: '3' });

  const load = () => api.getPaths().then((r) => setPaths(r.paths));
  useEffect(() => { load(); }, []);

  const handleSave = async () => {
    const data = { speciesId: form.speciesId, name: form.name, stage: Number(form.stage), dominantCategory: form.dominantCategory, spriteSheetKey: form.spriteSheetKey, iconKey: form.iconKey, description: form.description, isActive: form.isActive, statsGrowth: { hp: Number(form.hp), attack: Number(form.attack), defense: Number(form.defense), speed: Number(form.speed) } };
    if (editing) { await api.updatePath(form.speciesId, data); }
    else { await api.createPath(data); }
    setOpen(false); setEditing(null); load();
  };

  const handleDelete = async (speciesId: string) => { await api.deletePath(speciesId); load(); };

  const openEdit = (p: Record<string, unknown>) => {
    const sg = (p.statsGrowth as Record<string, number>) || {};
    setEditing(p);
    setForm({ speciesId: String(p.speciesId), name: String(p.name), stage: String(p.stage), dominantCategory: String(p.dominantCategory), spriteSheetKey: String(p.spriteSheetKey || ''), iconKey: String(p.iconKey || ''), description: String(p.description || ''), isActive: p.isActive !== false, hp: String(sg.hp ?? 5), attack: String(sg.attack ?? 3), defense: String(sg.defense ?? 3), speed: String(sg.speed ?? 3) });
    setOpen(true);
  };

  const openNew = () => { setEditing(null); setForm({ speciesId: '', name: '', stage: '1', dominantCategory: 'FOOD', spriteSheetKey: '', iconKey: '', description: '', isActive: true, hp: '5', attack: '3', defense: '3', speed: '3' }); setOpen(true); };

  return (
    <Box>
      <Stack direction="row" justifyContent="space-between" mb={2}>
        <Typography variant="h5">進化パス管理</Typography>
        <Button variant="contained" onClick={openNew}>新規登録</Button>
      </Stack>
      <TableContainer component={Paper}>
        <Table>
          <TableHead><TableRow><TableCell>種族ID</TableCell><TableCell>名前</TableCell><TableCell>段階</TableCell><TableCell>カテゴリ</TableCell><TableCell>有効</TableCell><TableCell>操作</TableCell></TableRow></TableHead>
          <TableBody>
            {paths.map((p) => (
              <TableRow key={String(p.speciesId)}>
                <TableCell>{String(p.speciesId)}</TableCell>
                <TableCell>{String(p.name)}</TableCell>
                <TableCell>{String(p.stage)}</TableCell>
                <TableCell>{String(p.dominantCategory)}</TableCell>
                <TableCell>{p.isActive ? '✓' : '—'}</TableCell>
                <TableCell>
                  <Button size="small" onClick={() => openEdit(p)}>編集</Button>
                  <Button size="small" color="error" onClick={() => handleDelete(String(p.speciesId))}>削除</Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
      <Dialog open={open} onClose={() => setOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editing ? '進化パス編集' : '進化パス新規登録'}</DialogTitle>
        <DialogContent>
          <TextField fullWidth label="種族ID" value={form.speciesId} onChange={(e) => setForm({ ...form, speciesId: e.target.value })} margin="dense" disabled={!!editing} />
          <TextField fullWidth label="名前" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} margin="dense" />
          <TextField fullWidth label="段階" value={form.stage} onChange={(e) => setForm({ ...form, stage: e.target.value })} margin="dense" />
          <TextField fullWidth label="カテゴリ" value={form.dominantCategory} onChange={(e) => setForm({ ...form, dominantCategory: e.target.value })} margin="dense" />
          <TextField fullWidth label="アイコンキー" value={form.iconKey} onChange={(e) => setForm({ ...form, iconKey: e.target.value })} margin="dense" />
          <TextField fullWidth label="スプライトキー" value={form.spriteSheetKey} onChange={(e) => setForm({ ...form, spriteSheetKey: e.target.value })} margin="dense" />
          <TextField fullWidth label="説明" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} margin="dense" multiline rows={2} />
          <FormControlLabel control={<Switch checked={form.isActive} onChange={(e) => setForm({ ...form, isActive: e.target.checked })} />} label="有効" />
          <Typography variant="subtitle2" mt={1}>ステータス成長値</Typography>
          <Stack direction="row" spacing={1}>
            <TextField label="HP" value={form.hp} onChange={(e) => setForm({ ...form, hp: e.target.value })} margin="dense" size="small" />
            <TextField label="攻撃" value={form.attack} onChange={(e) => setForm({ ...form, attack: e.target.value })} margin="dense" size="small" />
            <TextField label="防御" value={form.defense} onChange={(e) => setForm({ ...form, defense: e.target.value })} margin="dense" size="small" />
            <TextField label="速度" value={form.speed} onChange={(e) => setForm({ ...form, speed: e.target.value })} margin="dense" size="small" />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>キャンセル</Button>
          <Button variant="contained" onClick={handleSave}>保存</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
