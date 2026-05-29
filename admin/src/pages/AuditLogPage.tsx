import { useEffect, useState } from 'react';
import { Box, Typography, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper } from '@mui/material';
import { api } from '../api/client';

export function AuditLogPage() {
  const [logs, setLogs] = useState<Array<{ logId: string; timestamp: string; operator: string; action: string; target: string }>>([]);

  useEffect(() => { api.getAuditLog().then((r) => setLogs(r.logs)); }, []);

  return (
    <Box>
      <Typography variant="h5" mb={2}>操作ログ</Typography>
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>日時</TableCell>
              <TableCell>操作者</TableCell>
              <TableCell>操作</TableCell>
              <TableCell>対象</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {logs.map((l) => (
              <TableRow key={l.logId}>
                <TableCell>{new Date(l.timestamp).toLocaleString('ja-JP')}</TableCell>
                <TableCell>{l.operator}</TableCell>
                <TableCell>{l.action}</TableCell>
                <TableCell>{l.target}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
}
