import '../models/app_session.dart';
import '../seeds/employee_seed.dart';

/// Default seed session — used when the app detects a persisted session on startup.
class SessionSeed {
  static AppSession createFresh() => AppSession.create(
        employeeId: EmployeeSeed.id,
        email: EmployeeSeed.email,
        provider: LoginProvider.google,
      );
}
