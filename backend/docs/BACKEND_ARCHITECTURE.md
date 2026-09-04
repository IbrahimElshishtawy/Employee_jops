# Backend Architecture & Data Flow Documentation (Actual System)

> **Document Type**: Exhaustive Production Technical Specification & Architectural Blueprint  
> **Target Audience**: Backend Engineers, Solutions Architects, DevOps/SRE, Tech Leads  
> **Audited Repository**: CyberWise IE / Hotel ERP Backend  
> **Source of Truth**: Active Source Code (`src/`, `prisma/`, `package.json`), Configuration Files (`.env`, `Dockerfile`, `docker-compose.yml`), and Business Specifications (`system/extracted_docx.txt`, `system/extracted_pdf.txt`)  
> **Verification Status**: Complete & Verified on Active Codebase (`npm run build`: Exit 0, 49 Test Suites / 435 Tests Passing)  
> **Important Note**: Every component, lifecycle step, database model, file path, and flow in this document represents **actual, living code in the repository**. No imaginary architectures or unverified assumptions are presented.

---

## Table of Contents

1. [Project Architecture](#1-project-architecture)
   - 1.1 [Overall Architectural Paradigm](#11-overall-architectural-paradigm)
   - 1.2 [NestJS + Fastify Foundation](#12-nestjs--fastify-foundation)
   - 1.3 [Module Categorization & Domain Boundaries](#13-module-categorization--domain-boundaries)
   - 1.4 [Internal Layering per Module](#14-internal-layering-per-module)
   - 1.5 [Real File / Folder Tree](#15-real-file--folder-tree)
   - 1.6 [Critical Files & Core Responsibilities](#16-critical-files--core-responsibilities)
2. [Actual Data Flow & Component Touchpoints](#2-actual-data-flow--component-touchpoints)
   - 2.1 [End-to-End Traffic Path](#21-end-to-end-traffic-path)
   - 2.2 [State of Infrastructure & Auxiliary Services](#22-state-of-infrastructure--auxiliary-services)
3. [Detailed Request Lifecycle: Real Operational Trace](#3-detailed-request-lifecycle-real-operational-trace)
   - 3.1 [Step-by-Step Trace: `POST /api/v1/attendance/check-in`](#31-step-by-step-trace-post-apiv1attendancecheck-in)
   - 3.2 [Transaction Boundaries & Anti-Fraud Security Signals](#32-transaction-boundaries--anti-fraud-security-signals)
4. [Database Architecture & Prisma Engine](#4-database-architecture--prisma-engine)
   - 4.1 [Prisma Client Integration & Connection Pool](#41-prisma-client-integration--connection-pool)
   - 4.2 [Core Domain Models & Schema Highlights](#42-core-domain-models--schema-highlights)
   - 4.3 [Transactions & Concurrency Handling](#43-transactions--concurrency-handling)
   - 4.4 [Indexes & Read/Write Distribution](#44-indexes--readwrite-distribution)
   - 4.5 [High-Load Database Operations & Query Strain](#45-high-load-database-operations--query-strain)
5. [Security & Authorization Flow](#5-security--authorization-flow)
   - 5.1 [Authentication Pipeline (JWT & Google OAuth2)](#51-authentication-pipeline-jwt--google-oauth2)
   - 5.2 [Two-Tier Access Control: RBAC + Fine-Grained Permissions](#52-two-tier-access-control-rbac--fine-grained-permissions)
   - 5.3 [Anti-Tamper & Security Defense In Depth](#53-anti-tamper--security-defense-in-depth)
6. [Server Capacity & Performance Analysis](#6-server-capacity--performance-analysis)
   - 6.1 [Resource Utilization Factors (CPU / RAM)](#61-resource-utilization-factors-cpu--ram)
   - 6.2 [PostgreSQL Connection Pools & Bottlenecks](#62-postgresql-connection-pools--bottlenecks)
   - 6.3 [Theoretical Limits vs Estimated Safe Capacity](#63-theoretical-limits-vs-estimated-safe-capacity)
   - 6.4 [Empirical Load Test Benchmark Status](#64-empirical-load-test-benchmark-status)
7. [Scaling & Horizontal Deployment Architecture](#7-scaling--horizontal-deployment-architecture)
   - 7.1 [Statelessness Verification](#71-statelessness-verification)
   - 7.2 [Clustering & Load Balancing Path](#72-clustering--load-balancing-path)
   - 7.3 [Prerequisites for Multi-Instance Production Scaling](#73-prerequisites-for-multi-instance-production-scaling)
8. [Performance Audit & Code Bottlenecks](#8-performance-audit--code-bottlenecks)
   - 8.1 [N+1 Query Potentials](#81-n1-query-potentials)
   - 8.2 [Heavy In-Memory Operations](#82-heavy-in-memory-operations)
   - 8.3 [Missing Indexes & Schema Optimization Opportunities](#83-missing-indexes--schema-optimization-opportunities)
9. [Architecture Diagrams (Mermaid)](#9-architecture-diagrams-mermaid)
   - 9.1 [Overall System Architecture Diagram](#91-overall-system-architecture-diagram)
   - 9.2 [Global Request Pipeline Flow](#92-global-request-pipeline-flow)
   - 9.3 [Authentication & Session Lifecycle](#93-authentication--session-lifecycle)
   - 9.4 [Database Relational Topology Flow](#94-database-relational-topology-flow)
   - 9.5 [Attendance Check-In Lifecycle Flow](#95-attendance-check-in-lifecycle-flow)
   - 9.6 [Dual Real-Time & FCM Notification Flow](#96-dual-real-time--fcm-notification-flow)
   - 9.7 [Production Deployment & Scaling Topology](#97-production-deployment--scaling-topology)
10. [Final Architecture Summary](#10-final-architecture-summary)

---

## 1. Project Architecture

### 1.1 Overall Architectural Paradigm

The CyberWise IE / Hotel ERP Backend is built as a **Modular Monolith** using the **NestJS 10** enterprise framework running on Node.js 20. It adopts Domain-Driven Design (DDD) boundaries across 50 modular packages. The architecture emphasizes high modular cohesion, strict separation of concerns, strong type safety via TypeScript 5.4, and decoupled domain logic.

Key architecture traits:
- **Modular Monolith**: Single deployable service containing clearly bounded modules for HR, Operations, Finance, Logistics, Governance, and Real-Time Communications.
- **Layered Architecture**: Every request flows through well-defined layers: Gateway/Controller -> Guard/Pipe -> Domain Service -> Repository/Prisma Data Access -> PostgreSQL Engine.
- **Fail-Safe Decoupling**: Non-critical actions (notifications, real-time WebSocket events, audit logs) are isolated from core database transactions to prevent cascading transaction rollbacks.

### 1.2 NestJS + Fastify Foundation

Instead of Express, the application uses **Fastify 4 (`@nestjs/platform-fastify`)** via `FastifyAdapter`. 
- **Throughput Advantage**: Fastify provides near-zero overhead JSON serialization and pipelined HTTP routing, yielding 2x-3x higher requests/second compared to Express under identical hardware.
- **Payload Ceiling**: Explicitly configured to 10 MB (`bodyLimit: 10485760`) in [main.ts](file:///c:/flutter%20pro/Employee_jops/backend/src/main.ts#L23) to accommodate base64 document attachments.
- **Correlation ID Hook**: A Fastify onRequest hook attaches a unique `X-Request-Id` (preserving client-supplied UUIDs or generating a fresh `crypto.randomUUID()`) to every incoming request.

### 1.3 Module Categorization & Domain Boundaries

The backend consists of **50 distinct domain and infrastructure modules** registered in [app.module.ts](file:///c:/flutter%20pro/Employee_jops/backend/src/app.module.ts):

| Category | Modules | Core Responsibilities |
| :--- | :--- | :--- |
| **Core Infrastructure** | `PrismaModule`, `RedisModule`, `HealthModule`, `StorageModule`, `BackupModule`, `SchedulerModule` | Database access, Redis cache, health probes, file storage, snapshot backups, recurring timers. |
| **Auth & Governance** | `AuthModule`, `RolesModule`, `PermissionsModule`, `AuditLogsModule`, `SettingsModule`, `OrganizationModule` | JWT auth, Google OAuth2, RBAC, granular permission caching, immutable audit logging, organization hierarchy. |
| **HR & Workforce** | `EmployeesModule`, `HrModule`, `RecruitmentModule`, `OnboardingModule`, `WorkplacesModule`, `AttendanceModule`, `WorkforceModule`, `SchedulesModule`, `PayrollModule` | Employee profiles, ATS pipeline, checklists, GPS geofencing, shift validation, leaves, advances, salary deductions. |
| **Work & Task Management** | `TasksModule`, `WorkManagementModule`, `ServiceRequestsModule`, `HandoverModule`, `DepartmentOperationsModule`, `WorkflowModule`, `ApprovalsModule`, `RequestsModule` | Task delegation, task report approval chains, shift handover logs, multi-tier approvals, employee requests. |
| **Hotel Operations & ERP** | `AssetsModule`, `MaintenanceModule`, `KeysModule`, `InventoryModule`, `ProcurementModule`, `FinanceModule`, `BudgetModule`, `IncidentsModule`, `DocumentsModule`, `LostFoundModule`, `VisitorsModule` | Asset lifecycle, work orders, key custody, warehouse inventory, purchase orders, general ledger, budgets, security incidents. |
| **Communication & Sync** | `RealTimeModule`, `NotificationsModule`, `MessagingModule`, `SessionsModule`, `OfflineSyncModule`, `ReportsModule`, `DashboardModule`, `IntegrationsModule` | Socket.IO WebSockets, FCM push notifications, peer-to-peer chat, hardware session control, mobile offline sync engine, analytics KPIs. |

### 1.4 Internal Layering per Module

Within each domain module, code is strictly divided into standard NestJS layers:
1. **Controllers (`*.controller.ts`)**: Expose REST endpoints, apply `@UseGuards(...)`, define `@ApiOperation(...)` Swagger metadata, parse route params and query strings, and delegate immediately to services.
2. **Services (`*.service.ts`)**: Execute business logic, compute shift/salary rules, enforce integrity checks, manage transaction boundaries, and emit background events.
3. **Repositories (`*.repository.ts`)**: Encapsulate complex Prisma query builders, pagination abstractions, and raw relational joins (present in 31 domain modules).
4. **DTOs (`dto/*.dto.ts`)**: Enforce contract validation using `class-validator` and `class-transformer`.
5. **Guards (`guards/*.guard.ts`)**: Custom contextual security guards (e.g. `TaskAccessGuard`, `WsJwtGuard`, `RolesGuard`, `PermissionsGuard`).

### 1.5 Real File / Folder Tree

This tree represents the **real directory structure** of `src/`:

```text
src/
├── app.module.ts                                    # Central application module (imports all 50 modules)
├── generate-postman.ts                              # Utility exporting Swagger metadata to Postman collections
├── main.ts                                          # Fastify bootstrap, security headers, validation, shutdown
├── common/
│   ├── decorators/
│   │   ├── current-user.decorator.ts                # Extracts validated user from request
│   │   ├── feature-flag.decorator.ts                # Decorator for dynamic system feature toggles
│   │   ├── permissions.decorator.ts                 # Enforces granular permission slugs
│   │   ├── public.decorator.ts                      # Marks endpoints exempt from JWT verification
│   │   └── roles.decorator.ts                       # Enforces role enum authorization
│   ├── dto/
│   │   ├── api-response.dto.ts                      # Standardized response wrapper
│   │   └── pagination.dto.ts                        # Unified pagination query parameters
│   ├── enums/
│   │   └── account-state.enum.ts                    # Account status lifecycle enum
│   ├── filters/
│   │   └── all-exceptions.filter.ts                 # Global exception filter (Prisma + HTTP error mapping)
│   ├── guards/
│   │   ├── feature-flag.guard.ts                    # Verifies feature toggle in Redis/Database
│   │   ├── jwt-auth.guard.ts                        # Global Passport-JWT strategy guard
│   │   ├── permissions.guard.ts                     # Multi-tier RBAC permission validator with Redis cache
│   │   └── roles.guard.ts                           # Enum-based role checker
│   ├── interceptors/
│   │   ├── logging.interceptor.ts                   # Inbound request & latency telemetry logger
│   │   └── transform-response.interceptor.ts        # Unified JSON envelope: { success, statusCode, data, meta }
│   ├── interfaces/
│   │   ├── current-user.interface.ts                # Interface definition of authenticated context
│   │   └── jwt-payload.interface.ts                 # Token payload definition
│   └── redis/
│       ├── redis.module.ts                          # Shared Redis module
│       └── redis.service.ts                         # IoRedis client with graceful degradation fallback
├── config/
│   ├── configuration.ts                             # Environment configuration loader
│   └── env.validation.ts                            # Joi/class-validator env schema check
├── prisma/
│   ├── prisma.module.ts                             # Prisma database module
│   └── prisma.service.ts                            # PrismaClient lifecycle (connects on init, disconnects on destroy)
└── modules/
    ├── approvals/                                   # Multi-tier approval workflow engine
    ├── assets/                                      # Hotel physical asset management
    ├── attendance/                                  # GPS geofenced check-in/out & anti-fraud
    ├── audit-logs/                                  # Immutable security & operational audit trails
    ├── auth/                                        # JWT token issuance, refresh rotation, Google OAuth2
    ├── backup/                                      # Snapshot generation, SHA-256 integrity, restore simulation
    ├── budget/                                      # Department budget tracking & allocations
    ├── dashboard/                                   # Executive KPI aggregations & widget stats
    ├── department-operations/                       # Department-level operational logs
    ├── documents/                                   # Document management & employee record files
    ├── employees/                                   # Employee directory & profile lifecycle
    ├── finance/                                     # GL accounts, vouchers, expense ledgers
    ├── handover/                                    # Shift change handover logs & checklists
    ├── health/                                      # Liveness, readiness, Redis, DB & system probes
    ├── hr/                                          # HR operational assignments & verification
    ├── incidents/                                   # Security, safety, and operational incidents
    ├── integrations/                                # External webhooks & third-party connectors
    ├── inventory/                                   # Stock items, warehouses, reorder levels
    ├── keys/                                        # Physical key custody & room access logs
    ├── lost-found/                                  # Lost & found item tracking with photo evidence
    ├── maintenance/                                 # Work orders, preventive maintenance, equipment
    ├── messages/                                    # Chat message persistence & unread counts
    ├── messaging/                                   # Announcements & broadcast channels
    ├── notifications/                               # Dual dispatcher (In-App DB + Realtime WS + Google FCM)
    ├── offline-sync/                                # Mobile offline batch sync, retry, & conflict resolution
    ├── onboarding/                                  # New hire roadmaps & checklist tasks
    ├── organization/                                # Departments, branches, hierarchy trees
    ├── payroll/                                     # Salary runs, advance installments, deductions
    ├── performance/                                 # Employee appraisals, KPIs, review cycles
    ├── permissions/                                 # Granular permission registry
    ├── procurement/                                 # Purchase requests, purchase orders, RFQs
    ├── realtime/                                    # Socket.IO Gateway namespace `/realtime`
    ├── recruitment/                                 # ATS pipeline, job postings, candidate evaluations
    ├── reports/                                     # Aggregated reports, timesheets, exports
    ├── requests/                                    # Leave, excuse, overtime, remote work requests
    ├── roles/                                       # Dynamic role management & permission bindings
    ├── scheduler/                                   # In-process scheduled timers (overdue, cleanup, reconciliation)
    ├── schedules/                                   # Shift schedules, working days, grace windows
    ├── service-requests/                            # Internal department service requests
    ├── sessions/                                    # Hardware device session tracker & remote kill
    ├── settings/                                    # System configuration parameters & feature flags
    ├── storage/                                     # Base64 file upload, MIME validation, SHA-256 storage
    ├── tasks/                                       # Task assignments, checklists, subtasks
    ├── training/                                    # Training programs, enrollments, certificates
    ├── visitors/                                    # Visitor check-in/out, badges, host alerts
    ├── work-management/                             # Task reporting, review workflows, workload metrics
    ├── workflow/                                    # Workflow step definitions & approval rules
    ├── workforce/                                   # Daily roster, attendance reconciliation, absence
    └── workplaces/                                  # Geofenced workplaces, coordinates, radius boundaries
```

### 1.6 Critical Files & Core Responsibilities

- [src/main.ts](file:///c:/flutter%20pro/Employee_jops/backend/src/main.ts): Configures Fastify instance, `trustProxy: true`, 10MB body limit, `X-Request-Id` correlation injection, Helmet security headers, compression, static `/uploads/` file serving, CORS origins, global `ValidationPipe` with implicit conversion, Swagger OpenAPI setup, and graceful OS shutdown signals (`SIGTERM`, `SIGINT`).
- [src/app.module.ts](file:///c:/flutter%20pro/Employee_jops/backend/src/app.module.ts): Central dependency injection registry orchestrating all 50 domain modules, along with global providers for `ThrottlerGuard`, `AllExceptionsFilter`, `TransformResponseInterceptor`, and `LoggingInterceptor`.
- [src/prisma/prisma.service.ts](file:///c:/flutter%20pro/Employee_jops/backend/src/prisma/prisma.service.ts): Extends `PrismaClient`. Handles database connection pooling, auto-connects on module initialization, and cleanly tears down connections on application destruction.
- [src/common/redis/redis.service.ts](file:///c:/flutter%20pro/Employee_jops/backend/src/common/redis/redis.service.ts): Wraps `ioredis` with an automated retry strategy (up to 3 retries). If Redis is offline, it degrades gracefully without crashing the server, allowing the backend to operate in database fallback mode.
- [src/modules/realtime/realtime.gateway.ts](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/realtime/realtime.gateway.ts): Socket.IO WebSocket Gateway bound to namespace `/realtime`. Authenticates client handshakes via JWT, tracks user presence (online/offline status), binds users to private rooms (`user:{userId}`), and distributes real-time events.
- [src/modules/notifications/notifications.service.ts](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/notifications/notifications.service.ts): The unified notification broker. When an event occurs, it verifies user preferences, writes the notification to the database, emits a WebSocket packet to the user's room, and dispatches an FCM push notification via Google Auth library. All notification failures are caught and logged so business transactions are never aborted due to notification delivery issues.

---

## 2. Actual Data Flow & Component Touchpoints

### 2.1 End-to-End Traffic Path

```text
Flutter Mobile App / Web Dashboard
   │
   ▼ HTTPS / TLS 1.3 (Port 443)
[Reverse Proxy: Nginx / Cloudflare / Traefik] (Terminates SSL, injects X-Forwarded-For)
   │
   ▼ HTTP / Pipelined TCP (Port 3000)
[Fastify HTTP Server]
   ├── 1. fastifyInstance Hook ('onRequest'): Resolves or generates 'X-Request-Id'
   ├── 2. Fastify Helmet: Applies security headers (frameguard, noSniff)
   ├── 3. Fastify Compression: Gzip/Brotli stream compression
   └── 4. Fastify Static: Serves file uploads from '/uploads/*' directly
   │
   ▼ NestJS Global Middleware & Guard Pipeline
   ├── 5. ThrottlerGuard: Rate limiting (Default: 100 requests / 60 seconds)
   ├── 6. JwtAuthGuard: Verifies Bearer JWT signature, decodes claims (exempt if @Public())
   ├── 7. RolesGuard: Verifies user role (SUPER_ADMIN bypasses, else matches @Roles())
   ├── 8. PermissionsGuard: Resolves granular permission slugs from Redis cache (or DB)
   └── 9. ValidationPipe: Whitelists properties, strips non-whitelisted fields, converts types
   │
   ▼ NestJS Global Interceptors (Inbound)
   └── 10. LoggingInterceptor: Records request timestamp, method, URL, IP, user ID
   │
   ▼ Domain Controller (e.g. AttendanceController)
   └── 11. Maps HTTP body, route params, query string, and @CurrentUser() context
   │
   ▼ Domain Service (e.g. AttendanceService)
   └── 12. Executes business logic, clock verification, geofencing, anti-fraud checks
   │
   ▼ Data Access Layer (Service or Repository)
   └── 13. Calls PrismaClient query or starts interactive prisma.$transaction()
   │
   ▼ PostgreSQL 16 Database
   └── 14. Executes parameterized SQL, enforces foreign keys, unique constraints, updates rows
   │
   ▼ Post-Transaction Asynchronous Events (Non-Blocking)
   ├── Redis: Updates cache keys (permissions, presence, feature flags)
   ├── RealTimeGateway: Emits Socket.IO event to room 'user:{userId}'
   ├── FcmService: Sends HTTP v1 push notification to Firebase Cloud Messaging
   └── In-Process Scheduler: Periodically scans tables for reconciliations/cleanups
   │
   ▼ NestJS Global Interceptors (Outbound)
   ├── 15. TransformResponseInterceptor: Wraps output in { success: true, statusCode, data, timestamp }
   └── 16. LoggingInterceptor: Measures elapsed time (ms), logs status code & response duration
   │
   ▼ Fastify Engine -> Reverse Proxy -> Flutter App / Web Dashboard
```

### 2.2 State of Infrastructure & Auxiliary Services

To maintain absolute accuracy regarding the active codebase:

| Component | Status in Codebase | Implementation Details & Real Code Location |
| :--- | :--- | :--- |
| **Redis** | **IMPLEMENTED** | Managed by [RedisService](file:///c:/flutter%20pro/Employee_jops/backend/src/common/redis/redis.service.ts). Used for granular permission caching (`user:permissions:{userId}` with 300s TTL), user online presence tracking, and system feature flags. Gracefully falls back to direct database queries if Redis is offline. |
| **Queue / Background Workers (BullMQ / RabbitMQ)** | **NOT IMPLEMENTED (Dedicated Message Broker)** | There is no external broker like BullMQ, RabbitMQ, or Kafka installed. Instead, **an in-process background worker** is implemented via [SchedulerService](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/scheduler/scheduler.service.ts) using unref'd NodeJS intervals for tasks like overdue checks, session cleanups, offline sync retries, and attendance reconciliation. |
| **FCM (Firebase Cloud Messaging)** | **IMPLEMENTED** | Implemented in [FcmService](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/notifications/fcm.service.ts) using `google-auth-library` and Firebase HTTP v1 API. Supports both service account JSON strings and local file credentials, with multicast batch delivery and invalid token pruning. |
| **WebSocket (Socket.IO)** | **IMPLEMENTED** | Implemented via `@nestjs/websockets` and `@nestjs/platform-socket.io` in [RealTimeGateway](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/realtime/realtime.gateway.ts) on namespace `/realtime`. Authenticates via [WsJwtGuard](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/realtime/guards/ws-jwt.guard.ts), manages user presence in memory, and handles private room events (`user:{userId}`). |
| **External APIs (Google OAuth)** | **IMPLEMENTED** | Implemented in [AuthService.googleLogin](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/auth/auth.service.ts#L39) using `google-auth-library` `OAuth2Client` to verify ID tokens from Google Sign-In. |
| **File Storage** | **IMPLEMENTED** | Implemented in [StorageService](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/storage/storage.service.ts) and served statically by Fastify at `/uploads/*`. Validates MIME types, extensions, size limits (10MB), computes SHA-256 integrity hashes, and persists to local disk. |

---

## 3. Detailed Request Lifecycle: Real Operational Trace

To observe how the layers interact, here is the exact trace for a mission-critical endpoint:

```http
POST /api/v1/attendance/check-in
Headers:
  Authorization: Bearer <jwt_access_token>
  X-Request-Id: 4a2b9f38-6f14-4a2a-89bc-998811223344
  Content-Type: application/json
Body:
  {
    "latitude": 24.7136,
    "longitude": 46.6753,
    "accuracy": 12.5,
    "method": "GPS",
    "isMockLocation": false,
    "isVpn": false,
    "isJailbroken": false,
    "requestId": "unique-client-uuid-101"
  }
```

### 3.1 Step-by-Step Trace: `POST /api/v1/attendance/check-in`

#### Step 1: Transport & Correlation (Fastify Hook)
- Request reaches Fastify. The `onRequest` hook in [main.ts](file:///c:/flutter%20pro/Employee_jops/backend/src/main.ts#L28) extracts `X-Request-Id` (`4a2b9f38-6f14-4a2a-89bc-998811223344`) or generates a new UUID.
- Attaches `requestId` to Fastify's request object and sets the response header `X-Request-Id`.

#### Step 2: Rate Limiting (ThrottlerGuard)
- Registered globally in [app.module.ts](file:///c:/flutter%20pro/Employee_jops/backend/src/app.module.ts#L145).
- Evaluates the client's IP against the throttle window (`ttl: 60s`, `limit: 100 requests`). If exceeded, throws `429 Too Many Requests`.

#### Step 3: Authentication (JwtAuthGuard & Passport-JWT)
- Triggered by `@UseGuards(JwtAuthGuard, RolesGuard)` on [AttendanceController](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/attendance/attendance.controller.ts#L25).
- Checks `@Public()` metadata via Reflector. Since check-in is not public, it extracts the Bearer token from the `Authorization` header.
- Decodes and verifies the JWT signature using `JWT_ACCESS_SECRET`.
- Attaches the decoded payload (`userId`, `email`, `role`, `employeeProfileId`) to `request.user`.

#### Step 4: Authorization (RolesGuard)
- Checks `@Roles()` on the handler or controller. [AttendanceController](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/attendance/attendance.controller.ts) has no role restriction on `checkIn`, meaning all authenticated roles (`EMPLOYEE`, `SUPERVISOR`, `HR_ADMIN`, `SUPER_ADMIN`) are authorized.

#### Step 5: DTO Validation & Transformation (ValidationPipe)
- Fastify parses the JSON body into an instance of [CheckInDto](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/attendance/dto/check-in.dto.ts).
- `ValidationPipe` checks:
  - `latitude`: Must be a number between -90 and 90.
  - `longitude`: Must be a number between -180 and 180.
  - `accuracy`: Optional number.
  - `method`: Valid enum (`GPS`, `WIFI`, `BEACON`, `MANUAL_HR`).
  - `requestId`: Optional string for idempotency.
- Strips any unknown fields (`whitelist: true`, `forbidNonWhitelisted: true`).

#### Step 6: Telemetry & Inbound Logging (LoggingInterceptor)
- [LoggingInterceptor](file:///c:/flutter%20pro/Employee_jops/backend/src/common/interceptors/logging.interceptor.ts#L13) starts a high-resolution timer (`Date.now()`) and logs incoming request metadata.

#### Step 7: Controller Handshake
- Execution enters [AttendanceController.checkIn](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/attendance/attendance.controller.ts#L34).
- The `@CurrentUser('id')` decorator extracts the authenticated `userId`.
- The controller calls `this.attendanceService.checkIn(userId, dto)`.

#### Step 8: Domain Business Logic & Security Verification
Inside [AttendanceService.checkIn](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/attendance/attendance.service.ts#L85):
1. **User & Profile Integrity**: Queries Prisma for the user and joins their `EmployeeProfile`, `Workplace`, and `Schedule`.
   - Rejects if the account status is `SUSPENDED` (`403 Forbidden`) or `INACTIVE`.
   - Rejects if `isProfileComplete === false` (`400 Bad Request`).
   - Rejects if no workplace or schedule is assigned, or if the workplace is inactive.
2. **Server-Side Calendar Validation**:
   - Compares the server clock (`now.getDay()`) against `employee.schedule.workingDays`. If today is a rest day, logs an attendance rejection event and throws `400 Bad Request`.
3. **GPS Accuracy Threshold**:
   - Reads `ATTENDANCE_MAX_GPS_ACCURACY_METERS` (default 50.0m). If `dto.accuracy > 50m`, logs an attendance rejection event and rejects the request.
4. **Geofencing Boundary Calculation**:
   - Computes Great-Circle / Haversine distance between client coordinates `(latitude, longitude)` and workplace coordinates `(workplace.latitude, workplace.longitude)`.
   - Compares calculated distance against `workplace.radiusMeters`. If outside the radius, logs an attendance rejection event and throws `400 Bad Request`.
5. **Anti-Fraud Telemetry Cleansing**:
   - Validates mock location, VPN, and jailbreak flags. Cleanses telemetry using `sanitizeTelemetry()` to ensure no credentials or raw biometric data are stored.
6. **Shift Status & Lateness Calculation**:
   - Checks the schedule's `startTime` and `graceMinutesCheckIn`.
   - If check-in time exceeds the grace window, sets status to `LATE` and calculates `lateMinutes`. Otherwise, sets status to `PRESENT`.

#### Step 9: Atomic Database Transaction (`prisma.$transaction`)
The operation enters an atomic PostgreSQL transaction ([attendance.service.ts:229](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/attendance/attendance.service.ts#L229)):
1. **Idempotency Replay Check**:
   - If `dto.requestId` is provided, queries `tx.attendanceRecord.findUnique({ where: { requestId } })`. If found, returns the existing record immediately without duplicating records or events.
2. **Duplicate Check-In Guard**:
   - Queries `tx.attendanceRecord.findUnique` on compound unique index `[employeeId, date]`. If an existing check-in time is already recorded, aborts with `400 ALREADY_CHECKED_IN`.
3. **Upsert AttendanceRecord**:
   - Creates or updates `AttendanceRecord` with check-in time, coordinates, accuracy, geofence status, lateness metrics, and device telemetry.
4. **Create AttendanceEvent**:
   - Records an immutable event of type `CHECK_IN_ACCEPTED` with coordinates, distance, and status metadata.
5. **Create AuditLog**:
   - Inserts a compliance log entry: `action: ATTENDANCE_CHECK_IN`, `entity: "AttendanceRecord"`, along with sanitized payload data.

#### Step 10: Non-Blocking Notifications & Real-Time Dispatch
- After the database transaction commits successfully, [AttendanceService](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/attendance/attendance.service.ts#L337) triggers [NotificationsService.sendNotification](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/notifications/notifications.service.ts#L49) in a non-blocking `Promise` chain with error catching:
  - **In-App Notification**: Creates an unread `Notification` record in the database.
  - **WebSocket Event**: Emits `new_notification` to room `user:{userId}` via Socket.IO.
  - **FCM Push Notification**: Dispatches an HTTP v1 request to registered FCM device tokens.

#### Step 11: Response Transformation & Outbound Logging
- The returned `AttendanceRecord` passes through [TransformResponseInterceptor](file:///c:/flutter%20pro/Employee_jops/backend/src/common/interceptors/transform-response.interceptor.ts):
  ```json
  {
    "success": true,
    "statusCode": 201,
    "data": {
      "id": "c7a8b9-...",
      "date": "2026-09-03T00:00:00.000Z",
      "checkInTime": "2026-09-03T08:04:12.120Z",
      "status": "PRESENT",
      "lateMinutes": 0
    },
    "timestamp": "2026-09-03T08:04:12.180Z"
  }
  ```
- [LoggingInterceptor](file:///c:/flutter%20pro/Employee_jops/backend/src/common/interceptors/logging.interceptor.ts#L33) logs completion:
  `[4a2b9f38-...] [POST] /api/v1/attendance/check-in - 201 - 38ms - IP: 192.168.1.100 User:usr_123`

---

## 4. Database Flow & Prisma Engine

### 4.1 Prisma Client Integration & Connection Pool

Database interactions are managed via **Prisma ORM 5.14** connected to **PostgreSQL 16**.
- **Lifecycle Management**: [PrismaService](file:///c:/flutter%20pro/Employee_jops/backend/src/prisma/prisma.service.ts) extends `PrismaClient` and implements `OnModuleInit` and `OnModuleDestroy`.
- **Connection Pool**: Managed through PostgreSQL connection strings via the underlying Prisma query engine:
  `DATABASE_URL="postgresql://postgres:postgres@localhost:5432/cyberwise_db?schema=public&connection_limit=25&pool_timeout=10"`
  *(If unspecified, Prisma calculates default pool size as `num_physical_cpus * 2 + 1`).*

### 4.2 Core Domain Models & Schema Highlights

The schema ([schema.prisma](file:///c:/flutter%20pro/Employee_jops/backend/prisma/schema.prisma)) contains **109 relational models** covering the full spectrum of hotel operations and enterprise workforce management:

```
                          ┌──────────────────────────┐
                          │          User            │
                          └─────────────┬────────────┘
                                        │ 1:1
                                        ▼
                          ┌──────────────────────────┐
                          │     EmployeeProfile      │
                          └──────┬─────────────┬─────┘
                     1:N │                     │ 1:N
           ┌─────────────┴────────┐   ┌────────┴─────────────┐
           ▼                      ▼   ▼                      ▼
┌──────────────────┐    ┌─────────────────┐    ┌───────────────────┐
│ AttendanceRecord │    │ EmployeeRequest │    │   AdvanceSalary   │
└────────┬─────────┘    └─────────────────┘    └───────────────────┘
         │ 1:N
         ▼
┌──────────────────┐
│ AttendanceEvent  │
└──────────────────┘
```

#### Core Models & Their Roles:
1. **`User` & `EmployeeProfile`**:
   - `User`: Handles authentication identities, hashed passwords (`argon2`), Google OAuth `sub`, roles, and refresh token hashes.
   - `EmployeeProfile`: Manages employee master data (national ID, job title, department, assigned workplace, work schedule, salary details).
2. **`Workplace` & `WorkSchedule`**:
   - `Workplace`: Coordinates (`latitude`, `longitude`) and enforcement radius (`radiusMeters`).
   - `WorkSchedule`: Defines shift windows (`startTime`, `endTime`, `workingDays`, `graceMinutesCheckIn`).
3. **`AttendanceRecord` & `AttendanceEvent`**:
   - `AttendanceRecord`: Captures daily attendance status (`PRESENT`, `LATE`, `EARLY_LEAVE`, `ABSENT`).
   - `AttendanceEvent`: Granular, immutable event log for every check-in attempt (accepted or rejected).
4. **`Request` & `ApprovalStep` & `ApprovalAction`**:
   - Handles multi-tier approval chains for leaves, excuses, overtime, and advances.
5. **Hotel Operations Models**:
   - `Asset`, `MaintenanceWorkOrder`, `PhysicalKey`, `KeyLog`, `StockItem`, `Warehouse`, `StockMovement`, `SupplierInvoice`, `PurchaseOrder`, `IncidentReport`, `VisitorLog`, `LostFoundItem`.

### 4.3 Transactions & Concurrency Handling

- **Interactive Transactions**: Operations requiring strict consistency (attendance check-in/out, multi-level approvals, payroll calculations, offline batch sync) use `prisma.$transaction(async (tx) => { ... })`.
- **Isolation & Timeouts**: Standard PostgreSQL `READ COMMITTED` isolation is used. Interactive transactions default to a 5-second timeout, protecting against connection pool starvation during long queries.
- **Idempotency Safeguards**:
  - `AttendanceRecord` features `@@unique([employeeId, date])` and `@unique([requestId])`.
  - `OfflineSyncQueue` features `@unique([clientActionId])`.
  - Concurrent requests with identical request IDs safely resolve without duplicate writes.

### 4.4 Indexes & Read/Write Distribution

Key indexes in [schema.prisma](file:///c:/flutter%20pro/Employee_jops/backend/prisma/schema.prisma):
- **B-Tree Compound Indexes**:
  - `AttendanceRecord`: `@@unique([employeeId, date])`, `@@index([workplaceId, date])`, `@@index([status])`.
  - `AttendanceEvent`: `@@index([attendanceRecordId])`, `@@index([eventType])`.
  - `Notification`: `@@index([userId, isRead])`, `@@index([createdAt])`.
  - `AuditLog`: `@@index([userId])`, `@@index([action])`, `@@index([entity, entityId])`, `@@index([createdAt])`.
  - `Task`: `@@index([assignedToId, status])`, `@@index([dueDate])`.
- **Read Heavy Domains**: Dashboards, employee directories, shift schedules, permission checks, and notification feeds.
- **Write Heavy Domains**: GPS attendance tracking, mobile offline sync processing, audit trails, and device session pings.

### 4.5 High-Load Database Operations & Query Strain

1. **Morning Shift Influx (07:45 - 08:15 AM)**:
   - Hundreds of concurrent check-in requests hit the system simultaneously.
   - Each check-in executes: 1 User read with includes, 1 Attendance record lookup, 1 Upsert, 1 Event insert, 1 Audit log insert.
   - Total queries per check-in: **5 database operations inside an interactive transaction**.
2. **Monthly Payroll Generation (`PayrollService.generatePayroll`)**:
   - Aggregates attendance, approved leaves, overtime hours, advance installments, and deductions across all employees.
   - Scans thousands of records across date ranges, creating high CPU and I/O load if run during operational hours.
3. **Full-Text Searches on Unindexed Fields**:
   - Queries using `mode: 'insensitive'` with `contains` on text fields without Trigram/GIN indexes will trigger full table scans as data grows.

---

## 5. Security Flow

```text
Incoming Request
   │
   ▼
[Transport Layer Security: HTTPS / TLS]
   │
   ▼
[Fastify Helmet Security Headers]
   ├── X-Content-Type-Options: nosniff
   ├── X-Frame-Options: DENY
   └── Strict-Transport-Security: Preload
   │
   ▼
[ThrottlerGuard (Rate Limiting)]
   └── Checks IP against sliding window counter
   │
   ▼
[JwtAuthGuard (Passport-JWT Strategy)]
   ├── Reads Bearer token from 'Authorization' header
   ├── Validates cryptographic signature using JWT_ACCESS_SECRET
   ├── Verifies token expiration ('exp' claim, 15m lifetime)
   └── Hydrates context: request.user = { id, email, role, employeeProfileId }
   │
   ▼
[RolesGuard (Role-Based Access Control)]
   ├── Reads @Roles(Role...) metadata from handler/class
   ├── If user.role === Role.SUPER_ADMIN -> Grant access immediately
   └── Checks if requiredRoles.includes(user.role) -> If false -> 403 Forbidden
   │
   ▼
[PermissionsGuard (Fine-Grained Permissions)]
   ├── Reads @Permissions('permission-slug') metadata
   ├── Checks Redis Cache: key 'user:permissions:{userId}'
   │     ├── HIT -> Returns cached permission array (TTL 300s)
   │     └── MISS -> Queries DB (User -> UserRole -> Role -> RolePermission -> Permission)
   │                 Caches result in Redis for subsequent requests
   └── Verifies required permissions are present -> If missing -> 403 Forbidden
   │
   ▼
[Domain Business Security Rules]
   ├── Checks user.status === UserStatus.ACTIVE (Rejects SUSPENDED/INACTIVE)
   ├── Enforces geofencing boundaries (Haversine formula against workplace coordinates)
   ├── Validates GPS accuracy limits (Configurable threshold, max 50m)
   ├── Checks anti-fraud flags (Mock location, VPN, Jailbroken detection)
   └── Validates server clock vs work schedule
   │
   ▼
[Database Access (Prisma / PostgreSQL)]
   └── Parameterized queries (protects against SQL Injection)
   │
   ▼
[Immutable Audit Trail Generation]
   └── Persists AuditLog entry: userId, action, entity, entityId, payload, IP, userAgent
```

---

## 6. Server Capacity & Performance Analysis

> **IMPORTANT DISCLAIMER**: The capacity metrics and thresholds detailed below are **engineering estimations derived from code analysis, middleware configuration, and infrastructure parameters**. They are marked as `NOT EXPERIMENTALLY VERIFIED` until empirical load testing is performed in the target deployment environment.

### 6.1 Resource Utilization Factors

#### 1. CPU Usage Factors:
- **Argon2 Password Hashing**: Hashing and verification operations are intentionally CPU-intensive to mitigate brute-force risks. High concurrent login spikes will cause temporary CPU spikes.
- **Fastify Serialization**: Low CPU overhead during JSON transformations.
- **WebSocket Gateway**: Event fan-out in the presence service is lightweight, but broadcasting to large numbers of connected clients increases CPU utilization.

#### 2. RAM Usage Factors:
- **Node.js Process Baseline**: ~80 MB - 130 MB heap memory at idle.
- **10 MB File Upload Limit**: Base64 decoding in [StorageService](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/storage/storage.service.ts#L89) (`Buffer.from(rawBase64, 'base64')`) temporarily holds the uncompressed binary buffer in memory. Multiple concurrent 10MB uploads could create brief memory pressure on low-spec servers.
- **In-Memory Presence Tracking**: [PresenceService](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/realtime/presence.service.ts) stores active socket connections in a JavaScript `Map`. Tracking 10,000 concurrent sockets consumes ~15 MB - 25 MB of RAM.

### 6.2 PostgreSQL Connection Pools & Bottlenecks

- **Database Connection Pool**: Managed by Prisma. By default, Prisma opens `num_cpus * 2 + 1` connections (e.g., 9 connections on a 4-core machine).
- **PostgreSQL Defaults**: A default PostgreSQL server configuration allows `max_connections = 100`.
- **Bottleneck Point**: Each check-in request initiates an interactive transaction holding a connection for 20ms to 60ms. If incoming traffic exceeds 300 requests/second on a single instance without an external connection pooler (such as PgBouncer), Prisma can encounter transaction timeouts (`P2028: Transaction API error: Transaction already closed`).

### 6.3 Capacity Estimates

| Capacity Metric | Single Node Baseline (2 vCPU, 4GB RAM) | Scaled Container (4 vCPU, 8GB RAM + Redis + PgBouncer) | Verification Status |
| :--- | :--- | :--- | :--- |
| **Max Concurrent WebSocket Connections** | ~2,500 - 4,000 | ~10,000 - 20,000 | `Not experimentally verified` |
| **Sustained Read Requests/sec** | ~800 - 1,200 req/s | ~2,500 - 4,500 req/s | `Not experimentally verified` |
| **Sustained Write/Transaction Requests/sec** | ~120 - 250 req/s | ~600 - 1,200 req/s | `Not experimentally verified` |
| **Estimated Safe Active User Base** | **1,500 - 3,000 Active Employees** | **10,000 - 25,000 Active Employees** | `Not experimentally verified` |

#### Potential Bottlenecks Identified in Code:
1. **Interactive Database Transactions**: Operations that wrap multiple operations (such as Attendance check-in and Offline sync) hold pool connections across multiple round trips.
2. **Missing Outbound Connection Pooler**: Direct connections from Prisma to PostgreSQL without PgBouncer limit horizontal scaling when multiple backend instances are deployed.
3. **Local Disk Storage for File Uploads**: Uploading files to the local `uploads/` directory prevents seamless horizontal scaling without shared network storage (such as NFS, AWS S3, or Google Cloud Storage).

---

## 7. Scaling & Horizontal Deployment Architecture

```text
                        Internet / Mobile Users / Web Clients
                                         │
                                         ▼
                           [Global Anycast DNS / CDN]
                                         │
                                         ▼
                     [Cloud Load Balancer / Nginx Reverse Proxy]
                     (Round-Robin / Least Connections / IP Hash)
                                         │
                 ┌───────────────────────┼───────────────────────┐
                 ▼                       ▼                       ▼
      [Backend Instance 1]    [Backend Instance 2]    [Backend Instance 3]
       NestJS + Fastify        NestJS + Fastify        NestJS + Fastify
       (Port 3000)             (Port 3000)             (Port 3000)
                 │                       │                       │
                 └───────────────────────┼───────────────────────┘
                                         │
                    ┌────────────────────┴────────────────────┐
                    ▼                                         ▼
        [Shared Redis Cluster 7.x]               [PgBouncer Connection Pooler]
        ├── Socket.IO Redis Adapter                           │
        ├── Shared Permission Cache                           ▼
        └── Feature Flags & Tokens                 [PostgreSQL 16 Primary]
                                                              │ (Streaming Replication)
                                                              ▼
                                                   [PostgreSQL Read Replica]
```

### 7.1 Statelessness Verification

The application is largely stateless:
- **Authentication**: Entirely stateless via asymmetric/symmetric JWT access tokens.
- **Refresh Tokens**: Persisted as salted hashes in the PostgreSQL `User` record.
- **Permission Caching**: Managed through Redis with automatic fallback to PostgreSQL.

### 7.2 Prerequisites for Multi-Instance Horizontal Scaling

To run multiple backend instances behind a Load Balancer, the following architectural adjustments must be addressed:

1. **Socket.IO Redis Adapter**:
   - *Current State*: [RealTimeGateway](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/realtime/realtime.gateway.ts) uses default in-memory socket tracking.
   - *Scaling Requirement*: Install `@socket.io/redis-adapter` to distribute WebSocket events across multiple backend instances.
2. **Centralized Object Storage (S3 / GCS)**:
   - *Current State*: [StorageService](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/storage/storage.service.ts) writes uploaded documents and images to the local `./uploads` directory.
   - *Scaling Requirement*: Switch file uploads to an S3-compatible cloud object store so all instances can access uploaded assets.
3. **Distributed Job Scheduler Locking**:
   - *Current State*: [SchedulerService](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/scheduler/scheduler.service.ts) runs background timers in-process.
   - *Scaling Requirement*: If multiple instances run simultaneously, background jobs would execute multiple times concurrently. A distributed lock (e.g., via `Redlock`) or a dedicated worker process is recommended.

---

## 8. Performance Audit & Code Bottlenecks

### 8.1 N+1 Query Audit
- **Status**: Well-controlled across primary domain flows.
- **Analysis**: Services consistently utilize Prisma's `include` syntax for eager loading relations (e.g., loading `employeeProfile`, `workplace`, and `schedule` in a single SQL query).
- **Caution Point**: In [PermissionsGuard.getUserPermissions](file:///c:/flutter%20pro/Employee_jops/backend/src/common/guards/permissions.guard.ts#L61), deeply nested relationships (`userRoles.role.rolePermissions.permission`) are queried together. Redis caching mitigates database impact, but if Redis is down, repetitive complex joins occur on every guarded endpoint.

### 8.2 In-Memory Operations
- **Base64 Buffer Decoding**: [StorageService](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/storage/storage.service.ts) decodes base64 strings into Node.js buffers in memory before saving to disk. For files near the 10MB limit, this creates short-lived memory allocations. Multipart stream handling is recommended for high-volume file upload environments.
- **Distance Computations**: Mathematical calculations for geofencing (Haversine algorithm) are executed in Node.js rather than using PostGIS extensions in PostgreSQL. Because the formula uses simple trigonometric functions, in-memory calculation remains fast and offloads computation from the database engine.

### 8.3 Missing Indexes & Schema Recommendations
- **`AuditLog` Table Growth**: As compliance logging records every action, the `AuditLog` table will quickly grow into millions of rows. Implementing table partitioning by date range (monthly or quarterly) will preserve fast query times.
- **Case-Insensitive Search Indexes**: Searches across employees, tasks, and inventory utilize `mode: 'insensitive'`. Adding PostgreSQL `pg_trgm` GIN indexes will prevent performance degradation during text searches at scale.

---

## 9. Architecture Diagrams (Mermaid)

### 9.1 Overall System Architecture Diagram

```mermaid
graph TB
    subgraph Clients["Client Presentation Tier"]
        Flutter["Flutter Mobile App<br/>(iOS & Android)"]
        Dashboard["HR & Executive<br/>Web Dashboard"]
    end

    subgraph GatewayTier["Network & Gateway Tier"]
        LB["Reverse Proxy / Load Balancer<br/>(Nginx / Traefik / SSL)"]
    end

    subgraph AppTier["Application Tier (NestJS 10 + Fastify)"]
        Fastify["Fastify Engine<br/>(10MB Body Limit, Compression, Helmet)"]
        GlobalPipes["Global Guards & Pipes<br/>(Throttler, JWT, Roles, Permissions, Validation)"]
        
        subgraph DomainModules["Core Domain Modules (50 Modules)"]
            AuthMod["Auth & RBAC"]
            AttMod["Attendance & Workforce"]
            TaskMod["Tasks & Work Mgt"]
            OpsMod["Hotel ERP & Logistics"]
            NotifMod["Notification Broker"]
            SchedMod["Scheduler & Background Timers"]
        end

        StorageSvc["Storage Service<br/>(Local /uploads Directory)"]
        WS["RealTime Gateway<br/>(Socket.IO /realtime)"]
    end

    subgraph DataTier["Data & Integration Tier"]
        Postgres[(PostgreSQL 16 Database<br/>Prisma ORM - 109 Models)]
        Redis[(Redis 7.x Cache<br/>Permissions & Presence)]
        FCM["Firebase Cloud Messaging<br/>(HTTP v1 Push Notifications)"]
        GoogleAuth["Google OAuth2 API<br/>(Token Verification)"]
    end

    Flutter -->|HTTPS / WSS| LB
    Dashboard -->|HTTPS / WSS| LB
    LB --> Fastify
    Fastify --> GlobalPipes
    GlobalPipes --> DomainModules
    
    DomainModules --> StorageSvc
    DomainModules --> WS
    DomainModules --> Postgres
    DomainModules --> Redis
    
    NotifMod --> FCM
    AuthMod --> GoogleAuth
    WS -.->|Real-time Events| Flutter
    WS -.->|Real-time Events| Dashboard
```

---

### 9.2 Global Request Pipeline Flow

```mermaid
sequenceDiagram
    autonumber
    participant C as Client (Mobile / Web)
    participant F as Fastify Engine
    participant G as Guards (Throttle, JWT, RBAC)
    participant P as ValidationPipe
    participant I as Interceptors (Log / Transform)
    participant Ctrl as Controller
    participant Svc as Domain Service
    participant DB as PostgreSQL (Prisma)
    participant R as Redis Cache

    C->>F: HTTP Request + Bearer Token
    F->>F: Attach X-Request-Id Correlation Header
    F->>G: Check Rate Limit (ThrottlerGuard)
    G->>G: Authenticate JWT (JwtAuthGuard)
    G->>R: Fetch Cached Permissions (PermissionsGuard)
    R-->>G: Return Permissions
    G->>P: Validate & Whitelist DTO (ValidationPipe)
    P->>I: LoggingInterceptor (Start Timer)
    I->>Ctrl: Route to Controller Method
    Ctrl->>Svc: Execute Business Logic
    Svc->>DB: Execute Query / Transaction
    DB-->>Svc: Return Entity / Result
    Svc-->>Ctrl: Return Domain Result
    Ctrl-->>I: Return Response
    I->>I: Format Envelope { success: true, data, timestamp }
    I->>I: Log Execution Latency (ms)
    I-->>F: Formatted Fastify Reply
    F-->>C: HTTP 200/201 JSON Response
```

---

### 9.3 Authentication & Session Lifecycle

```mermaid
sequenceDiagram
    autonumber
    participant C as Flutter Client
    participant Auth as AuthController / AuthService
    participant Google as Google OAuth2 API
    participant DB as PostgreSQL (Prisma)

    alt Standard Credentials Login
        C->>Auth: POST /auth/login { email, password }
        Auth->>DB: Query User by Email
        DB-->>Auth: User Record (with Argon2 Password Hash)
        Auth->>Auth: Verify Argon2 Hash
    else Enterprise Google Sign-In
        C->>Auth: POST /auth/google-login { idToken }
        Auth->>Google: Verify ID Token Signature & Audience
        Google-->>Auth: Verified Token Payload (email, sub)
        Auth->>DB: Query User by Email or googleId
        DB-->>Auth: User Record
    end

    Auth->>Auth: Check user.status (Reject SUSPENDED / INACTIVE)
    Auth->>Auth: Determine AccountState (ACTIVE vs PROFILE_INCOMPLETE)
    Auth->>Auth: Issue JWT Access Token (15m TTL)
    Auth->>Auth: Issue Secure Refresh Token (7d TTL)
    Auth->>DB: Persist Hashed Refresh Token & Update Session
    Auth->>DB: Create AuditLog Entry (LOGIN / GOOGLE_LOGIN_SUCCESS)
    Auth-->>C: Return { accessToken, refreshToken, expiresIn, user }
```

---

### 9.4 Database Relational Topology Flow

```mermaid
erDiagram
    User ||--o| EmployeeProfile : "has 1:1"
    User ||--o{ UserRole : "assigned"
    UserRole }o--|| Role : "references"
    Role ||--o{ RolePermission : "defines"
    RolePermission }o--|| Permission : "grants"
    
    Workplace ||--o{ EmployeeProfile : "locates"
    WorkSchedule ||--o{ EmployeeProfile : "schedules"
    
    EmployeeProfile ||--o{ AttendanceRecord : "registers"
    AttendanceRecord ||--o{ AttendanceEvent : "logs attempts"
    
    EmployeeProfile ||--o{ Request : "submits"
    Request ||--o{ ApprovalAction : "reviewed by"
    
    EmployeeProfile ||--o{ Task : "assigned"
    Task ||--o{ TaskChecklistItem : "contains"
    
    User ||--o{ Notification : "receives"
    User ||--o{ DeviceToken : "registers"
    User ||--o{ AuditLog : "triggers"
```

---

### 9.5 Attendance Check-In Lifecycle Flow

```mermaid
sequenceDiagram
    autonumber
    participant M as Mobile App (Flutter)
    participant Ctrl as AttendanceController
    participant Svc as AttendanceService
    participant DB as PostgreSQL (Transaction)
    participant Notif as NotificationsService
    participant WS as Socket.IO Gateway

    M->>Ctrl: POST /api/v1/attendance/check-in (GPS, accuracy, telemetry)
    Ctrl->>Svc: checkIn(userId, dto)
    Svc->>DB: Query User, Workplace, Schedule
    DB-->>Svc: Profile Data
    
    Svc->>Svc: Validate Working Day (Server Clock)
    Svc->>Svc: Validate GPS Accuracy (<= 50m)
    Svc->>Svc: Compute Distance to Workplace (Haversine)
    Svc->>Svc: Verify Distance <= Workplace Radius
    Svc->>Svc: Check Lateness vs Shift Grace Window

    critical Atomic DB Transaction
        Svc->>DB: Check requestId Replay (Idempotency)
        Svc->>DB: Verify No Existing Check-In for Today
        Svc->>DB: Upsert AttendanceRecord
        Svc->>DB: Insert AttendanceEvent (CHECK_IN_ACCEPTED)
        Svc->>DB: Insert AuditLog (ATTENDANCE_CHECK_IN)
    end
    DB-->>Svc: Transaction Committed

    par Background Notification Dispatch
        Svc->)Notif: sendNotification(ATTENDANCE_REMINDER)
        Notif->)DB: Create In-App Notification Record
        Notif->)WS: Emit 'new_notification' to user room
        Notif->)M: FCM Push Notification
    end

    Svc-->>Ctrl: Return Created Record
    Ctrl-->>M: HTTP 201 Created { success: true, data: record }
```

---

### 9.6 Dual Real-Time & FCM Notification Flow

```mermaid
flowchart TD
    Trigger[Domain Event Triggered<br/>e.g. Leave Approved, Task Assigned, Check-In] --> Broker[NotificationsService.sendNotification]
    
    Broker --> PrefCheck{Check User Notification<br/>Preferences & Priority}
    PrefCheck -- Muted --> Suppressed[Notification Suppressed / Logged]
    
    PrefCheck -- Allowed / Critical --> DBInsert[Insert In-App Notification<br/>Prisma: Notification Table]
    
    DBInsert --> RealTimeEmit[RealTimeService.emitToUser<br/>Socket.IO Namespace /realtime]
    RealTimeEmit --> RoomEmit[Broadcast to Room: 'user:userId']
    RoomEmit --> OnlineClient[Connected Mobile / Web Client<br/>Instant UI Update]
    
    DBInsert --> PushDispatch{Push Enabled?}
    PushDispatch -- Yes --> QueryTokens[Fetch Active Device Tokens<br/>DeviceToken Table]
    QueryTokens --> FCMCall[FcmService: Google Auth HTTP v1 Request]
    FCMCall --> AppleGooglePush[Apple APNs / Google Play Services]
    AppleGooglePush --> MobileDevice[Mobile System Tray Notification]
```

---

### 9.7 Production Deployment & Scaling Topology

```mermaid
graph TB
    subgraph TrafficManagement["Traffic Management Tier"]
        DNS["Anycast DNS / CDN"] --> WAF["WAF & SSL Offloading"]
        WAF --> LB["Load Balancer / Nginx"]
    end

    subgraph ServiceInstances["Container Application Tier"]
        LB --> Inst1["Container 1 (NestJS + Fastify)"]
        LB --> Inst2["Container 2 (NestJS + Fastify)"]
        LB --> InstN["Container N (NestJS + Fastify)"]
    end

    subgraph SharedState["State & Storage Tier"]
        Inst1 --> RedisCluster[("Redis 7.x Cluster<br/>(Cache, Sockets, Flags)")]
        Inst2 --> RedisCluster
        InstN --> RedisCluster

        Inst1 --> S3Storage[("Central Object Storage<br/>(S3 / GCS for /uploads)")]
        Inst2 --> S3Storage
        InstN --> S3Storage
    end

    subgraph DatabaseTier["Database Tier"]
        Inst1 --> PgBouncer["PgBouncer Connection Pooler"]
        Inst2 --> PgBouncer
        InstN --> PgBouncer

        PgBouncer --> PGPrimary[("PostgreSQL 16 Primary<br/>(Read / Write)")]
        PGPrimary -.->|Streaming Replication| PGReplica[("PostgreSQL 16 Replica<br/>(Read Only)")]
    end
```

---

## 10. Final Architecture Summary

### Current Architecture
The CyberWise IE / Hotel ERP Backend is an enterprise-grade **Modular Monolith** built on **NestJS 10**, **Fastify 4**, **Prisma ORM 5.14**, and **PostgreSQL 16**. It incorporates comprehensive domain encapsulation across 50 functional modules, multi-level authorization guards, and robust defensive security practices.

### Strengths
1. **High-Performance HTTP Core**: The Fastify adapter delivers significantly higher throughput and lower request latency than standard Express implementations.
2. **Resilient Degradation**: Redis integration gracefully falls back to direct database queries if the cache cluster is temporarily unavailable, preventing system outages.
3. **Enterprise Defense in Depth**: Enforces rate limiting, JWT authentication, RBAC, Redis-cached granular permissions, geofencing, GPS accuracy verification, and device anti-fraud telemetry cleansing.
4. **Clean Domain Boundaries**: 50 clearly separated modules with dedicated DTO validation, service business logic, and repository data abstraction.
5. **Comprehensive Automated Test Coverage**: 49 test suites with 435 unit and integration tests passing with 0 errors.

### Weaknesses
1. **Local Disk Attachment Storage**: [StorageService](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/storage/storage.service.ts) currently writes file uploads to the local filesystem (`./uploads`), which requires migration to shared cloud object storage before running multiple concurrent backend instances.
2. **In-Process Scheduled Jobs**: [SchedulerService](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/scheduler/scheduler.service.ts) uses Node.js timers within the application process. Scaling horizontally requires distributed locking to prevent duplicate job execution.
3. **Single-Node Socket.IO Tracking**: [RealTimeGateway](file:///c:/flutter%20pro/Employee_jops/backend/src/modules/realtime/realtime.gateway.ts) maintains socket connections in local process memory, necessitating a Redis adapter for multi-instance deployments.

### Bottlenecks
1. **Interactive Database Transactions**: High-concurrency operations (such as peak check-in windows) hold PostgreSQL connections across multi-step transactions, making connection pooling a primary bottleneck under heavy load.
2. **High-Volume Audit Logging**: Because every authenticated action creates an audit log entry, the `AuditLog` table will expand rapidly, requiring proactive table partitioning.

### Security Risks
1. **Local Attachment Distribution**: Uploaded files are served directly through Fastify static file serving. Serving untrusted attachments without dedicated CDN domain isolation poses potential XSS/content injection risks if user-uploaded HTML or SVG files bypass MIME checks.
2. **JWT Secret Defaults in Development**: Default secrets exist in the fallback configuration (`default_secret`). Strict environment variable enforcement in production is essential.

### Performance Risks
1. **Memory Pressure from Large Uploads**: Decoding 10MB base64 payloads directly into in-memory buffers can create heap spikes under simultaneous multi-user upload scenarios.
2. **Complex Joins on Heavy Reporting Queries**: Analytical endpoints that aggregate across multiple large tables (payroll, executive dashboards) can cause database strain during peak operational hours.

### Scaling Risks
- Attempting to scale the backend horizontally across multiple container instances without first implementing an external Redis WebSocket adapter, S3-compatible cloud storage, and PgBouncer connection pooling will result in split-brain presence tracking and missing file uploads.

### Recommended Architectural Improvements
1. **Transition to S3/Cloud Storage**: Update `StorageService` to stream uploads directly to AWS S3, Google Cloud Storage, or MinIO.
2. **Implement PgBouncer**: Deploy PgBouncer in front of PostgreSQL to pool connections effectively and accommodate higher concurrent client volumes.
3. **Deploy Socket.IO Redis Adapter**: Configure `@socket.io/redis-adapter` in `RealTimeModule` to enable seamless WebSocket communication across multiple load-balanced backend containers.
4. **Implement PostgreSQL Table Partitioning**: Partition the `AuditLog` and `AttendanceEvent` tables by date range to maintain fast queries as data volume grows.
5. **Extract Scheduled Workers**: Separate recurring cron jobs into an independent worker process or container to keep the core API containers focused exclusively on HTTP and WebSocket traffic.
