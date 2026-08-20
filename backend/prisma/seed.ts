import { PrismaClient, Role, UserStatus, Gender } from '@prisma/client';
import * as argon2 from 'argon2';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seed for CyberWise IE...');

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
      radiusMeters: 200,
      isActive: true,
    },
  });

  console.log(`🏢 Created/Verified Workplace: ${headquarters.name}`);

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
      workingDays: [0, 1, 2, 3, 4], // Sun - Thu
      isDefault: true,
    },
  });

  console.log(`⏰ Created/Verified Schedule: ${defaultSchedule.name}`);

  // 3. Create Super Admin Account
  const adminPasswordHash = await argon2.hash('Admin@123456');
  const superAdmin = await prisma.user.upsert({
    where: { email: 'admin@cyberwise.com' },
    update: {},
    create: {
      email: 'admin@cyberwise.com',
      passwordHash: adminPasswordHash,
      role: Role.SUPER_ADMIN,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        create: {
          employeeCode: 'CW-0001',
          firstName: 'System',
          lastName: 'Administrator',
          phone: '+966500000001',
          jobTitle: 'Super Administrator',
          department: 'Executive',
          gender: Gender.MALE,
          workplaceId: headquarters.id,
          scheduleId: defaultSchedule.id,
        },
      },
    },
  });

  console.log(`👤 Created/Verified Super Admin: ${superAdmin.email}`);

  // 4. Create HR Manager Account
  const hrPasswordHash = await argon2.hash('HR@123456');
  const hrManager = await prisma.user.upsert({
    where: { email: 'hr@cyberwise.com' },
    update: {},
    create: {
      email: 'hr@cyberwise.com',
      passwordHash: hrPasswordHash,
      role: Role.HR_MANAGER,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        create: {
          employeeCode: 'CW-0002',
          firstName: 'Sarah',
          lastName: 'Al-Mansoor',
          phone: '+966500000002',
          jobTitle: 'HR Manager',
          department: 'Human Resources',
          gender: Gender.FEMALE,
          workplaceId: headquarters.id,
          scheduleId: defaultSchedule.id,
        },
      },
    },
  });

  console.log(`👤 Created/Verified HR Manager: ${hrManager.email}`);

  // 5. Create Sample Employee Account (for Mobile Testing)
  const empPasswordHash = await argon2.hash('Emp@123456');
  const employee = await prisma.user.upsert({
    where: { email: 'employee@cyberwise.com' },
    update: {},
    create: {
      email: 'employee@cyberwise.com',
      passwordHash: empPasswordHash,
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        create: {
          employeeCode: 'CW-0003',
          firstName: 'Tariq',
          lastName: 'Zaid',
          phone: '+966500000003',
          jobTitle: 'Software Engineer',
          department: 'Engineering',
          gender: Gender.MALE,
          workplaceId: headquarters.id,
          scheduleId: defaultSchedule.id,
        },
      },
    },
  });

  console.log(`👤 Created/Verified Employee: ${employee.email}`);
  console.log('✅ Seeding completed successfully.');
}

main()
  .catch((e) => {
    console.error('❌ Seeding error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
