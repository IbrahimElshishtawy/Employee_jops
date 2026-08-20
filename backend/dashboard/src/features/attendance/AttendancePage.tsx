import React, { useEffect, useState } from 'react';
import { Download, Filter, AlertTriangle } from 'lucide-react';
import { api } from '../../core/network/api-client';
import { DataTable, Column } from '../../shared/components/DataTable';
import { Button } from '../../shared/components/Button';
import { StatusBadge } from '../../shared/components/Badge';

export const AttendancePage: React.FC = () => {
  const [records, setRecords] = useState<any[]>([]);
  const [summary, setSummary] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);

  // Filters
  const [department, setDepartment] = useState('');
  const [status, setStatus] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  const fetchAttendance = async (p = page) => {
    setIsLoading(true);
    try {
      const params = new URLSearchParams();
      params.set('page', String(p));
      params.set('limit', '15');
      if (department) params.set('department', department);
      if (status) params.set('status', status);
      if (startDate) params.set('startDate', startDate);
      if (endDate) params.set('endDate', endDate);

      const res = await api.get(`/reports/attendance?${params.toString()}`);
      setRecords(res.data?.data || []);
      setSummary(res.data?.summary || null);
      setTotal(res.data?.meta?.total || 0);
      setTotalPages(res.data?.meta?.totalPages || 1);
    } catch {
      // Fallback
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchAttendance(page);
  }, [page, department, status]);

  const handleExportCsv = async () => {
    try {
      const token = localStorage.getItem('cw_access_token') || sessionStorage.getItem('cw_access_token');
      const res = await fetch('/api/v1/reports/attendance/export', {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });
      const blob = await res.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `attendance-report-${new Date().toISOString().split('T')[0]}.csv`;
      document.body.appendChild(a);
      a.click();
      a.remove();
    } catch {
      alert('Failed to export CSV');
    }
  };

  const columns: Column<any>[] = [
    {
      key: 'date',
      header: 'Date',
      render: (r) => (
        <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 600 }}>
          {new Date(r.date).toISOString().split('T')[0]}
        </span>
      ),
    },
    {
      key: 'employee',
      header: 'Employee',
      render: (r) => (
        <div>
          <span style={{ fontWeight: 600 }}>{r.employee?.firstName} {r.employee?.lastName}</span>
          <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
            {r.employee?.employeeCode} • {r.employee?.department}
          </p>
        </div>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      render: (r) => <StatusBadge status={r.status} />,
    },
    {
      key: 'checkIn',
      header: 'Check-In',
      render: (r) => (
        <div style={{ fontSize: '0.85rem' }}>
          <span>{r.checkInTime ? new Date(r.checkInTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '—'}</span>
          {r.lateMinutes > 0 && (
            <span style={{ color: 'var(--warning-text)', display: 'block', fontSize: '0.7rem', fontWeight: 700 }}>
              +{r.lateMinutes}m Late
            </span>
          )}
        </div>
      ),
    },
    {
      key: 'checkOut',
      header: 'Check-Out',
      render: (r) => (
        <div style={{ fontSize: '0.85rem' }}>
          <span>{r.checkOutTime ? new Date(r.checkOutTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '—'}</span>
          {r.earlyLeaveMinutes > 0 && (
            <span style={{ color: 'var(--danger-text)', display: 'block', fontSize: '0.7rem', fontWeight: 700 }}>
              -{r.earlyLeaveMinutes}m Early
            </span>
          )}
        </div>
      ),
    },
    {
      key: 'duration',
      header: 'Work Duration',
      render: (r) => (
        <span style={{ fontFamily: 'var(--font-mono)', fontSize: '0.85rem' }}>
          {r.workDurationMinutes ? `${Math.floor(r.workDurationMinutes / 60)}h ${r.workDurationMinutes % 60}m` : '—'}
        </span>
      ),
    },
    {
      key: 'signals',
      header: 'Signals',
      render: (r) => (
        <div className="flex gap-1">
          {r.isSuspicious && (
            <span className="badge badge-danger" title="Suspicious GPS/Device Signal">
              <AlertTriangle size={12} />
              Flagged
            </span>
          )}
          {r.isManualEntry && (
            <span className="badge badge-warning" title="Manually Adjusted by HR">
              Manual
            </span>
          )}
        </div>
      ),
    },
  ];

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800 }}>Live Attendance & Operations</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
            Inspect GPS check-in/out timestamps, compliance rates, and late/early departure metrics
          </p>
        </div>
        <Button variant="secondary" icon={<Download size={16} />} onClick={handleExportCsv}>
          Export CSV
        </Button>
      </div>

      {/* Summary KPI Ribbon */}
      {summary && (
        <div className="grid grid-cols-4 gap-4">
          <div className="card">
            <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Attendance Rate</span>
            <h3 style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--primary)' }}>
              {summary.attendanceRate}%
            </h3>
          </div>
          <div className="card">
            <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Present Days</span>
            <h3 style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--success)' }}>
              {summary.presentDays}
            </h3>
          </div>
          <div className="card">
            <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Late Occurrences</span>
            <h3 style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--warning)' }}>
              {summary.lateDays} <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>({summary.totalLateMinutes}m)</span>
            </h3>
          </div>
          <div className="card">
            <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Absence Count</span>
            <h3 style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--danger)' }}>
              {summary.absentDays}
            </h3>
          </div>
        </div>
      )}

      {/* Filters Bar */}
      <div className="card flex items-center gap-3 flex-wrap">
        <div className="flex items-center gap-2" style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
          <Filter size={16} />
          <strong>Filters:</strong>
        </div>

        <select
          className="select"
          style={{ width: '180px' }}
          value={department}
          onChange={(e) => setDepartment(e.target.value)}
        >
          <option value="">All Departments</option>
          <option value="Engineering">Engineering</option>
          <option value="Product">Product</option>
          <option value="Design">Design</option>
          <option value="HR">HR & People</option>
          <option value="Finance">Finance</option>
        </select>

        <select
          className="select"
          style={{ width: '160px' }}
          value={status}
          onChange={(e) => setStatus(e.target.value)}
        >
          <option value="">All Statuses</option>
          <option value="PRESENT">Present</option>
          <option value="LATE">Late</option>
          <option value="ABSENT">Absent</option>
          <option value="EARLY_LEAVE">Early Leave</option>
        </select>

        <input
          type="date"
          className="input"
          style={{ width: '150px' }}
          value={startDate}
          onChange={(e) => setStartDate(e.target.value)}
        />
        <input
          type="date"
          className="input"
          style={{ width: '150px' }}
          value={endDate}
          onChange={(e) => setEndDate(e.target.value)}
        />

        <Button variant="secondary" size="sm" onClick={() => fetchAttendance(1)}>
          Apply
        </Button>
      </div>

      <DataTable
        columns={columns}
        data={records}
        isLoading={isLoading}
        page={page}
        totalPages={totalPages}
        total={total}
        onPageChange={setPage}
      />
    </div>
  );
};
