import React from 'react';
import {
  LayoutDashboard,
  Users,
  Building2,
  MapPin,
  Calendar,
  Clock,
  FileCheck,
  CreditCard,
  Coins,
  Receipt,
  BarChart3,
  Megaphone,
  MessageSquare,
  ShieldCheck,
  LogOut,
  ChevronRight,
} from 'lucide-react';
import { NAV_ITEMS, NavItem } from '../../core/constants/permissions';
import { useAuth } from '../../core/routing/auth-context';

const iconMap: Record<string, React.ReactNode> = {
  LayoutDashboard: <LayoutDashboard size={18} />,
  Users: <Users size={18} />,
  Building2: <Building2 size={18} />,
  MapPin: <MapPin size={18} />,
  Calendar: <Calendar size={18} />,
  Clock: <Clock size={18} />,
  FileCheck: <FileCheck size={18} />,
  CreditCard: <CreditCard size={18} />,
  Coins: <Coins size={18} />,
  Receipt: <Receipt size={18} />,
  BarChart3: <BarChart3 size={18} />,
  Megaphone: <Megaphone size={18} />,
  MessageSquare: <MessageSquare size={18} />,
  ShieldCheck: <ShieldCheck size={18} />,
};

interface SidebarProps {
  currentPath: string;
  onNavigate: (path: string) => void;
  isOpen: boolean;
  onClose: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentPath,
  onNavigate,
  isOpen,
  onClose,
}) => {
  const { user, logout, hasRole } = useAuth();

  const allowedNavItems = NAV_ITEMS.filter((item) => hasRole(item.roles));

  return (
    <>
      {/* Mobile Backdrop */}
      {isOpen && (
        <div
          onClick={onClose}
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(0,0,0,0.5)',
            zIndex: 40,
          }}
          className="md:hidden"
        />
      )}

      <aside
        style={{
          width: '260px',
          backgroundColor: 'var(--bg-secondary)',
          borderRight: '1px solid var(--border-color)',
          display: 'flex',
          flexDirection: 'column',
          height: '100vh',
          position: 'sticky',
          top: 0,
          zIndex: 45,
          transition: 'transform 0.2s ease',
        }}
      >
        {/* Brand Header */}
        <div
          style={{
            padding: '1.25rem 1.5rem',
            borderBottom: '1px solid var(--border-color)',
            display: 'flex',
            alignItems: 'center',
            gap: '0.75rem',
          }}
        >
          <div
            style={{
              width: '36px',
              height: '36px',
              borderRadius: '8px',
              background: 'linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#fff',
              fontWeight: 800,
              fontSize: '1.1rem',
            }}
          >
            CW
          </div>
          <div>
            <h4 style={{ fontSize: '1rem', fontWeight: 800, lineHeight: 1.2 }}>CyberWise IE</h4>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 500 }}>
              HR Intelligence
            </span>
          </div>
        </div>

        {/* Navigation List */}
        <div style={{ flex: 1, overflowY: 'auto', padding: '1rem 0.75rem' }} className="flex flex-col gap-1">
          {allowedNavItems.map((item: NavItem) => {
            const isActive = currentPath === item.path || currentPath.startsWith(`${item.path}/`);
            return (
              <button
                key={item.id}
                onClick={() => {
                  onNavigate(item.path);
                  onClose();
                }}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '0.625rem 0.875rem',
                  borderRadius: 'var(--radius-sm)',
                  border: 'none',
                  background: isActive ? 'var(--primary-light)' : 'transparent',
                  color: isActive ? 'var(--primary)' : 'var(--text-secondary)',
                  cursor: 'pointer',
                  fontWeight: isActive ? 700 : 500,
                  fontSize: '0.875rem',
                  textAlign: 'left',
                  transition: 'all 0.15s ease',
                }}
              >
                <div className="flex items-center gap-3">
                  <span style={{ color: isActive ? 'var(--primary)' : 'var(--text-muted)' }}>
                    {iconMap[item.icon] || <LayoutDashboard size={18} />}
                  </span>
                  <span>{item.label}</span>
                </div>
                {isActive && <ChevronRight size={14} />}
              </button>
            );
          })}
        </div>

        {/* User Info / Logout Footer */}
        <div
          style={{
            padding: '1rem 1.25rem',
            borderTop: '1px solid var(--border-color)',
            backgroundColor: 'var(--bg-tertiary)',
          }}
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3 overflow-hidden">
              <div
                style={{
                  width: '34px',
                  height: '34px',
                  borderRadius: '50%',
                  backgroundColor: 'var(--primary)',
                  color: '#fff',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontWeight: 700,
                  fontSize: '0.875rem',
                  flexShrink: 0,
                }}
              >
                {user?.employeeProfile?.firstName?.[0] || user?.email?.[0]?.toUpperCase() || 'U'}
              </div>
              <div style={{ minWidth: 0, overflow: 'hidden' }}>
                <p
                  style={{
                    fontSize: '0.85rem',
                    fontWeight: 700,
                    whiteSpace: 'nowrap',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                  }}
                >
                  {user?.employeeProfile ? `${user.employeeProfile.firstName} ${user.employeeProfile.lastName}` : user?.email}
                </p>
                <span
                  style={{
                    fontSize: '0.7rem',
                    color: 'var(--text-muted)',
                    textTransform: 'uppercase',
                    fontWeight: 600,
                  }}
                >
                  {user?.role?.replace(/_/g, ' ')}
                </span>
              </div>
            </div>
            <button
              onClick={logout}
              className="btn btn-ghost btn-icon"
              title="Log out"
              style={{ color: 'var(--danger)' }}
            >
              <LogOut size={16} />
            </button>
          </div>
        </div>
      </aside>
    </>
  );
};
