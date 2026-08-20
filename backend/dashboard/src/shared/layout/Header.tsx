import React from 'react';
import { Menu, Moon, Sun, Bell, Shield, User as UserIcon } from 'lucide-react';
import { useTheme } from '../../core/theme/theme-provider';
import { useAuth } from '../../core/routing/auth-context';

interface HeaderProps {
  onToggleSidebar: () => void;
  breadcrumbs: string[];
  unreadNotificationsCount?: number;
  onOpenNotifications: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  onToggleSidebar,
  breadcrumbs,
  unreadNotificationsCount = 0,
  onOpenNotifications,
}) => {
  const { theme, toggleTheme } = useTheme();
  const { user } = useAuth();

  return (
    <header
      style={{
        height: '64px',
        backgroundColor: 'var(--bg-glass)',
        backdropFilter: 'blur(8px)',
        borderBottom: '1px solid var(--border-color)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '0 1.5rem',
        position: 'sticky',
        top: 0,
        zIndex: 30,
      }}
    >
      {/* Left: Mobile Menu & Breadcrumbs */}
      <div className="flex items-center gap-3">
        <button
          className="btn btn-ghost btn-icon md:hidden"
          onClick={onToggleSidebar}
          aria-label="Toggle Navigation"
        >
          <Menu size={20} />
        </button>

        <div className="flex items-center gap-2" style={{ fontSize: '0.875rem' }}>
          <span style={{ color: 'var(--text-muted)' }}>HR Portal</span>
          {breadcrumbs.map((crumb, idx) => (
            <React.Fragment key={idx}>
              <span style={{ color: 'var(--text-muted)' }}>/</span>
              <span
                style={{
                  fontWeight: idx === breadcrumbs.length - 1 ? 700 : 500,
                  color: idx === breadcrumbs.length - 1 ? 'var(--text-primary)' : 'var(--text-secondary)',
                }}
              >
                {crumb}
              </span>
            </React.Fragment>
          ))}
        </div>
      </div>

      {/* Right: Actions (Theme, Notifications, Profile) */}
      <div className="flex items-center gap-3">
        {/* Security Indicator */}
        <div
          className="hidden sm:flex items-center gap-1 badge badge-success"
          title="RBAC Active & Encrypted Session"
          style={{ fontSize: '0.7rem', padding: '0.2rem 0.6rem' }}
        >
          <Shield size={12} />
          <span>SECURE</span>
        </div>

        {/* Dark/Light Theme Toggle */}
        <button
          className="btn btn-ghost btn-icon"
          onClick={toggleTheme}
          title={theme === 'dark' ? 'Switch to Light Mode' : 'Switch to Dark Mode'}
        >
          {theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
        </button>

        {/* Notifications Trigger */}
        <button
          className="btn btn-ghost btn-icon"
          onClick={onOpenNotifications}
          style={{ position: 'relative' }}
          title="View Notifications"
        >
          <Bell size={18} />
          {unreadNotificationsCount > 0 && (
            <span
              style={{
                position: 'absolute',
                top: '4px',
                right: '4px',
                width: '8px',
                height: '8px',
                borderRadius: '50%',
                backgroundColor: 'var(--danger)',
              }}
            />
          )}
        </button>

        {/* User Pill */}
        <div
          className="flex items-center gap-2"
          style={{
            padding: '0.25rem 0.5rem',
            borderRadius: 'var(--radius-sm)',
            border: '1px solid var(--border-color)',
            backgroundColor: 'var(--bg-secondary)',
          }}
        >
          <UserIcon size={16} color="var(--primary)" />
          <span style={{ fontSize: '0.8rem', fontWeight: 600 }}>
            {user?.employeeProfile?.firstName || user?.email?.split('@')[0] || 'User'}
          </span>
        </div>
      </div>
    </header>
  );
};
