import { Test, TestingModule } from "@nestjs/testing";
import { DashboardService } from "./dashboard.service";
import { DashboardRepository } from "./dashboard.repository";

describe("DashboardService", () => {
  let service: DashboardService;
  let repo: jest.Mocked<DashboardRepository>;

  beforeEach(async () => {
    const mockRepo = {
      getExecutiveKPIs: jest.fn().mockResolvedValue({
        operational: { totalAssets: 150, assetsUnderMaintenance: 3 },
        supplyChain: { totalStockItems: 420 },
        financeMonthToDate: { totalRevenue: 500000, totalExpenses: 300000, netProfit: 200000 },
        safetyAndSecurity: { openIncidents: 1 },
        workforce: { activeEmployees: 85 },
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DashboardService,
        { provide: DashboardRepository, useValue: mockRepo },
      ],
    }).compile();

    service = module.get<DashboardService>(DashboardService);
    repo = module.get(DashboardRepository);
  });

  describe("getExecutiveKPIs", () => {
    it("should return aggregated executive KPIs", async () => {
      const result = await service.getExecutiveKPIs();
      expect(result.operational.totalAssets).toBe(150);
      expect(result.financeMonthToDate.netProfit).toBe(200000);
      expect(repo.getExecutiveKPIs).toHaveBeenCalled();
    });
  });
});
