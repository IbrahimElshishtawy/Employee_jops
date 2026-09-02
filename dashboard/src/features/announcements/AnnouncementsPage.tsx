import React, { useEffect, useState } from 'react';
import { Megaphone, Plus, Send, XCircle } from 'lucide-react';
import { api } from '../../core/network/api-client';
import { DataTable, Column } from '../../shared/components/DataTable';
import { Button } from '../../shared/components/Button';
import { Modal } from '../../shared/components/Modal';
import { StatusBadge } from '../../shared/components/Badge';

export const AnnouncementsPage: React.FC = () => {
  const [announcements, setAnnouncements] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [form, setForm] = useState({
    title: '',
    body: '',
    targetType: 'ALL',
    targetDepartment: '',
  });

  const fetchAnnouncements = async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/announcements');
      setAnnouncements(Array.isArray(res.data) ? res.data : res.data?.data || []);
    } catch {
      // Fallback
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchAnnouncements();
  }, []);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      await api.post('/announcements', form);
      setIsCreateOpen(false);
      setForm({ title: '', body: '', targetType: 'ALL', targetDepartment: '' });
      fetchAnnouncements();
    } catch (err: any) {
      alert(err.message || 'Failed to create announcement');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handlePublish = async (id: string) => {
    try {
      await api.post(`/announcements/${id}/publish`, {});
      fetchAnnouncements();
    } catch (err: any) {
      alert(err.message || 'Publishing error');
    }
  };

  const handleCancel = async (id: string) => {
    try {
      await api.post(`/announcements/${id}/cancel`, {});
      fetchAnnouncements();
    } catch (err: any) {
      alert(err.message || 'Cancellation error');
    }
  };

  const columns: Column<any>[] = [
    {
      key: 'title',
      header: 'Title & Content',
      render: (a) => (
        <div>
          <div className="flex items-center gap-2">
            <Megaphone size={16} color="var(--primary)" />
            <strong style={{ fontSize: '0.95rem' }}>{a.title}</strong>
          </div>
          <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginTop: '0.2rem' }}>
            {a.body}
          </p>
        </div>
      ),
    },
    {
      key: 'target',
      header: 'Audience Scope',
      render: (a) => (
        <span className="badge badge-primary">
          {a.targetType === 'DEPARTMENT' ? `Dept: ${a.targetDepartment}` : a.targetType}
        </span>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      render: (a) => <StatusBadge status={a.status} />,
    },
    {
      key: 'created',
      header: 'Created At',
      render: (a) => <span style={{ fontSize: '0.8rem' }}>{new Date(a.createdAt).toLocaleDateString()}</span>,
    },
    {
      key: 'actions',
      header: 'Actions',
      render: (a) => (
        <div className="flex items-center gap-2">
          {a.status === 'DRAFT' && (
            <Button
              variant="primary"
              size="sm"
              icon={<Send size={14} />}
              onClick={() => handlePublish(a.id)}
            >
              Publish
            </Button>
          )}
          {a.status === 'PUBLISHED' && (
            <Button
              variant="danger"
              size="sm"
              icon={<XCircle size={14} />}
              onClick={() => handleCancel(a.id)}
            >
              Cancel
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
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800 }}>HR Broadcast Announcements</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
            Publish company-wide and departmental notices, push notifications, and corporate updates
          </p>
        </div>
        <Button variant="primary" icon={<Plus size={16} />} onClick={() => setIsCreateOpen(true)}>
          New Announcement
        </Button>
      </div>

      <DataTable columns={columns} data={announcements} isLoading={isLoading} />

      {/* Create Modal */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="Create Broadcast Announcement"
        footer={
          <>
            <Button variant="secondary" onClick={() => setIsCreateOpen(false)}>
              Cancel
            </Button>
            <Button variant="primary" onClick={handleCreate} isLoading={isSubmitting}>
              Save as Draft
            </Button>
          </>
        }
      >
        <form className="flex flex-col gap-3">
          <div>
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
              Announcement Title *
            </label>
            <input
              required
              className="input"
              placeholder="e.g. Annual Company All-Hands Meeting"
              value={form.title}
              onChange={(e) => setForm({ ...form, title: e.target.value })}
            />
          </div>

          <div>
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
              Audience Scope *
            </label>
            <select
              className="select"
              value={form.targetType}
              onChange={(e) => setForm({ ...form, targetType: e.target.value })}
            >
              <option value="ALL">All Company Staff</option>
              <option value="DEPARTMENT">Specific Department</option>
            </select>
          </div>

          {form.targetType === 'DEPARTMENT' && (
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                Department Name *
              </label>
              <input
                required
                className="input"
                placeholder="Engineering"
                value={form.targetDepartment}
                onChange={(e) => setForm({ ...form, targetDepartment: e.target.value })}
              />
            </div>
          )}

          <div>
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
              Notice Content *
            </label>
            <textarea
              required
              rows={4}
              className="textarea"
              placeholder="Write the full announcement message here..."
              value={form.body}
              onChange={(e) => setForm({ ...form, body: e.target.value })}
            />
          </div>
        </form>
      </Modal>
    </div>
  );
};
