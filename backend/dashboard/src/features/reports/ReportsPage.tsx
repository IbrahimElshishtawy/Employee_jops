import React, { useEffect, useState } from 'react';
import { Download, AlertCircle, Clock, UserX, FileCheck } from 'lucide-react';
import { api } from '../../core/network/api-client';
import { Button } from '../../shared/components/Button';

export const ReportsPage: React.FC = () => {
  const [lateStats, setLateStats] = useState<any>(null);
  const [absenceStats, setAbsenceStats] = useState<any>(null);
  const [requestStats, setRequestStats] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);

  const fetchReports = async () => {
    setIsLoading(true);
    try {
      const [lateRes, absRes, reqRes] = await Promise.all([
        api.get('/reports/attendance/late'),
        api.get('/reports/attendance/absence'),
        api.get('/reports/requests'),
      ]);
      setLateStats(lateRes.data);
      setAbsenceStats(absRes.data);
      setRequestStats(reqRes.data);
    } catch {
      // Fallback
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchReports();
  }, []);

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
      a.download = `attendance-intelligence-report-${new Date().toISOString().split('T')[0]}.csv`;
      document.body.appendChild(a);
      a.click();
      a.remove();
    } catch {
      alert('Failed to export CSV report');
    }
  };

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800 }}>HR Intelligence & Analytics</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
            Organizational metrics, lateness distributions, absence rates, and exportable intelligence
          </p>
        </div>
        <Button variant="primary" icon={<Download size={16} />} onClick={handleExportCsv}>
          Export Full Attendance CSV
        </Button>
      </div>

      {isLoading ? (
        <div className="grid grid-cols-3 gap-4">
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="card" style={{ height: '220px', background: 'var(--bg-tertiary)' }} />
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-3 gap-6">
          {/* Late Intelligence */}
          <div className="card flex flex-col justify-between">
            <div>
              <div className="flex items-center gap-2" style={{ marginBottom: '1rem' }}>
                <Clock size={20} color="var(--warning)" />
                <h4>Late Arrival Intelligence</h4>
              </div>
              <div className="flex flex-col gap-2" style={{ fontSize: '0.875rem' }}>
                <div className="flex justify-between" style={{ padding: '0.4rem 0', borderBottom: '1px solid var(--border-color)' }}>
                  <span style={{ color: 'var(--text-secondary)' }}>Total Late Minutes</span>
                  <strong style={{ color: 'var(--warning-text)' }}>{lateStats?.summary?.totalLateMinutes ?? 0} mins</strong>
                </div>
                <div className="flex justify-between" style={{ padding: '0.4rem 0', borderBottom: '1px solid var(--border-color)' }}>
                  <span style={{ color: 'var(--text-secondary)' }}>Average Late per Occurrence</span>
                  <strong>{lateStats?.summary?.averageLateMinutes ?? 0} mins</strong>
                </div>
                <div className="flex justify-between" style={{ padding: '0.4rem 0', borderBottom: '1px solid var(--border-color)' }}>
                  <span style={{ color: 'var(--text-secondary)' }}>Affected Employees</span>
                  <strong>{lateStats?.summary?.lateEmployeesCount ?? 0} Staff</strong>
                </div>
              </div>

              {/* Top Late Employees Snippet */}
              {lateStats?.topLateEmployees?.length > 0 && (
                <div style={{ marginTop: '1rem' }}>
                  <span style={{ fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', color: 'var(--text-muted)' }}>
                    Top Frequent Late Arrivals
                  </span>
                  <div className="flex flex-col gap-1" style={{ marginTop: '0.4rem' }}>
                    {lateStats.topLateEmployees.slice(0, 3).map((emp: any) => (
                      <div key={emp.employeeId} className="flex justify-between" style={{ fontSize: '0.8rem' }}>
                        <span>{emp.employeeName}</span>
                        <span style={{ fontWeight: 700, color: 'var(--warning-text)' }}>{emp.totalLateMinutes}m ({emp.occurrences}x)</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Absence Analytics */}
          <div className="card flex flex-col justify-between">
            <div>
              <div className="flex items-center gap-2" style={{ marginBottom: '1rem' }}>
                <UserX size={20} color="var(--danger)" />
                <h4>Absence & Leave Analytics</h4>
              </div>
              <div className="flex flex-col gap-2" style={{ fontSize: '0.875rem' }}>
                <div className="flex justify-between" style={{ padding: '0.4rem 0', borderBottom: '1px solid var(--border-color)' }}>
                  <span style={{ color: 'var(--text-secondary)' }}>Total Absence Count</span>
                  <strong style={{ color: 'var(--danger-text)' }}>{absenceStats?.summary?.totalAbsenceCount ?? 0}</strong>
                </div>
                <div className="flex justify-between" style={{ padding: '0.4rem 0', borderBottom: '1px solid var(--border-color)' }}>
                  <span style={{ color: 'var(--text-secondary)' }}>Approved Leave Days</span>
                  <strong style={{ color: 'var(--success-text)' }}>{absenceStats?.summary?.approvedAbsence ?? 0}</strong>
                </div>
                <div className="flex justify-between" style={{ padding: '0.4rem 0', borderBottom: '1px solid var(--border-color)' }}>
                  <span style={{ color: 'var(--text-secondary)' }}>Unexcused Absences</span>
                  <strong style={{ color: 'var(--danger-text)' }}>{absenceStats?.summary?.unapprovedAbsence ?? 0}</strong>
                </div>
                <div className="flex justify-between" style={{ padding: '0.4rem 0', borderBottom: '1px solid var(--border-color)' }}>
                  <span style={{ color: 'var(--text-secondary)' }}>Overall Absence Rate</span>
                  <strong>{absenceStats?.summary?.absenceRate ?? 0}%</strong>
                </div>
              </div>
            </div>
          </div>

          {/* Request Pipeline Analytics */}
          <div className="card flex flex-col justify-between">
            <div>
              <div className="flex items-center gap-2" style={{ marginBottom: '1rem' }}>
                <FileCheck size={20} color="var(--primary)" />
                <h4>Workflow Resolution Times</h4>
              </div>
              <div className="flex flex-col gap-2" style={{ fontSize: '0.875rem' }}>
                <div className="flex justify-between" style={{ padding: '0.4rem 0', borderBottom: '1px solid var(--border-color)' }}>
                  <span style={{ color: 'var(--text-secondary)' }}>Approval Rate</span>
                  <strong style={{ color: 'var(--success-text)' }}>{requestStats?.summary?.approvalRate ?? 0}%</strong>
                </div>
                <div className="flex justify-between" style={{ padding: '0.4rem 0', borderBottom: '1px solid var(--border-color)' }}>
                  <span style={{ color: 'var(--text-secondary)' }}>Rejection Rate</span>
                  <strong style={{ color: 'var(--danger-text)' }}>{requestStats?.summary?.rejectionRate ?? 0}%</strong>
                </div>
                <div className="flex justify-between" style={{ padding: '0.4rem 0', borderBottom: '1px solid var(--border-color)' }}>
                  <span style={{ color: 'var(--text-secondary)' }}>Avg Turnaround Time</span>
                  <strong>{requestStats?.summary?.averageProcessingDurationHours ?? 0} hrs</strong>
                </div>
                <div className="flex justify-between" style={{ padding: '0.4rem 0', borderBottom: '1px solid var(--border-color)' }}>
                  <span style={{ color: 'var(--text-secondary)' }}>Total Requests Logged</span>
                  <strong>{requestStats?.summary?.totalRequests ?? 0}</strong>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
