import React, { useEffect, useState } from 'react';
import { Building2, Users, FileCheck, UserCheck } from 'lucide-react';
import { api } from '../../core/network/api-client';

export const DepartmentsPage: React.FC = () => {
  const [departments, setDepartments] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const fetchDepartments = async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/reports/departments');
      setDepartments(Array.isArray(res.data) ? res.data : []);
    } catch {
      // Fallback
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchDepartments();
  }, []);

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 style={{ fontSize: '1.75rem', fontWeight: 800 }}>Departments & Divisions</h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
          Headcount allocation, active presence, and pending departmental requests
        </p>
      </div>

      {isLoading ? (
        <div className="grid grid-cols-3 gap-4">
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="card" style={{ height: '140px', background: 'var(--bg-tertiary)' }} />
          ))}
        </div>
      ) : departments.length === 0 ? (
        <div className="card" style={{ textAlign: 'center', padding: '3rem 1rem' }}>
          <Building2 size={36} color="var(--text-muted)" style={{ margin: '0 auto 0.5rem' }} />
          <p style={{ color: 'var(--text-secondary)' }}>No department metrics available</p>
        </div>
      ) : (
        <div className="grid grid-cols-3 gap-4">
          {departments.map((dept) => (
            <div key={dept.department} className="card card-hover flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Building2 size={20} color="var(--primary)" />
                  <h3 style={{ fontSize: '1.1rem' }}>{dept.department}</h3>
                </div>
                <span className="badge badge-primary">{dept.employeeCount} Members</span>
              </div>

              <div className="grid grid-cols-2 gap-2" style={{ marginTop: '1.25rem', paddingTop: '1rem', borderTop: '1px solid var(--border-color)', fontSize: '0.85rem' }}>
                <div className="flex items-center gap-2">
                  <UserCheck size={16} color="var(--success)" />
                  <span>Present: <strong>{dept.todayPresent ?? '—'}</strong></span>
                </div>
                <div className="flex items-center gap-2">
                  <FileCheck size={16} color="var(--warning)" />
                  <span>Pending: <strong>{dept.pendingRequests ?? 0}</strong></span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
