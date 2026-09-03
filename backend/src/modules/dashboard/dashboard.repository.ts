import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import {
  AssetStatus,
  MaintenanceRequestStatus,
  WorkOrderStatus,
  PurchaseRequestStatus,
  PurchaseOrderStatus,
  IncidentStatus,
  LostFoundStatus,
  UserStatus,
} from "@prisma/client";

@Injectable()
export class DashboardRepository {
  constructor(private readonly prisma: PrismaService) {}

  async getExecutiveKPIs() {
    const today = new Date();
    const startOfToday = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);

    const [
      // Operational
      totalAssets,
      assetsUnderMaintenance,
      pendingMaintenanceRequests,
      activeWorkOrders,
      totalKeys,

      // Inventory & Procurement
      totalStockItems,
      pendingPurchaseRequests,
      activePurchaseOrders,

      // Finance
      expensesAgg,
      revenuesAgg,

      // Safety & Documents
      openIncidents,
      unclaimedLostFound,
      todayVisitors,

      // HR & Staff
      activeEmployees,
      activeTrainings,
    ] = await Promise.all([
      // Operational
      this.prisma.asset.count(),
      this.prisma.asset.count({ where: { status: AssetStatus.UNDER_MAINTENANCE } }),
      this.prisma.maintenanceRequest.count({ where: { status: MaintenanceRequestStatus.SUBMITTED } }),
      this.prisma.workOrder.count({ where: { status: WorkOrderStatus.IN_PROGRESS } }),
      this.prisma.physicalKey.count(),

      // Inventory & Procurement
      this.prisma.stockItem.count(),
      this.prisma.purchaseRequest.count({ where: { status: PurchaseRequestStatus.SUBMITTED } }),
      this.prisma.purchaseOrder.count({ where: { status: PurchaseOrderStatus.SENT } }),

      // Finance
      this.prisma.financialExpense.aggregate({
        _sum: { amount: true },
        where: { expenseDate: { gte: startOfMonth } },
      }),
      this.prisma.financialRevenue.aggregate({
        _sum: { amount: true },
        where: { revenueDate: { gte: startOfMonth } },
      }),

      // Safety & Docs
      this.prisma.safetyIncident.count({
        where: { status: { in: [IncidentStatus.REPORTED, IncidentStatus.UNDER_INVESTIGATION] } },
      }),
      this.prisma.lostFoundItem.count({ where: { status: LostFoundStatus.FOUND } }),
      this.prisma.visitorLog.count({ where: { checkInTime: { gte: startOfToday } } }),

      // HR
      this.prisma.employeeProfile.count({
        where: { user: { status: UserStatus.ACTIVE } },
      }),
      this.prisma.trainingSession.count({
        where: { status: "SCHEDULED" },
      }),
    ]);

    return {
      operational: {
        totalAssets,
        assetsUnderMaintenance,
        pendingMaintenanceRequests,
        activeWorkOrders,
        totalKeys,
      },
      supplyChain: {
        totalStockItems,
        pendingPurchaseRequests,
        activePurchaseOrders,
      },
      financeMonthToDate: {
        totalRevenue: revenuesAgg._sum.amount ? Number(revenuesAgg._sum.amount) : 0,
        totalExpenses: expensesAgg._sum.amount ? Number(expensesAgg._sum.amount) : 0,
        netProfit:
          (revenuesAgg._sum.amount ? Number(revenuesAgg._sum.amount) : 0) -
          (expensesAgg._sum.amount ? Number(expensesAgg._sum.amount) : 0),
      },
      safetyAndSecurity: {
        openIncidents,
        unclaimedLostFound,
        todayVisitors,
      },
      workforce: {
        activeEmployees,
        activeTrainings,
      },
      asOfDate: new Date(),
    };
  }
}
