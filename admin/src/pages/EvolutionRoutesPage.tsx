import { useEffect, useState } from 'react';
import { Box, Typography, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, Button, Dialog, DialogTitle, DialogContent, DialogActions, TextField, Stack } from '@mui/material';
import { api } from '../api/client';

export function EvolutionRoutesPage() {
  const [routes, setRoutes] = useState<Array<Record<string, unknown>>>([]);
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<Record<string, unknown> | null>(null);
  const [form, setForm] = useState({ routeId: '', fromSpeciesId: '', toSpeciesId: '', requiredLevel: '5', categoryThreshold: '0.6', conditionCategory: 'FOOD', priority: '1' });

  const load = () => api.getRoutes().then((r) => setRoutes(r.routes));
  useEffect(() => { load(); }, []);

  const handleSave = async () => {
    const data = { ...form, requiredLevel: Number(form.requiredLevel), categoryThreshold: Number(form.categoryThreshold), priority: Number(form.priority) };
    if (editing) { await api.updateRoute(form.routeId, data); }
    else { await api.createRoute(data); }
    setOpen(false); setEditing(null); load();
  };

  const handleDelete = async (routeId: string) => { await api.deleteRoute(routeId); load(); };

  const openEdit = (r: Record<string, unknown>) => {
    setEditing(r);
    setForm({ routeId: String(r.routeId), fromSpeciesId: String(r.fromSpeciesId), toSpeciesId: String(r.toSpeciesId), requiredLevel: String(r.requiredLevel ?? ''), categoryThreshold: String(r.categoryThreshold ?? ''), conditionCategory: String(r.conditionCategory ?? ''), priority: String(r.priority ?? '') });
    setOpen(true);
  };

  const openNew = () => { setEditing(null); setForm({ routeId: '', fromSpeciesId: '', toSpeciesId: '', requiredLevel: '5', categoryThreshold: '0.6', conditionCategory: 'FOOD', priority: '1' }); setOpen(true); };

  return (
    <Box>
      <Stack direction="row" justifyContent="space-between" mb={2}>
        <Typography variant="h5">進化条件管理</Typography>
        <Button variant="contained" onClick={openNew}>新規登録</Button>
      </Stack>
      <TableContainer component={Paper}>
        <Table>
          <TableHead><TableRow><TableCell>ルートID</TableCell><TableCell>進化元</TableCell><TableCell>進化先</TableCell><TableCell>必要Lv</TableCell><TableCell>カテゴリ</TableCell><TableCell>閾値</TableCell><TableCell>優先度</TableCell><TableCell>操作</TableCell></TableRow></TableHead>
          <TableBody>
            {routes.map((r) => (
              <TableRow key={String(r.routeId)}>
                <TableCell>{String(r.routeId)}</TableCell>
                <TableCell>{String(r.fromSpeciesId)}</TableCell>
                <TableCell>{String(r.toSpeciesId)}</TableCell>
                <TableCell>{String(r.requiredLevel)}</TableCell>
                <TableCell>{String(r.conditionCategory)}</TableCell>
                <TableCell>{String(r.categoryThreshold)}</TableCell>
                <TableCell>{String(r.priority)}</TableCell>
                <TableCell>
                  <Button size="small" onClick={() => openEdit(r)}>編集</Button>
                  <Button size="small" color="error" onClick={() => handleDelete(String(r.routeId))}>削除</Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
      <Dialog open={open} onClose={() => setOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editing ? '進化条件編集' : '進化条件新規登録'}</DialogTitle>
        <DialogContent>
          <TextField fullWidth label="ルートID" value={form.routeId} onChange={(e) => setForm({ ...form, routeId: e.target.value })} margin="dense" disabled={!!editing} />
          <TextField fullWidth label="進化元 (fromSpeciesId)" value={form.fromSpeciesId} onChange={(e) => setForm({ ...form, fromSpeciesId: e.target.value })} margin="dense" />
          <TextField fullWidth label="進化先 (toSpeciesId)" value={form.toSpeciesId} onChange={(e) => setForm({ ...form, toSpeciesId: e.target.value })} margin="dense" />
          <TextField fullWidth label="必要レベル" value={form.requiredLevel} onChange={(e) => setForm({ ...form, requiredLevel: e.target.value })} margin="dense" />
          <TextField fullWidth label="条件カテゴリ (FOOD/LIFESTYLE/MIXED)" value={form.conditionCategory} onChange={(e) => setForm({ ...form, conditionCategory: e.target.value })} margin="dense" />
          <TextField fullWidth label="カテゴリ閾値 (0〜1)" value={form.categoryThreshold} onChange={(e) => setForm({ ...form, categoryThreshold: e.target.value })} margin="dense" />
          <TextField fullWidth label="優先度 (小さいほど優先)" value={form.priority} onChange={(e) => setForm({ ...form, priority: e.target.value })} margin="dense" />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>キャンセル</Button>
          <Button variant="contained" onClick={handleSave}>保存</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
