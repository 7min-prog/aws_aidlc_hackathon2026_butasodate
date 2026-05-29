import { useEffect, useState } from 'react';
import { Box, Typography, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, Button, Dialog, DialogTitle, DialogContent, DialogActions, TextField, Stack } from '@mui/material';
import { api } from '../api/client';

export function EvolutionPathsPage() {
  const [paths, setPaths] = useState<Array<Record<string, unknown>>>([]);
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<Record<string, unknown> | null>(null);
  const [form, setForm] = useState({ pathId: '', name: '', stage: '1', dominantCategory: 'FOOD', spriteSheetKey: '', description: '' });

  const load = () => api.getPaths().then((r) => setPaths(r.paths));
  useEffect(() => { load(); }, []);

  const handleSave = async () => {
    if (editing) { await api.updatePath(form.pathId, form); }
    else { await api.createPath(form); }
    setOpen(false); setEditing(null); load();
  };

  const handleDelete = async (pathId: string) => { await api.deletePath(pathId); load(); };

  const openEdit = (p: Record<string, unknown>) => {
    setEditing(p); setForm({ pathId: String(p.pathId), name: String(p.name), stage: String(p.stage), dominantCategory: String(p.dominantCategory), spriteSheetKey: String(p.spriteSheetKey || ''), description: String(p.description || '') });
    setOpen(true);
  };

  const openNew = () => { setEditing(null); setForm({ pathId: '', name: '', stage: '1', dominantCategory: 'FOOD', spriteSheetKey: '', description: '' }); setOpen(true); };

  return (
    <Box>
      <Stack direction="row" justifyContent="space-between" mb={2}>
        <Typography variant="h5">進化パス管理</Typography>
        <Button variant="contained" onClick={openNew}>新規登録</Button>
      </Stack>
      <TableContainer component={Paper}>
        <Table>
          <TableHead><TableRow><TableCell>ID</TableCell><TableCell>名前</TableCell><TableCell>段階</TableCell><TableCell>カテゴリ</TableCell><TableCell>操作</TableCell></TableRow></TableHead>
          <TableBody>
            {paths.map((p) => (
              <TableRow key={String(p.pathId)}>
                <TableCell>{String(p.pathId)}</TableCell>
                <TableCell>{String(p.name)}</TableCell>
                <TableCell>{String(p.stage)}</TableCell>
                <TableCell>{String(p.dominantCategory)}</TableCell>
                <TableCell>
                  <Button size="small" onClick={() => openEdit(p)}>編集</Button>
                  <Button size="small" color="error" onClick={() => handleDelete(String(p.pathId))}>削除</Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
      <Dialog open={open} onClose={() => setOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editing ? '進化パス編集' : '進化パス新規登録'}</DialogTitle>
        <DialogContent>
          <TextField fullWidth label="パスID" value={form.pathId} onChange={(e) => setForm({ ...form, pathId: e.target.value })} margin="dense" disabled={!!editing} />
          <TextField fullWidth label="名前" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} margin="dense" />
          <TextField fullWidth label="段階" value={form.stage} onChange={(e) => setForm({ ...form, stage: e.target.value })} margin="dense" />
          <TextField fullWidth label="カテゴリ" value={form.dominantCategory} onChange={(e) => setForm({ ...form, dominantCategory: e.target.value })} margin="dense" />
          <TextField fullWidth label="スプライトキー" value={form.spriteSheetKey} onChange={(e) => setForm({ ...form, spriteSheetKey: e.target.value })} margin="dense" />
          <TextField fullWidth label="説明" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} margin="dense" multiline rows={2} />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>キャンセル</Button>
          <Button variant="contained" onClick={handleSave}>保存</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
