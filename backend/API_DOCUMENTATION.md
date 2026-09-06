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
