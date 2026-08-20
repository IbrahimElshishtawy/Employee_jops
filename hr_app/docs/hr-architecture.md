# CyberWise IE — HR Management System Architecture Specification

## 1. System Overview & Core Principles

The **CyberWise IE HR Management System** is an enterprise-grade administrative dashboard designed for authorized HR personnel and leadership. It communicates seamlessly with the unified **CyberWise IE Backend API and Database**, operating in harmony with the existing **Employee Mobile App**.

```
                           CyberWise IE
                                |
                 ┌──────────────┴──────────────┐
                 |                             |
          Employee Mobile App             HR Dashboard
             (Flutter Mobile)           (Flutter Web/Desktop)
                 |                             |
                 └──────────────┬──────────────┘
                                |
                         Backend REST API
                                |
                             Database
```

### Architectural Tenets
1. **Single Source of Truth**: The Backend API is the authoritative source for data validation, role authorization, and audit logs. The frontend never makes authoritative security or payroll decisions.
2. **Clean Architecture (Domain-Driven Design)**: Strict unidirectional dependencies from Presentation → Domain → Data → Core/API.
3. **No Business Logic in Widgets**: UI components are purely declarative. State and logic reside in dedicated controllers and use cases.
4. **Dual Data Layer (Safe Mock Mode vs Live REST API)**: Mock repositories with strictly fake `TEST-EMP-xxx` test data implement the identical Domain repository interfaces as production REST API clients.
5. **Role-Based Access Control (RBAC)**: Centralized authorization service with granular permissions (`employees.read`, `requests.approve`, etc.) and route/widget gating.

---

## 2. Final Project Folder Structure

```
hr_app/
├── docs/
│   └── hr-architecture.md             # This document
├── lib/
│   ├── app/
│   │   ├── app.dart                   # Root MaterialApp with theme & router
│   │   └── app_bootstrap.dart         # Async initialization (Storage, DI, Env, Auth)
│   ├── core/
│   │   ├── config/                    # AppConfig, EnvConfig, FeatureFlags
│   │   ├── constants/                 # ApiEndpoints, AppColors, AppDimensions, AppTypography
│   │   ├── errors/                    # AppException, Failure, ErrorHandler
│   │   ├── localization/              # AppStrings
│   │   ├── network/                   # ApiClient, ApiResponse, Interceptors (Auth, Logging)
│   │   ├── rbac/                      # AppRole, AppPermission, AuthorizationService, PermissionGuard
│   │   ├── routing/                   # AppRouter, RouteGuards, RouteNames
│   │   ├── security/                  # SessionManager, TokenStorage
│   │   ├── storage/                   # LocalStorage
│   │   ├── theme/                     # AppTheme (Light/Dark), ThemeController
│   │   ├── utils/                     # DateFormatter, ResponsiveLayout, Validator
│   │   └── widgets/                   # Reusable UI Design System
│   │       ├── cards/                 # StatCard, ChartCard
│   │       ├── feedback/              # StatusBadge, EmptyStateView, ErrorStateView, LoadingStateView
│   │       ├── filters/               # FilterBar, DateRangePickerField
│   │       ├── forms/                 # HrTextField, HrButton
│   │       ├── layout/                # HrScaffold, HrSidebar, HrTopbar
│   │       └── tables/                # HrDataTable, TablePagination
│   └── features/                      # 14 Independent HR Feature Modules
│       ├── authentication/            # Login, Session Management, Logout
│       ├── dashboard/                 # KPI Metrics, Attendance Distribution
│       ├── employees/                 # Employee Directory, Status Management
│       ├── attendance/                # Punch Logs, Tardiness, Overtime
│       ├── requests/                  # Unified Requests (Leave, Permission, Late, Absence, Half-Day)
│       ├── advances/                  # Salary Advance Requests & Approvals
│       ├── deductions/                # Disciplinary & Absence Deductions
│       ├── workplaces/                # Geofenced Workplace Locations
│       ├── schedules/                 # Shifts & Working Hour Policies
│       ├── reports/                   # Operational Reports & CSV Exports
│       ├── notifications/             # Real-time System Alerts
│       ├── messages/                  # HR Broadcast Announcements
│       ├── audit_logs/                # Immutable Administrative Audit Trail
│       └── settings/                  # System Runtime Info & Dev RBAC Switcher
├── test/
│   ├── core/                          # RBAC, Utils, Route Guards tests
│   ├── features/                      # Mock repositories contract tests
│   └── widgets/                       # Component rendering tests
└── pubspec.yaml
```

---

## 3. Layer Architecture Breakdown

### 1. Presentation Layer
- **Pages**: Screen views (e.g., `EmployeeListScreen`, `DashboardScreen`, `LoginScreen`).
- **Widgets**: Reusable, state-agnostic presentation components.
- **Controllers**: `ChangeNotifier` state containers managing loading states, validation, and domain interactions.

