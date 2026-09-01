import {
  PrismaClient,
  Role,
  UserStatus,
  Gender,
  BranchType,
  PositionLevel,
  SettingCategory,
  PermissionAction,
  PermissionSubject,
} from "@prisma/client";
import * as argon2 from "argon2";

const prisma = new PrismaClient();

async function main() {
  console.log("🌱 Starting Enterprise Database Seed (Phase 1 — Organization, RBAC & Settings)...");

  // ==========================================
  // 1. CREATE DEFAULT ORGANIZATION
  // ==========================================
  const organization = await prisma.organization.upsert({
    where: { code: "CW-CORP" },
    update: {},
    create: {
      name: "CyberWise Hospitality & Enterprise Group",
      code: "CW-CORP",
      description: "Authoritative Enterprise Workforce & Operations Management Platform",
      address: "100 Innovation Boulevard, Smart Village",
      phone: "+20220001000",
      email: "info@cyberwise.com",
      currency: "EGP",
      timezone: "Africa/Cairo",
      isActive: true,
    },
  });
  console.log(`🏢 Organization: ${organization.name} (${organization.code})`);

  // ==========================================
  // 2. CREATE DEFAULT BRANCH / HOTEL
  // ==========================================
  const headquartersBranch = await prisma.branch.upsert({
    where: { code: "GNH-HQ" },
    update: {},
    create: {
      organizationId: organization.id,
      name: "Grand Nile Headquarters & Resort",
      code: "GNH-HQ",
      type: BranchType.HEADQUARTERS,
      address: "Corniche El Nile, Garden City",
      city: "Cairo",
      country: "Egypt",
      phone: "+20220002000",
      email: "cairo-hq@cyberwise.com",
      latitude: 30.0444,
      longitude: 31.2357,
      radiusMeters: 150,
      isActive: true,
    },
  });
  console.log(`🏨 Branch/Hotel: ${headquartersBranch.name} (${headquartersBranch.code})`);

  // ==========================================
  // 3. CREATE DEFAULT DEPARTMENTS
  // ==========================================
  const executiveDept = await prisma.department.upsert({
    where: { code: "EXEC-DEPT" },
    update: {},
    create: {
      organizationId: organization.id,
      branchId: headquartersBranch.id,
      name: "Executive Management",
      code: "EXEC-DEPT",
      description: "C-Level Leadership and Corporate Strategy",
    },
  });

  const hrDept = await prisma.department.upsert({
    where: { code: "HR-DEPT" },
    update: {},
    create: {
      organizationId: organization.id,
      branchId: headquartersBranch.id,
      name: "Human Resources",
      code: "HR-DEPT",
      description: "Talent Acquisition, Employee Relations, and Payroll",
    },
  });

  const engineeringDept = await prisma.department.upsert({
    where: { code: "ENG-DEPT" },
    update: {},
    create: {
      organizationId: organization.id,
      branchId: headquartersBranch.id,
      name: "Engineering & IT",
      code: "ENG-DEPT",
      description: "Software Engineering, Infrastructure, and Cybersecurity",
    },
  });

  const operationsDept = await prisma.department.upsert({
    where: { code: "OPS-DEPT" },
    update: {},
    create: {
      organizationId: organization.id,
      branchId: headquartersBranch.id,
      name: "Operations & Facilities",
      code: "OPS-DEPT",
      description: "Facility Maintenance and Daily Operational Support",
    },
  });

  const fbDept = await prisma.department.upsert({
    where: { code: "FB-DEPT" },
    update: {},
    create: {
      organizationId: organization.id,
      branchId: headquartersBranch.id,
      name: "Food & Beverage",
      code: "FB-DEPT",
      description: "Restaurants, Kitchens, and Banquet Services",
    },
  });
  console.log(`📂 Departments initialized: Executive, HR, Engineering, Operations, F&B`);

  // ==========================================
  // 4. CREATE DEFAULT SECTIONS
  // ==========================================
  const softwareSec = await prisma.section.upsert({
    where: { code: "ENG-SW-SEC" },
    update: {},
    create: {
      departmentId: engineeringDept.id,
      name: "Software Development",
      code: "ENG-SW-SEC",
      description: "Backend, Frontend, and Mobile Applications",
    },
  });

  const pastrySec = await prisma.section.upsert({
    where: { code: "FB-PASTRY-SEC" },
    update: {},
    create: {
      departmentId: fbDept.id,
      name: "Pastry & Bakery",
      code: "FB-PASTRY-SEC",
      description: "Bakery and Pastry Production",
    },
  });
  console.log(`📑 Sections initialized: Software Development, Pastry & Bakery`);

  // ==========================================
  // 5. CREATE DEFAULT POSITIONS
  // ==========================================
  const ceoPosition = await prisma.position.upsert({
    where: { code: "POS-CEO" },
    update: {},
    create: {
      organizationId: organization.id,
      departmentId: executiveDept.id,
      title: "Chief Executive Officer",
      code: "POS-CEO",
      level: PositionLevel.EXECUTIVE,
    },
  });

  const hrManagerPosition = await prisma.position.upsert({
    where: { code: "POS-HR-MGR" },
    update: {},
    create: {
      organizationId: organization.id,
      departmentId: hrDept.id,
      title: "HR Manager",
      code: "POS-HR-MGR",
      level: PositionLevel.MANAGER,
    },
  });

  const seniorDevPosition = await prisma.position.upsert({
    where: { code: "POS-SR-DEV" },
    update: {},
    create: {
      organizationId: organization.id,
      departmentId: engineeringDept.id,
      sectionId: softwareSec.id,
      title: "Senior Software Engineer",
      code: "POS-SR-DEV",
      level: PositionLevel.SENIOR,
    },
  });
  console.log(`👔 Positions initialized: CEO, HR Manager, Senior Software Engineer`);

  // ==========================================
  // 6. CREATE DEFAULT WORKPLACE & SCHEDULE
  // ==========================================
  const headquartersWorkplace = await prisma.workplace.upsert({
    where: { code: "HQ-MAIN" },
    update: {
      organizationId: organization.id,
      branchId: headquartersBranch.id,
    },
    create: {
      name: "CyberWise Headquarters Geofence",
      code: "HQ-MAIN",
      address: "100 Innovation Boulevard, Smart Village",
      latitude: 30.0444,
      longitude: 31.2357,
      radiusMeters: 100,
      organizationId: organization.id,
      branchId: headquartersBranch.id,
      isActive: true,
    },
  });

  const defaultSchedule = await prisma.schedule.upsert({
    where: { id: "default-standard-schedule" },
    update: {},
    create: {
      id: "default-standard-schedule",
      name: "Standard Working Hours",
      description: "Sunday to Thursday, 09:00 - 17:00",
      workplaceId: headquartersWorkplace.id,
      startTime: "09:00",
      endTime: "17:00",
      graceMinutesCheckIn: 15,
      graceMinutesCheckOut: 15,
      workingDays: [0, 1, 2, 3, 4, 5, 6],
      isDefault: true,
    },
  });

  // ==========================================
  // 7. CANONICAL PERMISSIONS CATALOG
  // ==========================================
  const canonicalPermissions = [
    // Organization
    { slug: "organization:read", action: PermissionAction.READ, subject: PermissionSubject.ORGANIZATION, module: "organization", description: "View organization structure, branches, and departments" },
    { slug: "organization:manage", action: PermissionAction.MANAGE, subject: PermissionSubject.ORGANIZATION, module: "organization", description: "Create and update organization, branches, and departments" },
    // Employees
    { slug: "employees:read", action: PermissionAction.READ, subject: PermissionSubject.EMPLOYEES, module: "employees", description: "View employee profiles" },
    { slug: "employees:create", action: PermissionAction.CREATE, subject: PermissionSubject.EMPLOYEES, module: "employees", description: "Create employee profiles" },
    { slug: "employees:update", action: PermissionAction.UPDATE, subject: PermissionSubject.EMPLOYEES, module: "employees", description: "Update employee details" },
    { slug: "employees:delete", action: PermissionAction.DELETE, subject: PermissionSubject.EMPLOYEES, module: "employees", description: "Delete employee profiles" },
    // Attendance
    { slug: "attendance:read", action: PermissionAction.READ, subject: PermissionSubject.ATTENDANCE, module: "attendance", description: "View attendance records" },
    { slug: "attendance:manage", action: PermissionAction.MANAGE, subject: PermissionSubject.ATTENDANCE, module: "attendance", description: "Adjust and correct attendance logs" },
    // Schedules
    { slug: "schedules:read", action: PermissionAction.READ, subject: PermissionSubject.SCHEDULES, module: "schedules", description: "View work schedules" },
    { slug: "schedules:manage", action: PermissionAction.MANAGE, subject: PermissionSubject.SCHEDULES, module: "schedules", description: "Manage shifts and assign schedules" },
    // Requests
    { slug: "requests:read", action: PermissionAction.READ, subject: PermissionSubject.REQUESTS, module: "requests", description: "View leave and permission requests" },
    { slug: "requests:approve", action: PermissionAction.EXECUTE, subject: PermissionSubject.REQUESTS, module: "requests", description: "Approve or reject requests" },
    // Payroll
    { slug: "payroll:read", action: PermissionAction.READ, subject: PermissionSubject.PAYROLL, module: "payroll", description: "View payroll periods and slips" },
    { slug: "payroll:calculate", action: PermissionAction.EXECUTE, subject: PermissionSubject.PAYROLL, module: "payroll", description: "Execute payroll calculation" },
    { slug: "payroll:finalize", action: PermissionAction.EXECUTE, subject: PermissionSubject.PAYROLL, module: "payroll", description: "Finalize and lock payroll cycles" },
    // Reports
    { slug: "reports:read", action: PermissionAction.READ, subject: PermissionSubject.REPORTS, module: "reports", description: "Generate and download HR reports" },
    // Settings
    { slug: "settings:read", action: PermissionAction.READ, subject: PermissionSubject.SETTINGS, module: "settings", description: "View system settings" },
    { slug: "settings:manage", action: PermissionAction.MANAGE, subject: PermissionSubject.SETTINGS, module: "settings", description: "Modify system configuration and feature flags" },
    // Roles & Permissions
    { slug: "roles:read", action: PermissionAction.READ, subject: PermissionSubject.ROLES, module: "roles", description: "View roles and permission matrices" },
    { slug: "roles:manage", action: PermissionAction.MANAGE, subject: PermissionSubject.ROLES, module: "roles", description: "Create and assign custom roles" },
    // Audit Logs
    { slug: "audit-logs:read", action: PermissionAction.READ, subject: PermissionSubject.AUDIT_LOGS, module: "audit-logs", description: "View compliance audit trails" },
  ];

  for (const perm of canonicalPermissions) {
    await prisma.permission.upsert({
      where: { slug: perm.slug },
      update: { description: perm.description, module: perm.module },
      create: perm,
    });
  }
  console.log(`🔐 Seeded ${canonicalPermissions.length} Canonical System Permissions`);

  // ==========================================
  // 8. SYSTEM ROLES & PERMISSION MATRICES
  // ==========================================
  const allPermissions = await prisma.permission.findMany();
  const allPermIds = allPermissions.map((p) => ({ permissionId: p.id }));

  const roleSuperAdmin = await prisma.roleRecord.upsert({
    where: { slug: "super-admin" },
    update: {},
    create: {
      name: "Super Administrator",
      slug: "super-admin",
      description: "Full authoritative control over all system domains",
      isSystem: true,
      rolePermissions: { create: allPermIds },
    },
  });

  const hrManagerPerms = allPermissions
    .filter((p) => p.slug !== "settings:manage" && p.slug !== "roles:manage")
    .map((p) => ({ permissionId: p.id }));

  const roleHrManager = await prisma.roleRecord.upsert({
    where: { slug: "hr-manager" },
    update: {},
    create: {
      name: "HR Manager",
      slug: "hr-manager",
      description: "Manages employees, schedules, attendance, leaves, and payroll",
      isSystem: true,
      rolePermissions: { create: hrManagerPerms },
    },
  });

  const employeePerms = allPermissions
    .filter((p) =>
      ["attendance:read", "requests:read", "payroll:read", "organization:read"].includes(
        p.slug,
      ),
    )
    .map((p) => ({ permissionId: p.id }));

  const roleEmployee = await prisma.roleRecord.upsert({
    where: { slug: "employee" },
    update: {},
    create: {
      name: "Standard Employee",
      slug: "employee",
      description: "Self-service mobile/web access",
      isSystem: true,
      rolePermissions: { create: employeePerms },
    },
  });
  console.log(`🛡️ Seeded System Roles: super-admin, hr-manager, employee`);

  // ==========================================
  // 9. SYSTEM SETTINGS & FEATURE FLAGS
  // ==========================================
  const systemSettingsSeed = [
    { key: "company_name", value: "CyberWise Hospitality Group", category: SettingCategory.GENERAL, isPublic: true, description: "Official company display name" },
    { key: "default_currency", value: "EGP", category: SettingCategory.GENERAL, isPublic: true, description: "Base operating currency" },
    { key: "attendance_grace_period_minutes", value: 15, category: SettingCategory.ATTENDANCE, isPublic: true, description: "Allowed check-in grace duration" },
    { key: "max_gps_accuracy_meters", value: 50, category: SettingCategory.ATTENDANCE, isPublic: true, description: "Max GPS accuracy accepted for geofence check-in" },
    { key: "enable_google_login", value: true, category: SettingCategory.SECURITY, isPublic: true, description: "Allow Google Workspace SSO" },
  ];

  for (const s of systemSettingsSeed) {
    await prisma.systemSetting.upsert({
      where: { key: s.key },
      update: { value: s.value, category: s.category, isPublic: s.isPublic },
      create: s,
    });
  }

  const featureFlagsSeed = [
    { key: "enable_biometric_face_id", isEnabled: false, description: "Biometric facial recognition at check-in", rolloutPercentage: 0 },
    { key: "enable_auto_payroll_calculation", isEnabled: true, description: "Automatic end-of-month payroll computation", rolloutPercentage: 100 },
    { key: "enable_reporting_hierarchy", isEnabled: true, description: "Hierarchical org-chart visualization", rolloutPercentage: 100 },
  ];

  for (const f of featureFlagsSeed) {
    await prisma.featureFlag.upsert({
      where: { key: f.key },
      update: { isEnabled: f.isEnabled, description: f.description },
      create: f,
    });
  }
  console.log(`⚙️ Seeded System Settings & Feature Flags`);

  // ==========================================
  // 10. SEED CORE ACCOUNTS WITH FULL HIERARCHY
  // ==========================================
  const defaultPasswordHash = await argon2.hash("Test@123456");

  // Super Admin
  const superAdmin = await prisma.user.upsert({
    where: { email: "admin@example.test" },
    update: {},
    create: {
      email: "admin@example.test",
      passwordHash: defaultPasswordHash,
      role: Role.SUPER_ADMIN,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        create: {
          employeeCode: "CW-0001",
          firstName: "System",
          lastName: "Administrator",
          phone: "+966500000001",
          nationalId: "1000000001",
          jobTitle: "Chief Executive Officer",
          department: "Executive Management",
          gender: Gender.MALE,
          organizationId: organization.id,
          branchId: headquartersBranch.id,
          departmentId: executiveDept.id,
          positionId: ceoPosition.id,
          workplaceId: headquartersWorkplace.id,
          scheduleId: defaultSchedule.id,
          isProfileComplete: true,
        },
      },
      userRoles: {
        create: [{ roleId: roleSuperAdmin.id }],
      },
    },
  });
  console.log(`👤 Super Admin: ${superAdmin.email}`);

  // HR Manager
  const hrManager = await prisma.user.upsert({
    where: { email: "hr@example.test" },
    update: {},
    create: {
      email: "hr@example.test",
      passwordHash: defaultPasswordHash,
      role: Role.HR_MANAGER,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        create: {
          employeeCode: "CW-0002",
          firstName: "Sarah",
          lastName: "Mansoor",
          phone: "+966500000002",
          nationalId: "1000000002",
          jobTitle: "HR Manager",
          department: "Human Resources",
          gender: Gender.FEMALE,
          organizationId: organization.id,
          branchId: headquartersBranch.id,
          departmentId: hrDept.id,
          positionId: hrManagerPosition.id,
          workplaceId: headquartersWorkplace.id,
          scheduleId: defaultSchedule.id,
          isProfileComplete: true,
        },
      },
      userRoles: {
        create: [{ roleId: roleHrManager.id }],
      },
    },
  });
  console.log(`👤 HR Manager: ${hrManager.email}`);

  // Active Employee
  const activeEmployee = await prisma.user.upsert({
    where: { email: "employee.active@example.test" },
    update: {},
    create: {
      email: "employee.active@example.test",
      googleId: "google-active-employee-id",
      passwordHash: defaultPasswordHash,
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        create: {
          employeeCode: "CW-1001",
          firstName: "Tariq",
          lastName: "Zaid",
          phone: "+966500001001",
          nationalId: "1000001001",
          jobTitle: "Senior Software Engineer",
          department: "Engineering & IT",
          gender: Gender.MALE,
          organizationId: organization.id,
          branchId: headquartersBranch.id,
          departmentId: engineeringDept.id,
          sectionId: softwareSec.id,
          positionId: seniorDevPosition.id,
          workplaceId: headquartersWorkplace.id,
          scheduleId: defaultSchedule.id,
          isProfileComplete: true,
        },
      },
      userRoles: {
        create: [{ roleId: roleEmployee.id }],
      },
    },
  });
  console.log(`👤 Active Employee: ${activeEmployee.email}`);

  // Incomplete Profile Employee
  const newEmployee = await prisma.user.upsert({
    where: { email: "employee.new@example.test" },
    update: {},
    create: {
      email: "employee.new@example.test",
      googleId: "google-new-employee-id",
      passwordHash: defaultPasswordHash,
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        create: {
          employeeCode: "CW-1002",
          firstName: "New",
          lastName: "Joiner",
          jobTitle: "Junior Developer",
          department: "Engineering & IT",
          organizationId: organization.id,
          branchId: headquartersBranch.id,
          departmentId: engineeringDept.id,
          isProfileComplete: false,
        },
      },
    },
  });
  console.log(`👤 New Employee (Incomplete): ${newEmployee.email}`);

  // Suspended Employee
  const suspendedEmployee = await prisma.user.upsert({
    where: { email: "employee.suspended@example.test" },
    update: {},
    create: {
      email: "employee.suspended@example.test",
      googleId: "google-suspended-employee-id",
      passwordHash: defaultPasswordHash,
      role: Role.EMPLOYEE,
      status: UserStatus.SUSPENDED,
      employeeProfile: {
        create: {
          employeeCode: "CW-1003",
          firstName: "Suspended",
          lastName: "User",
          jobTitle: "Analyst",
          department: "Operations & Facilities",
          organizationId: organization.id,
          branchId: headquartersBranch.id,
          departmentId: operationsDept.id,
          workplaceId: headquartersWorkplace.id,
          isProfileComplete: true,
        },
      },
    },
  });
  console.log(`👤 Suspended Employee: ${suspendedEmployee.email}`);

  // Employee without Workplace
  const noWorkplaceEmployee = await prisma.user.upsert({
    where: { email: "employee.noworkplace@example.test" },
    update: {},
    create: {
      email: "employee.noworkplace@example.test",
      googleId: "google-noworkplace-id",
      passwordHash: defaultPasswordHash,
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        create: {
          employeeCode: "CW-1004",
          firstName: "No",
          lastName: "Workplace",
          phone: "+966500001004",
          nationalId: "1000001004",
          jobTitle: "Field Agent",
          department: "Sales",
          scheduleId: defaultSchedule.id,
          isProfileComplete: true,
          workplaceId: null,
        },
      },
    },
  });
  console.log(`👤 Employee without Workplace: ${noWorkplaceEmployee.email}`);

  // Employee without Schedule
  const noScheduleEmployee = await prisma.user.upsert({
    where: { email: "employee.noschedule@example.test" },
    update: {},
    create: {
      email: "employee.noschedule@example.test",
      googleId: "google-noschedule-id",
      passwordHash: defaultPasswordHash,
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        create: {
          employeeCode: "CW-1005",
          firstName: "No",
          lastName: "Schedule",
          phone: "+966500001005",
          nationalId: "1000001005",
          jobTitle: "Contractor",
          department: "Consulting",
          workplaceId: headquartersWorkplace.id,
          isProfileComplete: true,
          scheduleId: null,
        },
      },
    },
  });
  console.log(`👤 Employee without Schedule: ${noScheduleEmployee.email}`);

  console.log("✅ Phase 1 Database Seeding completed successfully.");
}

main()
  .catch((e) => {
    console.error("❌ Seeding error:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
