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
export class TaskAccessGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest();
    const user = req.user;
    const taskId = req.params?.id || req.params?.taskId;

    if (!user) {
      throw new ForbiddenException("Unauthenticated user");
    }

    // SUPER_ADMIN and HR_ADMIN have global access
    if (user.role === Role.SUPER_ADMIN || user.role === Role.HR_ADMIN) {
      return true;
    }

    if (!taskId) {
      return true;
    }

    const task = await this.prisma.task.findUnique({
      where: { id: taskId },
      select: {
        id: true,
        creatorId: true,
        assigneeId: true,
        departmentId: true,
        assignee: {
          select: {
            id: true,
            userId: true,
            departmentId: true,
            managerId: true,
          },
        },
      },
    });

    if (!task) {
      throw new NotFoundException(`Task with ID ${taskId} not found`);
    }

    // Task creator always has access
    if (task.creatorId === user.id) {
      return true;
    }

    // Task assignee always has access
    if (task.assignee && task.assignee.userId === user.id) {
      return true;
    }

    // Manager / Supervisor check: manager of the assignee
    const userEmployee = await this.prisma.employeeProfile.findUnique({
      where: { userId: user.id },
      select: { id: true, departmentId: true },
    });

    if (userEmployee) {
      if (task.assignee && task.assignee.managerId === userEmployee.id) {
        return true;
      }
      if (
        (user.role === Role.HR_MANAGER || user.role === Role.SUPERVISOR) &&
        task.departmentId === userEmployee.departmentId
      ) {
        return true;
      }
    }

    throw new ForbiddenException(
      "You do not have permission to access this task",
    );
  }
}
