import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { AttendanceService } from './attendance.service';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

describe('AttendanceService', () => {
  let service: AttendanceService;

  const mockPrismaService = {
    user: { findUnique: jest.fn() },
    attendanceRecord: {
      findUnique: jest.fn(),
      upsert: jest.fn(),
      update: jest.fn(),
      count: jest.fn(),
      findMany: jest.fn(),
    },
    auditLog: { create: jest.fn() },
  };

  const mockNotificationsService = {
    sendNotification: jest.fn().mockResolvedValue({ id: 'notif-01' }),
  };

  const mockConfigService = {
    get: jest.fn().mockReturnValue(50.0),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AttendanceService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: NotificationsService, useValue: mockNotificationsService },
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    service = module.get<AttendanceService>(AttendanceService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
