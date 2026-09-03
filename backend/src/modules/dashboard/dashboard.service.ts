import { Injectable, Logger } from "@nestjs/common";
import { DashboardRepository } from "./dashboard.repository";

@Injectable()
export class DashboardService {
  private readonly logger = new Logger(DashboardService.name);

  constructor(private readonly repo: DashboardRepository) {}

  async getExecutiveKPIs() {
    return this.repo.getExecutiveKPIs();
  }
}
