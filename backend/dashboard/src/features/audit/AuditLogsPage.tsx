import React, { useEffect, useState } from 'react';
import { ShieldCheck, Filter } from 'lucide-react';
import { api } from '../../core/network/api-client';
import { DataTable, Column } from '../../shared/components/DataTable';
import { StatusBadge } from '../../shared/components/Badge';

export const AuditLogsPage: React.FC = () => {
  const [logs, setLogs] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);
  const [actionFilter, setActionFilter] = useState('');

  const fetchLogs = async (p = page) => {
    setIsLoading(true);
    try {
      const params = new URLSearchParams();
      params.set('page', String(p));
      params.set('limit', '15');
      if (actionFilter) params.set('action', actionFilter);

      const res = await api.get(`/audit-logs?${params.toString()}`);
      const list = Array.isArray(res.data) ? res.data : res.data?.data || [];
      setLogs(list);
      setTotal(res.data?.meta?.total || list.length);
      setTotalPages(res.data?.meta?.totalPages || 1);
    } catch {
      // Fallback
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs(page);
  }, [page, actionFilter]);

  const columns: Column<any>[] = [
    {
      key: 'timestamp',
      header: 'Timestamp',
      render: (log) => (
        <span style={{ fontSize: '0.8rem', fontFamily: 'var(--font-mono)' }}>
          {new Date(log.createdAt).toLocaleString()}
        </span>
      ),
    },
    {
      key: 'action',
      header: 'Action',
      render: (log) => <StatusBadge status={log.action} />,
    },
    {
      key: 'actor',
      header: 'Actor',
      render: (log) => (
        <div>
          <span style={{ fontWeight: 600 }}>
            {log.user?.employeeProfile
              ? `${log.user.employeeProfile.firstName} ${log.user.employeeProfile.lastName}`
              : log.user?.email || 'System'}
          </span>
          <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
            {log.user?.role || 'SYSTEM_SERVICE'}
          </p>
        </div>
      ),
    },
    {
      key: 'entity',
      header: 'Resource Target',
      render: (log) => (
        <span className="badge badge-info">
          {log.entity}
        </span>
      ),
    },
    {
      key: 'ip',
      header: 'IP Address / Agent',
      render: (log) => (
        <span style={{ fontSize: '0.75rem', fontFamily: 'var(--font-mono)', color: 'var(--text-muted)' }}>
          {log.ipAddress || '127.0.0.1'}
        </span>
      ),
    },
  ];

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800 }}>Compliance Audit Trail</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
            Immutable logs of administrative changes, approvals, security events, and financial locks
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Filter size={16} color="var(--text-muted)" />
          <select
            className="select"
            style={{ width: '180px' }}
            value={actionFilter}
            onChange={(e) => setActionFilter(e.target.value)}
          >
            <option value="">All Actions</option>
            <option value="CREATE">CREATE</option>
            <option value="UPDATE">UPDATE</option>
            <option value="DELETE">DELETE</option>
            <option value="LOGIN">LOGIN</option>
            <option value="APPROVE">APPROVE</option>
            <option value="REJECT">REJECT</option>
            <option value="PAYROLL_FINALIZED">PAYROLL_FINALIZED</option>
          </select>
        </div>
      </div>

      <DataTable
        columns={columns}
        data={logs}
        isLoading={isLoading}
        page={page}
        totalPages={totalPages}
        total={total}
        onPageChange={setPage}
      />
    </div>
  );
};
