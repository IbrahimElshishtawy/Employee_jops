import { createParamDecorator, ExecutionContext } from "@nestjs/common";
import { CurrentUser as CurrentUserType } from "../interfaces/current-user.interface";

export const CurrentUser = createParamDecorator(
  (data: keyof CurrentUserType | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user;
    return data ? user?.[data] : user;
  },
);
