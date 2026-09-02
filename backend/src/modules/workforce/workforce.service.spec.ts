import { Test, TestingModule } from "@nestjs/testing";
import { WorkforceService } from "./workforce.service";
import { WorkforceRepository } from "./workforce.repository";
import { AttendanceStatus, RequestType } from "@prisma/client";

describe("WorkforceService", () => {
  let service: WorkforceService;
  let mockWorkforceRepo: any;

  const mockEmployees = [
    {
      id: "emp-1",
      employeeCode: "EMP001",
      firstName: "Ahmed",
      lastName: "Ali",
      jobTitle: "Software Engineer",
      department: "Engineering",
      workplaceId: "wp-1",
      workplace: { id: "wp-1", name: "HQ", code: "HQ01" },
      scheduleId: "sched-1",
      schedule: {
        id: "sched-1",
        name: "Standard",
        startTime: "09:00",
        endTime: "17:00",
        workingDays: [0, 1, 2, 3, 4, 5, 6], // Works every day
      },
    },
    {
      id: "emp-2",
      employeeCode: "EMP002",
      firstName: "Sara",
      lastName: "Mohamed",
      jobTitle: "HR Specialist",
      department: "HR",
      workplaceId: "wp-1",
      workplace: { id: "wp-1", name: "HQ", code: "HQ01" },
      scheduleId: "sched-1",
      schedule: {
        id: "sched-1",
        name: "Standard",
        startTime: "09:00",
        endTime: "17:00",
        workingDays: [0, 1, 2, 3, 4, 5, 6],
      },
    },
    {
      id: "emp-3",
      employeeCode: "EMP003",
      firstName: "Omar",
      lastName: "Khaled",
      jobTitle: "Finance Analyst",
      department: "Finance",
      workplaceId: "wp-2",
      workplace: { id: "wp-2", name: "Branch North", code: "BN01" },
      scheduleId: "sched-1",
      schedule: {
        id: "sched-1",
        name: "Standard",
        startTime: "09:00",
        endTime: "17:00",
        workingDays: [0, 1, 2, 3, 4, 5, 6],
      },
    },
  ];

  const mockToday = new Date("2026-09-02T00:00:00.000Z");

  const mockAttendanceRecords = [
    {
      id: "rec-1",
      employeeId: "emp-1",
      date: mockToday,
      status: AttendanceStatus.PRESENT,
      checkInTime: new Date("2026-09-02T08:55:00.000Z"),
      checkOutTime: new Date("2026-09-02T17:30:00.000Z"),
      workDurationMinutes: 515,
      lateMinutes: 0,
      earlyLeaveMinutes: 0,
      overtimeMinutes: 30,
      employee: {
        id: "emp-1",
        employeeCode: "EMP001",
        firstName: "Ahmed",
        lastName: "Ali",
        department: "Engineering",
        jobTitle: "Software Engineer",
      },
      workplace: { id: "wp-1", name: "HQ", code: "HQ01" },
    },
    {
      id: "rec-2",
      employeeId: "emp-2",
      date: mockToday,
      status: AttendanceStatus.LATE,
      checkInTime: new Date("2026-09-02T09:45:00.000Z"),
      checkOutTime: null,
      workDurationMinutes: 0,
      lateMinutes: 45,
      earlyLeaveMinutes: 0,
      overtimeMinutes: 0,
      employee: {
        id: "emp-2",
        employeeCode: "EMP002",
        firstName: "Sara",
        lastName: "Mohamed",
        department: "HR",
        jobTitle: "HR Specialist",
      },
      workplace: { id: "wp-1", name: "HQ", code: "HQ01" },
    },
  ];

  const mockApprovedLeaves = [
    {
      id: "leave-1",
      employeeId: "emp-3",
      type: RequestType.ANNUAL_LEAVE,
      startDate: mockToday,
      endDate: mockToday,
      employee: {
        id: "emp-3",
        employeeCode: "EMP003",
        firstName: "Omar",
        lastName: "Khaled",
        department: "Finance",
      },
    },
  ];

  beforeEach(async () => {
    mockWorkforceRepo = {
      countActiveEmployees: jest.fn().mockResolvedValue(mockEmployees.length),
      getActiveEmployeesWithSchedule: jest.fn().mockResolvedValue(mockEmployees),
      getAttendanceForDate: jest.fn().mockResolvedValue(mockAttendanceRecords),
      getAttendanceForRange: jest.fn().mockResolvedValue(mockAttendanceRecords),
      getApprovedLeavesForDate: jest.fn().mockResolvedValue(mockApprovedLeaves),
      getDepartmentStats: jest.fn().mockResolvedValue(mockAttendanceRecords),
      getWorkplaceStats: jest.fn().mockResolvedValue(mockAttendanceRecords),
      getTopOvertimeRecords: jest.fn().mockResolvedValue([mockAttendanceRecords[0]]),
      markAbsences: jest.fn().mockResolvedValue([
        {
          id: "rec-absent-1",
          employeeId: "emp-4",
          date: mockToday,
          status: AttendanceStatus.ABSENT,
        },
      ]),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WorkforceService,
        { provide: WorkforceRepository, useValue: mockWorkforceRepo },
      ],
    }).compile();

    service = module.get<WorkforceService>(WorkforceService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });

  describe("getLiveStatus", () => {
    it("should compute real-time live presence metrics for today", async () => {
      const result = await service.getLiveStatus({ date: "2026-09-02" });

      expect(result).toBeDefined();
      expect(result.metrics.totalActiveEmployees).toBe(3);
      expect(result.metrics.presentCount).toBe(2);
      expect(result.metrics.currentlyCheckedInCount).toBe(1); // emp-2 is checked in without checkout
      expect(result.metrics.checkedOutCount).toBe(1); // emp-1 has checked out
      expect(result.metrics.lateCount).toBe(1);
      expect(result.metrics.onLeaveCount).toBe(1);
      expect(result.presentEmployees.length).toBe(2);
      expect(result.onLeaveEmployees.length).toBe(1);
    });
  });

  describe("getStatistics", () => {
    it("should aggregate total work hours, overtime, late minutes, and punctuality rate", async () => {
      const result = await service.getStatistics({
        startDate: "2026-09-01",
        endDate: "2026-09-30",
      });

      expect(result).toBeDefined();
      expect(result.summary.totalRecords).toBe(2);
      expect(result.summary.presentCount).toBe(2);
      expect(result.summary.lateCount).toBe(1);
      expect(result.summary.totalOvertimeMinutes).toBe(30);
      expect(result.summary.totalLateMinutes).toBe(45);
      expect(result.summary.attendanceRatePercentage).toBe(100);
      expect(result.summary.punctualityRatePercentage).toBe(50);
    });
  });

  describe("getDepartmentWorkforce", () => {
    it("should break down workforce performance by department", async () => {
      const result = await service.getDepartmentWorkforce({
        startDate: "2026-09-01",
        endDate: "2026-09-30",
      });

      expect(result.departments).toBeDefined();
      expect(result.departments.length).toBe(2);
      const engineering = result.departments.find((d) => d.department === "Engineering");
      expect(engineering).toBeDefined();
      expect(engineering.presentCount).toBe(1);
      expect(engineering.totalOvertimeHours).toBe(0.5);
    });
  });

  describe("getWorkplaceWorkforce", () => {
    it("should break down workforce performance by workplace", async () => {
      const result = await service.getWorkplaceWorkforce({
        startDate: "2026-09-01",
        endDate: "2026-09-30",
      });

      expect(result.workplaces).toBeDefined();
      expect(result.workplaces.length).toBe(1);
      expect(result.workplaces[0].workplaceName).toBe("HQ");
    });
  });

  describe("getAbsentEmployees & markAbsences", () => {
    it("should identify scheduled employees with no attendance and no leave", async () => {
      // Mock un-attended employee
      mockWorkforceRepo.getActiveEmployeesWithSchedule.mockResolvedValueOnce([
        ...mockEmployees,
        {
          id: "emp-absent",
          employeeCode: "EMP999",
          firstName: "Absent",
          lastName: "Worker",
          department: "Operations",
          schedule: { workingDays: [mockToday.getDay()], startTime: "09:00", endTime: "17:00" },
        },
      ]);

      const result = await service.getAbsentEmployees("2026-09-02");
      expect(result.absentCount).toBe(1);
      expect(result.employees[0].employeeId).toBe("emp-absent");
    });

    it("should batch mark absent employees with audit reason", async () => {
      const result = await service.markAbsences("hr-admin-1", {
        date: "2026-09-02",
        employeeIds: ["emp-4"],
        reason: "Unexcused absence on shift",
      });

      expect(result.count).toBe(1);
      expect(mockWorkforceRepo.markAbsences).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.objectContaining({
            employeeId: "emp-4",
            reason: "Unexcused absence on shift",
          }),
        ]),
        "hr-admin-1",
      );
    });
  });

  describe("getOvertimeSummary", () => {
    it("should return top overtime employees and totals", async () => {
      const result = await service.getOvertimeSummary({
        startDate: "2026-09-01",
        endDate: "2026-09-30",
      });

      expect(result.totalOvertimeHours).toBe(0.5);
      expect(result.topEmployees.length).toBe(1);
      expect(result.topEmployees[0].name).toBe("Ahmed Ali");
      expect(result.topEmployees[0].totalOvertimeMinutes).toBe(30);
    });
  });
});
