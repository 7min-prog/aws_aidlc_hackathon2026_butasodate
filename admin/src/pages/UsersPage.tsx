import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Box, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, Button, Typography, Chip, TextField } from '@mui/material';
import { api } from '../api/client';

export function UsersPage() {
  const [users, setUsers] = useState<Array<{ username: string; status: string; enabled: boolean }>>([]);
  const [search, setSearch] = useState('');
  const navigate = useNavigate();

  useEffect(() => { api.getUsers().then((r) => setUsers(r.users)); }, []);

  const filtered = users.filter((u) => u.username.includes(search));

  return (
    <Box>
      <Typography variant="h5" mb={2}>ユーザー管理</Typography>
      <TextField label="検索" size="small" value={search} onChange={(e) => setSearch(e.target.value)} sx={{ mb: 2 }} />
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>ユーザー名</TableCell>
              <TableCell>ステータス</TableCell>
              <TableCell>有効</TableCell>
              <TableCell>操作</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filtered.map((u) => (
              <TableRow key={u.username}>
                <TableCell>{u.username}</TableCell>
                <TableCell>{u.status}</TableCell>
                <TableCell><Chip label={u.enabled ? '有効' : '停止'} color={u.enabled ? 'success' : 'error'} size="small" /></TableCell>
                <TableCell><Button size="small" onClick={() => navigate(`/users/${u.username}`)}>詳細</Button></TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
}
