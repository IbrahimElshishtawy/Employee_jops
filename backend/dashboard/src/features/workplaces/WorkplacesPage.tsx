import React, { useEffect, useState } from 'react';
import { MapPin, Plus, Shield } from 'lucide-react';
import { api } from '../../core/network/api-client';
import { DataTable, Column } from '../../shared/components/DataTable';
import { Button } from '../../shared/components/Button';
import { Modal } from '../../shared/components/Modal';
import { StatusBadge } from '../../shared/components/Badge';

export const WorkplacesPage: React.FC = () => {
  const [workplaces, setWorkplaces] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [form, setForm] = useState({
    name: '',
    code: '',
    address: '',
    latitude: 30.0444,
    longitude: 31.2357,
    radiusMeters: 100,
  });

  const fetchWorkplaces = async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/workplaces');
      setWorkplaces(Array.isArray(res.data) ? res.data : []);
    } catch {
      // Fallback
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchWorkplaces();
  }, []);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      await api.post('/workplaces', form);
      setIsCreateOpen(false);
      setForm({
        name: '',
        code: '',
        address: '',
        latitude: 30.0444,
        longitude: 31.2357,
        radiusMeters: 100,
      });
      fetchWorkplaces();
    } catch (err: any) {
      alert(err.message || 'Failed to create workplace');
    } finally {
      setIsSubmitting(false);
    }
  };

  const columns: Column<any>[] = [
    {
      key: 'code',
      header: 'Branch Code',
      render: (w) => <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 600 }}>{w.code}</span>,
    },
    {
      key: 'name',
      header: 'Workplace Name',
      render: (w) => (
        <div className="flex items-center gap-2">
          <MapPin size={16} color="var(--primary)" />
          <span style={{ fontWeight: 600 }}>{w.name}</span>
        </div>
      ),
    },
    { key: 'address', header: 'Address' },
    {
      key: 'geofence',
      header: 'Geofence Radius',
      render: (w) => (
        <span className="badge badge-info">
          <Shield size={12} />
          {w.radiusMeters || 100}m radius
        </span>
      ),
    },
    {
      key: 'coordinates',
      header: 'Coordinates',
      render: (w) => (
        <span style={{ fontSize: '0.75rem', fontFamily: 'var(--font-mono)', color: 'var(--text-muted)' }}>
          {Number(w.latitude).toFixed(4)}, {Number(w.longitude).toFixed(4)}
        </span>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      render: (w) => <StatusBadge status={w.isActive ? 'ACTIVE' : 'INACTIVE'} />,
    },
  ];

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800 }}>Workplaces & Geofences</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
            Configure corporate branches, allowed GPS geofence zones, and check-in boundaries
          </p>
        </div>
        <Button
          variant="primary"
          icon={<Plus size={16} />}
          onClick={() => setIsCreateOpen(true)}
        >
          Add Workplace
        </Button>
      </div>

      <DataTable columns={columns} data={workplaces} isLoading={isLoading} />

      {/* Create Modal */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="Add Workplace Branch"
        footer={
          <>
            <Button variant="secondary" onClick={() => setIsCreateOpen(false)}>
              Cancel
            </Button>
            <Button variant="primary" onClick={handleCreate} isLoading={isSubmitting}>
              Save Workplace
            </Button>
          </>
        }
      >
        <form className="flex flex-col gap-3">
          <div>
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
              Branch Name *
            </label>
            <input
              required
              className="input"
              placeholder="Cairo Main HQ"
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
            />
          </div>

          <div>
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
              Branch Code *
            </label>
            <input
              required
              className="input"
              placeholder="CAI-HQ"
              value={form.code}
              onChange={(e) => setForm({ ...form, code: e.target.value })}
            />
          </div>

          <div>
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
              Address
            </label>
            <input
              className="input"
              placeholder="Smart Village, Building B12, Giza"
              value={form.address}
              onChange={(e) => setForm({ ...form, address: e.target.value })}
            />
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                Latitude *
              </label>
              <input
                required
                type="number"
                step="any"
                className="input"
                value={form.latitude}
                onChange={(e) => setForm({ ...form, latitude: parseFloat(e.target.value) })}
              />
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                Longitude *
              </label>
              <input
                required
                type="number"
                step="any"
                className="input"
                value={form.longitude}
                onChange={(e) => setForm({ ...form, longitude: parseFloat(e.target.value) })}
              />
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                Radius (Meters)
              </label>
              <input
                required
                type="number"
                className="input"
                value={form.radiusMeters}
                onChange={(e) => setForm({ ...form, radiusMeters: parseInt(e.target.value, 10) })}
              />
            </div>
          </div>
        </form>
      </Modal>
    </div>
  );
};
