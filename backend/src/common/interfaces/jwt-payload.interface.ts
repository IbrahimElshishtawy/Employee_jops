export interface JwtPayload {
  sub: string;
  email: string;
  role: string;
  employeeProfileId?: string;
  iat?: number;
  exp?: number;
}
