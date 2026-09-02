import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { Prisma, RequestStatus, RequestType } from "@prisma/client";
import { CreateDelegationDto } from "./dto";

@Injectable()
export class ApprovalsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findRequestWithDetails(requestId: string) {
    return this.prisma.request.findUnique({
      where: { id: requestId },
      include: {
        employee: {
          include: {
            user: {
              select: {
                id: true,
                email: true,
                role: true,
                status: true,
              },
            },
            manager: {
              include: {
                user: {
                  select: {
                    id: true,
                    email: true,
                    role: true,
                  },
                },
              },
            },
            departmentRel: {
              include: {
                headOfDepartment: {
                  include: {
                    user: {
                      select: {
                        id: true,
                        email: true,
                        role: true,
                      },
                    },
                  },
                },
              },
            },
            section: {
              include: {
                headOfSection: {
                  include: {
                    user: {
                      select: {
                        id: true,
                        email: true,
                        role: true,
                      },
                    },
                  },
                },
              },
            },
            workplace: { select: { id: true, name: true, code: true } },
            schedule: { select: { id: true, name: true, startTime: true, endTime: true } },
          },
        },
        workflow: {
          include: {
            steps: {
              orderBy: { stepOrder: "asc" },
            },
          },
        },
        approvalSteps: {
          include: {
            approver: {
              select: {
                id: true,
                email: true,
                role: true,
                employeeProfile: {
                  select: {
                    firstName: true,
                    lastName: true,
                    jobTitle: true,
                  },
                },
              },
            },
          },
          orderBy: [{ stepOrder: "asc" }, { createdAt: "asc" }],
        },
      },
    });
  }

  async findApprovalHistory(requestId: string) {
    return this.prisma.approvalStep.findMany({
      where: { requestId },
      include: {
        approver: {
          select: {
            id: true,
            email: true,
            role: true,
            employeeProfile: {
              select: {
                id: true,
                employeeCode: true,
                firstName: true,
                lastName: true,
                jobTitle: true,
              },
            },
          },
        },
      },
      orderBy: [{ stepOrder: "asc" }, { createdAt: "asc" }],
    });
  }

  async findActiveDelegationsForDelegate(delegateUserId: string, targetDate: Date = new Date()) {
    const dateOnly = new Date(
      Date.UTC(targetDate.getUTCFullYear(), targetDate.getUTCMonth(), targetDate.getUTCDate()),
    );

    return this.prisma.approvalDelegation.findMany({
      where: {
        delegateId: delegateUserId,
        isActive: true,
        startDate: { lte: dateOnly },
        endDate: { gte: dateOnly },
      },
      include: {
        delegator: {
          select: {
            id: true,
            email: true,
            role: true,
            employeeProfile: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                department: true,
              },
            },
          },
        },
      },
    });
  }

  async createDelegation(delegatorId: string, dto: CreateDelegationDto) {
    const startDate = new Date(dto.startDate);
    const endDate = new Date(dto.endDate);

    return this.prisma.approvalDelegation.create({
      data: {
        delegatorId,
        delegateId: dto.delegateId,
        requestType: dto.requestType,
        startDate,
        endDate,
        isActive: true,
        reason: dto.reason,
      },
      include: {
        delegate: {
          select: {
            id: true,
            email: true,
            role: true,
            employeeProfile: {
              select: {
                firstName: true,
                lastName: true,
              },
            },
          },
        },
      },
    });
  }

  async findDelegations(userId: string) {
    return this.prisma.approvalDelegation.findMany({
      where: {
        OR: [{ delegatorId: userId }, { delegateId: userId }],
      },
      include: {
        delegator: {
          select: {
            id: true,
            email: true,
            employeeProfile: { select: { firstName: true, lastName: true } },
          },
        },
        delegate: {
          select: {
            id: true,
            email: true,
            employeeProfile: { select: { firstName: true, lastName: true } },
          },
        },
      },
      orderBy: { createdAt: "desc" },
    });
  }

  async revokeDelegation(id: string, userId: string) {
    return this.prisma.approvalDelegation.update({
      where: { id },
      data: { isActive: false },
    });
  }
}
