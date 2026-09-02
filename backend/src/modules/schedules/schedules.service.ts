import { Injectable, NotFoundException } from "@nestjs/common";
import { CreateScheduleDto, UpdateScheduleDto } from "./dto";
import { SchedulesRepository } from "./schedules.repository";

@Injectable()
export class SchedulesService {
  constructor(private readonly schedulesRepo: SchedulesRepository) {}

  async create(data: CreateScheduleDto) {
    return this.schedulesRepo.create(data);
  }

  async findAll() {
    return this.schedulesRepo.findAll();
  }

  async findOne(id: string) {
    const schedule = await this.schedulesRepo.findById(id);
    if (!schedule) {
      throw new NotFoundException("Schedule not found");
    }
    return schedule;
  }

  async update(id: string, data: UpdateScheduleDto) {
    await this.findOne(id);
    return this.schedulesRepo.update(id, data);
  }

  async remove(id: string) {
    await this.findOne(id);
    return this.schedulesRepo.delete(id);
  }

  async assignToEmployee(scheduleId: string, employeeId: string) {
    await this.findOne(scheduleId);
    return this.schedulesRepo.assignToEmployee(scheduleId, employeeId);
  }
}
