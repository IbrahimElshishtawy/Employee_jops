import React, { useEffect, useState } from 'react';
import { useAuth } from './core/routing/auth-context';
import { LoginPage } from './features/auth/LoginPage';
import { AppShell } from './shared/layout/AppShell';

// Feature Pages
import { DashboardPage } from './features/dashboard/DashboardPage';
import { EmployeesPage } from './features/employees/EmployeesPage';
import { DepartmentsPage } from './features/departments/DepartmentsPage';
import { WorkplacesPage } from './features/workplaces/WorkplacesPage';
import { SchedulesPage } from './features/schedules/SchedulesPage';
import { AttendancePage } from './features/attendance/AttendancePage';
import { RequestsPage } from './features/requests/RequestsPage';
import { PayrollPage } from './features/payroll/PayrollPage';
import { AdvancesPage } from './features/advances/AdvancesPage';
import { DeductionsPage } from './features/deductions/DeductionsPage';
import { ReportsPage } from './features/reports/ReportsPage';
import { AnnouncementsPage } from './features/announcements/AnnouncementsPage';
import { MessagesPage } from './features/messages/MessagesPage';
import { AuditLogsPage } from './features/audit/AuditLogsPage';

export const App: React.FC = () => {
  const { isAuthenticated, isLoading } = useAuth();
  const [currentPath, setCurrentPath] = useState<string>(() => {
    return window.location.pathname === '/' ? '/dashboard' : window.location.pathname;
  });

  useEffect(() => {
    const handlePopState = () => {
      setCurrentPath(window.location.pathname);
    };
    window.addEventListener('popstate', handlePopState);
    return () => window.removeEventListener('popstate', handlePopState);
  }, []);

  const handleNavigate = (path: string) => {
    window.history.pushState({}, '', path);
    setCurrentPath(path);
    window.scrollTo(0, 0);
  };

  if (isLoading) {
    return (
      <div
        style={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: 'var(--bg-primary)',
          color: 'var(--primary)',
          fontSize: '1.25rem',
          fontWeight: 700,
        }}
      >
        <div className="flex items-center gap-3">
          <div
            style={{
              width: '24px',
              height: '24px',
              border: '3px solid var(--primary)',
              borderTopColor: 'transparent',
              borderRadius: '50%',
              animation: 'spin 0.8s linear infinite',
            }}
          />
          <span>Authenticating Session...</span>
        </div>
      </div>
    );
  }

  if (!isAuthenticated || currentPath === '/login') {
    return <LoginPage />;
  }

  // Generate breadcrumb trail
  const pathSegments = currentPath.split('/').filter(Boolean);
  const breadcrumbs = pathSegments.map(
    (seg) => seg.charAt(0).toUpperCase() + seg.slice(1),
  );

  const renderContent = () => {
    switch (currentPath) {
      case '/dashboard':
        return <DashboardPage onNavigate={handleNavigate} />;
      case '/employees':
        return <EmployeesPage />;
      case '/departments':
        return <DepartmentsPage />;
      case '/workplaces':
        return <WorkplacesPage />;
      case '/schedules':
        return <SchedulesPage />;
      case '/attendance':
        return <AttendancePage />;
      case '/requests':
        return <RequestsPage />;
      case '/payroll':
        return <PayrollPage />;
      case '/advances':
        return <AdvancesPage />;
      case '/deductions':
        return <DeductionsPage />;
      case '/reports':
        return <ReportsPage />;
      case '/announcements':
        return <AnnouncementsPage />;
      case '/messages':
        return <MessagesPage />;
      case '/audit':
        return <AuditLogsPage />;
      default:
        return <DashboardPage onNavigate={handleNavigate} />;
    }
  };

  return (
    <AppShell
      currentPath={currentPath}
      onNavigate={handleNavigate}
      breadcrumbs={breadcrumbs.length > 0 ? breadcrumbs : ['Dashboard']}
    >
      {renderContent()}
    </AppShell>
  );
};
