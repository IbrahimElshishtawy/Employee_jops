# CYBERWISE HOTEL ERP BACKEND — FINAL WORKFLOW IMPLEMENTATION STATUS

**Document Version:** 3.0.0  
**Date:** September 4, 2026  
**Auditor:** Senior Backend Architect & Production Readiness Engineer  
**Status:** CODE VERIFIED & ARCHITECTURALLY PROVEN  
**Repository Root:** `C:\flutter pro\Employee_jops\backend`

---

## 1. COMPREHENSIVE REQUIREMENTS TO CODE PIPELINE

Below is the verified chain for every business workflow across the entire Hotel ERP system.

```
REQUIREMENT
→ WORKFLOW
→ API ENDPOINT
→ CONTROLLER
→ SERVICE
→ DATABASE (PRISMA / POSTGRESQL)
→ AUTHORIZATION (GUARDS / ROLES)
→ SIDE EFFECTS (AUDIT / NOTIFICATIONS / REALTIME)
→ TESTS (JEST SUITES)
→ STATUS
```

---

### DOMAIN 1: AUTHENTICATION & DEVICE SESSIONS

#### 1. User Credential Authentication & Device Fingerprinting
- **Requirement:** FR-AUTH-001 (Secure user login with argon2/bcrypt password hashing, device session creation, JWT access & refresh token issuance).
- **Workflow:** User submits username/email, password, and device telemetry $\rightarrow$ Credentials verified $\rightarrow$ Session registered $\rightarrow$ Dual JWT issued.
- **API:** `POST /api/v1/auth/login`
- **Controller:** `AuthController.login()` ([auth.controller.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/auth/auth.controller.ts#L29))
- **Service:** `AuthService.login()` ([auth.service.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/auth/auth.service.ts#L45))
- **Database:** `User`, `RefreshToken`, `HardwareSession`
- **Authorization:** `@Public()` (Unauthenticated entrypoint with Throttler rate limiting)
- **Side Effects:** `AuditLog` entry (`LOGIN_SUCCESS`), device session tracking with IP and User-Agent.
- **Tests:** `src/modules/auth/auth.service.spec.ts`
- **Status:** **IMPLEMENTED**

#### 2. Refresh Token Rotation & Replay Detection
- **Requirement:** FR-AUTH-002 (Rotating refresh token prevents token reuse; revokes session on replay attempt).
- **Workflow:** Client sends valid refresh token $\rightarrow$ Database validates hash and session $\rightarrow$ Invalidates old token $\rightarrow$ Issues new token pair.
- **API:** `POST /api/v1/auth/refresh`
- **Controller:** `AuthController.refresh()` ([auth.controller.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/auth/auth.controller.ts#L52))
- **Service:** `AuthService.refreshTokens()` ([auth.service.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/auth/auth.service.ts#L110))
- **Database:** `RefreshToken`, `HardwareSession`
- **Authorization:** `JwtAuthGuard` (RefreshToken Strategy)
- **Side Effects:** Revocation of previous token family on replay detection.
- **Tests:** `src/modules/auth/auth.service.spec.ts`
- **Status:** **IMPLEMENTED**

#### 3. Remote Device Revocation & Logout
- **Requirement:** FR-AUTH-003 (Terminate active hardware session from user profile or admin console).
- **Workflow:** User/Admin initiates device termination $\rightarrow$ Session marked inactive $\rightarrow$ Associated refresh tokens deleted $\rightarrow$ Forces client re-login.
- **API:** `DELETE /api/v1/sessions/:id`
- **Controller:** `SessionsController.revokeSession()` ([sessions.controller.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/sessions/sessions.controller.ts#L24))
- **Service:** `SessionsService.revokeSession()` ([sessions.service.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/sessions/sessions.service.ts#L50))
- **Database:** `HardwareSession`, `RefreshToken`
- **Authorization:** `JwtAuthGuard` (Owner or Admin authorization check)
- **Side Effects:** `AuditLog` entry (`SESSION_REVOKED`).
- **Tests:** `src/modules/sessions/sessions.service.spec.ts`
- **Status:** **IMPLEMENTED**

---

### DOMAIN 2: WORKFORCE, ATTENDANCE & SHIFTS

#### 4. Geofence & Anti-Spoofing Attendance Check-in
- **Requirement:** FR-ATT-001 (Validates working day, GPS accuracy $\le 50$m, workplace radius, mock location anti-fraud, shift grace period, duplicate check-in prevention).
- **Workflow:** Mobile app sends GPS lat/long + telemetry $\rightarrow$ Haversine distance computed $\rightarrow$ Shift late minutes evaluated $\rightarrow$ Atomic check-in saved.
- **API:** `POST /api/v1/attendance/check-in`
- **Controller:** `AttendanceController.checkIn()` ([attendance.controller.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/attendance/attendance.controller.ts#L26))
- **Service:** `AttendanceService.checkIn()` ([attendance.service.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/attendance/attendance.service.ts#L85))
- **Database:** `AttendanceRecord`, `AttendanceEvent`, `Workplace`, `Schedule`
- **Authorization:** `JwtAuthGuard`
- **Side Effects:** `AuditLog`, `AttendanceEvent`, late notification dispatch if late minutes $> 0$.
- **Tests:** `src/modules/attendance/attendance.service.spec.ts`, `attendance-operations.spec.ts`, `employee-core-e2e.spec.ts`
- **Status:** **IMPLEMENTED**

#### 5. Attendance Check-out & Overtime Computation
- **Requirement:** FR-ATT-002 (Validates existing open session, checks minimum shift hours, computes overtime and early departure).
- **Workflow:** Mobile app sends checkout payload $\rightarrow$ Server closes active check-in record $\rightarrow$ Computes worked minutes $\rightarrow$ Updates daily summary.
- **API:** `POST /api/v1/attendance/check-out`
- **Controller:** `AttendanceController.checkOut()` ([attendance.controller.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/attendance/attendance.controller.ts#L45))
- **Service:** `AttendanceService.checkOut()` ([attendance.service.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/attendance/attendance.service.ts#L320))
- **Database:** `AttendanceRecord`, `AttendanceEvent`
- **Authorization:** `JwtAuthGuard`
- **Side Effects:** `AttendanceEvent` (`CHECK_OUT_ACCEPTED`), `AuditLog`.
- **Tests:** `src/modules/attendance/attendance.service.spec.ts`
- **Status:** **IMPLEMENTED**

#### 6. Manual HR Attendance Correction
- **Requirement:** FR-ATT-003 (Authorized HR administrator corrects missed punches or amends status with reason).
- **Workflow:** HR submits adjustment $\rightarrow$ Old vs new values captured $\rightarrow$ Record updated inside transaction $\rightarrow$ Immutable audit log created.
- **API:** `POST /api/v1/attendance/manual`
- **Controller:** `AttendanceController.manualAttendance()` ([attendance.controller.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/attendance/attendance.controller.ts#L60))
- **Service:** `AttendanceService.manualAttendance()` ([attendance.service.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/attendance/attendance.service.ts#L510))
- **Database:** `AttendanceRecord`, `AttendanceEvent`, `AuditLog`
- **Authorization:** `JwtAuthGuard`, `@Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)`
- **Side Effects:** `AuditLog` with delta payload; employee notified.
- **Tests:** `src/modules/attendance/attendance-operations.spec.ts`
- **Status:** **IMPLEMENTED**

---

### DOMAIN 3: REQUESTS & MULTI-TIER APPROVAL WORKFLOWS

#### 7. Employee Leave Request Submission
- **Requirement:** FR-REQ-001 (Leave submission with balance deduction preview, working day calculation, and multi-step approval attachment).
- **Workflow:** Employee submits leave type + date range $\rightarrow$ Balance checked $\rightarrow$ Days reserved $\rightarrow$ Request and ordered approval steps generated.
- **API:** `POST /api/v1/requests`
- **Controller:** `RequestsController.create()` ([requests.controller.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/requests/requests.controller.ts#L40))
- **Service:** `RequestsService.create()` ([requests.service.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/requests/requests.service.ts#L109))
- **Database:** `Request`, `ApprovalStep`, `LeaveBalance`
- **Authorization:** `JwtAuthGuard`, `RolesGuard`
- **Side Effects:** Pending days deducted from `LeaveBalance`; Notification sent to Step 1 approver.
- **Tests:** `src/modules/requests/requests.service.spec.ts`, `phase4-workflow-approvals.spec.ts`
- **Status:** **IMPLEMENTED**

#### 8. Multi-Level Approval Step Execution
- **Requirement:** FR-REQ-002 (Sequential approval through Department Manager, HR, and GM with delegation support).
- **Workflow:** Current level approver approves step $\rightarrow$ Step updated to `APPROVED` $\rightarrow$ If last step, Request marked `APPROVED` and balance finalized; if intermediate, advances to next step.
- **API:** `POST /api/v1/requests/:id/approve`
- **Controller:** `RequestsController.approve()` ([requests.controller.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/requests/requests.controller.ts#L75))
- **Service:** `RequestsService.approve()` ([requests.service.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/requests/requests.service.ts#L220))
- **Database:** `Request`, `ApprovalStep`, `LeaveBalance`
- **Authorization:** `JwtAuthGuard`, `@Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)`
- **Side Effects:** `AuditLog` entry; Employee notified of approval.
- **Tests:** `src/modules/phase4-workflow-approvals.spec.ts`
- **Status:** **IMPLEMENTED**

---

### DOMAIN 4: TASKS, WORK MANAGEMENT & SHIFT HANDOVER

#### 9. Task Lifecycle & State Machine Transitions
- **Requirement:** FR-TSK-001 (Task lifecycle: TODO $\rightarrow$ ACCEPTED $\rightarrow$ IN_PROGRESS $\rightarrow$ BLOCKED $\rightarrow$ PENDING_REVIEW $\rightarrow$ COMPLETED / CANCELLED).
- **Workflow:** User submits state change $\rightarrow$ Validates transition against state machine matrix $\rightarrow$ Updates progress and timestamps $\rightarrow$ Records history.
- **API:** `PATCH /api/v1/tasks/:id/status`
- **Controller:** `TasksController.updateStatus()` ([tasks.controller.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/tasks/tasks.controller.ts#L40))
- **Service:** `TasksService.updateStatus()` ([tasks.service.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/tasks/tasks.service.ts#L241))
- **Database:** `Task`, `TaskHistory`, `AuditLog`
- **Authorization:** `JwtAuthGuard`, `RolesGuard` (Assignee, Creator, or Department Manager)
- **Side Effects:** Task history entry; counterpart user notified.
- **Tests:** `src/modules/phase5-tasks-work-management.spec.ts`
- **Status:** **IMPLEMENTED**

#### 10. Shift Handover Protocol & Open Task Capture
- **Requirement:** FR-HND-001 (Digital shift handover capturing open department tasks, cash balance, and VIP notes with dual sign-off).
- **Workflow:** Outgoing supervisor generates handover $\rightarrow$ Server auto-attaches open department tasks $\rightarrow$ Incoming supervisor acknowledges and confirms.
- **API:** `POST /api/v1/handover` & `POST /api/v1/handover/:id/acknowledge`
- **Controller:** `HandoverController` ([handover.controller.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/handover/handover.controller.ts#L33))
- **Service:** `HandoverService` ([handover.service.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/handover/handover.service.ts#L39))
- **Database:** `ShiftHandover`, `ShiftHandoverItem`, `Task`
- **Authorization:** `JwtAuthGuard`, `RolesGuard`
- **Side Effects:** `AuditLog` (`HANDOVER_CREATED`, `HANDOVER_ACKNOWLEDGED`), Notification dispatched.
- **Tests:** `src/modules/handover/handover.service.spec.ts`, `phase7-service-requests-handover-operations.spec.ts`
- **Status:** **IMPLEMENTED**

---

### DOMAIN 5: ASSETS, MAINTENANCE & INVENTORY

#### 11. Asset Maintenance & Work Order Execution
- **Requirement:** FR-MNT-001 (Report broken asset, transition asset to UNDER_MAINTENANCE, issue work order, consume spare parts, return asset to ACTIVE on completion).
- **Workflow:** Tech creates work order $\rightarrow$ Consumes parts $\rightarrow$ Warehouse balance deducted $\rightarrow$ Completes order $\rightarrow$ Asset restored.
- **API:** `POST /api/v1/maintenance/work-orders` & `POST /api/v1/maintenance/work-orders/:id/parts`
- **Controller:** `MaintenanceController` ([maintenance.controller.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/maintenance/maintenance.controller.ts#L37))
- **Service:** `MaintenanceService` ([maintenance.service.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/maintenance/maintenance.service.ts#L43))
- **Database:** `Asset`, `MaintenanceRequest`, `WorkOrder`, `SparePart`, `StockItem`
- **Authorization:** `JwtAuthGuard`, `RolesGuard`
- **Side Effects:** Inventory balance updated; `AuditLog` recorded.
- **Tests:** `src/modules/maintenance/maintenance.service.spec.ts`
- **Status:** **IMPLEMENTED**

#### 12. Multi-Warehouse Stock Transfer & Low-Stock Alerts
- **Requirement:** FR-INV-001 (Multi-warehouse stock movements with sufficiency check, reorder level tracking, and automated low-stock warnings).
- **Workflow:** User initiates transfer $\rightarrow$ Verifies available stock $\rightarrow$ Deducts source, adds target warehouse $\rightarrow$ Triggers alert if $\le$ reorder level.
- **API:** `POST /api/v1/inventory/movements`
- **Controller:** `InventoryController.executeStockMovement()` ([inventory.controller.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/inventory/inventory.controller.ts#L32))
- **Service:** `InventoryService.executeStockMovement()` ([inventory.service.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/inventory/inventory.service.ts#L177))
- **Database:** `StockItem`, `StockMovement`, `Warehouse`
- **Authorization:** `JwtAuthGuard`, `RolesGuard`
- **Side Effects:** Low stock alert logged and dispatched; `AuditLog` recorded.
- **Tests:** `src/modules/inventory/inventory.service.spec.ts`
- **Status:** **IMPLEMENTED**

---

### DOMAIN 6: FINANCE, BUDGETS & PAYROLL

#### 13. Double-Entry Balanced Journal Postings
- **Requirement:** FR-FIN-001 (Double-entry journal validation requiring $\sum \text{debits} == \sum \text{credits}$, immutable once posted).
- **Workflow:** Finance submits lines $\rightarrow$ Invariant check $| \sum D - \sum C | \le 0.001$ $\rightarrow$ Entry registered $\rightarrow$ Posted to General Ledger.
- **API:** `POST /api/v1/finance/journal-entries`
- **Controller:** `FinanceController.createJournalEntry()` ([finance.controller.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/finance/finance.controller.ts#L32))
- **Service:** `FinanceService.createJournalEntry()` ([finance.service.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/finance/finance.service.ts#L74))
- **Database:** `JournalEntry`, `JournalEntryLine`, `ChartOfAccount`
- **Authorization:** `JwtAuthGuard`, `@Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)`
- **Side Effects:** `AuditLog` with total monetary sum.
- **Tests:** `src/modules/finance/finance.service.spec.ts`
- **Status:** **IMPLEMENTED**

#### 14. Monthly Payroll Calculation & Gross-to-Net Finalization
- **Requirement:** FR-PAY-001 (Gross-to-net calculation incorporating base salary, allowances, attendance late penalties, approved advance installments, tax, and social insurance).
- **Workflow:** Admin opens period $\rightarrow$ Triggers calculation $\rightarrow$ Generates payslip line items $\rightarrow$ Review $\rightarrow$ Finalize period (locks records).
- **API:** `POST /api/v1/payroll/calculate` & `POST /api/v1/payroll/finalize`
- **Controller:** `PayrollController` ([payroll.controller.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/payroll/payroll.controller.ts#L43))
- **Service:** `PayrollService` ([payroll.service.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/payroll/payroll.service.ts#L40))
- **Database:** `PayrollPeriod`, `PayrollRecord`, `PayrollLineItem`, `SalaryProfile`, `AdvanceInstallment`
- **Authorization:** `JwtAuthGuard`, `@Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)`
- **Side Effects:** Advance installment marked PAID; employee notifications sent; `AuditLog` recorded.
- **Tests:** `src/modules/payroll/payroll.service.spec.ts`
- **Status:** **IMPLEMENTED**

---

### DOMAIN 7: OFFLINE SYNC, BACKUPS & DISASTER RECOVERY

#### 15. Offline Mutation Batch Synchronization
- **Requirement:** FR-SYNC-001 (Batch push of mobile offline actions with client UUID deduplication, server conflict detection, and delta extraction).
- **Workflow:** Client pushes mutation batch $\rightarrow$ `clientActionId` checked $\rightarrow$ Timestamp conflict checked $\rightarrow$ Executed in Prisma transaction.
- **API:** `POST /api/v1/sync/batch` & `GET /api/v1/sync/changes`
- **Controller:** `OfflineSyncController` ([offline-sync.controller.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/offline-sync/offline-sync.controller.ts#L25))
- **Service:** `OfflineSyncService` ([offline-sync.service.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/offline-sync/offline-sync.service.ts#L30))
- **Database:** `OfflineSyncQueue`, `Task`, `ServiceRequest`
- **Authorization:** `JwtAuthGuard`
- **Side Effects:** Real-time WebSocket event dispatch.
- **Tests:** `src/modules/offline-sync/offline-sync.service.spec.ts`
- **Status:** **IMPLEMENTED**

#### 16. Database Snapshot Backup & Verified Restore
- **Requirement:** FR-BKP-001 (JSON entity snapshot serialization, SHA-256 integrity checksum, dry-run simulation mode, and retention enforcement).
- **Workflow:** SuperAdmin triggers snapshot $\rightarrow$ Table records serialized $\rightarrow$ SHA-256 computed $\rightarrow$ Saved to archive $\rightarrow$ Tested with dry-run restore.
- **API:** `POST /api/v1/backup` & `POST /api/v1/backup/:id/restore`
- **Controller:** `BackupController` ([backup.controller.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/backup/backup.controller.ts#L22))
- **Service:** `BackupService` ([backup.service.ts](file:///C:/flutter%20pro/Employee_jops/backend/src/modules/backup/backup.service.ts#L26))
- **Database:** `SystemSetting`, `Department`, `AssetCategory`, `Warehouse`, `StockCategory`, `AuditLog`
- **Authorization:** `JwtAuthGuard`, `@Roles(Role.SUPER_ADMIN)`
- **Side Effects:** `AuditLog` entry; retention cleanup removes backups $> 30$ days.
- **Tests:** `src/modules/backup/backup.service.spec.ts`
- **Status:** **IMPLEMENTED**
