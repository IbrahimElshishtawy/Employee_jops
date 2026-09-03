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
export class HandoverAccessGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest();
    const user = req.user;
    const id = req.params?.id || req.params?.handoverId;

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

    const handover = await this.prisma.shiftHandover.findUnique({
      where: { id },
      select: {
        id: true,
        departmentId: true,
        handedOverById: true,
        receivedById: true,
        handedOverBy: {
          select: { userId: true },
        },
        receivedBy: {
          select: { userId: true },
        },
        department: {
          select: {
            headOfDepartmentId: true,
          },
        },
      },
    });

    if (!handover) {
      throw new NotFoundException(`Shift handover ${id} not found`);
    }

    // Giver has access
    if (handover.handedOverBy?.userId === user.id) {
      return true;
    }

    // Receiver has access
    if (handover.receivedBy?.userId === user.id) {
      return true;
    }

    // Department Head or department staff has access
    const userEmployee = await this.prisma.employeeProfile.findUnique({
      where: { userId: user.id },
      select: { id: true, departmentId: true },
    });

    if (userEmployee) {
      if (handover.department?.headOfDepartmentId === userEmployee.id) {
        return true;
      }
      if (userEmployee.departmentId === handover.departmentId) {
        return true;
      }
    }

    throw new ForbiddenException(
      "You do not have permission to access this shift handover",
    );
  }
}
