# CyberWise IE — Production Security & Operations Runbook

## 1. Authentication & Session Security
- **Access Tokens**: Short-lived JWTs (15 minutes expiry) signed using HMAC-SHA256 with cryptographically random secrets (min 256 bits).
- **Refresh Tokens**: Opaque 40-byte random tokens stored in PostgreSQL as SHA-256 hashes with an absolute 7-day TTL.
- **Rotation & Replay Detection**: Every refresh token usage rotates the token pair and invalidates the previous token. Presenting an already-revoked refresh token triggers an active session purge, revoking all active sessions for that user and logging an audit event.
- **Password Protection**: Hashed using Argon2id with memory-hard parameters.

---

## 2. Authorization & RBAC Boundaries
- **Authoritative Enforcement**: Backend `JwtAuthGuard` and `RolesGuard` act as the authoritative security boundary.
- **Role Hierarchy**:
  - `SUPER_ADMIN`: Full system configuration, audit review, and user management.
  - `HR_ADMIN` / `HR_MANAGER`: Employee lifecycle, payroll, attendance, shift schedules, and request approvals.
  - `SUPERVISOR`: Team attendance logs and request escalations.
  - `EMPLOYEE`: Personal check-in/out, self-service leave requests, salary advances, and individual payslips.
- **IDOR Protection**: All resource-level endpoints verify either HR administrative privileges or strict object ownership (`currentUser.employeeProfileId === resource.employeeId`).

---

## 3. Attendance, Geofencing & Fraud Prevention
- **Calculations**: Haversine distance from branch GPS coordinates and working duration calculations are strictly computed server-side.
- **Accuracy Safeguards**: Device GPS accuracy is bounded (configurable via `ATTENDANCE_MAX_GPS_ACCURACY_METERS`, default $\le 50$ meters).
- **Telemetry Sanitization**: Raw biometric templates or device credentials are scrubbed from telemetry storage before persisting to audit tables.

---

## 4. Backup & Disaster Recovery Runbook
### PostgreSQL Backup Strategy
- **Daily Automated Snapshots**:
  ```bash
  pg_dump -h $DB_HOST -U $DB_USER -d cyberwise_db -F c -b -v -f "/backups/cyberwise_$(date +%Y%m%d_%H%M%S).dump"
  ```
- **Retention**: 30 daily snapshots, 12 monthly archives in encrypted object storage (e.g. AWS S3 Glacier or Google Cloud Storage).
- **Restore Verification Procedure**:
  ```bash
  pg_restore -h $DB_HOST -U $DB_USER -d cyberwise_db_recovery -v "/backups/cyberwise_20260820.dump"
  ```

### Redis Recovery Strategy
- Redis operates with **AOF (Append Only File)** enabled (`appendonly yes`) + periodic RDB snapshots.
- In the event of cold restarts, Redis rehydrates rate limit counters and session tokens from disk.

---

## 5. Security Incident Response Protocol
| Incident Type | Detection Trigger | Containment & Remediation Step |
| :--- | :--- | :--- |
| **Token Compromise / Replay** | Revoked refresh token presented | Auto-revocation of all tokens for user. Force password reset. |
| **Suspected Data Breach** | Anomalous mass exports in audit logs | Immediately rotate `JWT_ACCESS_SECRET` and database credentials. |
| **GPS Spoofing / Mock Location** | Suspicious telemetry flags | Flag attendance record as `isSuspicious=true`; trigger manual HR review. |
| **DDoS / Brute-Force** | Rate limit threshold violations (HTTP 429) | Upstream firewall / Cloudflare IP throttling. |
