import { PrismaClient, Role, UserStatus, Gender } from '@prisma/client';
import * as argon2 from 'argon2';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seed for CyberWise IE (Phase 02)...');

  // 1. Create Default Workplace
  const headquarters = await prisma.workplace.upsert({
    where: { code: 'HQ-MAIN' },
    update: {},
    create: {
      name: 'CyberWise Headquarters',
      code: 'HQ-MAIN',
      address: '100 Innovation Boulevard, Tech District',
      latitude: 24.7136,
      longitude: 46.6753,
      radiusMeters: 100, // 100 meters geofence
      isActive: true,
    },
  });

  console.log(`🏢 Created/Verified Workplace: ${headquarters.name} (Radius: ${headquarters.radiusMeters}m)`);

  // 2. Create Default Schedule
  const defaultSchedule = await prisma.schedule.upsert({
    where: { id: 'default-standard-schedule' },
    update: {},
    create: {
      id: 'default-standard-schedule',
      name: 'Standard Working Hours',
      description: 'Sunday to Thursday, 09:00 - 17:00',
      workplaceId: headquarters.id,
      startTime: '09:00',
      endTime: '17:00',
      graceMinutesCheckIn: 15,
      graceMinutesCheckOut: 15,
      workingDays: [0, 1, 2, 3, 4, 5, 6], // All days for testing flexibility
      isDefault: true,
    },
  });

  console.log(`⏰ Created/Verified Schedule: ${defaultSchedule.name}`);

  const defaultPasswordHash = await argon2.hash('Test@123456');

  // 3. Super Admin Account
  const superAdmin = await prisma.user.upsert({
    where: { email: 'admin@example.test' },
    update: {},
    create: {
      email: 'admin@example.test',
      passwordHash: defaultPasswordHash,
      role: Role.SUPER_ADMIN,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        create: {
          employeeCode: 'CW-0001',
          firstName: 'System',
          lastName: 'Administrator',
          phone: '+966500000001',
          nationalId: '1000000001',
          jobTitle: 'Super Administrator',
          department: 'Executive',
          gender: Gender.MALE,
          workplaceId: headquarters.id,
          scheduleId: defaultSchedule.id,
          isProfileComplete: true,
        },
      },
    },
  });
  console.log(`👤 Super Admin: ${superAdmin.email}`);

  // 4. HR Manager Account
  const hrManager = await prisma.user.upsert({
    where: { email: 'hr@example.test' },
    update: {},
    create: {
      email: 'hr@example.test',
      passwordHash: defaultPasswordHash,
      role: Role.HR_MANAGER,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        create: {
          employeeCode: 'CW-0002',
          firstName: 'Sarah',
          lastName: 'Mansoor',
          phone: '+966500000002',
          nationalId: '1000000002',
          jobTitle: 'HR Manager',
          department: 'Human Resources',
          gender: Gender.FEMALE,
          workplaceId: headquarters.id,
          scheduleId: defaultSchedule.id,
          isProfileComplete: true,
        },
      },
    },
  });
  console.log(`👤 HR Manager: ${hrManager.email}`);

  // 5. Active Employee (Profile Complete, Ready for Attendance)
  const activeEmployee = await prisma.user.upsert({
    where: { email: 'employee.active@example.test' },
    update: {},
    create: {
      email: 'employee.active@example.test',
      googleId: 'google-active-employee-id',
      passwordHash: defaultPasswordHash,
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        create: {
          employeeCode: 'CW-1001',
          firstName: 'Tariq',
          lastName: 'Zaid',
          phone: '+966500001001',
          nationalId: '1000001001',
          jobTitle: 'Senior Software Engineer',
          department: 'Engineering',
          gender: Gender.MALE,
          workplaceId: headquarters.id,
          scheduleId: defaultSchedule.id,
          isProfileComplete: true,
        },
      },
    },
  });
  console.log(`👤 Active Employee: ${activeEmployee.email}`);

  // 6. New Employee (Profile Incomplete)
  const newEmployee = await prisma.user.upsert({
    where: { email: 'employee.new@example.test' },
    update: {},
    create: {
      email: 'employee.new@example.test',
      googleId: 'google-new-employee-id',
      passwordHash: defaultPasswordHash,
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        create: {
          employeeCode: 'CW-1002',
          firstName: 'New',
          lastName: 'Joiner',
          jobTitle: 'Junior Developer',
          department: 'Engineering',
          isProfileComplete: false, // Incomplete onboarding
        },
      },
    },
  });
  console.log(`👤 New Employee (Incomplete Profile): ${newEmployee.email}`);

  // 7. Suspended Employee
  const suspendedEmployee = await prisma.user.upsert({
    where: { email: 'employee.suspended@example.test' },
    update: {},
    create: {
      email: 'employee.suspended@example.test',
      googleId: 'google-suspended-employee-id',
      passwordHash: defaultPasswordHash,
      role: Role.EMPLOYEE,
      status: UserStatus.SUSPENDED,
      employeeProfile: {
        create: {
          employeeCode: 'CW-1003',
          firstName: 'Suspended',
          lastName: 'User',
          jobTitle: 'Analyst',
          department: 'Operations',
          workplaceId: headquarters.id,
          isProfileComplete: true,
        },
      },
    },
  });
  console.log(`👤 Suspended Employee: ${suspendedEmployee.email}`);

  // 8. Employee without Workplace
  const noWorkplaceEmployee = await prisma.user.upsert({
    where: { email: 'employee.noworkplace@example.test' },
    update: {},
    create: {
      email: 'employee.noworkplace@example.test',
      googleId: 'google-noworkplace-id',
      passwordHash: defaultPasswordHash,
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        create: {
          employeeCode: 'CW-1004',
          firstName: 'No',
          lastName: 'Workplace',
          phone: '+966500001004',
          nationalId: '1000001004',
          jobTitle: 'Field Agent',
          department: 'Sales',
          scheduleId: defaultSchedule.id,
          isProfileComplete: true,
          workplaceId: null, // No workplace
        },
      },
    },
  });
  console.log(`👤 Employee without Workplace: ${noWorkplaceEmployee.email}`);

  // 9. Employee without Schedule
  const noScheduleEmployee = await prisma.user.upsert({
    where: { email: 'employee.noschedule@example.test' },
    update: {},
    create: {
      email: 'employee.noschedule@example.test',
      googleId: 'google-noschedule-id',
      passwordHash: defaultPasswordHash,
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        create: {
          employeeCode: 'CW-1005',
          firstName: 'No',
          lastName: 'Schedule',
          phone: '+966500001005',
          nationalId: '1000001005',
          jobTitle: 'Contractor',
          department: 'Consulting',
          workplaceId: headquarters.id,
          isProfileComplete: true,
          scheduleId: null, // No schedule
        },
      },
    },
  });
  console.log(`👤 Employee without Schedule: ${noScheduleEmployee.email}`);

  console.log('✅ Phase 02 Seeding completed successfully.');
}

main()
  .catch((e) => {
    console.error('❌ Seeding error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
