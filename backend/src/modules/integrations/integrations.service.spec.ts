import { Test, TestingModule } from "@nestjs/testing";
import { IntegrationsService } from "./integrations.service";
import { IntegrationsRepository } from "./integrations.repository";
import { PrismaService } from "../../prisma/prisma.service";

describe("IntegrationsService", () => {
  let service: IntegrationsService;
  let repo: jest.Mocked<IntegrationsRepository>;
  let prisma: any;

  beforeEach(async () => {
    const mockRepo = {
      createApiKey: jest.fn(),
      findApiKeys: jest.fn(),
      findApiKeyById: jest.fn(),
      revokeApiKey: jest.fn(),
      createWebhook: jest.fn(),
      findWebhooks: jest.fn(),
      findWebhookById: jest.fn(),
      updateWebhookStatus: jest.fn(),
      findLogs: jest.fn(),
    };

    const mockPrisma = {
      auditLog: { create: jest.fn().mockResolvedValue({ id: "audit-1" }) },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        IntegrationsService,
        { provide: IntegrationsRepository, useValue: mockRepo },
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<IntegrationsService>(IntegrationsService);
    repo = module.get(IntegrationsRepository);
    prisma = module.get(PrismaService);
  });

  describe("createApiKey", () => {
    it("should generate hashed key, return plain key once, and log audit", async () => {
      repo.createApiKey.mockResolvedValue({
        id: "key-1",
        name: "Test Key",
        keyPrefix: "sec_live_123",
        scopes: ["*"],
        expiresAt: null,
        createdAt: new Date(),
      } as any);

      const result = await service.createApiKey("user-1", { name: "Test Key" });
      expect(result.apiKey.id).toBe("key-1");
      expect(result.plainTextKey).toBeDefined();
      expect(result.plainTextKey.startsWith("sec_live_")).toBe(true);
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("createWebhook", () => {
    it("should generate signing secret, save webhook, and log audit", async () => {
      repo.createWebhook.mockResolvedValue({
        id: "wh-1",
        name: "Test Hook",
        targetUrl: "https://hook.com",
        events: ["room.status_changed"],
      } as any);

      const result = await service.createWebhook("user-1", {
        name: "Test Hook",
        targetUrl: "https://hook.com",
        events: ["room.status_changed"],
      });

      expect(result.id).toBe("wh-1");
      expect(repo.createWebhook).toHaveBeenCalledWith(
        expect.anything(),
        expect.stringMatching(/^whsec_/),
      );
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });
});
