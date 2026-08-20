import React, { useEffect, useState } from 'react';
import { Plus, Eye, Edit, Trash2 } from 'lucide-react';
import { api } from '../../core/network/api-client';
import { DataTable, Column } from '../../shared/components/DataTable';
import { Button } from '../../shared/components/Button';
import { Modal, ConfirmDialog } from '../../shared/components/Modal';
import { StatusBadge } from '../../shared/components/Badge';

export const EmployeesPage: React.FC = () => {
  const [employees, setEmployees] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);
  const [search, setSearch] = useState('');

  // Modals state
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [viewEmployee, setViewEmployee] = useState<any | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<any | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Form State for create
  const [createForm, setCreateForm] = useState({
    email: '',
    password: '',
    firstName: '',
    lastName: '',
    employeeCode: '',
    department: 'Engineering',
    jobTitle: '',
    baseSalary: 15000,
    role: 'EMPLOYEE',
  });

  const fetchEmployees = async (currPage = page, searchTerm = search) => {
    setIsLoading(true);
    try {
      const res = await api.get('/employees', {
        headers: {},
      });
      // Handle pagination or array response
      const list = Array.isArray(res.data) ? res.data : res.data?.data || [];
      setEmployees(list);
      setTotal(res.data?.meta?.total || list.length);
      setTotalPages(res.data?.meta?.totalPages || 1);
    } catch {
      // Fallback
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchEmployees(page, search);
  }, [page]);

  const handleCreateEmployee = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      await api.post('/employees', createForm);
      setIsCreateOpen(false);
      setCreateForm({
        email: '',
        password: '',
        firstName: '',
        lastName: '',
        employeeCode: '',
        department: 'Engineering',
        jobTitle: '',
        baseSalary: 15000,
        role: 'EMPLOYEE',
      });
      fetchEmployees(1);
    } catch (err: any) {
      alert(err.message || 'Failed to create employee');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteEmployee = async () => {
    if (!deleteTarget) return;
    setIsSubmitting(true);
    try {
      await api.delete(`/employees/${deleteTarget.id}`);
      setDeleteTarget(null);
      fetchEmployees(page);
    } catch (err: any) {
      alert(err.message || 'Failed to delete employee');
    } finally {
      setIsSubmitting(false);
    }
  };

  const columns: Column<any>[] = [
    {
      key: 'employeeCode',
      header: 'Code',
      render: (emp) => <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 600 }}>{emp.employeeCode}</span>,
    },
    {
      key: 'name',
      header: 'Employee Name',
      render: (emp) => (
        <div className="flex items-center gap-3">
          <div
            style={{
              width: '32px',
              height: '32px',
              borderRadius: '50%',
              backgroundColor: 'var(--primary-light)',
              color: 'var(--primary)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: 700,
              fontSize: '0.8rem',
            }}
          >
            {emp.firstName?.[0]}
          </div>
          <div>
            <span style={{ fontWeight: 600 }}>{emp.firstName} {emp.lastName}</span>
            <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{emp.user?.email || '—'}</p>
          </div>
        </div>
      ),
    },
    { key: 'department', header: 'Department' },
    { key: 'jobTitle', header: 'Job Title' },
    {
      key: 'status',
      header: 'Status',
      render: (emp) => <StatusBadge status={emp.user?.status || (emp.isProfileComplete ? 'ACTIVE' : 'PENDING')} />,
    },
    {
      key: 'actions',
      header: 'Actions',
      render: (emp) => (
        <div className="flex items-center gap-1">
          <button
            className="btn btn-ghost btn-icon"
            onClick={() => setViewEmployee(emp)}
            title="View Profile Details"
          >
            <Eye size={16} />
          </button>
          <button
            className="btn btn-ghost btn-icon"
            onClick={() => setDeleteTarget(emp)}
            title="Remove Employee"
            style={{ color: 'var(--danger)' }}
          >
            <Trash2 size={16} />
          </button>
        </div>
      ),
    },
  ];

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800 }}>Employee Directory</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
            Manage staff profiles, departmental allocations, and work credentials
          </p>
        </div>
        <Button
          variant="primary"
          icon={<Plus size={16} />}
          onClick={() => setIsCreateOpen(true)}
        >
          Add Employee
        </Button>
      </div>

      {/* Directory Table */}
      <DataTable
        columns={columns}
        data={employees}
        isLoading={isLoading}
        page={page}
        totalPages={totalPages}
        total={total}
        onPageChange={setPage}
        searchValue={search}
        onSearchChange={(val) => {
          setSearch(val);
          fetchEmployees(1, val);
        }}
        searchPlaceholder="Search employees by name, code, or email..."
      />

      {/* Create Employee Modal */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="Add New Employee"
        footer={
          <>
            <Button variant="secondary" onClick={() => setIsCreateOpen(false)}>
              Cancel
            </Button>
            <Button variant="primary" onClick={handleCreateEmployee} isLoading={isSubmitting}>
              Create Employee
            </Button>
          </>
        }
      >
        <form className="flex flex-col gap-3">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                First Name *
              </label>
              <input
                required
                className="input"
                placeholder="Ahmed"
                value={createForm.firstName}
                onChange={(e) => setCreateForm({ ...createForm, firstName: e.target.value })}
              />
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                Last Name *
              </label>
              <input
                required
                className="input"
                placeholder="Mansour"
                value={createForm.lastName}
                onChange={(e) => setCreateForm({ ...createForm, lastName: e.target.value })}
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                Work Email *
              </label>
              <input
                required
                type="email"
                className="input"
                placeholder="ahmed@cyberwise.com"
                value={createForm.email}
                onChange={(e) => setCreateForm({ ...createForm, email: e.target.value })}
              />
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                Employee Code *
              </label>
              <input
                required
                className="input"
                placeholder="CW-0105"
                value={createForm.employeeCode}
                onChange={(e) => setCreateForm({ ...createForm, employeeCode: e.target.value })}
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                Department *
              </label>
              <select
                className="select"
                value={createForm.department}
                onChange={(e) => setCreateForm({ ...createForm, department: e.target.value })}
              >
                <option value="Engineering">Engineering</option>
                <option value="Product">Product</option>
                <option value="Design">Design</option>
                <option value="HR">HR & People</option>
                <option value="Finance">Finance</option>
                <option value="Operations">Operations</option>
              </select>
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                Job Title *
              </label>
              <input
                required
                className="input"
                placeholder="Software Engineer"
                value={createForm.jobTitle}
                onChange={(e) => setCreateForm({ ...createForm, jobTitle: e.target.value })}
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                Initial Password *
              </label>
              <input
                required
                type="password"
                className="input"
                placeholder="••••••••••••"
                value={createForm.password}
                onChange={(e) => setCreateForm({ ...createForm, password: e.target.value })}
              />
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.3rem' }}>
                Base Salary (EGP)
              </label>
              <input
                type="number"
                className="input"
                value={createForm.baseSalary}
                onChange={(e) => setCreateForm({ ...createForm, baseSalary: Number(e.target.value) })}
              />
            </div>
          </div>
        </form>
      </Modal>

      {/* View Employee Profile Drawer */}
      {viewEmployee && (
        <Modal
          isOpen={!!viewEmployee}
          onClose={() => setViewEmployee(null)}
          title={`Profile: ${viewEmployee.firstName} ${viewEmployee.lastName}`}
          footer={
            <Button variant="secondary" onClick={() => setViewEmployee(null)}>
              Close
            </Button>
          }
        >
          <div className="flex flex-col gap-4">
            <div className="flex items-center gap-4" style={{ paddingBottom: '1rem', borderBottom: '1px solid var(--border-color)' }}>
              <div
                style={{
                  width: '56px',
                  height: '56px',
                  borderRadius: '50%',
                  backgroundColor: 'var(--primary)',
                  color: '#fff',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontWeight: 800,
                  fontSize: '1.25rem',
                }}
              >
                {viewEmployee.firstName?.[0]}
              </div>
              <div>
                <h3 style={{ fontSize: '1.1rem' }}>{viewEmployee.firstName} {viewEmployee.lastName}</h3>
                <p style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>{viewEmployee.jobTitle} • {viewEmployee.department}</p>
                <div className="flex items-center gap-2" style={{ marginTop: '0.25rem' }}>
                  <StatusBadge status={viewEmployee.user?.status || 'ACTIVE'} />
                  <span style={{ fontSize: '0.75rem', fontFamily: 'var(--font-mono)', color: 'var(--text-muted)' }}>
                    {viewEmployee.employeeCode}
                  </span>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4" style={{ fontSize: '0.875rem' }}>
              <div>
                <span style={{ color: 'var(--text-muted)', fontSize: '0.75rem', textTransform: 'uppercase', fontWeight: 600 }}>
                  Email
                </span>
                <p style={{ fontWeight: 600 }}>{viewEmployee.user?.email || '—'}</p>
              </div>
              <div>
                <span style={{ color: 'var(--text-muted)', fontSize: '0.75rem', textTransform: 'uppercase', fontWeight: 600 }}>
                  Phone
                </span>
                <p style={{ fontWeight: 600 }}>{viewEmployee.phone || '—'}</p>
              </div>
              <div>
                <span style={{ color: 'var(--text-muted)', fontSize: '0.75rem', textTransform: 'uppercase', fontWeight: 600 }}>
                  Workplace
                </span>
                <p style={{ fontWeight: 600 }}>{viewEmployee.workplace?.name || 'Main Branch'}</p>
              </div>
              <div>
                <span style={{ color: 'var(--text-muted)', fontSize: '0.75rem', textTransform: 'uppercase', fontWeight: 600 }}>
                  Base Salary
                </span>
                <p style={{ fontWeight: 700, color: 'var(--primary)' }}>
                  EGP {Number(viewEmployee.baseSalary || 0).toLocaleString()}
                </p>
              </div>
            </div>
          </div>
        </Modal>
      )}

      {/* Delete Confirmation */}
      <ConfirmDialog
        isOpen={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={handleDeleteEmployee}
        title="Delete Employee Record"
        message={`Are you sure you want to remove ${deleteTarget?.firstName} ${deleteTarget?.lastName} (${deleteTarget?.employeeCode})? This will revoke system access.`}
        confirmLabel="Delete Employee"
        isLoading={isSubmitting}
      />
    </div>
  );
};
