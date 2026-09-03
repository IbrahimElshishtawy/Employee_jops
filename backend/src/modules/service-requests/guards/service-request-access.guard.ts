import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  NotFoundException,
} from "@nestjs/common";
import { Role } from "@prisma/client";
import { PrismaService } from "../../../prisma/prisma.service";

@Injectable()
export class ServiceRequestAccessGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest();
    const user = req.user;
    const id = req.params?.id || req.params?.serviceRequestId;

    if (!user) {
      throw new ForbiddenException("Unauthenticated user");
    }

    // SUPER_ADMIN and HR_ADMIN have global administrative access
    if (user.role === Role.SUPER_ADMIN || user.role === Role.HR_ADMIN) {
      return true;
    }

    if (!id) {
      return true;
    }

    const serviceRequest = await this.prisma.serviceRequest.findUnique({
      where: { id },
      select: {
        id: true,
        requesterId: true,
        departmentId: true,
        assignedToId: true,
        requester: {
          select: {
            id: true,
            userId: true,
          },
        },
        assignedTo: {
          select: {
            id: true,
            userId: true,
          },
        },
        department: {
          select: {
            id: true,
            headOfDepartmentId: true,
          },
        },
      },
    });

    if (!serviceRequest) {
      throw new NotFoundException(`Service request ${id} not found`);
    }

    // 1. Requester has access
    if (serviceRequest.requester?.userId === user.id) {
      return true;
    }

    // 2. Assigned technician has access
    if (serviceRequest.assignedTo?.userId === user.id) {
      return true;
    }

    // 3. Department head or staff of servicing department has access
    const userEmployee = await this.prisma.employeeProfile.findUnique({
      where: { userId: user.id },
      select: { id: true, departmentId: true },
    });

    if (userEmployee) {
      // User is the head of department
      if (serviceRequest.department?.headOfDepartmentId === userEmployee.id) {
        return true;
      }
      // User is a member of the servicing department (e.g. IT support engineer or Maintenance tech)
      if (userEmployee.departmentId === serviceRequest.departmentId) {
        return true;
      }
    }

    throw new ForbiddenException(
      "You do not have permission to access this service request",
    );
  }
}
