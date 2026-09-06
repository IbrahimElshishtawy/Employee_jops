# 🚀 تشغيل Backend واستخدام Postman

أهلاً بيك في الدليل الشامل لتشغيل واختبار الباك إند الخاص بنظام **CyberWise Hotel ERP & Workforce Management** المخصص لإدارة الفنادق والمنتجعات والقوى العاملة.
تم إعداد هذا الدليل بالكامل لمساعدتك في تشغيل السيرفر من الصفر وتجربة الـ **416 endpoint** الحقيقية الموجودة في الكود الفعلي باستخدام Postman بدون أي تعقيد وبدون أي افتراضات.

---

## الخطوة 1 — متطلبات التشغيل (System Prerequisites)

تأكد إن جهازك أو السيرفر متوفر عليه المتطلبات دي قبل ما تبدأ:

- **Node.js**: إصدار `Node.js 18.x` أو `Node.js 20.x LTS` أو أحدث (المشروع متوافق ومبني بـ TypeScript 5).
- **npm**: الإصدار `npm 9+` أو `10+` أو `11+` لإدارة الحزم والـ dependencies.
- **PostgreSQL**: الإصدار `15` (متاح وجاهز عبر `docker-compose.yml` كـ Alpine image على بورت `5432`).
- **Redis**: الإصدار `7` (متاح في `docker-compose.yml` كـ Alpine image على بورت `6379`).
- **Docker & Docker Compose**: لتشغيل قاعدة البيانات وريديس بنقرة واحدة.
- **Prisma ORM**: الإصدار `^5.14.0` (مُثبت ضمن devDependencies لإدارة الـ Schema والـ Migrations).
- **Firebase Admin SDK (FCM)** *(اختياري)*: `FCM_PROJECT_ID`, `FCM_CLIENT_EMAIL`, `FCM_PRIVATE_KEY` لإرسال إشعارات وتنبيهات تطبيق الموبايل.
- **Environment Variables**: ملف `.env` مهيأ بجميع المتغيرات المطلوبة المستخرجة من `.env.example`.

---

## الخطوة 2 — تثبيت Dependencies

افتح التيرمينال داخل مجلد المشروع:
```bash
cd "C:\flutter pro\Employee_jops\backend"
```

ونفّذ أمر التثبيت الرسمي:
```bash
npm install
```
الأمر ده هيثبت كل المكتبات الخاصة بـ NestJS 10 ومحرك Fastify و Prisma ORM وحزم التشفير والأمان.

---

## الخطوة 3 — إعداد Environment Variables

المشروع بيحتوي على ملف نموذجي جاهز باسم `.env.example`. انسخ الملف ده وأنشئ منه ملف `.env` في المسار الرئيسي للباك إند:

```bash
# لو على نظام Windows PowerShell:
Copy-Item .env.example .env

# أو باستخدام CMD / Bash:
cp .env.example .env
```

افتح ملف `.env` وتأكد من القيم الأساسية (ممنوع وضع Secrets حقيقية على مستودعات عامة):

```env
# تكوين السيرفر الأساسي
NODE_ENV=development
PORT=3000
HOST=0.0.0.0
APP_NAME=CyberWise-IE-Backend
API_PREFIX=api/v1

# رابط الاتصال بقاعدة بيانات PostgreSQL
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/cyberwise_db?schema=public"

# خادم Redis للكاشينج والمهام الموزعة
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# مفاتيح تشفير توكنات الأمان (JWT)
JWT_ACCESS_SECRET="YOUR_SUPER_SECURE_JWT_ACCESS_SECRET_KEY"
JWT_ACCESS_EXPIRATION=15m
JWT_REFRESH_SECRET="YOUR_SUPER_SECURE_JWT_REFRESH_SECRET_KEY"
JWT_REFRESH_EXPIRATION=7d

# إعدادات الأمان ومعدل الطلبات
CORS_ORIGINS=*
THROTTLE_TTL=60
THROTTLE_LIMIT=100

# إعدادات Firebase Cloud Messaging (FCM) للإشعارات
FCM_PROJECT_ID=
FCM_CLIENT_EMAIL=
FCM_PRIVATE_KEY=
```

---

## الخطوة 4 — تشغيل PostgreSQL

المشروع جاهز ومجهز بملف `docker-compose.yml` بيشغل PostgreSQL 15:

1. شغّل الحاوية في الخلفية:
```bash
docker-compose up -d postgres
```
2. بيانات قاعدة البيانات الافتراضية من المشروع:
   - **اسم الحاوية**: `cyberwise_postgres`
   - **المستخدم (User)**: `postgres`
   - **كلمة المرور (Password)**: `postgres`
   - **اسم قاعدة البيانات (DB Name)**: `cyberwise_db`
   - **البورت (Port)**: `5432`
3. للتأكد إن قاعدة البيانات شغالة وتستقبل اتصالات:
```bash
docker ps
# أو افحصها مباشرة بالأمر المدمج:
docker exec -it cyberwise_postgres pg_isready -U postgres -d cyberwise_db
```

---

## الخطوة 5 — تشغيل Redis

خادم Redis 7 موجود وجاهز في الـ `docker-compose.yml`:

1. شغّل حاوية Redis:
```bash
docker-compose up -d redis
```
2. بيانات Redis:
   - **اسم الحاوية**: `cyberwise_redis`
   - **البورت (Port)**: `6379`
3. التأكد إنه شغال:
```bash
docker exec -it cyberwise_redis redis-cli ping
# المتوقع يرد: PONG
```
4. **دور Redis في الكود الفعلي للمشروع**:
   - **الكاشينج السريع**: حفظ الاستعلامات المتكررة لتقليل الضغط على قاعدة البيانات (`RedisService`).
   - **القفل الموزع (Distributed Locks)**: منع تكرار تنفيذ الـ Cron Jobs والمهام المجدولة لو السيرفر شغال منه أكتر من نسخة (`DistributedLockService`).
   - **التواصل اللحظي (Realtime Pub/Sub)**: إدارة غرف وتجمعات اتصالات Socket.IO للمحادثات والإشعارات اللحظية (`RealtimeService`).
   - **المرونة العالية (Resilient Degradation)**: كود المشروع مصمم بمرونة فائقة؛ لو Redis مش متاح أو توقف، السيرفر لا يتوقف وبيتحول تلقائياً لـ In-Memory Fallback ويكمل شغل عادي جداً!

---

## الخطوة 6 — Prisma Database (الهيكل والبيانات الأولية)

نفّذ الخطوات دي بالترتيب الدقيق:

### أ) توليد عميل Prisma:
```bash
npm run prisma:generate
```

### ب) تطبيق الـ Migrations:
- **في بيئة التطوير (Development)**:
```bash
npm run prisma:migrate
```
*(أو للمزامنة السريعة للنماذج: `npm run prisma:push`)*

- **في بيئة الإنتاج (Production)**:
```bash
npx prisma migrate deploy
```

> [!WARNING]
> ⚠️ **تحذير هام جداً**: إياك تشغل `npx prisma migrate reset` على سيرفر إنتاج أو قاعدة بيانات فيها شغل حقيقي، لأن الأمر ده بيعمل Drop ومسح كامل لقاعدة البيانات بكل اللي فيها! الأمر ده مسموح بيه فقط في مرحلة التطوير المبدئي لو محتاج تصفر الداتابيز تماماً.

### ج) زراعة البيانات الافتراضية (Seed Database):
لتجهيز حسابات النظام الأساسية والهيكل التنظيمي المعتمد في المشروع، شغّل الأمر:
```bash
npm run prisma:seed
```
الأمر ده هينشئ في قاعدة البيانات تلقائياً:
- المؤسسة الفندقية المركزية: `CyberWise Hospitality & Enterprise Group` (كود: `CW-CORP`).
- الفندق الرئيسي / الفرع: `Grand Nile Headquarters & Resort` (كود: `GNH-HQ`).
- الأقسام الرئيسية (Executive Management, HR, Housekeeping, Front Office).
- حسابات المستخدمين الأساسية للاختبار:
  - **Super Admin**: `admin@example.test` / كلمة المرور: `Test@123456`
  - **HR Manager**: `hr@example.test` / كلمة المرور: `Test@123456`
  - **Active Employee**: `employee.active@example.test` / كلمة المرور: `Test@123456`

---

## الخطوة 7 — تشغيل Backend

شغّل خادم الباك إند بأمر التطوير الرسمي الموجود في `package.json`:

```bash
npm run start:dev
```

معلومات الاتصال بالسيرفر المستخرجة من `src/main.ts`:
- **Port**: `3000`
- **Host**: `0.0.0.0` (أو `localhost`)
- **API Prefix**: `api/v1`
- **Base URL الفعلي**:
  `http://localhost:3000/api/v1`

---

## الخطوة 8 — التأكد أن Backend يعمل

تقدر تتأكد إن السيرفر قيد التشغيل وقاعد البيانات جاهزة فوراً باستخدام Health API:

- **Method**: `GET`
- **URL**: `http://localhost:3000/api/v1/health/live`
- **Expected Response**:
```json
{
  "status": "ok",
  "uptimeSeconds": 14,
  "timestamp": "2026-09-06T14:00:00.000Z"
}
```

أو لفحص تفصيلي للـ Database والميموري:
- **Method**: `GET`
- **URL**: `http://localhost:3000/api/v1/health`
- **Expected Response**:
```json
{
  "status": "ok",
  "info": {
    "database": { "status": "up" },
    "memory_heap": { "status": "up" }
  },
  "error": {},
  "details": {
    "database": { "status": "up" },
    "memory_heap": { "status": "up" }
  }
}
```

---

# 📚 API Documentation (Swagger)

المشروع بيوفر توثيق تفاعلي كامل ومباشر مبني بـ Swagger OpenAPI:

🔗 **رابط Swagger التفاعلي المباشر**:
👉 [http://localhost:3000/api/docs](http://localhost:3000/api/docs)

من خلال الرابط ده تقدر:
- تستعرض الـ 416 endpoint وتفاصيل الـ Request والـ Response DTOs.
- تضغط على زر **Authorize** في أعلى اليمين وتحط الـ Bearer Token لتجربة الـ APIs مباشرة من المتصفح مع حفظ الجلسة (`persistAuthorization: true`).

---

# 📮 Postman Collection

### تحميل Postman Collection

ملفات Postman موجودة فعلياً داخل المجلد الرئيسي للمشروع كالتالي:

- 📄 **ملف الكوليكشن الكاملة (416 APIs)**:
  `CyberWise_Hotel_ERP.postman_collection.json`
- 🌍 **ملف البيئة المحلية (Environment)**:
  `CyberWise_Hotel_ERP.postman_environment.json`

#### خطوات الاستيراد في Postman:
1. افتح برنامج **Postman**.
2. اضغط على زر **Import** في أعلى يسار الشاشة.
3. اختر ملف الكوليكشن: `CyberWise_Hotel_ERP.postman_collection.json`.
4. اضغط **Import** مرة تانية واختر ملف البيئة: `CyberWise_Hotel_ERP.postman_environment.json`.
5. من القائمة المنسدلة للبيئات في أعلى اليمين (Environment Selector)، تأكد من اختيار:
   **CyberWise Hotel ERP — Local Environment**.
6. توجه لمجلد `Authentication` ونفذ طلب تسجيل الدخول أولاً:
   `[AUTH-002] Login user with Email/Password`.
7. بعد نجاح الـ Login، كل التوكنات ومعرفات المستخدمين بتتخزن تلقائياً في متغيرات Postman وتقدر تشغل أي API تاني في الكوليكشن بسلاسة!

---

# 🧪 تشغيل Postman لأول مرة

علشان تختبر النظام لأول مرة بنجاح وبدون أي أخطاء، اتبع الخطوات دي بالترتيب:

1. **شغّل PostgreSQL**: `docker-compose up -d postgres`
2. **شغّل Redis**: `docker-compose up -d redis`
3. **شغّل الباك إند**: `npm run start:dev`
4. **تأكد من الـ Health API**: افتح المتصفح على `http://localhost:3000/api/v1/health/live`
5. **افتح Postman**.
6. **استورد الكوليكشن**: `CyberWise_Hotel_ERP.postman_collection.json`
7. **استورد الـ Environment**: `CyberWise_Hotel_ERP.postman_environment.json`
8. **اختر البيئة**: حدد `CyberWise Hotel ERP — Local Environment` من القائمة في Postman.
9. **نفّذ تسجيل الدخول (Login)**: افتح مجلد `Authentication` واضغط Send على طلب `[AUTH-002] Login user with Email/Password`.
10. **تحقق من حفظ التوكن**: افتح تبويب الـ Environment في Postman هتلاقي قيمة `accessToken` و `refreshToken` و `userId` و `employeeId` اتحدثت تلقائياً من خلال التيست سكريبت المدمج.
11. **اختبر باقي الـ APIs**: جرب باقي الموديولات حسب ترتيب الاعتماديات الموضح بالأسفل.

---

# 🔐 شرح نظام المصادقة (Authentication & Authorization)

النظام بيعتمد على معيار **RFC 6750 Bearer Token** مع تشفير كلمات المرور بأقوى معيار عالمي **Argon2id**:

### 1. مسار تسجيل الدخول (Login Endpoint):
- **Method**: `POST`
- **Path**: `/api/v1/auth/login`
- **الوصول**: عام بدون توكن (Public)
- **Body**:
```json
{
  "email": "admin@example.test",
  "password": "Test@123456"
}
```

### 2. الـ Tokens المرتجعة:
- **Access Token**: توكن بصيغة JWT صالح لمدة **15 دقيقة**، بيحتوي على معرف المستخدم ودوره الوظيفي (`SUPER_ADMIN`, `HR_ADMIN`, `EMPLOYEE`).
- **Refresh Token**: توكن آمن مشفر صالح لمدة **7 أيام** بيستخدم لتجديد الـ Access Token من غير ما تطلب من المستخدم يسجل دخول من جديد.

### 3. تمرير الـ Authorization Header:
جميع الـ APIs المحمية في النظام بتتطلب تمرير الـ Header التالي في كل طلب:
```http
Authorization: Bearer {{accessToken}}
```
> [!TIP]
> 💡 **ميزة كوليكشن Postman المجهزة**: الكوليكشن مضبوطة في جذر المجلد الأساسي على استخدام Bearer Token بقيمة `{{accessToken}}` تلقائياً لكل الطلبات، فمش هتحتاج تضيف الـ Header ده يدوي نهائياً!

### 4. تجديد التوكن (Token Refresh):
- **Method**: `POST`
- **Path**: `/api/v1/auth/refresh`
- **Body**:
```json
{
  "refreshToken": "{{refreshToken}}"
}
```

---

# 🔄 ترتيب اختبار النظام (Chained Execution Order)

علشان تختبر الـ 416 API بدون ما تقابلك مشاكل المفاتيح الأجنبية (Foreign Keys) المفقودة في الداتابيز، الترتيب المنطقي المعتمد على الـ Dependencies الفعلية في الكود هو كالتالي:

1. **المرحلة 1: الصحة والاتصال (Health & Diagnostics)**
   - تشغيل `[HLT-001]` إلى `[HLT-008]` للتأكد من اتصال PostgreSQL و Redis وذاكرة السيرفر.
2. **المرحلة 2: المصادقة والتوكنات (Authentication & Profile)**
   - تسجيل الدخول `[AUTH-002]` والتقاط الـ Access Token تلقائياً.
   - قراءة بيانات البروفايل `[AUTH-006] GET /auth/me`.
   - تجربة تجديد التوكن `[AUTH-003] POST /auth/refresh`.
3. **المرحلة 3: الهيكل التنظيمي والفروع (Organization & Hierarchy)**
   - استعراض المؤسسة المركزية `[ORG-001]`، وفروع الفندق `[ORG-004]`، والأقسام `[ORG-010]`، والمسميات الوظيفية `[ORG-018]`.
4. **المرحلة 4: الأدوار والصلاحيات (Roles & Permissions)**
   - استعراض الأدوار الوظيفية المتاحة في النظام `[ROLE-001]` ومصفوفة الصلاحيات التفصيلية `[PERM-001]`.
5. **المرحلة 5: مواقع العمل والنطاقات الجغرافية (Workplaces & Geofences)**
   - إعداد إحداثيات موقع الفندق ونطاق البصمة الجغرافية (Latitude / Longitude / Radius) `[WKP-001]`.
6. **المرحلة 6: الورديات وجداول العمل (Schedules & Shifts)**
   - استعراض وتعريف ورديات العمل وساعات البداية والنهاية وفترات السماح `[SCH-001]`.
7. **المرحلة 7: الموظفون والتهيئة (Employees & Onboarding)**
   - استعراض دليل الموظفين `[EMP-001]`، وتسكين موظف جديد وربطه بالفرع والقسم ومكان العمل.
8. **المرحلة 8: الحضور والانصراف (Attendance Operations)**
   - محاكاة تسجيل حضور الموظف بالبصمة الجغرافية داخل نطاق الـ Geofence `[ATT-001]`.
   - استعراض شاشة المتابعة الحية لتواجد الموظفين في الفندق `[ATT-004] GET /attendance/live`.
   - تسجيل حركة الانصراف وحساب ساعات العمل الإضافية `[ATT-002]`.
9. **المرحلة 9: طلبات الموظفين والاعتمادات (Requests & Approvals)**
   - تقديم طلب إجازة سنوية أو إذن ساعي `[REQ-001]`.
   - استعراض الطلبات المعلقة واعتمادها رسمياً من قِبل مسؤول الـ HR أو المدير `[APR-001]`.
10. **المرحلة 10: المهام وإدارة العمل (Tasks & Work Management)**
    - إنشاء وتكليف مهمة عمل فندقية وتحديث نسبة إنجازها `[TSK-001]`.
11. **المرحلة 11: طلبات الخدمة وتسليم الورديات (Service Requests & Shift Handover)**
    - تقديم ومتابعة طلبات خدمة الغرف والصيانة للنزلاء `[SRV-001]`.
    - تدوين محضر تسليم واستلام الوردية لضمان استمرارية التشغيل `[HND-001]`.
12. **المرحلة 12: تشغيل الفندق والأصول والصيانة (Hotel Operations & Maintenance)**
    - تسجيل أصول ومعدات الفندق وحساب إهلاكها `[AST-001]`.
    - إصدار ومتابعة أوامر شغل الصيانة (Work Orders) `[MNT-001]`.
    - إصدار وتسليم واسترجاع كروت ومفاتيح الغرف `[KEY-001]`.
    - تسجيل الأمانات والمفقودات `[LNF-001]`، وسجل تصاريح الزوار `[VIS-001]`.
13. **المرحلة 13: سلاسل الإمداد والمخازن (Inventory & Procurement)**
    - إدارة أصناف المخازن والتسويات الجردية `[INV-001]`.
    - تسجيل الموردين وإنشاء أوامر الشراء (Purchase Orders) `[PRC-001]`.
14. **المرحلة 14: المالية والموازنات (Finance & Accounting & Budget)**
    - تسجيل قيود اليومية وفواتير المصروفات ومتابعة الموازنات التقديرية `[FIN-001]`، `[BDG-001]`.
15. **المرحلة 15: مسيرات الرواتب والسلف (Payroll, Advances & Deductions)**
    - احتساب مسير الرواتب الشهري آلياً وخصم السلف والغياب `[PAY-001]`.
    - تقديم واعتماد طلبات السلف المالية على الراتب `[PAY-010]`.
16. **المرحلة 16: الإشعارات والمراسلات (Notifications & Messaging)**
    - اختبار الإشعارات والتنبيهات وربط Firebase FCM `[NOTIF-001]`.
    - المحادثات الفورية الفردية والجماعية `[MSG-001]`.
    - نشر الإعلانات والتعميمات الإدارية `[ANN-001]`.
17. **المرحلة 17: التقارير ولوحة المؤشرات (Reports & BI Dashboard)**
    - استعراض لوحة مؤشرات الأداء التنفيذية (KPIs) `[DSH-001]`.
    - استخراج وتصدير تقارير الحضور والرواتب والعمليات `[REP-001]`.
18. **المرحلة 18: أمان النظام والمزامنة والنسخ الاحتياطي (System, Sync & Backup)**
    - اختبار محرك مزامنة البيانات دون اتصال `[SNC-001]`.
    - فحص سجلات الرقابة والتدقيق الأمني `[AUD-001]`.
    - إجراء وتنزيل نسخة احتياطية كاملة للنظام `[BKP-001]`.

---

# CyberWise Hotel ERP — Complete API Inventory

**Platform**: CyberWise Hospitality & Enterprise Resource Planning Backend  
**Architecture**: NestJS 10 (Fastify Engine), Prisma ORM, PostgreSQL, Redis Cache  
**Base URL**: `http://localhost:3000/api/v1`  
**Total Endpoints Discovered & Verified**: **416**  
**Total Functional Modules**: **48**  
**Authentication Standard**: RFC 6750 Bearer Token (Argon2id password hashing + JWT)  
**Verification Date**: September 2026  

---

## Table of Contents

- [Health (8 APIs)](#health)
- [Authentication (6 APIs)](#authentication)
- [Organization & Hierarchy (27 APIs)](#organization-hierarchy)
- [Roles (8 APIs)](#roles)
- [Permissions (4 APIs)](#permissions)
- [Settings & Feature Flags (7 APIs)](#settings-feature-flags)
- [HR Management (8 APIs)](#hr-management)
- [Recruitment & ATS (24 APIs)](#recruitment-ats)
- [Employee Onboarding (10 APIs)](#employee-onboarding)
- [Employees (9 APIs)](#employees)
- [Workplaces (5 APIs)](#workplaces)
- [Attendance & Workforce Operations (10 APIs)](#attendance-workforce-operations)
- [Workforce Operations & Analytics (8 APIs)](#workforce-operations-analytics)
- [Schedules (5 APIs)](#schedules)
- [Workflows (6 APIs)](#workflows)
- [Approvals (6 APIs)](#approvals)
- [Notifications & In-App Alerts (11 APIs)](#notifications-in-app-alerts)
- [HR Announcements & Broadcasts (6 APIs)](#hr-announcements-broadcasts)
- [Requests (15 APIs)](#requests)
- [Payroll, Salary Advances & Deductions (24 APIs)](#payroll-salary-advances-deductions)
- [Internal Messaging & Conversations (9 APIs)](#internal-messaging-conversations)
- [Reports & Analytics Engine (18 APIs)](#reports-analytics-engine)
- [Audit Logs (1 APIs)](#audit-logs)
- [Tasks & Work Execution (17 APIs)](#tasks-work-execution)
- [Work Management & Approvals (5 APIs)](#work-management-approvals)
- [Service Requests (11 APIs)](#service-requests)
- [Shift Handover (5 APIs)](#shift-handover)
- [Department Operations (3 APIs)](#department-operations)
- [Assets Management (8 APIs)](#assets-management)
- [Maintenance Management (11 APIs)](#maintenance-management)
- [Key & Physical Access Management (6 APIs)](#key-physical-access-management)
- [Inventory & Stores (12 APIs)](#inventory-stores)
- [Procurement & Suppliers (15 APIs)](#procurement-suppliers)
- [Finance & Accounting (13 APIs)](#finance-accounting)
- [Budget Management (5 APIs)](#budget-management)
- [Incident & Safety Management (7 APIs)](#incident-safety-management)
- [Documents Management (5 APIs)](#documents-management)
- [Lost & Found (5 APIs)](#lost-found)
- [Visitor Management (4 APIs)](#visitor-management)
- [Performance Management (9 APIs)](#performance-management)
- [Training & Development (10 APIs)](#training-development)
- [Sessions & Active Devices (4 APIs)](#sessions-active-devices)
- [Integrations & Webhooks (7 APIs)](#integrations-webhooks)
- [Offline Sync Engine (7 APIs)](#offline-sync-engine)
- [Executive Dashboard & BI (1 APIs)](#executive-dashboard-bi)
- [File Storage (3 APIs)](#file-storage)
- [Background Jobs & Scheduler (2 APIs)](#background-jobs-scheduler)
- [Backup & Disaster Recovery (6 APIs)](#backup-disaster-recovery)

---

## Health

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **HLT-001** | `GET` | `/api/v1/health` | Public | Public | System overall health status |
| **HLT-002** | `GET` | `/api/v1/health/live` | Public | Public | Liveness probe (Is process alive?) |
| **HLT-003** | `GET` | `/api/v1/health/ready` | Public | Public | Readiness probe (Can instance accept traffic?) |
| **HLT-004** | `GET` | `/api/v1/health/db` | Public | Public | PostgreSQL Database Connectivity probe |
| **HLT-005** | `GET` | `/api/v1/health/redis` | Public | Public | Redis Cache & Rate Limiting probe |
| **HLT-006** | `GET` | `/api/v1/health/queues` | Public | Public | Offline Sync Queue and Background Workers monitoring (OPS-003) |
| **HLT-007** | `GET` | `/api/v1/health/integrations` | Public | Public | External integrations and webhook channel monitoring (OPS-004) |
| **HLT-008** | `GET` | `/api/v1/health/system` | Public | Public | Holistic system telemetry, CPU, memory, DB, and cache metrics |

### HLT-001 — System overall health status

**بتعمل إيه؟**:
فحص شامل لصحة النظام وأداء السيرفر وقاعدة البيانات والميموري هيب.

**مين يقدر يستخدمها؟**:
متاحة للجميع بدون تسجيل دخول (Public Endpoint)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/health`
- **Controller**: `HealthController -> HealthCheck()`
- **Service Execution**: `health.check()`
- **Authentication**: **Public**
- **Authorized Roles**: `Public`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PrismaConnection`, `RedisCache`

**Purpose & Business Context**:
System overall health status. This endpoint operates with strict transactional integrity under the Health subsystem.

**Headers**:
```http
Content-Type: application/json
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `503 Error`: The Health Check is not successful
- `400 Error`: Validation failure (invalid payload or params)

**Execution Prerequisites & Dependencies**:
- Active System State

---

### HLT-002 — Liveness probe (Is process alive?)

**بتعمل إيه؟**:
فحص حيوية التطبيق (Liveness Probe) للتأكد من أن خادم الباك إند قيد التشغيل ويعمل بدون توقف.

**مين يقدر يستخدمها؟**:
متاحة للجميع بدون تسجيل دخول (Public Endpoint)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/health/live`
- **Controller**: `HealthController -> HealthCheck()`
- **Service Execution**: `health.check()`
- **Authentication**: **Public**
- **Authorized Roles**: `Public`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PrismaConnection`, `RedisCache`

**Purpose & Business Context**:
Liveness probe (Is process alive?). This endpoint operates with strict transactional integrity under the Health subsystem.

**Headers**:
```http
Content-Type: application/json
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)

**Execution Prerequisites & Dependencies**:
- Active System State

---

### HLT-003 — Readiness probe (Can instance accept traffic?)

**بتعمل إيه؟**:
فحص جاهزية التطبيق (Readiness Probe) للتأكد من أن السيرفر جاهز يستقبل ترافيك ومتصل بقاعدة البيانات.

**مين يقدر يستخدمها؟**:
متاحة للجميع بدون تسجيل دخول (Public Endpoint)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/health/ready`
- **Controller**: `HealthController -> HealthCheck()`
- **Service Execution**: `health.check()`
- **Authentication**: **Public**
- **Authorized Roles**: `Public`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PrismaConnection`, `RedisCache`

**Purpose & Business Context**:
Readiness probe (Can instance accept traffic?). This endpoint operates with strict transactional integrity under the Health subsystem.

**Headers**:
```http
Content-Type: application/json
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)

**Execution Prerequisites & Dependencies**:
- Active System State

---

### HLT-004 — PostgreSQL Database Connectivity probe

**بتعمل إيه؟**:
فحص مباشر للاتصال بقاعدة بيانات PostgreSQL للتأكد من استجابتها وسرعة الاستعلام.

**مين يقدر يستخدمها؟**:
متاحة للجميع بدون تسجيل دخول (Public Endpoint)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/health/db`
- **Controller**: `HealthController -> HealthCheck()`
- **Service Execution**: `health.check()`
- **Authentication**: **Public**
- **Authorized Roles**: `Public`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PrismaConnection`, `RedisCache`

**Purpose & Business Context**:
PostgreSQL Database Connectivity probe. This endpoint operates with strict transactional integrity under the Health subsystem.

**Headers**:
```http
Content-Type: application/json
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)

**Execution Prerequisites & Dependencies**:
- Active System State

---

### HLT-005 — Redis Cache & Rate Limiting probe

**بتعمل إيه؟**:
فحص حالة وسرعة استجابة خادم Redis Cache للكاشينج وتوزيع المهام.

**مين يقدر يستخدمها؟**:
متاحة للجميع بدون تسجيل دخول (Public Endpoint)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/health/redis`
- **Controller**: `HealthController -> HealthCheck()`
- **Service Execution**: `health.check()`
- **Authentication**: **Public**
- **Authorized Roles**: `Public`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PrismaConnection`, `RedisCache`

**Purpose & Business Context**:
Redis Cache & Rate Limiting probe. This endpoint operates with strict transactional integrity under the Health subsystem.

**Headers**:
```http
Content-Type: application/json
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)

**Execution Prerequisites & Dependencies**:
- Active System State

---

### HLT-006 — Offline Sync Queue and Background Workers monitoring (OPS-003)

**بتعمل إيه؟**:
فحص شامل لصحة النظام وأداء السيرفر وقاعدة البيانات والميموري هيب.

**مين يقدر يستخدمها؟**:
متاحة للجميع بدون تسجيل دخول (Public Endpoint)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/health/queues`
- **Controller**: `HealthController -> HealthCheck()`
- **Service Execution**: `health.check()`
- **Authentication**: **Public**
- **Authorized Roles**: `Public`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PrismaConnection`, `RedisCache`

**Purpose & Business Context**:
Offline Sync Queue and Background Workers monitoring (OPS-003). This endpoint operates with strict transactional integrity under the Health subsystem.

**Headers**:
```http
Content-Type: application/json
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)

**Execution Prerequisites & Dependencies**:
- Active System State

---

### HLT-007 — External integrations and webhook channel monitoring (OPS-004)

**بتعمل إيه؟**:
فحص حالة الاتصال بجميع واجهات وخدمات التكامل الخارجية (Webhooks/Integrations).

**مين يقدر يستخدمها؟**:
متاحة للجميع بدون تسجيل دخول (Public Endpoint)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/health/integrations`
- **Controller**: `HealthController -> HealthCheck()`
- **Service Execution**: `health.check()`
- **Authentication**: **Public**
- **Authorized Roles**: `Public`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PrismaConnection`, `RedisCache`

**Purpose & Business Context**:
External integrations and webhook channel monitoring (OPS-004). This endpoint operates with strict transactional integrity under the Health subsystem.

**Headers**:
```http
Content-Type: application/json
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)

**Execution Prerequisites & Dependencies**:
- Active System State

---

### HLT-008 — Holistic system telemetry, CPU, memory, DB, and cache metrics

**بتعمل إيه؟**:
فحص شامل لصحة النظام وأداء السيرفر وقاعدة البيانات والميموري هيب.

**مين يقدر يستخدمها؟**:
متاحة للجميع بدون تسجيل دخول (Public Endpoint)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/health/system`
- **Controller**: `HealthController -> HealthCheck()`
- **Service Execution**: `health.check()`
- **Authentication**: **Public**
- **Authorized Roles**: `Public`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PrismaConnection`, `RedisCache`

**Purpose & Business Context**:
Holistic system telemetry, CPU, memory, DB, and cache metrics. This endpoint operates with strict transactional integrity under the Health subsystem.

**Headers**:
```http
Content-Type: application/json
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)

**Execution Prerequisites & Dependencies**:
- Active System State

---

## Authentication

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **AUTH-001** | `POST` | `/api/v1/auth/google` | Public | Public | Employee Google Sign-In with authoritative onboarding state |
| **AUTH-002** | `POST` | `/api/v1/auth/login` | Public | Public | Login user with Email/Password (HR Dashboard / Admin) |
| **AUTH-003** | `POST` | `/api/v1/auth/refresh` | Public | Public | Rotate and refresh JWT access token |
| **AUTH-004** | `POST` | `/api/v1/auth/logout` | Public | Public | Logout and revoke refresh token |
| **AUTH-005** | `POST` | `/api/v1/auth/change-password` | Public | Public | Change password for authenticated user |
| **AUTH-006** | `GET` | `/api/v1/auth/me` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Get current authenticated user & profile status |

### AUTH-001 — Employee Google Sign-In with authoritative onboarding state

**بتعمل إيه؟**:
تسجيل دخول موظف الفندق عبر حساب Google (Google Sign-In) لتطبيق الموبايل، والتحقق من حالة تهيئة حسابه.

**مين يقدر يستخدمها؟**:
متاحة للجميع بدون تسجيل دخول (Public Endpoint)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/auth/google`
- **Controller**: `AuthController -> HttpCode()`
- **Service Execution**: `authService.googleLogin()`
- **Authentication**: **Public**
- **Authorized Roles**: `Public`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `User`, `EmployeeProfile`, `RefreshToken`, `Session`, `AuditLog`

**Purpose & Business Context**:
Employee Google Sign-In with authoritative onboarding state. This endpoint operates with strict transactional integrity under the Authentication subsystem.

**Headers**:
```http
Content-Type: application/json
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "idToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6Ij...google_id_token",
  "deviceId": "c6b8f72a-9e12-4d15-8c01-fbb19d45e0aa"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### AUTH-002 — Login user with Email/Password (HR Dashboard / Admin)

**بتعمل إيه؟**:
تسجيل دخول المستخدم (مدير النظام أو مسؤولي الموارد البشرية) بالبريد الإلكتروني وكلمة المرور، واستخراج Access Token و Refresh Token لتأمين باقي الطلبات.

**مين يقدر يستخدمها؟**:
متاحة للجميع بدون تسجيل دخول (Public Endpoint)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/auth/login`
- **Controller**: `AuthController -> HttpCode()`
- **Service Execution**: `authService.googleLogin()`
- **Authentication**: **Public**
- **Authorized Roles**: `Public`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `User`, `EmployeeProfile`, `RefreshToken`, `Session`, `AuditLog`

**Purpose & Business Context**:
Login user with Email/Password (HR Dashboard / Admin). This endpoint operates with strict transactional integrity under the Authentication subsystem.

**Headers**:
```http
Content-Type: application/json
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "email": "{{adminEmail}}",
  "password": "{{adminPassword}}"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)

**Execution Prerequisites & Dependencies**:
- Active System State

---

### AUTH-003 — Rotate and refresh JWT access token

**بتعمل إيه؟**:
تجديد وتدوير Access Token منتهي الصلاحية باستخدام Refresh Token ساري بدون الحاجة لإعادة تسجيل الدخول.

**مين يقدر يستخدمها؟**:
متاحة للجميع بدون تسجيل دخول (Public Endpoint)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/auth/refresh`
- **Controller**: `AuthController -> HttpCode()`
- **Service Execution**: `authService.googleLogin()`
- **Authentication**: **Public**
- **Authorized Roles**: `Public`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `User`, `EmployeeProfile`, `RefreshToken`, `Session`, `AuditLog`

**Purpose & Business Context**:
Rotate and refresh JWT access token. This endpoint operates with strict transactional integrity under the Authentication subsystem.

**Headers**:
```http
Content-Type: application/json
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "refreshToken": "{{refreshToken}}"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### AUTH-004 — Logout and revoke refresh token

**بتعمل إيه؟**:
تسجيل الخروج من النظام، وإلغاء صلاحية الـ Refresh Token وإنهاء الجلسة النشطة في قاعدة البيانات وريديس.

**مين يقدر يستخدمها؟**:
متاحة للجميع بدون تسجيل دخول (Public Endpoint)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/auth/logout`
- **Controller**: `AuthController -> HttpCode()`
- **Service Execution**: `authService.googleLogin()`
- **Authentication**: **Public**
- **Authorized Roles**: `Public`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `User`, `EmployeeProfile`, `RefreshToken`, `Session`, `AuditLog`

**Purpose & Business Context**:
Logout and revoke refresh token. This endpoint operates with strict transactional integrity under the Authentication subsystem.

**Headers**:
```http
Content-Type: application/json
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "refreshToken": "{{refreshToken}}"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### AUTH-005 — Change password for authenticated user

**بتعمل إيه؟**:
تغيير كلمة المرور الخاصة بالمستخدم الحالي بعد مطابقة كلمة المرور القديمة وتشفير الجديدة بتقنية Argon2id.

**مين يقدر يستخدمها؟**:
متاحة للجميع بدون تسجيل دخول (Public Endpoint)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/auth/change-password`
- **Controller**: `AuthController -> HttpCode()`
- **Service Execution**: `authService.googleLogin()`
- **Authentication**: **Public**
- **Authorized Roles**: `Public`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `User`, `EmployeeProfile`, `RefreshToken`, `Session`, `AuditLog`

**Purpose & Business Context**:
Change password for authenticated user. This endpoint operates with strict transactional integrity under the Authentication subsystem.

**Headers**:
```http
Content-Type: application/json
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "currentPassword": "{{adminPassword}}",
  "newPassword": "{{adminPassword}}"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### AUTH-006 — Get current authenticated user & profile status

**بتعمل إيه؟**:
جلب الملف الشخصي الكامل للمستخدم المسجل حالياً، شامل أدواره وصلاحياته وبيانات الموظف والفرع التابع له.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/auth/me`
- **Controller**: `AuthController -> ApiBearerAuth()`
- **Service Execution**: `authService.getMe()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `User`, `EmployeeProfile`, `RefreshToken`, `Session`, `AuditLog`

**Purpose & Business Context**:
Get current authenticated user & profile status. This endpoint operates with strict transactional integrity under the Authentication subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Organization & Hierarchy

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **ORG-001** | `POST` | `/api/v1/organization` | JWT Bearer | SUPER_ADMIN | Create organization root (Super Admin only) |
| **ORG-002** | `GET` | `/api/v1/organization` | JWT Bearer | SUPER_ADMIN | List all organizations |
| **ORG-003** | `GET` | `/api/v1/organization/tree/hierarchy` | JWT Bearer | SUPER_ADMIN | Get complete nested organization structure tree |
| **ORG-004** | `GET` | `/api/v1/organization/reporting-tree/{employeeProfileId}` | JWT Bearer | SUPER_ADMIN | Get employee reporting lines (Chain of command & direct reports) |
| **ORG-005** | `GET` | `/api/v1/organization/{id}` | JWT Bearer | SUPER_ADMIN | Get organization details by ID or code |
| **ORG-006** | `PUT` | `/api/v1/organization/{id}` | JWT Bearer | SUPER_ADMIN | Update organization details |
| **ORG-007** | `DELETE` | `/api/v1/organization/{id}` | JWT Bearer | SUPER_ADMIN | Delete organization |
| **ORG-008** | `POST` | `/api/v1/organization/branches` | JWT Bearer | SUPER_ADMIN | Create a branch, hotel, or site location |
| **ORG-009** | `GET` | `/api/v1/organization/branches` | JWT Bearer | SUPER_ADMIN | List branches/hotels |
| **ORG-010** | `GET` | `/api/v1/organization/branches/{id}` | JWT Bearer | SUPER_ADMIN | Get branch details |
| **ORG-011** | `PUT` | `/api/v1/organization/branches/{id}` | JWT Bearer | SUPER_ADMIN | Update branch details |
| **ORG-012** | `DELETE` | `/api/v1/organization/branches/{id}` | JWT Bearer | SUPER_ADMIN | Delete branch |
| **ORG-013** | `POST` | `/api/v1/organization/departments` | JWT Bearer | SUPER_ADMIN | Create a department or division |
| **ORG-014** | `GET` | `/api/v1/organization/departments` | JWT Bearer | SUPER_ADMIN | List departments |
| **ORG-015** | `GET` | `/api/v1/organization/departments/{id}` | JWT Bearer | SUPER_ADMIN | Get department details |
| **ORG-016** | `PUT` | `/api/v1/organization/departments/{id}` | JWT Bearer | SUPER_ADMIN | Update department details |
| **ORG-017** | `DELETE` | `/api/v1/organization/departments/{id}` | JWT Bearer | SUPER_ADMIN | Delete department |
| **ORG-018** | `POST` | `/api/v1/organization/sections` | JWT Bearer | SUPER_ADMIN | Create a section inside a department |
| **ORG-019** | `GET` | `/api/v1/organization/sections` | JWT Bearer | SUPER_ADMIN | List sections |
| **ORG-020** | `GET` | `/api/v1/organization/sections/{id}` | JWT Bearer | SUPER_ADMIN | Get section details |
| **ORG-021** | `PUT` | `/api/v1/organization/sections/{id}` | JWT Bearer | SUPER_ADMIN | Update section |
| **ORG-022** | `DELETE` | `/api/v1/organization/sections/{id}` | JWT Bearer | SUPER_ADMIN | Delete section |
| **ORG-023** | `POST` | `/api/v1/organization/positions` | JWT Bearer | SUPER_ADMIN | Create a job position |
| **ORG-024** | `GET` | `/api/v1/organization/positions` | JWT Bearer | SUPER_ADMIN | List positions |
| **ORG-025** | `GET` | `/api/v1/organization/positions/{id}` | JWT Bearer | SUPER_ADMIN | Get position details |
| **ORG-026** | `PUT` | `/api/v1/organization/positions/{id}` | JWT Bearer | SUPER_ADMIN | Update position |
| **ORG-027** | `DELETE` | `/api/v1/organization/positions/{id}` | JWT Bearer | SUPER_ADMIN | Delete position |

### ORG-001 — Create organization root (Super Admin only)

**بتعمل إيه؟**:
تسجيل وإنشاء كيان تنظيمي جديد للمجموعة الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/organization`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.createOrganization()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Create organization root (Super Admin only). This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "name": "CyberWise Hospitality Group",
  "code": "CW-CORP",
  "logoUrl": "https://example.com/logo.png",
  "taxNumber": "123-456-789",
  "commercialRegister": "CR-987654",
  "description": "Enterprise Hospitality & Workforce Platform",
  "address": "100 Innovation Boulevard",
  "phone": "+201000000000",
  "email": "contact@cyberwise.com",
  "currency": "EGP",
  "timezone": "Africa/Cairo"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ORG-002 — List all organizations

**بتعمل إيه؟**:
استعراض الهيكل التنظيمي الشامل للمؤسسة والفروع التابعة لها.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/organization`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.findAllOrganizations()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
List all organizations. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ORG-003 — Get complete nested organization structure tree

**بتعمل إيه؟**:
استعراض الهيكل التنظيمي الشامل للمؤسسة والفروع التابعة لها.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/organization/tree/hierarchy`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.findAllOrganizations()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Get complete nested organization structure tree. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `organizationId` | No | `string` | `` | Filter parameter: organizationId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ORG-004 — Get employee reporting lines (Chain of command & direct reports)

**بتعمل إيه؟**:
استعراض الهيكل التنظيمي الشامل للمؤسسة والفروع التابعة لها.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/organization/reporting-tree/{employeeProfileId}`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.findAllOrganizations()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Get employee reporting lines (Chain of command & direct reports). This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `employeeProfileId` | `string` | `id-12345` | Identifier parameter: employeeProfileId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ORG-005 — Get organization details by ID or code

**بتعمل إيه؟**:
استعراض الهيكل التنظيمي الشامل للمؤسسة والفروع التابعة لها.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/organization/{id}`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.findAllOrganizations()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Get organization details by ID or code. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ORG-006 — Update organization details

**بتعمل إيه؟**:
تعديل بيانات المؤسسة الفندقية (الاسم، الشعار، العملة، المنطقة الزمنية).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `PUT`
- **Full URL**: `http://localhost:3000/api/v1/organization/{id}`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.updateOrganization()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Update organization details. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "name": "CyberWise Hospitality Group LLC",
  "logoUrl": "sample_logoUrl",
  "taxNumber": "sample_taxNumber",
  "commercialRegister": "sample_commercialRegister",
  "description": "sample_description",
  "address": "sample_address",
  "phone": "+201000000001",
  "email": "admin@example.test",
  "currency": "sample_currency",
  "timezone": "sample_timezone",
  "isActive": true
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ORG-007 — Delete organization

**بتعمل إيه؟**:
إدارة بيانات الهيكل التنظيمي للمؤسسة الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/organization/{id}`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.deleteOrganization()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Delete organization. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ORG-008 — Create a branch, hotel, or site location

**بتعمل إيه؟**:
إضافة فرع أو فندق جديد تابع للمجموعة الفندقية مع تحديد موقعه الجغرافي ونطاق الـ Geofence.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/organization/branches`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.createOrganization()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Create a branch, hotel, or site location. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "organizationId": "sample-uuid-v4",
  "name": "Grand Nile Hotel & Resort",
  "code": "GNH-01",
  "type": "BRANCH",
  "address": "Corniche El Nile, Cairo",
  "city": "Cairo",
  "country": "Egypt",
  "phone": "+20220000001",
  "email": "cairo-branch@cyberwise.com",
  "latitude": 30.0444,
  "longitude": 31.2357,
  "radiusMeters": 150
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Organization (ORG-001)

---

### ORG-009 — List branches/hotels

**بتعمل إيه؟**:
عرض قائمة بجميع فروع وفنادق المؤسسة الفندقية مع إحصائيات كل فرع.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/organization/branches`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.findAllOrganizations()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
List branches/hotels. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `organizationId` | No | `string` | `` | Filter parameter: organizationId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Organization (ORG-001)

---

### ORG-010 — Get branch details

**بتعمل إيه؟**:
عرض قائمة بجميع فروع وفنادق المؤسسة الفندقية مع إحصائيات كل فرع.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/organization/branches/{id}`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.findAllOrganizations()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Get branch details. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Organization (ORG-001)

---

### ORG-011 — Update branch details

**بتعمل إيه؟**:
تعديل بيانات فرع فندقي (الاسم، العنوان، الإحداثيات الجغرافية، حالة النشاط).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `PUT`
- **Full URL**: `http://localhost:3000/api/v1/organization/branches/{id}`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.updateOrganization()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Update branch details. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "name": "sample_name",
  "type": "HEADQUARTERS",
  "address": "sample_address",
  "city": "sample_city",
  "country": "sample_country",
  "phone": "+201000000001",
  "email": "admin@example.test",
  "latitude": 100,
  "longitude": 100,
  "radiusMeters": 100,
  "isActive": true
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Organization (ORG-001)

---

### ORG-012 — Delete branch

**بتعمل إيه؟**:
أرشفة أو حذف فرع فندقي من النظام بعد التأكد من عدم وجود ارتباطات حية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/organization/branches/{id}`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.deleteOrganization()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Delete branch. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Organization (ORG-001)

---

### ORG-013 — Create a department or division

**بتعمل إيه؟**:
إنشاء قسم جديد داخل الفندق (مثل الاستقبال، الهاوس كيبينج، الحسابات، الأغذية والمشروبات).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/organization/departments`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.createOrganization()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Create a department or division. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "organizationId": "sample-uuid-v4",
  "branchId": "sample-uuid-v4",
  "parentDepartmentId": "sample-uuid-v4",
  "headOfDepartmentId": "sample-uuid-v4",
  "name": "Food & Beverage",
  "code": "FB-DEPT",
  "description": "Handles kitchen, restaurants, and room service"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Organization (ORG-001)

---

### ORG-014 — List departments

**بتعمل إيه؟**:
جلب قائمة بجميع الأقسام التابعة للفندق أو الفرع مع هيكلها الإداري.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/organization/departments`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.findAllOrganizations()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
List departments. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `organizationId` | No | `string` | `` | Filter parameter: organizationId |
| `branchId` | No | `string` | `` | Filter parameter: branchId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Organization (ORG-001)

---

### ORG-015 — Get department details

**بتعمل إيه؟**:
جلب قائمة بجميع الأقسام التابعة للفندق أو الفرع مع هيكلها الإداري.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/organization/departments/{id}`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.findAllOrganizations()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Get department details. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Organization (ORG-001)

---

### ORG-016 — Update department details

**بتعمل إيه؟**:
تحديث بيانات وقسم فندقي معين وربطه برئيس القسم.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `PUT`
- **Full URL**: `http://localhost:3000/api/v1/organization/departments/{id}`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.updateOrganization()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Update department details. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "name": "sample_name",
  "description": "sample_description",
  "branchId": "sample-uuid-v4",
  "parentDepartmentId": "sample-uuid-v4",
  "headOfDepartmentId": "sample-uuid-v4",
  "isActive": true
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Organization (ORG-001)

---

### ORG-017 — Delete department

**بتعمل إيه؟**:
حذف أو تعطيل قسم في الفندق ونقل الموظفين المرتبطين به.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/organization/departments/{id}`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.deleteOrganization()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Delete department. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Organization (ORG-001)

---

### ORG-018 — Create a section inside a department

**بتعمل إيه؟**:
تسجيل وإنشاء كيان تنظيمي جديد للمجموعة الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/organization/sections`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.createOrganization()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Create a section inside a department. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "departmentId": "sample-uuid-v4",
  "headOfSectionId": "sample-uuid-v4",
  "name": "Pastry & Bakery",
  "code": "PASTRY-SEC",
  "description": "sample_description"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ORG-019 — List sections

**بتعمل إيه؟**:
استعراض الهيكل التنظيمي الشامل للمؤسسة والفروع التابعة لها.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/organization/sections`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.findAllOrganizations()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
List sections. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `departmentId` | No | `string` | `` | Filter parameter: departmentId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ORG-020 — Get section details

**بتعمل إيه؟**:
استعراض الهيكل التنظيمي الشامل للمؤسسة والفروع التابعة لها.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/organization/sections/{id}`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.findAllOrganizations()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Get section details. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ORG-021 — Update section

**بتعمل إيه؟**:
تعديل بيانات المؤسسة الفندقية (الاسم، الشعار، العملة، المنطقة الزمنية).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `PUT`
- **Full URL**: `http://localhost:3000/api/v1/organization/sections/{id}`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.updateOrganization()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Update section. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "name": "sample_name",
  "description": "sample_description",
  "headOfSectionId": "sample-uuid-v4",
  "isActive": true
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ORG-022 — Delete section

**بتعمل إيه؟**:
إدارة بيانات الهيكل التنظيمي للمؤسسة الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/organization/sections/{id}`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.deleteOrganization()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Delete section. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ORG-023 — Create a job position

**بتعمل إيه؟**:
إضافة مسمى وظيفي جديد في الهيكل التنظيمي وتحديد المستوى والمسؤوليات وسقف الراتب.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/organization/positions`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.createOrganization()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Create a job position. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "organizationId": "sample-uuid-v4",
  "departmentId": "sample-uuid-v4",
  "sectionId": "sample-uuid-v4",
  "title": "Executive Sous Chef",
  "code": "SOUS-CHEF",
  "level": "MID",
  "minSalary": 8000,
  "maxSalary": 15000,
  "description": "sample_description"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ORG-024 — List positions

**بتعمل إيه؟**:
جلب قائمة المسميات والوظائف المعتمدة في الفندق مصنفة حسب الأقسام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/organization/positions`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.findAllOrganizations()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
List positions. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `organizationId` | No | `string` | `` | Filter parameter: organizationId |
| `departmentId` | No | `string` | `` | Filter parameter: departmentId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ORG-025 — Get position details

**بتعمل إيه؟**:
جلب قائمة المسميات والوظائف المعتمدة في الفندق مصنفة حسب الأقسام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/organization/positions/{id}`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.findAllOrganizations()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Get position details. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ORG-026 — Update position

**بتعمل إيه؟**:
تعديل بيانات المسمى الوظيفي ومستواه الإداري والراتب الأساسي.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `PUT`
- **Full URL**: `http://localhost:3000/api/v1/organization/positions/{id}`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.updateOrganization()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Update position. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "title": "sample_title",
  "level": "ENTRY",
  "minSalary": 100,
  "maxSalary": 100,
  "description": "sample_description",
  "departmentId": "sample-uuid-v4",
  "sectionId": "sample-uuid-v4",
  "isActive": true
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ORG-027 — Delete position

**بتعمل إيه؟**:
حذف مسمى وظيفي من الهيكل التنظيمي للفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/organization/positions/{id}`
- **Controller**: `OrganizationController -> Roles()`
- **Service Execution**: `orgService.deleteOrganization()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Organization`, `Branch`, `Department`, `Section`, `Position`

**Purpose & Business Context**:
Delete position. This endpoint operates with strict transactional integrity under the Organization & Hierarchy subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Roles

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **ROLE-001** | `POST` | `/api/v1/roles` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Create a custom role with optional initial permissions |
| **ROLE-002** | `GET` | `/api/v1/roles` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | List all roles with pagination and search |
| **ROLE-003** | `GET` | `/api/v1/roles/users/{userId}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Get effective roles and permissions of a user |
| **ROLE-004** | `POST` | `/api/v1/roles/users/assign` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Assign database roles to a specific user |
| **ROLE-005** | `GET` | `/api/v1/roles/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Get role details by ID or slug |
| **ROLE-006** | `PUT` | `/api/v1/roles/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Update role details |
| **ROLE-007** | `DELETE` | `/api/v1/roles/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Delete a custom role (System roles cannot be deleted) |
| **ROLE-008** | `PUT` | `/api/v1/roles/{id}/permissions` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Synchronize permission matrix for a role |

### ROLE-001 — Create a custom role with optional initial permissions

**بتعمل إيه؟**:
إنشاء دور وظيفي جديد وتحديد صلاحياته ومسؤولياته في النظام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/roles`
- **Controller**: `RolesController -> Roles()`
- **Service Execution**: `rolesService.create()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `RoleRecord`, `RolePermission`, `Permission`, `UserRole`

**Purpose & Business Context**:
Create a custom role with optional initial permissions. This endpoint operates with strict transactional integrity under the Roles subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "name": "Payroll Officer",
  "slug": "payroll-officer",
  "description": "Handles payroll calculations, adjustments, and review",
  "permissionSlugs": [
    "payroll:read",
    "payroll:calculate"
  ],
  "organizationId": "sample-uuid-v4"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ROLE-002 — List all roles with pagination and search

**بتعمل إيه؟**:
استعراض قائمة بجميع الأدوار الوظيفية المتاحة في النظام ومستوياتها.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/roles`
- **Controller**: `RolesController -> Roles()`
- **Service Execution**: `rolesService.findAll()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `RoleRecord`, `RolePermission`, `Permission`, `UserRole`

**Purpose & Business Context**:
List all roles with pagination and search. This endpoint operates with strict transactional integrity under the Roles subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ROLE-003 — Get effective roles and permissions of a user

**بتعمل إيه؟**:
استعراض قائمة بجميع الأدوار الوظيفية المتاحة في النظام ومستوياتها.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/roles/users/{userId}`
- **Controller**: `RolesController -> Roles()`
- **Service Execution**: `rolesService.findAll()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `RoleRecord`, `RolePermission`, `Permission`, `UserRole`

**Purpose & Business Context**:
Get effective roles and permissions of a user. This endpoint operates with strict transactional integrity under the Roles subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `userId` | `string` | `id-12345` | Identifier parameter: userId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ROLE-004 — Assign database roles to a specific user

**بتعمل إيه؟**:
إنشاء دور وظيفي جديد وتحديد صلاحياته ومسؤولياته في النظام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/roles/users/assign`
- **Controller**: `RolesController -> Roles()`
- **Service Execution**: `rolesService.create()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `RoleRecord`, `RolePermission`, `Permission`, `UserRole`

**Purpose & Business Context**:
Assign database roles to a specific user. This endpoint operates with strict transactional integrity under the Roles subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "userId": "a8e9d3c2-1b2c-3d4e-5f6a-7b8c9d0e1f2a",
  "roleSlugs": [
    "hr-manager",
    "custom-auditor"
  ]
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ROLE-005 — Get role details by ID or slug

**بتعمل إيه؟**:
استعراض قائمة بجميع الأدوار الوظيفية المتاحة في النظام ومستوياتها.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/roles/{id}`
- **Controller**: `RolesController -> Roles()`
- **Service Execution**: `rolesService.findAll()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `RoleRecord`, `RolePermission`, `Permission`, `UserRole`

**Purpose & Business Context**:
Get role details by ID or slug. This endpoint operates with strict transactional integrity under the Roles subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ROLE-006 — Update role details

**بتعمل إيه؟**:
تعديل بيانات الدور الوظيفي وتحديث الصلاحيات المرتبطة به.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `PUT`
- **Full URL**: `http://localhost:3000/api/v1/roles/{id}`
- **Controller**: `RolesController -> Roles()`
- **Service Execution**: `rolesService.update()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `RoleRecord`, `RolePermission`, `Permission`, `UserRole`

**Purpose & Business Context**:
Update role details. This endpoint operates with strict transactional integrity under the Roles subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "name": "Senior Payroll Officer",
  "description": "sample_description",
  "isActive": true
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ROLE-007 — Delete a custom role (System roles cannot be deleted)

**بتعمل إيه؟**:
حذف أو تعطيل دور وظيفي من النظام بعد التأكد من عدم ارتباط مستخدمين به.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/roles/{id}`
- **Controller**: `RolesController -> Roles()`
- **Service Execution**: `rolesService.remove()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `RoleRecord`, `RolePermission`, `Permission`, `UserRole`

**Purpose & Business Context**:
Delete a custom role (System roles cannot be deleted). This endpoint operates with strict transactional integrity under the Roles subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ROLE-008 — Synchronize permission matrix for a role

**بتعمل إيه؟**:
تعديل بيانات الدور الوظيفي وتحديث الصلاحيات المرتبطة به.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `PUT`
- **Full URL**: `http://localhost:3000/api/v1/roles/{id}/permissions`
- **Controller**: `RolesController -> Roles()`
- **Service Execution**: `rolesService.update()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `RoleRecord`, `RolePermission`, `Permission`, `UserRole`

**Purpose & Business Context**:
Synchronize permission matrix for a role. This endpoint operates with strict transactional integrity under the Roles subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "permissionSlugs": [
    "employees:read",
    "payroll:read",
    "payroll:calculate"
  ]
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Permissions

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **PERM-001** | `POST` | `/api/v1/permissions` | JWT Bearer | SUPER_ADMIN | Create a new granular permission (Super Admin only) |
| **PERM-002** | `GET` | `/api/v1/permissions` | JWT Bearer | SUPER_ADMIN | List all permissions with filtering and pagination |
| **PERM-003** | `GET` | `/api/v1/permissions/catalog/grouped` | JWT Bearer | SUPER_ADMIN | Get all permissions grouped by domain module |
| **PERM-004** | `GET` | `/api/v1/permissions/{id}` | JWT Bearer | SUPER_ADMIN | Get permission by ID or slug |

### PERM-001 — Create a new granular permission (Super Admin only)

**بتعمل إيه؟**:
استعراض والتحقق من الصلاحيات التفصيلية المتاحة للمستخدمين عبر وحدات النظام المختلفة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/permissions`
- **Controller**: `PermissionsController -> Roles()`
- **Service Execution**: `permissionsService.create()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Permission`, `RolePermission`

**Purpose & Business Context**:
Create a new granular permission (Super Admin only). This endpoint operates with strict transactional integrity under the Permissions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "slug": "employees:read",
  "action": "READ",
  "subject": "EMPLOYEES",
  "description": "Allows viewing employee profiles and listing",
  "module": "employees"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PERM-002 — List all permissions with filtering and pagination

**بتعمل إيه؟**:
استعراض والتحقق من الصلاحيات التفصيلية المتاحة للمستخدمين عبر وحدات النظام المختلفة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/permissions`
- **Controller**: `PermissionsController -> Roles()`
- **Service Execution**: `permissionsService.findAll()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Permission`, `RolePermission`

**Purpose & Business Context**:
List all permissions with filtering and pagination. This endpoint operates with strict transactional integrity under the Permissions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `module` | No | `string` | `` | Filter by module group |
| `action` | No | `string` | `` | Filter by action type |
| `subject` | No | `string` | `` | Filter by subject/resource |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PERM-003 — Get all permissions grouped by domain module

**بتعمل إيه؟**:
استعراض والتحقق من الصلاحيات التفصيلية المتاحة للمستخدمين عبر وحدات النظام المختلفة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/permissions/catalog/grouped`
- **Controller**: `PermissionsController -> Roles()`
- **Service Execution**: `permissionsService.findAll()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Permission`, `RolePermission`

**Purpose & Business Context**:
Get all permissions grouped by domain module. This endpoint operates with strict transactional integrity under the Permissions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PERM-004 — Get permission by ID or slug

**بتعمل إيه؟**:
استعراض والتحقق من الصلاحيات التفصيلية المتاحة للمستخدمين عبر وحدات النظام المختلفة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/permissions/{id}`
- **Controller**: `PermissionsController -> Roles()`
- **Service Execution**: `permissionsService.findAll()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Permission`, `RolePermission`

**Purpose & Business Context**:
Get permission by ID or slug. This endpoint operates with strict transactional integrity under the Permissions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Settings & Feature Flags

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **SET-001** | `GET` | `/api/v1/settings/public` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Get public system settings (Unauthenticated bootstrap endpoint) |
| **SET-002** | `GET` | `/api/v1/settings` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Get all system settings with category filtering |
| **SET-003** | `POST` | `/api/v1/settings` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Set or update a system setting (Super Admin only) |
| **SET-004** | `DELETE` | `/api/v1/settings/{key}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Delete a system setting (Super Admin only) |
| **SET-005** | `GET` | `/api/v1/settings/flags` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | List all system feature flags |
| **SET-006** | `POST` | `/api/v1/settings/flags` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Create a feature flag |
| **SET-007** | `PUT` | `/api/v1/settings/flags/{key}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Update feature flag status and rules |

### SET-001 — Get public system settings (Unauthenticated bootstrap endpoint)

**بتعمل إيه؟**:
جلب واستعراض إعدادات النظام والتكوينات التشغيلية الحالية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/settings/public`
- **Controller**: `SettingsController -> Public()`
- **Service Execution**: `settingsService.getPublicSettings()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `SystemSetting`, `FeatureFlag`

**Purpose & Business Context**:
Get public system settings (Unauthenticated bootstrap endpoint). This endpoint operates with strict transactional integrity under the Settings & Feature Flags subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SET-002 — Get all system settings with category filtering

**بتعمل إيه؟**:
جلب واستعراض إعدادات النظام والتكوينات التشغيلية الحالية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/settings`
- **Controller**: `SettingsController -> Public()`
- **Service Execution**: `settingsService.getPublicSettings()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `SystemSetting`, `FeatureFlag`

**Purpose & Business Context**:
Get all system settings with category filtering. This endpoint operates with strict transactional integrity under the Settings & Feature Flags subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `category` | No | `string` | `` | Filter parameter: category |
| `organizationId` | No | `string` | `` | Filter parameter: organizationId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SET-003 — Set or update a system setting (Super Admin only)

**بتعمل إيه؟**:
تحديث وضبط إعدادات النظام ومفاتيح الخصائص (Feature Flags) لتفعيل أو إيقاف ميزات معينة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/settings`
- **Controller**: `SettingsController -> ApiBearerAuth()`
- **Service Execution**: `settingsService.setSetting()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `SystemSetting`, `FeatureFlag`

**Purpose & Business Context**:
Set or update a system setting (Super Admin only). This endpoint operates with strict transactional integrity under the Settings & Feature Flags subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "key": "attendance_grace_period_minutes",
  "value": 15,
  "category": "GENERAL",
  "isPublic": false,
  "description": "Grace period for check-in before marking lateness",
  "organizationId": "sample-uuid-v4"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SET-004 — Delete a system setting (Super Admin only)

**بتعمل إيه؟**:
جلب واستعراض إعدادات النظام والتكوينات التشغيلية الحالية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/settings/{key}`
- **Controller**: `SettingsController -> ApiBearerAuth()`
- **Service Execution**: `settingsService.deleteSetting()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `SystemSetting`, `FeatureFlag`

**Purpose & Business Context**:
Delete a system setting (Super Admin only). This endpoint operates with strict transactional integrity under the Settings & Feature Flags subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `key` | `string` | `id-12345` | Identifier parameter: key |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SET-005 — List all system feature flags

**بتعمل إيه؟**:
جلب واستعراض إعدادات النظام والتكوينات التشغيلية الحالية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/settings/flags`
- **Controller**: `SettingsController -> Public()`
- **Service Execution**: `settingsService.getPublicSettings()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `SystemSetting`, `FeatureFlag`

**Purpose & Business Context**:
List all system feature flags. This endpoint operates with strict transactional integrity under the Settings & Feature Flags subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `organizationId` | No | `string` | `` | Filter parameter: organizationId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SET-006 — Create a feature flag

**بتعمل إيه؟**:
تحديث وضبط إعدادات النظام ومفاتيح الخصائص (Feature Flags) لتفعيل أو إيقاف ميزات معينة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/settings/flags`
- **Controller**: `SettingsController -> ApiBearerAuth()`
- **Service Execution**: `settingsService.setSetting()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `SystemSetting`, `FeatureFlag`

**Purpose & Business Context**:
Create a feature flag. This endpoint operates with strict transactional integrity under the Settings & Feature Flags subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "key": "enable_biometric_face_id",
  "isEnabled": false,
  "description": "Enables AI biometric facial verification at check-in",
  "rolloutPercentage": 100,
  "rules": null,
  "organizationId": "sample-uuid-v4"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SET-007 — Update feature flag status and rules

**بتعمل إيه؟**:
تحديث وضبط إعدادات النظام ومفاتيح الخصائص (Feature Flags) لتفعيل أو إيقاف ميزات معينة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `PUT`
- **Full URL**: `http://localhost:3000/api/v1/settings/flags/{key}`
- **Controller**: `SettingsController -> ApiBearerAuth()`
- **Service Execution**: `settingsService.updateFeatureFlag()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `SystemSetting`, `FeatureFlag`

**Purpose & Business Context**:
Update feature flag status and rules. This endpoint operates with strict transactional integrity under the Settings & Feature Flags subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `key` | `string` | `id-12345` | Identifier parameter: key |

**Request Body Payload**:
```json
{
  "isEnabled": true,
  "description": "sample_description",
  "rolloutPercentage": 100,
  "rules": null
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## HR Management

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **HR-001** | `GET` | `/api/v1/hr/employees` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get enriched paginated employee list with organizational & hierarchy filters |
| **HR-002** | `GET` | `/api/v1/hr/employees/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get detailed HR employee profile with full hierarchy, documents, and onboarding status |
| **HR-003** | `PATCH` | `/api/v1/hr/employees/{id}/assignment` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Reassign employee department, position, section, manager, workplace, or schedule |
| **HR-004** | `POST` | `/api/v1/hr/employees/{id}/documents` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Add document metadata for employee |
| **HR-005** | `GET` | `/api/v1/hr/employees/{id}/documents` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | List all document records and verification statuses for employee |
| **HR-006** | `PATCH` | `/api/v1/hr/documents/{docId}/verify` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Verify or revoke verification of employee document metadata |
| **HR-007** | `PATCH` | `/api/v1/hr/documents/{docId}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Update document metadata |
| **HR-008** | `DELETE` | `/api/v1/hr/documents/{docId}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Delete employee document metadata |

### HR-001 — Get enriched paginated employee list with organizational & hierarchy filters

**بتعمل إيه؟**:
إدارة سياسات الموارد البشرية، وتتبع عمليات الموظفين وسجلات الامتثال واللوائح الداخلية للفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/hr/employees`
- **Controller**: `HrController -> Roles()`
- **Service Execution**: `hrService.getEmployees()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `EmployeeProfile`, `User`, `Position`, `Department`, `Document`

**Purpose & Business Context**:
Get enriched paginated employee list with organizational & hierarchy filters. This endpoint operates with strict transactional integrity under the HR Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `organizationId` | No | `string` | `` | Filter by Organization ID |
| `branchId` | No | `string` | `` | Filter by Branch ID |
| `departmentId` | No | `string` | `` | Filter by Department ID |
| `positionId` | No | `string` | `` | Filter by Position ID |
| `workplaceId` | No | `string` | `` | Filter by Workplace ID |
| `isOnboarded` | No | `boolean` | `` | Filter by Onboarding completion status |
| `isProfileComplete` | No | `boolean` | `` | Filter by Profile completion status |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### HR-002 — Get detailed HR employee profile with full hierarchy, documents, and onboarding status

**بتعمل إيه؟**:
إدارة سياسات الموارد البشرية، وتتبع عمليات الموظفين وسجلات الامتثال واللوائح الداخلية للفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/hr/employees/{id}`
- **Controller**: `HrController -> Roles()`
- **Service Execution**: `hrService.getEmployees()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `EmployeeProfile`, `User`, `Position`, `Department`, `Document`

**Purpose & Business Context**:
Get detailed HR employee profile with full hierarchy, documents, and onboarding status. This endpoint operates with strict transactional integrity under the HR Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Branch, Department, Position

---

### HR-003 — Reassign employee department, position, section, manager, workplace, or schedule

**بتعمل إيه؟**:
إدارة سياسات الموارد البشرية، وتتبع عمليات الموظفين وسجلات الامتثال واللوائح الداخلية للفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/hr/employees/{id}/assignment`
- **Controller**: `HrController -> Roles()`
- **Service Execution**: `hrService.updateEmployeeAssignment()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `EmployeeProfile`, `User`, `Position`, `Department`, `Document`

**Purpose & Business Context**:
Reassign employee department, position, section, manager, workplace, or schedule. This endpoint operates with strict transactional integrity under the HR Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "organizationId": "a8d29b2b-5867-4e94-813c-d38a065bb24c",
  "branchId": "b1d29b2b-5867-4e94-813c-d38a065bb24c",
  "departmentId": "c2d29b2b-5867-4e94-813c-d38a065bb24c",
  "sectionId": "d3d29b2b-5867-4e94-813c-d38a065bb24c",
  "positionId": "e4d29b2b-5867-4e94-813c-d38a065bb24c",
  "managerId": "f5d29b2b-5867-4e94-813c-d38a065bb24c",
  "workplaceId": "16d29b2b-5867-4e94-813c-d38a065bb24c",
  "scheduleId": "27d29b2b-5867-4e94-813c-d38a065bb24c",
  "jobTitle": "Senior Software Engineer",
  "department": "Engineering"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Branch, Department, Position

---

### HR-004 — Add document metadata for employee

**بتعمل إيه؟**:
إدارة سياسات الموارد البشرية، وتتبع عمليات الموظفين وسجلات الامتثال واللوائح الداخلية للفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/hr/employees/{id}/documents`
- **Controller**: `HrController -> Roles()`
- **Service Execution**: `hrService.addEmployeeDocument()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `EmployeeProfile`, `User`, `Position`, `Department`, `Document`

**Purpose & Business Context**:
Add document metadata for employee. This endpoint operates with strict transactional integrity under the HR Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "documentType": "NATIONAL_ID",
  "title": "National Identity Card",
  "documentNumber": "29801011234567",
  "issueDate": "2024-01-15",
  "expiryDate": "2031-01-14",
  "fileUrl": "https://storage.cyberwise.io/docs/national_id_01.pdf",
  "fileSize": 1048576,
  "mimeType": "application/pdf",
  "notes": "Verified against original civil registry card"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Branch, Department, Position

---

### HR-005 — List all document records and verification statuses for employee

**بتعمل إيه؟**:
إدارة سياسات الموارد البشرية، وتتبع عمليات الموظفين وسجلات الامتثال واللوائح الداخلية للفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/hr/employees/{id}/documents`
- **Controller**: `HrController -> Roles()`
- **Service Execution**: `hrService.getEmployees()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `EmployeeProfile`, `User`, `Position`, `Department`, `Document`

**Purpose & Business Context**:
List all document records and verification statuses for employee. This endpoint operates with strict transactional integrity under the HR Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Branch, Department, Position

---

### HR-006 — Verify or revoke verification of employee document metadata

**بتعمل إيه؟**:
إدارة سياسات الموارد البشرية، وتتبع عمليات الموظفين وسجلات الامتثال واللوائح الداخلية للفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/hr/documents/{docId}/verify`
- **Controller**: `HrController -> Roles()`
- **Service Execution**: `hrService.updateEmployeeAssignment()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `EmployeeProfile`, `User`, `Position`, `Department`, `Document`

**Purpose & Business Context**:
Verify or revoke verification of employee document metadata. This endpoint operates with strict transactional integrity under the HR Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `docId` | `string` | `id-12345` | Identifier parameter: docId |

**Request Body Payload**:
```json
{
  "isVerified": true,
  "notes": "Verified against original document"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### HR-007 — Update document metadata

**بتعمل إيه؟**:
إدارة سياسات الموارد البشرية، وتتبع عمليات الموظفين وسجلات الامتثال واللوائح الداخلية للفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/hr/documents/{docId}`
- **Controller**: `HrController -> Roles()`
- **Service Execution**: `hrService.updateEmployeeAssignment()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `EmployeeProfile`, `User`, `Position`, `Department`, `Document`

**Purpose & Business Context**:
Update document metadata. This endpoint operates with strict transactional integrity under the HR Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `docId` | `string` | `id-12345` | Identifier parameter: docId |

**Request Body Payload**:
```json
{
  "documentType": "NATIONAL_ID",
  "title": "National Identity Card",
  "documentNumber": "29801011234567",
  "issueDate": "2024-01-15",
  "expiryDate": "2031-01-14",
  "fileUrl": "https://storage.cyberwise.io/docs/national_id_01.pdf",
  "fileSize": 1048576,
  "mimeType": "application/pdf",
  "notes": "Verified against original civil registry card",
  "isVerified": true
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### HR-008 — Delete employee document metadata

**بتعمل إيه؟**:
إدارة سياسات الموارد البشرية، وتتبع عمليات الموظفين وسجلات الامتثال واللوائح الداخلية للفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/hr/documents/{docId}`
- **Controller**: `HrController -> Roles()`
- **Service Execution**: `hrService.deleteEmployeeDocument()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `EmployeeProfile`, `User`, `Position`, `Department`, `Document`

**Purpose & Business Context**:
Delete employee document metadata. This endpoint operates with strict transactional integrity under the HR Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `docId` | `string` | `id-12345` | Identifier parameter: docId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Recruitment & ATS

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **REC-001** | `POST` | `/api/v1/recruitment/job-openings` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Create a new job opening requisition |
| **REC-002** | `GET` | `/api/v1/recruitment/job-openings` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List paginated job openings with filter support |
| **REC-003** | `GET` | `/api/v1/recruitment/job-openings/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get job opening details with applications timeline |
| **REC-004** | `PATCH` | `/api/v1/recruitment/job-openings/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Update job opening parameters or status |
| **REC-005** | `DELETE` | `/api/v1/recruitment/job-openings/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Delete job opening |
| **REC-006** | `POST` | `/api/v1/recruitment/candidates` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Create candidate talent profile |
| **REC-007** | `GET` | `/api/v1/recruitment/candidates` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Search and list candidate talent database |
| **REC-008** | `GET` | `/api/v1/recruitment/candidates/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get candidate profile with full application & interview history |
| **REC-009** | `PATCH` | `/api/v1/recruitment/candidates/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Update candidate contact details and skills |
| **REC-010** | `DELETE` | `/api/v1/recruitment/candidates/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Delete candidate record |
| **REC-011** | `POST` | `/api/v1/recruitment/applications` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Submit/link candidate application for a job opening |
| **REC-012** | `GET` | `/api/v1/recruitment/applications` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List and filter job applications by opening or status |
| **REC-013** | `GET` | `/api/v1/recruitment/applications/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get application details with interview notes and evaluations |
| **REC-014** | `PATCH` | `/api/v1/recruitment/applications/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Update application stage, rating, or rejection reason |
| **REC-015** | `POST` | `/api/v1/recruitment/interviews` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Schedule candidate interview round |
| **REC-016** | `GET` | `/api/v1/recruitment/interviews` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List scheduled interviews |
| **REC-017** | `GET` | `/api/v1/recruitment/interviews/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get interview details and scorecard |
| **REC-018** | `PATCH` | `/api/v1/recruitment/interviews/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Update interview time, meeting link, or status |
| **REC-019** | `POST` | `/api/v1/recruitment/interviews/{id}/evaluations` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Submit structured interviewer scorecard and rating |
| **REC-020** | `POST` | `/api/v1/recruitment/offers` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Generate job offer for candidate |
| **REC-021** | `GET` | `/api/v1/recruitment/offers` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List all generated job offers |
| **REC-022** | `GET` | `/api/v1/recruitment/offers/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get job offer terms and acceptance status |
| **REC-023** | `PATCH` | `/api/v1/recruitment/offers/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Update job offer details, status (SENT, ACCEPTED, REJECTED) |
| **REC-024** | `POST` | `/api/v1/recruitment/hire` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Execute atomic hiring: Creates corporate user account, employee profile, links hierarchy & starts onboarding |

### REC-001 — Create a new job opening requisition

**بتعمل إيه؟**:
إدارة دورة التوظيف واستقطاب الكفاءات الفندقية من مرحلة الإعلان حتى الاختيار.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/job-openings`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.createJobOpening()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Create a new job opening requisition. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "title": "Senior Backend Engineer",
  "code": "ENG-BE-01",
  "organizationId": "a8d29b2b-5867-4e94-813c-d38a065bb24c",
  "branchId": "b1d29b2b-5867-4e94-813c-d38a065bb24c",
  "departmentId": "c2d29b2b-5867-4e94-813c-d38a065bb24c",
  "positionId": "e4d29b2b-5867-4e94-813c-d38a065bb24c",
  "description": "We are looking for a Node.js/NestJS expert...",
  "requirements": "5+ years NestJS, PostgreSQL, Prisma, Redis experience",
  "employmentType": "FULL_TIME",
  "status": "DRAFT",
  "vacancies": 2,
  "targetDate": "2026-12-31",
  "minSalary": 30000,
  "maxSalary": 45000,
  "currency": "EGP"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-002 — List paginated job openings with filter support

**بتعمل إيه؟**:
إدارة دورة التوظيف واستقطاب الكفاءات الفندقية من مرحلة الإعلان حتى الاختيار.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/job-openings`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.getJobOpenings()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
List paginated job openings with filter support. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `status` | No | `string` | `` | Filter parameter: status |
| `departmentId` | No | `string` | `` | Filter parameter: departmentId |
| `positionId` | No | `string` | `` | Filter parameter: positionId |
| `organizationId` | No | `string` | `` | Filter parameter: organizationId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-003 — Get job opening details with applications timeline

**بتعمل إيه؟**:
إدارة دورة التوظيف واستقطاب الكفاءات الفندقية من مرحلة الإعلان حتى الاختيار.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/job-openings/{id}`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.getJobOpenings()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Get job opening details with applications timeline. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-004 — Update job opening parameters or status

**بتعمل إيه؟**:
إدارة دورة التوظيف واستقطاب الكفاءات الفندقية من مرحلة الإعلان حتى الاختيار.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/job-openings/{id}`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.updateJobOpening()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Update job opening parameters or status. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "title": "Senior Backend Engineer",
  "code": "ENG-BE-01",
  "organizationId": "a8d29b2b-5867-4e94-813c-d38a065bb24c",
  "branchId": "b1d29b2b-5867-4e94-813c-d38a065bb24c",
  "departmentId": "c2d29b2b-5867-4e94-813c-d38a065bb24c",
  "positionId": "e4d29b2b-5867-4e94-813c-d38a065bb24c",
  "description": "We are looking for a Node.js/NestJS expert...",
  "requirements": "5+ years NestJS, PostgreSQL, Prisma, Redis experience",
  "employmentType": "FULL_TIME",
  "status": "DRAFT",
  "vacancies": 2,
  "targetDate": "2026-12-31",
  "minSalary": 30000,
  "maxSalary": 45000,
  "currency": "EGP"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-005 — Delete job opening

**بتعمل إيه؟**:
إدارة دورة التوظيف واستقطاب الكفاءات الفندقية من مرحلة الإعلان حتى الاختيار.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/job-openings/{id}`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.deleteJobOpening()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Delete job opening. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-006 — Create candidate talent profile

**بتعمل إيه؟**:
تسجيل متقدم جديد لشغل وظيفة في الفندق وإرفاق السيرة الذاتية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/candidates`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.createJobOpening()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Create candidate talent profile. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "firstName": "Ahmed",
  "lastName": "Hassan",
  "email": "ahmed.hassan@example.com",
  "phone": "+201012345678",
  "currentTitle": "Senior Software Engineer",
  "experienceYears": 6,
  "source": "DIRECT",
  "resumeUrl": "https://storage.cyberwise.io/resumes/ahmed_hassan_cv.pdf",
  "skills": [
    "Node.js",
    "TypeScript",
    "NestJS",
    "PostgreSQL",
    "Docker"
  ],
  "notes": "Strong architectural experience in fintech projects"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-007 — Search and list candidate talent database

**بتعمل إيه؟**:
متابعة وتقييم طلبات المتقدمين للوظائف ومراحل الفرز والمقابلات (ATS).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/candidates`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.getJobOpenings()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Search and list candidate talent database. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `source` | No | `string` | `` | Filter parameter: source |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-008 — Get candidate profile with full application & interview history

**بتعمل إيه؟**:
متابعة وتقييم طلبات المتقدمين للوظائف ومراحل الفرز والمقابلات (ATS).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/candidates/{id}`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.getJobOpenings()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Get candidate profile with full application & interview history. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-009 — Update candidate contact details and skills

**بتعمل إيه؟**:
متابعة وتقييم طلبات المتقدمين للوظائف ومراحل الفرز والمقابلات (ATS).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/candidates/{id}`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.updateJobOpening()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Update candidate contact details and skills. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "firstName": "Ahmed",
  "lastName": "Hassan",
  "email": "ahmed.hassan@example.com",
  "phone": "+201012345678",
  "currentTitle": "Senior Software Engineer",
  "experienceYears": 6,
  "source": "DIRECT",
  "resumeUrl": "https://storage.cyberwise.io/resumes/ahmed_hassan_cv.pdf",
  "skills": [
    "Node.js",
    "TypeScript",
    "NestJS",
    "PostgreSQL",
    "Docker"
  ],
  "notes": "Strong architectural experience in fintech projects"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-010 — Delete candidate record

**بتعمل إيه؟**:
متابعة وتقييم طلبات المتقدمين للوظائف ومراحل الفرز والمقابلات (ATS).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/candidates/{id}`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.deleteJobOpening()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Delete candidate record. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-011 — Submit/link candidate application for a job opening

**بتعمل إيه؟**:
تسجيل متقدم جديد لشغل وظيفة في الفندق وإرفاق السيرة الذاتية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/applications`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.createJobOpening()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Submit/link candidate application for a job opening. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "jobOpeningId": "a8d29b2b-5867-4e94-813c-d38a065bb24c",
  "candidateId": "b1d29b2b-5867-4e94-813c-d38a065bb24c",
  "status": "APPLIED",
  "rating": 4,
  "stageNotes": "Candidate applied via LinkedIn recruiter outreach"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-012 — List and filter job applications by opening or status

**بتعمل إيه؟**:
متابعة وتقييم طلبات المتقدمين للوظائف ومراحل الفرز والمقابلات (ATS).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/applications`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.getJobOpenings()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
List and filter job applications by opening or status. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `jobOpeningId` | No | `string` | `` | Filter parameter: jobOpeningId |
| `candidateId` | No | `string` | `` | Filter parameter: candidateId |
| `status` | No | `string` | `` | Filter parameter: status |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-013 — Get application details with interview notes and evaluations

**بتعمل إيه؟**:
متابعة وتقييم طلبات المتقدمين للوظائف ومراحل الفرز والمقابلات (ATS).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/applications/{id}`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.getJobOpenings()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Get application details with interview notes and evaluations. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-014 — Update application stage, rating, or rejection reason

**بتعمل إيه؟**:
متابعة وتقييم طلبات المتقدمين للوظائف ومراحل الفرز والمقابلات (ATS).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/applications/{id}`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.updateJobOpening()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Update application stage, rating, or rejection reason. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "status": "APPLIED",
  "rating": 5,
  "stageNotes": "Moved to technical round after initial screening",
  "rejectionReason": "Failed system design interview"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-015 — Schedule candidate interview round

**بتعمل إيه؟**:
جدولة موعد مقابلة شخصية أو اختبار فني لمرشح للوظيفة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/interviews`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.createJobOpening()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Schedule candidate interview round. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "applicationId": "a8d29b2b-5867-4e94-813c-d38a065bb24c",
  "title": "Technical Round 1: NestJS Architecture & DB Optimization",
  "interviewType": "TECHNICAL",
  "scheduledAt": "2026-09-10T11:00:00.000Z",
  "durationMinutes": 45,
  "interviewerId": "u1d29b2b-5867-4e94-813c-d38a065bb24c",
  "locationOrLink": "https://meet.google.com/abc-defg-hij",
  "status": "SCHEDULED",
  "feedbackNotes": "Focus on concurrency, caching, and clean architecture"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-016 — List scheduled interviews

**بتعمل إيه؟**:
إدارة مواعيد ونتائج مقابلات التوظيف وتقييمات مسؤولي الأقسام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/interviews`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.getJobOpenings()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
List scheduled interviews. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `applicationId` | No | `string` | `` | Filter parameter: applicationId |
| `interviewerId` | No | `string` | `` | Filter parameter: interviewerId |
| `status` | No | `string` | `` | Filter parameter: status |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-017 — Get interview details and scorecard

**بتعمل إيه؟**:
إدارة مواعيد ونتائج مقابلات التوظيف وتقييمات مسؤولي الأقسام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/interviews/{id}`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.getJobOpenings()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Get interview details and scorecard. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-018 — Update interview time, meeting link, or status

**بتعمل إيه؟**:
إدارة مواعيد ونتائج مقابلات التوظيف وتقييمات مسؤولي الأقسام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/interviews/{id}`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.updateJobOpening()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Update interview time, meeting link, or status. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "applicationId": "a8d29b2b-5867-4e94-813c-d38a065bb24c",
  "title": "Technical Round 1: NestJS Architecture & DB Optimization",
  "interviewType": "TECHNICAL",
  "scheduledAt": "2026-09-10T11:00:00.000Z",
  "durationMinutes": 45,
  "interviewerId": "u1d29b2b-5867-4e94-813c-d38a065bb24c",
  "locationOrLink": "https://meet.google.com/abc-defg-hij",
  "status": "SCHEDULED",
  "feedbackNotes": "Focus on concurrency, caching, and clean architecture"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-019 — Submit structured interviewer scorecard and rating

**بتعمل إيه؟**:
جدولة موعد مقابلة شخصية أو اختبار فني لمرشح للوظيفة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/interviews/{id}/evaluations`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.createJobOpening()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Submit structured interviewer scorecard and rating. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "rating": 5,
  "recommendation": "STRONG_HIRE",
  "criteriaScores": {
    "technicalCompetence": 5,
    "systemDesign": 4,
    "communication": 5,
    "cultureFit": 5
  },
  "strengths": "Exceptional mastery of NestJS, async programming, and SQL query optimization",
  "weaknesses": "Limited experience with Kubernetes helm charts",
  "comments": "Strongly recommended for the Tech Lead position"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-020 — Generate job offer for candidate

**بتعمل إيه؟**:
إدارة دورة التوظيف واستقطاب الكفاءات الفندقية من مرحلة الإعلان حتى الاختيار.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/offers`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.createJobOpening()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Generate job offer for candidate. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "applicationId": "a8d29b2b-5867-4e94-813c-d38a065bb24c",
  "candidateId": "b1d29b2b-5867-4e94-813c-d38a065bb24c",
  "positionId": "e4d29b2b-5867-4e94-813c-d38a065bb24c",
  "departmentId": "c2d29b2b-5867-4e94-813c-d38a065bb24c",
  "offeredSalary": 40000,
  "currency": "EGP",
  "benefits": "Medical & Life insurance, flexible hours, annual bonus",
  "proposedStartDate": "2026-10-01",
  "status": "DRAFT",
  "terms": "Probation period of 3 months applies",
  "notes": "Offer approved by HR Director and VP of Engineering"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-021 — List all generated job offers

**بتعمل إيه؟**:
إدارة دورة التوظيف واستقطاب الكفاءات الفندقية من مرحلة الإعلان حتى الاختيار.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/offers`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.getJobOpenings()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
List all generated job offers. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `applicationId` | No | `string` | `` | Filter parameter: applicationId |
| `candidateId` | No | `string` | `` | Filter parameter: candidateId |
| `status` | No | `string` | `` | Filter parameter: status |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-022 — Get job offer terms and acceptance status

**بتعمل إيه؟**:
إدارة دورة التوظيف واستقطاب الكفاءات الفندقية من مرحلة الإعلان حتى الاختيار.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/offers/{id}`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.getJobOpenings()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Get job offer terms and acceptance status. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-023 — Update job offer details, status (SENT, ACCEPTED, REJECTED)

**بتعمل إيه؟**:
إدارة دورة التوظيف واستقطاب الكفاءات الفندقية من مرحلة الإعلان حتى الاختيار.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/offers/{id}`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.updateJobOpening()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Update job offer details, status (SENT, ACCEPTED, REJECTED). This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "applicationId": "a8d29b2b-5867-4e94-813c-d38a065bb24c",
  "candidateId": "b1d29b2b-5867-4e94-813c-d38a065bb24c",
  "positionId": "e4d29b2b-5867-4e94-813c-d38a065bb24c",
  "departmentId": "c2d29b2b-5867-4e94-813c-d38a065bb24c",
  "offeredSalary": 40000,
  "currency": "EGP",
  "benefits": "Medical & Life insurance, flexible hours, annual bonus",
  "proposedStartDate": "2026-10-01",
  "status": "DRAFT",
  "terms": "Probation period of 3 months applies",
  "notes": "Offer approved by HR Director and VP of Engineering"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REC-024 — Execute atomic hiring: Creates corporate user account, employee profile, links hierarchy & starts onboarding

**بتعمل إيه؟**:
إدارة دورة التوظيف واستقطاب الكفاءات الفندقية من مرحلة الإعلان حتى الاختيار.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/recruitment/hire`
- **Controller**: `RecruitmentController -> Roles()`
- **Service Execution**: `recruitmentService.createJobOpening()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `JobOpening`, `Candidate`, `Application`, `Interview`, `JobOffer`

**Purpose & Business Context**:
Execute atomic hiring: Creates corporate user account, employee profile, links hierarchy & starts onboarding. This endpoint operates with strict transactional integrity under the Recruitment & ATS subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "applicationId": "a8d29b2b-5867-4e94-813c-d38a065bb24c",
  "candidateId": "b1d29b2b-5867-4e94-813c-d38a065bb24c",
  "email": "ahmed.hassan@company.com",
  "password": "TemporarySecureP@ss123",
  "role": "EMPLOYEE",
  "employeeCode": "CW-2045",
  "organizationId": "a8d29b2b-5867-4e94-813c-d38a065bb24c",
  "branchId": "b1d29b2b-5867-4e94-813c-d38a065bb24c",
  "departmentId": "c2d29b2b-5867-4e94-813c-d38a065bb24c",
  "sectionId": "d3d29b2b-5867-4e94-813c-d38a065bb24c",
  "positionId": "e4d29b2b-5867-4e94-813c-d38a065bb24c",
  "managerId": "f5d29b2b-5867-4e94-813c-d38a065bb24c",
  "workplaceId": "16d29b2b-5867-4e94-813c-d38a065bb24c",
  "scheduleId": "27d29b2b-5867-4e94-813c-d38a065bb24c",
  "hireDate": "2026-10-01",
  "baseSalary": 40000,
  "initiateOnboarding": true
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Employee Onboarding

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **ONB-001** | `POST` | `/api/v1/onboarding/workflows` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Initialize an onboarding workflow and standard checklist |
| **ONB-002** | `GET` | `/api/v1/onboarding/workflows` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List and track all employee onboarding workflows |
| **ONB-003** | `GET` | `/api/v1/onboarding/workflows/my` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get current employee onboarding checklist and roadmap (Self-Service) |
| **ONB-004** | `GET` | `/api/v1/onboarding/workflows/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get onboarding workflow details with complete task list |
| **ONB-005** | `PATCH` | `/api/v1/onboarding/workflows/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Update onboarding workflow dates or status |
| **ONB-006** | `PATCH` | `/api/v1/onboarding/workflows/{id}/finalize` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Finalize employee onboarding and unlock full profile |
| **ONB-007** | `POST` | `/api/v1/onboarding/tasks` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Add a custom checklist task to an onboarding workflow |
| **ONB-008** | `PATCH` | `/api/v1/onboarding/tasks/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Update task metadata, category, or assignment |
| **ONB-009** | `DELETE` | `/api/v1/onboarding/tasks/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Delete an onboarding checklist task |
| **ONB-010** | `PATCH` | `/api/v1/onboarding/tasks/{id}/complete` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Complete or toggle onboarding task status |

### ONB-001 — Initialize an onboarding workflow and standard checklist

**بتعمل إيه؟**:
بدء خطة تهيئة موظف جديد (Onboarding) وتكليفه بقائمة المهام المطلوبة قبل مباشرة العمل.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/onboarding/workflows`
- **Controller**: `OnboardingController -> Roles()`
- **Service Execution**: `onboardingService.createWorkflow()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `OnboardingRoadmap`, `OnboardingTask`, `EmployeeProfile`

**Purpose & Business Context**:
Initialize an onboarding workflow and standard checklist. This endpoint operates with strict transactional integrity under the Employee Onboarding subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "employeeId": "a8d29b2b-5867-4e94-813c-d38a065bb24c",
  "startDate": "2026-09-01",
  "targetDate": "2026-10-01",
  "status": "PENDING"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ONB-002 — List and track all employee onboarding workflows

**بتعمل إيه؟**:
إدارة ومتابعة مراحل تهيئة وتسكين الموظفين الجدد في الأقسام الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/onboarding/workflows`
- **Controller**: `OnboardingController -> Roles()`
- **Service Execution**: `onboardingService.getWorkflows()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `OnboardingRoadmap`, `OnboardingTask`, `EmployeeProfile`

**Purpose & Business Context**:
List and track all employee onboarding workflows. This endpoint operates with strict transactional integrity under the Employee Onboarding subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `status` | No | `string` | `` | Filter parameter: status |
| `employeeId` | No | `string` | `` | Filter parameter: employeeId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ONB-003 — Get current employee onboarding checklist and roadmap (Self-Service)

**بتعمل إيه؟**:
إدارة ومتابعة مراحل تهيئة وتسكين الموظفين الجدد في الأقسام الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/onboarding/workflows/my`
- **Controller**: `OnboardingController -> Roles()`
- **Service Execution**: `onboardingService.getWorkflows()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `OnboardingRoadmap`, `OnboardingTask`, `EmployeeProfile`

**Purpose & Business Context**:
Get current employee onboarding checklist and roadmap (Self-Service). This endpoint operates with strict transactional integrity under the Employee Onboarding subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ONB-004 — Get onboarding workflow details with complete task list

**بتعمل إيه؟**:
إدارة ومتابعة مراحل تهيئة وتسكين الموظفين الجدد في الأقسام الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/onboarding/workflows/{id}`
- **Controller**: `OnboardingController -> Roles()`
- **Service Execution**: `onboardingService.getWorkflows()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `OnboardingRoadmap`, `OnboardingTask`, `EmployeeProfile`

**Purpose & Business Context**:
Get onboarding workflow details with complete task list. This endpoint operates with strict transactional integrity under the Employee Onboarding subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ONB-005 — Update onboarding workflow dates or status

**بتعمل إيه؟**:
إدارة ومتابعة مراحل تهيئة وتسكين الموظفين الجدد في الأقسام الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/onboarding/workflows/{id}`
- **Controller**: `OnboardingController -> Roles()`
- **Service Execution**: `onboardingService.updateWorkflow()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `OnboardingRoadmap`, `OnboardingTask`, `EmployeeProfile`

**Purpose & Business Context**:
Update onboarding workflow dates or status. This endpoint operates with strict transactional integrity under the Employee Onboarding subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "employeeId": "a8d29b2b-5867-4e94-813c-d38a065bb24c",
  "startDate": "2026-09-01",
  "targetDate": "2026-10-01",
  "status": "PENDING",
  "completedAt": "2026-09-20T14:30:00.000Z"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ONB-006 — Finalize employee onboarding and unlock full profile

**بتعمل إيه؟**:
إدارة ومتابعة مراحل تهيئة وتسكين الموظفين الجدد في الأقسام الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/onboarding/workflows/{id}/finalize`
- **Controller**: `OnboardingController -> Roles()`
- **Service Execution**: `onboardingService.updateWorkflow()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `OnboardingRoadmap`, `OnboardingTask`, `EmployeeProfile`

**Purpose & Business Context**:
Finalize employee onboarding and unlock full profile. This endpoint operates with strict transactional integrity under the Employee Onboarding subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ONB-007 — Add a custom checklist task to an onboarding workflow

**بتعمل إيه؟**:
بدء خطة تهيئة موظف جديد (Onboarding) وتكليفه بقائمة المهام المطلوبة قبل مباشرة العمل.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/onboarding/tasks`
- **Controller**: `OnboardingController -> Roles()`
- **Service Execution**: `onboardingService.createWorkflow()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `OnboardingRoadmap`, `OnboardingTask`, `EmployeeProfile`

**Purpose & Business Context**:
Add a custom checklist task to an onboarding workflow. This endpoint operates with strict transactional integrity under the Employee Onboarding subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "workflowId": "a8d29b2b-5867-4e94-813c-d38a065bb24c",
  "title": "Submit National ID Copy",
  "description": "Provide front and back scan of valid national identity card",
  "category": "DOCUMENTATION",
  "isMandatory": true,
  "assignedToUserId": "u1d29b2b-5867-4e94-813c-d38a065bb24c",
  "dueDate": "2026-09-15",
  "orderIndex": 1,
  "notes": "Must be reviewed by HR compliance officer"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ONB-008 — Update task metadata, category, or assignment

**بتعمل إيه؟**:
متابعة وإنجاز مهام تهيئة الموظف الجديد واستلام مسوغات التعيين والزي الرسمي.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/onboarding/tasks/{id}`
- **Controller**: `OnboardingController -> Roles()`
- **Service Execution**: `onboardingService.updateWorkflow()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `OnboardingRoadmap`, `OnboardingTask`, `EmployeeProfile`

**Purpose & Business Context**:
Update task metadata, category, or assignment. This endpoint operates with strict transactional integrity under the Employee Onboarding subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "workflowId": "a8d29b2b-5867-4e94-813c-d38a065bb24c",
  "title": "Submit National ID Copy",
  "description": "Provide front and back scan of valid national identity card",
  "category": "DOCUMENTATION",
  "isMandatory": true,
  "assignedToUserId": "u1d29b2b-5867-4e94-813c-d38a065bb24c",
  "dueDate": "2026-09-15",
  "orderIndex": 1,
  "notes": "Must be reviewed by HR compliance officer"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ONB-009 — Delete an onboarding checklist task

**بتعمل إيه؟**:
متابعة وإنجاز مهام تهيئة الموظف الجديد واستلام مسوغات التعيين والزي الرسمي.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/onboarding/tasks/{id}`
- **Controller**: `OnboardingController -> Roles()`
- **Service Execution**: `onboardingService.deleteTask()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `OnboardingRoadmap`, `OnboardingTask`, `EmployeeProfile`

**Purpose & Business Context**:
Delete an onboarding checklist task. This endpoint operates with strict transactional integrity under the Employee Onboarding subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ONB-010 — Complete or toggle onboarding task status

**بتعمل إيه؟**:
متابعة وإنجاز مهام تهيئة الموظف الجديد واستلام مسوغات التعيين والزي الرسمي.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/onboarding/tasks/{id}/complete`
- **Controller**: `OnboardingController -> Roles()`
- **Service Execution**: `onboardingService.updateWorkflow()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `OnboardingRoadmap`, `OnboardingTask`, `EmployeeProfile`

**Purpose & Business Context**:
Complete or toggle onboarding task status. This endpoint operates with strict transactional integrity under the Employee Onboarding subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "isCompleted": true,
  "notes": "Verified National ID copy physically on 2026-09-05"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Employees

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **EMP-001** | `GET` | `/api/v1/employees/me` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get current employee profile & onboarding status |
| **EMP-002** | `PATCH` | `/api/v1/employees/me/profile` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Complete employee initial onboarding profile |
| **EMP-003** | `GET` | `/api/v1/employees/me/workplace` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get assigned workplace & geofence parameters for current employee |
| **EMP-004** | `GET` | `/api/v1/employees/me/schedule` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get work schedule & server-time working hours for current employee |
| **EMP-005** | `POST` | `/api/v1/employees` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Create new employee profile & user account (HR Dashboard) |
| **EMP-006** | `GET` | `/api/v1/employees` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get paginated employee list |
| **EMP-007** | `GET` | `/api/v1/employees/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get employee details by profile ID |
| **EMP-008** | `PATCH` | `/api/v1/employees/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Update employee profile (HR Dashboard) |
| **EMP-009** | `DELETE` | `/api/v1/employees/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Delete employee profile & associated user |

### EMP-001 — Get current employee profile & onboarding status

**بتعمل إيه؟**:
عرض دليل وبنك بيانات موظفي الفندق مع إمكانية الفلترة بالفرع والقسم والحالة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/employees/me`
- **Controller**: `EmployeesController -> ApiOperation()`
- **Service Execution**: `employeesService.getMyProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `EmployeeProfile`, `User`, `Department`, `Position`, `Workplace`

**Purpose & Business Context**:
Get current employee profile & onboarding status. This endpoint operates with strict transactional integrity under the Employees subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Branch, Department, Position

---

### EMP-002 — Complete employee initial onboarding profile

**بتعمل إيه؟**:
تعديل البيانات الشخصية أو الوظيفية أو المصرفية للموظف.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/employees/me/profile`
- **Controller**: `EmployeesController -> ApiOperation()`
- **Service Execution**: `employeesService.completeProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `EmployeeProfile`, `User`, `Department`, `Position`, `Workplace`

**Purpose & Business Context**:
Complete employee initial onboarding profile. This endpoint operates with strict transactional integrity under the Employees subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "firstName": "Tariq",
  "lastName": "Zaid",
  "nationalId": "1098765432",
  "phone": "+966500000003",
  "jobTitle": "Software Engineer",
  "department": "Engineering",
  "workplaceId": "uuid-workplace-id",
  "gender": "MALE"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Branch, Department, Position

---

### EMP-003 — Get assigned workplace & geofence parameters for current employee

**بتعمل إيه؟**:
عرض دليل وبنك بيانات موظفي الفندق مع إمكانية الفلترة بالفرع والقسم والحالة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/employees/me/workplace`
- **Controller**: `EmployeesController -> ApiOperation()`
- **Service Execution**: `employeesService.getMyProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `EmployeeProfile`, `User`, `Department`, `Position`, `Workplace`

**Purpose & Business Context**:
Get assigned workplace & geofence parameters for current employee. This endpoint operates with strict transactional integrity under the Employees subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Branch, Department, Position

---

### EMP-004 — Get work schedule & server-time working hours for current employee

**بتعمل إيه؟**:
عرض دليل وبنك بيانات موظفي الفندق مع إمكانية الفلترة بالفرع والقسم والحالة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/employees/me/schedule`
- **Controller**: `EmployeesController -> ApiOperation()`
- **Service Execution**: `employeesService.getMyProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `EmployeeProfile`, `User`, `Department`, `Position`, `Workplace`

**Purpose & Business Context**:
Get work schedule & server-time working hours for current employee. This endpoint operates with strict transactional integrity under the Employees subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Branch, Department, Position

---

### EMP-005 — Create new employee profile & user account (HR Dashboard)

**بتعمل إيه؟**:
إضافة وتعيين موظف فندقي جديد في النظام وربطه بالفرع والقسم والمسمى الوظيفي.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/employees`
- **Controller**: `EmployeesController -> Roles()`
- **Service Execution**: `employeesService.create()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `EmployeeProfile`, `User`, `Department`, `Position`, `Workplace`

**Purpose & Business Context**:
Create new employee profile & user account (HR Dashboard). This endpoint operates with strict transactional integrity under the Employees subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "email": "employee@cyberwise.com",
  "password": "Emp@123456",
  "employeeCode": "CW-1001",
  "firstName": "Omar",
  "lastName": "Khalid",
  "phone": "+966501112233",
  "nationalId": "1098765432",
  "jobTitle": "Software Engineer",
  "department": "Engineering",
  "gender": "MALE",
  "role": "EMPLOYEE",
  "workplaceId": "uuid-workplace-id",
  "scheduleId": "uuid-schedule-id",
  "managerId": "uuid-manager-profile-id",
  "baseSalary": 8500
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### EMP-006 — Get paginated employee list

**بتعمل إيه؟**:
عرض دليل وبنك بيانات موظفي الفندق مع إمكانية الفلترة بالفرع والقسم والحالة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/employees`
- **Controller**: `EmployeesController -> ApiOperation()`
- **Service Execution**: `employeesService.getMyProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `EmployeeProfile`, `User`, `Department`, `Position`, `Workplace`

**Purpose & Business Context**:
Get paginated employee list. This endpoint operates with strict transactional integrity under the Employees subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### EMP-007 — Get employee details by profile ID

**بتعمل إيه؟**:
عرض دليل وبنك بيانات موظفي الفندق مع إمكانية الفلترة بالفرع والقسم والحالة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/employees/{id}`
- **Controller**: `EmployeesController -> ApiOperation()`
- **Service Execution**: `employeesService.getMyProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `EmployeeProfile`, `User`, `Department`, `Position`, `Workplace`

**Purpose & Business Context**:
Get employee details by profile ID. This endpoint operates with strict transactional integrity under the Employees subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Branch, Department, Position

---

### EMP-008 — Update employee profile (HR Dashboard)

**بتعمل إيه؟**:
تعديل البيانات الشخصية أو الوظيفية أو المصرفية للموظف.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/employees/{id}`
- **Controller**: `EmployeesController -> ApiOperation()`
- **Service Execution**: `employeesService.completeProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `EmployeeProfile`, `User`, `Department`, `Position`, `Workplace`

**Purpose & Business Context**:
Update employee profile (HR Dashboard). This endpoint operates with strict transactional integrity under the Employees subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "email": "employee@cyberwise.com",
  "password": "Emp@123456",
  "employeeCode": "CW-1001",
  "firstName": "Omar",
  "lastName": "Khalid",
  "phone": "+966501112233",
  "nationalId": "1098765432",
  "jobTitle": "Software Engineer",
  "department": "Engineering",
  "gender": "MALE",
  "role": "EMPLOYEE",
  "workplaceId": "uuid-workplace-id",
  "scheduleId": "uuid-schedule-id",
  "managerId": "uuid-manager-profile-id",
  "baseSalary": 8500
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Branch, Department, Position

---

### EMP-009 — Delete employee profile & associated user

**بتعمل إيه؟**:
إنهاء خدمة موظف وأرشفة سجله الوظيفي في النظام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/employees/{id}`
- **Controller**: `EmployeesController -> Roles()`
- **Service Execution**: `employeesService.remove()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `EmployeeProfile`, `User`, `Department`, `Position`, `Workplace`

**Purpose & Business Context**:
Delete employee profile & associated user. This endpoint operates with strict transactional integrity under the Employees subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Branch, Department, Position

---

## Workplaces

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **WKP-001** | `POST` | `/api/v1/workplaces` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Create a new workplace / branch |
| **WKP-002** | `GET` | `/api/v1/workplaces` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | List all active workplaces |
| **WKP-003** | `GET` | `/api/v1/workplaces/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Get workplace details including geofence |
| **WKP-004** | `PATCH` | `/api/v1/workplaces/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Update workplace settings & geofence |
| **WKP-005** | `DELETE` | `/api/v1/workplaces/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Delete workplace |

### WKP-001 — Create a new workplace / branch

**بتعمل إيه؟**:
تسجيل موقع عمل أو فرع فندقي جديد وتحديد إحداثيات الـ GPS ونصف قطر البصمة (Geofence).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/workplaces`
- **Controller**: `WorkplacesController -> Roles()`
- **Service Execution**: `workplacesService.create()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Workplace`, `Branch`, `Schedule`

**Purpose & Business Context**:
Create a new workplace / branch. This endpoint operates with strict transactional integrity under the Workplaces subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "name": "Riyadh HQ",
  "code": "RYD-01",
  "address": "King Fahd Road, Riyadh",
  "latitude": 24.7136,
  "longitude": 46.6753,
  "radiusMeters": 150,
  "wifiBssid": "aa:bb:cc:dd:ee:ff",
  "wifiIp": "192.168.1.1",
  "isActive": true
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### WKP-002 — List all active workplaces

**بتعمل إيه؟**:
استعراض قائمة مواقع العمل والفروع الفندقية ونطاقاتها الجغرافية المعتمدة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/workplaces`
- **Controller**: `WorkplacesController -> Roles()`
- **Service Execution**: `workplacesService.findAll()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Workplace`, `Branch`, `Schedule`

**Purpose & Business Context**:
List all active workplaces. This endpoint operates with strict transactional integrity under the Workplaces subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### WKP-003 — Get workplace details including geofence

**بتعمل إيه؟**:
استعراض قائمة مواقع العمل والفروع الفندقية ونطاقاتها الجغرافية المعتمدة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/workplaces/{id}`
- **Controller**: `WorkplacesController -> Roles()`
- **Service Execution**: `workplacesService.findAll()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Workplace`, `Branch`, `Schedule`

**Purpose & Business Context**:
Get workplace details including geofence. This endpoint operates with strict transactional integrity under the Workplaces subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### WKP-004 — Update workplace settings & geofence

**بتعمل إيه؟**:
تعديل إحداثيات الموقع أو نطاق الـ Geofence المسموح بتسجيل الحضور داخله.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/workplaces/{id}`
- **Controller**: `WorkplacesController -> Roles()`
- **Service Execution**: `workplacesService.update()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Workplace`, `Branch`, `Schedule`

**Purpose & Business Context**:
Update workplace settings & geofence. This endpoint operates with strict transactional integrity under the Workplaces subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "name": "Riyadh HQ",
  "code": "RYD-01",
  "address": "King Fahd Road, Riyadh",
  "latitude": 24.7136,
  "longitude": 46.6753,
  "radiusMeters": 150,
  "wifiBssid": "aa:bb:cc:dd:ee:ff",
  "wifiIp": "192.168.1.1",
  "isActive": true
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### WKP-005 — Delete workplace

**بتعمل إيه؟**:
حذف أو تعطيل موقع عمل من النظام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/workplaces/{id}`
- **Controller**: `WorkplacesController -> Roles()`
- **Service Execution**: `workplacesService.remove()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Workplace`, `Branch`, `Schedule`

**Purpose & Business Context**:
Delete workplace. This endpoint operates with strict transactional integrity under the Workplaces subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Attendance & Workforce Operations

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **ATT-001** | `POST` | `/api/v1/attendance/check-in` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Register employee check-in with GPS evidence & security signals |
| **ATT-002** | `POST` | `/api/v1/attendance/check-out` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Register employee check-out with GPS evidence & duration calculations |
| **ATT-003** | `GET` | `/api/v1/attendance/today` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get current authenticated employee attendance status for today |
| **ATT-004** | `GET` | `/api/v1/attendance/me` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get personal attendance history for current employee (supports month/date filters) |
| **ATT-005** | `GET` | `/api/v1/attendance/history` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Backward-compatible personal attendance history |
| **ATT-006** | `POST` | `/api/v1/attendance/manual` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR Manual Attendance Adjustment / Creation with mandatory reason |
| **ATT-007** | `GET` | `/api/v1/attendance/employee/{employeeId}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR Query: Get specific employee attendance records |
| **ATT-008** | `GET` | `/api/v1/attendance/workplace/{workplaceId}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR Query: Get attendance records for a specific workplace/branch |
| **ATT-009** | `GET` | `/api/v1/attendance/department/{department}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR Query: Get attendance records for a specific department |
| **ATT-010** | `GET` | `/api/v1/attendance/records` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR General Query: List attendance records across company |

### ATT-001 — Register employee check-in with GPS evidence & security signals

**بتعمل إيه؟**:
تسجيل حركة حضور الموظف بالبصمة الجغرافية مع التحقق الصارم من موقع الـ GPS داخل النطاق المسموح به لمقر العمل (Geofence).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/attendance/check-in`
- **Controller**: `AttendanceController -> ApiOperation()`
- **Service Execution**: `attendanceService.checkIn()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `AttendanceRecord`, `AttendanceEvent`, `Workplace`, `Schedule`

**Purpose & Business Context**:
Register employee check-in with GPS evidence & security signals. This endpoint operates with strict transactional integrity under the Attendance & Workforce Operations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "latitude": 24.7136,
  "longitude": 46.6753,
  "accuracy": 12.5,
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "method": "GPS",
  "biometricVerified": true,
  "isMockLocation": true,
  "isVpn": true,
  "isJailbroken": true,
  "wifiBssid": "sample-uuid-v4",
  "notes": "sample_notes"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile
- Assigned Workplace Geofence
- Assigned Schedule

---

### ATT-002 — Register employee check-out with GPS evidence & duration calculations

**بتعمل إيه؟**:
تسجيل حركة انصراف الموظف واحتساب ساعات العمل الفعلية وساعات العمل الإضافية (Overtime) آلياً.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/attendance/check-out`
- **Controller**: `AttendanceController -> ApiOperation()`
- **Service Execution**: `attendanceService.checkIn()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `AttendanceRecord`, `AttendanceEvent`, `Workplace`, `Schedule`

**Purpose & Business Context**:
Register employee check-out with GPS evidence & duration calculations. This endpoint operates with strict transactional integrity under the Attendance & Workforce Operations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "latitude": 24.7136,
  "longitude": 46.6753,
  "accuracy": 15,
  "requestId": "550e8400-e29b-41d4-a716-446655440001",
  "method": "GPS",
  "biometricVerified": true,
  "isMockLocation": true,
  "isVpn": true,
  "isJailbroken": true,
  "notes": "sample_notes"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile
- Assigned Workplace Geofence
- Assigned Schedule

---

### ATT-003 — Get current authenticated employee attendance status for today

**بتعمل إيه؟**:
جلب سجلات وبيانات الحضور والانصراف مع الفلاتر الزمنية والوظيفية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/attendance/today`
- **Controller**: `AttendanceController -> ApiOperation()`
- **Service Execution**: `attendanceService.getTodayStatus()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `AttendanceRecord`, `AttendanceEvent`, `Workplace`, `Schedule`

**Purpose & Business Context**:
Get current authenticated employee attendance status for today. This endpoint operates with strict transactional integrity under the Attendance & Workforce Operations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ATT-004 — Get personal attendance history for current employee (supports month/date filters)

**بتعمل إيه؟**:
جلب سجلات وبيانات الحضور والانصراف مع الفلاتر الزمنية والوظيفية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/attendance/me`
- **Controller**: `AttendanceController -> ApiOperation()`
- **Service Execution**: `attendanceService.getTodayStatus()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `AttendanceRecord`, `AttendanceEvent`, `Workplace`, `Schedule`

**Purpose & Business Context**:
Get personal attendance history for current employee (supports month/date filters). This endpoint operates with strict transactional integrity under the Attendance & Workforce Operations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Filter by start date (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | Filter by end date (YYYY-MM-DD) |
| `month` | No | `string` | `` | Filter by Year-Month (YYYY-MM) |
| `status` | No | `string` | `` | Filter by attendance status |
| `workplaceId` | No | `string` | `` | Filter by workplace ID |
| `department` | No | `string` | `` | Filter by department name |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `30` | Filter parameter: limit |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ATT-005 — Backward-compatible personal attendance history

**بتعمل إيه؟**:
استعراض سجل حركات الحضور والانصراف التفصيلية للموظفين خلال فترة زمنية محددة مع خيارات الفلترة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/attendance/history`
- **Controller**: `AttendanceController -> ApiOperation()`
- **Service Execution**: `attendanceService.getTodayStatus()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `AttendanceRecord`, `AttendanceEvent`, `Workplace`, `Schedule`

**Purpose & Business Context**:
Backward-compatible personal attendance history. This endpoint operates with strict transactional integrity under the Attendance & Workforce Operations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Filter by start date (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | Filter by end date (YYYY-MM-DD) |
| `month` | No | `string` | `` | Filter by Year-Month (YYYY-MM) |
| `status` | No | `string` | `` | Filter by attendance status |
| `workplaceId` | No | `string` | `` | Filter by workplace ID |
| `department` | No | `string` | `` | Filter by department name |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `30` | Filter parameter: limit |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ATT-006 — HR Manual Attendance Adjustment / Creation with mandatory reason

**بتعمل إيه؟**:
إدارة وتسجيل ومتابعة عمليات الحضور والانصراف وانضباط القوى العاملة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/attendance/manual`
- **Controller**: `AttendanceController -> ApiOperation()`
- **Service Execution**: `attendanceService.checkIn()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `AttendanceRecord`, `AttendanceEvent`, `Workplace`, `Schedule`

**Purpose & Business Context**:
HR Manual Attendance Adjustment / Creation with mandatory reason. This endpoint operates with strict transactional integrity under the Attendance & Workforce Operations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "employeeId": "uuid-employee-profile-id",
  "date": "2026-08-20",
  "status": "PRESENT",
  "checkInTime": "2026-08-20T09:00:00.000Z",
  "checkOutTime": "2026-08-20T17:00:00.000Z",
  "reason": "Biometric device offline during morning shift / field mission approved"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ATT-007 — HR Query: Get specific employee attendance records

**بتعمل إيه؟**:
جلب سجلات وبيانات الحضور والانصراف مع الفلاتر الزمنية والوظيفية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/attendance/employee/{employeeId}`
- **Controller**: `AttendanceController -> ApiOperation()`
- **Service Execution**: `attendanceService.getTodayStatus()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `AttendanceRecord`, `AttendanceEvent`, `Workplace`, `Schedule`

**Purpose & Business Context**:
HR Query: Get specific employee attendance records. This endpoint operates with strict transactional integrity under the Attendance & Workforce Operations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `employeeId` | `string` | `id-12345` | Identifier parameter: employeeId |

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Filter by start date (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | Filter by end date (YYYY-MM-DD) |
| `month` | No | `string` | `` | Filter by Year-Month (YYYY-MM) |
| `status` | No | `string` | `` | Filter by attendance status |
| `workplaceId` | No | `string` | `` | Filter by workplace ID |
| `department` | No | `string` | `` | Filter by department name |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `30` | Filter parameter: limit |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ATT-008 — HR Query: Get attendance records for a specific workplace/branch

**بتعمل إيه؟**:
جلب سجلات وبيانات الحضور والانصراف مع الفلاتر الزمنية والوظيفية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/attendance/workplace/{workplaceId}`
- **Controller**: `AttendanceController -> ApiOperation()`
- **Service Execution**: `attendanceService.getTodayStatus()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `AttendanceRecord`, `AttendanceEvent`, `Workplace`, `Schedule`

**Purpose & Business Context**:
HR Query: Get attendance records for a specific workplace/branch. This endpoint operates with strict transactional integrity under the Attendance & Workforce Operations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `workplaceId` | `string` | `id-12345` | Identifier parameter: workplaceId |

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Filter by start date (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | Filter by end date (YYYY-MM-DD) |
| `month` | No | `string` | `` | Filter by Year-Month (YYYY-MM) |
| `status` | No | `string` | `` | Filter by attendance status |
| `workplaceId` | No | `string` | `` | Filter by workplace ID |
| `department` | No | `string` | `` | Filter by department name |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `30` | Filter parameter: limit |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ATT-009 — HR Query: Get attendance records for a specific department

**بتعمل إيه؟**:
جلب سجلات وبيانات الحضور والانصراف مع الفلاتر الزمنية والوظيفية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/attendance/department/{department}`
- **Controller**: `AttendanceController -> ApiOperation()`
- **Service Execution**: `attendanceService.getTodayStatus()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `AttendanceRecord`, `AttendanceEvent`, `Workplace`, `Schedule`

**Purpose & Business Context**:
HR Query: Get attendance records for a specific department. This endpoint operates with strict transactional integrity under the Attendance & Workforce Operations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `department` | `string` | `id-12345` | Identifier parameter: department |

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Filter by start date (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | Filter by end date (YYYY-MM-DD) |
| `month` | No | `string` | `` | Filter by Year-Month (YYYY-MM) |
| `status` | No | `string` | `` | Filter by attendance status |
| `workplaceId` | No | `string` | `` | Filter by workplace ID |
| `department` | No | `string` | `` | Filter by department name |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `30` | Filter parameter: limit |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ATT-010 — HR General Query: List attendance records across company

**بتعمل إيه؟**:
جلب سجلات وبيانات الحضور والانصراف مع الفلاتر الزمنية والوظيفية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/attendance/records`
- **Controller**: `AttendanceController -> ApiOperation()`
- **Service Execution**: `attendanceService.getTodayStatus()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `AttendanceRecord`, `AttendanceEvent`, `Workplace`, `Schedule`

**Purpose & Business Context**:
HR General Query: List attendance records across company. This endpoint operates with strict transactional integrity under the Attendance & Workforce Operations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | **Yes** | `string` | `` | Filter parameter: startDate |
| `endDate` | **Yes** | `string` | `` | Filter parameter: endDate |
| `workplaceId` | **Yes** | `string` | `` | Filter parameter: workplaceId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Workforce Operations & Analytics

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **WFO-001** | `GET` | `/api/v1/workforce/live-status` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get real-time live presence dashboard for today (checked in, not checked in, late, on leave) |
| **WFO-002** | `GET` | `/api/v1/workforce/statistics` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get consolidated attendance & workforce statistics (attendance rate, total work hours, overtime, late) |
| **WFO-003** | `GET` | `/api/v1/workforce/summary` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get daily / periodic aggregated attendance trends with pagination |
| **WFO-004** | `GET` | `/api/v1/workforce/departments` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get department-level workforce distribution, attendance rates, and hours |
| **WFO-005** | `GET` | `/api/v1/workforce/workplaces` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get workplace/branch-level workforce distribution and performance metrics |
| **WFO-006** | `GET` | `/api/v1/workforce/absent-employees` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Identify employees scheduled to work on a date who have no check-in and no approved leave |
| **WFO-007** | `POST` | `/api/v1/workforce/mark-absent` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Batch/auto mark identified absent employees with audit trail recording |
| **WFO-008** | `GET` | `/api/v1/workforce/overtime-summary` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get top overtime workers and total overtime hours within period |

### WFO-001 — Get real-time live presence dashboard for today (checked in, not checked in, late, on leave)

**بتعمل إيه؟**:
شاشة متابعة الحضور اللحظية في الفندق لمعرفة المتواجدين على رأس العمل والمتأخرين والغائبين الآن.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/workforce/live-status`
- **Controller**: `WorkforceController -> ApiOperation()`
- **Service Execution**: `workforceService.getLiveStatus()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `AttendanceRecord`, `EmployeeProfile`, `Department`

**Purpose & Business Context**:
Get real-time live presence dashboard for today (checked in, not checked in, late, on leave). This endpoint operates with strict transactional integrity under the Workforce Operations & Analytics subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `date` | No | `string` | `` | Specific target date (YYYY-MM-DD). Defaults to today if not range. |
| `startDate` | No | `string` | `` | Range start date (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | Range end date (YYYY-MM-DD) |
| `month` | No | `string` | `` | Filter by Year-Month (YYYY-MM) |
| `workplaceId` | No | `string` | `` | Filter by Workplace ID |
| `department` | No | `string` | `` | Filter by Department name |
| `status` | No | `string` | `` | Filter by specific status |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `30` | Filter parameter: limit |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### WFO-002 — Get consolidated attendance & workforce statistics (attendance rate, total work hours, overtime, late)

**بتعمل إيه؟**:
جلب سجلات وبيانات الحضور والانصراف مع الفلاتر الزمنية والوظيفية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/workforce/statistics`
- **Controller**: `WorkforceController -> ApiOperation()`
- **Service Execution**: `workforceService.getLiveStatus()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `AttendanceRecord`, `EmployeeProfile`, `Department`

**Purpose & Business Context**:
Get consolidated attendance & workforce statistics (attendance rate, total work hours, overtime, late). This endpoint operates with strict transactional integrity under the Workforce Operations & Analytics subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `date` | No | `string` | `` | Specific target date (YYYY-MM-DD). Defaults to today if not range. |
| `startDate` | No | `string` | `` | Range start date (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | Range end date (YYYY-MM-DD) |
| `month` | No | `string` | `` | Filter by Year-Month (YYYY-MM) |
| `workplaceId` | No | `string` | `` | Filter by Workplace ID |
| `department` | No | `string` | `` | Filter by Department name |
| `status` | No | `string` | `` | Filter by specific status |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `30` | Filter parameter: limit |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### WFO-003 — Get daily / periodic aggregated attendance trends with pagination

**بتعمل إيه؟**:
استخراج إحصائيات ومعدلات الحضور ونسب الانضباط والغياب الشهرية والأسبوعية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/workforce/summary`
- **Controller**: `WorkforceController -> ApiOperation()`
- **Service Execution**: `workforceService.getLiveStatus()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `AttendanceRecord`, `EmployeeProfile`, `Department`

**Purpose & Business Context**:
Get daily / periodic aggregated attendance trends with pagination. This endpoint operates with strict transactional integrity under the Workforce Operations & Analytics subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `date` | No | `string` | `` | Specific target date (YYYY-MM-DD). Defaults to today if not range. |
| `startDate` | No | `string` | `` | Range start date (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | Range end date (YYYY-MM-DD) |
| `month` | No | `string` | `` | Filter by Year-Month (YYYY-MM) |
| `workplaceId` | No | `string` | `` | Filter by Workplace ID |
| `department` | No | `string` | `` | Filter by Department name |
| `status` | No | `string` | `` | Filter by specific status |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `30` | Filter parameter: limit |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### WFO-004 — Get department-level workforce distribution, attendance rates, and hours

**بتعمل إيه؟**:
جلب سجلات وبيانات الحضور والانصراف مع الفلاتر الزمنية والوظيفية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/workforce/departments`
- **Controller**: `WorkforceController -> ApiOperation()`
- **Service Execution**: `workforceService.getLiveStatus()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `AttendanceRecord`, `EmployeeProfile`, `Department`

**Purpose & Business Context**:
Get department-level workforce distribution, attendance rates, and hours. This endpoint operates with strict transactional integrity under the Workforce Operations & Analytics subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `date` | No | `string` | `` | Specific target date (YYYY-MM-DD). Defaults to today if not range. |
| `startDate` | No | `string` | `` | Range start date (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | Range end date (YYYY-MM-DD) |
| `month` | No | `string` | `` | Filter by Year-Month (YYYY-MM) |
| `workplaceId` | No | `string` | `` | Filter by Workplace ID |
| `department` | No | `string` | `` | Filter by Department name |
| `status` | No | `string` | `` | Filter by specific status |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `30` | Filter parameter: limit |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Organization (ORG-001)

---

### WFO-005 — Get workplace/branch-level workforce distribution and performance metrics

**بتعمل إيه؟**:
جلب سجلات وبيانات الحضور والانصراف مع الفلاتر الزمنية والوظيفية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/workforce/workplaces`
- **Controller**: `WorkforceController -> ApiOperation()`
- **Service Execution**: `workforceService.getLiveStatus()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `AttendanceRecord`, `EmployeeProfile`, `Department`

**Purpose & Business Context**:
Get workplace/branch-level workforce distribution and performance metrics. This endpoint operates with strict transactional integrity under the Workforce Operations & Analytics subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `date` | No | `string` | `` | Specific target date (YYYY-MM-DD). Defaults to today if not range. |
| `startDate` | No | `string` | `` | Range start date (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | Range end date (YYYY-MM-DD) |
| `month` | No | `string` | `` | Filter by Year-Month (YYYY-MM) |
| `workplaceId` | No | `string` | `` | Filter by Workplace ID |
| `department` | No | `string` | `` | Filter by Department name |
| `status` | No | `string` | `` | Filter by specific status |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `30` | Filter parameter: limit |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### WFO-006 — Identify employees scheduled to work on a date who have no check-in and no approved leave

**بتعمل إيه؟**:
جلب سجلات وبيانات الحضور والانصراف مع الفلاتر الزمنية والوظيفية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/workforce/absent-employees`
- **Controller**: `WorkforceController -> ApiOperation()`
- **Service Execution**: `workforceService.getLiveStatus()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `AttendanceRecord`, `EmployeeProfile`, `Department`

**Purpose & Business Context**:
Identify employees scheduled to work on a date who have no check-in and no approved leave. This endpoint operates with strict transactional integrity under the Workforce Operations & Analytics subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `date` | **Yes** | `string` | `` | Filter parameter: date |
| `workplaceId` | **Yes** | `string` | `` | Filter parameter: workplaceId |
| `department` | **Yes** | `string` | `` | Filter parameter: department |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### WFO-007 — Batch/auto mark identified absent employees with audit trail recording

**بتعمل إيه؟**:
إدارة وتسجيل ومتابعة عمليات الحضور والانصراف وانضباط القوى العاملة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/workforce/mark-absent`
- **Controller**: `WorkforceController -> Roles()`
- **Service Execution**: `workforceService.markAbsences()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `AttendanceRecord`, `EmployeeProfile`, `Department`

**Purpose & Business Context**:
Batch/auto mark identified absent employees with audit trail recording. This endpoint operates with strict transactional integrity under the Workforce Operations & Analytics subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "date": "2026-09-02",
  "employeeIds": [
    "emp-uuid-1",
    "emp-uuid-2"
  ],
  "reason": "System auto-absence detection for unexcused missed shift"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### WFO-008 — Get top overtime workers and total overtime hours within period

**بتعمل إيه؟**:
جلب سجلات وبيانات الحضور والانصراف مع الفلاتر الزمنية والوظيفية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/workforce/overtime-summary`
- **Controller**: `WorkforceController -> ApiOperation()`
- **Service Execution**: `workforceService.getLiveStatus()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `AttendanceRecord`, `EmployeeProfile`, `Department`

**Purpose & Business Context**:
Get top overtime workers and total overtime hours within period. This endpoint operates with strict transactional integrity under the Workforce Operations & Analytics subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `date` | No | `string` | `` | Specific target date (YYYY-MM-DD). Defaults to today if not range. |
| `startDate` | No | `string` | `` | Range start date (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | Range end date (YYYY-MM-DD) |
| `month` | No | `string` | `` | Filter by Year-Month (YYYY-MM) |
| `workplaceId` | No | `string` | `` | Filter by Workplace ID |
| `department` | No | `string` | `` | Filter by Department name |
| `status` | No | `string` | `` | Filter by specific status |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `30` | Filter parameter: limit |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Schedules

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **SCH-001** | `POST` | `/api/v1/schedules` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Create a new shift schedule |
| **SCH-002** | `GET` | `/api/v1/schedules` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | List all active shift schedules |
| **SCH-003** | `GET` | `/api/v1/schedules/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Get schedule details |
| **SCH-004** | `PATCH` | `/api/v1/schedules/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Update schedule timings |
| **SCH-005** | `DELETE` | `/api/v1/schedules/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Delete schedule |

### SCH-001 — Create a new shift schedule

**بتعمل إيه؟**:
إنشاء نمط وردية جديد (صباحية، مسائية، ليلية) مع تحديد ساعات البداية والنهاية وفترة السماح.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/schedules`
- **Controller**: `SchedulesController -> Roles()`
- **Service Execution**: `schedulesService.create()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Schedule`, `Workplace`, `EmployeeProfile`

**Purpose & Business Context**:
Create a new shift schedule. This endpoint operates with strict transactional integrity under the Schedules subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "name": "Standard Morning Shift",
  "description": "Regular 9 to 5 working shift",
  "workplaceId": "c7b5f92a-3e81-49a6-8c54-1b1e9d123456",
  "startTime": "09:00",
  "endTime": "17:00",
  "graceMinutesCheckIn": 15,
  "graceMinutesCheckOut": 15,
  "workingDays": [
    0,
    1,
    2,
    3,
    4
  ],
  "isDefault": false
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SCH-002 — List all active shift schedules

**بتعمل إيه؟**:
استعراض جميع جداول الورديات المعتمدة ومواعيد العمل في الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/schedules`
- **Controller**: `SchedulesController -> Roles()`
- **Service Execution**: `schedulesService.findAll()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Schedule`, `Workplace`, `EmployeeProfile`

**Purpose & Business Context**:
List all active shift schedules. This endpoint operates with strict transactional integrity under the Schedules subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SCH-003 — Get schedule details

**بتعمل إيه؟**:
استعراض جميع جداول الورديات المعتمدة ومواعيد العمل في الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/schedules/{id}`
- **Controller**: `SchedulesController -> Roles()`
- **Service Execution**: `schedulesService.findAll()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Schedule`, `Workplace`, `EmployeeProfile`

**Purpose & Business Context**:
Get schedule details. This endpoint operates with strict transactional integrity under the Schedules subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SCH-004 — Update schedule timings

**بتعمل إيه؟**:
تعديل مواعيد الوردية أو فترة السماح أو ساعات الراحة لجدول عمل.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/schedules/{id}`
- **Controller**: `SchedulesController -> Roles()`
- **Service Execution**: `schedulesService.update()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Schedule`, `Workplace`, `EmployeeProfile`

**Purpose & Business Context**:
Update schedule timings. This endpoint operates with strict transactional integrity under the Schedules subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "name": "Standard Morning Shift",
  "description": "Regular 9 to 5 working shift",
  "workplaceId": "c7b5f92a-3e81-49a6-8c54-1b1e9d123456",
  "startTime": "09:00",
  "endTime": "17:00",
  "graceMinutesCheckIn": 15,
  "graceMinutesCheckOut": 15,
  "workingDays": [
    0,
    1,
    2,
    3,
    4
  ],
  "isDefault": false
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SCH-005 — Delete schedule

**بتعمل إيه؟**:
إلغاء أو حذف جدول ورديات من النظام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/schedules/{id}`
- **Controller**: `SchedulesController -> Roles()`
- **Service Execution**: `schedulesService.remove()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Schedule`, `Workplace`, `EmployeeProfile`

**Purpose & Business Context**:
Delete schedule. This endpoint operates with strict transactional integrity under the Schedules subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Workflows

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **WFL-001** | `POST` | `/api/v1/workflows` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Create a new approval workflow definition |
| **WFL-002** | `GET` | `/api/v1/workflows` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List workflows with filtering and pagination |
| **WFL-003** | `POST` | `/api/v1/workflows/match-preview` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Preview/Simulate workflow matching for a given request criteria |
| **WFL-004** | `GET` | `/api/v1/workflows/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get workflow definition by ID |
| **WFL-005** | `PATCH` | `/api/v1/workflows/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Update workflow definition |
| **WFL-006** | `DELETE` | `/api/v1/workflows/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Delete workflow definition |

### WFL-001 — Create a new approval workflow definition

**بتعمل إيه؟**:
تصميم وتعريف مسار عمل وموافقات إدارية جديد (Workflow) للطلبات والعمليات الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/workflows`
- **Controller**: `WorkflowController -> Roles()`
- **Service Execution**: `workflowService.create()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `WorkflowDefinition`, `WorkflowStep`, `WorkflowInstance`

**Purpose & Business Context**:
Create a new approval workflow definition. This endpoint operates with strict transactional integrity under the Workflows subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "name": "Standard Leave Approval Workflow",
  "description": "Two-stage approval: Direct Manager -> HR Manager",
  "requestType": "ANNUAL_LEAVE",
  "organizationId": "org-uuid-v4",
  "departmentId": "dept-uuid-v4",
  "role": "EMPLOYEE",
  "minDays": 1,
  "maxDays": 14,
  "minAmount": 1000,
  "maxAmount": 10000,
  "priority": 10,
  "isActive": true,
  "isDefault": false,
  "steps": []
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### WFL-002 — List workflows with filtering and pagination

**بتعمل إيه؟**:
استعراض قائمة مسارات العمل ودورات الموافقات المعتمدة في النظام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/workflows`
- **Controller**: `WorkflowController -> Roles()`
- **Service Execution**: `workflowService.findAll()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `WorkflowDefinition`, `WorkflowStep`, `WorkflowInstance`

**Purpose & Business Context**:
List workflows with filtering and pagination. This endpoint operates with strict transactional integrity under the Workflows subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `requestType` | No | `string` | `` | Filter parameter: requestType |
| `departmentId` | No | `string` | `` | Filter parameter: departmentId |
| `role` | No | `string` | `` | Filter parameter: role |
| `isActive` | No | `boolean` | `` | Filter parameter: isActive |
| `search` | No | `string` | `` | Filter parameter: search |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### WFL-003 — Preview/Simulate workflow matching for a given request criteria

**بتعمل إيه؟**:
تصميم وتعريف مسار عمل وموافقات إدارية جديد (Workflow) للطلبات والعمليات الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/workflows/match-preview`
- **Controller**: `WorkflowController -> Roles()`
- **Service Execution**: `workflowService.create()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `WorkflowDefinition`, `WorkflowStep`, `WorkflowInstance`

**Purpose & Business Context**:
Preview/Simulate workflow matching for a given request criteria. This endpoint operates with strict transactional integrity under the Workflows subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### WFL-004 — Get workflow definition by ID

**بتعمل إيه؟**:
استعراض قائمة مسارات العمل ودورات الموافقات المعتمدة في النظام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/workflows/{id}`
- **Controller**: `WorkflowController -> Roles()`
- **Service Execution**: `workflowService.findAll()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `WorkflowDefinition`, `WorkflowStep`, `WorkflowInstance`

**Purpose & Business Context**:
Get workflow definition by ID. This endpoint operates with strict transactional integrity under the Workflows subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Workflow UUID |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### WFL-005 — Update workflow definition

**بتعمل إيه؟**:
تعديل مستويات وسلسلة الموافقات في مسار عمل محدد.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/workflows/{id}`
- **Controller**: `WorkflowController -> Roles()`
- **Service Execution**: `workflowService.update()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `WorkflowDefinition`, `WorkflowStep`, `WorkflowInstance`

**Purpose & Business Context**:
Update workflow definition. This endpoint operates with strict transactional integrity under the Workflows subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Workflow UUID |

**Request Body Payload**:
```json
{
  "name": "Standard Leave Approval Workflow",
  "description": "Two-stage approval: Direct Manager -> HR Manager",
  "requestType": "ANNUAL_LEAVE",
  "organizationId": "org-uuid-v4",
  "departmentId": "dept-uuid-v4",
  "role": "EMPLOYEE",
  "minDays": 1,
  "maxDays": 14,
  "minAmount": 1000,
  "maxAmount": 10000,
  "priority": 10,
  "isActive": true,
  "isDefault": false,
  "steps": []
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### WFL-006 — Delete workflow definition

**بتعمل إيه؟**:
حذف مسار عمل إداري من النظام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/workflows/{id}`
- **Controller**: `WorkflowController -> Roles()`
- **Service Execution**: `workflowService.remove()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `WorkflowDefinition`, `WorkflowStep`, `WorkflowInstance`

**Purpose & Business Context**:
Delete workflow definition. This endpoint operates with strict transactional integrity under the Workflows subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Workflow UUID |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Approvals

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **APR-001** | `GET` | `/api/v1/approvals/pending` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +4 | Get pending requests awaiting review by current user (as Direct Manager, Dept Head, Role, or Delegate) |
| **APR-002** | `POST` | `/api/v1/approvals/{requestId}/action` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +4 | Process approval, rejection, or delegation for current active workflow step |
| **APR-003** | `GET` | `/api/v1/approvals/history/{requestId}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +4 | Get full approval history and step progression audit trail for a request |
| **APR-004** | `POST` | `/api/v1/approvals/delegations` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +4 | Delegate approval authority to another user for a temporary period |
| **APR-005** | `GET` | `/api/v1/approvals/delegations` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +4 | List active and historical delegations for current user |
| **APR-006** | `PATCH` | `/api/v1/approvals/delegations/{id}/revoke` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +4 | Revoke an active delegation before its expiration |

### APR-001 — Get pending requests awaiting review by current user (as Direct Manager, Dept Head, Role, or Delegate)

**بتعمل إيه؟**:
جلب قائمة الطلبات المعلقة التي تنتظر موافقة أو توقيع المستخدم الحالي.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE, 

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/approvals/pending`
- **Controller**: `ApprovalsController -> ApiOperation()`
- **Service Execution**: `approvalsService.getPendingApprovals()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`, `EMPLOYEE`, ``
- **Test Priority**: **P0**
- **Prisma Database Entities**: `ApprovalRequest`, `ApprovalStep`, `ApprovalHistory`

**Purpose & Business Context**:
Get pending requests awaiting review by current user (as Direct Manager, Dept Head, Role, or Delegate). This endpoint operates with strict transactional integrity under the Approvals subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `requestType` | No | `string` | `` | Filter parameter: requestType |
| `employeeId` | No | `string` | `` | Filter parameter: employeeId |
| `startDate` | No | `string` | `` | Filter parameter: startDate |
| `endDate` | No | `string` | `` | Filter parameter: endDate |
| `search` | No | `string` | `` | Filter parameter: search |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE, ]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### APR-002 — Process approval, rejection, or delegation for current active workflow step

**بتعمل إيه؟**:
إدارة عمليات مراجعة واعتماد طلبات الموظفين والأعمال الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE, 

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/approvals/{requestId}/action`
- **Controller**: `ApprovalsController -> HttpCode()`
- **Service Execution**: `approvalsService.processApprovalStep()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`, `EMPLOYEE`, ``
- **Test Priority**: **P0**
- **Prisma Database Entities**: `ApprovalRequest`, `ApprovalStep`, `ApprovalHistory`

**Purpose & Business Context**:
Process approval, rejection, or delegation for current active workflow step. This endpoint operates with strict transactional integrity under the Approvals subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `requestId` | `string` | `id-12345` | Request UUID |

**Request Body Payload**:
```json
{
  "action": "APPROVE",
  "comment": "Approved after reviewing team availability and project deadlines.",
  "rejectionReason": "Insufficient sprint coverage during production release."
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation error or duplicate approval
- `403 Error`: Forbidden: Not authorized for this step
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### APR-003 — Get full approval history and step progression audit trail for a request

**بتعمل إيه؟**:
استعراض سجل الموافقات والاعتمادات السابقة وحالاتها وملاحظات المديرين.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE, 

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/approvals/history/{requestId}`
- **Controller**: `ApprovalsController -> ApiOperation()`
- **Service Execution**: `approvalsService.getPendingApprovals()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`, `EMPLOYEE`, ``
- **Test Priority**: **P0**
- **Prisma Database Entities**: `ApprovalRequest`, `ApprovalStep`, `ApprovalHistory`

**Purpose & Business Context**:
Get full approval history and step progression audit trail for a request. This endpoint operates with strict transactional integrity under the Approvals subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `requestId` | `string` | `id-12345` | Request UUID |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE, ]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### APR-004 — Delegate approval authority to another user for a temporary period

**بتعمل إيه؟**:
إدارة عمليات مراجعة واعتماد طلبات الموظفين والأعمال الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE, 

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/approvals/delegations`
- **Controller**: `ApprovalsController -> HttpCode()`
- **Service Execution**: `approvalsService.processApprovalStep()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`, `EMPLOYEE`, ``
- **Test Priority**: **P0**
- **Prisma Database Entities**: `ApprovalRequest`, `ApprovalStep`, `ApprovalHistory`

**Purpose & Business Context**:
Delegate approval authority to another user for a temporary period. This endpoint operates with strict transactional integrity under the Approvals subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "delegateId": "user-uuid-to-delegate-to",
  "requestType": "ANNUAL_LEAVE",
  "startDate": "2026-09-01",
  "endDate": "2026-09-15",
  "reason": "Delegating manager approval duties during annual vacation."
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE, ]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### APR-005 — List active and historical delegations for current user

**بتعمل إيه؟**:
استعراض سجل الموافقات والاعتمادات السابقة وحالاتها وملاحظات المديرين.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE, 

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/approvals/delegations`
- **Controller**: `ApprovalsController -> ApiOperation()`
- **Service Execution**: `approvalsService.getPendingApprovals()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`, `EMPLOYEE`, ``
- **Test Priority**: **P0**
- **Prisma Database Entities**: `ApprovalRequest`, `ApprovalStep`, `ApprovalHistory`

**Purpose & Business Context**:
List active and historical delegations for current user. This endpoint operates with strict transactional integrity under the Approvals subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE, ]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### APR-006 — Revoke an active delegation before its expiration

**بتعمل إيه؟**:
إدارة عمليات مراجعة واعتماد طلبات الموظفين والأعمال الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE, 

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/approvals/delegations/{id}/revoke`
- **Controller**: `ApprovalsController -> ApiOperation()`
- **Service Execution**: `approvalsService.revokeDelegation()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`, `EMPLOYEE`, ``
- **Test Priority**: **P0**
- **Prisma Database Entities**: `ApprovalRequest`, `ApprovalStep`, `ApprovalHistory`

**Purpose & Business Context**:
Revoke an active delegation before its expiration. This endpoint operates with strict transactional integrity under the Approvals subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Delegation UUID |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE, ]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Notifications & In-App Alerts

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **NOTIF-001** | `POST` | `/api/v1/notifications/device-token` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Register/Refresh FCM device token for push notifications |
| **NOTIF-002** | `DELETE` | `/api/v1/notifications/device-token/{fcmToken}` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Unregister/Deactivate device token on logout |
| **NOTIF-003** | `GET` | `/api/v1/notifications` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Get current user notifications with pagination & filters |
| **NOTIF-004** | `GET` | `/api/v1/notifications/my` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Get current user notifications (alias) |
| **NOTIF-005** | `GET` | `/api/v1/notifications/unread-count` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Get count of unread in-app notifications |
| **NOTIF-006** | `POST` | `/api/v1/notifications/{id}/read` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Mark single notification as read |
| **NOTIF-007** | `PATCH` | `/api/v1/notifications/{id}/read` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Mark single notification as read (PATCH alias) |
| **NOTIF-008** | `POST` | `/api/v1/notifications/read-all` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Mark all notifications as read in bulk |
| **NOTIF-009** | `PATCH` | `/api/v1/notifications/read-all` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Mark all notifications as read in bulk (PATCH alias) |
| **NOTIF-010** | `GET` | `/api/v1/notifications/preferences` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Get user notification channel preferences |
| **NOTIF-011** | `PATCH` | `/api/v1/notifications/preferences` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Update user notification channel preferences |

### NOTIF-001 — Register/Refresh FCM device token for push notifications

**بتعمل إيه؟**:
إرسال تنبيه أو إشعار فوري لموظف أو مجموعة موظفين داخل التطبيق.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/notifications/device-token`
- **Controller**: `NotificationsController -> ApiOperation()`
- **Service Execution**: `notificationsService.registerDeviceToken()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Notification`, `DeviceToken`, `User`

**Purpose & Business Context**:
Register/Refresh FCM device token for push notifications. This endpoint operates with strict transactional integrity under the Notifications & In-App Alerts subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "fcmToken": "sample_fcmToken",
  "platform": "ANDROID",
  "deviceId": "sample-uuid-v4"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### NOTIF-002 — Unregister/Deactivate device token on logout

**بتعمل إيه؟**:
جلب واستعراض قائمة الإشعارات والتنبيهات الخاصة بالموظف وحالاتها.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/notifications/device-token/{fcmToken}`
- **Controller**: `NotificationsController -> HttpCode()`
- **Service Execution**: `notificationsService.removeDeviceToken()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Notification`, `DeviceToken`, `User`

**Purpose & Business Context**:
Unregister/Deactivate device token on logout. This endpoint operates with strict transactional integrity under the Notifications & In-App Alerts subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `fcmToken` | `string` | `id-12345` | Identifier parameter: fcmToken |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### NOTIF-003 — Get current user notifications with pagination & filters

**بتعمل إيه؟**:
جلب واستعراض قائمة الإشعارات والتنبيهات الخاصة بالموظف وحالاتها.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/notifications`
- **Controller**: `NotificationsController -> ApiOperation()`
- **Service Execution**: `notificationsService.getMyNotifications()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Notification`, `DeviceToken`, `User`

**Purpose & Business Context**:
Get current user notifications with pagination & filters. This endpoint operates with strict transactional integrity under the Notifications & In-App Alerts subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `type` | No | `string` | `` | Filter notifications by category/type |
| `priority` | No | `string` | `` | Filter notifications by priority |
| `isRead` | No | `boolean` | `` | Filter read (true) or unread (false) notifications |
| `startDate` | No | `string` | `` | Filter notifications created on or after this date |
| `endDate` | No | `string` | `` | Filter notifications created on or before this date |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### NOTIF-004 — Get current user notifications (alias)

**بتعمل إيه؟**:
جلب واستعراض قائمة الإشعارات والتنبيهات الخاصة بالموظف وحالاتها.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/notifications/my`
- **Controller**: `NotificationsController -> ApiOperation()`
- **Service Execution**: `notificationsService.getMyNotifications()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Notification`, `DeviceToken`, `User`

**Purpose & Business Context**:
Get current user notifications (alias). This endpoint operates with strict transactional integrity under the Notifications & In-App Alerts subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `type` | No | `string` | `` | Filter notifications by category/type |
| `priority` | No | `string` | `` | Filter notifications by priority |
| `isRead` | No | `boolean` | `` | Filter read (true) or unread (false) notifications |
| `startDate` | No | `string` | `` | Filter notifications created on or after this date |
| `endDate` | No | `string` | `` | Filter notifications created on or before this date |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### NOTIF-005 — Get count of unread in-app notifications

**بتعمل إيه؟**:
جلب واستعراض قائمة الإشعارات والتنبيهات الخاصة بالموظف وحالاتها.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/notifications/unread-count`
- **Controller**: `NotificationsController -> ApiOperation()`
- **Service Execution**: `notificationsService.getMyNotifications()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Notification`, `DeviceToken`, `User`

**Purpose & Business Context**:
Get count of unread in-app notifications. This endpoint operates with strict transactional integrity under the Notifications & In-App Alerts subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### NOTIF-006 — Mark single notification as read

**بتعمل إيه؟**:
تحديث حالة الإشعار إلى (تمت القراءة) للمستخدم الحالي.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/notifications/{id}/read`
- **Controller**: `NotificationsController -> ApiOperation()`
- **Service Execution**: `notificationsService.registerDeviceToken()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Notification`, `DeviceToken`, `User`

**Purpose & Business Context**:
Mark single notification as read. This endpoint operates with strict transactional integrity under the Notifications & In-App Alerts subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### NOTIF-007 — Mark single notification as read (PATCH alias)

**بتعمل إيه؟**:
تحديث حالة الإشعار إلى (تمت القراءة) للمستخدم الحالي.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/notifications/{id}/read`
- **Controller**: `NotificationsController -> ApiOperation()`
- **Service Execution**: `notificationsService.markAsRead()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Notification`, `DeviceToken`, `User`

**Purpose & Business Context**:
Mark single notification as read (PATCH alias). This endpoint operates with strict transactional integrity under the Notifications & In-App Alerts subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### NOTIF-008 — Mark all notifications as read in bulk

**بتعمل إيه؟**:
تحديث حالة الإشعار إلى (تمت القراءة) للمستخدم الحالي.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/notifications/read-all`
- **Controller**: `NotificationsController -> ApiOperation()`
- **Service Execution**: `notificationsService.registerDeviceToken()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Notification`, `DeviceToken`, `User`

**Purpose & Business Context**:
Mark all notifications as read in bulk. This endpoint operates with strict transactional integrity under the Notifications & In-App Alerts subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### NOTIF-009 — Mark all notifications as read in bulk (PATCH alias)

**بتعمل إيه؟**:
تحديث حالة الإشعار إلى (تمت القراءة) للمستخدم الحالي.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/notifications/read-all`
- **Controller**: `NotificationsController -> ApiOperation()`
- **Service Execution**: `notificationsService.markAsRead()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Notification`, `DeviceToken`, `User`

**Purpose & Business Context**:
Mark all notifications as read in bulk (PATCH alias). This endpoint operates with strict transactional integrity under the Notifications & In-App Alerts subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### NOTIF-010 — Get user notification channel preferences

**بتعمل إيه؟**:
جلب واستعراض قائمة الإشعارات والتنبيهات الخاصة بالموظف وحالاتها.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/notifications/preferences`
- **Controller**: `NotificationsController -> ApiOperation()`
- **Service Execution**: `notificationsService.getMyNotifications()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Notification`, `DeviceToken`, `User`

**Purpose & Business Context**:
Get user notification channel preferences. This endpoint operates with strict transactional integrity under the Notifications & In-App Alerts subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### NOTIF-011 — Update user notification channel preferences

**بتعمل إيه؟**:
جلب واستعراض قائمة الإشعارات والتنبيهات الخاصة بالموظف وحالاتها.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/notifications/preferences`
- **Controller**: `NotificationsController -> ApiOperation()`
- **Service Execution**: `notificationsService.markAsRead()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Notification`, `DeviceToken`, `User`

**Purpose & Business Context**:
Update user notification channel preferences. This endpoint operates with strict transactional integrity under the Notifications & In-App Alerts subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "attendanceNotifications": true,
  "requestNotifications": true,
  "payrollNotifications": true,
  "advanceNotifications": true,
  "announcementNotifications": true,
  "messageNotifications": true,
  "taskNotifications": true,
  "emailNotifications": true,
  "pushNotifications": true
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## HR Announcements & Broadcasts

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **ANN-001** | `POST` | `/api/v1/announcements` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR: Create a company or department announcement |
| **ANN-002** | `GET` | `/api/v1/announcements` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get announcements visible to current user (or all if HR) |
| **ANN-003** | `GET` | `/api/v1/announcements/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | View announcement details (auto-marks as read) |
| **ANN-004** | `POST` | `/api/v1/announcements/{id}/publish` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR: Publish announcement and broadcast notifications |
| **ANN-005** | `POST` | `/api/v1/announcements/{id}/cancel` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR: Cancel an announcement |
| **ANN-006** | `POST` | `/api/v1/announcements/{id}/read` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Mark announcement as read by employee |

### ANN-001 — HR: Create a company or department announcement

**بتعمل إيه؟**:
نشر تعميم أو إعلان إداري جديد لموظفي الفندق مع تحديد الفروع المستهدفة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/announcements`
- **Controller**: `AnnouncementsController -> Roles()`
- **Service Execution**: `announcementsService.createAnnouncement()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Announcement`, `User`, `Department`

**Purpose & Business Context**:
HR: Create a company or department announcement. This endpoint operates with strict transactional integrity under the HR Announcements & Broadcasts subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "title": "Annual Company Gathering & Strategy Kickoff 2026",
  "body": "We are excited to invite all team members to our annual celebration this Thursday...",
  "priority": "NORMAL",
  "targetType": "ALL",
  "targetDepartment": "Engineering",
  "targetWorkplaceId": "workplace-uuid-1",
  "targetEmployeeIds": [
    "emp-1",
    "emp-2"
  ],
  "expiresAt": "2026-12-31T23:59:59Z",
  "publishNow": false
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ANN-002 — Get announcements visible to current user (or all if HR)

**بتعمل إيه؟**:
استعراض الإعلانات والتعميمات الإدارية الصادرة من إدارة الموارد البشرية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/announcements`
- **Controller**: `AnnouncementsController -> ApiOperation()`
- **Service Execution**: `announcementsService.getAnnouncements()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Announcement`, `User`, `Department`

**Purpose & Business Context**:
Get announcements visible to current user (or all if HR). This endpoint operates with strict transactional integrity under the HR Announcements & Broadcasts subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `status` | No | `string` | `` | Filter announcements by status (DRAFT, PUBLISHED, EXPIRED, CANCELLED) |
| `targetType` | No | `string` | `` | Filter by audience target type |
| `department` | No | `string` | `` | Filter by department |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ANN-003 — View announcement details (auto-marks as read)

**بتعمل إيه؟**:
استعراض الإعلانات والتعميمات الإدارية الصادرة من إدارة الموارد البشرية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/announcements/{id}`
- **Controller**: `AnnouncementsController -> ApiOperation()`
- **Service Execution**: `announcementsService.getAnnouncements()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Announcement`, `User`, `Department`

**Purpose & Business Context**:
View announcement details (auto-marks as read). This endpoint operates with strict transactional integrity under the HR Announcements & Broadcasts subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ANN-004 — HR: Publish announcement and broadcast notifications

**بتعمل إيه؟**:
نشر تعميم أو إعلان إداري جديد لموظفي الفندق مع تحديد الفروع المستهدفة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/announcements/{id}/publish`
- **Controller**: `AnnouncementsController -> Roles()`
- **Service Execution**: `announcementsService.createAnnouncement()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Announcement`, `User`, `Department`

**Purpose & Business Context**:
HR: Publish announcement and broadcast notifications. This endpoint operates with strict transactional integrity under the HR Announcements & Broadcasts subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ANN-005 — HR: Cancel an announcement

**بتعمل إيه؟**:
نشر تعميم أو إعلان إداري جديد لموظفي الفندق مع تحديد الفروع المستهدفة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/announcements/{id}/cancel`
- **Controller**: `AnnouncementsController -> Roles()`
- **Service Execution**: `announcementsService.createAnnouncement()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Announcement`, `User`, `Department`

**Purpose & Business Context**:
HR: Cancel an announcement. This endpoint operates with strict transactional integrity under the HR Announcements & Broadcasts subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### ANN-006 — Mark announcement as read by employee

**بتعمل إيه؟**:
نشر تعميم أو إعلان إداري جديد لموظفي الفندق مع تحديد الفروع المستهدفة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/announcements/{id}/read`
- **Controller**: `AnnouncementsController -> Roles()`
- **Service Execution**: `announcementsService.createAnnouncement()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Announcement`, `User`, `Department`

**Purpose & Business Context**:
Mark announcement as read by employee. This endpoint operates with strict transactional integrity under the HR Announcements & Broadcasts subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Requests

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **REQ-001** | `POST` | `/api/v1/requests` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Submit a new request (Leave, Absence, Permission, Late Excuse, Early Leave, Half Day, etc.) |
| **REQ-002** | `GET` | `/api/v1/requests` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | HR: Filtered and paginated queue of employee requests (status, department, workplace, dates) |
| **REQ-003** | `GET` | `/api/v1/requests/me` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get paginated submitted requests for current employee |
| **REQ-004** | `GET` | `/api/v1/requests/my-requests` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Alias: Get submitted requests for current employee |
| **REQ-005** | `GET` | `/api/v1/requests/leave-balances/me` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get current year leave balances and remaining days for current employee |
| **REQ-006** | `GET` | `/api/v1/requests/leave-balances/employee/{employeeId}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | HR: Get leave balances for a specific employee |
| **REQ-007** | `POST` | `/api/v1/requests/leave-balances` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | HR: Allocate / Initialize new leave balance for an employee |
| **REQ-008** | `PATCH` | `/api/v1/requests/leave-balances/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | HR: Adjust total or used days on an existing leave balance |
| **REQ-009** | `GET` | `/api/v1/requests/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get request details with approval history (IDOR protected: Owner or HR) |
| **REQ-010** | `POST` | `/api/v1/requests/{id}/cancel` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Employee: Cancel a pending request |
| **REQ-011** | `PATCH` | `/api/v1/requests/{id}/cancel` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Employee: Cancel a pending request (PATCH method) |
| **REQ-012** | `POST` | `/api/v1/requests/{id}/approve` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | HR: Approve an employee request (updates leave balance, attendance records, audit & notification) |
| **REQ-013** | `PATCH` | `/api/v1/requests/{id}/approve` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | HR: Approve an employee request (PATCH method) |
| **REQ-014** | `POST` | `/api/v1/requests/{id}/reject` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | HR: Reject an employee request with mandatory reason |
| **REQ-015** | `PATCH` | `/api/v1/requests/{id}/reject` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | HR: Reject an employee request with mandatory reason (PATCH method) |

### REQ-001 — Submit a new request (Leave, Absence, Permission, Late Excuse, Early Leave, Half Day, etc.)

**بتعمل إيه؟**:
تقديم طلب موظف جديد (إجازة سنوية/مرضية، إذن خروج ساعي، عمل عن بعد، سلفة مالية، بدل إضافي).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/requests`
- **Controller**: `RequestsController -> ApiOperation()`
- **Service Execution**: `requestsService.create()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Request`, `WorkflowInstance`, `EmployeeProfile`

**Purpose & Business Context**:
Submit a new request (Leave, Absence, Permission, Late Excuse, Early Leave, Half Day, etc.). This endpoint operates with strict transactional integrity under the Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "type": "ANNUAL_LEAVE",
  "startDate": "2026-09-01",
  "endDate": "2026-09-05",
  "startTime": "10:00",
  "endTime": "12:00",
  "halfDayPeriod": "FIRST_HALF",
  "reason": "Annual family vacation / Personal medical appointment",
  "attachmentUrl": "https://storage.cyberwise.com/attachments/medical_report.pdf",
  "idempotencyKey": "req_idempotency_uuid_v4_12345",
  "metadata": {
    "targetAttendanceDate": "2026-09-01",
    "estimatedHours": 2
  }
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation error or insufficient leave balance
- `403 Error`: Forbidden for inactive employees
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### REQ-002 — HR: Filtered and paginated queue of employee requests (status, department, workplace, dates)

**بتعمل إيه؟**:
استعراض قائمة طلبات الموظفين مع إمكانية الفلترة بنوع الطلب وحالته والتاريخ.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/requests`
- **Controller**: `RequestsController -> ApiOperation()`
- **Service Execution**: `requestsService.findMyRequests()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Request`, `WorkflowInstance`, `EmployeeProfile`

**Purpose & Business Context**:
HR: Filtered and paginated queue of employee requests (status, department, workplace, dates). This endpoint operates with strict transactional integrity under the Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `status` | No | `string` | `` | Filter by request status (PENDING, APPROVED, REJECTED, CANCELLED) |
| `type` | No | `string` | `` | Filter by request type |
| `employeeId` | No | `string` | `` | Filter by specific Employee Profile ID (HR only) |
| `department` | No | `string` | `` | Filter by employee department (HR only) |
| `workplaceId` | No | `string` | `` | Filter by workplace / branch ID (HR only) |
| `startDate` | No | `string` | `` | Filter requests active on or after this date |
| `endDate` | No | `string` | `` | Filter requests active on or before this date |
| `sortBy` | No | `string` | `createdAt` | Field to sort results by |
| `sortOrder` | No | `string` | `desc` | Sort order direction |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### REQ-003 — Get paginated submitted requests for current employee

**بتعمل إيه؟**:
استعراض قائمة طلبات الموظفين مع إمكانية الفلترة بنوع الطلب وحالته والتاريخ.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/requests/me`
- **Controller**: `RequestsController -> ApiOperation()`
- **Service Execution**: `requestsService.findMyRequests()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Request`, `WorkflowInstance`, `EmployeeProfile`

**Purpose & Business Context**:
Get paginated submitted requests for current employee. This endpoint operates with strict transactional integrity under the Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `status` | No | `string` | `` | Filter by request status (PENDING, APPROVED, REJECTED, CANCELLED) |
| `type` | No | `string` | `` | Filter by request type |
| `employeeId` | No | `string` | `` | Filter by specific Employee Profile ID (HR only) |
| `department` | No | `string` | `` | Filter by employee department (HR only) |
| `workplaceId` | No | `string` | `` | Filter by workplace / branch ID (HR only) |
| `startDate` | No | `string` | `` | Filter requests active on or after this date |
| `endDate` | No | `string` | `` | Filter requests active on or before this date |
| `sortBy` | No | `string` | `createdAt` | Field to sort results by |
| `sortOrder` | No | `string` | `desc` | Sort order direction |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### REQ-004 — Alias: Get submitted requests for current employee

**بتعمل إيه؟**:
استعراض قائمة طلبات الموظفين مع إمكانية الفلترة بنوع الطلب وحالته والتاريخ.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/requests/my-requests`
- **Controller**: `RequestsController -> ApiOperation()`
- **Service Execution**: `requestsService.findMyRequests()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Request`, `WorkflowInstance`, `EmployeeProfile`

**Purpose & Business Context**:
Alias: Get submitted requests for current employee. This endpoint operates with strict transactional integrity under the Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `status` | No | `string` | `` | Filter by request status (PENDING, APPROVED, REJECTED, CANCELLED) |
| `type` | No | `string` | `` | Filter by request type |
| `employeeId` | No | `string` | `` | Filter by specific Employee Profile ID (HR only) |
| `department` | No | `string` | `` | Filter by employee department (HR only) |
| `workplaceId` | No | `string` | `` | Filter by workplace / branch ID (HR only) |
| `startDate` | No | `string` | `` | Filter requests active on or after this date |
| `endDate` | No | `string` | `` | Filter requests active on or before this date |
| `sortBy` | No | `string` | `createdAt` | Field to sort results by |
| `sortOrder` | No | `string` | `desc` | Sort order direction |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### REQ-005 — Get current year leave balances and remaining days for current employee

**بتعمل إيه؟**:
استعراض قائمة طلبات الموظفين مع إمكانية الفلترة بنوع الطلب وحالته والتاريخ.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/requests/leave-balances/me`
- **Controller**: `RequestsController -> ApiOperation()`
- **Service Execution**: `requestsService.findMyRequests()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Request`, `WorkflowInstance`, `EmployeeProfile`

**Purpose & Business Context**:
Get current year leave balances and remaining days for current employee. This endpoint operates with strict transactional integrity under the Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `year` | No | `number` | `` | Filter parameter: year |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### REQ-006 — HR: Get leave balances for a specific employee

**بتعمل إيه؟**:
استعراض قائمة طلبات الموظفين مع إمكانية الفلترة بنوع الطلب وحالته والتاريخ.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/requests/leave-balances/employee/{employeeId}`
- **Controller**: `RequestsController -> ApiOperation()`
- **Service Execution**: `requestsService.findMyRequests()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Request`, `WorkflowInstance`, `EmployeeProfile`

**Purpose & Business Context**:
HR: Get leave balances for a specific employee. This endpoint operates with strict transactional integrity under the Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `employeeId` | `string` | `id-12345` | Employee Profile UUID |

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `year` | No | `number` | `` | Filter parameter: year |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### REQ-007 — HR: Allocate / Initialize new leave balance for an employee

**بتعمل إيه؟**:
تقديم طلب موظف جديد (إجازة سنوية/مرضية، إذن خروج ساعي، عمل عن بعد، سلفة مالية، بدل إضافي).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/requests/leave-balances`
- **Controller**: `RequestsController -> ApiOperation()`
- **Service Execution**: `requestsService.create()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Request`, `WorkflowInstance`, `EmployeeProfile`

**Purpose & Business Context**:
HR: Allocate / Initialize new leave balance for an employee. This endpoint operates with strict transactional integrity under the Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "employeeId": "emp-profile-uuid-1234",
  "leaveType": "ANNUAL_LEAVE",
  "year": 2026,
  "totalDays": 21
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### REQ-008 — HR: Adjust total or used days on an existing leave balance

**بتعمل إيه؟**:
تعديل بيانات طلب معلق قبل اعتماده.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/requests/leave-balances/{id}`
- **Controller**: `RequestsController -> Roles()`
- **Service Execution**: `requestsService.adjustLeaveBalance()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Request`, `WorkflowInstance`, `EmployeeProfile`

**Purpose & Business Context**:
HR: Adjust total or used days on an existing leave balance. This endpoint operates with strict transactional integrity under the Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | LeaveBalance UUID |

**Request Body Payload**:
```json
{
  "totalDays": 25,
  "usedDays": 2,
  "reason": "Annual bonus leave adjustment (+4 days)"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### REQ-009 — Get request details with approval history (IDOR protected: Owner or HR)

**بتعمل إيه؟**:
استعراض قائمة طلبات الموظفين مع إمكانية الفلترة بنوع الطلب وحالته والتاريخ.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/requests/{id}`
- **Controller**: `RequestsController -> ApiOperation()`
- **Service Execution**: `requestsService.findMyRequests()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Request`, `WorkflowInstance`, `EmployeeProfile`

**Purpose & Business Context**:
Get request details with approval history (IDOR protected: Owner or HR). This endpoint operates with strict transactional integrity under the Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Request UUID |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### REQ-010 — Employee: Cancel a pending request

**بتعمل إيه؟**:
تقديم طلب موظف جديد (إجازة سنوية/مرضية، إذن خروج ساعي، عمل عن بعد، سلفة مالية، بدل إضافي).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/requests/{id}/cancel`
- **Controller**: `RequestsController -> ApiOperation()`
- **Service Execution**: `requestsService.create()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Request`, `WorkflowInstance`, `EmployeeProfile`

**Purpose & Business Context**:
Employee: Cancel a pending request. This endpoint operates with strict transactional integrity under the Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Request UUID |

**Request Body Payload**:
```json
{
  "reason": "Plans changed, no longer required."
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### REQ-011 — Employee: Cancel a pending request (PATCH method)

**بتعمل إيه؟**:
إلغاء طلب معلق بواسطة الموظف قبل اتخاذ إجراء الاعتماد عليه.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/requests/{id}/cancel`
- **Controller**: `RequestsController -> Roles()`
- **Service Execution**: `requestsService.adjustLeaveBalance()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Request`, `WorkflowInstance`, `EmployeeProfile`

**Purpose & Business Context**:
Employee: Cancel a pending request (PATCH method). This endpoint operates with strict transactional integrity under the Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Request UUID |

**Request Body Payload**:
```json
{
  "reason": "Plans changed, no longer required."
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### REQ-012 — HR: Approve an employee request (updates leave balance, attendance records, audit & notification)

**بتعمل إيه؟**:
تقديم طلب موظف جديد (إجازة سنوية/مرضية، إذن خروج ساعي، عمل عن بعد، سلفة مالية، بدل إضافي).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/requests/{id}/approve`
- **Controller**: `RequestsController -> ApiOperation()`
- **Service Execution**: `requestsService.create()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Request`, `WorkflowInstance`, `EmployeeProfile`

**Purpose & Business Context**:
HR: Approve an employee request (updates leave balance, attendance records, audit & notification). This endpoint operates with strict transactional integrity under the Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Request UUID |

**Request Body Payload**:
```json
{
  "comment": "Approved based on departmental staffing coverage."
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### REQ-013 — HR: Approve an employee request (PATCH method)

**بتعمل إيه؟**:
تعديل بيانات طلب معلق قبل اعتماده.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/requests/{id}/approve`
- **Controller**: `RequestsController -> Roles()`
- **Service Execution**: `requestsService.adjustLeaveBalance()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Request`, `WorkflowInstance`, `EmployeeProfile`

**Purpose & Business Context**:
HR: Approve an employee request (PATCH method). This endpoint operates with strict transactional integrity under the Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Request UUID |

**Request Body Payload**:
```json
{
  "comment": "Approved based on departmental staffing coverage."
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### REQ-014 — HR: Reject an employee request with mandatory reason

**بتعمل إيه؟**:
تقديم طلب موظف جديد (إجازة سنوية/مرضية، إذن خروج ساعي، عمل عن بعد، سلفة مالية، بدل إضافي).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/requests/{id}/reject`
- **Controller**: `RequestsController -> ApiOperation()`
- **Service Execution**: `requestsService.create()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Request`, `WorkflowInstance`, `EmployeeProfile`

**Purpose & Business Context**:
HR: Reject an employee request with mandatory reason. This endpoint operates with strict transactional integrity under the Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Request UUID |

**Request Body Payload**:
```json
{
  "reason": "Insufficient project coverage during sprint release window."
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### REQ-015 — HR: Reject an employee request with mandatory reason (PATCH method)

**بتعمل إيه؟**:
تعديل بيانات طلب معلق قبل اعتماده.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/requests/{id}/reject`
- **Controller**: `RequestsController -> Roles()`
- **Service Execution**: `requestsService.adjustLeaveBalance()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Request`, `WorkflowInstance`, `EmployeeProfile`

**Purpose & Business Context**:
HR: Reject an employee request with mandatory reason (PATCH method). This endpoint operates with strict transactional integrity under the Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Request UUID |

**Request Body Payload**:
```json
{
  "reason": "Insufficient project coverage during sprint release window."
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

## Payroll, Salary Advances & Deductions

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **PAY-001** | `GET` | `/api/v1/payroll/salary/me` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Employee: View my current salary profile |
| **PAY-002** | `GET` | `/api/v1/payroll/salary/employee/{employeeId}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR: View salary profile for specific employee |
| **PAY-003** | `POST` | `/api/v1/payroll/salary` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR: Set or update employee salary profile (with history versioning) |
| **PAY-004** | `GET` | `/api/v1/payroll/salary/history/{employeeId}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR: View salary modification history for employee |
| **PAY-005** | `POST` | `/api/v1/payroll/advances` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Employee: Request a salary advance |
| **PAY-006** | `GET` | `/api/v1/payroll/advances` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR: List and filter all salary advance requests |
| **PAY-007** | `GET` | `/api/v1/payroll/advances/me` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Employee: View my salary advance requests & installment schedule |
| **PAY-008** | `GET` | `/api/v1/payroll/advances/my` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Employee: View my salary advances (alias) |
| **PAY-009** | `GET` | `/api/v1/payroll/advances/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | View detailed salary advance with installment schedule |
| **PAY-010** | `POST` | `/api/v1/payroll/advances/{id}/approve` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR: Approve salary advance and generate installment schedule |
| **PAY-011** | `POST` | `/api/v1/payroll/advances/{id}/reject` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR: Reject salary advance with mandatory reason |
| **PAY-012** | `POST` | `/api/v1/payroll/advances/installments/{installmentId}/pay` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR / Finance: Record payment towards an advance installment |
| **PAY-013** | `POST` | `/api/v1/payroll/deductions` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR: Create manual financial deduction or penalty |
| **PAY-014** | `GET` | `/api/v1/payroll/deductions` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR: List and filter all financial deductions |
| **PAY-015** | `GET` | `/api/v1/payroll/deductions/me` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Employee: View my deductions |
| **PAY-016** | `GET` | `/api/v1/payroll/deductions/my` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Employee: View my deductions (alias) |
| **PAY-017** | `POST` | `/api/v1/payroll/periods` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR: Create a new monthly payroll period |
| **PAY-018** | `GET` | `/api/v1/payroll/periods` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR: List all payroll periods |
| **PAY-019** | `POST` | `/api/v1/payroll/periods/{id}/calculate` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR: Run calculation engine for payroll period |
| **PAY-020** | `POST` | `/api/v1/payroll/periods/{id}/finalize` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR / Finance: Finalize and lock payroll period |
| **PAY-021** | `GET` | `/api/v1/payroll/me` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Employee: View my monthly payroll payslips |
| **PAY-022** | `GET` | `/api/v1/payroll/records/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | View detailed payslip with itemized line items |
| **PAY-023** | `POST` | `/api/v1/payroll/records/{id}/adjust` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR: Create post-finalization adjustment for payroll record |
| **PAY-024** | `GET` | `/api/v1/payroll` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR: List and filter all employee payroll records |

### PAY-001 — Employee: View my current salary profile

**بتعمل إيه؟**:
جلب كشوف وبيانات الرواتب ودورات الدفع الشهرية للمؤسسة الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/payroll/salary/me`
- **Controller**: `PayrollController -> ApiOperation()`
- **Service Execution**: `payrollService.getSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
Employee: View my current salary profile. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-002 — HR: View salary profile for specific employee

**بتعمل إيه؟**:
جلب كشوف وبيانات الرواتب ودورات الدفع الشهرية للمؤسسة الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/payroll/salary/employee/{employeeId}`
- **Controller**: `PayrollController -> ApiOperation()`
- **Service Execution**: `payrollService.getSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
HR: View salary profile for specific employee. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `employeeId` | `string` | `id-12345` | Identifier parameter: employeeId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-003 — HR: Set or update employee salary profile (with history versioning)

**بتعمل إيه؟**:
إدارة مسيرات الرواتب والسلف المالية والاستقطاعات للموظفين.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/payroll/salary`
- **Controller**: `PayrollController -> Roles()`
- **Service Execution**: `payrollService.setSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
HR: Set or update employee salary profile (with history versioning). This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "employeeId": "emp-uuid-1234",
  "basicSalary": 15000,
  "allowances": 2500,
  "currency": "EGP",
  "effectiveFrom": "2026-01-01",
  "reason": "Annual appraisal promotion / Initial hiring package"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-004 — HR: View salary modification history for employee

**بتعمل إيه؟**:
جلب كشوف وبيانات الرواتب ودورات الدفع الشهرية للمؤسسة الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/payroll/salary/history/{employeeId}`
- **Controller**: `PayrollController -> ApiOperation()`
- **Service Execution**: `payrollService.getSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
HR: View salary modification history for employee. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `employeeId` | `string` | `id-12345` | Identifier parameter: employeeId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-005 — Employee: Request a salary advance

**بتعمل إيه؟**:
تسجيل طلب صرف سلفة مالية على الراتب لموظف مع خطة الأقساط الشهرية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/payroll/advances`
- **Controller**: `PayrollController -> Roles()`
- **Service Execution**: `payrollService.setSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
Employee: Request a salary advance. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "amount": 5000,
  "requestedInstallments": 3,
  "reason": "Emergency home maintenance and family medical expenses",
  "idempotencyKey": "adv_idemp_key_uuid_12345"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-006 — HR: List and filter all salary advance requests

**بتعمل إيه؟**:
استعراض طلبات وسجلات السلف المالية وأرصدتها المتبقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/payroll/advances`
- **Controller**: `PayrollController -> ApiOperation()`
- **Service Execution**: `payrollService.getSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
HR: List and filter all salary advance requests. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `status` | No | `string` | `` | Filter by advance status (PENDING, APPROVED, ACTIVE, PAID, REJECTED, CANCELLED) |
| `employeeId` | No | `string` | `` | Filter by specific employee profile ID |
| `department` | No | `string` | `` | Filter by employee department |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-007 — Employee: View my salary advance requests & installment schedule

**بتعمل إيه؟**:
استعراض طلبات وسجلات السلف المالية وأرصدتها المتبقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/payroll/advances/me`
- **Controller**: `PayrollController -> ApiOperation()`
- **Service Execution**: `payrollService.getSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
Employee: View my salary advance requests & installment schedule. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `status` | No | `string` | `` | Filter by advance status (PENDING, APPROVED, ACTIVE, PAID, REJECTED, CANCELLED) |
| `employeeId` | No | `string` | `` | Filter by specific employee profile ID |
| `department` | No | `string` | `` | Filter by employee department |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-008 — Employee: View my salary advances (alias)

**بتعمل إيه؟**:
استعراض طلبات وسجلات السلف المالية وأرصدتها المتبقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/payroll/advances/my`
- **Controller**: `PayrollController -> ApiOperation()`
- **Service Execution**: `payrollService.getSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
Employee: View my salary advances (alias). This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `status` | No | `string` | `` | Filter by advance status (PENDING, APPROVED, ACTIVE, PAID, REJECTED, CANCELLED) |
| `employeeId` | No | `string` | `` | Filter by specific employee profile ID |
| `department` | No | `string` | `` | Filter by employee department |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-009 — View detailed salary advance with installment schedule

**بتعمل إيه؟**:
استعراض طلبات وسجلات السلف المالية وأرصدتها المتبقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/payroll/advances/{id}`
- **Controller**: `PayrollController -> ApiOperation()`
- **Service Execution**: `payrollService.getSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
View detailed salary advance with installment schedule. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-010 — HR: Approve salary advance and generate installment schedule

**بتعمل إيه؟**:
تسجيل طلب صرف سلفة مالية على الراتب لموظف مع خطة الأقساط الشهرية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/payroll/advances/{id}/approve`
- **Controller**: `PayrollController -> Roles()`
- **Service Execution**: `payrollService.setSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
HR: Approve salary advance and generate installment schedule. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "approvedAmount": 5000,
  "installmentsCount": 3,
  "firstDueDate": "2026-09-01",
  "remarks": "Approved as per company salary advance policy."
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-011 — HR: Reject salary advance with mandatory reason

**بتعمل إيه؟**:
تسجيل طلب صرف سلفة مالية على الراتب لموظف مع خطة الأقساط الشهرية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/payroll/advances/{id}/reject`
- **Controller**: `PayrollController -> Roles()`
- **Service Execution**: `payrollService.setSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
HR: Reject salary advance with mandatory reason. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "reason": "Active outstanding advance exists or probationary period not completed."
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-012 — HR / Finance: Record payment towards an advance installment

**بتعمل إيه؟**:
تسجيل طلب صرف سلفة مالية على الراتب لموظف مع خطة الأقساط الشهرية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/payroll/advances/installments/{installmentId}/pay`
- **Controller**: `PayrollController -> Roles()`
- **Service Execution**: `payrollService.setSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
HR / Finance: Record payment towards an advance installment. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `installmentId` | `string` | `id-12345` | Identifier parameter: installmentId |

**Request Body Payload**:
```json
{
  "amount": 1000,
  "notes": "Paid via bank transfer / direct deposit",
  "idempotencyKey": "pay_idemp_key_123"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-013 — HR: Create manual financial deduction or penalty

**بتعمل إيه؟**:
إدارة الخصومات والجزاءات المالية على الموظفين وربطها بمسير الرواتب.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/payroll/deductions`
- **Controller**: `PayrollController -> Roles()`
- **Service Execution**: `payrollService.setSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
HR: Create manual financial deduction or penalty. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "employeeId": "emp-uuid-1234",
  "type": "PENALTY",
  "amount": 500,
  "reason": "Damaged company equipment / policy non-compliance fine",
  "effectiveDate": "2026-08-15"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-014 — HR: List and filter all financial deductions

**بتعمل إيه؟**:
إدارة الخصومات والجزاءات المالية على الموظفين وربطها بمسير الرواتب.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/payroll/deductions`
- **Controller**: `PayrollController -> ApiOperation()`
- **Service Execution**: `payrollService.getSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
HR: List and filter all financial deductions. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `employeeId` | No | `string` | `` | Filter deductions by Employee Profile UUID |
| `type` | No | `string` | `` | Filter by deduction category |
| `startDate` | No | `string` | `` | Filter deductions on or after this date |
| `endDate` | No | `string` | `` | Filter deductions on or before this date |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-015 — Employee: View my deductions

**بتعمل إيه؟**:
إدارة الخصومات والجزاءات المالية على الموظفين وربطها بمسير الرواتب.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/payroll/deductions/me`
- **Controller**: `PayrollController -> ApiOperation()`
- **Service Execution**: `payrollService.getSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
Employee: View my deductions. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `employeeId` | No | `string` | `` | Filter deductions by Employee Profile UUID |
| `type` | No | `string` | `` | Filter by deduction category |
| `startDate` | No | `string` | `` | Filter deductions on or after this date |
| `endDate` | No | `string` | `` | Filter deductions on or before this date |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-016 — Employee: View my deductions (alias)

**بتعمل إيه؟**:
إدارة الخصومات والجزاءات المالية على الموظفين وربطها بمسير الرواتب.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/payroll/deductions/my`
- **Controller**: `PayrollController -> ApiOperation()`
- **Service Execution**: `payrollService.getSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
Employee: View my deductions (alias). This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `employeeId` | No | `string` | `` | Filter deductions by Employee Profile UUID |
| `type` | No | `string` | `` | Filter by deduction category |
| `startDate` | No | `string` | `` | Filter deductions on or after this date |
| `endDate` | No | `string` | `` | Filter deductions on or before this date |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-017 — HR: Create a new monthly payroll period

**بتعمل إيه؟**:
إدارة مسيرات الرواتب والسلف المالية والاستقطاعات للموظفين.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/payroll/periods`
- **Controller**: `PayrollController -> Roles()`
- **Service Execution**: `payrollService.setSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
HR: Create a new monthly payroll period. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "name": "2026-08",
  "startDate": "2026-08-01",
  "endDate": "2026-08-31"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-018 — HR: List all payroll periods

**بتعمل إيه؟**:
جلب كشوف وبيانات الرواتب ودورات الدفع الشهرية للمؤسسة الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/payroll/periods`
- **Controller**: `PayrollController -> ApiOperation()`
- **Service Execution**: `payrollService.getSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
HR: List all payroll periods. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | **Yes** | `number` | `` | Filter parameter: page |
| `limit` | **Yes** | `number` | `` | Filter parameter: limit |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-019 — HR: Run calculation engine for payroll period

**بتعمل إيه؟**:
تشغيل احتساب مسير الرواتب الشهري للموظفين آلياً بناءً على ساعات العمل، الغياب، الإضافي، والسلف.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/payroll/periods/{id}/calculate`
- **Controller**: `PayrollController -> Roles()`
- **Service Execution**: `payrollService.setSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
HR: Run calculation engine for payroll period. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "employeeId": "sample-uuid-v4",
  "department": "Engineering",
  "recalculate": false
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Configured Organization
- Active Employee Contracts

---

### PAY-020 — HR / Finance: Finalize and lock payroll period

**بتعمل إيه؟**:
إقفال واعتماد مسير الرواتب النهائي لشهر محدد وتجهيزه للتحويل البنكي.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/payroll/periods/{id}/finalize`
- **Controller**: `PayrollController -> Roles()`
- **Service Execution**: `payrollService.setSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
HR / Finance: Finalize and lock payroll period. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "remarks": "Finalized and approved by CFO & HR Director for disbursement.",
  "idempotencyKey": "fin_period_idemp_key_2026_08"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Configured Organization
- Active Employee Contracts

---

### PAY-021 — Employee: View my monthly payroll payslips

**بتعمل إيه؟**:
جلب كشوف وبيانات الرواتب ودورات الدفع الشهرية للمؤسسة الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/payroll/me`
- **Controller**: `PayrollController -> ApiOperation()`
- **Service Execution**: `payrollService.getSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
Employee: View my monthly payroll payslips. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `period` | No | `string` | `` | Filter by payroll period name (e.g. YYYY-MM) |
| `payrollPeriodId` | No | `string` | `` | Filter by Payroll Period UUID |
| `employeeId` | No | `string` | `` | Filter by Employee Profile UUID |
| `department` | No | `string` | `` | Filter by employee department |
| `status` | No | `string` | `` | Filter by payroll record status (DRAFT, CALCULATED, REVIEW, FINALIZED, PAID) |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-022 — View detailed payslip with itemized line items

**بتعمل إيه؟**:
جلب كشوف وبيانات الرواتب ودورات الدفع الشهرية للمؤسسة الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/payroll/records/{id}`
- **Controller**: `PayrollController -> ApiOperation()`
- **Service Execution**: `payrollService.getSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
View detailed payslip with itemized line items. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-023 — HR: Create post-finalization adjustment for payroll record

**بتعمل إيه؟**:
إدارة مسيرات الرواتب والسلف المالية والاستقطاعات للموظفين.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/payroll/records/{id}/adjust`
- **Controller**: `PayrollController -> Roles()`
- **Service Execution**: `payrollService.setSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
HR: Create post-finalization adjustment for payroll record. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "type": "BONUS",
  "amount": 1000,
  "isDeduction": false,
  "reason": "Post-close retroactive bonus adjustment approved by General Manager"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PAY-024 — HR: List and filter all employee payroll records

**بتعمل إيه؟**:
جلب كشوف وبيانات الرواتب ودورات الدفع الشهرية للمؤسسة الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/payroll`
- **Controller**: `PayrollController -> ApiOperation()`
- **Service Execution**: `payrollService.getSalaryProfile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `PayrollPeriod`, `Payslip`, `SalaryAdvance`, `Loan`, `Deduction`

**Purpose & Business Context**:
HR: List and filter all employee payroll records. This endpoint operates with strict transactional integrity under the Payroll, Salary Advances & Deductions subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `period` | No | `string` | `` | Filter by payroll period name (e.g. YYYY-MM) |
| `payrollPeriodId` | No | `string` | `` | Filter by Payroll Period UUID |
| `employeeId` | No | `string` | `` | Filter by Employee Profile UUID |
| `department` | No | `string` | `` | Filter by employee department |
| `status` | No | `string` | `` | Filter by payroll record status (DRAFT, CALCULATED, REVIEW, FINALIZED, PAID) |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Internal Messaging & Conversations

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **MSG-001** | `POST` | `/api/v1/messages/conversations` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Start a new 1-on-1 conversation |
| **MSG-002** | `GET` | `/api/v1/messages/conversations` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Get current user conversations list with unread badges |
| **MSG-003** | `POST` | `/api/v1/messages/groups` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Create a new group conversation with participants |
| **MSG-004** | `GET` | `/api/v1/messages/unread-count` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Get total unread messages count for current user |
| **MSG-005** | `GET` | `/api/v1/messages/conversations/{id}` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Get paginated message history for a conversation |
| **MSG-006** | `POST` | `/api/v1/messages/conversations/{id}/messages` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Send a message in a conversation |
| **MSG-007** | `POST` | `/api/v1/messages` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Send a message (with conversationId in body) |
| **MSG-008** | `POST` | `/api/v1/messages/conversations/{id}/read` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Mark all messages in a conversation as read |
| **MSG-009** | `DELETE` | `/api/v1/messages/{id}` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Soft delete a message (sender or HR admin) |

### MSG-001 — Start a new 1-on-1 conversation

**بتعمل إيه؟**:
إرسال رسالة جديدة في محادثة فردية أو جماعية بين موظفي الفندق.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/messages/conversations`
- **Controller**: `MessagesController -> ApiOperation()`
- **Service Execution**: `messagingService.createConversation()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Conversation`, `Message`, `ConversationParticipant`

**Purpose & Business Context**:
Start a new 1-on-1 conversation. This endpoint operates with strict transactional integrity under the Internal Messaging & Conversations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "participantUserId": "emp-uuid-123",
  "title": "Salary inquiry & contract amendment question",
  "content": "Hello HR Team, I have a question regarding my recent overtime calculation...",
  "attachmentUrl": "https://storage.cyberwise.internal/attachments/pay_stub_query.pdf",
  "idempotencyKey": "msg_idemp_key_123"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### MSG-002 — Get current user conversations list with unread badges

**بتعمل إيه؟**:
جلب المحادثات وقنوات التواصل الخاصة بالموظف الحالي وسجل الرسائل.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/messages/conversations`
- **Controller**: `MessagesController -> ApiOperation()`
- **Service Execution**: `messagingService.getUserConversations()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Conversation`, `Message`, `ConversationParticipant`

**Purpose & Business Context**:
Get current user conversations list with unread badges. This endpoint operates with strict transactional integrity under the Internal Messaging & Conversations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### MSG-003 — Create a new group conversation with participants

**بتعمل إيه؟**:
إرسال رسالة جديدة في محادثة فردية أو جماعية بين موظفي الفندق.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/messages/groups`
- **Controller**: `MessagesController -> ApiOperation()`
- **Service Execution**: `messagingService.createConversation()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Conversation`, `Message`, `ConversationParticipant`

**Purpose & Business Context**:
Create a new group conversation with participants. This endpoint operates with strict transactional integrity under the Internal Messaging & Conversations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "title": "Operations Team Channel",
  "participantUserIds": [
    "user-uuid-1",
    "user-uuid-2"
  ],
  "initialMessage": "Welcome everyone to the Operations team channel!"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### MSG-004 — Get total unread messages count for current user

**بتعمل إيه؟**:
إدارة المراسلات الداخلية والمحادثات الفورية بين موظفي الفندق.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/messages/unread-count`
- **Controller**: `MessagesController -> ApiOperation()`
- **Service Execution**: `messagingService.getUserConversations()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Conversation`, `Message`, `ConversationParticipant`

**Purpose & Business Context**:
Get total unread messages count for current user. This endpoint operates with strict transactional integrity under the Internal Messaging & Conversations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### MSG-005 — Get paginated message history for a conversation

**بتعمل إيه؟**:
جلب المحادثات وقنوات التواصل الخاصة بالموظف الحالي وسجل الرسائل.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/messages/conversations/{id}`
- **Controller**: `MessagesController -> ApiOperation()`
- **Service Execution**: `messagingService.getUserConversations()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Conversation`, `Message`, `ConversationParticipant`

**Purpose & Business Context**:
Get paginated message history for a conversation. This endpoint operates with strict transactional integrity under the Internal Messaging & Conversations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `before` | No | `string` | `` | Cursor timestamp or message ID for fetching older messages |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### MSG-006 — Send a message in a conversation

**بتعمل إيه؟**:
إرسال رسالة جديدة في محادثة فردية أو جماعية بين موظفي الفندق.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/messages/conversations/{id}/messages`
- **Controller**: `MessagesController -> ApiOperation()`
- **Service Execution**: `messagingService.createConversation()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Conversation`, `Message`, `ConversationParticipant`

**Purpose & Business Context**:
Send a message in a conversation. This endpoint operates with strict transactional integrity under the Internal Messaging & Conversations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "conversationId": "conv-uuid-123",
  "content": "Thank you for following up. Here is the requested document.",
  "attachmentUrl": "https://storage.cyberwise.internal/attachments/doc.pdf",
  "idempotencyKey": "msg_idemp_send_uuid_123"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### MSG-007 — Send a message (with conversationId in body)

**بتعمل إيه؟**:
إرسال رسالة جديدة في محادثة فردية أو جماعية بين موظفي الفندق.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/messages`
- **Controller**: `MessagesController -> ApiOperation()`
- **Service Execution**: `messagingService.createConversation()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Conversation`, `Message`, `ConversationParticipant`

**Purpose & Business Context**:
Send a message (with conversationId in body). This endpoint operates with strict transactional integrity under the Internal Messaging & Conversations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "conversationId": "conv-uuid-123",
  "content": "Thank you for following up. Here is the requested document.",
  "attachmentUrl": "https://storage.cyberwise.internal/attachments/doc.pdf",
  "idempotencyKey": "msg_idemp_send_uuid_123"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### MSG-008 — Mark all messages in a conversation as read

**بتعمل إيه؟**:
إرسال رسالة جديدة في محادثة فردية أو جماعية بين موظفي الفندق.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/messages/conversations/{id}/read`
- **Controller**: `MessagesController -> ApiOperation()`
- **Service Execution**: `messagingService.createConversation()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Conversation`, `Message`, `ConversationParticipant`

**Purpose & Business Context**:
Mark all messages in a conversation as read. This endpoint operates with strict transactional integrity under the Internal Messaging & Conversations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### MSG-009 — Soft delete a message (sender or HR admin)

**بتعمل إيه؟**:
إدارة المراسلات الداخلية والمحادثات الفورية بين موظفي الفندق.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/messages/{id}`
- **Controller**: `MessagesController -> HttpCode()`
- **Service Execution**: `messagingService.deleteMessage()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Conversation`, `Message`, `ConversationParticipant`

**Purpose & Business Context**:
Soft delete a message (sender or HR admin). This endpoint operates with strict transactional integrity under the Internal Messaging & Conversations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Reports & Analytics Engine

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **REP-001** | `GET` | `/api/v1/reports/dashboard` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | HR Dashboard summary KPIs, today attendance, pending items |
| **REP-002** | `GET` | `/api/v1/reports/me` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Employee self-report (own attendance rate, late minutes, absences, requests, advances, payroll) |
| **REP-003** | `GET` | `/api/v1/reports/attendance` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Comprehensive attendance analytics with rates & date ranges |
| **REP-004** | `GET` | `/api/v1/reports/attendance/late` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Late arrival analytics, top offenders, and distribution |
| **REP-005** | `GET` | `/api/v1/reports/attendance/absence` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Absence analytics (approved vs unapproved, rates, distribution) |
| **REP-006** | `GET` | `/api/v1/reports/attendance/security` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Attendance security telemetry (geofence breaches, GPS accuracy, suspicious device signals) |
| **REP-007** | `GET` | `/api/v1/reports/attendance/export` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Export filtered attendance reports with formula injection protection (CSV) |
| **REP-008** | `GET` | `/api/v1/reports/requests` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Request analytics, approval/rejection rates & processing duration |
| **REP-009** | `GET` | `/api/v1/reports/payroll` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Payroll analytics, gross/net trends, departmental payroll |
| **REP-010** | `GET` | `/api/v1/reports/deductions` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Deduction analytics grouped by type and department |
| **REP-011** | `GET` | `/api/v1/reports/advances` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Salary advance analytics, active balances, repayment stats |
| **REP-012** | `GET` | `/api/v1/reports/employees` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Employee distribution by department, workplace, and job title |
| **REP-013** | `GET` | `/api/v1/reports/departments` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Department performance metrics and headcount stats |
| **REP-014** | `GET` | `/api/v1/reports/workplaces` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Workplace operational metrics, geofence breaches, manual edits |
| **REP-015** | `GET` | `/api/v1/reports/tasks` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Comprehensive task KPIs, completion/overdue rates & status breakdown |
| **REP-016** | `GET` | `/api/v1/reports/tasks/employees` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Employee task productivity, completion rates & performance ratings |
| **REP-017** | `GET` | `/api/v1/reports/tasks/departments` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Departmental task load, active bottlenecks & completion rates |
| **REP-018** | `GET` | `/api/v1/reports/tasks/export` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Export tasks report with CSV injection protection |

### REP-001 — HR Dashboard summary KPIs, today attendance, pending items

**بتعمل إيه؟**:
استخراج وعرض التقارير التحليلية والإحصائية لعمليات الفندق والقوى العاملة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/reports/dashboard`
- **Controller**: `ReportsController -> Roles()`
- **Service Execution**: `reportsService.getDashboardSummary()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ReportGeneration`, `AuditLog`, `AttendanceRecord`, `PayrollPeriod`

**Purpose & Business Context**:
HR Dashboard summary KPIs, today attendance, pending items. This endpoint operates with strict transactional integrity under the Reports & Analytics Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REP-002 — Employee self-report (own attendance rate, late minutes, absences, requests, advances, payroll)

**بتعمل إيه؟**:
استخراج وعرض التقارير التحليلية والإحصائية لعمليات الفندق والقوى العاملة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/reports/me`
- **Controller**: `ReportsController -> Roles()`
- **Service Execution**: `reportsService.getDashboardSummary()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ReportGeneration`, `AuditLog`, `AttendanceRecord`, `PayrollPeriod`

**Purpose & Business Context**:
Employee self-report (own attendance rate, late minutes, absences, requests, advances, payroll). This endpoint operates with strict transactional integrity under the Reports & Analytics Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Start date in ISO format (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | End date in ISO format (YYYY-MM-DD) |
| `year` | No | `number` | `` | Specific year for annual/monthly aggregation |
| `month` | No | `number` | `` | Specific month (1-12) for monthly aggregation |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `sortBy` | No | `string` | `createdAt` | Field name to sort by (whitelisted) |
| `sortOrder` | No | `string` | `desc` | Filter parameter: sortOrder |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REP-003 — Comprehensive attendance analytics with rates & date ranges

**بتعمل إيه؟**:
استخراج وعرض التقارير التحليلية والإحصائية لعمليات الفندق والقوى العاملة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/reports/attendance`
- **Controller**: `ReportsController -> Roles()`
- **Service Execution**: `reportsService.getDashboardSummary()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ReportGeneration`, `AuditLog`, `AttendanceRecord`, `PayrollPeriod`

**Purpose & Business Context**:
Comprehensive attendance analytics with rates & date ranges. This endpoint operates with strict transactional integrity under the Reports & Analytics Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Start date in ISO format (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | End date in ISO format (YYYY-MM-DD) |
| `year` | No | `number` | `` | Specific year for annual/monthly aggregation |
| `month` | No | `number` | `` | Specific month (1-12) for monthly aggregation |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `sortBy` | No | `string` | `createdAt` | Field name to sort by (whitelisted) |
| `sortOrder` | No | `string` | `desc` | Filter parameter: sortOrder |
| `employeeId` | No | `string` | `` | Filter by specific Employee ID |
| `department` | No | `string` | `` | Filter by Department |
| `workplaceId` | No | `string` | `` | Filter by Workplace ID |
| `status` | No | `string` | `` | Filter by Attendance Status |
| `scheduleId` | No | `string` | `` | Filter by Schedule/Shift ID |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REP-004 — Late arrival analytics, top offenders, and distribution

**بتعمل إيه؟**:
استخراج وعرض التقارير التحليلية والإحصائية لعمليات الفندق والقوى العاملة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/reports/attendance/late`
- **Controller**: `ReportsController -> Roles()`
- **Service Execution**: `reportsService.getDashboardSummary()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ReportGeneration`, `AuditLog`, `AttendanceRecord`, `PayrollPeriod`

**Purpose & Business Context**:
Late arrival analytics, top offenders, and distribution. This endpoint operates with strict transactional integrity under the Reports & Analytics Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Start date in ISO format (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | End date in ISO format (YYYY-MM-DD) |
| `year` | No | `number` | `` | Specific year for annual/monthly aggregation |
| `month` | No | `number` | `` | Specific month (1-12) for monthly aggregation |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `sortBy` | No | `string` | `createdAt` | Field name to sort by (whitelisted) |
| `sortOrder` | No | `string` | `desc` | Filter parameter: sortOrder |
| `employeeId` | No | `string` | `` | Filter by specific Employee ID |
| `department` | No | `string` | `` | Filter by Department |
| `workplaceId` | No | `string` | `` | Filter by Workplace ID |
| `status` | No | `string` | `` | Filter by Attendance Status |
| `scheduleId` | No | `string` | `` | Filter by Schedule/Shift ID |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REP-005 — Absence analytics (approved vs unapproved, rates, distribution)

**بتعمل إيه؟**:
استخراج وعرض التقارير التحليلية والإحصائية لعمليات الفندق والقوى العاملة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/reports/attendance/absence`
- **Controller**: `ReportsController -> Roles()`
- **Service Execution**: `reportsService.getDashboardSummary()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ReportGeneration`, `AuditLog`, `AttendanceRecord`, `PayrollPeriod`

**Purpose & Business Context**:
Absence analytics (approved vs unapproved, rates, distribution). This endpoint operates with strict transactional integrity under the Reports & Analytics Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Start date in ISO format (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | End date in ISO format (YYYY-MM-DD) |
| `year` | No | `number` | `` | Specific year for annual/monthly aggregation |
| `month` | No | `number` | `` | Specific month (1-12) for monthly aggregation |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `sortBy` | No | `string` | `createdAt` | Field name to sort by (whitelisted) |
| `sortOrder` | No | `string` | `desc` | Filter parameter: sortOrder |
| `employeeId` | No | `string` | `` | Filter by specific Employee ID |
| `department` | No | `string` | `` | Filter by Department |
| `workplaceId` | No | `string` | `` | Filter by Workplace ID |
| `status` | No | `string` | `` | Filter by Attendance Status |
| `scheduleId` | No | `string` | `` | Filter by Schedule/Shift ID |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REP-006 — Attendance security telemetry (geofence breaches, GPS accuracy, suspicious device signals)

**بتعمل إيه؟**:
استخراج وعرض التقارير التحليلية والإحصائية لعمليات الفندق والقوى العاملة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/reports/attendance/security`
- **Controller**: `ReportsController -> Roles()`
- **Service Execution**: `reportsService.getDashboardSummary()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ReportGeneration`, `AuditLog`, `AttendanceRecord`, `PayrollPeriod`

**Purpose & Business Context**:
Attendance security telemetry (geofence breaches, GPS accuracy, suspicious device signals). This endpoint operates with strict transactional integrity under the Reports & Analytics Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Start date in ISO format (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | End date in ISO format (YYYY-MM-DD) |
| `year` | No | `number` | `` | Specific year for annual/monthly aggregation |
| `month` | No | `number` | `` | Specific month (1-12) for monthly aggregation |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `sortBy` | No | `string` | `createdAt` | Field name to sort by (whitelisted) |
| `sortOrder` | No | `string` | `desc` | Filter parameter: sortOrder |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REP-007 — Export filtered attendance reports with formula injection protection (CSV)

**بتعمل إيه؟**:
تصدير وطباعة التقرير بصيغة PDF أو Excel للتحليل والمراجعة الإدارية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/reports/attendance/export`
- **Controller**: `ReportsController -> Roles()`
- **Service Execution**: `reportsService.getDashboardSummary()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ReportGeneration`, `AuditLog`, `AttendanceRecord`, `PayrollPeriod`

**Purpose & Business Context**:
Export filtered attendance reports with formula injection protection (CSV). This endpoint operates with strict transactional integrity under the Reports & Analytics Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Start date in ISO format (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | End date in ISO format (YYYY-MM-DD) |
| `year` | No | `number` | `` | Specific year for annual/monthly aggregation |
| `month` | No | `number` | `` | Specific month (1-12) for monthly aggregation |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `sortBy` | No | `string` | `createdAt` | Field name to sort by (whitelisted) |
| `sortOrder` | No | `string` | `desc` | Filter parameter: sortOrder |
| `employeeId` | No | `string` | `` | Filter by specific Employee ID |
| `department` | No | `string` | `` | Filter by Department |
| `workplaceId` | No | `string` | `` | Filter by Workplace ID |
| `status` | No | `string` | `` | Filter by Attendance Status |
| `scheduleId` | No | `string` | `` | Filter by Schedule/Shift ID |
| `format` | No | `string` | `csv` | Export file format |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REP-008 — Request analytics, approval/rejection rates & processing duration

**بتعمل إيه؟**:
استخراج وعرض التقارير التحليلية والإحصائية لعمليات الفندق والقوى العاملة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/reports/requests`
- **Controller**: `ReportsController -> Roles()`
- **Service Execution**: `reportsService.getDashboardSummary()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `ReportGeneration`, `AuditLog`, `AttendanceRecord`, `PayrollPeriod`

**Purpose & Business Context**:
Request analytics, approval/rejection rates & processing duration. This endpoint operates with strict transactional integrity under the Reports & Analytics Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Start date in ISO format (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | End date in ISO format (YYYY-MM-DD) |
| `year` | No | `number` | `` | Specific year for annual/monthly aggregation |
| `month` | No | `number` | `` | Specific month (1-12) for monthly aggregation |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `sortBy` | No | `string` | `createdAt` | Field name to sort by (whitelisted) |
| `sortOrder` | No | `string` | `desc` | Filter parameter: sortOrder |
| `employeeId` | No | `string` | `` | Filter by specific Employee ID |
| `department` | No | `string` | `` | Filter by Department |
| `type` | No | `string` | `` | Filter by Request Type |
| `status` | No | `string` | `` | Filter by Request Status |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### REP-009 — Payroll analytics, gross/net trends, departmental payroll

**بتعمل إيه؟**:
استخراج وعرض التقارير التحليلية والإحصائية لعمليات الفندق والقوى العاملة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/reports/payroll`
- **Controller**: `ReportsController -> Roles()`
- **Service Execution**: `reportsService.getDashboardSummary()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ReportGeneration`, `AuditLog`, `AttendanceRecord`, `PayrollPeriod`

**Purpose & Business Context**:
Payroll analytics, gross/net trends, departmental payroll. This endpoint operates with strict transactional integrity under the Reports & Analytics Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Start date in ISO format (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | End date in ISO format (YYYY-MM-DD) |
| `year` | No | `number` | `` | Specific year for annual/monthly aggregation |
| `month` | No | `number` | `` | Specific month (1-12) for monthly aggregation |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `sortBy` | No | `string` | `createdAt` | Field name to sort by (whitelisted) |
| `sortOrder` | No | `string` | `desc` | Filter parameter: sortOrder |
| `payrollPeriodId` | No | `string` | `` | Filter by Payroll Period ID |
| `department` | No | `string` | `` | Filter by Department |
| `workplaceId` | No | `string` | `` | Filter by Workplace ID |
| `status` | No | `string` | `` | Filter by Payroll Period Status |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REP-010 — Deduction analytics grouped by type and department

**بتعمل إيه؟**:
استخراج وعرض التقارير التحليلية والإحصائية لعمليات الفندق والقوى العاملة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/reports/deductions`
- **Controller**: `ReportsController -> Roles()`
- **Service Execution**: `reportsService.getDashboardSummary()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ReportGeneration`, `AuditLog`, `AttendanceRecord`, `PayrollPeriod`

**Purpose & Business Context**:
Deduction analytics grouped by type and department. This endpoint operates with strict transactional integrity under the Reports & Analytics Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Start date in ISO format (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | End date in ISO format (YYYY-MM-DD) |
| `year` | No | `number` | `` | Specific year for annual/monthly aggregation |
| `month` | No | `number` | `` | Specific month (1-12) for monthly aggregation |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `sortBy` | No | `string` | `createdAt` | Field name to sort by (whitelisted) |
| `sortOrder` | No | `string` | `desc` | Filter parameter: sortOrder |
| `type` | No | `string` | `` | Filter by Deduction Type |
| `department` | No | `string` | `` | Filter by Department |
| `employeeId` | No | `string` | `` | Filter by Employee ID |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REP-011 — Salary advance analytics, active balances, repayment stats

**بتعمل إيه؟**:
استخراج وعرض التقارير التحليلية والإحصائية لعمليات الفندق والقوى العاملة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/reports/advances`
- **Controller**: `ReportsController -> Roles()`
- **Service Execution**: `reportsService.getDashboardSummary()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ReportGeneration`, `AuditLog`, `AttendanceRecord`, `PayrollPeriod`

**Purpose & Business Context**:
Salary advance analytics, active balances, repayment stats. This endpoint operates with strict transactional integrity under the Reports & Analytics Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Start date in ISO format (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | End date in ISO format (YYYY-MM-DD) |
| `year` | No | `number` | `` | Specific year for annual/monthly aggregation |
| `month` | No | `number` | `` | Specific month (1-12) for monthly aggregation |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `sortBy` | No | `string` | `createdAt` | Field name to sort by (whitelisted) |
| `sortOrder` | No | `string` | `desc` | Filter parameter: sortOrder |
| `department` | No | `string` | `` | Filter by Department |
| `employeeId` | No | `string` | `` | Filter by Employee ID |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REP-012 — Employee distribution by department, workplace, and job title

**بتعمل إيه؟**:
استخراج وعرض التقارير التحليلية والإحصائية لعمليات الفندق والقوى العاملة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/reports/employees`
- **Controller**: `ReportsController -> Roles()`
- **Service Execution**: `reportsService.getDashboardSummary()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ReportGeneration`, `AuditLog`, `AttendanceRecord`, `PayrollPeriod`

**Purpose & Business Context**:
Employee distribution by department, workplace, and job title. This endpoint operates with strict transactional integrity under the Reports & Analytics Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Start date in ISO format (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | End date in ISO format (YYYY-MM-DD) |
| `year` | No | `number` | `` | Specific year for annual/monthly aggregation |
| `month` | No | `number` | `` | Specific month (1-12) for monthly aggregation |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `sortBy` | No | `string` | `createdAt` | Field name to sort by (whitelisted) |
| `sortOrder` | No | `string` | `desc` | Filter parameter: sortOrder |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REP-013 — Department performance metrics and headcount stats

**بتعمل إيه؟**:
استخراج وعرض التقارير التحليلية والإحصائية لعمليات الفندق والقوى العاملة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/reports/departments`
- **Controller**: `ReportsController -> Roles()`
- **Service Execution**: `reportsService.getDashboardSummary()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ReportGeneration`, `AuditLog`, `AttendanceRecord`, `PayrollPeriod`

**Purpose & Business Context**:
Department performance metrics and headcount stats. This endpoint operates with strict transactional integrity under the Reports & Analytics Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Organization (ORG-001)

---

### REP-014 — Workplace operational metrics, geofence breaches, manual edits

**بتعمل إيه؟**:
استخراج وعرض التقارير التحليلية والإحصائية لعمليات الفندق والقوى العاملة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/reports/workplaces`
- **Controller**: `ReportsController -> Roles()`
- **Service Execution**: `reportsService.getDashboardSummary()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ReportGeneration`, `AuditLog`, `AttendanceRecord`, `PayrollPeriod`

**Purpose & Business Context**:
Workplace operational metrics, geofence breaches, manual edits. This endpoint operates with strict transactional integrity under the Reports & Analytics Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Start date in ISO format (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | End date in ISO format (YYYY-MM-DD) |
| `year` | No | `number` | `` | Specific year for annual/monthly aggregation |
| `month` | No | `number` | `` | Specific month (1-12) for monthly aggregation |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `sortBy` | No | `string` | `createdAt` | Field name to sort by (whitelisted) |
| `sortOrder` | No | `string` | `desc` | Filter parameter: sortOrder |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REP-015 — Comprehensive task KPIs, completion/overdue rates & status breakdown

**بتعمل إيه؟**:
استخراج وعرض التقارير التحليلية والإحصائية لعمليات الفندق والقوى العاملة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/reports/tasks`
- **Controller**: `ReportsController -> Roles()`
- **Service Execution**: `reportsService.getDashboardSummary()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ReportGeneration`, `AuditLog`, `AttendanceRecord`, `PayrollPeriod`

**Purpose & Business Context**:
Comprehensive task KPIs, completion/overdue rates & status breakdown. This endpoint operates with strict transactional integrity under the Reports & Analytics Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Start date in ISO format (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | End date in ISO format (YYYY-MM-DD) |
| `year` | No | `number` | `` | Specific year for annual/monthly aggregation |
| `month` | No | `number` | `` | Specific month (1-12) for monthly aggregation |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `sortBy` | No | `string` | `createdAt` | Field name to sort by (whitelisted) |
| `sortOrder` | No | `string` | `desc` | Filter parameter: sortOrder |
| `departmentId` | No | `string` | `` | Filter by Department ID |
| `employeeId` | No | `string` | `` | Filter by assigned EmployeeProfile ID |
| `workplaceId` | No | `string` | `` | Filter by Workplace ID |
| `status` | No | `string` | `` | Filter parameter: status |
| `priority` | No | `string` | `` | Filter parameter: priority |
| `isOverdue` | No | `boolean` | `` | Filter overdue tasks |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REP-016 — Employee task productivity, completion rates & performance ratings

**بتعمل إيه؟**:
استخراج وعرض التقارير التحليلية والإحصائية لعمليات الفندق والقوى العاملة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/reports/tasks/employees`
- **Controller**: `ReportsController -> Roles()`
- **Service Execution**: `reportsService.getDashboardSummary()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ReportGeneration`, `AuditLog`, `AttendanceRecord`, `PayrollPeriod`

**Purpose & Business Context**:
Employee task productivity, completion rates & performance ratings. This endpoint operates with strict transactional integrity under the Reports & Analytics Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Start date in ISO format (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | End date in ISO format (YYYY-MM-DD) |
| `year` | No | `number` | `` | Specific year for annual/monthly aggregation |
| `month` | No | `number` | `` | Specific month (1-12) for monthly aggregation |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `sortBy` | No | `string` | `createdAt` | Field name to sort by (whitelisted) |
| `sortOrder` | No | `string` | `desc` | Filter parameter: sortOrder |
| `departmentId` | No | `string` | `` | Filter by Department ID |
| `employeeId` | No | `string` | `` | Filter by assigned EmployeeProfile ID |
| `workplaceId` | No | `string` | `` | Filter by Workplace ID |
| `status` | No | `string` | `` | Filter parameter: status |
| `priority` | No | `string` | `` | Filter parameter: priority |
| `isOverdue` | No | `boolean` | `` | Filter overdue tasks |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### REP-017 — Departmental task load, active bottlenecks & completion rates

**بتعمل إيه؟**:
استخراج وعرض التقارير التحليلية والإحصائية لعمليات الفندق والقوى العاملة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/reports/tasks/departments`
- **Controller**: `ReportsController -> Roles()`
- **Service Execution**: `reportsService.getDashboardSummary()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ReportGeneration`, `AuditLog`, `AttendanceRecord`, `PayrollPeriod`

**Purpose & Business Context**:
Departmental task load, active bottlenecks & completion rates. This endpoint operates with strict transactional integrity under the Reports & Analytics Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Start date in ISO format (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | End date in ISO format (YYYY-MM-DD) |
| `year` | No | `number` | `` | Specific year for annual/monthly aggregation |
| `month` | No | `number` | `` | Specific month (1-12) for monthly aggregation |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `sortBy` | No | `string` | `createdAt` | Field name to sort by (whitelisted) |
| `sortOrder` | No | `string` | `desc` | Filter parameter: sortOrder |
| `departmentId` | No | `string` | `` | Filter by Department ID |
| `employeeId` | No | `string` | `` | Filter by assigned EmployeeProfile ID |
| `workplaceId` | No | `string` | `` | Filter by Workplace ID |
| `status` | No | `string` | `` | Filter parameter: status |
| `priority` | No | `string` | `` | Filter parameter: priority |
| `isOverdue` | No | `boolean` | `` | Filter overdue tasks |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Organization (ORG-001)

---

### REP-018 — Export tasks report with CSV injection protection

**بتعمل إيه؟**:
تصدير وطباعة التقرير بصيغة PDF أو Excel للتحليل والمراجعة الإدارية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/reports/tasks/export`
- **Controller**: `ReportsController -> Roles()`
- **Service Execution**: `reportsService.getDashboardSummary()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ReportGeneration`, `AuditLog`, `AttendanceRecord`, `PayrollPeriod`

**Purpose & Business Context**:
Export tasks report with CSV injection protection. This endpoint operates with strict transactional integrity under the Reports & Analytics Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `startDate` | No | `string` | `` | Start date in ISO format (YYYY-MM-DD) |
| `endDate` | No | `string` | `` | End date in ISO format (YYYY-MM-DD) |
| `year` | No | `number` | `` | Specific year for annual/monthly aggregation |
| `month` | No | `number` | `` | Specific month (1-12) for monthly aggregation |
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `sortBy` | No | `string` | `createdAt` | Field name to sort by (whitelisted) |
| `sortOrder` | No | `string` | `desc` | Filter parameter: sortOrder |
| `departmentId` | No | `string` | `` | Filter by Department ID |
| `employeeId` | No | `string` | `` | Filter by assigned EmployeeProfile ID |
| `workplaceId` | No | `string` | `` | Filter by Workplace ID |
| `status` | No | `string` | `` | Filter parameter: status |
| `priority` | No | `string` | `` | Filter parameter: priority |
| `isOverdue` | No | `boolean` | `` | Filter overdue tasks |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Audit Logs

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **AUD-001** | `GET` | `/api/v1/audit-logs` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | List all system audit logs |

### AUD-001 — List all system audit logs

**بتعمل إيه؟**:
استعراض سجل الرقابة والتدقيق الأمني (Audit Trail) لجميع العمليات الحساسة لمعرفة من قام بأي إجراء ومتى بالتفصيل.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/audit-logs`
- **Controller**: `AuditLogsController -> Roles()`
- **Service Execution**: `auditLogsService.findAll()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `AuditLog`, `User`

**Purpose & Business Context**:
List all system audit logs. This endpoint operates with strict transactional integrity under the Audit Logs subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search term |
| `action` | No | `string` | `` | Filter by action |
| `entity` | No | `string` | `` | Filter by entity name (e.g. EmployeeProfile, AttendanceRecord) |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Tasks & Work Execution

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **TSK-001** | `POST` | `/api/v1/tasks` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Create a new task and optionally assign to an employee |
| **TSK-002** | `GET` | `/api/v1/tasks` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | List tasks with pagination, filters and search |
| **TSK-003** | `GET` | `/api/v1/tasks/my` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get current employee assigned and created tasks |
| **TSK-004** | `GET` | `/api/v1/tasks/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get task details including checklist, comments, and attachments |
| **TSK-005** | `PATCH` | `/api/v1/tasks/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Update task metadata, priority, due date, or progress |
| **TSK-006** | `DELETE` | `/api/v1/tasks/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Delete or cancel task |
| **TSK-007** | `POST` | `/api/v1/tasks/{id}/assign` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Assign or reassign task to an employee |
| **TSK-008** | `POST` | `/api/v1/tasks/{id}/accept` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Assigned employee accepts task (TODO -> ACCEPTED) |
| **TSK-009** | `POST` | `/api/v1/tasks/{id}/status` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Update task lifecycle status (IN_PROGRESS, BLOCKED, etc.) |
| **TSK-010** | `POST` | `/api/v1/tasks/{id}/checklist` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Add checklist item to task |
| **TSK-011** | `PATCH` | `/api/v1/tasks/{id}/checklist/{itemId}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Toggle or update checklist item (auto-updates progress %) |
| **TSK-012** | `DELETE` | `/api/v1/tasks/{id}/checklist/{itemId}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Delete checklist item from task |
| **TSK-013** | `POST` | `/api/v1/tasks/{id}/comments` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Add comment to task |
| **TSK-014** | `GET` | `/api/v1/tasks/{id}/comments` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get all comments for a task |
| **TSK-015** | `POST` | `/api/v1/tasks/{id}/attachments` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Attach file metadata to task |
| **TSK-016** | `GET` | `/api/v1/tasks/{id}/attachments` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | List task attachments |
| **TSK-017** | `GET` | `/api/v1/tasks/{id}/history` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get chronological audit history for a task |

### TSK-001 — Create a new task and optionally assign to an employee

**بتعمل إيه؟**:
إنشاء مهمة عمل جديدة وتكليف موظف أو فريق بإنجازها مع تحديد الموعد النهائي والأولوية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/tasks`
- **Controller**: `TasksController -> Roles()`
- **Service Execution**: `tasksService.createTask()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Task`, `TaskAssignment`, `TaskComment`, `TaskAttachment`

**Purpose & Business Context**:
Create a new task and optionally assign to an employee. This endpoint operates with strict transactional integrity under the Tasks & Work Execution subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "title": "Implement Phase 5 Tasks & Reports",
  "description": "sample_description",
  "priority": "MEDIUM",
  "assigneeId": "sample-uuid-v4",
  "departmentId": "sample-uuid-v4",
  "workplaceId": "sample-uuid-v4",
  "startDate": "2026-09-03T09:00:00Z",
  "dueDate": "2026-09-10T18:00:00Z",
  "checklist": [],
  "metadata": null
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TSK-002 — List tasks with pagination, filters and search

**بتعمل إيه؟**:
متابعة وإدارة المهام التشغيلية ومستوى إنجاز فرق العمل داخل الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/tasks`
- **Controller**: `TasksController -> ApiOperation()`
- **Service Execution**: `tasksService.findAll()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Task`, `TaskAssignment`, `TaskComment`, `TaskAttachment`

**Purpose & Business Context**:
List tasks with pagination, filters and search. This endpoint operates with strict transactional integrity under the Tasks & Work Execution subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `status` | No | `string` | `` | Filter parameter: status |
| `priority` | No | `string` | `` | Filter parameter: priority |
| `assigneeId` | No | `string` | `` | Filter by assigned EmployeeProfile ID |
| `creatorId` | No | `string` | `` | Filter by creator User ID |
| `departmentId` | No | `string` | `` | Filter by Department ID |
| `workplaceId` | No | `string` | `` | Filter by Workplace ID |
| `isOverdue` | No | `boolean` | `` | Filter overdue tasks |
| `startDate` | No | `string` | `` | Filter tasks with due date on or after |
| `endDate` | No | `string` | `` | Filter tasks with due date on or before |
| `search` | No | `string` | `` | Search query across title and description |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TSK-003 — Get current employee assigned and created tasks

**بتعمل إيه؟**:
متابعة وإدارة المهام التشغيلية ومستوى إنجاز فرق العمل داخل الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/tasks/my`
- **Controller**: `TasksController -> ApiOperation()`
- **Service Execution**: `tasksService.findAll()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Task`, `TaskAssignment`, `TaskComment`, `TaskAttachment`

**Purpose & Business Context**:
Get current employee assigned and created tasks. This endpoint operates with strict transactional integrity under the Tasks & Work Execution subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `status` | No | `string` | `` | Filter parameter: status |
| `priority` | No | `string` | `` | Filter parameter: priority |
| `assigneeId` | No | `string` | `` | Filter by assigned EmployeeProfile ID |
| `creatorId` | No | `string` | `` | Filter by creator User ID |
| `departmentId` | No | `string` | `` | Filter by Department ID |
| `workplaceId` | No | `string` | `` | Filter by Workplace ID |
| `isOverdue` | No | `boolean` | `` | Filter overdue tasks |
| `startDate` | No | `string` | `` | Filter tasks with due date on or after |
| `endDate` | No | `string` | `` | Filter tasks with due date on or before |
| `search` | No | `string` | `` | Search query across title and description |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TSK-004 — Get task details including checklist, comments, and attachments

**بتعمل إيه؟**:
متابعة وإدارة المهام التشغيلية ومستوى إنجاز فرق العمل داخل الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/tasks/{id}`
- **Controller**: `TasksController -> ApiOperation()`
- **Service Execution**: `tasksService.findAll()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Task`, `TaskAssignment`, `TaskComment`, `TaskAttachment`

**Purpose & Business Context**:
Get task details including checklist, comments, and attachments. This endpoint operates with strict transactional integrity under the Tasks & Work Execution subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TSK-005 — Update task metadata, priority, due date, or progress

**بتعمل إيه؟**:
متابعة وإدارة المهام التشغيلية ومستوى إنجاز فرق العمل داخل الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/tasks/{id}`
- **Controller**: `TasksController -> UseGuards()`
- **Service Execution**: `tasksService.updateTask()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Task`, `TaskAssignment`, `TaskComment`, `TaskAttachment`

**Purpose & Business Context**:
Update task metadata, priority, due date, or progress. This endpoint operates with strict transactional integrity under the Tasks & Work Execution subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "title": "Implement Phase 5 Tasks & Reports",
  "description": "sample_description",
  "priority": "MEDIUM",
  "assigneeId": "sample-uuid-v4",
  "departmentId": "sample-uuid-v4",
  "workplaceId": "sample-uuid-v4",
  "startDate": "2026-09-03T09:00:00Z",
  "dueDate": "2026-09-10T18:00:00Z",
  "checklist": [],
  "metadata": null,
  "progress": 75
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TSK-006 — Delete or cancel task

**بتعمل إيه؟**:
متابعة وإدارة المهام التشغيلية ومستوى إنجاز فرق العمل داخل الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/tasks/{id}`
- **Controller**: `TasksController -> UseGuards()`
- **Service Execution**: `tasksService.deleteChecklistItem()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Task`, `TaskAssignment`, `TaskComment`, `TaskAttachment`

**Purpose & Business Context**:
Delete or cancel task. This endpoint operates with strict transactional integrity under the Tasks & Work Execution subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TSK-007 — Assign or reassign task to an employee

**بتعمل إيه؟**:
إنشاء مهمة عمل جديدة وتكليف موظف أو فريق بإنجازها مع تحديد الموعد النهائي والأولوية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/tasks/{id}/assign`
- **Controller**: `TasksController -> Roles()`
- **Service Execution**: `tasksService.createTask()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Task`, `TaskAssignment`, `TaskComment`, `TaskAttachment`

**Purpose & Business Context**:
Assign or reassign task to an employee. This endpoint operates with strict transactional integrity under the Tasks & Work Execution subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "assigneeId": "emp-uuid-123",
  "notes": "sample_notes"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TSK-008 — Assigned employee accepts task (TODO -> ACCEPTED)

**بتعمل إيه؟**:
إنشاء مهمة عمل جديدة وتكليف موظف أو فريق بإنجازها مع تحديد الموعد النهائي والأولوية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/tasks/{id}/accept`
- **Controller**: `TasksController -> Roles()`
- **Service Execution**: `tasksService.createTask()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Task`, `TaskAssignment`, `TaskComment`, `TaskAttachment`

**Purpose & Business Context**:
Assigned employee accepts task (TODO -> ACCEPTED). This endpoint operates with strict transactional integrity under the Tasks & Work Execution subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TSK-009 — Update task lifecycle status (IN_PROGRESS, BLOCKED, etc.)

**بتعمل إيه؟**:
تحديث حالة المهمة (جارية، معلقة، مكتملة) وتوثيق نسبة الإنجاز.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/tasks/{id}/status`
- **Controller**: `TasksController -> Roles()`
- **Service Execution**: `tasksService.createTask()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Task`, `TaskAssignment`, `TaskComment`, `TaskAttachment`

**Purpose & Business Context**:
Update task lifecycle status (IN_PROGRESS, BLOCKED, etc.). This endpoint operates with strict transactional integrity under the Tasks & Work Execution subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "status": "IN_PROGRESS",
  "reason": "Starting implementation"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TSK-010 — Add checklist item to task

**بتعمل إيه؟**:
إنشاء مهمة عمل جديدة وتكليف موظف أو فريق بإنجازها مع تحديد الموعد النهائي والأولوية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/tasks/{id}/checklist`
- **Controller**: `TasksController -> Roles()`
- **Service Execution**: `tasksService.createTask()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Task`, `TaskAssignment`, `TaskComment`, `TaskAttachment`

**Purpose & Business Context**:
Add checklist item to task. This endpoint operates with strict transactional integrity under the Tasks & Work Execution subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "title": "Verify DB indexes",
  "orderIndex": 0
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TSK-011 — Toggle or update checklist item (auto-updates progress %)

**بتعمل إيه؟**:
متابعة وإدارة المهام التشغيلية ومستوى إنجاز فرق العمل داخل الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/tasks/{id}/checklist/{itemId}`
- **Controller**: `TasksController -> UseGuards()`
- **Service Execution**: `tasksService.updateTask()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Task`, `TaskAssignment`, `TaskComment`, `TaskAttachment`

**Purpose & Business Context**:
Toggle or update checklist item (auto-updates progress %). This endpoint operates with strict transactional integrity under the Tasks & Work Execution subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |
| `itemId` | `string` | `id-12345` | Identifier parameter: itemId |

**Request Body Payload**:
```json
{
  "title": "sample_title",
  "isCompleted": true,
  "orderIndex": 100
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TSK-012 — Delete checklist item from task

**بتعمل إيه؟**:
متابعة وإدارة المهام التشغيلية ومستوى إنجاز فرق العمل داخل الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/tasks/{id}/checklist/{itemId}`
- **Controller**: `TasksController -> UseGuards()`
- **Service Execution**: `tasksService.deleteChecklistItem()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Task`, `TaskAssignment`, `TaskComment`, `TaskAttachment`

**Purpose & Business Context**:
Delete checklist item from task. This endpoint operates with strict transactional integrity under the Tasks & Work Execution subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |
| `itemId` | `string` | `id-12345` | Identifier parameter: itemId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TSK-013 — Add comment to task

**بتعمل إيه؟**:
إنشاء مهمة عمل جديدة وتكليف موظف أو فريق بإنجازها مع تحديد الموعد النهائي والأولوية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/tasks/{id}/comments`
- **Controller**: `TasksController -> Roles()`
- **Service Execution**: `tasksService.createTask()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Task`, `TaskAssignment`, `TaskComment`, `TaskAttachment`

**Purpose & Business Context**:
Add comment to task. This endpoint operates with strict transactional integrity under the Tasks & Work Execution subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "content": "Checklist items 1 and 2 completed.",
  "attachmentUrl": "sample_attachmentUrl"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TSK-014 — Get all comments for a task

**بتعمل إيه؟**:
متابعة وإدارة المهام التشغيلية ومستوى إنجاز فرق العمل داخل الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/tasks/{id}/comments`
- **Controller**: `TasksController -> ApiOperation()`
- **Service Execution**: `tasksService.findAll()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Task`, `TaskAssignment`, `TaskComment`, `TaskAttachment`

**Purpose & Business Context**:
Get all comments for a task. This endpoint operates with strict transactional integrity under the Tasks & Work Execution subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TSK-015 — Attach file metadata to task

**بتعمل إيه؟**:
إنشاء مهمة عمل جديدة وتكليف موظف أو فريق بإنجازها مع تحديد الموعد النهائي والأولوية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/tasks/{id}/attachments`
- **Controller**: `TasksController -> Roles()`
- **Service Execution**: `tasksService.createTask()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Task`, `TaskAssignment`, `TaskComment`, `TaskAttachment`

**Purpose & Business Context**:
Attach file metadata to task. This endpoint operates with strict transactional integrity under the Tasks & Work Execution subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "fileName": "architecture-diagram.pdf",
  "fileUrl": "https://storage.cyberwise.internal/tasks/att-123.pdf",
  "fileSize": 1048576,
  "mimeType": "application/pdf"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TSK-016 — List task attachments

**بتعمل إيه؟**:
متابعة وإدارة المهام التشغيلية ومستوى إنجاز فرق العمل داخل الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/tasks/{id}/attachments`
- **Controller**: `TasksController -> ApiOperation()`
- **Service Execution**: `tasksService.findAll()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Task`, `TaskAssignment`, `TaskComment`, `TaskAttachment`

**Purpose & Business Context**:
List task attachments. This endpoint operates with strict transactional integrity under the Tasks & Work Execution subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TSK-017 — Get chronological audit history for a task

**بتعمل إيه؟**:
متابعة وإدارة المهام التشغيلية ومستوى إنجاز فرق العمل داخل الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/tasks/{id}/history`
- **Controller**: `TasksController -> ApiOperation()`
- **Service Execution**: `tasksService.findAll()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Task`, `TaskAssignment`, `TaskComment`, `TaskAttachment`

**Purpose & Business Context**:
Get chronological audit history for a task. This endpoint operates with strict transactional integrity under the Tasks & Work Execution subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Work Management & Approvals

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **WKM-001** | `POST` | `/api/v1/work-management/tasks/{id}/report` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Employee submits task execution report upon finishing work (Transitions task to PENDING_REVIEW) |
| **WKM-002** | `POST` | `/api/v1/work-management/tasks/{id}/review` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Manager reviews task report: APPROVE (completes task) or REJECT (returns to IN_PROGRESS) |
| **WKM-003** | `GET` | `/api/v1/work-management/pending-reviews` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get queue of pending task reviews for manager |
| **WKM-004** | `GET` | `/api/v1/work-management/department-workload` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get team/department workload breakdown, task distribution & capacity |
| **WKM-005** | `POST` | `/api/v1/work-management/check-overdue` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Trigger low-resource scan to flag overdue tasks |

### WKM-001 — Employee submits task execution report upon finishing work (Transitions task to PENDING_REVIEW)

**بتعمل إيه؟**:
إدارة عمليات مراجعة واعتماد طلبات الموظفين والأعمال الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/work-management/tasks/{id}/report`
- **Controller**: `WorkManagementController -> ApiOperation()`
- **Service Execution**: `workService.submitTaskReport()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `WorkTask`, `ApprovalFlow`, `EmployeeProfile`

**Purpose & Business Context**:
Employee submits task execution report upon finishing work (Transitions task to PENDING_REVIEW). This endpoint operates with strict transactional integrity under the Work Management & Approvals subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "summary": "Completed unit and integration tests with 100% coverage",
  "challenges": "Encountered initial flakiness in async DB mock, resolved via transactional isolation.",
  "hoursSpent": 4.5,
  "progress": 100,
  "attachments": [
    {
      "fileName": "test-report.pdf",
      "fileUrl": "https://cyberwise.test/test-report.pdf"
    }
  ]
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### WKM-002 — Manager reviews task report: APPROVE (completes task) or REJECT (returns to IN_PROGRESS)

**بتعمل إيه؟**:
إدارة عمليات مراجعة واعتماد طلبات الموظفين والأعمال الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/work-management/tasks/{id}/review`
- **Controller**: `WorkManagementController -> ApiOperation()`
- **Service Execution**: `workService.submitTaskReport()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `WorkTask`, `ApprovalFlow`, `EmployeeProfile`

**Purpose & Business Context**:
Manager reviews task report: APPROVE (completes task) or REJECT (returns to IN_PROGRESS). This endpoint operates with strict transactional integrity under the Work Management & Approvals subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "action": "APPROVE",
  "reviewNotes": "Work verified and approved according to QA guidelines.",
  "rating": 5
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### WKM-003 — Get queue of pending task reviews for manager

**بتعمل إيه؟**:
جلب قائمة الطلبات المعلقة التي تنتظر موافقة أو توقيع المستخدم الحالي.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/work-management/pending-reviews`
- **Controller**: `WorkManagementController -> Roles()`
- **Service Execution**: `workService.getPendingReviews()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `WorkTask`, `ApprovalFlow`, `EmployeeProfile`

**Purpose & Business Context**:
Get queue of pending task reviews for manager. This endpoint operates with strict transactional integrity under the Work Management & Approvals subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | **Yes** | `number` | `` | Filter parameter: page |
| `limit` | **Yes** | `number` | `` | Filter parameter: limit |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### WKM-004 — Get team/department workload breakdown, task distribution & capacity

**بتعمل إيه؟**:
استعراض سجل الموافقات والاعتمادات السابقة وحالاتها وملاحظات المديرين.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/work-management/department-workload`
- **Controller**: `WorkManagementController -> Roles()`
- **Service Execution**: `workService.getPendingReviews()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `WorkTask`, `ApprovalFlow`, `EmployeeProfile`

**Purpose & Business Context**:
Get team/department workload breakdown, task distribution & capacity. This endpoint operates with strict transactional integrity under the Work Management & Approvals subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `departmentId` | No | `string` | `` | Department ID filter |
| `workplaceId` | No | `string` | `` | Workplace ID filter |
| `startDate` | No | `string` | `` | Filter from date |
| `endDate` | No | `string` | `` | Filter to date |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### WKM-005 — Trigger low-resource scan to flag overdue tasks

**بتعمل إيه؟**:
إدارة عمليات مراجعة واعتماد طلبات الموظفين والأعمال الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/work-management/check-overdue`
- **Controller**: `WorkManagementController -> ApiOperation()`
- **Service Execution**: `workService.submitTaskReport()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `WorkTask`, `ApprovalFlow`, `EmployeeProfile`

**Purpose & Business Context**:
Trigger low-resource scan to flag overdue tasks. This endpoint operates with strict transactional integrity under the Work Management & Approvals subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Service Requests

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **SRV-001** | `POST` | `/api/v1/service-requests` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Create a new service request |
| **SRV-002** | `GET` | `/api/v1/service-requests` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | List service requests with filters and pagination |
| **SRV-003** | `GET` | `/api/v1/service-requests/{id}` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Get service request details by ID |
| **SRV-004** | `PATCH` | `/api/v1/service-requests/{id}/assign` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Assign service request to an employee / technician |
| **SRV-005** | `PATCH` | `/api/v1/service-requests/{id}/start` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Start working on a service request (status -> IN_PROGRESS) |
| **SRV-006** | `PATCH` | `/api/v1/service-requests/{id}/complete` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Mark service request as COMPLETED with resolution notes |
| **SRV-007** | `POST` | `/api/v1/service-requests/{id}/review` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Customer/Requester review and sign-off (ACCEPT or REVISION) |
| **SRV-008** | `PATCH` | `/api/v1/service-requests/{id}/close` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Directly close a service request |
| **SRV-009** | `PATCH` | `/api/v1/service-requests/{id}/cancel` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Cancel a service request (by requester or admin) |
| **SRV-010** | `PATCH` | `/api/v1/service-requests/{id}/reject` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Reject a service request (by department supervisor or admin) |
| **SRV-011** | `POST` | `/api/v1/service-requests/{id}/comments` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Add a comment or internal note to the service request |

### SRV-001 — Create a new service request

**بتعمل إيه؟**:
إنشاء طلب خدمة فندقية جديد من النزيل أو القسم وتوجيهه للجهة المختصة.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/service-requests`
- **Controller**: `ServiceRequestsController -> ApiOperation()`
- **Service Execution**: `serviceRequestsService.createServiceRequest()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ServiceRequest`, `ServiceRequestComment`, `ServiceRequestAttachment`

**Purpose & Business Context**:
Create a new service request. This endpoint operates with strict transactional integrity under the Service Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "title": "Printer malfunctioning in 3rd Floor Finance Room",
  "description": "The HP LaserJet printer shows paper jam and red error code 50.4.",
  "category": "GENERAL",
  "priority": "MEDIUM",
  "departmentId": "dept-it-uuid",
  "location": "Floor 3, Office 302",
  "dueDate": "2026-09-05T17:00:00Z",
  "metadata": null
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SRV-002 — List service requests with filters and pagination

**بتعمل إيه؟**:
إدارة ومتابعة طلبات الخدمات الفندقية ومعدل سرعة الاستجابة وخدمة النزلاء.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/service-requests`
- **Controller**: `ServiceRequestsController -> ApiOperation()`
- **Service Execution**: `serviceRequestsService.listServiceRequests()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ServiceRequest`, `ServiceRequestComment`, `ServiceRequestAttachment`

**Purpose & Business Context**:
List service requests with filters and pagination. This endpoint operates with strict transactional integrity under the Service Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search by title, description, or request number |
| `status` | No | `string` | `` | Filter parameter: status |
| `priority` | No | `string` | `` | Filter parameter: priority |
| `category` | No | `string` | `` | Filter parameter: category |
| `departmentId` | No | `string` | `` | Filter by servicing Department ID |
| `requesterId` | No | `string` | `` | Filter by requester EmployeeProfile ID |
| `assignedToId` | No | `string` | `` | Filter by assigned technician EmployeeProfile ID |
| `startDate` | No | `string` | `` | Start date filter |
| `endDate` | No | `string` | `` | End date filter |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SRV-003 — Get service request details by ID

**بتعمل إيه؟**:
إدارة ومتابعة طلبات الخدمات الفندقية ومعدل سرعة الاستجابة وخدمة النزلاء.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/service-requests/{id}`
- **Controller**: `ServiceRequestsController -> ApiOperation()`
- **Service Execution**: `serviceRequestsService.listServiceRequests()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ServiceRequest`, `ServiceRequestComment`, `ServiceRequestAttachment`

**Purpose & Business Context**:
Get service request details by ID. This endpoint operates with strict transactional integrity under the Service Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SRV-004 — Assign service request to an employee / technician

**بتعمل إيه؟**:
إسناد طلب خدمة فندقية (مثل تنظيف، خدمة غرف، حقائب) إلى موظف التنفيذ المتاح.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/service-requests/{id}/assign`
- **Controller**: `ServiceRequestsController -> UseGuards()`
- **Service Execution**: `serviceRequestsService.assignServiceRequest()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ServiceRequest`, `ServiceRequestComment`, `ServiceRequestAttachment`

**Purpose & Business Context**:
Assign service request to an employee / technician. This endpoint operates with strict transactional integrity under the Service Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "assignedToId": "emp-tech-101",
  "dueDate": "2026-09-06T18:00:00Z",
  "notes": "Please bring replacement toner cartridge."
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SRV-005 — Start working on a service request (status -> IN_PROGRESS)

**بتعمل إيه؟**:
إدارة ومتابعة طلبات الخدمات الفندقية ومعدل سرعة الاستجابة وخدمة النزلاء.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/service-requests/{id}/start`
- **Controller**: `ServiceRequestsController -> UseGuards()`
- **Service Execution**: `serviceRequestsService.assignServiceRequest()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ServiceRequest`, `ServiceRequestComment`, `ServiceRequestAttachment`

**Purpose & Business Context**:
Start working on a service request (status -> IN_PROGRESS). This endpoint operates with strict transactional integrity under the Service Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SRV-006 — Mark service request as COMPLETED with resolution notes

**بتعمل إيه؟**:
إدارة ومتابعة طلبات الخدمات الفندقية ومعدل سرعة الاستجابة وخدمة النزلاء.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/service-requests/{id}/complete`
- **Controller**: `ServiceRequestsController -> UseGuards()`
- **Service Execution**: `serviceRequestsService.assignServiceRequest()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ServiceRequest`, `ServiceRequestComment`, `ServiceRequestAttachment`

**Purpose & Business Context**:
Mark service request as COMPLETED with resolution notes. This endpoint operates with strict transactional integrity under the Service Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "status": "IN_PROGRESS",
  "resolutionNotes": "Paper jam cleared, rollers cleaned and test print passed.",
  "reason": "Duplicate request already addressed under SR-2026-0012.",
  "notes": "sample_notes"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SRV-007 — Customer/Requester review and sign-off (ACCEPT or REVISION)

**بتعمل إيه؟**:
إنشاء طلب خدمة فندقية جديد من النزيل أو القسم وتوجيهه للجهة المختصة.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/service-requests/{id}/review`
- **Controller**: `ServiceRequestsController -> ApiOperation()`
- **Service Execution**: `serviceRequestsService.createServiceRequest()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ServiceRequest`, `ServiceRequestComment`, `ServiceRequestAttachment`

**Purpose & Business Context**:
Customer/Requester review and sign-off (ACCEPT or REVISION). This endpoint operates with strict transactional integrity under the Service Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "rating": 5,
  "feedback": "The technician arrived fast and fixed the problem thoroughly.",
  "decision": "ACCEPT"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SRV-008 — Directly close a service request

**بتعمل إيه؟**:
إدارة ومتابعة طلبات الخدمات الفندقية ومعدل سرعة الاستجابة وخدمة النزلاء.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/service-requests/{id}/close`
- **Controller**: `ServiceRequestsController -> UseGuards()`
- **Service Execution**: `serviceRequestsService.assignServiceRequest()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ServiceRequest`, `ServiceRequestComment`, `ServiceRequestAttachment`

**Purpose & Business Context**:
Directly close a service request. This endpoint operates with strict transactional integrity under the Service Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SRV-009 — Cancel a service request (by requester or admin)

**بتعمل إيه؟**:
إدارة ومتابعة طلبات الخدمات الفندقية ومعدل سرعة الاستجابة وخدمة النزلاء.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/service-requests/{id}/cancel`
- **Controller**: `ServiceRequestsController -> UseGuards()`
- **Service Execution**: `serviceRequestsService.assignServiceRequest()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ServiceRequest`, `ServiceRequestComment`, `ServiceRequestAttachment`

**Purpose & Business Context**:
Cancel a service request (by requester or admin). This endpoint operates with strict transactional integrity under the Service Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SRV-010 — Reject a service request (by department supervisor or admin)

**بتعمل إيه؟**:
إدارة ومتابعة طلبات الخدمات الفندقية ومعدل سرعة الاستجابة وخدمة النزلاء.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/service-requests/{id}/reject`
- **Controller**: `ServiceRequestsController -> UseGuards()`
- **Service Execution**: `serviceRequestsService.assignServiceRequest()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ServiceRequest`, `ServiceRequestComment`, `ServiceRequestAttachment`

**Purpose & Business Context**:
Reject a service request (by department supervisor or admin). This endpoint operates with strict transactional integrity under the Service Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SRV-011 — Add a comment or internal note to the service request

**بتعمل إيه؟**:
إنشاء طلب خدمة فندقية جديد من النزيل أو القسم وتوجيهه للجهة المختصة.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/service-requests/{id}/comments`
- **Controller**: `ServiceRequestsController -> ApiOperation()`
- **Service Execution**: `serviceRequestsService.createServiceRequest()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ServiceRequest`, `ServiceRequestComment`, `ServiceRequestAttachment`

**Purpose & Business Context**:
Add a comment or internal note to the service request. This endpoint operates with strict transactional integrity under the Service Requests subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "content": "Waiting for replacement toner cartridge from supplier.",
  "attachmentUrl": "sample_attachmentUrl",
  "isInternal": false
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Shift Handover

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **HND-001** | `POST` | `/api/v1/handover` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Create a new shift handover with notes & open tasks |
| **HND-002** | `GET` | `/api/v1/handover` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | List shift handovers with filters and pagination |
| **HND-003** | `GET` | `/api/v1/handover/{id}` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Get shift handover details by ID |
| **HND-004** | `PATCH` | `/api/v1/handover/{id}/acknowledge` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Acknowledge, flag or reject a shift handover |
| **HND-005** | `POST` | `/api/v1/handover/{id}/items` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Add an item, task, or incident to the shift handover |

### HND-001 — Create a new shift handover with notes & open tasks

**بتعمل إيه؟**:
تسجيل محضر تسليم واستلام الوردية (Handover) وتدوين الملاحظات والمهام المعلقة للوردية القادمة.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/handover`
- **Controller**: `HandoverController -> ApiOperation()`
- **Service Execution**: `handoverService.createHandover()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ShiftHandover`, `HandoverNote`, `ShiftHandoverItem`

**Purpose & Business Context**:
Create a new shift handover with notes & open tasks. This endpoint operates with strict transactional integrity under the Shift Handover subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "shiftDate": "2026-09-03",
  "shiftName": "Morning Shift (08:00 - 16:00)",
  "departmentId": "dept-ops-uuid",
  "workplaceId": "sample-uuid-v4",
  "scheduleId": "sample-uuid-v4",
  "receivedById": "sample-uuid-v4",
  "summary": "All regular duties fulfilled; 2 ongoing facility tickets transferred to evening shift.",
  "notes": "sample_notes",
  "includeOpenTasks": true,
  "items": [],
  "metadata": null
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### HND-002 — List shift handovers with filters and pagination

**بتعمل إيه؟**:
استعراض سجلات تسليم الورديات بين موظفي الأقسام الفندقية للتحقق من استمرارية التشغيل.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/handover`
- **Controller**: `HandoverController -> ApiOperation()`
- **Service Execution**: `handoverService.listHandovers()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ShiftHandover`, `HandoverNote`, `ShiftHandoverItem`

**Purpose & Business Context**:
List shift handovers with filters and pagination. This endpoint operates with strict transactional integrity under the Shift Handover subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `10` | Filter parameter: limit |
| `search` | No | `string` | `` | Search by summary, notes, or handover number |
| `status` | No | `string` | `` | Filter parameter: status |
| `departmentId` | No | `string` | `` | Filter by Department ID |
| `workplaceId` | No | `string` | `` | Filter by Workplace ID |
| `handedOverById` | No | `string` | `` | Filter by outgoing EmployeeProfile ID |
| `receivedById` | No | `string` | `` | Filter by receiving EmployeeProfile ID |
| `shiftDate` | No | `string` | `` | Filter by specific shift date (YYYY-MM-DD) |
| `startDate` | No | `string` | `` | Start date range filter |
| `endDate` | No | `string` | `` | End date range filter |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### HND-003 — Get shift handover details by ID

**بتعمل إيه؟**:
استعراض سجلات تسليم الورديات بين موظفي الأقسام الفندقية للتحقق من استمرارية التشغيل.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/handover/{id}`
- **Controller**: `HandoverController -> ApiOperation()`
- **Service Execution**: `handoverService.listHandovers()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ShiftHandover`, `HandoverNote`, `ShiftHandoverItem`

**Purpose & Business Context**:
Get shift handover details by ID. This endpoint operates with strict transactional integrity under the Shift Handover subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### HND-004 — Acknowledge, flag or reject a shift handover

**بتعمل إيه؟**:
استعراض سجلات تسليم الورديات بين موظفي الأقسام الفندقية للتحقق من استمرارية التشغيل.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/handover/{id}/acknowledge`
- **Controller**: `HandoverController -> UseGuards()`
- **Service Execution**: `handoverService.acknowledgeHandover()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ShiftHandover`, `HandoverNote`, `ShiftHandoverItem`

**Purpose & Business Context**:
Acknowledge, flag or reject a shift handover. This endpoint operates with strict transactional integrity under the Shift Handover subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "action": "ACKNOWLEDGE",
  "acknowledgementNotes": "Shift received, all tools and open items verified on site.",
  "discrepancyNotes": "Toolbox #3 key is missing from the designated cabinet."
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### HND-005 — Add an item, task, or incident to the shift handover

**بتعمل إيه؟**:
تسجيل محضر تسليم واستلام الوردية (Handover) وتدوين الملاحظات والمهام المعلقة للوردية القادمة.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/handover/{id}/items`
- **Controller**: `HandoverController -> ApiOperation()`
- **Service Execution**: `handoverService.createHandover()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ShiftHandover`, `HandoverNote`, `ShiftHandoverItem`

**Purpose & Business Context**:
Add an item, task, or incident to the shift handover. This endpoint operates with strict transactional integrity under the Shift Handover subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "title": "Late delivery of spare parts expected at 20:00",
  "description": "sample_description",
  "category": "GENERAL",
  "priority": "MEDIUM",
  "taskId": "sample-uuid-v4",
  "serviceRequestId": "sample-uuid-v4",
  "requiresAction": true
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Department Operations

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **DPT-001** | `GET` | `/api/v1/department-operations/overview` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Get real-time operational telemetry and dashboard for a department |
| **DPT-002** | `POST` | `/api/v1/department-operations/triage` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Triage and assign a service request with priority & deadline |
| **DPT-003** | `GET` | `/api/v1/department-operations/reports` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Get operational KPI report (completion rates, resolution SLA, workload) |

### DPT-001 — Get real-time operational telemetry and dashboard for a department

**بتعمل إيه؟**:
إدارة ومتابعة العمليات التشغيلية واللوجستية الداخلية للأقسام الفندقية.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/department-operations/overview`
- **Controller**: `DepartmentOperationsController -> ApiOperation()`
- **Service Execution**: `departmentOperationsService.getOverview()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `DepartmentDailyOperation`, `DepartmentTask`, `Department`

**Purpose & Business Context**:
Get real-time operational telemetry and dashboard for a department. This endpoint operates with strict transactional integrity under the Department Operations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `departmentId` | **Yes** | `string` | `` | Department ID to view operational telemetry for |
| `date` | No | `string` | `` | Optional specific date for shift and attendance analysis (YYYY-MM-DD) |
| `workplaceId` | No | `string` | `` | Optional workplace filter |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### DPT-002 — Triage and assign a service request with priority & deadline

**بتعمل إيه؟**:
إدارة ومتابعة العمليات التشغيلية واللوجستية الداخلية للأقسام الفندقية.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/department-operations/triage`
- **Controller**: `DepartmentOperationsController -> ApiOperation()`
- **Service Execution**: `departmentOperationsService.triageServiceRequest()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `DepartmentDailyOperation`, `DepartmentTask`, `Department`

**Purpose & Business Context**:
Triage and assign a service request with priority & deadline. This endpoint operates with strict transactional integrity under the Department Operations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "serviceRequestId": "sr-uuid-1",
  "assignedToId": "emp-tech-1",
  "priority": "LOW",
  "dueDate": "2026-09-04T18:00:00Z",
  "notes": "sample_notes"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### DPT-003 — Get operational KPI report (completion rates, resolution SLA, workload)

**بتعمل إيه؟**:
إدارة ومتابعة العمليات التشغيلية واللوجستية الداخلية للأقسام الفندقية.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/department-operations/reports`
- **Controller**: `DepartmentOperationsController -> ApiOperation()`
- **Service Execution**: `departmentOperationsService.getOverview()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `DepartmentDailyOperation`, `DepartmentTask`, `Department`

**Purpose & Business Context**:
Get operational KPI report (completion rates, resolution SLA, workload). This endpoint operates with strict transactional integrity under the Department Operations subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `departmentId` | **Yes** | `string` | `` | Department ID |
| `startDate` | **Yes** | `string` | `` | Start date (YYYY-MM-DD) |
| `endDate` | **Yes** | `string` | `` | End date (YYYY-MM-DD) |
| `exportCsv` | No | `boolean` | `false` | Whether to return results formatted as CSV |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Assets Management

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **AST-001** | `POST` | `/api/v1/assets/categories` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Create an asset category |
| **AST-002** | `GET` | `/api/v1/assets/categories` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List all asset categories |
| **AST-003** | `POST` | `/api/v1/assets` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Register a new asset |
| **AST-004** | `GET` | `/api/v1/assets` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List assets with pagination and filters |
| **AST-005** | `GET` | `/api/v1/assets/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get asset details by ID |
| **AST-006** | `PATCH` | `/api/v1/assets/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Update asset metadata, status, location, or assignment |
| **AST-007** | `DELETE` | `/api/v1/assets/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Delete an asset |
| **AST-008** | `POST` | `/api/v1/assets/{id}/calculate-depreciation` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Calculate straight-line depreciation for an asset |

### AST-001 — Create an asset category

**بتعمل إيه؟**:
تسجيل أصل أو جهاز فندقي جديد في العهدة (مثل تكييفات، أثاث غرف، أجهزة مطبخ) وتحديد الباركود وقيمة الشراء.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/assets/categories`
- **Controller**: `AssetsController -> Roles()`
- **Service Execution**: `assetsService.createCategory()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Asset`, `AssetCategory`, `AssetAssignment`, `AssetMaintenanceLog`

**Purpose & Business Context**:
Create an asset category. This endpoint operates with strict transactional integrity under the Assets Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "name": "IT Equipment",
  "code": "CAT-IT-01",
  "description": "Laptops, monitors, networking gear",
  "usefulLifeMonths": 36,
  "depreciationRate": 20
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### AST-002 — List all asset categories

**بتعمل إيه؟**:
استعراض سجل الأصول والمعدات الفندقية وتوزيعها على الفروع والأقسام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/assets/categories`
- **Controller**: `AssetsController -> ApiOperation()`
- **Service Execution**: `assetsService.getCategories()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Asset`, `AssetCategory`, `AssetAssignment`, `AssetMaintenanceLog`

**Purpose & Business Context**:
List all asset categories. This endpoint operates with strict transactional integrity under the Assets Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### AST-003 — Register a new asset

**بتعمل إيه؟**:
تسجيل أصل أو جهاز فندقي جديد في العهدة (مثل تكييفات، أثاث غرف، أجهزة مطبخ) وتحديد الباركود وقيمة الشراء.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/assets`
- **Controller**: `AssetsController -> Roles()`
- **Service Execution**: `assetsService.createCategory()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Asset`, `AssetCategory`, `AssetAssignment`, `AssetMaintenanceLog`

**Purpose & Business Context**:
Register a new asset. This endpoint operates with strict transactional integrity under the Assets Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "assetCode": "AST-2026-0001",
  "name": "Dell Latitude 5440",
  "description": "Core i7 16GB RAM Laptop",
  "categoryId": "cat-uuid-123",
  "serialNumber": "SN-987654321",
  "barcode": "BC-12345678",
  "purchaseDate": "2026-01-15T00:00:00.000Z",
  "purchaseCost": 4500,
  "location": "Floor 2, Room 204",
  "status": "ACTIVE",
  "departmentId": "dept-uuid-456",
  "assignedToId": "emp-profile-uuid-789",
  "warrantyExpiry": "2028-01-15T00:00:00.000Z",
  "metadata": {
    "vendor": "Dell Inc",
    "poNumber": "PO-991"
  }
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### AST-004 — List assets with pagination and filters

**بتعمل إيه؟**:
استعراض سجل الأصول والمعدات الفندقية وتوزيعها على الفروع والأقسام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/assets`
- **Controller**: `AssetsController -> ApiOperation()`
- **Service Execution**: `assetsService.getCategories()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Asset`, `AssetCategory`, `AssetAssignment`, `AssetMaintenanceLog`

**Purpose & Business Context**:
List assets with pagination and filters. This endpoint operates with strict transactional integrity under the Assets Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `search` | No | `string` | `` | Search by name, assetCode, serialNumber, barcode |
| `status` | No | `string` | `` | Filter parameter: status |
| `categoryId` | No | `string` | `` | Filter parameter: categoryId |
| `departmentId` | No | `string` | `` | Filter parameter: departmentId |
| `assignedToId` | No | `string` | `` | Filter parameter: assignedToId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### AST-005 — Get asset details by ID

**بتعمل إيه؟**:
استعراض سجل الأصول والمعدات الفندقية وتوزيعها على الفروع والأقسام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/assets/{id}`
- **Controller**: `AssetsController -> ApiOperation()`
- **Service Execution**: `assetsService.getCategories()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Asset`, `AssetCategory`, `AssetAssignment`, `AssetMaintenanceLog`

**Purpose & Business Context**:
Get asset details by ID. This endpoint operates with strict transactional integrity under the Assets Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### AST-006 — Update asset metadata, status, location, or assignment

**بتعمل إيه؟**:
تحديث بيانات الأصل الفندقي (الموقع، الحالة التشغيلية، المسؤول عنه).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/assets/{id}`
- **Controller**: `AssetsController -> Roles()`
- **Service Execution**: `assetsService.updateAsset()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Asset`, `AssetCategory`, `AssetAssignment`, `AssetMaintenanceLog`

**Purpose & Business Context**:
Update asset metadata, status, location, or assignment. This endpoint operates with strict transactional integrity under the Assets Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "assetCode": "AST-2026-0001",
  "name": "Dell Latitude 5440",
  "description": "Core i7 16GB RAM Laptop",
  "categoryId": "cat-uuid-123",
  "serialNumber": "SN-987654321",
  "barcode": "BC-12345678",
  "purchaseDate": "2026-01-15T00:00:00.000Z",
  "purchaseCost": 4500,
  "location": "Floor 2, Room 204",
  "status": "ACTIVE",
  "departmentId": "dept-uuid-456",
  "assignedToId": "emp-profile-uuid-789",
  "warrantyExpiry": "2028-01-15T00:00:00.000Z",
  "metadata": {
    "vendor": "Dell Inc",
    "poNumber": "PO-991"
  }
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### AST-007 — Delete an asset

**بتعمل إيه؟**:
إدارة أصول ومعدات الفندق الثابتة وجردها وتتبع إهلاكها.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/assets/{id}`
- **Controller**: `AssetsController -> Roles()`
- **Service Execution**: `assetsService.deleteAsset()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Asset`, `AssetCategory`, `AssetAssignment`, `AssetMaintenanceLog`

**Purpose & Business Context**:
Delete an asset. This endpoint operates with strict transactional integrity under the Assets Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### AST-008 — Calculate straight-line depreciation for an asset

**بتعمل إيه؟**:
تسجيل أصل أو جهاز فندقي جديد في العهدة (مثل تكييفات، أثاث غرف، أجهزة مطبخ) وتحديد الباركود وقيمة الشراء.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/assets/{id}/calculate-depreciation`
- **Controller**: `AssetsController -> Roles()`
- **Service Execution**: `assetsService.createCategory()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Asset`, `AssetCategory`, `AssetAssignment`, `AssetMaintenanceLog`

**Purpose & Business Context**:
Calculate straight-line depreciation for an asset. This endpoint operates with strict transactional integrity under the Assets Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Maintenance Management

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **MNT-001** | `POST` | `/api/v1/maintenance/requests` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Create a maintenance request |
| **MNT-002** | `GET` | `/api/v1/maintenance/requests` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | List maintenance requests with pagination and filters |
| **MNT-003** | `GET` | `/api/v1/maintenance/requests/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get maintenance request details |
| **MNT-004** | `PATCH` | `/api/v1/maintenance/requests/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Update maintenance request status or resolution |
| **MNT-005** | `POST` | `/api/v1/maintenance/work-orders` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Create a maintenance work order |
| **MNT-006** | `GET` | `/api/v1/maintenance/work-orders` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | List work orders with pagination and filters |
| **MNT-007** | `GET` | `/api/v1/maintenance/work-orders/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get work order details including spare parts and technicians |
| **MNT-008** | `PATCH` | `/api/v1/maintenance/work-orders/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Update work order status, technician, or hours |
| **MNT-009** | `POST` | `/api/v1/maintenance/work-orders/{id}/spare-parts` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Consume spare parts on a work order and decrement inventory |
| **MNT-010** | `POST` | `/api/v1/maintenance/spare-parts` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Register a new spare part in catalog |
| **MNT-011** | `GET` | `/api/v1/maintenance/spare-parts` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | List all spare parts catalog |

### MNT-001 — Create a maintenance request

**بتعمل إيه؟**:
استعراض وإدارة بلاغات وأوامر الصيانة الفندقية ومؤشرات سرعة الإصلاح.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/maintenance/requests`
- **Controller**: `MaintenanceController -> ApiOperation()`
- **Service Execution**: `maintenanceService.createRequest()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `MaintenanceWorkOrder`, `MaintenanceSchedule`, `Asset`

**Purpose & Business Context**:
Create a maintenance request. This endpoint operates with strict transactional integrity under the Maintenance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "title": "AC leaking in Executive Suite 401",
  "description": "Water dripping from the indoor unit onto the carpet",
  "type": "CORRECTIVE",
  "priority": "MEDIUM",
  "assetId": "ast-uuid-123",
  "departmentId": "dept-engineering-uuid",
  "scheduledDate": "2026-09-04T10:00:00.000Z"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### MNT-002 — List maintenance requests with pagination and filters

**بتعمل إيه؟**:
استعراض وإدارة بلاغات وأوامر الصيانة الفندقية ومؤشرات سرعة الإصلاح.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/maintenance/requests`
- **Controller**: `MaintenanceController -> ApiOperation()`
- **Service Execution**: `maintenanceService.findRequests()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `MaintenanceWorkOrder`, `MaintenanceSchedule`, `Asset`

**Purpose & Business Context**:
List maintenance requests with pagination and filters. This endpoint operates with strict transactional integrity under the Maintenance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `search` | No | `string` | `` | Search by title, description, requestNumber |
| `status` | No | `string` | `` | Filter parameter: status |
| `type` | No | `string` | `` | Filter parameter: type |
| `priority` | No | `string` | `` | Filter parameter: priority |
| `departmentId` | No | `string` | `` | Filter parameter: departmentId |
| `assetId` | No | `string` | `` | Filter parameter: assetId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### MNT-003 — Get maintenance request details

**بتعمل إيه؟**:
استعراض وإدارة بلاغات وأوامر الصيانة الفندقية ومؤشرات سرعة الإصلاح.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/maintenance/requests/{id}`
- **Controller**: `MaintenanceController -> ApiOperation()`
- **Service Execution**: `maintenanceService.findRequests()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `MaintenanceWorkOrder`, `MaintenanceSchedule`, `Asset`

**Purpose & Business Context**:
Get maintenance request details. This endpoint operates with strict transactional integrity under the Maintenance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### MNT-004 — Update maintenance request status or resolution

**بتعمل إيه؟**:
استعراض وإدارة بلاغات وأوامر الصيانة الفندقية ومؤشرات سرعة الإصلاح.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/maintenance/requests/{id}`
- **Controller**: `MaintenanceController -> Roles()`
- **Service Execution**: `maintenanceService.updateRequest()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `MaintenanceWorkOrder`, `MaintenanceSchedule`, `Asset`

**Purpose & Business Context**:
Update maintenance request status or resolution. This endpoint operates with strict transactional integrity under the Maintenance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "status": "SUBMITTED",
  "priority": "LOW",
  "resolutionNotes": "Resolved by replacing the drainage tube.",
  "scheduledDate": "2026-09-05T14:00:00.000Z"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### MNT-005 — Create a maintenance work order

**بتعمل إيه؟**:
إصدار أمر شغل صيانة جديد (Work Order) لعطل في غرفة أو مرفق بالفندق مع تحديد درجة الأهمية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/maintenance/work-orders`
- **Controller**: `MaintenanceController -> ApiOperation()`
- **Service Execution**: `maintenanceService.createRequest()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `MaintenanceWorkOrder`, `MaintenanceSchedule`, `Asset`

**Purpose & Business Context**:
Create a maintenance work order. This endpoint operates with strict transactional integrity under the Maintenance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "maintenanceRequestId": "maint-req-uuid",
  "title": "Repair HVAC Unit in Suite 401",
  "description": "Inspect compressor, replace drainage pipe, clean filter",
  "priority": "MEDIUM",
  "status": "PENDING",
  "technicianId": "emp-tech-profile-uuid",
  "estimatedHours": 2.5,
  "notes": "Requires ladder and vacuum drain pump"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Asset (AST-003)

---

### MNT-006 — List work orders with pagination and filters

**بتعمل إيه؟**:
متابعة وإدارة أوامر شغل الصيانة المفتوحة والجارية والمنتهية في الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/maintenance/work-orders`
- **Controller**: `MaintenanceController -> ApiOperation()`
- **Service Execution**: `maintenanceService.findRequests()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `MaintenanceWorkOrder`, `MaintenanceSchedule`, `Asset`

**Purpose & Business Context**:
List work orders with pagination and filters. This endpoint operates with strict transactional integrity under the Maintenance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `search` | No | `string` | `` | Search by title, description, orderNumber |
| `status` | No | `string` | `` | Filter parameter: status |
| `priority` | No | `string` | `` | Filter parameter: priority |
| `technicianId` | No | `string` | `` | Filter parameter: technicianId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Asset (AST-003)

---

### MNT-007 — Get work order details including spare parts and technicians

**بتعمل إيه؟**:
متابعة وإدارة أوامر شغل الصيانة المفتوحة والجارية والمنتهية في الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/maintenance/work-orders/{id}`
- **Controller**: `MaintenanceController -> ApiOperation()`
- **Service Execution**: `maintenanceService.findRequests()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `MaintenanceWorkOrder`, `MaintenanceSchedule`, `Asset`

**Purpose & Business Context**:
Get work order details including spare parts and technicians. This endpoint operates with strict transactional integrity under the Maintenance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Asset (AST-003)

---

### MNT-008 — Update work order status, technician, or hours

**بتعمل إيه؟**:
متابعة وإدارة أوامر شغل الصيانة المفتوحة والجارية والمنتهية في الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/maintenance/work-orders/{id}`
- **Controller**: `MaintenanceController -> Roles()`
- **Service Execution**: `maintenanceService.updateRequest()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `MaintenanceWorkOrder`, `MaintenanceSchedule`, `Asset`

**Purpose & Business Context**:
Update work order status, technician, or hours. This endpoint operates with strict transactional integrity under the Maintenance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "status": "PENDING",
  "priority": "LOW",
  "technicianId": "emp-tech-profile-uuid",
  "actualHours": 3,
  "cost": 150,
  "notes": "Replacement completed and tested successfully."
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Asset (AST-003)

---

### MNT-009 — Consume spare parts on a work order and decrement inventory

**بتعمل إيه؟**:
إصدار أمر شغل صيانة جديد (Work Order) لعطل في غرفة أو مرفق بالفندق مع تحديد درجة الأهمية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/maintenance/work-orders/{id}/spare-parts`
- **Controller**: `MaintenanceController -> ApiOperation()`
- **Service Execution**: `maintenanceService.createRequest()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `MaintenanceWorkOrder`, `MaintenanceSchedule`, `Asset`

**Purpose & Business Context**:
Consume spare parts on a work order and decrement inventory. This endpoint operates with strict transactional integrity under the Maintenance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "sparePartId": "spare-part-uuid",
  "quantity": 2
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Created Asset (AST-003)

---

### MNT-010 — Register a new spare part in catalog

**بتعمل إيه؟**:
استعراض وإدارة بلاغات وأوامر الصيانة الفندقية ومؤشرات سرعة الإصلاح.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/maintenance/spare-parts`
- **Controller**: `MaintenanceController -> ApiOperation()`
- **Service Execution**: `maintenanceService.createRequest()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `MaintenanceWorkOrder`, `MaintenanceSchedule`, `Asset`

**Purpose & Business Context**:
Register a new spare part in catalog. This endpoint operates with strict transactional integrity under the Maintenance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "partNumber": "PART-HVAC-01",
  "name": "Flexible Drainage Hose 1/2 inch",
  "description": "High durability flexible condensate pipe",
  "category": "HVAC",
  "unitOfMeasure": "METER",
  "unitCost": 25.5,
  "quantityOnHand": 50,
  "minQuantity": 10
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### MNT-011 — List all spare parts catalog

**بتعمل إيه؟**:
استعراض وإدارة بلاغات وأوامر الصيانة الفندقية ومؤشرات سرعة الإصلاح.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/maintenance/spare-parts`
- **Controller**: `MaintenanceController -> ApiOperation()`
- **Service Execution**: `maintenanceService.findRequests()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `MaintenanceWorkOrder`, `MaintenanceSchedule`, `Asset`

**Purpose & Business Context**:
List all spare parts catalog. This endpoint operates with strict transactional integrity under the Maintenance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Key & Physical Access Management

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **KEY-001** | `POST` | `/api/v1/keys` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Register a new physical key |
| **KEY-002** | `GET` | `/api/v1/keys` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | List physical keys with pagination and filters |
| **KEY-003** | `GET` | `/api/v1/keys/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get key details including active assignment and access history |
| **KEY-004** | `POST` | `/api/v1/keys/{id}/assign` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Assign a key to an employee |
| **KEY-005** | `POST` | `/api/v1/keys/assignments/{assignmentId}/return` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Return an assigned key and increment available copies |
| **KEY-006** | `POST` | `/api/v1/keys/{id}/access-log` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Log a physical access event for this key |

### KEY-001 — Register a new physical key

**بتعمل إيه؟**:
تسجيل مفتاح مادي أو بطاقة دخول إلكترونية جديدة في نظام الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/keys`
- **Controller**: `KeysController -> Roles()`
- **Service Execution**: `keysService.createKey()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `PhysicalKey`, `KeyLog`, `KeyHolder`

**Purpose & Business Context**:
Register a new physical key. This endpoint operates with strict transactional integrity under the Key & Physical Access Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "keyCode": "KEY-RM-401",
  "keyType": "ROOM",
  "name": "Master Key Suite 401",
  "location": "Front Desk Key Box 2, Slot 14",
  "totalCopies": 2,
  "status": "ACTIVE"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### KEY-002 — List physical keys with pagination and filters

**بتعمل إيه؟**:
إدارة ومتابعة حركة مفاتيح وكروت الغرف والمرافق الحيوية في الفندق لضمان الأمان.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/keys`
- **Controller**: `KeysController -> ApiOperation()`
- **Service Execution**: `keysService.findKeys()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `PhysicalKey`, `KeyLog`, `KeyHolder`

**Purpose & Business Context**:
List physical keys with pagination and filters. This endpoint operates with strict transactional integrity under the Key & Physical Access Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `search` | No | `string` | `` | Search by keyCode, name, location |
| `keyType` | No | `string` | `` | Filter parameter: keyType |
| `status` | No | `string` | `` | Filter parameter: status |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### KEY-003 — Get key details including active assignment and access history

**بتعمل إيه؟**:
إدارة ومتابعة حركة مفاتيح وكروت الغرف والمرافق الحيوية في الفندق لضمان الأمان.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/keys/{id}`
- **Controller**: `KeysController -> ApiOperation()`
- **Service Execution**: `keysService.findKeys()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `PhysicalKey`, `KeyLog`, `KeyHolder`

**Purpose & Business Context**:
Get key details including active assignment and access history. This endpoint operates with strict transactional integrity under the Key & Physical Access Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### KEY-004 — Assign a key to an employee

**بتعمل إيه؟**:
إصدار وتسليم مفتاح أو بطاقة غرفة/جناح فندقي لنزيل أو موظف مع تسجيل وقت التسليم.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/keys/{id}/assign`
- **Controller**: `KeysController -> Roles()`
- **Service Execution**: `keysService.createKey()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `PhysicalKey`, `KeyLog`, `KeyHolder`

**Purpose & Business Context**:
Assign a key to an employee. This endpoint operates with strict transactional integrity under the Key & Physical Access Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "employeeId": "emp-profile-uuid",
  "expectedReturnAt": "2026-09-03T18:00:00.000Z",
  "notes": "Assigned for cleaning shift"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### KEY-005 — Return an assigned key and increment available copies

**بتعمل إيه؟**:
إصدار وتسليم مفتاح أو بطاقة غرفة/جناح فندقي لنزيل أو موظف مع تسجيل وقت التسليم.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/keys/assignments/{assignmentId}/return`
- **Controller**: `KeysController -> Roles()`
- **Service Execution**: `keysService.createKey()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `PhysicalKey`, `KeyLog`, `KeyHolder`

**Purpose & Business Context**:
Return an assigned key and increment available copies. This endpoint operates with strict transactional integrity under the Key & Physical Access Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `assignmentId` | `string` | `id-12345` | Identifier parameter: assignmentId |

**Request Body Payload**:
```json
{
  "notes": "Returned in good condition"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### KEY-006 — Log a physical access event for this key

**بتعمل إيه؟**:
تسجيل مفتاح مادي أو بطاقة دخول إلكترونية جديدة في نظام الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/keys/{id}/access-log`
- **Controller**: `KeysController -> Roles()`
- **Service Execution**: `keysService.createKey()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `PhysicalKey`, `KeyLog`, `KeyHolder`

**Purpose & Business Context**:
Log a physical access event for this key. This endpoint operates with strict transactional integrity under the Key & Physical Access Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "action": "DOOR_OPENED",
  "employeeId": "emp-profile-uuid",
  "notes": "Accessed room 401 for room service"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Inventory & Stores

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **INV-001** | `POST` | `/api/v1/inventory/warehouses` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Create a new warehouse or storage location |
| **INV-002** | `GET` | `/api/v1/inventory/warehouses` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List all warehouses |
| **INV-003** | `POST` | `/api/v1/inventory/categories` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Create a stock category |
| **INV-004** | `GET` | `/api/v1/inventory/categories` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List stock categories |
| **INV-005** | `POST` | `/api/v1/inventory/items` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Create a new stock item with SKU, thresholds, and initial balance |
| **INV-006** | `GET` | `/api/v1/inventory/items` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List stock items with search, warehouse filter, and low-stock indicator |
| **INV-007** | `GET` | `/api/v1/inventory/items/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get stock item details |
| **INV-008** | `PATCH` | `/api/v1/inventory/items/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Update stock item metadata, thresholds, or pricing |
| **INV-009** | `POST` | `/api/v1/inventory/movements` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Execute a stock movement (RECEIVE, ISSUE, TRANSFER, ADJUST) |
| **INV-010** | `GET` | `/api/v1/inventory/movements` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List stock movement history with filters |
| **INV-011** | `POST` | `/api/v1/inventory/counts` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Initiate a physical inventory count audit session |
| **INV-012** | `GET` | `/api/v1/inventory/counts` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List stock count audit sessions |

### INV-001 — Create a new warehouse or storage location

**بتعمل إيه؟**:
إضافة صنف استهلاكي أو تشغيلي جديد إلى دليل أصناف المخازن الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/inventory/warehouses`
- **Controller**: `InventoryController -> Roles()`
- **Service Execution**: `inventoryService.createWarehouse()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `InventoryItem`, `InventoryCategory`, `StockTransaction`, `Warehouse`

**Purpose & Business Context**:
Create a new warehouse or storage location. This endpoint operates with strict transactional integrity under the Inventory & Stores subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "code": "WH-MAIN",
  "name": "Central Food & Beverage Store",
  "location": "Basement Level B2, Sector C",
  "departmentId": "dept-uuid",
  "isActive": true
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INV-002 — List all warehouses

**بتعمل إيه؟**:
متابعة وإدارة أرصدة المخازن والمستودعات الفندقية وحركات الأصناف ومستويات إعادة الطلب.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/inventory/warehouses`
- **Controller**: `InventoryController -> ApiOperation()`
- **Service Execution**: `inventoryService.findWarehouses()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `InventoryItem`, `InventoryCategory`, `StockTransaction`, `Warehouse`

**Purpose & Business Context**:
List all warehouses. This endpoint operates with strict transactional integrity under the Inventory & Stores subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INV-003 — Create a stock category

**بتعمل إيه؟**:
إضافة صنف استهلاكي أو تشغيلي جديد إلى دليل أصناف المخازن الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/inventory/categories`
- **Controller**: `InventoryController -> Roles()`
- **Service Execution**: `inventoryService.createWarehouse()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `InventoryItem`, `InventoryCategory`, `StockTransaction`, `Warehouse`

**Purpose & Business Context**:
Create a stock category. This endpoint operates with strict transactional integrity under the Inventory & Stores subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "code": "CAT-LINEN",
  "name": "Hotel Bedding & Linens",
  "description": "Sheets, pillowcases, bath towels, and bathrobes"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INV-004 — List stock categories

**بتعمل إيه؟**:
متابعة وإدارة أرصدة المخازن والمستودعات الفندقية وحركات الأصناف ومستويات إعادة الطلب.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/inventory/categories`
- **Controller**: `InventoryController -> ApiOperation()`
- **Service Execution**: `inventoryService.findWarehouses()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `InventoryItem`, `InventoryCategory`, `StockTransaction`, `Warehouse`

**Purpose & Business Context**:
List stock categories. This endpoint operates with strict transactional integrity under the Inventory & Stores subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INV-005 — Create a new stock item with SKU, thresholds, and initial balance

**بتعمل إيه؟**:
إضافة صنف استهلاكي أو تشغيلي جديد إلى دليل أصناف المخازن الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/inventory/items`
- **Controller**: `InventoryController -> Roles()`
- **Service Execution**: `inventoryService.createWarehouse()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `InventoryItem`, `InventoryCategory`, `StockTransaction`, `Warehouse`

**Purpose & Business Context**:
Create a new stock item with SKU, thresholds, and initial balance. This endpoint operates with strict transactional integrity under the Inventory & Stores subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "sku": "SKU-TOWEL-WHT-L",
  "barcode": "884920192831",
  "name": "White Luxury Bath Towel 70x140cm",
  "description": "100% Egyptian cotton, 600 GSM",
  "categoryId": "stock-cat-uuid",
  "warehouseId": "warehouse-uuid",
  "unitOfMeasure": "PCS",
  "unitPrice": 45,
  "costPrice": 30,
  "quantityOnHand": 100,
  "minThreshold": 20,
  "maxThreshold": 500,
  "reorderLevel": 30,
  "isActive": true
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INV-006 — List stock items with search, warehouse filter, and low-stock indicator

**بتعمل إيه؟**:
متابعة وإدارة أرصدة المخازن والمستودعات الفندقية وحركات الأصناف ومستويات إعادة الطلب.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/inventory/items`
- **Controller**: `InventoryController -> ApiOperation()`
- **Service Execution**: `inventoryService.findWarehouses()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `InventoryItem`, `InventoryCategory`, `StockTransaction`, `Warehouse`

**Purpose & Business Context**:
List stock items with search, warehouse filter, and low-stock indicator. This endpoint operates with strict transactional integrity under the Inventory & Stores subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `search` | No | `string` | `` | Search by sku, barcode, name |
| `warehouseId` | No | `string` | `` | Filter parameter: warehouseId |
| `categoryId` | No | `string` | `` | Filter parameter: categoryId |
| `lowStock` | No | `boolean` | `` | Filter items where quantityOnHand <= reorderLevel |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INV-007 — Get stock item details

**بتعمل إيه؟**:
متابعة وإدارة أرصدة المخازن والمستودعات الفندقية وحركات الأصناف ومستويات إعادة الطلب.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/inventory/items/{id}`
- **Controller**: `InventoryController -> ApiOperation()`
- **Service Execution**: `inventoryService.findWarehouses()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `InventoryItem`, `InventoryCategory`, `StockTransaction`, `Warehouse`

**Purpose & Business Context**:
Get stock item details. This endpoint operates with strict transactional integrity under the Inventory & Stores subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INV-008 — Update stock item metadata, thresholds, or pricing

**بتعمل إيه؟**:
متابعة وإدارة أرصدة المخازن والمستودعات الفندقية وحركات الأصناف ومستويات إعادة الطلب.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/inventory/items/{id}`
- **Controller**: `InventoryController -> Roles()`
- **Service Execution**: `inventoryService.updateStockItem()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `InventoryItem`, `InventoryCategory`, `StockTransaction`, `Warehouse`

**Purpose & Business Context**:
Update stock item metadata, thresholds, or pricing. This endpoint operates with strict transactional integrity under the Inventory & Stores subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "sku": "SKU-TOWEL-WHT-L",
  "barcode": "884920192831",
  "name": "White Luxury Bath Towel 70x140cm",
  "description": "100% Egyptian cotton, 600 GSM",
  "categoryId": "stock-cat-uuid",
  "warehouseId": "warehouse-uuid",
  "unitOfMeasure": "PCS",
  "unitPrice": 45,
  "costPrice": 30,
  "quantityOnHand": 100,
  "minThreshold": 20,
  "maxThreshold": 500,
  "reorderLevel": 30,
  "isActive": true
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INV-009 — Execute a stock movement (RECEIVE, ISSUE, TRANSFER, ADJUST)

**بتعمل إيه؟**:
إضافة صنف استهلاكي أو تشغيلي جديد إلى دليل أصناف المخازن الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/inventory/movements`
- **Controller**: `InventoryController -> Roles()`
- **Service Execution**: `inventoryService.createWarehouse()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `InventoryItem`, `InventoryCategory`, `StockTransaction`, `Warehouse`

**Purpose & Business Context**:
Execute a stock movement (RECEIVE, ISSUE, TRANSFER, ADJUST). This endpoint operates with strict transactional integrity under the Inventory & Stores subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "itemId": "item-uuid",
  "warehouseId": "warehouse-uuid",
  "type": "RECEIVE",
  "quantity": 25,
  "referenceType": "PURCHASE_ORDER",
  "referenceId": "po-uuid-123",
  "reason": "Restocked from supplier order PO-901",
  "unitPrice": 30
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INV-010 — List stock movement history with filters

**بتعمل إيه؟**:
متابعة وإدارة أرصدة المخازن والمستودعات الفندقية وحركات الأصناف ومستويات إعادة الطلب.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/inventory/movements`
- **Controller**: `InventoryController -> ApiOperation()`
- **Service Execution**: `inventoryService.findWarehouses()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `InventoryItem`, `InventoryCategory`, `StockTransaction`, `Warehouse`

**Purpose & Business Context**:
List stock movement history with filters. This endpoint operates with strict transactional integrity under the Inventory & Stores subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `itemId` | No | `string` | `` | Filter parameter: itemId |
| `warehouseId` | No | `string` | `` | Filter parameter: warehouseId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INV-011 — Initiate a physical inventory count audit session

**بتعمل إيه؟**:
إضافة صنف استهلاكي أو تشغيلي جديد إلى دليل أصناف المخازن الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/inventory/counts`
- **Controller**: `InventoryController -> Roles()`
- **Service Execution**: `inventoryService.createWarehouse()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `InventoryItem`, `InventoryCategory`, `StockTransaction`, `Warehouse`

**Purpose & Business Context**:
Initiate a physical inventory count audit session. This endpoint operates with strict transactional integrity under the Inventory & Stores subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "warehouseId": "warehouse-uuid",
  "notes": "Annual physical inventory count Q3"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INV-012 — List stock count audit sessions

**بتعمل إيه؟**:
متابعة وإدارة أرصدة المخازن والمستودعات الفندقية وحركات الأصناف ومستويات إعادة الطلب.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/inventory/counts`
- **Controller**: `InventoryController -> ApiOperation()`
- **Service Execution**: `inventoryService.findWarehouses()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `InventoryItem`, `InventoryCategory`, `StockTransaction`, `Warehouse`

**Purpose & Business Context**:
List stock count audit sessions. This endpoint operates with strict transactional integrity under the Inventory & Stores subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `warehouseId` | **Yes** | `string` | `` | Filter parameter: warehouseId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Procurement & Suppliers

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **PRC-001** | `POST` | `/api/v1/procurement/suppliers` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Register a new supplier |
| **PRC-002** | `GET` | `/api/v1/procurement/suppliers` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List suppliers with search and pagination |
| **PRC-003** | `GET` | `/api/v1/procurement/suppliers/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get supplier details by ID |
| **PRC-004** | `PATCH` | `/api/v1/procurement/suppliers/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Update supplier details or rating |
| **PRC-005** | `POST` | `/api/v1/procurement/requests` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Create a purchase request (PR) |
| **PRC-006** | `GET` | `/api/v1/procurement/requests` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List purchase requests with filters |
| **PRC-007** | `GET` | `/api/v1/procurement/requests/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get purchase request details |
| **PRC-008** | `POST` | `/api/v1/procurement/requests/{id}/approve` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Approve a purchase request |
| **PRC-009** | `POST` | `/api/v1/procurement/orders` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Create a purchase order (PO) from scratch or from approved PR |
| **PRC-010** | `GET` | `/api/v1/procurement/orders` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List purchase orders with filters |
| **PRC-011** | `GET` | `/api/v1/procurement/orders/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get purchase order details and items |
| **PRC-012** | `PATCH` | `/api/v1/procurement/orders/{id}/status` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Update purchase order status (SENT, PARTIALLY_RECEIVED, RECEIVED, etc.) |
| **PRC-013** | `POST` | `/api/v1/procurement/invoices` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Register a supplier invoice matched with PO |
| **PRC-014** | `GET` | `/api/v1/procurement/invoices` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List supplier invoices with status filters |
| **PRC-015** | `GET` | `/api/v1/procurement/invoices/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get supplier invoice details |

### PRC-001 — Register a new supplier

**بتعمل إيه؟**:
تسجيل مورد تجاري جديد للفندق وتوثيق بيانات الاتصال وشروط الدفع والتعاقد.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/procurement/suppliers`
- **Controller**: `ProcurementController -> Roles()`
- **Service Execution**: `procurementService.createSupplier()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Supplier`, `PurchaseOrder`, `PurchaseOrderItem`, `Contract`

**Purpose & Business Context**:
Register a new supplier. This endpoint operates with strict transactional integrity under the Procurement & Suppliers subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "code": "SUP-001",
  "name": "Al-Safwa Hotel Supplies LLC",
  "contactPerson": "Ahmed Mansour",
  "email": "sales@alsafwasupplies.com",
  "phone": "+966501234567",
  "address": "King Fahd Road, Riyadh, Saudi Arabia",
  "taxNumber": "300123456700003",
  "paymentTerms": "Net 30 Days",
  "rating": 4.8
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PRC-002 — List suppliers with search and pagination

**بتعمل إيه؟**:
إدارة قائمة الموردين المعتمدين وسجل التعاملات والتقييم الدوري لكل مورد.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/procurement/suppliers`
- **Controller**: `ProcurementController -> ApiOperation()`
- **Service Execution**: `procurementService.findSuppliers()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Supplier`, `PurchaseOrder`, `PurchaseOrderItem`, `Contract`

**Purpose & Business Context**:
List suppliers with search and pagination. This endpoint operates with strict transactional integrity under the Procurement & Suppliers subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `search` | No | `string` | `` | Search by code, name, contactPerson, email |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PRC-003 — Get supplier details by ID

**بتعمل إيه؟**:
إدارة قائمة الموردين المعتمدين وسجل التعاملات والتقييم الدوري لكل مورد.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/procurement/suppliers/{id}`
- **Controller**: `ProcurementController -> ApiOperation()`
- **Service Execution**: `procurementService.findSuppliers()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Supplier`, `PurchaseOrder`, `PurchaseOrderItem`, `Contract`

**Purpose & Business Context**:
Get supplier details by ID. This endpoint operates with strict transactional integrity under the Procurement & Suppliers subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PRC-004 — Update supplier details or rating

**بتعمل إيه؟**:
إدارة قائمة الموردين المعتمدين وسجل التعاملات والتقييم الدوري لكل مورد.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/procurement/suppliers/{id}`
- **Controller**: `ProcurementController -> Roles()`
- **Service Execution**: `procurementService.updateSupplier()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Supplier`, `PurchaseOrder`, `PurchaseOrderItem`, `Contract`

**Purpose & Business Context**:
Update supplier details or rating. This endpoint operates with strict transactional integrity under the Procurement & Suppliers subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "code": "SUP-001",
  "name": "Al-Safwa Hotel Supplies LLC",
  "contactPerson": "Ahmed Mansour",
  "email": "sales@alsafwasupplies.com",
  "phone": "+966501234567",
  "address": "King Fahd Road, Riyadh, Saudi Arabia",
  "taxNumber": "300123456700003",
  "paymentTerms": "Net 30 Days",
  "rating": 4.8
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PRC-005 — Create a purchase request (PR)

**بتعمل إيه؟**:
إدارة عمليات المشتريات والتوريد وعروض الأسعار لمستلزمات وتشغيل الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/procurement/requests`
- **Controller**: `ProcurementController -> Roles()`
- **Service Execution**: `procurementService.createSupplier()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Supplier`, `PurchaseOrder`, `PurchaseOrderItem`, `Contract`

**Purpose & Business Context**:
Create a purchase request (PR). This endpoint operates with strict transactional integrity under the Procurement & Suppliers subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "departmentId": "dept-housekeeping-uuid",
  "priority": "HIGH",
  "requiredDate": "2026-09-15T00:00:00.000Z",
  "notes": "Urgent restocking for upcoming holiday season",
  "items": []
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### PRC-006 — List purchase requests with filters

**بتعمل إيه؟**:
إدارة عمليات المشتريات والتوريد وعروض الأسعار لمستلزمات وتشغيل الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/procurement/requests`
- **Controller**: `ProcurementController -> ApiOperation()`
- **Service Execution**: `procurementService.findSuppliers()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Supplier`, `PurchaseOrder`, `PurchaseOrderItem`, `Contract`

**Purpose & Business Context**:
List purchase requests with filters. This endpoint operates with strict transactional integrity under the Procurement & Suppliers subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `status` | No | `string` | `` | Filter parameter: status |
| `departmentId` | No | `string` | `` | Filter parameter: departmentId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### PRC-007 — Get purchase request details

**بتعمل إيه؟**:
إدارة عمليات المشتريات والتوريد وعروض الأسعار لمستلزمات وتشغيل الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/procurement/requests/{id}`
- **Controller**: `ProcurementController -> ApiOperation()`
- **Service Execution**: `procurementService.findSuppliers()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Supplier`, `PurchaseOrder`, `PurchaseOrderItem`, `Contract`

**Purpose & Business Context**:
Get purchase request details. This endpoint operates with strict transactional integrity under the Procurement & Suppliers subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### PRC-008 — Approve a purchase request

**بتعمل إيه؟**:
إدارة عمليات المشتريات والتوريد وعروض الأسعار لمستلزمات وتشغيل الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/procurement/requests/{id}/approve`
- **Controller**: `ProcurementController -> Roles()`
- **Service Execution**: `procurementService.createSupplier()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P0**
- **Prisma Database Entities**: `Supplier`, `PurchaseOrder`, `PurchaseOrderItem`, `Contract`

**Purpose & Business Context**:
Approve a purchase request. This endpoint operates with strict transactional integrity under the Procurement & Suppliers subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Active Employee Profile

---

### PRC-009 — Create a purchase order (PO) from scratch or from approved PR

**بتعمل إيه؟**:
إنشاء أمر شراء رسمي (Purchase Order) وتوجيهه للمورد لتوريد مستلزمات الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/procurement/orders`
- **Controller**: `ProcurementController -> Roles()`
- **Service Execution**: `procurementService.createSupplier()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Supplier`, `PurchaseOrder`, `PurchaseOrderItem`, `Contract`

**Purpose & Business Context**:
Create a purchase order (PO) from scratch or from approved PR. This endpoint operates with strict transactional integrity under the Procurement & Suppliers subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "purchaseRequestId": "pr-uuid-123",
  "supplierId": "supplier-uuid-456",
  "expectedDeliveryDate": "2026-09-20T00:00:00.000Z",
  "paymentTerms": "Net 30 Days",
  "taxAmount": 243.75,
  "notes": "Deliver to Central Receiving Dock",
  "items": []
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Registered Supplier (PRC-001)

---

### PRC-010 — List purchase orders with filters

**بتعمل إيه؟**:
إدارة ومتابعة أوامر الشراء وحالات استلام البضائع من الموردين.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/procurement/orders`
- **Controller**: `ProcurementController -> ApiOperation()`
- **Service Execution**: `procurementService.findSuppliers()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Supplier`, `PurchaseOrder`, `PurchaseOrderItem`, `Contract`

**Purpose & Business Context**:
List purchase orders with filters. This endpoint operates with strict transactional integrity under the Procurement & Suppliers subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `status` | No | `string` | `` | Filter parameter: status |
| `supplierId` | No | `string` | `` | Filter parameter: supplierId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Registered Supplier (PRC-001)

---

### PRC-011 — Get purchase order details and items

**بتعمل إيه؟**:
إدارة ومتابعة أوامر الشراء وحالات استلام البضائع من الموردين.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/procurement/orders/{id}`
- **Controller**: `ProcurementController -> ApiOperation()`
- **Service Execution**: `procurementService.findSuppliers()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Supplier`, `PurchaseOrder`, `PurchaseOrderItem`, `Contract`

**Purpose & Business Context**:
Get purchase order details and items. This endpoint operates with strict transactional integrity under the Procurement & Suppliers subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Registered Supplier (PRC-001)

---

### PRC-012 — Update purchase order status (SENT, PARTIALLY_RECEIVED, RECEIVED, etc.)

**بتعمل إيه؟**:
إدارة ومتابعة أوامر الشراء وحالات استلام البضائع من الموردين.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/procurement/orders/{id}/status`
- **Controller**: `ProcurementController -> Roles()`
- **Service Execution**: `procurementService.updateSupplier()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Supplier`, `PurchaseOrder`, `PurchaseOrderItem`, `Contract`

**Purpose & Business Context**:
Update purchase order status (SENT, PARTIALLY_RECEIVED, RECEIVED, etc.). This endpoint operates with strict transactional integrity under the Procurement & Suppliers subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)
- Registered Supplier (PRC-001)

---

### PRC-013 — Register a supplier invoice matched with PO

**بتعمل إيه؟**:
إدارة عمليات المشتريات والتوريد وعروض الأسعار لمستلزمات وتشغيل الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/procurement/invoices`
- **Controller**: `ProcurementController -> Roles()`
- **Service Execution**: `procurementService.createSupplier()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Supplier`, `PurchaseOrder`, `PurchaseOrderItem`, `Contract`

**Purpose & Business Context**:
Register a supplier invoice matched with PO. This endpoint operates with strict transactional integrity under the Procurement & Suppliers subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "invoiceNumber": "INV-SUP-8910",
  "purchaseOrderId": "po-uuid-123",
  "supplierId": "supplier-uuid-456",
  "invoiceDate": "2026-09-03T00:00:00.000Z",
  "dueDate": "2026-10-03T00:00:00.000Z",
  "subtotal": 1625,
  "taxAmount": 243.75,
  "notes": "Matches delivered items for PO-901"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PRC-014 — List supplier invoices with status filters

**بتعمل إيه؟**:
إدارة عمليات المشتريات والتوريد وعروض الأسعار لمستلزمات وتشغيل الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/procurement/invoices`
- **Controller**: `ProcurementController -> ApiOperation()`
- **Service Execution**: `procurementService.findSuppliers()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Supplier`, `PurchaseOrder`, `PurchaseOrderItem`, `Contract`

**Purpose & Business Context**:
List supplier invoices with status filters. This endpoint operates with strict transactional integrity under the Procurement & Suppliers subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `status` | No | `string` | `` | Filter parameter: status |
| `supplierId` | No | `string` | `` | Filter parameter: supplierId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PRC-015 — Get supplier invoice details

**بتعمل إيه؟**:
إدارة عمليات المشتريات والتوريد وعروض الأسعار لمستلزمات وتشغيل الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/procurement/invoices/{id}`
- **Controller**: `ProcurementController -> ApiOperation()`
- **Service Execution**: `procurementService.findSuppliers()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Supplier`, `PurchaseOrder`, `PurchaseOrderItem`, `Contract`

**Purpose & Business Context**:
Get supplier invoice details. This endpoint operates with strict transactional integrity under the Procurement & Suppliers subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Finance & Accounting

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **FIN-001** | `POST` | `/api/v1/finance/accounts` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Create a chart of accounts entry |
| **FIN-002** | `GET` | `/api/v1/finance/accounts` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get chart of accounts tree |
| **FIN-003** | `POST` | `/api/v1/finance/journal-entries` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Create a balanced double-entry journal entry |
| **FIN-004** | `GET` | `/api/v1/finance/journal-entries` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List journal entries with pagination and filters |
| **FIN-005** | `GET` | `/api/v1/finance/journal-entries/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get journal entry details including debit/credit lines |
| **FIN-006** | `POST` | `/api/v1/finance/journal-entries/{id}/post` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Post a journal entry to the general ledger |
| **FIN-007** | `POST` | `/api/v1/finance/expenses` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Record a financial expense |
| **FIN-008** | `GET` | `/api/v1/finance/expenses` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List financial expenses with filters |
| **FIN-009** | `PATCH` | `/api/v1/finance/expenses/{id}/status` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Update expense status (APPROVED, PAID, REJECTED) |
| **FIN-010** | `POST` | `/api/v1/finance/revenues` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Record a financial revenue or income |
| **FIN-011** | `GET` | `/api/v1/finance/revenues` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List financial revenues with filters |
| **FIN-012** | `POST` | `/api/v1/finance/bank-accounts` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Register a bank account |
| **FIN-013** | `GET` | `/api/v1/finance/bank-accounts` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List active bank accounts |

### FIN-001 — Create a chart of accounts entry

**بتعمل إيه؟**:
إدارة الحسابات المالية العامة، قيود اليومية، والدورات المحاسبية للفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/finance/accounts`
- **Controller**: `FinanceController -> Roles()`
- **Service Execution**: `financeService.createAccount()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Invoice`, `Payment`, `Expense`, `FinancialAccount`, `GeneralLedgerEntry`

**Purpose & Business Context**:
Create a chart of accounts entry. This endpoint operates with strict transactional integrity under the Finance & Accounting subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "code": "1010",
  "name": "Cash and Cash Equivalents",
  "type": "ASSET",
  "category": "CURRENT_ASSETS",
  "parentId": "parent-account-uuid",
  "isHeader": false
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### FIN-002 — Get chart of accounts tree

**بتعمل إيه؟**:
إدارة الحسابات المالية العامة، قيود اليومية، والدورات المحاسبية للفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/finance/accounts`
- **Controller**: `FinanceController -> ApiOperation()`
- **Service Execution**: `financeService.findAccounts()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Invoice`, `Payment`, `Expense`, `FinancialAccount`, `GeneralLedgerEntry`

**Purpose & Business Context**:
Get chart of accounts tree. This endpoint operates with strict transactional integrity under the Finance & Accounting subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### FIN-003 — Create a balanced double-entry journal entry

**بتعمل إيه؟**:
تسجيل أو استعراض قيود اليومية المحاسبية المزدوجة وضبط توازن الدائن والمدين.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/finance/journal-entries`
- **Controller**: `FinanceController -> Roles()`
- **Service Execution**: `financeService.createAccount()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Invoice`, `Payment`, `Expense`, `FinancialAccount`, `GeneralLedgerEntry`

**Purpose & Business Context**:
Create a balanced double-entry journal entry. This endpoint operates with strict transactional integrity under the Finance & Accounting subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "entryDate": "2026-09-03T00:00:00.000Z",
  "reference": "REF-INV-8910",
  "memo": "Bi-weekly supplier invoice settlement",
  "lines": []
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### FIN-004 — List journal entries with pagination and filters

**بتعمل إيه؟**:
تسجيل أو استعراض قيود اليومية المحاسبية المزدوجة وضبط توازن الدائن والمدين.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/finance/journal-entries`
- **Controller**: `FinanceController -> ApiOperation()`
- **Service Execution**: `financeService.findAccounts()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Invoice`, `Payment`, `Expense`, `FinancialAccount`, `GeneralLedgerEntry`

**Purpose & Business Context**:
List journal entries with pagination and filters. This endpoint operates with strict transactional integrity under the Finance & Accounting subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `status` | No | `string` | `` | Filter parameter: status |
| `search` | No | `string` | `` | Search by entryNumber, reference, memo |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### FIN-005 — Get journal entry details including debit/credit lines

**بتعمل إيه؟**:
تسجيل أو استعراض قيود اليومية المحاسبية المزدوجة وضبط توازن الدائن والمدين.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/finance/journal-entries/{id}`
- **Controller**: `FinanceController -> ApiOperation()`
- **Service Execution**: `financeService.findAccounts()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Invoice`, `Payment`, `Expense`, `FinancialAccount`, `GeneralLedgerEntry`

**Purpose & Business Context**:
Get journal entry details including debit/credit lines. This endpoint operates with strict transactional integrity under the Finance & Accounting subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### FIN-006 — Post a journal entry to the general ledger

**بتعمل إيه؟**:
تسجيل أو استعراض قيود اليومية المحاسبية المزدوجة وضبط توازن الدائن والمدين.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/finance/journal-entries/{id}/post`
- **Controller**: `FinanceController -> Roles()`
- **Service Execution**: `financeService.createAccount()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Invoice`, `Payment`, `Expense`, `FinancialAccount`, `GeneralLedgerEntry`

**Purpose & Business Context**:
Post a journal entry to the general ledger. This endpoint operates with strict transactional integrity under the Finance & Accounting subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### FIN-007 — Record a financial expense

**بتعمل إيه؟**:
إدارة الحسابات المالية العامة، قيود اليومية، والدورات المحاسبية للفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/finance/expenses`
- **Controller**: `FinanceController -> Roles()`
- **Service Execution**: `financeService.createAccount()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Invoice`, `Payment`, `Expense`, `FinancialAccount`, `GeneralLedgerEntry`

**Purpose & Business Context**:
Record a financial expense. This endpoint operates with strict transactional integrity under the Finance & Accounting subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "category": "OPERATING_SUPPLIES",
  "amount": 450,
  "currency": "SAR",
  "expenseDate": "2026-09-03T00:00:00.000Z",
  "departmentId": "dept-uuid",
  "paidTo": "Office Depot Saudi",
  "paymentMethod": "BANK_TRANSFER",
  "reference": "RCPT-10293",
  "description": "Stationery for front desk"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### FIN-008 — List financial expenses with filters

**بتعمل إيه؟**:
إدارة الحسابات المالية العامة، قيود اليومية، والدورات المحاسبية للفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/finance/expenses`
- **Controller**: `FinanceController -> ApiOperation()`
- **Service Execution**: `financeService.findAccounts()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Invoice`, `Payment`, `Expense`, `FinancialAccount`, `GeneralLedgerEntry`

**Purpose & Business Context**:
List financial expenses with filters. This endpoint operates with strict transactional integrity under the Finance & Accounting subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `status` | No | `string` | `` | Filter parameter: status |
| `category` | No | `string` | `` | Filter parameter: category |
| `departmentId` | No | `string` | `` | Filter parameter: departmentId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### FIN-009 — Update expense status (APPROVED, PAID, REJECTED)

**بتعمل إيه؟**:
إدارة الحسابات المالية العامة، قيود اليومية، والدورات المحاسبية للفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/finance/expenses/{id}/status`
- **Controller**: `FinanceController -> Roles()`
- **Service Execution**: `financeService.updateExpenseStatus()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Invoice`, `Payment`, `Expense`, `FinancialAccount`, `GeneralLedgerEntry`

**Purpose & Business Context**:
Update expense status (APPROVED, PAID, REJECTED). This endpoint operates with strict transactional integrity under the Finance & Accounting subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### FIN-010 — Record a financial revenue or income

**بتعمل إيه؟**:
إدارة الحسابات المالية العامة، قيود اليومية، والدورات المحاسبية للفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/finance/revenues`
- **Controller**: `FinanceController -> Roles()`
- **Service Execution**: `financeService.createAccount()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Invoice`, `Payment`, `Expense`, `FinancialAccount`, `GeneralLedgerEntry`

**Purpose & Business Context**:
Record a financial revenue or income. This endpoint operates with strict transactional integrity under the Finance & Accounting subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "category": "ROOM_SALES",
  "amount": 12500,
  "currency": "SAR",
  "revenueDate": "2026-09-03T00:00:00.000Z",
  "departmentId": "dept-frontoffice-uuid",
  "receivedFrom": "Daily Front Desk POS Settled Income",
  "paymentMethod": "CREDIT_CARD",
  "reference": "BATCH-POS-991",
  "description": "Daily revenue close for 3rd Sept 2026"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### FIN-011 — List financial revenues with filters

**بتعمل إيه؟**:
إدارة الحسابات المالية العامة، قيود اليومية، والدورات المحاسبية للفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/finance/revenues`
- **Controller**: `FinanceController -> ApiOperation()`
- **Service Execution**: `financeService.findAccounts()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Invoice`, `Payment`, `Expense`, `FinancialAccount`, `GeneralLedgerEntry`

**Purpose & Business Context**:
List financial revenues with filters. This endpoint operates with strict transactional integrity under the Finance & Accounting subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `category` | No | `string` | `` | Filter parameter: category |
| `departmentId` | No | `string` | `` | Filter parameter: departmentId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### FIN-012 — Register a bank account

**بتعمل إيه؟**:
إدارة الحسابات المالية العامة، قيود اليومية، والدورات المحاسبية للفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/finance/bank-accounts`
- **Controller**: `FinanceController -> Roles()`
- **Service Execution**: `financeService.createAccount()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Invoice`, `Payment`, `Expense`, `FinancialAccount`, `GeneralLedgerEntry`

**Purpose & Business Context**:
Register a bank account. This endpoint operates with strict transactional integrity under the Finance & Accounting subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "bankName": "Al-Rajhi Bank",
  "accountNumber": "SA9820000001234567890123",
  "iban": "SA9820000001234567890123",
  "branchName": "Olaya Branch, Riyadh",
  "currency": "SAR",
  "openingBalance": 50000
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### FIN-013 — List active bank accounts

**بتعمل إيه؟**:
إدارة الحسابات المالية العامة، قيود اليومية، والدورات المحاسبية للفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/finance/bank-accounts`
- **Controller**: `FinanceController -> ApiOperation()`
- **Service Execution**: `financeService.findAccounts()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P1**
- **Prisma Database Entities**: `Invoice`, `Payment`, `Expense`, `FinancialAccount`, `GeneralLedgerEntry`

**Purpose & Business Context**:
List active bank accounts. This endpoint operates with strict transactional integrity under the Finance & Accounting subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Budget Management

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **BDG-001** | `POST` | `/api/v1/budget` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Create a budget plan with category allocation lines |
| **BDG-002** | `GET` | `/api/v1/budget` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List budgets with filters |
| **BDG-003** | `GET` | `/api/v1/budget/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get budget details and lines |
| **BDG-004** | `PATCH` | `/api/v1/budget/{id}/status` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Update budget status (APPROVED, ACTIVE, CLOSED) |
| **BDG-005** | `POST` | `/api/v1/budget/spend` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Record spending against a specific budget line |

### BDG-001 — Create a budget plan with category allocation lines

**بتعمل إيه؟**:
إدارة وضبط الموازنات التقديرية التشغيلية لأقسام الفندق ومقارنتها بالمصروفات الفعلية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/budget`
- **Controller**: `BudgetController -> Roles()`
- **Service Execution**: `budgetService.createBudget()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Budget`, `BudgetLineItem`, `Department`

**Purpose & Business Context**:
Create a budget plan with category allocation lines. This endpoint operates with strict transactional integrity under the Budget Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "budgetCode": "BUD-2026-HK",
  "title": "Housekeeping Annual Operating Budget 2026",
  "fiscalYear": 2026,
  "periodType": "ANNUAL",
  "startDate": "2026-01-01T00:00:00.000Z",
  "endDate": "2026-12-31T23:59:59.999Z",
  "departmentId": "dept-housekeeping-uuid",
  "status": "DRAFT",
  "notes": "Approved in Board meeting Jan 2026",
  "lines": []
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### BDG-002 — List budgets with filters

**بتعمل إيه؟**:
إدارة وضبط الموازنات التقديرية التشغيلية لأقسام الفندق ومقارنتها بالمصروفات الفعلية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/budget`
- **Controller**: `BudgetController -> ApiOperation()`
- **Service Execution**: `budgetService.findBudgets()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Budget`, `BudgetLineItem`, `Department`

**Purpose & Business Context**:
List budgets with filters. This endpoint operates with strict transactional integrity under the Budget Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `fiscalYear` | No | `number` | `` | Filter parameter: fiscalYear |
| `status` | No | `string` | `` | Filter parameter: status |
| `departmentId` | No | `string` | `` | Filter parameter: departmentId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### BDG-003 — Get budget details and lines

**بتعمل إيه؟**:
إدارة وضبط الموازنات التقديرية التشغيلية لأقسام الفندق ومقارنتها بالمصروفات الفعلية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/budget/{id}`
- **Controller**: `BudgetController -> ApiOperation()`
- **Service Execution**: `budgetService.findBudgets()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Budget`, `BudgetLineItem`, `Department`

**Purpose & Business Context**:
Get budget details and lines. This endpoint operates with strict transactional integrity under the Budget Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### BDG-004 — Update budget status (APPROVED, ACTIVE, CLOSED)

**بتعمل إيه؟**:
إدارة وضبط الموازنات التقديرية التشغيلية لأقسام الفندق ومقارنتها بالمصروفات الفعلية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/budget/{id}/status`
- **Controller**: `BudgetController -> Roles()`
- **Service Execution**: `budgetService.updateBudgetStatus()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Budget`, `BudgetLineItem`, `Department`

**Purpose & Business Context**:
Update budget status (APPROVED, ACTIVE, CLOSED). This endpoint operates with strict transactional integrity under the Budget Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### BDG-005 — Record spending against a specific budget line

**بتعمل إيه؟**:
إدارة وضبط الموازنات التقديرية التشغيلية لأقسام الفندق ومقارنتها بالمصروفات الفعلية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/budget/spend`
- **Controller**: `BudgetController -> Roles()`
- **Service Execution**: `budgetService.createBudget()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Budget`, `BudgetLineItem`, `Department`

**Purpose & Business Context**:
Record spending against a specific budget line. This endpoint operates with strict transactional integrity under the Budget Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "budgetLineId": "budget-line-uuid",
  "amount": 4500
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Incident & Safety Management

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **INC-001** | `POST` | `/api/v1/incidents` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Report an incident (safety, security, guest, employee) |
| **INC-002** | `GET` | `/api/v1/incidents` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | List incidents with filters and search |
| **INC-003** | `GET` | `/api/v1/incidents/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get incident details, investigations, and corrective actions |
| **INC-004** | `PATCH` | `/api/v1/incidents/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Update incident status or severity |
| **INC-005** | `POST` | `/api/v1/incidents/{id}/investigation` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Add an investigation finding and root cause analysis |
| **INC-006** | `POST` | `/api/v1/incidents/{id}/corrective-actions` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Assign a corrective action for an incident |
| **INC-007** | `PATCH` | `/api/v1/incidents/corrective-actions/{actionId}/resolve` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Resolve and close a corrective action |

### INC-001 — Report an incident (safety, security, guest, employee)

**بتعمل إيه؟**:
تسجيل بلاغ حادث أمني أو مهني جديد داخل الفندق وتوثيق التفاصيل والمصابين إن وجدوا.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/incidents`
- **Controller**: `IncidentsController -> ApiOperation()`
- **Service Execution**: `incidentsService.createIncident()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `IncidentReport`, `IncidentInvestigation`, `SafetyCorrectiveAction`

**Purpose & Business Context**:
Report an incident (safety, security, guest, employee). This endpoint operates with strict transactional integrity under the Incident & Safety Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "title": "Slip and Fall in Lobby Corridor",
  "description": "Guest slipped on wet marble floor where no warning sign was placed.",
  "type": "SAFETY",
  "severity": "MEDIUM",
  "location": "Main Lobby, near East Elevator Bank",
  "incidentDate": "2026-09-03T11:30:00.000Z",
  "departmentId": "dept-security-uuid",
  "evidenceUrls": [
    "https://storage.hotel.com/evidence/lobby-wet-floor.jpg"
  ]
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INC-002 — List incidents with filters and search

**بتعمل إيه؟**:
متابعة والتحقيق في حوادث الأمن والسلامة المهنية وإجراءات تصحيح المسار بالفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/incidents`
- **Controller**: `IncidentsController -> ApiOperation()`
- **Service Execution**: `incidentsService.findIncidents()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `IncidentReport`, `IncidentInvestigation`, `SafetyCorrectiveAction`

**Purpose & Business Context**:
List incidents with filters and search. This endpoint operates with strict transactional integrity under the Incident & Safety Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `search` | No | `string` | `` | Search by title, description, incidentNumber, location |
| `type` | No | `string` | `` | Filter parameter: type |
| `severity` | No | `string` | `` | Filter parameter: severity |
| `status` | No | `string` | `` | Filter parameter: status |
| `departmentId` | No | `string` | `` | Filter parameter: departmentId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INC-003 — Get incident details, investigations, and corrective actions

**بتعمل إيه؟**:
متابعة والتحقيق في حوادث الأمن والسلامة المهنية وإجراءات تصحيح المسار بالفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/incidents/{id}`
- **Controller**: `IncidentsController -> ApiOperation()`
- **Service Execution**: `incidentsService.findIncidents()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `IncidentReport`, `IncidentInvestigation`, `SafetyCorrectiveAction`

**Purpose & Business Context**:
Get incident details, investigations, and corrective actions. This endpoint operates with strict transactional integrity under the Incident & Safety Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INC-004 — Update incident status or severity

**بتعمل إيه؟**:
متابعة والتحقيق في حوادث الأمن والسلامة المهنية وإجراءات تصحيح المسار بالفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/incidents/{id}`
- **Controller**: `IncidentsController -> Roles()`
- **Service Execution**: `incidentsService.updateIncident()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `IncidentReport`, `IncidentInvestigation`, `SafetyCorrectiveAction`

**Purpose & Business Context**:
Update incident status or severity. This endpoint operates with strict transactional integrity under the Incident & Safety Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "status": "REPORTED",
  "severity": "LOW"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INC-005 — Add an investigation finding and root cause analysis

**بتعمل إيه؟**:
تسجيل بلاغ حادث أمني أو مهني جديد داخل الفندق وتوثيق التفاصيل والمصابين إن وجدوا.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/incidents/{id}/investigation`
- **Controller**: `IncidentsController -> ApiOperation()`
- **Service Execution**: `incidentsService.createIncident()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `IncidentReport`, `IncidentInvestigation`, `SafetyCorrectiveAction`

**Purpose & Business Context**:
Add an investigation finding and root cause analysis. This endpoint operates with strict transactional integrity under the Incident & Safety Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "findings": "CCTV footage showed Housekeeping mopped floor at 11:25 with no wet floor cone placed.",
  "rootCause": "Failure to follow SOP HK-042 (caution cone mandatory)",
  "recommendations": "Refresher training on spill safety and equipment check"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INC-006 — Assign a corrective action for an incident

**بتعمل إيه؟**:
تسجيل بلاغ حادث أمني أو مهني جديد داخل الفندق وتوثيق التفاصيل والمصابين إن وجدوا.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/incidents/{id}/corrective-actions`
- **Controller**: `IncidentsController -> ApiOperation()`
- **Service Execution**: `incidentsService.createIncident()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `IncidentReport`, `IncidentInvestigation`, `SafetyCorrectiveAction`

**Purpose & Business Context**:
Assign a corrective action for an incident. This endpoint operates with strict transactional integrity under the Incident & Safety Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "actionTitle": "Install 4 extra caution cones at Lobby station",
  "description": "Procure and place bright yellow folding caution cones at each service cart",
  "assignedToId": "emp-profile-uuid",
  "dueDate": "2026-09-10T18:00:00.000Z"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INC-007 — Resolve and close a corrective action

**بتعمل إيه؟**:
متابعة والتحقيق في حوادث الأمن والسلامة المهنية وإجراءات تصحيح المسار بالفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/incidents/corrective-actions/{actionId}/resolve`
- **Controller**: `IncidentsController -> Roles()`
- **Service Execution**: `incidentsService.updateIncident()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `IncidentReport`, `IncidentInvestigation`, `SafetyCorrectiveAction`

**Purpose & Business Context**:
Resolve and close a corrective action. This endpoint operates with strict transactional integrity under the Incident & Safety Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `actionId` | `string` | `id-12345` | Identifier parameter: actionId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Documents Management

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **DOC-001** | `POST` | `/api/v1/documents` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Upload and register a document in central archive |
| **DOC-002** | `GET` | `/api/v1/documents` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List accessible documents based on user role |
| **DOC-003** | `GET` | `/api/v1/documents/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get document details and version history |
| **DOC-004** | `POST` | `/api/v1/documents/{id}/versions` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Upload a new version of an existing document |
| **DOC-005** | `PATCH` | `/api/v1/documents/{id}/archive` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Archive an obsolete document |

### DOC-001 — Upload and register a document in central archive

**بتعمل إيه؟**:
أرشفة ورفع مستند أو عقد رسمي جديد في نظام إدارة الوثائق الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/documents`
- **Controller**: `DocumentsController -> Roles()`
- **Service Execution**: `documentsService.createDocument()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Document`, `DocumentFolder`, `DocumentPermission`

**Purpose & Business Context**:
Upload and register a document in central archive. This endpoint operates with strict transactional integrity under the Documents Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "title": "Standard Operating Procedure: Front Desk Check-in",
  "description": "Standard guest arrival protocol, ID verification, and payment processing",
  "category": "SOP",
  "fileUrl": "https://storage.hotel.com/docs/sop-fd-checkin-v1.pdf",
  "fileType": "pdf",
  "fileSize": 1048576,
  "currentVersion": "1.0",
  "expirationDate": "2028-12-31T23:59:59.000Z",
  "departmentId": "dept-frontoffice-uuid",
  "accessRoles": [
    "SUPER_ADMIN",
    "HR_ADMIN"
  ]
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### DOC-002 — List accessible documents based on user role

**بتعمل إيه؟**:
استعراض وإدارة المستندات والعقود والوثائق الرسمية المصنفة في النظام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/documents`
- **Controller**: `DocumentsController -> ApiOperation()`
- **Service Execution**: `documentsService.findDocuments()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Document`, `DocumentFolder`, `DocumentPermission`

**Purpose & Business Context**:
List accessible documents based on user role. This endpoint operates with strict transactional integrity under the Documents Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `search` | No | `string` | `` | Search by title, description, documentNumber |
| `category` | No | `string` | `` | Filter parameter: category |
| `status` | No | `string` | `` | Filter parameter: status |
| `departmentId` | No | `string` | `` | Filter parameter: departmentId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### DOC-003 — Get document details and version history

**بتعمل إيه؟**:
استعراض وإدارة المستندات والعقود والوثائق الرسمية المصنفة في النظام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/documents/{id}`
- **Controller**: `DocumentsController -> ApiOperation()`
- **Service Execution**: `documentsService.findDocuments()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Document`, `DocumentFolder`, `DocumentPermission`

**Purpose & Business Context**:
Get document details and version history. This endpoint operates with strict transactional integrity under the Documents Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### DOC-004 — Upload a new version of an existing document

**بتعمل إيه؟**:
أرشفة ورفع مستند أو عقد رسمي جديد في نظام إدارة الوثائق الفندقية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/documents/{id}/versions`
- **Controller**: `DocumentsController -> Roles()`
- **Service Execution**: `documentsService.createDocument()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Document`, `DocumentFolder`, `DocumentPermission`

**Purpose & Business Context**:
Upload a new version of an existing document. This endpoint operates with strict transactional integrity under the Documents Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "versionNumber": "2.0",
  "fileUrl": "https://storage.hotel.com/docs/sop-fd-checkin-v2.pdf",
  "changeSummary": "Updated with digital key card issuance steps"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### DOC-005 — Archive an obsolete document

**بتعمل إيه؟**:
استعراض وإدارة المستندات والعقود والوثائق الرسمية المصنفة في النظام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/documents/{id}/archive`
- **Controller**: `DocumentsController -> Roles()`
- **Service Execution**: `documentsService.archiveDocument()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Document`, `DocumentFolder`, `DocumentPermission`

**Purpose & Business Context**:
Archive an obsolete document. This endpoint operates with strict transactional integrity under the Documents Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Lost & Found

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **LNF-001** | `POST` | `/api/v1/lost-found` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Register a found item |
| **LNF-002** | `GET` | `/api/v1/lost-found` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | List lost and found items with filters and search |
| **LNF-003** | `GET` | `/api/v1/lost-found/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Get details of a lost & found item |
| **LNF-004** | `POST` | `/api/v1/lost-found/{id}/claim` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Process owner claim and return of item |
| **LNF-005** | `PATCH` | `/api/v1/lost-found/{id}/status` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +2 | Update item status (DISPOSED, AUCTIONED, EXPIRED) |

### LNF-001 — Register a found item

**بتعمل إيه؟**:
تسجيل أمانة أو مقتنيات مفقودة تم العثور عليها في غرف أو مرافق الفندق مع وصفها وصورتها.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/lost-found`
- **Controller**: `LostFoundController -> ApiOperation()`
- **Service Execution**: `lostFoundService.createItem()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `LostFoundItem`, `LostFoundClaim`

**Purpose & Business Context**:
Register a found item. This endpoint operates with strict transactional integrity under the Lost & Found subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "itemName": "Gold Rolex Watch",
  "description": "Oyster Perpetual with silver dial found near pool lounger",
  "category": "JEWELRY",
  "locationFound": "Outdoor Pool Area, Cabana 4",
  "foundDate": "2026-09-03T10:15:00.000Z",
  "storageLocation": "Security Safe #3, Box A",
  "images": [
    "https://storage.hotel.com/lostfound/watch.jpg"
  ]
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### LNF-002 — List lost and found items with filters and search

**بتعمل إيه؟**:
استعراض وإدارة سجل المفقودات والأمانات الخاصة بالنزلاء وأماكن حفظها بالفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/lost-found`
- **Controller**: `LostFoundController -> ApiOperation()`
- **Service Execution**: `lostFoundService.findItems()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `LostFoundItem`, `LostFoundClaim`

**Purpose & Business Context**:
List lost and found items with filters and search. This endpoint operates with strict transactional integrity under the Lost & Found subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `search` | No | `string` | `` | Search by itemName, description, itemNumber, locationFound |
| `status` | No | `string` | `` | Filter parameter: status |
| `category` | No | `string` | `` | Filter parameter: category |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### LNF-003 — Get details of a lost & found item

**بتعمل إيه؟**:
استعراض وإدارة سجل المفقودات والأمانات الخاصة بالنزلاء وأماكن حفظها بالفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/lost-found/{id}`
- **Controller**: `LostFoundController -> ApiOperation()`
- **Service Execution**: `lostFoundService.findItems()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `LostFoundItem`, `LostFoundClaim`

**Purpose & Business Context**:
Get details of a lost & found item. This endpoint operates with strict transactional integrity under the Lost & Found subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### LNF-004 — Process owner claim and return of item

**بتعمل إيه؟**:
توثيق تسليم الأمانة أو المفقودات لنزيل الفندق والتوقيع على الاستلام.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/lost-found/{id}/claim`
- **Controller**: `LostFoundController -> ApiOperation()`
- **Service Execution**: `lostFoundService.createItem()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `LostFoundItem`, `LostFoundClaim`

**Purpose & Business Context**:
Process owner claim and return of item. This endpoint operates with strict transactional integrity under the Lost & Found subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "claimantName": "Sarah Jenkins",
  "claimantPhone": "+15552345678",
  "claimantNationalId": "US-P-98765432"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### LNF-005 — Update item status (DISPOSED, AUCTIONED, EXPIRED)

**بتعمل إيه؟**:
استعراض وإدارة سجل المفقودات والأمانات الخاصة بالنزلاء وأماكن حفظها بالفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/lost-found/{id}/status`
- **Controller**: `LostFoundController -> Roles()`
- **Service Execution**: `lostFoundService.updateItemStatus()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`, `SUPERVISOR`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `LostFoundItem`, `LostFoundClaim`

**Purpose & Business Context**:
Update item status (DISPOSED, AUCTIONED, EXPIRED). This endpoint operates with strict transactional integrity under the Lost & Found subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Visitor Management

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **VIS-001** | `POST` | `/api/v1/visitors/check-in` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Check in a visitor and notify host employee |
| **VIS-002** | `POST` | `/api/v1/visitors/{id}/check-out` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Check out a visitor |
| **VIS-003** | `GET` | `/api/v1/visitors` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | List visitors with filters and search |
| **VIS-004** | `GET` | `/api/v1/visitors/{id}` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Get visitor details by ID |

### VIS-001 — Check in a visitor and notify host employee

**بتعمل إيه؟**:
تسجيل دخول زائر جديد للفندق أو الإدارة وإصدار تصريح زيارة مؤقت.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/visitors/check-in`
- **Controller**: `VisitorsController -> ApiOperation()`
- **Service Execution**: `visitorsService.checkInVisitor()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Visitor`, `VisitorPass`, `VisitorVisitLog`

**Purpose & Business Context**:
Check in a visitor and notify host employee. This endpoint operates with strict transactional integrity under the Visitor Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "fullName": "Michael Chang",
  "phone": "+966551234567",
  "company": "Oracle Middle East",
  "nationalIdOrPassport": "P98765432",
  "purpose": "Quarterly IT Infrastructure Review",
  "hostEmployeeId": "emp-profile-uuid",
  "badgeNumber": "BADGE-VIS-102",
  "remarks": "Visitor escorted to Floor 4 conference room"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### VIS-002 — Check out a visitor

**بتعمل إيه؟**:
تسجيل وقت مغادرة الزائر وتسليم بطاقة الدخول.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/visitors/{id}/check-out`
- **Controller**: `VisitorsController -> ApiOperation()`
- **Service Execution**: `visitorsService.checkInVisitor()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Visitor`, `VisitorPass`, `VisitorVisitLog`

**Purpose & Business Context**:
Check out a visitor. This endpoint operates with strict transactional integrity under the Visitor Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "remarks": "Badge returned, visitor escorted out"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### VIS-003 — List visitors with filters and search

**بتعمل إيه؟**:
استعراض وإدارة سجل الزوار ومواعيد الدخول والخروج والجهة المقصودة بالزيارة.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/visitors`
- **Controller**: `VisitorsController -> ApiOperation()`
- **Service Execution**: `visitorsService.findVisitors()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Visitor`, `VisitorPass`, `VisitorVisitLog`

**Purpose & Business Context**:
List visitors with filters and search. This endpoint operates with strict transactional integrity under the Visitor Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `search` | No | `string` | `` | Search by fullName, phone, company, badgeNumber, visitorNumber |
| `status` | No | `string` | `` | Filter parameter: status |
| `hostEmployeeId` | No | `string` | `` | Filter parameter: hostEmployeeId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### VIS-004 — Get visitor details by ID

**بتعمل إيه؟**:
استعراض وإدارة سجل الزوار ومواعيد الدخول والخروج والجهة المقصودة بالزيارة.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/visitors/{id}`
- **Controller**: `VisitorsController -> ApiOperation()`
- **Service Execution**: `visitorsService.findVisitors()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Visitor`, `VisitorPass`, `VisitorVisitLog`

**Purpose & Business Context**:
Get visitor details by ID. This endpoint operates with strict transactional integrity under the Visitor Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Performance Management

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **PRF-001** | `POST` | `/api/v1/performance/kpis` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Define an employee KPI |
| **PRF-002** | `GET` | `/api/v1/performance/kpis` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List employee KPIs |
| **PRF-003** | `POST` | `/api/v1/performance/goals` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Assign a performance goal to an employee |
| **PRF-004** | `GET` | `/api/v1/performance/goals` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List performance goals with filters |
| **PRF-005** | `PATCH` | `/api/v1/performance/goals/{id}/progress` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Update goal progress value and trigger auto-achievement |
| **PRF-006** | `POST` | `/api/v1/performance/reviews` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Submit a performance review for an employee |
| **PRF-007** | `GET` | `/api/v1/performance/reviews` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List performance reviews with filters |
| **PRF-008** | `GET` | `/api/v1/performance/reviews/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get review details including strengths and improvement areas |
| **PRF-009** | `POST` | `/api/v1/performance/reviews/{id}/acknowledge` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Employee acknowledges receipt and discussion of performance review |

### PRF-001 — Define an employee KPI

**بتعمل إيه؟**:
إنشاء وتوثيق تقييم أداء دوري لموظف وربطه بمؤشرات الأداء (KPIs) والأهداف المحددة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/performance/kpis`
- **Controller**: `PerformanceController -> Roles()`
- **Service Execution**: `performanceService.createKPI()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `PerformanceReview`, `AppraisalCycle`, `KpiTarget`

**Purpose & Business Context**:
Define an employee KPI. This endpoint operates with strict transactional integrity under the Performance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "code": "KPI-GUEST-SAT",
  "title": "Guest Satisfaction Score",
  "description": "Monthly guest review average score percentage",
  "targetValue": 95,
  "unit": "PERCENT",
  "category": "SERVICE",
  "departmentId": "dept-frontoffice-uuid"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PRF-002 — List employee KPIs

**بتعمل إيه؟**:
متابعة مؤشرات أداء الموظفين ونتائج التقييمات الدورية السنوية ونصف السنوية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/performance/kpis`
- **Controller**: `PerformanceController -> ApiOperation()`
- **Service Execution**: `performanceService.findKPIs()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `PerformanceReview`, `AppraisalCycle`, `KpiTarget`

**Purpose & Business Context**:
List employee KPIs. This endpoint operates with strict transactional integrity under the Performance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `departmentId` | **Yes** | `string` | `` | Filter parameter: departmentId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PRF-003 — Assign a performance goal to an employee

**بتعمل إيه؟**:
إنشاء وتوثيق تقييم أداء دوري لموظف وربطه بمؤشرات الأداء (KPIs) والأهداف المحددة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/performance/goals`
- **Controller**: `PerformanceController -> Roles()`
- **Service Execution**: `performanceService.createKPI()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `PerformanceReview`, `AppraisalCycle`, `KpiTarget`

**Purpose & Business Context**:
Assign a performance goal to an employee. This endpoint operates with strict transactional integrity under the Performance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "employeeId": "emp-profile-uuid",
  "kpiId": "kpi-uuid",
  "title": "Achieve 98% room inspection passing score",
  "description": "Zero guest cleanliness complaints in assigned section",
  "targetValue": 98,
  "deadline": "2026-12-31T23:59:59.000Z",
  "weight": 25
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PRF-004 — List performance goals with filters

**بتعمل إيه؟**:
متابعة مؤشرات أداء الموظفين ونتائج التقييمات الدورية السنوية ونصف السنوية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/performance/goals`
- **Controller**: `PerformanceController -> ApiOperation()`
- **Service Execution**: `performanceService.findKPIs()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `PerformanceReview`, `AppraisalCycle`, `KpiTarget`

**Purpose & Business Context**:
List performance goals with filters. This endpoint operates with strict transactional integrity under the Performance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `employeeId` | No | `string` | `` | Filter parameter: employeeId |
| `status` | No | `string` | `` | Filter parameter: status |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PRF-005 — Update goal progress value and trigger auto-achievement

**بتعمل إيه؟**:
متابعة مؤشرات أداء الموظفين ونتائج التقييمات الدورية السنوية ونصف السنوية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/performance/goals/{id}/progress`
- **Controller**: `PerformanceController -> ApiOperation()`
- **Service Execution**: `performanceService.updateGoalProgress()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `PerformanceReview`, `AppraisalCycle`, `KpiTarget`

**Purpose & Business Context**:
Update goal progress value and trigger auto-achievement. This endpoint operates with strict transactional integrity under the Performance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "currentValue": 75.5,
  "status": "NOT_STARTED"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PRF-006 — Submit a performance review for an employee

**بتعمل إيه؟**:
إنشاء وتوثيق تقييم أداء دوري لموظف وربطه بمؤشرات الأداء (KPIs) والأهداف المحددة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/performance/reviews`
- **Controller**: `PerformanceController -> Roles()`
- **Service Execution**: `performanceService.createKPI()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `PerformanceReview`, `AppraisalCycle`, `KpiTarget`

**Purpose & Business Context**:
Submit a performance review for an employee. This endpoint operates with strict transactional integrity under the Performance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "employeeId": "emp-profile-uuid",
  "cycleName": "Annual Review 2026",
  "periodStart": "2026-01-01T00:00:00.000Z",
  "periodEnd": "2026-12-31T23:59:59.000Z",
  "overallRating": 4.5,
  "strengths": "Exceptional guest communication and leadership under pressure",
  "improvements": "Further training on PMS back-office night audit",
  "comments": "Recommended for Senior Concierge promotion"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PRF-007 — List performance reviews with filters

**بتعمل إيه؟**:
متابعة مؤشرات أداء الموظفين ونتائج التقييمات الدورية السنوية ونصف السنوية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/performance/reviews`
- **Controller**: `PerformanceController -> ApiOperation()`
- **Service Execution**: `performanceService.findKPIs()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `PerformanceReview`, `AppraisalCycle`, `KpiTarget`

**Purpose & Business Context**:
List performance reviews with filters. This endpoint operates with strict transactional integrity under the Performance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `employeeId` | No | `string` | `` | Filter parameter: employeeId |
| `status` | No | `string` | `` | Filter parameter: status |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PRF-008 — Get review details including strengths and improvement areas

**بتعمل إيه؟**:
متابعة مؤشرات أداء الموظفين ونتائج التقييمات الدورية السنوية ونصف السنوية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/performance/reviews/{id}`
- **Controller**: `PerformanceController -> ApiOperation()`
- **Service Execution**: `performanceService.findKPIs()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `PerformanceReview`, `AppraisalCycle`, `KpiTarget`

**Purpose & Business Context**:
Get review details including strengths and improvement areas. This endpoint operates with strict transactional integrity under the Performance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### PRF-009 — Employee acknowledges receipt and discussion of performance review

**بتعمل إيه؟**:
إنشاء وتوثيق تقييم أداء دوري لموظف وربطه بمؤشرات الأداء (KPIs) والأهداف المحددة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/performance/reviews/{id}/acknowledge`
- **Controller**: `PerformanceController -> Roles()`
- **Service Execution**: `performanceService.createKPI()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `PerformanceReview`, `AppraisalCycle`, `KpiTarget`

**Purpose & Business Context**:
Employee acknowledges receipt and discussion of performance review. This endpoint operates with strict transactional integrity under the Performance Management subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Training & Development

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **TRN-001** | `POST` | `/api/v1/training/courses` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Create a training course |
| **TRN-002** | `GET` | `/api/v1/training/courses` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List training courses |
| **TRN-003** | `GET` | `/api/v1/training/courses/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get course details and upcoming sessions |
| **TRN-004** | `POST` | `/api/v1/training/sessions` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Schedule a training session |
| **TRN-005** | `GET` | `/api/v1/training/sessions` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List training sessions with filters |
| **TRN-006** | `GET` | `/api/v1/training/sessions/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get session details and enrolled participants |
| **TRN-007** | `POST` | `/api/v1/training/sessions/{id}/enroll` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Enroll an employee into a training session |
| **TRN-008** | `PATCH` | `/api/v1/training/enrollments/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Update enrollment status and score (e.g. COMPLETED, FAILED) |
| **TRN-009** | `POST` | `/api/v1/training/certificates` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Issue a training certificate to an employee |
| **TRN-010** | `GET` | `/api/v1/training/certificates` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | List employee certificates |

### TRN-001 — Create a training course

**بتعمل إيه؟**:
إضافة برنامج أو دورة تدريبية جديدة وتحديد مدتها ومحتواها والمدرب المسؤول.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/training/courses`
- **Controller**: `TrainingController -> Roles()`
- **Service Execution**: `trainingService.createCourse()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `TrainingCourse`, `TrainingSession`, `TrainingEnrollment`

**Purpose & Business Context**:
Create a training course. This endpoint operates with strict transactional integrity under the Training & Development subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "code": "CRS-FIRE-01",
  "title": "Hotel Fire Safety & Evacuation Certification",
  "description": "Comprehensive hands-on fire extinguisher drill and building emergency evacuation",
  "category": "SAFETY",
  "isMandatory": true,
  "durationHours": 4,
  "validityMonths": 12
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TRN-002 — List training courses

**بتعمل إيه؟**:
إدارة خطط التدريب والتطوير المهني لكوادر وموظفي الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/training/courses`
- **Controller**: `TrainingController -> ApiOperation()`
- **Service Execution**: `trainingService.findCourses()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `TrainingCourse`, `TrainingSession`, `TrainingEnrollment`

**Purpose & Business Context**:
List training courses. This endpoint operates with strict transactional integrity under the Training & Development subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `search` | No | `string` | `` | Search by code, title |
| `category` | No | `string` | `` | Filter parameter: category |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TRN-003 — Get course details and upcoming sessions

**بتعمل إيه؟**:
إدارة خطط التدريب والتطوير المهني لكوادر وموظفي الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/training/courses/{id}`
- **Controller**: `TrainingController -> ApiOperation()`
- **Service Execution**: `trainingService.findCourses()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `TrainingCourse`, `TrainingSession`, `TrainingEnrollment`

**Purpose & Business Context**:
Get course details and upcoming sessions. This endpoint operates with strict transactional integrity under the Training & Development subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TRN-004 — Schedule a training session

**بتعمل إيه؟**:
إضافة برنامج أو دورة تدريبية جديدة وتحديد مدتها ومحتواها والمدرب المسؤول.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/training/sessions`
- **Controller**: `TrainingController -> Roles()`
- **Service Execution**: `trainingService.createCourse()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `TrainingCourse`, `TrainingSession`, `TrainingEnrollment`

**Purpose & Business Context**:
Schedule a training session. This endpoint operates with strict transactional integrity under the Training & Development subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "courseId": "course-uuid",
  "trainerName": "Captain Tariq Al-Ghamdi (Civil Defense Certified)",
  "startDate": "2026-09-15T09:00:00.000Z",
  "endDate": "2026-09-15T13:00:00.000Z",
  "location": "Grand Ballroom A & East Assembly Point",
  "maxParticipants": 30
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TRN-005 — List training sessions with filters

**بتعمل إيه؟**:
إدارة خطط التدريب والتطوير المهني لكوادر وموظفي الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/training/sessions`
- **Controller**: `TrainingController -> ApiOperation()`
- **Service Execution**: `trainingService.findCourses()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `TrainingCourse`, `TrainingSession`, `TrainingEnrollment`

**Purpose & Business Context**:
List training sessions with filters. This endpoint operates with strict transactional integrity under the Training & Development subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |
| `courseId` | No | `string` | `` | Filter parameter: courseId |
| `status` | No | `string` | `` | Filter parameter: status |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TRN-006 — Get session details and enrolled participants

**بتعمل إيه؟**:
إدارة خطط التدريب والتطوير المهني لكوادر وموظفي الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/training/sessions/{id}`
- **Controller**: `TrainingController -> ApiOperation()`
- **Service Execution**: `trainingService.findCourses()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `TrainingCourse`, `TrainingSession`, `TrainingEnrollment`

**Purpose & Business Context**:
Get session details and enrolled participants. This endpoint operates with strict transactional integrity under the Training & Development subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TRN-007 — Enroll an employee into a training session

**بتعمل إيه؟**:
تسجيل وإلحاق موظف بدورة تدريبية متخصصة في الضيافة أو السلامة.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/training/sessions/{id}/enroll`
- **Controller**: `TrainingController -> Roles()`
- **Service Execution**: `trainingService.createCourse()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `TrainingCourse`, `TrainingSession`, `TrainingEnrollment`

**Purpose & Business Context**:
Enroll an employee into a training session. This endpoint operates with strict transactional integrity under the Training & Development subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "employeeId": "emp-profile-uuid"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TRN-008 — Update enrollment status and score (e.g. COMPLETED, FAILED)

**بتعمل إيه؟**:
إدارة خطط التدريب والتطوير المهني لكوادر وموظفي الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/training/enrollments/{id}`
- **Controller**: `TrainingController -> Roles()`
- **Service Execution**: `trainingService.updateEnrollment()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `TrainingCourse`, `TrainingSession`, `TrainingEnrollment`

**Purpose & Business Context**:
Update enrollment status and score (e.g. COMPLETED, FAILED). This endpoint operates with strict transactional integrity under the Training & Development subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "status": "COMPLETED",
  "score": 92.5
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TRN-009 — Issue a training certificate to an employee

**بتعمل إيه؟**:
إضافة برنامج أو دورة تدريبية جديدة وتحديد مدتها ومحتواها والمدرب المسؤول.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/training/certificates`
- **Controller**: `TrainingController -> Roles()`
- **Service Execution**: `trainingService.createCourse()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `TrainingCourse`, `TrainingSession`, `TrainingEnrollment`

**Purpose & Business Context**:
Issue a training certificate to an employee. This endpoint operates with strict transactional integrity under the Training & Development subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "employeeId": "emp-profile-uuid",
  "courseId": "course-uuid",
  "title": "Certified Fire Safety & Evacuation Specialist",
  "expiryDate": "2027-09-15T00:00:00.000Z",
  "certificateUrl": "https://storage.hotel.com/certs/cert-9981.pdf"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### TRN-010 — List employee certificates

**بتعمل إيه؟**:
إدارة خطط التدريب والتطوير المهني لكوادر وموظفي الفندق.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/training/certificates`
- **Controller**: `TrainingController -> ApiOperation()`
- **Service Execution**: `trainingService.findCourses()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `TrainingCourse`, `TrainingSession`, `TrainingEnrollment`

**Purpose & Business Context**:
List employee certificates. This endpoint operates with strict transactional integrity under the Training & Development subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `employeeId` | **Yes** | `string` | `` | Filter parameter: employeeId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Sessions & Active Devices

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **SES-001** | `POST` | `/api/v1/sessions/register` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Register or refresh device session (FCM token, hardware ID) |
| **SES-002** | `GET` | `/api/v1/sessions/my-devices` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | List currently active device sessions for current user |
| **SES-003** | `DELETE` | `/api/v1/sessions/{id}` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Remotely revoke and terminate a specific device session |
| **SES-004** | `DELETE` | `/api/v1/sessions/other/{currentSessionId}` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Revoke and terminate all other devices except the current session |

### SES-001 — Register or refresh device session (FCM token, hardware ID)

**بتعمل إيه؟**:
عرض قائمة الأجهزة والجلسات النشطة حالياً للمستخدم لضمان الأمان والرقابة.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/sessions/register`
- **Controller**: `SessionsController -> ApiOperation()`
- **Service Execution**: `sessionsService.registerDeviceSession()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Session`, `User`, `DeviceToken`

**Purpose & Business Context**:
Register or refresh device session (FCM token, hardware ID). This endpoint operates with strict transactional integrity under the Sessions & Active Devices subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "sessionToken": "session-token-string",
  "devicePlatform": "ANDROID",
  "deviceModel": "iPhone 15 Pro",
  "osVersion": "iOS 17.5",
  "appVersion": "2.1.0",
  "ipAddress": "192.168.1.100",
  "userAgent": "Mozilla/5.0 Mobile"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SES-002 — List currently active device sessions for current user

**بتعمل إيه؟**:
عرض قائمة الأجهزة والجلسات النشطة حالياً للمستخدم لضمان الأمان والرقابة.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/sessions/my-devices`
- **Controller**: `SessionsController -> ApiOperation()`
- **Service Execution**: `sessionsService.getMyActiveSessions()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Session`, `User`, `DeviceToken`

**Purpose & Business Context**:
List currently active device sessions for current user. This endpoint operates with strict transactional integrity under the Sessions & Active Devices subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SES-003 — Remotely revoke and terminate a specific device session

**بتعمل إيه؟**:
إنهاء وإلغاء جلسة نشطة على جهاز محدد وتسجيل خروجه إجبارياً من النظام.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/sessions/{id}`
- **Controller**: `SessionsController -> ApiOperation()`
- **Service Execution**: `sessionsService.terminateSession()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Session`, `User`, `DeviceToken`

**Purpose & Business Context**:
Remotely revoke and terminate a specific device session. This endpoint operates with strict transactional integrity under the Sessions & Active Devices subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SES-004 — Revoke and terminate all other devices except the current session

**بتعمل إيه؟**:
إنهاء وإلغاء جلسة نشطة على جهاز محدد وتسجيل خروجه إجبارياً من النظام.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/sessions/other/{currentSessionId}`
- **Controller**: `SessionsController -> ApiOperation()`
- **Service Execution**: `sessionsService.terminateSession()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `Session`, `User`, `DeviceToken`

**Purpose & Business Context**:
Revoke and terminate all other devices except the current session. This endpoint operates with strict transactional integrity under the Sessions & Active Devices subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `currentSessionId` | `string` | `id-12345` | Identifier parameter: currentSessionId |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Integrations & Webhooks

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **INT-001** | `POST` | `/api/v1/integrations/api-keys` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Generate a new scoped API key (SHA-256 hashed) |
| **INT-002** | `GET` | `/api/v1/integrations/api-keys` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | List active API keys with prefixes and scopes |
| **INT-003** | `DELETE` | `/api/v1/integrations/api-keys/{id}` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Revoke an API key |
| **INT-004** | `POST` | `/api/v1/integrations/webhooks` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Register an outgoing webhook subscription |
| **INT-005** | `GET` | `/api/v1/integrations/webhooks` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | List configured webhooks |
| **INT-006** | `PATCH` | `/api/v1/integrations/webhooks/{id}/status` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Enable or disable a webhook configuration |
| **INT-007** | `GET` | `/api/v1/integrations/logs` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Audit integration request logs |

### INT-001 — Generate a new scoped API key (SHA-256 hashed)

**بتعمل إيه؟**:
إدارة وضبط واجهات الربط البرمجي (Webhooks/Integrations) مع الأنظمة الفندقية الخارجية (PMS/OTA).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/integrations/api-keys`
- **Controller**: `IntegrationsController -> ApiOperation()`
- **Service Execution**: `integrationsService.createApiKey()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `IntegrationConfig`, `WebhookSubscription`, `WebhookDeliveryLog`

**Purpose & Business Context**:
Generate a new scoped API key (SHA-256 hashed). This endpoint operates with strict transactional integrity under the Integrations & Webhooks subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "name": "Opera PMS Integration Key",
  "scopes": [
    "rooms:read",
    "reservations:write"
  ],
  "expiresAt": "2027-12-31T23:59:59.000Z"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INT-002 — List active API keys with prefixes and scopes

**بتعمل إيه؟**:
إدارة وضبط واجهات الربط البرمجي (Webhooks/Integrations) مع الأنظمة الفندقية الخارجية (PMS/OTA).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/integrations/api-keys`
- **Controller**: `IntegrationsController -> ApiOperation()`
- **Service Execution**: `integrationsService.findApiKeys()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `IntegrationConfig`, `WebhookSubscription`, `WebhookDeliveryLog`

**Purpose & Business Context**:
List active API keys with prefixes and scopes. This endpoint operates with strict transactional integrity under the Integrations & Webhooks subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INT-003 — Revoke an API key

**بتعمل إيه؟**:
إدارة وضبط واجهات الربط البرمجي (Webhooks/Integrations) مع الأنظمة الفندقية الخارجية (PMS/OTA).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/integrations/api-keys/{id}`
- **Controller**: `IntegrationsController -> ApiOperation()`
- **Service Execution**: `integrationsService.revokeApiKey()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `IntegrationConfig`, `WebhookSubscription`, `WebhookDeliveryLog`

**Purpose & Business Context**:
Revoke an API key. This endpoint operates with strict transactional integrity under the Integrations & Webhooks subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INT-004 — Register an outgoing webhook subscription

**بتعمل إيه؟**:
إدارة وضبط واجهات الربط البرمجي (Webhooks/Integrations) مع الأنظمة الفندقية الخارجية (PMS/OTA).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/integrations/webhooks`
- **Controller**: `IntegrationsController -> ApiOperation()`
- **Service Execution**: `integrationsService.createApiKey()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `IntegrationConfig`, `WebhookSubscription`, `WebhookDeliveryLog`

**Purpose & Business Context**:
Register an outgoing webhook subscription. This endpoint operates with strict transactional integrity under the Integrations & Webhooks subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "name": "Channel Manager Webhook",
  "targetUrl": "https://api.externalchannel.com/webhooks/hotel",
  "events": [
    "room.status_changed",
    "guest.checked_in",
    "inventory.low_stock"
  ],
  "retryLimit": 3
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INT-005 — List configured webhooks

**بتعمل إيه؟**:
إدارة وضبط واجهات الربط البرمجي (Webhooks/Integrations) مع الأنظمة الفندقية الخارجية (PMS/OTA).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/integrations/webhooks`
- **Controller**: `IntegrationsController -> ApiOperation()`
- **Service Execution**: `integrationsService.findApiKeys()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `IntegrationConfig`, `WebhookSubscription`, `WebhookDeliveryLog`

**Purpose & Business Context**:
List configured webhooks. This endpoint operates with strict transactional integrity under the Integrations & Webhooks subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INT-006 — Enable or disable a webhook configuration

**بتعمل إيه؟**:
إدارة وضبط واجهات الربط البرمجي (Webhooks/Integrations) مع الأنظمة الفندقية الخارجية (PMS/OTA).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `PATCH`
- **Full URL**: `http://localhost:3000/api/v1/integrations/webhooks/{id}/status`
- **Controller**: `IntegrationsController -> ApiOperation()`
- **Service Execution**: `integrationsService.updateWebhookStatus()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `IntegrationConfig`, `WebhookSubscription`, `WebhookDeliveryLog`

**Purpose & Business Context**:
Enable or disable a webhook configuration. This endpoint operates with strict transactional integrity under the Integrations & Webhooks subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### INT-007 — Audit integration request logs

**بتعمل إيه؟**:
إدارة وضبط واجهات الربط البرمجي (Webhooks/Integrations) مع الأنظمة الفندقية الخارجية (PMS/OTA).

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/integrations/logs`
- **Controller**: `IntegrationsController -> ApiOperation()`
- **Service Execution**: `integrationsService.findApiKeys()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `IntegrationConfig`, `WebhookSubscription`, `WebhookDeliveryLog`

**Purpose & Business Context**:
Audit integration request logs. This endpoint operates with strict transactional integrity under the Integrations & Webhooks subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `20` | Filter parameter: limit |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Offline Sync Engine

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **SNC-001** | `POST` | `/api/v1/sync` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Standard mobile client sync endpoint (POST /api/v1/sync) |
| **SNC-002** | `POST` | `/api/v1/sync/batch` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Push batch of offline actions recorded on mobile client |
| **SNC-003** | `GET` | `/api/v1/sync/changes` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Retrieve server delta changes since client cursor (FR-SYNC-001) |
| **SNC-004** | `GET` | `/api/v1/sync/queue` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Check status of previously submitted sync items |
| **SNC-005** | `POST` | `/api/v1/sync/retry/{id}` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Retry a failed or pending sync item (FR-SYNC-006) |
| **SNC-006** | `POST` | `/api/v1/sync/resolve-conflict/{id}` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Resolve a synchronization conflict item using specified strategy (FR-SYNC-007) |
| **SNC-007** | `GET` | `/api/v1/sync/logs` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Query operational synchronization audit logs (FR-SYNC-008) |

### SNC-001 — Standard mobile client sync endpoint (POST /api/v1/sync)

**بتعمل إيه؟**:
إرسال ومزامنة العمليات التي تم تنفيذها دون اتصال (Offline Data) من تطبيق الموبايل للسيرفر.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/sync`
- **Controller**: `OfflineSyncController -> ApiOperation()`
- **Service Execution**: `offlineSyncService.processSyncBatch()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `SyncChangeLog`, `SyncClientState`, `OfflineMutationQueue`

**Purpose & Business Context**:
Standard mobile client sync endpoint (POST /api/v1/sync). This endpoint operates with strict transactional integrity under the Offline Sync Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "items": [],
  "syncCursor": "2026-09-03T09:00:00.000Z",
  "lastSyncToken": "2026-09-03T09:00:00.000Z"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SNC-002 — Push batch of offline actions recorded on mobile client

**بتعمل إيه؟**:
إرسال ومزامنة العمليات التي تم تنفيذها دون اتصال (Offline Data) من تطبيق الموبايل للسيرفر.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/sync/batch`
- **Controller**: `OfflineSyncController -> ApiOperation()`
- **Service Execution**: `offlineSyncService.processSyncBatch()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `SyncChangeLog`, `SyncClientState`, `OfflineMutationQueue`

**Purpose & Business Context**:
Push batch of offline actions recorded on mobile client. This endpoint operates with strict transactional integrity under the Offline Sync Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "items": [],
  "syncCursor": "2026-09-03T09:00:00.000Z",
  "lastSyncToken": "2026-09-03T09:00:00.000Z"
}
```

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SNC-003 — Retrieve server delta changes since client cursor (FR-SYNC-001)

**بتعمل إيه؟**:
سحب آخر تحديثات البيانات من السيرفر لتحديث قاعدة البيانات المحلية في تطبيق الموبايل.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/sync/changes`
- **Controller**: `OfflineSyncController -> ApiOperation()`
- **Service Execution**: `offlineSyncService.getServerChanges()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `SyncChangeLog`, `SyncClientState`, `OfflineMutationQueue`

**Purpose & Business Context**:
Retrieve server delta changes since client cursor (FR-SYNC-001). This endpoint operates with strict transactional integrity under the Offline Sync Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `cursor` | **Yes** | `string` | `` | Filter parameter: cursor |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SNC-004 — Check status of previously submitted sync items

**بتعمل إيه؟**:
سحب آخر تحديثات البيانات من السيرفر لتحديث قاعدة البيانات المحلية في تطبيق الموبايل.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/sync/queue`
- **Controller**: `OfflineSyncController -> ApiOperation()`
- **Service Execution**: `offlineSyncService.getServerChanges()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `SyncChangeLog`, `SyncClientState`, `OfflineMutationQueue`

**Purpose & Business Context**:
Check status of previously submitted sync items. This endpoint operates with strict transactional integrity under the Offline Sync Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `page` | No | `number` | `1` | Filter parameter: page |
| `limit` | No | `number` | `50` | Filter parameter: limit |
| `status` | No | `string` | `` | Filter parameter: status |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SNC-005 — Retry a failed or pending sync item (FR-SYNC-006)

**بتعمل إيه؟**:
إرسال ومزامنة العمليات التي تم تنفيذها دون اتصال (Offline Data) من تطبيق الموبايل للسيرفر.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/sync/retry/{id}`
- **Controller**: `OfflineSyncController -> ApiOperation()`
- **Service Execution**: `offlineSyncService.processSyncBatch()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `SyncChangeLog`, `SyncClientState`, `OfflineMutationQueue`

**Purpose & Business Context**:
Retry a failed or pending sync item (FR-SYNC-006). This endpoint operates with strict transactional integrity under the Offline Sync Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SNC-006 — Resolve a synchronization conflict item using specified strategy (FR-SYNC-007)

**بتعمل إيه؟**:
إرسال ومزامنة العمليات التي تم تنفيذها دون اتصال (Offline Data) من تطبيق الموبايل للسيرفر.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/sync/resolve-conflict/{id}`
- **Controller**: `OfflineSyncController -> ApiOperation()`
- **Service Execution**: `offlineSyncService.processSyncBatch()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `SyncChangeLog`, `SyncClientState`, `OfflineMutationQueue`

**Purpose & Business Context**:
Resolve a synchronization conflict item using specified strategy (FR-SYNC-007). This endpoint operates with strict transactional integrity under the Offline Sync Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "strategy": "CLIENT_WINS",
  "resolvedPayload": {
    "status": "COMPLETED",
    "resolvedAt": "2026-09-03T12:00:00.000Z"
  }
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SNC-007 — Query operational synchronization audit logs (FR-SYNC-008)

**بتعمل إيه؟**:
سحب آخر تحديثات البيانات من السيرفر لتحديث قاعدة البيانات المحلية في تطبيق الموبايل.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/sync/logs`
- **Controller**: `OfflineSyncController -> ApiOperation()`
- **Service Execution**: `offlineSyncService.getServerChanges()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `SyncChangeLog`, `SyncClientState`, `OfflineMutationQueue`

**Purpose & Business Context**:
Query operational synchronization audit logs (FR-SYNC-008). This endpoint operates with strict transactional integrity under the Offline Sync Engine subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Query Parameters**:
| Parameter | Required | Type | Example | Description |
|-----------|----------|------|---------|-------------|
| `entityType` | **Yes** | `string` | `` | Filter parameter: entityType |
| `status` | **Yes** | `string` | `` | Filter parameter: status |
| `page` | **Yes** | `number` | `` | Filter parameter: page |
| `limit` | **Yes** | `number` | `` | Filter parameter: limit |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Executive Dashboard & BI

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **DSH-001** | `GET` | `/api/v1/dashboard/executive-kpis` | JWT Bearer | SUPER_ADMIN, HR_ADMIN +1 | Get unified real-time executive dashboard KPIs across all ERP domains |

### DSH-001 — Get unified real-time executive dashboard KPIs across all ERP domains

**بتعمل إيه؟**:
جلب مؤشرات الأداء الرئيسية (KPIs) ولوحة التحكم التنفيذية لنسب الإشغال والعمالة والإيرادات للإدارة العليا.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN, HR_MANAGER

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/dashboard/executive-kpis`
- **Controller**: `DashboardController -> Roles()`
- **Service Execution**: `dashboardService.getExecutiveKPIs()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`, `HR_MANAGER`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ExecutiveDashboardMetrics`, `KpiAggregateView`

**Purpose & Business Context**:
Get unified real-time executive dashboard KPIs across all ERP domains. This endpoint operates with strict transactional integrity under the Executive Dashboard & BI subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN, HR_MANAGER]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## File Storage

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **STR-001** | `POST` | `/api/v1/storage/upload` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Upload file (Image, PDF, Document, Attachment) |
| **STR-002** | `GET` | `/api/v1/storage/metadata/{folder}/{filename}` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Get metadata for a stored file |
| **STR-003** | `DELETE` | `/api/v1/storage/{folder}/{filename}` | JWT Bearer | Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE) | Delete a stored file |

### STR-001 — Upload file (Image, PDF, Document, Attachment)

**بتعمل إيه؟**:
رفع ملف أو مستند أو صورة جديدة إلى خادم التخزين والحصول على رابط الوصول الآمن.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/storage/upload`
- **Controller**: `StorageController -> ApiOperation()`
- **Service Execution**: `storageService.uploadFile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `StoredFile`, `FileMetadata`

**Purpose & Business Context**:
Upload file (Image, PDF, Document, Attachment). This endpoint operates with strict transactional integrity under the File Storage subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "originalName": "inspection-photo.jpg",
  "mimeType": "image/jpeg",
  "base64Content": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD...",
  "folder": "maintenance"
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### STR-002 — Get metadata for a stored file

**بتعمل إيه؟**:
تحميل أو استعراض ملف مخزن في النظام عبر معرفه أو مساره.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/storage/metadata/{folder}/{filename}`
- **Controller**: `StorageController -> ApiOperation()`
- **Service Execution**: `storageService.getFileMetadata()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `StoredFile`, `FileMetadata`

**Purpose & Business Context**:
Get metadata for a stored file. This endpoint operates with strict transactional integrity under the File Storage subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `folder` | `string` | `id-12345` | Identifier parameter: folder |
| `filename` | `string` | `id-12345` | Identifier parameter: filename |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### STR-003 — Delete a stored file

**بتعمل إيه؟**:
إدارة التخزين السحابي والمحلي للمستندات والملفات المرفقة في النظام.

**مين يقدر يستخدمها؟**:
Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/storage/{folder}/{filename}`
- **Controller**: `StorageController -> ApiOperation()`
- **Service Execution**: `storageService.deleteFile()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `Any Authenticated Role (SUPER_ADMIN, HR_ADMIN, HR_MANAGER, SUPERVISOR, EMPLOYEE)`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `StoredFile`, `FileMetadata`

**Purpose & Business Context**:
Delete a stored file. This endpoint operates with strict transactional integrity under the File Storage subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `folder` | `string` | `id-12345` | Identifier parameter: folder |
| `filename` | `string` | `id-12345` | Identifier parameter: filename |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Background Jobs & Scheduler

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **SCHD-001** | `GET` | `/api/v1/scheduler/jobs` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | List all background scheduled jobs and their execution states |
| **SCHD-002** | `POST` | `/api/v1/scheduler/jobs/{name}/run` | JWT Bearer | SUPER_ADMIN, HR_ADMIN | Trigger immediate on-demand execution of a background job |

### SCHD-001 — List all background scheduled jobs and their execution states

**بتعمل إيه؟**:
إدارة وتشغيل ومراقبة المهام المجدولة في الخلفية (Cron Jobs) للعمليات الآلية اليومية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/scheduler/jobs`
- **Controller**: `SchedulerController -> Roles()`
- **Service Execution**: `schedulerService.listJobs()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ScheduledJobRun`, `DistributedLock`

**Purpose & Business Context**:
List all background scheduled jobs and their execution states. This endpoint operates with strict transactional integrity under the Background Jobs & Scheduler subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### SCHD-002 — Trigger immediate on-demand execution of a background job

**بتعمل إيه؟**:
إدارة وتشغيل ومراقبة المهام المجدولة في الخلفية (Cron Jobs) للعمليات الآلية اليومية.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN, HR_ADMIN

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/scheduler/jobs/{name}/run`
- **Controller**: `SchedulerController -> Roles()`
- **Service Execution**: `schedulerService.executeJob()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`, `HR_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `ScheduledJobRun`, `DistributedLock`

**Purpose & Business Context**:
Trigger immediate on-demand execution of a background job. This endpoint operates with strict transactional integrity under the Background Jobs & Scheduler subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `name` | `string` | `id-12345` | Identifier parameter: name |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN, HR_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

## Backup & Disaster Recovery

| ID | Method | Endpoint | Auth | Role | Purpose |
|----|--------|----------|------|------|---------|
| **BKP-001** | `POST` | `/api/v1/backup/create` | JWT Bearer | SUPER_ADMIN | Create immediate database & system state backup (OPS-006) |
| **BKP-002** | `GET` | `/api/v1/backup/list` | JWT Bearer | SUPER_ADMIN | List all existing system backups with checksums |
| **BKP-003** | `GET` | `/api/v1/backup/health` | JWT Bearer | SUPER_ADMIN | Backup readiness, storage, and retention health check |
| **BKP-004** | `GET` | `/api/v1/backup/{id}` | JWT Bearer | SUPER_ADMIN | Get single backup details by ID or Number |
| **BKP-005** | `DELETE` | `/api/v1/backup/{id}` | JWT Bearer | SUPER_ADMIN | Delete backup according to retention policy (OPS-008) |
| **BKP-006** | `POST` | `/api/v1/backup/{id}/restore` | JWT Bearer | SUPER_ADMIN | Test restore simulation or execute restore (OPS-007) |

### BKP-001 — Create immediate database & system state backup (OPS-006)

**بتعمل إيه؟**:
بدء تشغيل نسخة احتياطية فورية وشاملة لقاعدة بيانات وملفات النظام وتخزينها بأمان.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/backup/create`
- **Controller**: `BackupController -> Roles()`
- **Service Execution**: `backupService.createBackup()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `BackupSnapshot`, `BackupMetadata`

**Purpose & Business Context**:
Create immediate database & system state backup (OPS-006). This endpoint operates with strict transactional integrity under the Backup & Disaster Recovery subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body Payload**:
```json
{
  "notes": "Daily automated database snapshot",
  "includeFiles": false
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### BKP-002 — List all existing system backups with checksums

**بتعمل إيه؟**:
إدارة ومتابعة عمليات النسخ الاحتياطي الدوري وتاريخها والتحقق من سلامتها.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/backup/list`
- **Controller**: `BackupController -> Roles()`
- **Service Execution**: `backupService.listBackups()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `BackupSnapshot`, `BackupMetadata`

**Purpose & Business Context**:
List all existing system backups with checksums. This endpoint operates with strict transactional integrity under the Backup & Disaster Recovery subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### BKP-003 — Backup readiness, storage, and retention health check

**بتعمل إيه؟**:
إدارة ومتابعة عمليات النسخ الاحتياطي الدوري وتاريخها والتحقق من سلامتها.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/backup/health`
- **Controller**: `BackupController -> Roles()`
- **Service Execution**: `backupService.listBackups()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `BackupSnapshot`, `BackupMetadata`

**Purpose & Business Context**:
Backup readiness, storage, and retention health check. This endpoint operates with strict transactional integrity under the Backup & Disaster Recovery subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]

**Execution Prerequisites & Dependencies**:
- Active System State

---

### BKP-004 — Get single backup details by ID or Number

**بتعمل إيه؟**:
إدارة ومتابعة عمليات النسخ الاحتياطي الدوري وتاريخها والتحقق من سلامتها.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `GET`
- **Full URL**: `http://localhost:3000/api/v1/backup/{id}`
- **Controller**: `BackupController -> Roles()`
- **Service Execution**: `backupService.listBackups()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `BackupSnapshot`, `BackupMetadata`

**Purpose & Business Context**:
Get single backup details by ID or Number. This endpoint operates with strict transactional integrity under the Backup & Disaster Recovery subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### BKP-005 — Delete backup according to retention policy (OPS-008)

**بتعمل إيه؟**:
إدارة ومتابعة عمليات النسخ الاحتياطي الدوري وتاريخها والتحقق من سلامتها.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `DELETE`
- **Full URL**: `http://localhost:3000/api/v1/backup/{id}`
- **Controller**: `BackupController -> Roles()`
- **Service Execution**: `backupService.deleteBackup()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `BackupSnapshot`, `BackupMetadata`

**Purpose & Business Context**:
Delete backup according to retention policy (OPS-008). This endpoint operates with strict transactional integrity under the Backup & Disaster Recovery subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body**: *None (Empty Body)*

**Expected Responses**:
- `200 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

### BKP-006 — Test restore simulation or execute restore (OPS-007)

**بتعمل إيه؟**:
استعادة النظام وقاعدة البيانات من نسخة احتياطية سابقة في حالات الطوارئ.

**مين يقدر يستخدمها؟**:
SUPER_ADMIN

- **Method**: `POST`
- **Full URL**: `http://localhost:3000/api/v1/backup/{id}/restore`
- **Controller**: `BackupController -> Roles()`
- **Service Execution**: `backupService.createBackup()`
- **Authentication**: **JWT Bearer**
- **Authorized Roles**: `SUPER_ADMIN`
- **Test Priority**: **P2**
- **Prisma Database Entities**: `BackupSnapshot`, `BackupMetadata`

**Purpose & Business Context**:
Test restore simulation or execute restore (OPS-007). This endpoint operates with strict transactional integrity under the Backup & Disaster Recovery subsystem.

**Headers**:
```http
Content-Type: application/json
Authorization: Bearer <JWT_ACCESS_TOKEN>
X-Request-Id: <UUID_CORRELATION_ID>
```

**Path Parameters**:
| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `id` | `string` | `id-12345` | Identifier parameter: id |

**Request Body Payload**:
```json
{
  "simulateOnly": true
}
```

**Expected Responses**:
- `201 Success`: Successful execution with payload formatted in standard application envelope `{ success: true, data: ..., timestamp: ... }`.
- `400 Error`: Validation failure (invalid payload or params)
- `401 Error`: Missing or invalid Bearer JWT token
- `403 Error`: Forbidden: Requires role [SUPER_ADMIN]
- `404 Error`: Target entity does not exist

**Execution Prerequisites & Dependencies**:
- Valid JWT Bearer Access Token (AUTH-002)

---