### 2. Domain Layer
- **Entities**: Pure Dart domain models with business invariants (e.g., `EmployeeEntity`, `AttendanceRecord`, `HrRequestEntity`).
- **Repository Contracts**: Abstract interfaces defining data requirements without implementation details.
- **Failures**: Typed domain-level error representations mapped for safe user display.

### 3. Data Layer
- **DTOs / Models**: JSON serializable objects mapping to and from the CyberWise IE backend schema.
- **Data Sources & API Clients**: Centralized HTTP client with interceptors for headers, tokens, and sanitization.
- **Mock Repositories**: Self-contained mock data sources using strictly fake information for fast offline development.

### 4. Core Layer
- **Network**: `ApiClient`, `AuthInterceptor`, `LoggingInterceptor`.
- **Security & Storage**: `TokenStorage`, `SessionManager`, `LocalStorage`.
- **RBAC**: `AuthorizationService`, `AppRole`, `AppPermission`, `PermissionGuard`.
- **Routing**: `AppRouter` with `ShellRoute` and `RouteGuards`.

---

## 4. Role-Based Access Control (RBAC) Matrix

| Permission Key | Description | Super Admin | HR Admin | HR Manager | HR Staff | Viewer |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| `employees.read` | View employee roster | ✅ | ✅ | ✅ | ✅ | ✅ |
| `employees.create` | Add new employee | ✅ | ✅ | ❌ | ❌ | ❌ |
| `employees.update` | Edit employee details | ✅ | ✅ | ✅ | ❌ | ❌ |
| `employees.delete` | Suspend/deactivate employee | ✅ | ✅ | ❌ | ❌ | ❌ |
| `attendance.read` | View attendance records | ✅ | ✅ | ✅ | ✅ | ✅ |
| `attendance.export` | Export attendance CSV | ✅ | ✅ | ✅ | ❌ | ❌ |
| `requests.read` | View unified requests | ✅ | ✅ | ✅ | ✅ | ✅ |
| `requests.approve` | Approve requests | ✅ | ✅ | ✅ | ❌ | ❌ |
| `requests.reject` | Reject requests | ✅ | ✅ | ✅ | ❌ | ❌ |
| `advances.read` | View salary advances | ✅ | ✅ | ✅ | ✅ | ✅ |
| `advances.approve` | Approve salary advances | ✅ | ✅ | ✅ | ❌ | ❌ |
| `deductions.read` | View deductions | ✅ | ✅ | ✅ | ✅ | ✅ |
| `deductions.create` | Create deductions | ✅ | ✅ | ❌ | ❌ | ❌ |
| `workplaces.read` | View workplace geofences | ✅ | ✅ | ✅ | ✅ | ✅ |
| `workplaces.create` | Create workplaces | ✅ | ✅ | ❌ | ❌ | ❌ |
| `schedules.read` | View work schedules | ✅ | ✅ | ✅ | ✅ | ✅ |
| `audit_logs.read` | View administrative audit trail | ✅ | ✅ | ❌ | ❌ | ✅ |
| `settings.manage` | Modify system configurations | ✅ | ❌ | ❌ | ❌ | ❌ |

---

## 5. Development & Production Workflows

### Development Mode (Offline / Mock Mode)
- Configured via `EnvConfig.enableMockData = true`.
- Repositories automatically use `MockAuthRepository`, `MockEmployeeRepository`, etc.
- Safe test identities (`TEST-EMP-001` to `TEST-EMP-005`) are provided out-of-the-box.
- Built-in **RBAC Role Switcher** on the Settings page allows testing permission variations instantly.

### Staging / Production Mode (Live REST API)
- Set `EnvConfig.currentEnvironment = Environment.prod`.
- `enableMockData` is strictly locked to `false`.
- All requests are routed through `HttpApiClient` with `Bearer` authentication tokens stored via `TokenStorage`.
- Inactivity timeouts are monitored and enforced by `SessionManager`.

---

## 6. How to Extend With New HR Features

1. **Define Entity in Domain**: Create `lib/features/<feature>/domain/entities/<name>_entity.dart`.
2. **Define Repository Contract**: Add abstract methods in `domain/repositories/`.
3. **Implement Repositories**:
   - `Mock<Feature>Repository` in `data/repositories/`.
   - `Api<Feature>Repository` in `data/repositories/`.
4. **Create Controller**: State management in `presentation/controllers/`.
5. **Create Screen**: Build UI in `presentation/pages/` utilizing `FilterBar`, `HrDataTable`, and `StatusBadge`.
6. **Register in DI & Router**: Register repository in `AppBootstrap`, provide via `HrApp`, and add route in `AppRouter`.
