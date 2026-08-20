import React, { useEffect, useState } from 'react';
import { Calendar, Clock, Plus } from 'lucide-react';
import { api } from '../../core/network/api-client';
import { DataTable, Column } from '../../shared/components/DataTable';
import { Button } from '../../shared/components/Button';
import { Modal } from '../../shared/components/Modal';

const DAY_NAMES = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

export const SchedulesPage: React.FC = () => {
  const [schedules, setSchedules] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [form, setForm] = useState({
    name: '',
    description: '',
    startTime: '09:00',
    endTime: '17:00',
    graceMinutesCheckIn: 15,
    graceMinutesCheckOut: 15,
    workingDays: [0, 1, 2, 3, 4], // Sun - Thu
  });

  const fetchSchedules = async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/schedules');
      setSchedules(Array.isArray(res.data) ? res.data : []);
    } catch {
      // Fallback
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchSchedules();
  }, []);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      await api.post('/schedules', form);
      setIsCreateOpen(false);
      setForm({
        name: '',
        description: '',
        startTime: '09:00',
        endTime: '17:00',
        graceMinutesCheckIn: 15,
        graceMinutesCheckOut: 15,
        workingDays: [0, 1, 2, 3, 4],
      });
      fetchSchedules();
    } catch (err: any) {
      alert(err.message || 'Failed to create schedule');
    } finally {
      setIsSubmitting(false);
    }
  };

  const toggleDay = (dayIndex: number) => {
    setForm((prev) => {
      const exists = prev.workingDays.includes(dayIndex);
      return {
        ...prev,
        workingDays: exists
          ? prev.workingDays.filter((d) => d !== dayIndex)
          : [...prev.workingDays, dayIndex].sort(),
      };
    });
  };

  const columns: Column<any>[] = [
    {
      key: 'name',
      header: 'Schedule Name',
      render: (s) => (
        <div className="flex items-center gap-2">
          <Calendar size={16} color="var(--primary)" />
          <span style={{ fontWeight: 600 }}>{s.name}</span>
        </div>
      ),
    },
    {
      key: 'hours',
      header: 'Working Hours',
      render: (s) => (
        <div className="flex items-center gap-1" style={{ fontFamily: 'var(--font-mono)' }}>
          <Clock size={14} color="var(--text-muted)" />
          <span>{s.startTime} – {s.endTime}</span>
        </div>
      ),
    },
    {
      key: 'grace',
      header: 'Grace Periods',
      render: (s) => (
        <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
          In: {s.graceMinutesCheckIn || 15}m • Out: {s.graceMinutesCheckOut || 15}m
        </span>
      ),
    },
    {
      key: 'workingDays',
      header: 'Working Days',
      render: (s) => (
        <div className="flex gap-1 flex-wrap">
          {DAY_NAMES.map((day, idx) => {
            const isWorkDay = Array.isArray(s.workingDays) && s.workingDays.includes(idx);
            return (
              <span
                key={day}
                style={{
                  fontSize: '0.7rem',
                  padding: '0.15rem 0.4rem',
                  borderRadius: '4px',
                  backgroundColor: isWorkDay ? 'var(--primary-light)' : 'var(--bg-tertiary)',
                  color: isWorkDay ? 'var(--primary-text)' : 'var(--text-muted)',
                  fontWeight: isWorkDay ? 700 : 500,
                }}
              >
                {day}
              </span>
            );
          })}
        </div>
      ),
    },
  ];

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800 }}>Shift Schedules</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
            Define corporate shifts, working day masks, and allowable check-in grace minutes
          </p>
        </div>
        <Button
          variant="primary"
          icon={<Plus size={16} />}
          onClick={() => setIsCreateOpen(true)}
        >
          Add Shift Schedule
        </Button>
      </div>

      <DataTable columns={columns} data={schedules} isLoading={isLoading} />

      {/* Create Modal */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="Create Shift Schedule"
        footer={
          <>
            <Button variant="secondary" onClick={() => setIsCreateOpen(false)}>
              Cancel
            </Button>
            <Button variant="primary" onClick={handleCreate} isLoading={isSubmitting}>
              Save Schedule
            </Button>
          </>
        }
      >
        <form className="flex flex-col gap-3">
          <div>
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
              Schedule Name *
            </label>
            <input
              required
              className="input"
              placeholder="Standard Morning Shift (9am - 5pm)"
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                Shift Start Time *
              </label>
              <input
                required
                type="time"
                className="input"
                value={form.startTime}
                onChange={(e) => setForm({ ...form, startTime: e.target.value })}
              />
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                Shift End Time *
              </label>
              <input
                required
                type="time"
                className="input"
                value={form.endTime}
                onChange={(e) => setForm({ ...form, endTime: e.target.value })}
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                Grace Period Check-In (mins)
              </label>
              <input
                type="number"
                className="input"
                value={form.graceMinutesCheckIn}
                onChange={(e) => setForm({ ...form, graceMinutesCheckIn: parseInt(e.target.value, 10) })}
              />
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                Grace Period Check-Out (mins)
              </label>
              <input
                type="number"
                className="input"
                value={form.graceMinutesCheckOut}
                onChange={(e) => setForm({ ...form, graceMinutesCheckOut: parseInt(e.target.value, 10) })}
              />
            </div>
          </div>

          <div>
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.5rem' }}>
              Working Days
            </label>
            <div className="flex gap-2 flex-wrap">
              {DAY_NAMES.map((day, idx) => {
                const isSelected = form.workingDays.includes(idx);
                return (
                  <button
                    key={day}
                    type="button"
                    className={`btn btn-sm ${isSelected ? 'btn-primary' : 'btn-secondary'}`}
                    onClick={() => toggleDay(idx)}
                  >
                    {day}
                  </button>
                );
              })}
            </div>
          </div>
        </form>
      </Modal>
    </div>
  );
};
