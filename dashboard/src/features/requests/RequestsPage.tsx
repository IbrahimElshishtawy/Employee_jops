import React, { useEffect, useState } from 'react';
import { Check, X } from 'lucide-react';
import { api } from '../../core/network/api-client';
import { DataTable, Column } from '../../shared/components/DataTable';
import { Button } from '../../shared/components/Button';
import { Modal } from '../../shared/components/Modal';
import { StatusBadge } from '../../shared/components/Badge';

export const RequestsPage: React.FC = () => {
  const [requests, setRequests] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);

  const [statusFilter, setStatusFilter] = useState('');
  const [rejectModalTarget, setRejectModalTarget] = useState<any | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const fetchRequests = async (p = page) => {
    setIsLoading(true);
    try {
      const params = new URLSearchParams();
      params.set('page', String(p));
      params.set('limit', '10');
      if (statusFilter) params.set('status', statusFilter);

      const res = await api.get(`/requests?${params.toString()}`);
      const list = Array.isArray(res.data) ? res.data : res.data?.data || [];
      setRequests(list);
      setTotal(res.data?.meta?.total || list.length);
      setTotalPages(res.data?.meta?.totalPages || 1);
    } catch {
      // Fallback
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchRequests(page);
  }, [page, statusFilter]);

  const handleApprove = async (id: string) => {
    try {
      await api.post(`/requests/${id}/approve`, {});
      fetchRequests(page);
    } catch (err: any) {
      alert(err.message || 'Failed to approve request');
    }
  };

  const handleReject = async () => {
    if (!rejectModalTarget) return;
    if (!rejectionReason.trim()) {
      alert('Please provide a rejection reason');
      return;
    }

    setIsSubmitting(true);
    try {
      await api.post(`/requests/${rejectModalTarget.id}/reject`, {
        reason: rejectionReason,
      });
      setRejectModalTarget(null);
      setRejectionReason('');
      fetchRequests(page);
    } catch (err: any) {
      alert(err.message || 'Failed to reject request');
    } finally {
      setIsSubmitting(false);
    }
  };

  const columns: Column<any>[] = [
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
      key: 'type',
      header: 'Request Type',
      render: (r) => (
        <span className="badge badge-primary">
          {r.type?.replace(/_/g, ' ')}
        </span>
      ),
    },
    {
      key: 'dates',
      header: 'Duration',
      render: (r) => (
        <div style={{ fontSize: '0.8rem', fontFamily: 'var(--font-mono)' }}>
          {new Date(r.startDate).toISOString().split('T')[0]} to {new Date(r.endDate).toISOString().split('T')[0]}
        </div>
      ),
    },
    {
      key: 'reason',
      header: 'Reason',
      render: (r) => <span style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>{r.reason}</span>,
    },
    {
      key: 'status',
      header: 'Status',
      render: (r) => <StatusBadge status={r.status} />,
    },
    {
      key: 'actions',
      header: 'Review',
      render: (r) => (
        r.status === 'PENDING' ? (
          <div className="flex items-center gap-2">
            <Button
              variant="primary"
              size="sm"
              icon={<Check size={14} />}
              onClick={() => handleApprove(r.id)}
            >
              Approve
            </Button>
            <Button
              variant="danger"
              size="sm"
              icon={<X size={14} />}
              onClick={() => {
                setRejectModalTarget(r);
                setRejectionReason('');
              }}
            >
              Reject
            </Button>
          </div>
        ) : (
          <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Reviewed</span>
        )
      ),
    },
  ];

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800 }}>Employee Requests & Leave Management</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
            Review, approve, or reject employee leave balances, excuses, and remote work requests
          </p>
        </div>

        <div className="flex items-center gap-2">
          <select
            className="select"
            style={{ width: '160px' }}
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="">All Statuses</option>
            <option value="PENDING">Pending Only</option>
            <option value="APPROVED">Approved</option>
            <option value="REJECTED">Rejected</option>
          </select>
        </div>
      </div>

      <DataTable
        columns={columns}
        data={requests}
        isLoading={isLoading}
        page={page}
        totalPages={totalPages}
        total={total}
        onPageChange={setPage}
      />

      {/* Reject Modal with Mandatory Reason */}
      <Modal
        isOpen={!!rejectModalTarget}
        onClose={() => setRejectModalTarget(null)}
        title="Reject Employee Request"
        footer={
          <>
            <Button variant="secondary" onClick={() => setRejectModalTarget(null)}>
              Cancel
            </Button>
            <Button variant="danger" onClick={handleReject} isLoading={isSubmitting}>
              Confirm Rejection
            </Button>
          </>
        }
      >
        <div className="flex flex-col gap-3">
          <p style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>
            Please state the mandatory business reason for rejecting this request for{' '}
            <strong>{rejectModalTarget?.employee?.firstName} {rejectModalTarget?.employee?.lastName}</strong>.
          </p>
          <textarea
            required
            rows={4}
            className="textarea"
            placeholder="e.g. Insufficient project staffing during requested dates..."
            value={rejectionReason}
            onChange={(e) => setRejectionReason(e.target.value)}
          />
        </div>
      </Modal>
    </div>
  );
};
