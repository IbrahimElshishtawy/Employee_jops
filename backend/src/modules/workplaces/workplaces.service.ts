import {
  Injectable,
  NotFoundException,
  ConflictException,
} from "@nestjs/common";
import { CreateWorkplaceDto } from "./dto/create-workplace.dto";
import { UpdateWorkplaceDto } from "./dto/update-workplace.dto";
import { WorkplacesRepository } from "./workplaces.repository";

@Injectable()
export class WorkplacesService {
  constructor(private readonly workplacesRepo: WorkplacesRepository) {}

  async create(dto: CreateWorkplaceDto) {
    const existing = await this.workplacesRepo.findByCode(dto.code);
    if (existing) {
      throw new ConflictException("Workplace code already exists");
    }

    return this.workplacesRepo.create(dto);
  }

  async findAll() {
    return this.workplacesRepo.findAll();
  }

  async findOne(id: string) {
    const workplace = await this.workplacesRepo.findById(id);
    if (!workplace) {
      throw new NotFoundException("Workplace not found");
    }

    return workplace;
  }

  async update(id: string, dto: UpdateWorkplaceDto) {
    await this.findOne(id);
    return this.workplacesRepo.update(id, dto);
  }

  async remove(id: string) {
    await this.findOne(id);
    return this.workplacesRepo.delete(id);
  }

  async assignToEmployee(workplaceId: string, employeeId: string) {
    await this.findOne(workplaceId);
    return this.workplacesRepo.assignToEmployee(workplaceId, employeeId);
  }
}
