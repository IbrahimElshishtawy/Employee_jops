import { Role, UserStatus } from '@prisma/client';

export interface CurrentUser {
  id: string;
  email: string;
  role: Role;
  status: UserStatus;
  employeeProfileId?: string;
}
