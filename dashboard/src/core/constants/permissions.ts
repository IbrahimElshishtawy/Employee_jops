export enum Role {
  SUPER_ADMIN = 'SUPER_ADMIN',
  HR_ADMIN = 'HR_ADMIN',
  HR_MANAGER = 'HR_MANAGER',
  SUPERVISOR = 'SUPERVISOR',
  EMPLOYEE = 'EMPLOYEE',
}

export interface NavItem {
  id: string;
  label: string;
  path: string;
  icon: string;
  roles: Role[];
  badgeKey?: string;
}

export const NAV_ITEMS: NavItem[] = [
  {
    id: 'dashboard',
    label: 'Dashboard',
    path: '/dashboard',
    icon: 'LayoutDashboard',
    roles: [Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR, Role.EMPLOYEE],
  },
  {
    id: 'employees',
    label: 'Employees',
    path: '/employees',
    icon: 'Users',
    roles: [Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR],
  },
  {
    id: 'departments',
    label: 'Departments',
    path: '/departments',
    icon: 'Building2',
    roles: [Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER],
  },
  {
    id: 'workplaces',
    label: 'Workplaces',
    path: '/workplaces',
    icon: 'MapPin',
    roles: [Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR, Role.EMPLOYEE],
  },
  {
    id: 'schedules',
    label: 'Schedules',
    path: '/schedules',
    icon: 'Calendar',
    roles: [Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR, Role.EMPLOYEE],
  },
  {
    id: 'attendance',
    label: 'Attendance',
    path: '/attendance',
    icon: 'Clock',
    roles: [Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR, Role.EMPLOYEE],
  },
  {
    id: 'requests',
    label: 'Requests & Leaves',
    path: '/requests',
    icon: 'FileCheck',
    roles: [Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR, Role.EMPLOYEE],
    badgeKey: 'pendingRequests',
  },
  {
    id: 'payroll',
    label: 'Payroll & Salaries',
    path: '/payroll',
    icon: 'CreditCard',
    roles: [Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER],
  },
  {
    id: 'advances',
    label: 'Salary Advances',
    path: '/advances',
    icon: 'Coins',
    roles: [Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.EMPLOYEE],
    badgeKey: 'pendingAdvances',
  },
  {
    id: 'deductions',
    label: 'Deductions & Penalties',
    path: '/deductions',
    icon: 'Receipt',
    roles: [Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER],
  },
  {
    id: 'reports',
    label: 'Reports & Intelligence',
    path: '/reports',
    icon: 'BarChart3',
    roles: [Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR],
  },
  {
    id: 'announcements',
    label: 'Announcements',
    path: '/announcements',
    icon: 'Megaphone',
    roles: [Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR, Role.EMPLOYEE],
  },
  {
    id: 'messages',
    label: 'Messages',
    path: '/messages',
    icon: 'MessageSquare',
    roles: [Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR, Role.EMPLOYEE],
  },
  {
    id: 'audit',
    label: 'Audit Trail',
    path: '/audit',
    icon: 'ShieldCheck',
    roles: [Role.SUPER_ADMIN, Role.HR_ADMIN],
  },
];
