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
export class DepartmentAccessGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest();
    const user = req.user;
    const departmentId =
      req.params?.departmentId ||
      req.query?.departmentId ||
      req.body?.departmentId;

    if (!user) {
      throw new ForbiddenException("Unauthenticated user");
    }

    // Global administrators
    if (user.role === Role.SUPER_ADMIN || user.role === Role.HR_ADMIN) {
      return true;
    }

    if (!departmentId) {
      return true;
    }

    const department = await this.prisma.department.findUnique({
      where: { id: departmentId },
      select: {
        id: true,
        headOfDepartmentId: true,
      },
    });

    if (!department) {
      throw new NotFoundException(`Department ${departmentId} not found`);
    }

    const userEmployee = await this.prisma.employeeProfile.findUnique({
      where: { userId: user.id },
      select: { id: true, departmentId: true },
    });

    if (userEmployee) {
      // Is Head of Department
      if (department.headOfDepartmentId === userEmployee.id) {
        return true;
      }
      // Belongs to the department as supervisor or manager
      if (
        userEmployee.departmentId === department.id &&
        (user.role === Role.SUPERVISOR || user.role === Role.HR_MANAGER)
      ) {
        return true;
      }
    }

    throw new ForbiddenException(
      "You do not have management access to this department's operations",
    );
  }
}
