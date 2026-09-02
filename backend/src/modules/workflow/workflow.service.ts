import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from "@nestjs/common";
import { WorkflowRepository } from "./workflow.repository";
import { CreateWorkflowDto, QueryWorkflowDto, UpdateWorkflowDto } from "./dto";
import { PrismaService } from "../../prisma/prisma.service";
import {
  ApproverType,
  AuditAction,
  RequestType,
  Role,
  WorkflowDefinition,
  WorkflowStepDefinition,
} from "@prisma/client";

export interface WorkflowMatchResult {
  workflowId: string | null;
  workflowName: string;
  totalSteps: number;
  steps: Array<{
    stepOrder: number;
    name: string;
    approverType: ApproverType;
    role?: Role | null;
    specificUserId?: string | null;
    isMandatory: boolean;
    canDelegate: boolean;
  }>;
}

@Injectable()
export class WorkflowService {
  private readonly logger = new Logger(WorkflowService.name);

  constructor(
    private readonly workflowRepo: WorkflowRepository,
    private readonly prisma: PrismaService,
  ) {}

  async create(dto: CreateWorkflowDto, currentUserId?: string) {
    if (!dto.steps || dto.steps.length === 0) {
      throw new BadRequestException("Workflow must contain at least one step");
    }

    // Validate stepOrder uniqueness and sequential correctness
    const stepOrders = dto.steps.map((s) => s.stepOrder);
    const uniqueOrders = new Set(stepOrders);
    if (uniqueOrders.size !== stepOrders.length) {
      throw new BadRequestException("Step orders must be unique");
    }

    for (const step of dto.steps) {
      if (step.approverType === ApproverType.SPECIFIC_ROLE && !step.role) {
        throw new BadRequestException(
          `Step '${step.name}' specifies SPECIFIC_ROLE but no role was provided`,
        );
      }
      if (
        step.approverType === ApproverType.SPECIFIC_USER &&
        !step.specificUserId
      ) {
        throw new BadRequestException(
          `Step '${step.name}' specifies SPECIFIC_USER but no specificUserId was provided`,
        );
      }
    }

    const workflow = await this.workflowRepo.create(dto);

    if (currentUserId) {
      await this.prisma.auditLog.create({
        data: {
          userId: currentUserId,
          action: AuditAction.WORKFLOW_CREATED,
          entity: "WorkflowDefinition",
          entityId: workflow.id,
          payload: { name: workflow.name, requestType: workflow.requestType },
        },
      });
    }

    return workflow;
  }

  async update(id: string, dto: UpdateWorkflowDto, currentUserId?: string) {
    const existing = await this.workflowRepo.findById(id);
    if (!existing) {
      throw new NotFoundException(`Workflow ${id} not found`);
    }

    if (dto.steps && dto.steps.length > 0) {
      const stepOrders = dto.steps.map((s) => s.stepOrder);
      const uniqueOrders = new Set(stepOrders);
      if (uniqueOrders.size !== stepOrders.length) {
        throw new BadRequestException("Step orders must be unique");
      }
    }

    const updated = await this.workflowRepo.update(id, dto);

    if (currentUserId) {
      await this.prisma.auditLog.create({
        data: {
          userId: currentUserId,
          action: AuditAction.WORKFLOW_UPDATED,
          entity: "WorkflowDefinition",
          entityId: id,
          payload: { changes: dto as any },
        },
      });
    }

    return updated;
  }

  async findAll(query: QueryWorkflowDto) {
    return this.workflowRepo.findAll(query);
  }

  async findOne(id: string) {
    const wf = await this.workflowRepo.findById(id);
    if (!wf) {
      throw new NotFoundException(`Workflow ${id} not found`);
    }
    return wf;
  }

  async remove(id: string, currentUserId?: string) {
    const existing = await this.workflowRepo.findById(id);
    if (!existing) {
      throw new NotFoundException(`Workflow ${id} not found`);
    }

    const deleted = await this.workflowRepo.delete(id);

    if (currentUserId) {
      await this.prisma.auditLog.create({
        data: {
          userId: currentUserId,
          action: AuditAction.WORKFLOW_DELETED,
          entity: "WorkflowDefinition",
          entityId: id,
          payload: { name: existing.name },
        },
      });
    }

    return deleted;
  }

  /**
   * Matches the best WorkflowDefinition for a given request parameters
   */
  async matchWorkflow(params: {
    requestType: RequestType;
    departmentId?: string | null;
    role?: Role | null;
    days?: number;
    amount?: number;
  }): Promise<WorkflowMatchResult> {
    const candidates = await this.workflowRepo.findActiveCandidates({
      requestType: params.requestType,
      departmentId: params.departmentId,
      role: params.role,
    });

    let matched:
      (WorkflowDefinition & { steps: WorkflowStepDefinition[] }) | null = null;

    for (const cand of candidates) {
      // 1. Department match: if workflow specifies department, employee must match
      if (cand.departmentId && cand.departmentId !== params.departmentId) {
        continue;
      }
      // 2. Role match: if workflow specifies role, employee role must match
      if (cand.role && cand.role !== params.role) {
        continue;
      }
      // 3. Days threshold check
      if (params.days !== undefined) {
        if (cand.minDays !== null && params.days < cand.minDays) continue;
        if (cand.maxDays !== null && params.days > cand.maxDays) continue;
      }
      // 4. Amount threshold check
      if (params.amount !== undefined) {
        if (cand.minAmount !== null && params.amount < Number(cand.minAmount))
          continue;
        if (cand.maxAmount !== null && params.amount > Number(cand.maxAmount))
          continue;
      }

      // Found highest priority match
      matched = cand;
      break;
    }

    if (!matched) {
      // Check for default active workflow
      const defaultWf = candidates.find((c) => c.isDefault);
      if (defaultWf) {
        matched = defaultWf;
      }
    }

    if (matched && matched.steps.length > 0) {
      return {
        workflowId: matched.id,
        workflowName: matched.name,
        totalSteps: matched.steps.length,
        steps: matched.steps.map((s) => ({
          stepOrder: s.stepOrder,
          name: s.name,
          approverType: s.approverType,
          role: s.role,
          specificUserId: s.specificUserId,
          isMandatory: s.isMandatory,
          canDelegate: s.canDelegate,
        })),
      };
    }

    // Default Fallback Workflow: Single step HR/Supervisor approval
    return {
      workflowId: null,
      workflowName: "Default System Workflow",
      totalSteps: 1,
      steps: [
        {
          stepOrder: 1,
          name: "Manager or HR Approval",
          approverType: ApproverType.DIRECT_MANAGER,
          role: Role.HR_MANAGER,
          isMandatory: true,
          canDelegate: true,
        },
      ],
    };
  }
}
