import React, { useEffect, useState } from 'react';
import {
  Users,
  UserCheck,
  UserX,
  Clock,
  FileCheck,
  Coins,
  CreditCard,
  Building,
  RefreshCw,
  ArrowUpRight,
} from 'lucide-react';
import { api } from '../../core/network/api-client';
import { StatCard } from '../../shared/components/StatCard';
import { Button } from '../../shared/components/Button';
import { StatusBadge } from '../../shared/components/Badge';

export const DashboardPage: React.FC<{ onNavigate: (path: string) => void }> = ({ onNavigate }) => {
  const [data, setData] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchDashboard = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const res = await api.get('/reports/dashboard');
      setData(res.data);
    } catch (err: any) {
      setError(err.message || 'Failed to load dashboard metrics');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboard();
  }, []);

  return (
    <div className="flex flex-col gap-6">
      {/* Top Banner & Refresh */}
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800 }}>HR Executive Dashboard</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
            Live workforce overview, attendance telemetry, and pending actions
          </p>
        </div>
        <Button
          variant="secondary"
          size="sm"
          icon={<RefreshCw size={14} className={isLoading ? 'animate-spin' : ''} />}
          onClick={fetchDashboard}
          disabled={isLoading}
        >
          Refresh Data
        </Button>
      </div>

      {error && (
        <div
          style={{
            backgroundColor: 'var(--danger-light)',
            color: 'var(--danger-text)',
            padding: '1rem',
            borderRadius: 'var(--radius-md)',
            border: '1px solid var(--danger)',
          }}
        >
          {error}
        </div>
      )}

      {/* Primary KPI Grid */}
      <div className="grid grid-cols-4 gap-4">
        <StatCard
          title="Total Headcount"
          value={data?.employees?.total ?? '—'}
          subtitle={`${data?.employees?.active ?? 0} Active • ${data?.employees?.inactive ?? 0} Inactive`}
          icon={<Users size={20} />}
          color="var(--primary)"
        />
        <StatCard
          title="Present Today"
          value={data?.todayAttendance?.present ?? '—'}
          subtitle={`${data?.todayAttendance?.currentlyCheckedIn ?? 0} Currently working`}
          icon={<UserCheck size={20} />}
          color="var(--success)"
        />
        <StatCard
          title="Late Arrivals"
          value={data?.todayAttendance?.late ?? '—'}
          subtitle="Checked in past schedule"
          icon={<Clock size={20} />}
          color="var(--warning)"
        />
        <StatCard
          title="Absent Today"
          value={data?.todayAttendance?.absent ?? '—'}
          subtitle="No check-in record"
          icon={<UserX size={20} />}
          color="var(--danger)"
        />
      </div>

      {/* Actionable Pipeline Cards */}
      <div className="grid grid-cols-3 gap-6">
        {/* Pending Approvals Card */}
        <div className="card flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between" style={{ marginBottom: '1rem' }}>
              <h4>Pending Action Queue</h4>
              <StatusBadge status={data?.pendingActions?.requests > 0 ? 'PENDING' : 'ACTIVE'} />
            </div>
            <div className="flex flex-col gap-3">
              <div
                className="flex items-center justify-between"
                style={{
                  padding: '0.75rem',
                  borderRadius: 'var(--radius-sm)',
                  backgroundColor: 'var(--bg-tertiary)',
                }}
              >
                <div className="flex items-center gap-2">
                  <FileCheck size={18} color="var(--primary)" />
                  <span style={{ fontWeight: 600, fontSize: '0.875rem' }}>Employee Requests & Leaves</span>
                </div>
                <span style={{ fontWeight: 800, fontSize: '1.1rem' }}>
                  {data?.pendingActions?.requests ?? 0}
                </span>
              </div>

              <div
                className="flex items-center justify-between"
                style={{
                  padding: '0.75rem',
                  borderRadius: 'var(--radius-sm)',
                  backgroundColor: 'var(--bg-tertiary)',
                }}
              >
                <div className="flex items-center gap-2">
                  <Coins size={18} color="var(--warning)" />
                  <span style={{ fontWeight: 600, fontSize: '0.875rem' }}>Salary Advance Requests</span>
                </div>
                <span style={{ fontWeight: 800, fontSize: '1.1rem' }}>
                  {data?.pendingActions?.advances ?? 0}
                </span>
              </div>
            </div>
          </div>

          <div className="flex gap-2" style={{ marginTop: '1.5rem' }}>
            <Button
              variant="primary"
              size="sm"
              style={{ flex: 1 }}
              onClick={() => onNavigate('/requests')}
            >
              Review Requests
            </Button>
            <Button
              variant="secondary"
              size="sm"
              style={{ flex: 1 }}
              onClick={() => onNavigate('/advances')}
            >
              Review Advances
            </Button>
          </div>
        </div>

        {/* Monthly Financial Intelligence */}
        <div className="card flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between" style={{ marginBottom: '1rem' }}>
              <h4>Monthly Payroll Metrics</h4>
              <CreditCard size={18} color="var(--primary)" />
            </div>
            <div className="flex flex-col gap-2" style={{ fontSize: '0.875rem' }}>
              <div className="flex justify-between" style={{ padding: '0.4rem 0', borderBottom: '1px solid var(--border-color)' }}>
                <span style={{ color: 'var(--text-secondary)' }}>Gross Payroll</span>
                <span style={{ fontWeight: 700 }}>
                  EGP {Number(data?.monthlyFinancials?.grossPayroll || 0).toLocaleString()}
                </span>
              </div>
              <div className="flex justify-between" style={{ padding: '0.4rem 0', borderBottom: '1px solid var(--border-color)' }}>
                <span style={{ color: 'var(--text-secondary)' }}>Total Deductions</span>
                <span style={{ fontWeight: 700, color: 'var(--danger)' }}>
                  - EGP {Number(data?.monthlyFinancials?.totalDeductions || 0).toLocaleString()}
                </span>
              </div>
              <div className="flex justify-between" style={{ padding: '0.4rem 0', borderBottom: '1px solid var(--border-color)' }}>
                <span style={{ color: 'var(--text-secondary)' }}>Advances Disbursed</span>
                <span style={{ fontWeight: 700 }}>
                  EGP {Number(data?.monthlyFinancials?.totalAdvances || 0).toLocaleString()}
                </span>
              </div>
              <div className="flex justify-between" style={{ padding: '0.6rem 0', fontWeight: 800 }}>
                <span>Net Estimated Pay</span>
                <span style={{ color: 'var(--primary)', fontSize: '1.1rem' }}>
                  EGP {Number(data?.monthlyFinancials?.netPayroll || 0).toLocaleString()}
                </span>
              </div>
            </div>
          </div>

          <Button
            variant="secondary"
            size="sm"
            style={{ width: '100%', marginTop: '1rem' }}
            onClick={() => onNavigate('/payroll')}
          >
            Open Payroll Engine
            <ArrowUpRight size={14} />
          </Button>
        </div>

        {/* Quick Operations Shortcuts */}
        <div className="card flex flex-col justify-between">
          <div>
            <h4 style={{ marginBottom: '1rem' }}>Quick Operational Shortcuts</h4>
            <div className="flex flex-col gap-2">
              <button
                className="btn btn-secondary"
                style={{ width: '100%', justifyContent: 'flex-start' }}
                onClick={() => onNavigate('/employees')}
              >
                <Users size={16} color="var(--primary)" />
                <span>Manage Employees</span>
              </button>
              <button
                className="btn btn-secondary"
                style={{ width: '100%', justifyContent: 'flex-start' }}
                onClick={() => onNavigate('/attendance')}
              >
                <Clock size={16} color="var(--success)" />
                <span>Live Attendance Logs</span>
              </button>
              <button
                className="btn btn-secondary"
                style={{ width: '100%', justifyContent: 'flex-start' }}
                onClick={() => onNavigate('/workplaces')}
              >
                <Building size={16} color="var(--info)" />
                <span>Branches & Geofences</span>
              </button>
              <button
                className="btn btn-secondary"
                style={{ width: '100%', justifyContent: 'flex-start' }}
                onClick={() => onNavigate('/reports')}
              >
                <RefreshCw size={16} color="var(--warning)" />
                <span>Export Intelligence Reports</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
