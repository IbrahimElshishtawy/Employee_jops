# Employee Mobile App — Missing Requirements
## Master Architectural, Technical, and Integration Specification for Production Readiness

> **Project:** CyberWise Hotel ERP & Workforce Management System — Employee Mobile Application  
> **Mobile Codebase Path:** `C:\flutter pro\Employee_jops\employee_setup`  
> **Backend Codebase Path:** `C:\flutter pro\Employee_jops\backend`  
> **Authoritative API Contract:** `C:\flutter pro\Employee_jops\employee_setup\EMPLOYEE_APP_API_ENDPOINTS.md`  
> **Integration Audits:** `EMPLOYEE_APP_API_INTEGRATION_AUDIT.md`, `FINAL_EMPLOYEE_BACKEND_INTEGRATION_AUDIT.md`  
> **Document Purpose:** Single authoritative implementation masterplan documenting everything the Employee Mobile App is missing, incomplete, incorrect, mocked, or needs before becoming a complete, production-ready enterprise mobile app.  
> **Policy:** ZERO CODE MODIFICATIONS in this phase. Audit and specification only.

---

## 📑 Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Current Application Status](#2-current-application-status)
3. [Current Architecture](#3-current-architecture)
4. [Complete Feature Inventory](#4-complete-feature-inventory)
5. [Missing Screens](#5-missing-screens)
6. [Missing User Flows](#6-missing-user-flows)
7. [API Integration Gaps](#7-api-integration-gaps)
8. [Network Layer Gaps](#8-network-layer-gaps)
9. [Authentication & Session Gaps](#9-authentication--session-gaps)
10. [Attendance Gaps](#10-attendance-gaps)
11. [Requests Gaps](#11-requests-gaps)
12. [Tasks Gaps](#12-tasks-gaps)
13. [Notifications Gaps](#13-notifications-gaps)
14. [Messaging Gaps](#14-messaging-gaps)
15. [Payroll Gaps](#15-payroll-gaps)
16. [Reports Gaps](#16-reports-gaps)
17. [Files & Documents Gaps](#17-files--documents-gaps)
18. [Offline & Sync Gaps](#18-offline--sync-gaps)
19. [Security Gaps](#19-security-gaps)
20. [Error Handling Gaps](#20-error-handling-gaps)
21. [UI/UX Gaps](#21-uiux-gaps)
22. [State Management Gaps](#22-state-management-gaps)
23. [Local Storage Gaps](#23-local-storage-gaps)
24. [Performance Gaps](#24-performance-gaps)
25. [Testing Gaps](#25-testing-gaps)
26. [Dependency Gaps](#26-dependency-gaps)
27. [Configuration Gaps](#27-configuration-gaps)
28. [Flutter ↔ Backend Contract Map](#28-flutter--backend-contract-map)
29. [P0 Requirements](#29-p0-requirements)
30. [P1 Requirements](#30-p1-requirements)
31. [P2 Requirements](#31-p2-requirements)
32. [P3 Requirements](#32-p3-requirements)
33. [Master Missing Requirements Matrix](#33-master-missing-requirements-matrix)
34. [Recommended Implementation Order](#34-recommended-implementation-order)
35. [Definition of Done](#35-definition-of-done)
36. [Final Readiness Checklist](#36-final-readiness-checklist)

---

## 1. Executive Summary

A deep code-level audit was conducted across the Flutter Employee App (`employee_setup`) and the enterprise backend (`backend`, NestJS 10 Fastify + Prisma ORM + PostgreSQL + Redis) against the 109 API endpoints documented in `EMPLOYEE_APP_API_ENDPOINTS.md`.

### Key Architectural Findings:

1. **Zero Network Connectivity (Actual HTTP Connectivity = 0%):**  
   The Flutter application currently has **no HTTP client** (`dio` or `http` are completely absent from `pubspec.yaml`). All repositories are hardwired to in-memory `MockDatabase` instances, static seeds (`EmployeeSeed`), or mock data sources (`CommunicationMockDataSource`). Not a single live HTTP request is sent by the application.

2. **Backend is 100% Production Ready:**  
   The NestJS Fastify backend has implemented, documented, and tested all **109 endpoints** required by the employee application across 24 modules, with Argon2id hashing, RFC 6750 Bearer JWT tokens, role-based access control, WebSocket real-time gateways, and Fastify security headers.

3. **Critical Contract Mismatches Will Trigger HTTP 400 In Real Calls:**  
   The backend enforces strict request validation via `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true })`. If Flutter sends extraneous fields (e.g. `clientRequestId`, `employeeId`, `distanceFromWorkplace` in Attendance; or `installments` instead of `requestedInstallments` in Advances), the Fastify server will immediately abort with `400 Bad Request`.

4. **10 Major Entire Modules Completely Missing from Mobile:**  
   Despite being live on the backend, Flutter has zero implementation (no screens, no models, no state, no routes) for:
   - Tasks & Checklists (13 APIs)
   - Shift Handover (5 APIs)
   - Employee Self-Reports (1 API)
   - Incident & Safety Reporting (3 APIs)
   - Maintenance Work Orders (3 APIs)
   - Lost & Found (3 APIs)
   - Performance Goals & Appraisals (4 APIs)
   - Training & Certifications (3 APIs)
   - Active Device Sessions Management (4 APIs)
   - Multi-action Offline Sync Engine (6 APIs)

5. **Security Vulnerabilities Identified in Mobile:**  
   - `SecureSessionStorage` writes sensitive tokens to `FlutterSecureStorage` but concurrently mirrors them in plaintext to `SharedPreferences` (`_prefs?.setString(key, value)`), exposing tokens to extraction on rooted devices.
   - Login screen only implements Google OAuth UI and completely lacks standard enterprise Email/Password login fields, password reset, or change password flows.
   - Push notifications rely on a dummy string generator (`'CW-FCM-TOKEN-${DateTime.now().millisecondsSinceEpoch}'`) without real Firebase Cloud Messaging integration.

---

## 2. Current Application Status

| Area | Current State | Evidence File | Assessment |
|---|---|---|---|
| **Network Client** | Completely absent. Neither `dio` nor `http` in `pubspec.yaml`. | `pubspec.yaml:30-58` | 🔴 Non-functional |
| **Authentication** | Mock token `'cyberwise_jwt_...'` stored locally; Google sign-in UI only; Email/Password missing. | `lib/features/auth/data/datasources/real_auth_datasource.dart:128` | 🔴 Blocked |
| **Attendance** | Local mock verification only (`MockAttendanceRepository`); no REST calls to `/api/v1/attendance/*`. | `lib/features/attendance/data/repositories/mock_attendance_repository.dart:32` | 🔴 Mocked |
| **Requests Hub** | Fractured domain models (`VacationRequest`, `PermissionRequest`, `AdvanceRequest`); separate mock repositories. | `lib/features/requests/presentation/screens/requests_hub_screen.dart` | 🟡 UI Only / Mocked |
| **Payroll & Advances** | Advances UI exists, but sends invalid payload (`installments` vs backend's `requestedInstallments`). Payslip / Salary structure screens missing. | `lib/features/advances/domain/models/advance_request.dart:71` | 🔴 Broken Contract |
| **Tasks & Checklists** | Zero files, zero screens, zero models in Flutter. Backend has 13 active endpoints. | `lib/features/` (folder absent) | 🔴 Missing |
| **Communication / Messaging** | Local mock data source (`CommunicationMockDataSource`). Invented endpoints (`/api/v1/communication/...`) mismatch backend (`/api/v1/messages/...`). | `lib/features/communication/data/datasources/communication_remote_data_source.dart:11-21` | 🔴 Mismatch & Mocked |
| **Push Notifications** | Local notification plugin only. Fake FCM token generator. No FCM background receiver. | `lib/core/services/notification_service.dart:207` | 🔴 Incomplete |
| **Offline Sync** | Only queues attendance items locally in `MockDatabase`; does not communicate with `/api/v1/sync` or `/api/v1/sync/batch`. | `lib/features/attendance/data/api/mock_attendance_api.dart` | 🔴 Ineffective |
| **Storage Security** | Dual-write vulnerability where secure tokens are stored in plaintext `SharedPreferences`. | `lib/core/storage/secure_session_storage.dart:48` | 🔴 Vulnerable |

---

## 3. Current Architecture

```
lib/
├── app/
│   ├── app.dart                    # MaterialApp.router root widget
│   └── app_providers.dart          # Global Riverpod provider composition
├── core/
│   ├── auth/                       # Auth state models
│   ├── constants/                  # Colors, dimensions, app constants
│   ├── errors/                     # App failures and exceptions
│   ├── extensions/                 # Context & string helper extensions
│   ├── localization/               # AR/EN localization delegates & strings
│   ├── mock/                       # In-memory MockDatabase and seeds
│   ├── network/                    # ConnectivityService (NO HTTP client)
│   ├── routing/                    # GoRouter configuration & routes
│   ├── services/                   # DeviceInfo, Biometrics, Notifications
│   ├── storage/                    # SecureSessionStorage, SharedPreferences
│   ├── theme/                      # Light & Dark theme data
│   └── widgets/                    # Reusable buttons, cards, text fields
└── features/
    ├── advances/                   # Advance requests & expense reports (Mocked)
    ├── attendance/                 # Punch verification, geofence, integrity (Mocked)
    ├── auth/                       # Google sign-in UI, splash screen (Mocked)
    ├── communication/              # Department directory, mock chat (Mocked)
    ├── home/                       # Dashboard, punch widget, recent requests
    ├── location_tracking/          # Background location tracking service
    ├── notifications/              # Notifications list & detail screen (Mocked)
    ├── onboarding/                 # 5-step profile completion wizard
    ├── permissions/                # Hourly permission request screens (Mocked)
    ├── profile/                    # Employee profile screen (Mocked)
    ├── requests/                   # Consolidated requests hub tab (Mocked)
    ├── settings/                   # Theme, language, GPS demo simulator
    └── vacations/                  # Vacation request screens (Mocked)
```

### Architectural Deficiencies:
1. **Absence of Remote Data Sources:** With the exception of `real_auth_datasource.dart` (which merely wraps local storage and `google_sign_in`), features do not possess remote data sources that invoke HTTP endpoints.
2. **Missing Dependency Injection for Network Layer:** There is no `dioProvider`, `apiClientProvider`, or authenticated HTTP interceptor in `lib/app/app_providers.dart`.
3. **No Domain-to-DTO Mapping:** Entities in `domain/models` double as serialization objects, causing contract friction with backend DTOs.

---

## 4. Complete Feature Inventory

| Module | Feature Name | Status | Current Files | Missing Components | Required Implementation |
|---|---|---|---|---|---|
| **01. Bootstrap** | Liveness & App Config | `MISSING` | `lib/main.dart` | No bootstrap API call before app render. | Call `GET /api/v1/health/live` and `GET /api/v1/settings/public`. Check mandatory update version. |
| **02. Auth** | Email/Password Login | `MISSING` | `lib/features/auth/presentation/screens/login_screen.dart` | No email or password text controllers, no submit button. | Implement UI form, validation, and call `POST /api/v1/auth/login`. |
| **02. Auth** | Google OAuth Login | `PARTIAL` | `lib/features/auth/data/datasources/real_auth_datasource.dart` | Native token fetched but never sent to backend. | Send `idToken` to `POST /api/v1/auth/google`, receive `{ accessToken, refreshToken, user }`. |
| **02. Auth** | Token Refresh | `MISSING` | `lib/core/storage/secure_session_storage.dart` | No 401 interceptor, no refresh mechanism. | Build Dio interceptor calling `POST /api/v1/auth/refresh` on 401. |
| **02. Auth** | Logout & Token Invalidation | `PARTIAL` | `lib/features/auth/data/datasources/real_auth_datasource.dart:155` | Only clears local storage. | Call `POST /api/v1/auth/logout` with `{ refreshToken }` before clearing local storage. |
| **02. Auth** | Change Password | `MISSING` | None | Screen, form, and repository call missing. | Build screen in settings calling `POST /api/v1/auth/change-password`. |
| **03. Profile** | Profile Onboarding | `PARTIAL` | `lib/features/onboarding/` | 5 screens exist but save only to `MockDatabase`. | Send payload to `PATCH /api/v1/employees/me/profile`. |
| **03. Profile** | Workplace & Geofence Sync | `MOCK` | `lib/core/mock/seeds/workplace_seed.dart` | Hardcoded Cairo HQ coordinates. | Fetch live workplace geofence via `GET /api/v1/employees/me/workplace`. |
| **03. Profile** | Work Schedule & Shift Info | `MOCK` | `lib/core/mock/seeds/schedule_seed.dart` | Hardcoded shift timings. | Fetch live shift info via `GET /api/v1/employees/me/schedule`. |
| **04. Attendance** | Smart Check-In | `BROKEN` | `lib/features/attendance/data/repositories/mock_attendance_repository.dart` | Payload mismatch (`clientRequestId` vs `requestId`); no real HTTP call. | Map to `CheckInDto` and POST to `/api/v1/attendance/check-in`. |
| **04. Attendance** | Smart Check-Out | `BROKEN` | `lib/features/attendance/data/repositories/mock_attendance_repository.dart` | Payload mismatch; no real HTTP call. | Map to `CheckOutDto` and POST to `/api/v1/attendance/check-out`. |
| **04. Attendance** | Today Shift Status | `MOCK` | `lib/features/attendance/presentation/widgets/today_attendance_status_card.dart` | Reads from `MockDatabase`. | Fetch live status via `GET /api/v1/attendance/today`. |
| **04. Attendance** | History & Calendar | `MOCK` | `lib/features/attendance/presentation/screens/attendance_history_screen.dart` | Reads from `MockDatabase`. | Fetch paginated records via `GET /api/v1/attendance/me`. |
| **05. Requests** | Leave Balances | `MOCK` | `lib/features/vacations/presentation/screens/new_vacation_screen.dart` | Hardcoded balance badges (21 days). | Fetch live balances via `GET /api/v1/requests/leave-balances/me`. |
| **05. Requests** | Request Submission | `BROKEN` | `lib/features/vacations/domain/models/vacation_request.dart` | Lowercase enums, extra fields (`daysCount`). | Map to `CreateRequestDto` and POST to `/api/v1/requests`. |
| **05. Requests** | Cancel Pending Request | `MISSING` | `lib/features/requests/presentation/screens/requests_hub_screen.dart` | No cancel button or API handler. | Add cancel action calling `POST /api/v1/requests/:id/cancel`. |
| **06. Payroll** | Salary Structure | `MISSING` | None | No screen or model for salary breakdown. | Build salary profile screen calling `GET /api/v1/payroll/salary/me`. |
| **06. Payroll** | Salary Advance Request | `BROKEN` | `lib/features/advances/domain/models/advance_request.dart:71` | Field name mismatch (`installments` vs `requestedInstallments`). | Fix field name to `requestedInstallments` and POST to `/api/v1/payroll/advances`. |
| **06. Payroll** | Payslips & Records | `MISSING` | None | No screen or repository for monthly payslips. | Build payslip list & detail screen calling `GET /api/v1/payroll/me` and `GET /api/v1/payroll/records/:id`. |
| **07. Tasks** | Task Management (13 APIs) | `MISSING` | None | Entire module missing. | Build task list, task details, checklists, progress updates, comments, and attachments. |
| **08. Notifications** | FCM Push Registration | `MOCK` | `lib/core/services/notification_service.dart:207` | Dummy token generator; no Firebase Core. | Install `firebase_core`, `firebase_messaging`, send real token to `POST /api/v1/notifications/device-token`. |
| **08. Notifications** | Notification Feed & Read State | `MOCK` | `lib/features/notifications/data/repositories/mock_notifications_repository.dart` | In-memory notification list. | Call `GET /api/v1/notifications`, `POST /api/v1/notifications/:id/read`, `POST /api/v1/notifications/read-all`. |
| **09. Announcements** | HR Announcements | `MISSING` | None | No announcements feed or acknowledgment screen. | Connect `GET /api/v1/announcements` and `POST /api/v1/announcements/:id/read`. |
| **10. Messaging** | Chat & Direct Messaging | `BROKEN` | `lib/features/communication/data/datasources/communication_remote_data_source.dart` | Fake routes (`/api/v1/communication/*`); no WebSockets. | Connect to `/api/v1/messages/*` and establish Socket.IO connection to `RealtimeGateway`. |
| **11. Service Requests** | Hotel Service Requests | `PARTIAL` | `lib/features/communication/presentation/screens/my_requests_screen.dart` | Calls mock datasource with non-existent URLs. | Connect to `/api/v1/service-requests/*`. |
| **12. Handover** | Shift Handover (5 APIs) | `MISSING` | None | Entire module missing. | Build handover submission, review, and acknowledgment screens. |
| **13. Reports** | Self Performance Reports | `MISSING` | None | Only expense reports exist in advances feature. | Connect `GET /api/v1/reports/me`. |
| **14. Incidents** | Safety Incident Reports | `MISSING` | None | Entire module missing. | Build incident report form and tracker calling `/api/v1/incidents/*`. |
| **15. Maintenance** | Facility Maintenance | `MISSING` | None | Entire module missing. | Build maintenance ticket creator and list calling `/api/v1/maintenance/requests/*`. |
| **16. Lost & Found** | Lost & Found Logging | `MISSING` | None | Entire module missing. | Build item registration form calling `/api/v1/lost-found/*`. |
| **17. Documents** | Official Employee Documents | `MISSING` | `lib/features/profile/presentation/screens/profile_screen.dart` | UI shows static card; no viewer or downloader. | Connect `GET /api/v1/documents` and document viewer. |
| **18. Performance** | Goals & Reviews (4 APIs) | `MISSING` | None | Entire module missing. | Build goal tracker and review acknowledgment calling `/api/v1/performance/*`. |
| **19. Training** | Courses & Certificates | `MISSING` | None | Entire module missing. | Build training catalog and certificate viewer calling `/api/v1/training/*`. |
| **20. Sessions** | Device Sessions (4 APIs) | `MISSING` | None | Entire module missing. | Build active devices manager in settings calling `/api/v1/sessions/*`. |
| **21. Storage** | Binary / Base64 File Upload | `MISSING` | None | No file picker, no image picker, no multipart upload. | Install `image_picker`, `file_picker`, connect `POST /api/v1/storage/upload`. |
| **22. Offline Sync** | Multi-Action Offline Queue | `MOCK` | `lib/core/mock/mock_database.dart:36` | Local queue in memory only. | Implement SQLite/Hive queue connecting to `POST /api/v1/sync/batch`. |

---

## 5. Missing Screens

The following 18 essential screens are completely missing from the Flutter mobile app:

### Screen 1: Email & Password Login Screen
- **Purpose:** Allow corporate employees without Google OAuth to authenticate with corporate email and password.
- **Access:** Public / Unauthenticated users.
- **Navigation:** App launch route or toggle on `/login`.
- **Required UI:** Corporate logo, Email field (with email validation), Password field (with obscure/reveal toggle), "Remember Me" checkbox, "Forgot Password" link, Submit button, Google Sign-In divider button.
- **States:** Loading spinner on button, Error snackbar/banner, Success transition to Home or Onboarding.
- **API:** `POST /api/v1/auth/login`. Payload: `{ "email": string, "password": string, "deviceId": string, "deviceType": "MOBILE" }`.

### Screen 2: Change / Reset Password Screen
- **Purpose:** Allow logged-in employees to update their account credentials.
- **Access:** Authenticated employees.
- **Navigation:** `SettingsScreen` -> Security -> "Change Password".
- **Required UI:** Current Password, New Password, Confirm New Password, Password strength indicator (min 8 chars, numbers, uppercase).
- **API:** `POST /api/v1/auth/change-password`. Payload: `{ "currentPassword": string, "newPassword": string }`.

### Screen 3: Attendance Details Screen
- **Purpose:** Inspect granular details of a specific day's punch record.
- **Access:** Authenticated employees.
- **Navigation:** Tap on any card in `AttendanceHistoryScreen`.
- **Required UI:** Date, Check-in timestamp, Check-out timestamp, Workplace name, Distance from geofence at punch, Late minutes badge, Total work hours, Overtime hours, Early departure warning, Map view showing punch location.
- **API:** Data fetched from `GET /api/v1/attendance/me` or item extra.

### Screen 4: Tasks List Screen
- **Purpose:** Display all assigned tasks and tasks created by the employee with status filters.
- **Access:** Authenticated employees.
- **Navigation:** Bottom Navigation or Home Dashboard quick action.
- **Required UI:** Search bar, Segmented filter tabs (`TODO`, `ACCEPTED`, `IN_PROGRESS`, `BLOCKED`, `COMPLETED`), Priority badges (`LOW`, `MEDIUM`, `HIGH`, `URGENT`), Due date countdown, Progress bar percentage, Floating Action Button to create task.
- **API:** `GET /api/v1/tasks/my?status=...&priority=...&page=1&limit=20`.

### Screen 5: Task Details & Checklist Screen
- **Purpose:** View full task briefing, check off checklist items, comment, and submit for review.
- **Access:** Task assignee, creator, or supervisor.
- **Navigation:** Tap on item in Tasks List.
- **Required UI:** Title, description, due date, priority, assigned by info, interactive checklist with checkboxes, "Add Checklist Item" input, status transition dropdown/buttons (`Accept`, `Start`, `Block`, `Complete`), comments thread with input box, attachment preview carousel, audit history timeline.
- **APIs:** `GET /api/v1/tasks/:id`, `POST /api/v1/tasks/:id/accept`, `POST /api/v1/tasks/:id/status`, `PATCH /api/v1/tasks/:id/checklist/:itemId`, `POST /api/v1/tasks/:id/comments`, `POST /api/v1/tasks/:id/attachments`.

### Screen 6: Salary Structure & Compensation Screen
- **Purpose:** Provide transparent view of the employee's approved wage structure.
- **Access:** Authenticated employee.
- **Navigation:** Profile -> Financials -> "Salary Structure".
- **Required UI:** Basic salary, Housing allowance, Transport allowance, Fixed other allowances, Gross salary summary card, Currency code, Effective start date.
- **API:** `GET /api/v1/payroll/salary/me`.

### Screen 7: Monthly Payslips (Payroll Records) Screen
- **Purpose:** View historical monthly payslips and payment confirmations.
- **Access:** Authenticated employee.
- **Navigation:** Profile -> Financials -> "Payslips Archive".
- **Required UI:** Year/Month selector, List of monthly payroll cards with Net Salary, Payment status badge (`PAID`, `PENDING`), Download PDF Payslip button.
- **API:** `GET /api/v1/payroll/me?year=2026`.

### Screen 8: Payslip Itemized Details Screen
- **Purpose:** Detailed inspection of gross earnings, deductions, overtime, advances subtracted, and net amount.
- **Access:** Authenticated employee.
- **Navigation:** Tap on item in Payslips Screen.
- **Required UI:** Pay period header, Gross salary breakdown, Additions (Overtime hours * rate, Bonuses), Deductions (GOSI/Social insurance, Late penalties, Advance installment deductions), Final Net Payable, Disbursed bank details.
- **API:** `GET /api/v1/payroll/records/:id`.

### Screen 9: HR Announcements Feed Screen
- **Purpose:** Read executive and departmental announcements and confirm receipt.
- **Access:** Authenticated employees.
- **Navigation:** Home screen bell/announcements pill or Navigation Drawer.
- **Required UI:** Pinned urgent announcement banner, List of announcements with priority tags (`URGENT`, `NORMAL`), published timestamp, author name, unread indicator dot, "Acknowledge / Mark as Read" button.
- **APIs:** `GET /api/v1/announcements`, `POST /api/v1/announcements/:id/read`.

### Screen 10: Shift Handover List Screen
- **Purpose:** Review ongoing shift handovers between incoming and outgoing shifts.
- **Access:** Department operational staff.
- **Navigation:** Home -> Operations -> "Shift Handover".
- **Required UI:** Active shift indicator, Handover cards showing departing employee, receiving employee, pending action item count, acknowledgment status (`PENDING`, `ACKNOWLEDGED`).
- **API:** `GET /api/v1/handover`.

### Screen 11: Create Shift Handover Screen
- **Purpose:** Document incomplete duties, room status, VIP arrivals, and equipment notes before punching out.
- **Access:** Department staff ending shift.
- **Navigation:** Shift Handover List -> "+" Button.
- **Required UI:** Target shift selector, Incoming colleague picker, Rich text summary note, Dynamic list of pending items with priority tags, Photo attachment picker, "Submit Handover" button.
- **API:** `POST /api/v1/handover`.

### Screen 12: Employee Self-Performance Reports Screen
- **Purpose:** View individual key performance indicators (KPIs), attendance consistency, and work hours.
- **Access:** Authenticated employee.
- **Navigation:** Profile -> "Performance & Attendance Stats".
- **Required UI:** Monthly compliance gauge (e.g. 98% attendance), Total working days, On-time punch count, Late punch count, Total approved leaves, Overtime hours graph, Task completion rate percentage.
- **API:** `GET /api/v1/reports/me?month=...&year=...`.

### Screen 13: Incident & Safety Reporting Screen
- **Purpose:** Immediately report physical damage, workplace hazards, medical incidents, or security breaches.
- **Access:** Authenticated employees.
- **Navigation:** Home -> Safety & Support -> "Report Incident".
- **Required UI:** Incident category picker (`SECURITY`, `HEALTH_SAFETY`, `PROPERTY_DAMAGE`), Location picker (hotel floor/room/area), Severity level (`LOW`, `MEDIUM`, `CRITICAL`), Description text field, Multi-image camera attachment picker, Submit button.
- **API:** `POST /api/v1/incidents`.

### Screen 14: Facility Maintenance Request Screen
- **Purpose:** Report broken hotel equipment, electrical faults, plumbing issues, or HVAC failure.
- **Access:** Authenticated employees.
- **Navigation:** Home -> Operations -> "Maintenance Request".
- **Required UI:** Asset tag / room number field, Problem category (`ELECTRICAL`, `PLUMBING`, `HVAC`, `CARPENTRY`), Priority picker, Photo proof upload, Description, Work order tracker.
- **API:** `POST /api/v1/maintenance/requests`.

### Screen 15: Lost & Found Registration Screen
- **Purpose:** Log guest items found in rooms, corridors, or restaurants.
- **Access:** Housekeeping, front office, and hotel staff.
- **Navigation:** Home -> Hotel Operations -> "Lost & Found".
- **Required UI:** Item title, Found location/room, Finding date & time, Custody safe reference, Finder employee badge, Photo upload, Status tracker (`IN_SAFE`, `RETURNED_TO_GUEST`).
- **API:** `POST /api/v1/lost-found`.

### Screen 16: Official Documents & Contracts Screen
- **Purpose:** Access official company documents, signed employment contracts, health certificates, and ID cards.
- **Access:** Authenticated employee.
- **Navigation:** Profile -> "Documents & Contracts".
- **Required UI:** Document categories (Contract, ID, Medical, Policy), Expiration warning badges, In-app PDF previewer, Secure download button.
- **API:** `GET /api/v1/documents` and `GET /api/v1/documents/:id`.

### Screen 17: Performance Goals & Appraisals Screen
- **Purpose:** Track annual objectives (KPIs), progress percentages, and review supervisor feedback.
- **Access:** Authenticated employee.
- **Navigation:** Profile -> "Goals & Reviews".
- **Required UI:** Active goals cards with progress sliders (0-100%), Due dates, Target metrics, Annual review score card with supervisor notes, "Acknowledge Review" signature/button.
- **APIs:** `GET /api/v1/performance/goals`, `PATCH /api/v1/performance/goals/:id/progress`, `GET /api/v1/performance/reviews`, `POST /api/v1/performance/reviews/:id/acknowledge`.

### Screen 18: Active Device Sessions & Security Screen
- **Purpose:** View all phones, tablets, or browsers currently logged into the employee's account and revoke unauthorized sessions remotely.
- **Access:** Authenticated employee.
- **Navigation:** Settings -> Security -> "Active Devices".
- **Required UI:** "Current Device" badge, List of other active sessions with Device Name, OS version, IP address, Last active time, "Revoke Device" button, "Terminate All Other Sessions" button.
- **APIs:** `GET /api/v1/sessions/my-devices`, `DELETE /api/v1/sessions/:id`, `DELETE /api/v1/sessions/other/:currentSessionId`.

---

## 6. Missing User Flows

### Workflow 1: Production Authentication & Session Restoration
```
[App Launch]
       │
       ▼
[Check Local Secure Storage] ──▶ No Session ──▶ [Login Screen]
       │                                              │ (Submit Email/Pass or Google)
       ▼ Valid Session Tokens Found                   ▼
[Decode & Check Access Token Expiry]            [POST /api/v1/auth/login or /google]
       │                                              │
       ├─▶ Token Valid ─────────┐                     ▼
       │                        │               [Receive Tokens & User Info]
       ▼ Token Expired          │                     │
[POST /api/v1/auth/refresh]     │                     ▼
       │                        │               [Store in Secure Hardware Storage]
       ├─▶ 200 OK (New Token) ──┤                     │
       │                        │                     ▼
       ▼ 401 Unauthorized       │               [Check isOnboarded Flag]
[Clear Storage & Go to Login]   │                     │
                                │                     ├─▶ false ──▶ [Onboarding Wizard]
                                ▼                     │
                        [GET /api/v1/employees/me]    └─▶ true  ──▶ [Home Dashboard]
                                │
                                ▼
                        [Populate User State & Enter App]
```

### Workflow 2: Enterprise Smart Punch (Check-In) Flow
```
[User Taps Check-In]
       │
       ▼
[Check GPS Service & Permission] ──▶ Disabled/Denied ──▶ [Show Permission Dialog]
       │
       ▼
[Acquire High-Accuracy Position]
       │
       ▼
[Run Anti-Fraud & Integrity Checks]
       │  ├─ Mock Location Provider Active?
       │  ├─ VPN Active?
       │  └─ Root / Jailbreak Detected?
       │
       ▼ Any Flag Triggered?
       ├─▶ Yes ──▶ [Block Punch & Show Security Violation Warning]
       │
       ▼ No Flags
[Check Workplace Geofence Distance]
       │
       ▼ Distance > Allowed Radius?
       ├─▶ Yes ──▶ [Display Warning & Require Geofence Exception Approval]
       │
       ▼ Within Radius
[Invoke Local Biometric Auth (Fingerprint / Face ID)]
       │
       ▼ Biometric Failed / Cancelled?
       ├─▶ Yes ──▶ [Abort Punch]
       │
       ▼ Biometric Passed
[Check Network Connectivity]
       │
       ├─▶ Offline ──▶ [Queue in Local SQLite/Hive Queue with clientRequestId]
       │                     │
       │                     ▼
       │               [Show "Recorded Offline — Pending Sync" Banner]
       │
       ▼ Online
[POST /api/v1/attendance/check-in]
       │ Payload: { latitude, longitude, accuracy, requestId, method: "GPS", biometricVerified: true }
       │
       ├─▶ 201 Created ──▶ [Update Home Attendance Card, Start Timer, Show Success Audio/Haptic]
       │
       └─▶ 400/409/500 ──▶ [Parse Structured API Error & Display Actionable Feedback]
```

### Workflow 3: Unified Request Submission & Approval Lifecycle
```
[Select Request Type (e.g. Annual Leave, Permission, Advance)]
       │
       ▼
[Fetch Live Prerequisite Data]
       ├─ If Leave: GET /api/v1/requests/leave-balances/me
       ├─ If Advance: GET /api/v1/payroll/salary/me (Validate max allowable advance)
       └─ If Permission: GET /api/v1/employees/me/schedule (Validate shift hours)
       │
       ▼
[Fill Request Form & Pick Attachments]
       │
       ▼ Has Attachment?
       ├─▶ Yes ──▶ [POST /api/v1/storage/upload] ──▶ [Obtain attachmentUrl]
       │
       ▼
[Submit Request: POST /api/v1/requests or POST /api/v1/payroll/advances]
       │ Payload includes idempotencyKey (UUIDv4)
       │
       ▼ 201 Created
[Invalidate Requests Provider Cache]
       │
       ▼
[Navigate to Requests Hub & Trigger Local Confirmation Notification]
       │
       ▼ If User Decides to Revoke Before HR Action
[POST /api/v1/requests/:id/cancel] ──▶ [Restore Balances & Mark Cancelled]
```

### Workflow 4: Real-time Incident / Work Order Escalation
```
[Staff Encounters Emergency / Maintenance Issue]
       │
       ▼
[Open Quick Incident Camera Form]
       │
       ▼
[Capture Photo & Auto-tag Current GPS / Floor Location]
       │
       ▼
[POST /api/v1/storage/upload (Upload Photo Base64/Multipart)]
       │
       ▼
[POST /api/v1/incidents or POST /api/v1/maintenance/requests]
       │
       ▼
[Receive Work Order ID & Confirmation]
       │
       ▼
[Socket.IO Gateway Notifies Maintenance Dispatcher in Real-time]
```

---

## 7. API Integration Gaps

The following matrix compares all **109 backend endpoints** from `EMPLOYEE_APP_API_ENDPOINTS.md` with the current Flutter implementation:

| API ID | Backend Method & Route | Flutter Method / Location | Status | Contract Gap & Mobile Need |
|---|---|---|---|---|
| **API-001** | `GET /api/v1/health/live` | None | `MISSING` | Need bootstrap health check before rendering router. |
| **API-002** | `GET /api/v1/settings/public` | None | `MISSING` | Need app config provider to load hotel logo, policies, min version. |
| **API-003** | `POST /api/v1/auth/login` | None | `MISSING` | Need email/password login method in `AuthRepository` & UI text fields. |
| **API-004** | `POST /api/v1/auth/google` | `RealAuthDataSource.signInWithGoogle` | `MISMATCH` | Flutter signs in natively but saves mock session locally without calling backend API. |
| **API-005** | `POST /api/v1/auth/refresh` | None | `MISSING` | Need Dio 401 interceptor with token mutex to refresh expired access tokens. |
| **API-006** | `POST /api/v1/auth/logout` | `RealAuthDataSource.clearSession` | `PARTIAL` | Only clears local storage; must call backend to revoke `refreshToken`. |
| **API-007** | `POST /api/v1/auth/change-password`| None | `MISSING` | Need change password form and repository implementation. |
| **API-008** | `GET /api/v1/auth/me` | None | `MISSING` | Need user session check against server on app launch. |
| **API-009** | `GET /api/v1/employees/me` | None | `MISSING` | Need employee profile remote datasource. Currently reads `EmployeeSeed`. |
| **API-010** | `PATCH /api/v1/employees/me/profile`| None | `MISSING` | Onboarding wizard finishes by writing to `MockDatabase`. Must call backend. |
| **API-011** | `GET /api/v1/employees/me/workplace`| None | `MISSING` | Need live workplace geofence coordinates instead of hardcoded Cairo HQ. |
| **API-012** | `GET /api/v1/employees/me/schedule` | None | `MISSING` | Need live shift schedule sync instead of hardcoded 08:00-16:00 shift. |
| **API-013** | `GET /api/v1/workplaces` | None | `MISSING` | Need hotel branches listing for multi-property employees. |
| **API-014** | `GET /api/v1/workplaces/:id` | None | `MISSING` | Need workplace detail endpoint integration. |
| **API-015** | `GET /api/v1/schedules` | None | `MISSING` | Need shift templates list integration. |
| **API-016** | `GET /api/v1/schedules/:id` | None | `MISSING` | Need shift details integration. |
| **API-017** | `POST /api/v1/attendance/check-in` | `MockAttendanceApi.submitAttendance` | `MISMATCH` | Field names mismatch (`clientRequestId`, `employeeId` vs `requestId`). No HTTP call. |
| **API-018** | `POST /api/v1/attendance/check-out` | `MockAttendanceApi.submitAttendance` | `MISMATCH` | Field names mismatch. No HTTP call. |
| **API-019** | `GET /api/v1/attendance/today` | `MockAttendanceRepository.getTodayStatus`| `MOCK` | Currently returns in-memory state; need remote HTTP fetch. |
| **API-020** | `GET /api/v1/attendance/me` | `MockAttendanceRepository.getHistory` | `MOCK` | Currently filters in-memory list; need paginated remote fetch. |
| **API-021** | `POST /api/v1/requests` | `MockVacationsRepository`, `MockPermissionsRepository` | `MISMATCH` | Fractured repositories; lowercase enums; sends invalid fields (`daysCount`). |
| **API-022** | `GET /api/v1/requests/me` | None | `MISSING` | Unified requests list calls separate mock repos. Need single endpoint call. |
| **API-023** | `GET /api/v1/requests/leave-balances/me` | None | `MISSING` | Vacation screen displays hardcoded balance numbers. Need live balances call. |
| **API-024** | `GET /api/v1/requests/:id` | None | `MISSING` | Request details screen shows mock object. Need live call. |
| **API-025** | `POST /api/v1/requests/:id/cancel` | None | `MISSING` | No cancellation capability in mobile app. |
| **API-026** | `GET /api/v1/payroll/salary/me` | None | `MISSING` | Entire screen and repository method missing. |
| **API-027** | `POST /api/v1/payroll/advances` | `MockAdvancesRepository.createAdvance` | `MISMATCH` | Sends `installments` instead of required `requestedInstallments`. No HTTP call. |
| **API-028** | `GET /api/v1/payroll/advances/me` | `MockAdvancesRepository.getAdvances` | `MISMATCH` | Backend response `installments` is a List; Flutter parses it as `int`. Crashes on live data. |
| **API-029** | `GET /api/v1/payroll/advances/:id` | `MockAdvancesRepository.getAdvanceById`| `MOCK` | Fetches from mock database. Need live endpoint call. |
| **API-030** | `GET /api/v1/payroll/deductions/me` | None | `MISSING` | Deductions and penalties list completely missing from mobile. |
| **API-031** | `GET /api/v1/payroll/me` | None | `MISSING` | Monthly payslip list completely missing from mobile. |
| **API-032** | `GET /api/v1/payroll/records/:id` | None | `MISSING` | Itemized payslip detail screen completely missing from mobile. |
| **API-033 to API-045** | `Tasks Module` (13 APIs) | None | `MISSING` | Entire Tasks module (list, detail, checklists, comments, attachments) missing. |
| **API-046 to API-053** | `Notifications Module` (8 APIs) | `MockNotificationsRepository` | `MOCK` | Dummy push token, no FCM, no remote fetch or read status updates. |
| **API-054 to API-056** | `Announcements Module` (3 APIs) | None | `MISSING` | Entire announcements feed and acknowledgment flow missing. |
| **API-057 to API-064** | `Messages Module` (8 APIs) | `CommunicationRemoteDataSource` | `MISMATCH` | Invented URLs (`/api/v1/communication/*`); backend routes are `/api/v1/messages/*`. |
| **API-065 to API-072** | `Service Requests` (8 APIs) | `CommunicationRemoteDataSource` | `MISMATCH` | Mobile uses fake routes; backend routes are `/api/v1/service-requests/*`. |
| **API-073 to API-077** | `Shift Handover` (5 APIs) | None | `MISSING` | Entire module missing. |
| **API-078** | `GET /api/v1/reports/me` | None | `MISSING` | Self-performance KPI report missing from mobile. |
| **API-079 to API-081** | `Incidents Module` (3 APIs) | None | `MISSING` | Hazard and security incident reporting missing from mobile. |
| **API-082 to API-084** | `Maintenance Module` (3 APIs) | None | `MISSING` | Hotel maintenance request ticketing missing from mobile. |
| **API-085 to API-087** | `Lost & Found Module` (3 APIs) | None | `MISSING` | Hotel lost & found registration missing from mobile. |
| **API-088 to API-089** | `Documents Module` (2 APIs) | None | `MISSING` | Employee contracts and document browser missing from mobile. |
| **API-090 to API-093** | `Performance Module` (4 APIs) | None | `MISSING` | Goal progress tracking and appraisal reviews missing from mobile. |
| **API-094 to API-096** | `Training Module` (3 APIs) | None | `MISSING` | Courses, sessions, and certificates missing from mobile. |
| **API-097 to API-100** | `Sessions Module` (4 APIs) | None | `MISSING` | Active device management and remote logout missing from mobile. |
| **API-101 to API-106** | `Offline Sync` (6 APIs) | None | `MISSING` | Multi-action delta sync, batch queue, and conflict resolution missing. |
| **API-107 to API-108** | `Storage Upload` (2 APIs) | None | `MISSING` | File and image upload client missing from mobile. |
| **API-109** | `GET /api/v1/organization/reporting-tree/:id` | None | `MISSING` | Direct supervisor and reporting tree hierarchy missing from mobile. |

---

## 8. Network Layer Gaps

### Deficiencies in `lib/core/network/`:
1. **HTTP Client Package Missing:** `pubspec.yaml` lacks `dio: ^5.7.0` (or `http`).
2. **Missing Base URL & Environment Configuration:** No `ApiConstants` or `EnvironmentConfig` defining `http://localhost:3000/api/v1` or staging/production base URLs.
3. **No Auth Interceptor:** No interceptor injecting `Authorization: Bearer <accessToken>` into outgoing requests.
4. **No Refresh Token Interceptor:** No automatic handling of `HTTP 401 Unauthorized` to acquire a new token from `/api/v1/auth/refresh` and replay failed requests.
5. **No Error Serialization:** No centralized parsing of backend Fastify validation error objects:
   ```json
   {
     "statusCode": 400,
     "message": ["requestedInstallments must be an integer number"],
     "error": "Bad Request"
   }
   ```
6. **No Request Cancellation:** No `CancelToken` integration when leaving screens or searching.
7. **No Logging Interceptor:** No sanitized HTTP logger for debug builds that redacts passwords and bearer tokens.

---

## 9. Authentication & Session Gaps

### Evidence Analysis:
- `lib/features/auth/presentation/screens/login_screen.dart`: Lines 246–286 only contain `GoogleSignInButton`. Email and password text fields, validation logic, and password visibility toggles are completely absent.
- `lib/features/auth/domain/repositories/auth_repository.dart`: Defines only `signInWithGoogle`, `getCurrentUser`, `updateEmployee`, and `signOut`. No `signInWithEmailAndPassword` method exists.
- `lib/features/auth/data/datasources/real_auth_datasource.dart`: Lines 125–135 write a mock session string `'cyberwise_jwt_${session.sessionId}'` instead of sending Google's `idToken` to `POST /api/v1/auth/google`.
- `lib/core/storage/secure_session_storage.dart`: Dual-writes tokens to `SharedPreferences` in plaintext on line 48, exposing JWT credentials to non-root backup tools or rooted device inspection.

### Required Mobile Authentication Architecture:
1. Implement full Email/Password UI and logic.
2. Send Google `idToken` to `POST /api/v1/auth/google`.
3. Receive real `{ accessToken, refreshToken, user }`.
4. Persist tokens strictly in encrypted hardware storage (`FlutterSecureStorage`).
5. Maintain an in-memory reactive `AuthState` stream consumed by `GoRouter` redirect guards.

---

## 10. Attendance Gaps

### Evidence Analysis:
- `lib/features/attendance/domain/models/attendance_api_contracts.dart:27-58`:
  ```dart
  class AttendanceSubmissionRequest {
    final String clientRequestId;
    final String employeeId;
    final AttendanceType attendanceType;
    final double latitude;
    final double longitude;
    final double accuracy;
    final DateTime clientTimestamp;
    final String workplaceId;
    final double distanceFromWorkplace;
    final bool biometricVerified;
    ...
  }
  ```
- Backend `CheckInDto` (`backend/src/modules/attendance/dto/check-in.dto.ts`):
  ```typescript
  export class CheckInDto {
    latitude: number;
    longitude: number;
    accuracy: number;
    requestId: string;
    method: 'GPS' | 'BEACON' | 'WIFI' | 'MANUAL';
    biometricVerified: boolean;
    isMockLocation?: boolean;
    isVpn?: boolean;
    isJailbroken?: boolean;
    wifiBssid?: string;
    notes?: string;
  }
  ```

### Critical Mismatches:
1. **Extraneous Fields Will Crash Call:** Sending `clientRequestId`, `employeeId`, `attendanceType`, or `distanceFromWorkplace` causes Fastify's `forbidNonWhitelisted: true` to reject the punch with `400 Bad Request`.
2. **Missing `requestId` Field:** Backend expects `requestId` (UUIDv4) for idempotency; Flutter sends `clientRequestId`.
3. **Missing `method` Field:** Backend requires `method` (enum string `"GPS"`).
4. **No Real Check-Out DTO:** Check-out needs `CheckOutDto` with `{ latitude, longitude, accuracy, requestId, method, biometricVerified }`.
5. **No History Filtering:** Flutter's `AttendanceHistoryScreen` does not support `month` and `year` query parameters to fetch server records.

---

## 11. Requests Gaps

### Evidence Analysis:
- `lib/features/vacations/domain/models/vacation_request.dart`:
  - Uses `VacationType { annual, sick, casual, unpaid }` instead of backend Prisma enums: `ANNUAL_LEAVE`, `SICK_LEAVE`, `UNPAID_LEAVE`, `EMERGENCY_LEAVE`.
  - Serializes `fromDate` and `toDate` as full ISO timestamps instead of `startDate: "YYYY-MM-DD"` and `endDate: "YYYY-MM-DD"`.
  - Serializes `daysCount`, which backend calculates server-side and forbids on input.
  - Serializes `employeeId`, which is extracted from the JWT token.
- `lib/features/permissions/domain/models/permission_request.dart`:
  - Fractured into a separate entity rather than mapping to the backend's unified `POST /api/v1/requests` with `type: "PERMISSION"`, `startTime`, and `endTime`.
- Absence of `leave-balances/me`:
  - `NewVacationScreen` displays hardcoded badges (21 days) instead of calling `GET /api/v1/requests/leave-balances/me`.

---

## 12. Tasks Gaps

### Status: 100% Missing in Flutter

Backend provides 13 fully functional endpoints for employee tasks and checklists:
- `GET /api/v1/tasks/my`
- `GET /api/v1/tasks/:id`
- `PATCH /api/v1/tasks/:id`
- `POST /api/v1/tasks/:id/accept`
- `POST /api/v1/tasks/:id/status`
- `POST /api/v1/tasks/:id/checklist`
- `PATCH /api/v1/tasks/:id/checklist/:itemId`
- `DELETE /api/v1/tasks/:id/checklist/:itemId`
- `POST /api/v1/tasks/:id/comments`
- `GET /api/v1/tasks/:id/comments`
- `POST /api/v1/tasks/:id/attachments`
- `GET /api/v1/tasks/:id/attachments`
- `GET /api/v1/tasks/:id/history`

### Required Mobile Additions:
1. Create `lib/features/tasks/` folder structure (domain, data, presentation).
2. Domain models: `TaskModel`, `TaskChecklistItem`, `TaskComment`, `TaskAttachment`.
3. Remote data source and repository connecting all 13 endpoints.
4. Riverpod providers: `tasksListProvider`, `taskDetailsProvider`.
5. Screens: `TasksListScreen`, `TaskDetailsScreen`, `CreateTaskScreen`.
6. Add route to `app_router.dart` and entry point on `HomeScreen`.

---

## 13. Notifications Gaps

### Evidence Analysis:
- `lib/core/services/notification_service.dart:207`:
  ```dart
  Future<String> getDevicePushToken() async {
    if (_cachedPushToken != null) return _cachedPushToken!;
    final token = 'CW-FCM-TOKEN-${DateTime.now().millisecondsSinceEpoch}';
    _cachedPushToken = token;
    return token;
  }
  ```
- `pubspec.yaml` lacks `firebase_core` and `firebase_messaging`.
- No call is made to `POST /api/v1/notifications/device-token` or `DELETE /api/v1/notifications/device-token/:fcmToken`.
- `lib/features/notifications/data/repositories/mock_notifications_repository.dart` maintains notifications in local RAM.

### Required Implementation:
1. Add `firebase_core: ^3.12.1` and `firebase_messaging: ^15.2.4`.
2. Configure Android `google-services.json` and iOS `GoogleService-Info.plist`.
3. On user login, obtain `FirebaseMessaging.instance.getToken()` and call `POST /api/v1/notifications/device-token` with `{ "fcmToken": token, "deviceType": "MOBILE" }`.
4. On logout, call `DELETE /api/v1/notifications/device-token/:fcmToken`.
5. Connect `GET /api/v1/notifications`, `POST /api/v1/notifications/:id/read`, and `POST /api/v1/notifications/read-all`.

---

## 14. Messaging Gaps

### Evidence Analysis:
- `lib/features/communication/data/datasources/communication_remote_data_source.dart:10-21`:
  Invents endpoints such as `GET /api/v1/communication/conversations` and `GET /api/v1/communication/departments`.
- Real backend endpoints are:
  - `POST /api/v1/messages/conversations`
  - `POST /api/v1/messages/groups`
  - `GET /api/v1/messages/conversations`
  - `GET /api/v1/messages/unread-count`
  - `GET /api/v1/messages/conversations/:id`
  - `POST /api/v1/messages/conversations/:id/messages`
  - `POST /api/v1/messages/conversations/:id/read`
  - `DELETE /api/v1/messages/:id`
- No WebSocket client (`socket_io_client`) exists to connect to backend's `RealtimeGateway` for instant message delivery, typing indicators, or read receipts.

---

## 15. Payroll Gaps

### Crucial Field Name Verification: `requestedInstallments` vs `installments`

#### Backend Verification:
- Endpoint: `POST /api/v1/payroll/advances`
- DTO (`RequestAdvanceDto`):
  ```typescript
  export class RequestAdvanceDto {
    @IsNumber()
    @Min(100)
    amount: number;

    @IsInt()
    @Min(1)
    @Max(12)
    requestedInstallments: number; // <-- MUST BE requestedInstallments

    @IsString()
    @IsNotEmpty()
    reason: string;

    @IsOptional()
    @IsString()
    idempotencyKey?: string;
  }
  ```
- Endpoint `GET /api/v1/payroll/advances/me` response:
  ```json
  {
    "data": [
      {
        "id": "adv_uuid_123456",
        "amount": 3000,
        "approvedAmount": 3000,
        "installmentsCount": 3,
        "remainingAmount": 2000,
        "status": "ACTIVE",
        "installments": [ // <-- ARRAY of installment objects, NOT an integer!
          { "month": "2026-08", "amount": 1000, "status": "PAID" },
          { "month": "2026-09", "amount": 1000, "status": "PENDING" }
        ]
      }
    ]
  }
  ```

#### Flutter Code Audit:
- File: `lib/features/advances/domain/models/advance_request.dart:71`:
  ```dart
  Map<String, dynamic> toJson() => {
    ...
    'installments': installments, // <-- BUG: Sends "installments"
  };
  ```
- File: `lib/features/advances/domain/models/advance_request.dart:85`:
  ```dart
  installments: json['installments'] as int? ?? 1, // <-- BUG: Casts Array to int!
  ```

#### Impact & Remedy:
1. **On Submit (`POST`):** Fastify returns `400 Bad Request: property installments should not exist, requestedInstallments should not be empty`.
2. **On Read (`GET`):** Flutter throws runtime `TypeError: List<dynamic> is not a subtype of type int`.
3. **Fix:** Rename serialization field to `requestedInstallments` in request DTO. In response DTO, map integer count from `installmentsCount` and parse the array of installments into `List<AdvanceInstallmentItem>`.

---

## 16. Reports Gaps

- Flutter currently only contains `ExpenseReportScreen` inside `lib/features/advances/`, which handles receipt settlement for financial advances.
- The core self-service employee report API `GET /api/v1/reports/me` (returning attendance percentage, punctuality, late hours, overtime, leave summary) has no presentation screen, provider, or repository in Flutter.

---

## 17. Files & Documents Gaps

1. **No Image / File Picker:** `pubspec.yaml` lacks `image_picker` and `file_picker`.
2. **No Storage API Integration:** Backend provides `POST /api/v1/storage/upload` accepting base64 or multipart files with instant CDN URL generation. Mobile has no remote client for this.
3. **No PDF Viewer:** `pubspec.yaml` lacks `flutter_pdfview` or `open_filex` to render downloaded contracts, pay slips, or policy documents.
4. **No Upload Progress / Cancellation:** No UI or network logic to report upload progress bars or cancel ongoing uploads.

---

## 18. Offline & Sync Gaps

1. **Current Mobile Implementation:** Only queues attendance items inside in-memory `MockDatabase.pendingOfflineSync`. Data is lost on app kill.
2. **Backend Architecture:** Backend provides an enterprise offline sync engine:
   - `POST /api/v1/sync` (single item punch/task update)
   - `POST /api/v1/sync/batch` (batch replay with transaction atomicity)
   - `GET /api/v1/sync/changes?since=timestamp` (delta changes sync)
   - `GET /api/v1/sync/queue` (queue processing inspection)
3. **Missing Mobile Components:**
   - Persistent local database (`hive_flutter` or `sqflite`) for the offline queue.
   - Sync engine background worker that detects connectivity via `connectivity_plus` and flushes pending items using exponential backoff.
   - Conflict resolution handler for punches or tasks modified on another client.

---

## 19. Security Gaps

| Vulnerability ID | Description | Evidence File & Line | Severity | Required Mitigation |
|---|---|---|---|---|
| **SEC-001** | Token mirrored to plaintext `SharedPreferences` | `lib/core/storage/secure_session_storage.dart:48` | 🔴 Critical | Remove `_prefs?.setString(key, value)` for tokens. Keep tokens exclusively in `FlutterSecureStorage`. |
| **SEC-002** | Missing Certificate Pinning | `lib/core/network/` | 🟡 High | Configure `SecurityContext` in Dio with hotel server TLS certificates to prevent MITM attacks. |
| **SEC-003** | Lack of Screen Blur on Backgrounding | `lib/app/app.dart` | 🟡 Medium | Implement `AppLifecycleListener` to blur sensitive employee data (salary, documents) in the app switcher. |
| **SEC-004** | Plaintext PII Caching | `lib/features/auth/data/datasources/real_auth_datasource.dart:130` | 🟡 High | User PII is JSON-stringified into unencrypted `SharedPreferences`. Must be stored encrypted. |

---

## 20. Error Handling Gaps

The mobile app lacks a centralized HTTP error dispatch system. The required error response matrix is:

| HTTP Status | Backend Meaning | Required Mobile Action |
|---|---|---|
| **401 Unauthorized** | Expired or invalid Access Token | Trigger Refresh Token flow. If refresh fails, purge secure storage and redirect to `/login` with an expiration banner. |
| **403 Forbidden** | Role or permission violation | Show an access denied dialog ("Unauthorized action. Contact HR."). Do not crash or retry. |
| **404 Not Found** | Record deleted or not found | Show an empty state card with a "Return to Dashboard" action. |
| **409 Conflict** | Duplicate punch, overlapping leave | Display backend `message` in a non-dismissible error card with instructions. |
| **422 / 400 Validation** | DTO validation constraint failed | Parse backend error array (`message: [...]`) and highlight corresponding input form fields. |
| **429 Too Many Requests** | Rate limit throttled | Show a countdown toast ("Too many attempts. Please wait X seconds.") and disable submit button. |
| **500 / 503 Server Error** | Backend crash or maintenance | Display "System under scheduled maintenance" error page with a manual retry button. |
| **Socket / Timeout** | No internet or server unreachable | Seamlessly switch to offline mode (if supported) or show network retry toast. |

---

## 21. UI/UX Gaps

1. **Absence of Skeleton Loaders:** Most screens only have a basic `CircularProgressIndicator` instead of shimmer skeleton layouts.
2. **Missing Pull-to-Refresh:** `AttendanceHistoryScreen`, `RequestsHubScreen`, and `AdvancesListScreen` lack `RefreshIndicator` widgets.
3. **No Empty States:** Screens render blank views when lists are empty instead of informative empty illustration cards.
4. **Keyboard Inset Padding Issues:** `NewAdvanceScreen` and `NewVacationScreen` can suffer from bottom-sheet overflow when the virtual keyboard appears.
5. **No System Dark Theme Listener:** Dark mode toggle is purely manual and does not auto-sync with system settings.

---

## 22. State Management Gaps

1. **State Mutation via MockDatabase:** UI screens read from and dispatch mutations directly to `mockDatabaseProvider`, bypassing clean architecture boundaries.
2. **Missing State Restoration:** App state is completely reinitialized on process death.
3. **No Optimistic Updates:** State only updates after long simulated delays, lacking optimistic UI updates with rollback capabilities on network failure.
4. **Cache Expiry Invalidation Missing:** Data in providers does not expire or revalidate upon screen focus or push notification trigger.

---

## 23. Local Storage Gaps

| Data Entity | Purpose | Target Storage | Encryption | Expiration / Flush | Clear on Logout? |
|---|---|---|---|---|---|
| `accessToken` | API Authorization | `FlutterSecureStorage` | Hardware Keystore/Keychain | 15 Minutes | Yes |
| `refreshToken` | Token Rotation | `FlutterSecureStorage` | Hardware Keystore/Keychain | 7 Days | Yes |
| `userProfile` | Cached Profile Data | `FlutterSecureStorage` | Hardware Keystore/Keychain | On Profile Update | Yes |
| `workplaceGeofence`| Offline Punch Boundary | Encrypted SharedPreferences | Hardware Key | 24 Hours | Yes |
| `offlinePunchQueue`| Pending Offline Punches| SQLite / Hive | AES-256 Encrypted | On Sync Confirmation| No (Preserve until sync) |
| `appSettings` | Language, Theme | `SharedPreferences` | None | Permanent | No |

---

## 24. Performance Gaps

1. **Unconstrained List Builders:** Several list screens render `Column(children: ...)` inside `SingleChildScrollView` rather than using `ListView.builder`, causing high memory consumption for large datasets.
2. **Absence of Image Caching:** No `cached_network_image` in `pubspec.yaml`; user avatars and attachments are re-downloaded repeatedly.
3. **Over-rebuilding from Root Providers:** Using `ref.watch(mockDatabaseProvider)` in screen builders causes entire pages to rebuild when unrelated mock state changes.

---

## 25. Testing Gaps

1. **Zero Unit Tests for Repositories:** No tests verifying HTTP serialization, DTO mapping, or error code conversion.
2. **Zero Integration Tests:** No tests covering the end-to-end punch flow, login flow, or request creation.
3. **Zero Security Tests:** No tests validating that auth tokens are never stored in plaintext `SharedPreferences`.
4. **Zero Mock Location Tests:** No tests verifying that mock GPS providers and VPN proxies are properly flagged and rejected.

---

## 26. Dependency Gaps

### Packages Needed in `pubspec.yaml`:

```yaml
dependencies:
  # Network & Realtime
  dio: ^5.7.0
  socket_io_client: ^3.0.2

  # Push Notifications & Firebase
  firebase_core: ^3.12.1
  firebase_messaging: ^15.2.4

  # Media, Files & PDF
  image_picker: ^1.1.2
  file_picker: ^8.1.7
  flutter_pdfview: ^1.4.0
  open_filex: ^4.7.0
  cached_network_image: ^3.4.1

  # Local Database for Offline Sync
  hive_flutter: ^1.1.0

dev_dependencies:
  mockito: ^5.4.5
  build_runner: ^2.4.14
```

---

## 27. Configuration Gaps

1. **Environment Variables:** No `.env.development`, `.env.staging`, or `.env.production` files for base URLs, client IDs, and timeouts.
2. **Flavor Configuration:** Missing Android build flavors and iOS schemes (`dev`, `staging`, `prod`).
3. **CodePush & Release Config:** Shorebird code push is included in dependencies but lacks proper release pipeline staging.

---

## 28. Flutter ↔ Backend Contract Map

```
Flutter Screen (Presentation)
      │
      ▼
Riverpod Notifier / StateNotifier (Application)
      │
      ▼
Repository Implementation (Data)
      │
      ▼
Remote Data Source (Network)
      │
      ▼
Dio HTTP Client + Auth Interceptor
      │  [Authorization: Bearer <accessToken>]
      ▼
HTTP Network Transport
      │
      ▼
Fastify Web Server (Backend main.ts)
      │  [ValidationPipe({ whitelist: true, forbidNonWhitelisted: true })]
      ▼
NestJS Controller (e.g. AttendanceController)
      │  [@UseGuards(JwtAuthGuard, RolesGuard)]
      ▼
NestJS Service (e.g. AttendanceService)
      │  [Geofence calculation, business rules, deduplication]
      ▼
Prisma ORM Client
      │
      ▼
PostgreSQL Database + Redis Cache
```

---

## 29. P0 Requirements (Blockers)

- **MOB-001:** Add `dio` and implement complete Network Layer (`ApiClient`, `AuthInterceptor`, 401 token refresh queue, base URL config).
- **MOB-002:** Fix security flaw in `SecureSessionStorage` to prevent plaintext token storage in `SharedPreferences`.
- **MOB-003:** Implement production Email/Password login and connect Google OAuth `idToken` to `POST /api/v1/auth/google`.
- **MOB-004:** Fix `AttendanceSubmissionRequest` DTO contract to match `CheckInDto` and `CheckOutDto` (`requestId`, `method: "GPS"`, remove forbidden fields).
- **MOB-005:** Fix Advance request DTO field name (`requestedInstallments` instead of `installments`) and fix response array parsing.
- **MOB-006:** Integrate real Firebase Cloud Messaging (`firebase_core`, `firebase_messaging`) and register push tokens with backend.

---

## 30. P1 Requirements (Major Production Functionality)

- **MOB-007:** Build complete Tasks & Checklist module (13 APIs, screens, providers, checklist interaction).
- **MOB-008:** Connect unified Requests API (`POST /api/v1/requests`, `GET /api/v1/requests/me`, `GET /api/v1/requests/leave-balances/me`).
- **MOB-009:** Build Salary Structure, Payslips archive, and itemized payslip details screens.
- **MOB-010:** Replace mock communication layer with real Messaging API (`/api/v1/messages/*`) and WebSocket `socket_io_client`.
- **MOB-011:** Connect live Workplace Geofence and Work Schedule sync endpoints.
- **MOB-012:** Implement persistent encrypted offline queue (Hive/SQLite) for attendance punches and tasks.
- **MOB-013:** Implement file upload client (`POST /api/v1/storage/upload`) with image and document pickers.

---

## 31. P2 Requirements (Important Improvements)

- **MOB-014:** Build HR Announcements feed with acknowledgment confirmation.
- **MOB-015:** Build Shift Handover module (5 APIs).
- **MOB-016:** Build Incident & Safety reporting module (3 APIs).
- **MOB-017:** Build Facility Maintenance work orders module (3 APIs).
- **MOB-018:** Build Lost & Found registration module (3 APIs).
- **MOB-019:** Build Performance Goals and Appraisal reviews module (4 APIs).
- **MOB-020:** Build Training catalog and Certificate viewer (3 APIs).
- **MOB-021:** Build Active Device Sessions manager with remote logout capability (4 APIs).
- **MOB-022:** Build Employee Self-Performance Reports screen (`GET /api/v1/reports/me`).

---

## 32. P3 Requirements (Optimizations & Polish)

- **MOB-023:** Add shimmer skeleton loading states to all list views.
- **MOB-024:** Integrate `cached_network_image` across all avatar and attachment views.
- **MOB-025:** Implement pull-to-refresh on all list and details screens.
- **MOB-026:** Implement background app switcher blur for employee privacy protection.
- **MOB-027:** Implement multi-environment flavor build configuration (`dev`, `staging`, `prod`).

---

## 33. Master Missing Requirements Matrix

| ID | Feature | Requirement | Current State | Missing Part | Target Files | API Route | Priority | Dependencies |
|---|---|---|---|---|---|---|---|---|
| **MOB-001** | Network | HTTP Client & Interceptors | None | `dio`, `ApiClient`, 401 refresh | `lib/core/network/` | `/api/v1/auth/refresh` | `P0` | None |
| **MOB-002** | Security | Secure Hardware Storage | Vulnerable | Stop writing tokens to prefs | `lib/core/storage/secure_session_storage.dart` | N/A | `P0` | None |
| **MOB-003** | Auth | Production Login Flows | Mock/UI Only | Email/pass UI, Google token API | `lib/features/auth/` | `/api/v1/auth/login`, `/auth/google` | `P0` | MOB-001, MOB-002 |
| **MOB-004** | Attendance | Check-In/Out Contract Fix | Broken Mismatch | Align with `CheckInDto` | `lib/features/attendance/` | `/api/v1/attendance/check-in`, `/check-out` | `P0` | MOB-001 |
| **MOB-005** | Payroll | Advance Contract Alignment | Broken Mismatch | `requestedInstallments` rename | `lib/features/advances/` | `/api/v1/payroll/advances` | `P0` | MOB-001 |
| **MOB-006** | Notifications| FCM Push Integration | Mock Generator | Real FCM token & registration | `lib/core/services/notification_service.dart` | `/api/v1/notifications/device-token` | `P0` | MOB-001 |
| **MOB-007** | Tasks | Complete Tasks Module | Missing (0%) | 13 APIs, screens, checklists | `lib/features/tasks/` | `/api/v1/tasks/*` | `P1` | MOB-001 |
| **MOB-008** | Requests | Unified Requests API | Fractured Mock | Unified DTO, balances API | `lib/features/requests/` | `/api/v1/requests/*` | `P1` | MOB-001 |
| **MOB-009** | Payroll | Payslips & Salary Structure | Missing (0%) | 3 screens, PDF download | `lib/features/payroll/` | `/api/v1/payroll/*` | `P1` | MOB-001 |
| **MOB-010** | Messaging | Real Messaging & WebSockets | Broken Routes | `/messages/*` routes + Socket.io| `lib/features/communication/` | `/api/v1/messages/*` | `P1` | MOB-001 |
| **MOB-011** | Attendance | Live Workplace & Shift Sync | Hardcoded Mock | Geofence & shift fetch | `lib/features/attendance/` | `/api/v1/employees/me/workplace` | `P1` | MOB-001 |
| **MOB-012** | Offline Sync| Persistent Offline Queue | In-memory only | Hive queue + batch sync | `lib/core/sync/` | `/api/v1/sync/batch` | `P1` | MOB-001 |
| **MOB-013** | Storage | File & Image Upload Client | Missing | Upload client + pickers | `lib/core/storage/` | `/api/v1/storage/upload` | `P1` | MOB-001 |
| **MOB-014** | Announcements| HR Announcements Feed | Missing (0%) | Feed & acknowledgment | `lib/features/announcements/` | `/api/v1/announcements/*` | `P2` | MOB-001 |
| **MOB-015** | Operations | Shift Handover | Missing (0%) | 5 APIs, handover screens | `lib/features/handover/` | `/api/v1/handover/*` | `P2` | MOB-001 |
| **MOB-016** | Operations | Incident & Safety Reports | Missing (0%) | Incident form & tracker | `lib/features/incidents/` | `/api/v1/incidents/*` | `P2` | MOB-013 |
| **MOB-017** | Operations | Maintenance Work Orders | Missing (0%) | Maintenance form & list | `lib/features/maintenance/` | `/api/v1/maintenance/*` | `P2` | MOB-013 |
| **MOB-018** | Operations | Lost & Found Registration | Missing (0%) | Item log & safe tracking | `lib/features/lost_found/` | `/api/v1/lost-found/*` | `P2` | MOB-013 |
| **MOB-019** | HR | Goals & Performance Review | Missing (0%) | KPI slider & review sign-off | `lib/features/performance/` | `/api/v1/performance/*` | `P2` | MOB-001 |
| **MOB-020** | HR | Training & Certificates | Missing (0%) | Catalog & cert viewer | `lib/features/training/` | `/api/v1/training/*` | `P2` | MOB-001 |
| **MOB-021** | Security | Device Sessions Manager | Missing (0%) | Device list & remote kill | `lib/features/settings/` | `/api/v1/sessions/*` | `P2` | MOB-001 |
| **MOB-022** | Reports | Employee Performance Report| Missing (0%) | Self attendance/KPI report | `lib/features/reports/` | `/api/v1/reports/me` | `P2` | MOB-001 |
| **MOB-023** | UI/UX | Shimmer Skeletons | Missing | Skeleton widgets | `lib/core/widgets/` | N/A | `P3` | None |
| **MOB-024** | Performance| Image Caching | Missing | `cached_network_image` | `lib/core/widgets/` | N/A | `P3` | None |
| **MOB-025** | UI/UX | Pull-to-Refresh | Missing | `RefreshIndicator` | Feature presentation screens | N/A | `P3` | None |
| **MOB-026** | Security | App Switcher Privacy Blur | Missing | Background blur listener | `lib/app/app.dart` | N/A | `P3` | None |
| **MOB-027** | Config | Multi-Flavor Configuration | Missing | Build flavors setup | `android/`, `ios/` | N/A | `P3` | None |

---

## 34. Recommended Implementation Order

To maintain clean architectural dependencies and prevent regressions, implement the missing requirements in the following strictly ordered phases:

```
PHASE 1: Project Foundation & Security Hardening
  └── MOB-002: Secure storage remediation (eliminate plaintext SharedPreferences leaks)
  └── Install required packages (dio, socket_io_client, firebase_core, image_picker)

PHASE 2: Network Infrastructure
  └── MOB-001: Dio client, Base URL config, Auth headers, 401 refresh token interceptor, error parser

PHASE 3: Authentication & Session Lifecycle
  └── MOB-003: Email/Password login UI + Google idToken backend exchange + session restoration

PHASE 4: Core Workplace & Profile Synchronization
  └── MOB-011: Workplace geofence coordinates & schedule sync endpoints

PHASE 5: Smart Attendance Contract Alignment
  └── MOB-004: Align check-in & check-out payloads with CheckInDto and CheckOutDto

PHASE 6: Push Notifications & Device Binding
  └── MOB-006: Real Firebase Cloud Messaging setup + token registration endpoints

PHASE 7: Unified Requests & Leave Balances
  └── MOB-008: Connect /api/v1/requests/*, fetch live balances, implement cancel request

PHASE 8: Financials & Payroll Integration
  └── MOB-005: Fix advance request contract (requestedInstallments)
  └── MOB-009: Build Payslip archive and Salary breakdown screens

PHASE 9: Task & Checklist Management
  └── MOB-007: Build complete 13-API Tasks module, checklists, and comments

PHASE 10: Real-time Communication & Messaging
  └── MOB-010: Connect /api/v1/messages/* routes and configure Socket.IO gateway

PHASE 11: File Storage & Attachments
  └── MOB-013: Implement /api/v1/storage/upload client with photo/document picker

PHASE 12: Offline Synchronization Engine
  └── MOB-012: Implement persistent encrypted queue and batch sync background worker

PHASE 13: Operational & Hotel Services
  └── MOB-014 to MOB-018: Handover, Incidents, Maintenance, Lost & Found, Announcements

PHASE 14: HR Development & Self Services
  └── MOB-019 to MOB-022: Goals, Training, Active Sessions, Self-reports

PHASE 15: Polish, Performance & Testing
  └── MOB-023 to MOB-027: Shimmer skeletons, image caching, pull-to-refresh, unit & integration tests
```

---

## 35. Definition of Done

A feature is considered **COMPLETE and PRODUCTION-READY** only when all criteria in its respective checklist are satisfied:

### 1. Authentication (DoD)
- [ ] User can log in with Email & Password.
- [ ] User can log in with Google OAuth (native `idToken` sent to backend).
- [ ] Tokens (`accessToken`, `refreshToken`) stored exclusively in hardware secure storage.
- [ ] 401 interceptor automatically refreshes access token without user disruption.
- [ ] Logout invalidates token on backend and clears local storage.
- [ ] Incomplete profile redirects to onboarding; completed profile redirects to home.

### 2. Attendance (DoD)
- [ ] Check-in sends exact `CheckInDto` (no extra fields, `requestId` present, `method: "GPS"`).
- [ ] Check-out calculates total work duration and updates daily record.
- [ ] Geofence accurately verified against live coordinates from `/api/v1/employees/me/workplace`.
- [ ] Anti-fraud checks (mock location, VPN, root) execute and block illicit punches.
- [ ] Biometric prompt succeeds before punch submission.
- [ ] Offline punches queue securely in local DB and sync automatically when internet returns.
- [ ] History list supports pagination and month/year filtering.

### 3. Requests & Leaves (DoD)
- [ ] Leave balances fetched dynamically from `/api/v1/requests/leave-balances/me`.
- [ ] Submission uses unified `POST /api/v1/requests` with uppercase enums.
- [ ] Attachment uploaded first via `/api/v1/storage/upload` and URL attached to request.
- [ ] Pending requests can be cancelled via `/api/v1/requests/:id/cancel`.
- [ ] Live status (`PENDING`, `APPROVED`, `REJECTED`) reflects immediately in UI.

### 4. Payroll & Advances (DoD)
- [ ] Advance submission sends `requestedInstallments` (1 to 12).
- [ ] Advances list correctly parses array of `installments` without type crash.
- [ ] Salary structure reflects live breakdown from `/api/v1/payroll/salary/me`.
- [ ] Monthly payslips list and itemized record detail screen render accurately.

### 5. Tasks (DoD)
- [ ] Employee can view assigned and created tasks filtered by status and priority.
- [ ] Employee can accept task (`POST /api/v1/tasks/:id/accept`).
- [ ] Checklist items can be toggled in real-time (`PATCH /api/v1/tasks/:id/checklist/:itemId`).
- [ ] Task comments and attachments submit and render cleanly.

---

## 36. Final Readiness Checklist

### Mobile App Readiness Assessment

| Evaluation Domain | Current Status | Notes & Blockers |
|---|---|---|
| **Architecture** | 🟡 Partial | Well-organized Riverpod/GoRouter structure, but lacks HTTP layer and DTO mappers. |
| **UI Design & Polish** | 🟢 Good | Clean Material 3 design, bilingual AR/EN support, responsive layouts. |
| **State Management** | 🟡 Partial | Riverpod implemented, but heavily coupled to mock database. |
| **Network Layer** | 🔴 Incomplete | No HTTP client (`dio` missing), no base URL config, no interceptors. |
| **Authentication** | 🔴 Incomplete | Email/password missing; Google OAuth only runs locally; mock session used. |
| **Session Management** | 🔴 Incomplete | No 401 refresh token interceptor; token stored insecurely in SharedPreferences. |
| **Attendance** | 🔴 Incomplete | Runs entirely on local mock; DTO contract mismatches with backend. |
| **Requests** | 🔴 Incomplete | Fractured models; enums lowercase; live leave balances not fetched. |
| **Tasks** | 🔴 Missing | 100% missing in Flutter (13 backend APIs not integrated). |
| **Notifications** | 🔴 Incomplete | Push notifications use dummy strings; no Firebase Cloud Messaging setup. |
| **Messaging** | 🔴 Broken | Invented routes mismatch backend; no WebSockets for real-time chat. |
| **Payroll** | 🔴 Incomplete | Advances have field mismatch bug; salary and payslip screens missing. |
| **Reports** | 🔴 Missing | Self-performance report endpoint not integrated. |
| **Files & Documents** | 🔴 Incomplete | No upload client; no PDF viewer; no image picker. |
| **Offline Sync** | 🔴 Incomplete | Queue exists only in RAM; no batch sync engine integration. |
| **Security** | 🔴 Insecure | Plaintext token storage; no certificate pinning; no privacy blur. |
| **Testing** | 🔴 Incomplete | Zero repository, integration, or contract unit tests. |
| **Performance** | 🟡 Fair | Needs unconstrained list refactoring and image caching. |

---

### Quantitative Requirements Breakdown

- **P0 Requirements (Critical Blockers):** `6`
- **P1 Requirements (Major Production):** `7`
- **P2 Requirements (Important Features):** `9`
- **P3 Requirements (Optimizations):** `5`
- **Total Master Requirements:** `27`

---

### Final Architectural Verdict

```
               🔴 NOT READY FOR PRODUCTION
(Application is running 100% on mock data with 0% live backend connectivity,
   critical DTO contract mismatches, and 10 completely unbuilt modules.)
```
