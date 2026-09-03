import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { CreateApiKeyDto, CreateWebhookDto, QueryLogsDto } from "./dto";
import { IntegrationStatus } from "@prisma/client";

@Injectable()
export class IntegrationsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createApiKey(
    userId: string,
    dto: CreateApiKeyDto,
    keyPrefix: string,
    keyHash: string,
  ) {
    return this.prisma.apiKey.create({
      data: {
        name: dto.name,
        keyPrefix,
        keyHash,
        scopes: dto.scopes || ["*"],
        expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : null,
        userId,
        isActive: true,
      },
    });
  }

  async findApiKeys() {
    return this.prisma.apiKey.findMany({
      orderBy: { createdAt: "desc" },
      select: {
        id: true,
        name: true,
        keyPrefix: true,
        scopes: true,
        isActive: true,
        expiresAt: true,
        lastUsedAt: true,
        createdAt: true,
      },
    });
  }

  async findApiKeyById(id: string) {
    return this.prisma.apiKey.findUnique({
      where: { id },
    });
  }

  async revokeApiKey(id: string) {
    return this.prisma.apiKey.update({
      where: { id },
      data: { isActive: false },
    });
  }

  async createWebhook(dto: CreateWebhookDto, secret: string) {
    return this.prisma.webhookConfig.create({
      data: {
        name: dto.name,
        targetUrl: dto.targetUrl,
        secret,
        events: dto.events,
        retryLimit: dto.retryLimit || 3,
        isActive: true,
      },
    });
  }

  async findWebhooks() {
    return this.prisma.webhookConfig.findMany({
      orderBy: { createdAt: "desc" },
    });
  }

  async findWebhookById(id: string) {
    return this.prisma.webhookConfig.findUnique({
      where: { id },
    });
  }

  async updateWebhookStatus(id: string, isActive: boolean) {
    return this.prisma.webhookConfig.update({
      where: { id },
      data: { isActive },
    });
  }

  async logIntegration(data: {
    source: string;
    target: string;
    action: string;
    status: IntegrationStatus;
    requestPayload?: any;
    responsePayload?: any;
    errorMessage?: string;
    durationMs?: number;
  }) {
    return this.prisma.integrationLog.create({
      data: {
        source: data.source,
        target: data.target,
        action: data.action,
        status: data.status,
        requestPayload: data.requestPayload,
        responsePayload: data.responsePayload,
        errorMessage: data.errorMessage,
        durationMs: data.durationMs,
      },
    });
  }

  async findLogs(query: QueryLogsDto) {
    const { page = 1, limit = 20 } = query;
    const skip = (page - 1) * limit;

    const [total, items] = await Promise.all([
      this.prisma.integrationLog.count(),
      this.prisma.integrationLog.findMany({
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }
}
