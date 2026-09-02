import React, { useEffect, useState } from 'react';
import { CreditCard, Plus, Calculator, CheckCircle2 } from 'lucide-react';
import { api } from '../../core/network/api-client';
import { DataTable, Column } from '../../shared/components/DataTable';
import { Button } from '../../shared/components/Button';
import { Modal, ConfirmDialog } from '../../shared/components/Modal';
import { StatusBadge } from '../../shared/components/Badge';

export const PayrollPage: React.FC = () => {
  const [periods, setPeriods] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [finalizeTarget, setFinalizeTarget] = useState<any | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [periodForm, setPeriodForm] = useState({
    name: `2026-${String(new Date().getMonth() + 1).padStart(2, '0')}`,
    startDate: new Date(Date.UTC(2026, new Date().getMonth(), 1)).toISOString().split('T')[0],
    endDate: new Date(Date.UTC(2026, new Date().getMonth() + 1, 0)).toISOString().split('T')[0],
  });

  const fetchPeriods = async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/payroll/periods');
      setPeriods(Array.isArray(res.data) ? res.data : res.data?.data || []);
    } catch {
      // Fallback
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchPeriods();
  }, []);

  const handleCreatePeriod = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      await api.post('/payroll/periods', periodForm);
      setIsCreateOpen(false);
      fetchPeriods();
    } catch (err: any) {
      alert(err.message || 'Failed to create period');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleCalculate = async (periodId: string) => {
    try {
      await api.post(`/payroll/periods/${periodId}/calculate`, {});
      alert('Payroll calculation finished successfully');
      fetchPeriods();
    } catch (err: any) {
      alert(err.message || 'Calculation error');
    }
  };

  const handleFinalize = async () => {
    if (!finalizeTarget) return;
    setIsSubmitting(true);
    try {
      await api.post(`/payroll/periods/${finalizeTarget.id}/finalize`, {});
      setFinalizeTarget(null);
      fetchPeriods();
    } catch (err: any) {
      alert(err.message || 'Finalization error');
    } finally {
      setIsSubmitting(false);
    }
  };

  const columns: Column<any>[] = [
    {
      key: 'name',
      header: 'Payroll Cycle',
      render: (p) => (
        <div className="flex items-center gap-2">
          <CreditCard size={16} color="var(--primary)" />
          <span style={{ fontWeight: 700, fontFamily: 'var(--font-mono)' }}>{p.name}</span>
        </div>
      ),
    },
    {
      key: 'dates',
      header: 'Period Dates',
      render: (p) => (
        <span style={{ fontSize: '0.85rem' }}>
          {new Date(p.startDate).toISOString().split('T')[0]} to {new Date(p.endDate).toISOString().split('T')[0]}
        </span>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      render: (p) => <StatusBadge status={p.status} />,
    },
    {
      key: 'recordsCount',
      header: 'Employees Processed',
      render: (p) => <span>{p._count?.payrollRecords ?? 0} Records</span>,
    },
    {
      key: 'actions',
      header: 'Actions',
      render: (p) => (
        <div className="flex items-center gap-2">
          {p.status === 'OPEN' && (
            <Button
              variant="secondary"
              size="sm"
              icon={<Calculator size={14} />}
              onClick={() => handleCalculate(p.id)}
            >
              Calculate
            </Button>
          )}
          {p.status !== 'FINALIZED' && (
            <Button
              variant="primary"
              size="sm"
              icon={<CheckCircle2 size={14} />}
              onClick={() => setFinalizeTarget(p)}
            >
              Finalize
            </Button>
          )}
        </div>
      ),
    },
  ];

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800 }}>Payroll Periods & Finalization</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
            Manage monthly salary calculation cycles, itemized payslips, and deduction locks
          </p>
        </div>
        <Button variant="primary" icon={<Plus size={16} />} onClick={() => setIsCreateOpen(true)}>
          Create Payroll Period
        </Button>
      </div>

      <DataTable columns={columns} data={periods} isLoading={isLoading} />

      {/* Create Period Modal */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="Open New Payroll Period"
        footer={
          <>
            <Button variant="secondary" onClick={() => setIsCreateOpen(false)}>
              Cancel
            </Button>
            <Button variant="primary" onClick={handleCreatePeriod} isLoading={isSubmitting}>
              Open Period
            </Button>
          </>
        }
      >
        <form className="flex flex-col gap-3">
          <div>
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
              Period Name (Cycle Label) *
            </label>
            <input
              required
              className="input"
              placeholder="2026-08"
              value={periodForm.name}
              onChange={(e) => setPeriodForm({ ...periodForm, name: e.target.value })}
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                Start Date *
              </label>
              <input
                required
                type="date"
                className="input"
                value={periodForm.startDate}
                onChange={(e) => setPeriodForm({ ...periodForm, startDate: e.target.value })}
              />
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                End Date *
              </label>
              <input
                required
                type="date"
                className="input"
                value={periodForm.endDate}
                onChange={(e) => setPeriodForm({ ...periodForm, endDate: e.target.value })}
              />
            </div>
          </div>
        </form>
      </Modal>

      {/* Finalize Confirmation Dialog */}
      <ConfirmDialog
        isOpen={!!finalizeTarget}
        onClose={() => setFinalizeTarget(null)}
        onConfirm={handleFinalize}
        title="Finalize & Lock Payroll Period"
        message={`Are you sure you want to finalize and lock the payroll period '${finalizeTarget?.name}'? Once finalized, salary numbers are frozen and employee payslips become immutable.`}
        confirmLabel="Finalize & Lock Period"
        isLoading={isSubmitting}
      />
    </div>
  );
};
