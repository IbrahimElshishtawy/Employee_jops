import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { CreateApiKeyDto, CreateWebhookDto, QueryLogsDto } from "./dto";

@Injectable()
export class IntegrationsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createApiKey(
    userId: string,
    dto: CreateApiKeyDto,
    prefix: string,
    keyHash: string,
  ) {
    return this.prisma.apiKey.create({
      data: {
        name: dto.name,
        prefix,
        keyHash,
        scopes: dto.scopes || ["*"],
        expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : null,
        createdById: userId,
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
        prefix: true,
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

  async createWebhook(dto: CreateWebhookDto, secretKey: string) {
    return this.prisma.webhookConfig.create({
      data: {
        name: dto.name,
        targetUrl: dto.targetUrl,
        secretKey,
        eventTypes: dto.eventTypes,
        retryCount: dto.retryCount || 3,
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
    apiKeyId?: string;
    endpoint: string;
    method: string;
    statusCode: number;
    requestBody?: any;
    responseBody?: any;
    durationMs: number;
    ipAddress?: string;
  }) {
    return this.prisma.integrationLog.create({
      data: {
        apiKeyId: data.apiKeyId,
        endpoint: data.endpoint,
        method: data.method,
        statusCode: data.statusCode,
        requestBody: data.requestBody,
        responseBody: data.responseBody,
        durationMs: data.durationMs,
        ipAddress: data.ipAddress,
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
        include: {
          apiKey: { select: { name: true, prefix: true } },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }
}
