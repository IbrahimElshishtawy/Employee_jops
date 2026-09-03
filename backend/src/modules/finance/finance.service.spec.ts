import { Test, TestingModule } from "@nestjs/testing";
import { FinanceService } from "./finance.service";
import { FinanceRepository } from "./finance.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { ConflictException, BadRequestException } from "@nestjs/common";
import { AccountType, JournalEntryStatus } from "@prisma/client";

describe("FinanceService", () => {
  let service: FinanceService;
  let repo: jest.Mocked<FinanceRepository>;
  let prisma: any;

  beforeEach(async () => {
    const mockRepo = {
      generateEntryNumber: jest.fn().mockResolvedValue("JE-20260903-0001"),
      generateExpenseNumber: jest.fn().mockResolvedValue("EXP-20260903-0001"),
      generateReceiptNumber: jest.fn().mockResolvedValue("REV-20260903-0001"),
      createAccount: jest.fn(),
      findAccounts: jest.fn(),
      findAccountById: jest.fn(),
      findAccountByCode: jest.fn(),
      createJournalEntry: jest.fn(),
      findJournalEntries: jest.fn(),
      findJournalEntryById: jest.fn(),
      postJournalEntry: jest.fn(),
      createExpense: jest.fn(),
      findExpenses: jest.fn(),
      updateExpenseStatus: jest.fn(),
      createRevenue: jest.fn(),
      findRevenues: jest.fn(),
      createBankAccount: jest.fn(),
      findBankAccounts: jest.fn(),
      findBankAccountById: jest.fn(),
      findBankAccountByNumber: jest.fn(),
    };

    const mockPrisma = {
      auditLog: { create: jest.fn().mockResolvedValue({ id: "audit-1" }) },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FinanceService,
        { provide: FinanceRepository, useValue: mockRepo },
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<FinanceService>(FinanceService);
    repo = module.get(FinanceRepository);
    prisma = module.get(PrismaService);
  });

  describe("createAccount", () => {
    it("should throw ConflictException if account code exists", async () => {
      repo.findAccountByCode.mockResolvedValue({ id: "acc-1" } as any);

      await expect(
        service.createAccount("user-1", {
          code: "1010",
          name: "Cash",
          type: AccountType.ASSET,
          category: "CURRENT_ASSETS",
        }),
      ).rejects.toThrow(ConflictException);
    });

    it("should create account successfully", async () => {
      repo.findAccountByCode.mockResolvedValue(null);
      repo.createAccount.mockResolvedValue({
        id: "acc-1",
        code: "1010",
        name: "Cash",
        type: AccountType.ASSET,
      } as any);

      const result = await service.createAccount("user-1", {
        code: "1010",
        name: "Cash",
        type: AccountType.ASSET,
        category: "CURRENT_ASSETS",
      });

      expect(result.id).toBe("acc-1");
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("createJournalEntry", () => {
    it("should throw BadRequestException if debits and credits do not balance", async () => {
      repo.findAccountById.mockResolvedValue({ id: "acc-1" } as any);

      await expect(
        service.createJournalEntry("user-1", {
          lines: [
            { accountId: "acc-1", debit: 100, credit: 0 },
            { accountId: "acc-2", debit: 0, credit: 90 }, // Unbalanced!
          ],
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("should create balanced double-entry journal entry", async () => {
      repo.findAccountById.mockResolvedValue({ id: "acc-1" } as any);
      repo.createJournalEntry.mockResolvedValue({
        id: "je-1",
        entryNumber: "JE-20260903-0001",
        status: JournalEntryStatus.DRAFT,
      } as any);

      const result = await service.createJournalEntry("user-1", {
        lines: [
          { accountId: "acc-1", debit: 1500, credit: 0 },
          { accountId: "acc-2", debit: 0, credit: 1500 },
        ],
      });

      expect(result.id).toBe("je-1");
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });
});
