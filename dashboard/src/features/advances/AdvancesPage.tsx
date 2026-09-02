import React, { useEffect, useState } from 'react';
import { Coins, Check, X } from 'lucide-react';
import { api } from '../../core/network/api-client';
import { DataTable, Column } from '../../shared/components/DataTable';
import { Button } from '../../shared/components/Button';
import { StatusBadge } from '../../shared/components/Badge';

export const AdvancesPage: React.FC = () => {
  const [advances, setAdvances] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const fetchAdvances = async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/payroll/advances');
      setAdvances(Array.isArray(res.data) ? res.data : res.data?.data || []);
    } catch {
      // Fallback
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchAdvances();
  }, []);

  const handleApprove = async (id: string, amount: number) => {
    try {
      await api.post(`/payroll/advances/${id}/approve`, {
        approvedAmount: amount,
        installmentsCount: 1,
      });
      fetchAdvances();
    } catch (err: any) {
      alert(err.message || 'Approval error');
    }
  };

  const handleReject = async (id: string) => {
    const reason = prompt('Please enter rejection reason:');
    if (!reason) return;
    try {
      await api.post(`/payroll/advances/${id}/reject`, { reason });
      fetchAdvances();
    } catch (err: any) {
      alert(err.message || 'Rejection error');
    }
  };

  const columns: Column<any>[] = [
    {
      key: 'employee',
      header: 'Employee',
      render: (a) => (
        <div>
          <span style={{ fontWeight: 600 }}>{a.employee?.firstName} {a.employee?.lastName}</span>
          <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{a.employee?.employeeCode}</p>
        </div>
      ),
    },
    {
      key: 'amount',
      header: 'Requested Amount',
      render: (a) => (
        <span style={{ fontWeight: 700, color: 'var(--primary)' }}>
          EGP {Number(a.amount || 0).toLocaleString()}
        </span>
      ),
    },
    {
      key: 'balance',
      header: 'Remaining Balance',
      render: (a) => (
        <span style={{ fontWeight: 600, color: Number(a.remainingAmount) > 0 ? 'var(--warning-text)' : 'var(--success-text)' }}>
          EGP {Number(a.remainingAmount || 0).toLocaleString()}
        </span>
      ),
    },
    {
      key: 'reason',
      header: 'Reason',
      render: (a) => <span style={{ fontSize: '0.85rem' }}>{a.reason}</span>,
    },
    {
      key: 'status',
      header: 'Status',
      render: (a) => <StatusBadge status={a.status} />,
    },
    {
      key: 'actions',
      header: 'Review',
      render: (a) => (
        a.status === 'PENDING' ? (
          <div className="flex items-center gap-2">
            <Button
              variant="primary"
              size="sm"
              icon={<Check size={14} />}
              onClick={() => handleApprove(a.id, Number(a.amount))}
            >
              Approve
            </Button>
            <Button
              variant="danger"
              size="sm"
              icon={<X size={14} />}
              onClick={() => handleReject(a.id)}
            >
              Reject
            </Button>
          </div>
        ) : (
          <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Processed</span>
        )
      ),
    },
  ];

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800 }}>Salary Advances & Loans</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
            Review employee financial advance requests, manage repayment balances and installment schedules
          </p>
        </div>
      </div>

      <DataTable columns={columns} data={advances} isLoading={isLoading} />
    </div>
  );
};
