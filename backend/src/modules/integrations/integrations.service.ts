import { Injectable, NotFoundException, Logger } from "@nestjs/common";
import { IntegrationsRepository } from "./integrations.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { CreateApiKeyDto, CreateWebhookDto, QueryLogsDto } from "./dto";
import { AuditAction } from "@prisma/client";
import * as crypto from "crypto";

@Injectable()
export class IntegrationsService {
  private readonly logger = new Logger(IntegrationsService.name);

  constructor(
    private readonly repo: IntegrationsRepository,
    private readonly prisma: PrismaService,
  ) {}

  // ============================================================
  // API KEYS
  // ============================================================

  async createApiKey(userId: string, dto: CreateApiKeyDto) {
    const rawSecret = crypto.randomBytes(24).toString("hex");
    const rawKey = `sec_live_${rawSecret}`;
    const keyPrefix = rawKey.slice(0, 12);
    const keyHash = crypto.createHash("sha256").update(rawKey).digest("hex");

    const apiKey = await this.repo.createApiKey(
      userId,
      dto,
      keyPrefix,
      keyHash,
    );

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "ApiKey",
        entityId: apiKey.id,
        payload: {
          name: apiKey.name,
          keyPrefix: apiKey.keyPrefix,
          scopes: apiKey.scopes,
        },
      },
    });

    return {
      apiKey: {
        id: apiKey.id,
        name: apiKey.name,
        keyPrefix: apiKey.keyPrefix,
        scopes: apiKey.scopes,
        expiresAt: apiKey.expiresAt,
        createdAt: apiKey.createdAt,
      },
      plainTextKey: rawKey,
    };
  }

  async findApiKeys() {
    return this.repo.findApiKeys();
  }

  async revokeApiKey(id: string, userId: string) {
    const apiKey = await this.repo.findApiKeyById(id);
    if (!apiKey) throw new NotFoundException(`API key '${id}' not found`);

    const updated = await this.repo.revokeApiKey(id);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "ApiKey",
        entityId: id,
        payload: { isActive: false, reason: "Revoked by admin" },
      },
    });

    return updated;
  }

  // ============================================================
  // WEBHOOKS
  // ============================================================

  async createWebhook(userId: string, dto: CreateWebhookDto) {
    const secret = `whsec_${crypto.randomBytes(24).toString("hex")}`;
    const webhook = await this.repo.createWebhook(dto, secret);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "WebhookConfig",
        entityId: webhook.id,
        payload: {
          name: webhook.name,
          targetUrl: webhook.targetUrl,
          events: webhook.events,
        },
      },
    });

    return webhook;
  }

  async findWebhooks() {
    return this.repo.findWebhooks();
  }

  async updateWebhookStatus(id: string, userId: string, isActive: boolean) {
    const webhook = await this.repo.findWebhookById(id);
    if (!webhook) throw new NotFoundException(`Webhook '${id}' not found`);

    const updated = await this.repo.updateWebhookStatus(id, isActive);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "WebhookConfig",
        entityId: id,
        payload: { isActive },
      },
    });

    return updated;
  }

  // ============================================================
  // LOGS
  // ============================================================

  async findLogs(query: QueryLogsDto) {
    return this.repo.findLogs(query);
  }
}
