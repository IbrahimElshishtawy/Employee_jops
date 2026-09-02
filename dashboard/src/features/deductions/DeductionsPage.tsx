import React, { useEffect, useState } from 'react';
import { Receipt, Plus } from 'lucide-react';
import { api } from '../../core/network/api-client';
import { DataTable, Column } from '../../shared/components/DataTable';
import { Button } from '../../shared/components/Button';
import { Modal } from '../../shared/components/Modal';

export const DeductionsPage: React.FC = () => {
  const [deductions, setDeductions] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [employees, setEmployees] = useState<any[]>([]);

  const [form, setForm] = useState({
    employeeId: '',
    type: 'LATENESS',
    amount: 250,
    reason: '',
    effectiveDate: new Date().toISOString().split('T')[0],
  });

  const fetchDeductions = async () => {
    setIsLoading(true);
    try {
      const [dedRes, empRes] = await Promise.all([
        api.get('/payroll/deductions'),
        api.get('/employees'),
      ]);
      setDeductions(Array.isArray(dedRes.data) ? dedRes.data : dedRes.data?.data || []);
      const empList = Array.isArray(empRes.data) ? empRes.data : empRes.data?.data || [];
      setEmployees(empList);
      if (empList.length > 0 && !form.employeeId) {
        setForm((prev) => ({ ...prev, employeeId: empList[0].id }));
      }
    } catch {
      // Fallback
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchDeductions();
  }, []);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      await api.post('/payroll/deductions', form);
      setIsCreateOpen(false);
      fetchDeductions();
    } catch (err: any) {
      alert(err.message || 'Failed to create deduction');
    } finally {
      setIsSubmitting(false);
    }
  };

  const columns: Column<any>[] = [
    {
      key: 'employee',
      header: 'Employee',
      render: (d) => (
        <div>
          <span style={{ fontWeight: 600 }}>{d.employee?.firstName} {d.employee?.lastName}</span>
          <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{d.employee?.employeeCode}</p>
        </div>
      ),
    },
    {
      key: 'type',
      header: 'Deduction Type',
      render: (d) => (
        <span className="badge badge-warning">
          <Receipt size={12} />
          {d.type}
        </span>
      ),
    },
    {
      key: 'amount',
      header: 'Amount',
      render: (d) => (
        <span style={{ fontWeight: 700, color: 'var(--danger)' }}>
          - EGP {Number(d.amount || 0).toLocaleString()}
        </span>
      ),
    },
    { key: 'reason', header: 'Reason' },
    {
      key: 'date',
      header: 'Effective Date',
      render: (d) => <span>{new Date(d.effectiveDate).toISOString().split('T')[0]}</span>,
    },
  ];

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800 }}>Deductions & Penalties</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
            Record and manage manual adjustments, disciplinary penalties, and lateness deductions
          </p>
        </div>
        <Button variant="primary" icon={<Plus size={16} />} onClick={() => setIsCreateOpen(true)}>
          Add Deduction
        </Button>
      </div>

      <DataTable columns={columns} data={deductions} isLoading={isLoading} />

      {/* Create Deduction Modal */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="Add Financial Deduction"
        footer={
          <>
            <Button variant="secondary" onClick={() => setIsCreateOpen(false)}>
              Cancel
            </Button>
            <Button variant="primary" onClick={handleCreate} isLoading={isSubmitting}>
              Apply Deduction
            </Button>
          </>
        }
      >
        <form className="flex flex-col gap-3">
          <div>
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
              Select Employee *
            </label>
            <select
              className="select"
              value={form.employeeId}
              onChange={(e) => setForm({ ...form, employeeId: e.target.value })}
            >
              {employees.map((emp) => (
                <option key={emp.id} value={emp.id}>
                  {emp.firstName} {emp.lastName} ({emp.employeeCode})
                </option>
              ))}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                Deduction Type *
              </label>
              <select
                className="select"
                value={form.type}
                onChange={(e) => setForm({ ...form, type: e.target.value })}
              >
                <option value="LATENESS">Lateness</option>
                <option value="ABSENCE">Absence</option>
                <option value="PENALTY">Penalty</option>
                <option value="DAMAGE">Damage</option>
                <option value="TAX">Tax</option>
                <option value="INSURANCE">Insurance</option>
                <option value="OTHER">Other</option>
              </select>
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                Amount (EGP) *
              </label>
              <input
                required
                type="number"
                className="input"
                value={form.amount}
                onChange={(e) => setForm({ ...form, amount: Number(e.target.value) })}
              />
            </div>
          </div>

          <div>
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
              Reason / Violation Note *
            </label>
            <textarea
              required
              rows={3}
              className="textarea"
              placeholder="e.g. Unexcused absence on Monday without prior permission notice"
              value={form.reason}
              onChange={(e) => setForm({ ...form, reason: e.target.value })}
            />
          </div>
        </form>
      </Modal>
    </div>
  );
};
