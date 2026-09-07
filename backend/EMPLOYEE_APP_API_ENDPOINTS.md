# Employee App API Endpoints — دليل الربط والتكامل الشامل لتطبيق الموظفين (Flutter)

> **النظام:** فندق وإدارة الموارد البشرية والقوى العاملة (CyberWise Hotel ERP & Workforce Management System)  
> **البيئة:** NestJS 10 (Fastify Engine) + Prisma ORM + PostgreSQL + Redis  
> **Base URL الفعلي:** `http://localhost:3000/api/v1` (أو الرابط السحابي للباك إند)  
> **Global Prefix المستخرج من الكود (`main.ts`):** `/api/v1`  
> **معيار المصادقة والتفويض:** RFC 6750 Bearer Token (JWT Access Token صالح 15 دقيقة، Refresh Token صالح 7 أيام)  
> **الهدف من هذا الملف:** توثيق حصري ودقيق بنسبة 100% لجميع الـ API Endpoints التي يحتاجها تطبيق الموظف (**Flutter Employee Mobile App**) فقط، والمستخرجة من الـ Controllers والـ DTOs والـ Prisma Schema الفعلية.

---

## 📑 جدول المحتويات (Index)

1. [جدول الـ APIs الرئيسي لتطبيق الموظف (Master Employee Endpoints Table)](#1-جدول-ال-apis-الرئيسي-لتطبيق-الموظف)
2. [التوثيق التفصيلي للـ Endpoints (Detailed Documentation)](#2-التوثيق-التفصيلي-لل-endpoints)
   - [01. تهيئة التطبيق والفحص الحي (App Bootstrap & Health)](#module-01-app-bootstrap--health)
   - [02. المصادقة والجلسات وكلمة المرور (Authentication & Security)](#module-02-authentication--security)
   - [03. الملف الشخصي وبيانات الموظف (Profile & Onboarding)](#module-03-profile--onboarding)
   - [04. مواقع العمل والنطاق الجغرافي (Workplaces & Geofences)](#module-04-workplaces--geofences)
   - [05. الورديات وجدول العمل (Schedules & Shifts)](#module-05-schedules--shifts)
   - [06. الحضور والانصراف والبصمة الذكية (Attendance & Smart Punch)](#module-06-attendance--smart-punch)
   - [07. طلبات الموظفين والإجازات والأذونات (Requests & Leaves)](#module-07-requests--leaves)
   - [08. الرواتب والسلف المالية والمستحقات (Payroll, Advances & Payslips)](#module-08-payroll-advances--payslips)
   - [09. مهام العمل والتكليفات (Tasks & Checklist Management)](#module-09-tasks--checklist-management)
   - [10. الإشعارات وتنبيهات الجوال (Push Notifications & In-App Alerts)](#module-10-push-notifications--in-app-alerts)
   - [11. الإعلانات والتعميمات الإدارية (HR Announcements)](#module-11-hr-announcements)
   - [12. المحادثات والتواصل مع الـ HR (Internal Messaging & Chat)](#module-12-internal-messaging--chat)
   - [13. طلبات الخدمة والعمليات الفندقية (Service Requests)](#module-13-service-requests)
   - [14. تسليم واستلام الورديات (Shift Handover)](#module-14-shift-handover)
   - [15. التقارير الذاتية ومؤشرات الأداء (Employee Self-Reports)](#module-15-employee-self-reports)
   - [16. البلاغات وحوادث السلامة (Incidents & Safety Reporting)](#module-16-incidents--safety-reporting)
   - [17. بلاغات الصيانة للأجهزة والمرافق (Maintenance Requests)](#module-17-maintenance-requests)
   - [18. الأمانات والمفقودات (Lost & Found)](#module-18-lost--found)
   - [19. مستندات وعقود الموظف (Employee Documents)](#module-19-employee-documents)
   - [20. الأهداف وتقييم الأداء (Performance Goals & Reviews)](#module-20-performance-goals--reviews)
   - [21. التدريب والشهادات المهنية (Training & Certificates)](#module-21-training--certificates)
   - [22. إدارة أجهزة وجلسات الموظف (Sessions & Active Devices)](#module-22-sessions--active-devices)
   - [23. محرك المزامنة دون اتصال (Offline Sync Engine)](#module-23-offline-sync-engine)
   - [24. رفع المرفقات والملفات (File Storage & Attachments)](#module-24-file-storage--attachments)
3. [قسم خاص: الـ APIs الخاصة بالإدارة والـ HR فقط (ADMIN / HR ONLY)](#3-admin--hr-only-endpoints)

---

## 1. جدول الـ APIs الرئيسي لتطبيق الموظف

| # | Module | Method | Endpoint | Auth | Role | Description |
|---|---|---|---|---|---|---|
| **01** | Bootstrap | `GET` | `/api/v1/health/live` | Public | Any | التأكد من أن السيرفر شغال ويستجيب |
| **02** | Bootstrap | `GET` | `/api/v1/settings/public` | Public | Any | جلب الإعدادات العامة للنظام وشعار وهوية الفندق |
| **03** | Auth | `POST` | `/api/v1/auth/login` | Public | Public | تسجيل الدخول بالبريد الإلكتروني وكلمة المرور |
| **04** | Auth | `POST` | `/api/v1/auth/google` | Public | Public | تسجيل الدخول السريع بحساب Google مع فحص حالة التهيئة |
| **05** | Auth | `POST` | `/api/v1/auth/refresh` | Public | Public | تجديد الـ Access Token المنتهي باستخدام الـ Refresh Token |
| **06** | Auth | `POST` | `/api/v1/auth/logout` | Required | All | تسجيل الخروج وإبطال الـ Refresh Token والجلسة |
| **07** | Auth | `POST` | `/api/v1/auth/change-password` | Required | All | تغيير كلمة المرور للموظف الحالي |
| **08** | Auth | `GET` | `/api/v1/auth/me` | Required | All | استرجاع بيانات حساب المستخدم الحالي وحالته |
| **09** | Profile | `GET` | `/api/v1/employees/me` | Required | Employee+ | استعراض الملف الوظيفي والشخصي الكامل للموظف |
| **10** | Profile | `PATCH` | `/api/v1/employees/me/profile` | Required | Employee+ | استكمال وتحديث الملف الشخصي للموظف (Onboarding) |
| **11** | Profile | `GET` | `/api/v1/employees/me/workplace` | Required | Employee+ | جلب موقع عمل الموظف وإحداثيات النطاق الجغرافي (Geofence) |
| **12** | Profile | `GET` | `/api/v1/employees/me/schedule` | Required | Employee+ | استعراض جدول ورديات الموظف وفترة السماح وساعات العمل |
| **13** | Workplaces | `GET` | `/api/v1/workplaces` | Required | Employee+ | استعراض قائمة مواقع وفروع الفندق النشطة |
| **14** | Workplaces | `GET` | `/api/v1/workplaces/:id` | Required | Employee+ | تفاصيل موقع عمل محدد وإحداثيات الـ Geofence |
| **15** | Schedules | `GET` | `/api/v1/schedules` | Required | Employee+ | استعراض قوالب ومواعيد الورديات المتاحة |
| **16** | Schedules | `GET` | `/api/v1/schedules/:id` | Required | Employee+ | تفاصيل وردية محددة وساعات البداية والنهاية |
| **17** | Hierarchy | `GET` | `/api/v1/organization/reporting-tree/:employeeProfileId` | Required | Employee+ | شجرة التسلسل الإداري للموظف ومديره المباشر |
| **18** | Attendance | `POST` | `/api/v1/attendance/check-in` | Required | Employee+ | تسجيل حضور الموظف الذكي بالـ GPS والبيومتري وفحص الأمان |
| **19** | Attendance | `POST` | `/api/v1/attendance/check-out` | Required | Employee+ | تسجيل انصراف الموظف وحساب ساعات العمل المنجزة |
| **20** | Attendance | `GET` | `/api/v1/attendance/today` | Required | Employee+ | استعراض حالة الحضور والانصراف لليوم الحالي للوردية |
| **21** | Attendance | `GET` | `/api/v1/attendance/me` | Required | Employee+ | سجل حضور وانصراف الموظف مع الفلترة بالتواريخ والشهور |
| **22** | Requests | `POST` | `/api/v1/requests` | Required | Employee+ | تقديم طلب جديد (إجازة، إذن ساعي، عذر تأخير، سلفة، إلخ) |
| **23** | Requests | `GET` | `/api/v1/requests/me` | Required | Employee+ | استعراض طلباتي السابقة وحالات الموافقة عليها |
| **24** | Requests | `GET` | `/api/v1/requests/leave-balances/me` | Required | Employee+ | استعراض أرصدة الإجازات السنوية والمتبقية للموظف |
| **25** | Requests | `GET` | `/api/v1/requests/:id` | Required | Employee+ | استعراض تفاصيل طلب معين وتاريخ دورة الاعتمادات |
| **26** | Requests | `POST` | `/api/v1/requests/:id/cancel` | Required | Employee+ | إلغاء طلب معلق قبل البت فيه من الإدارة |
| **27** | Payroll | `GET` | `/api/v1/payroll/salary/me` | Required | Employee+ | استعراض هيكل الراتب الحالي والبدلات المعتمدة |
| **28** | Payroll | `POST` | `/api/v1/payroll/advances` | Required | Employee+ | تقديم طلب سلفة مالية على الراتب وعدد الأقساط |
| **29** | Payroll | `GET` | `/api/v1/payroll/advances/me` | Required | Employee+ | متابعة سلف الموظف وجدول سداد الأقساط المتبقية |
| **30** | Payroll | `GET` | `/api/v1/payroll/advances/:id` | Required | Employee+ | استعراض تفاصيل سلفة محددة ومواعيد استحقاق أقساطها |
| **31** | Payroll | `GET` | `/api/v1/payroll/deductions/me` | Required | Employee+ | استعراض الخصومات والجزاءات المطبقة على الموظف |
| **32** | Payroll | `GET` | `/api/v1/payroll/me` | Required | Employee+ | استعراض مسيرات الرواتب الشهرية وقسائم القبض |
| **33** | Payroll | `GET` | `/api/v1/payroll/records/:id` | Required | Employee+ | تفاصيل قسيمة راتب شهرية محددة ومفرداتها تفصيلياً |
| **34** | Tasks | `GET` | `/api/v1/tasks/my` | Required | Employee+ | استعراض قائمة المهام المسندة للموظف والمهام التي أنشأها |
| **35** | Tasks | `GET` | `/api/v1/tasks/:id` | Required | Employee+ | تفاصيل المهمة وقائمة المراجعة (Checklist) والمرفقات |
| **36** | Tasks | `PATCH` | `/api/v1/tasks/:id` | Required | Employee+ | تحديث تقدم المهمة أو ملاحظاتها وتاريخ استحقاقها |
| **37** | Tasks | `POST` | `/api/v1/tasks/:id/accept` | Required | Employee+ | قبول الموظف للمهمة المسندة إليه (من TODO إلى ACCEPTED) |
| **38** | Tasks | `POST` | `/api/v1/tasks/:id/status` | Required | Employee+ | تحديث دورة حياة المهمة (IN_PROGRESS, BLOCKED, COMPLETED) |
| **39** | Tasks | `POST` | `/api/v1/tasks/:id/checklist` | Required | Employee+ | إضافة عنصر تحقق جديد داخل قائمة فحص المهمة |
| **40** | Tasks | `PATCH` | `/api/v1/tasks/:id/checklist/:itemId` | Required | Employee+ | تعليم عنصر فحص كمكتمل وتحديث نسبة إنجاز المهمة تلقائياً |
| **41** | Tasks | `DELETE` | `/api/v1/tasks/:id/checklist/:itemId` | Required | Employee+ | حذف عنصر فحص من قائمة المهمة |
| **42** | Tasks | `POST` | `/api/v1/tasks/:id/comments` | Required | Employee+ | إضافة تعليق أو تحديث كتابي على المهمة |
| **43** | Tasks | `GET` | `/api/v1/tasks/:id/comments` | Required | Employee+ | استعراض كافة التعليقات والنقاشات على المهمة |
| **44** | Tasks | `POST` | `/api/v1/tasks/:id/attachments` | Required | Employee+ | إرفاق ملف أو صورة تثبت إنجاز المهمة |
| **45** | Tasks | `GET` | `/api/v1/tasks/:id/attachments` | Required | Employee+ | استعراض مرفقات ومستندات المهمة |
| **46** | Tasks | `GET` | `/api/v1/tasks/:id/history` | Required | Employee+ | استعراض السجل الزمني والتدقيقي لتغييرات المهمة |
| **47** | Notifications | `POST` | `/api/v1/notifications/device-token` | Required | All | تسجيل أو تجديد رمز Firebase FCM لاستقبال الإشعارات |
| **48** | Notifications | `DELETE` | `/api/v1/notifications/device-token/:fcmToken` | Required | All | إلغاء تسجيل رمز الـ FCM عند تسجيل الخروج |
| **49** | Notifications | `GET` | `/api/v1/notifications` | Required | All | استعراض قائمة الإشعارات والتنبيهات الموجهة للموظف |
| **50** | Notifications | `GET` | `/api/v1/notifications/unread-count` | Required | All | جلب عدد الإشعارات غير المقروءة لعرض الـ Badge |
| **51** | Notifications | `POST` | `/api/v1/notifications/:id/read` | Required | All | تحديد إشعار معين كمقروء |
| **52** | Notifications | `POST` | `/api/v1/notifications/read-all` | Required | All | تحديد كل الإشعارات الواردة كمقروءة دفعة واحدة |
| **53** | Notifications | `GET` | `/api/v1/notifications/preferences` | Required | All | استعراض تفضيلات قنوات الإشعارات (Push, Email, In-App) |
| **54** | Notifications | `PATCH` | `/api/v1/notifications/preferences` | Required | All | تعديل تفضيلات تلقي الإشعارات لمختلف الأحداث |
| **55** | Announcements | `GET` | `/api/v1/announcements` | Required | All | استعراض التعميمات والإعلانات الإدارية العامة وقسم الموظف |
| **56** | Announcements | `GET` | `/api/v1/announcements/:id` | Required | All | قراءة تفاصيل إعلان معين مع تسجيل القراءة آلياً |
| **57** | Announcements | `POST` | `/api/v1/announcements/:id/read` | Required | All | تأكيد واعتراف الموظف بقراءة وفهم الإعلان الإداري |
| **58** | Messaging | `POST` | `/api/v1/messages/conversations` | Required | All | بدء محادثة جديدة 1-on-1 (مع مسؤول الـ HR أو زميل) |
| **59** | Messaging | `POST` | `/api/v1/messages/groups` | Required | All | إنشاء محادثة جماعية خاصة بفريق أو قسم |
| **60** | Messaging | `GET` | `/api/v1/messages/conversations` | Required | All | استعراض قائمة المحادثات مع آخر رسالة وعداد غير المقروء |
| **61** | Messaging | `GET` | `/api/v1/messages/unread-count` | Required | All | إجمالي عدد الرسائل غير المقروءة في كل المحادثات |
| **62** | Messaging | `GET` | `/api/v1/messages/conversations/:id` | Required | Participant | استعراض أرشيف رسائل محادثة معينة |
| **63** | Messaging | `POST` | `/api/v1/messages/conversations/:id/messages`| Required | Participant | إرسال رسالة نصية أو مرفق داخل محادثة |
| **64** | Messaging | `POST` | `/api/v1/messages/conversations/:id/read` | Required | Participant | تعليم جميع رسائل المحادثة كمقروءة |
| **65** | Messaging | `DELETE` | `/api/v1/messages/:id` | Required | Sender | حذف رسالة مرسلة من قِبل الموظف |
| **66** | Service Requests| `POST` | `/api/v1/service-requests` | Required | Employee+ | إنشاء طلب خدمة تشغيلي (صيانة غرفة، طلب إشراف داخلي، إلخ) |
| **67** | Service Requests| `GET` | `/api/v1/service-requests` | Required | Employee+ | استعراض طلبات الخدمة المنشأة بواسطة الموظف أو المسندة إليه |
| **68** | Service Requests| `GET` | `/api/v1/service-requests/:id` | Required | Participant | تفاصيل طلب الخدمة، القسم المعني، وخطوات المعالجة |
| **69** | Service Requests| `PATCH` | `/api/v1/service-requests/:id/start` | Required | Assignee | بدء الفني/الموظف في تنفيذ طلب الخدمة (IN_PROGRESS) |
| **70** | Service Requests| `PATCH` | `/api/v1/service-requests/:id/complete` | Required | Assignee | إنهاء العمل على طلب الخدمة وإرفاق ملاحظات الحل |
| **71** | Service Requests| `POST` | `/api/v1/service-requests/:id/review` | Required | Requester | مراجعة واعتماد الموظف الطالب لجودة تنفيذ الخدمة |
| **72** | Service Requests| `PATCH` | `/api/v1/service-requests/:id/cancel` | Required | Requester | إلغاء طلب الخدمة من قِبل منشئه مع ذكر السبب |
| **73** | Service Requests| `POST` | `/api/v1/service-requests/:id/comments` | Required | Participant | إضافة تعليق أو استفسار على طلب الخدمة |
| **74** | Handover | `POST` | `/api/v1/handover` | Required | Employee+ | إنشاء تقرير تسليم الوردية وتوثيق المهام العالقة |
| **75** | Handover | `GET` | `/api/v1/handover` | Required | Employee+ | استعراض تقارير تسليم الورديات السابقة للقسم |
| **76** | Handover | `GET` | `/api/v1/handover/:id` | Required | Participant | تفاصيل محضر تسليم وردية وعناصره المعلقة |
| **77** | Handover | `PATCH` | `/api/v1/handover/:id/acknowledge` | Required | Receiver | استلام وإقرار الوردية الجديدة بالموافقة أو التحفظ |
| **78** | Handover | `POST` | `/api/v1/handover/:id/items` | Required | Participant | إضافة بند أو مهمة مفتوحة جديدة لمحضر الوردية |
| **79** | Reports | `GET` | `/api/v1/reports/me` | Required | Employee+ | تقرير أداء وحضور الموظف الذاتي (نسبة الحضور، التأخير، الإجازات)|
| **80** | Incidents | `POST` | `/api/v1/incidents` | Required | Employee+ | الإبلاغ عن حادث أمني أو خطر سلامة فندقي أو إصابة |
| **81** | Incidents | `GET` | `/api/v1/incidents` | Required | Employee+ | استعراض قائمة البلاغات والحوادث المسجلة |
| **82** | Incidents | `GET` | `/api/v1/incidents/:id` | Required | Employee+ | تفاصيل بلاغ معين، تقرير التحقيق، والإجراءات التصحيحية |
| **83** | Maintenance | `POST` | `/api/v1/maintenance/requests` | Required | Employee+ | إنشاء بلاغ صيانة لمعدة، غرفة، أو مرفق فندقي |
| **84** | Maintenance | `GET` | `/api/v1/maintenance/requests` | Required | Employee+ | استعراض قائمة طلبات الصيانة |
| **85** | Maintenance | `GET` | `/api/v1/maintenance/requests/:id` | Required | Employee+ | تفاصيل طلب صيانة ومتابعة أمر الشغل (Work Order) |
| **86** | Lost & Found | `POST` | `/api/v1/lost-found` | Required | Employee+ | تسجيل أمانة أو غرض مفقود عُثر عليه في الفندق |
| **87** | Lost & Found | `GET` | `/api/v1/lost-found` | Required | Employee+ | استعراض سجل المفقودات والأمانات المسجلة |
| **88** | Lost & Found | `GET` | `/api/v1/lost-found/:id` | Required | Employee+ | تفاصيل الغرض المفقود ومكان حفظه بالخزينة |
| **89** | Documents | `GET` | `/api/v1/documents` | Required | Employee+ | استعراض الوثائق والمستندات المصرح للموظف بالاطلاع عليها |
| **90** | Documents | `GET` | `/api/v1/documents/:id` | Required | Employee+ | تفاصيل مستند معين ورابط تحميل الملف |
| **91** | Performance | `GET` | `/api/v1/performance/goals` | Required | Employee+ | استعراض الأهداف الوظيفية ومؤشرات الأداء المسندة للموظف |
| **92** | Performance | `PATCH` | `/api/v1/performance/goals/:id/progress` | Required | Employee+ | تحديث نسبة إنجاز هدف وظيفي وتحفيز الإنجاز الآلي |
| **93** | Performance | `GET` | `/api/v1/performance/reviews` | Required | Employee+ | استعراض تقييمات الأداء الدورية الخاصة بالموظف |
| **94** | Performance | `POST` | `/api/v1/performance/reviews/:id/acknowledge`| Required| Employee+ | إقرار واعتراف الموظف بنتيجة مناقشة تقييم أدائه السنوي |
| **95** | Training | `GET` | `/api/v1/training/courses` | Required | Employee+ | استعراض الدورات والبرامج التدريبية المتاحة |
| **96** | Training | `GET` | `/api/v1/training/sessions` | Required | Employee+ | استعراض الجلسات ومواعيد المحاضرات التدريبية المجدولة |
| **97** | Training | `GET` | `/api/v1/training/certificates` | Required | Employee+ | استعراض وتنزيل شهادات التدريب التي حصل عليها الموظف |
| **98** | Sessions | `POST` | `/api/v1/sessions/register` | Required | All | تسجيل جلسة هاتف الموظف (نوع الجهاز، الإصدار، الـ FCM) |
| **99** | Sessions | `GET` | `/api/v1/sessions/my-devices` | Required | All | استعراض الهواتف والأجهزة النشطة المرتبطة بحساب الموظف |
| **100**| Sessions | `DELETE` | `/api/v1/sessions/:id` | Required | All | تسجيل الخروج عن بعد من هاتف أو جهاز محدد |
| **101**| Sessions | `DELETE` | `/api/v1/sessions/other/:currentSessionId` | Required | All | إنهاء كل الجلسات الأخرى باستثناء الهاتف الحالي |
| **102**| Offline Sync | `POST` | `/api/v1/sync` | Required | All | نقطة المزامنة الأساسية لحركات عدم الاتصال للموبايل |
| **103**| Offline Sync | `POST` | `/api/v1/sync/batch` | Required | All | إرسال حزمة عمليات مسجلة بدون إنترنت (Punches, Tasks) |
| **104**| Offline Sync | `GET` | `/api/v1/sync/changes` | Required | All | جلب تحديثات السيرفر الجديدة منذ آخر مزامنة (Delta Sync) |
| **105**| Offline Sync | `GET` | `/api/v1/sync/queue` | Required | All | متابعة حالة طابور العمليات المرسلة مسبقاً والتأكد من معالجتها |
| **106**| Offline Sync | `POST` | `/api/v1/sync/retry/:id` | Required | All | إعادة محاولة معالجة عملية مزامنة معلقة أو فاشلة |
| **107**| Offline Sync | `POST` | `/api/v1/sync/resolve-conflict/:id` | Required | All | حل تعارض بيانات المزامنة وفق استراتيجية معتمدة |
| **108**| Storage | `POST` | `/api/v1/storage/upload` | Required | All | رفع ملف أو صورة Base64 والحصول على رابط آمن وفوري |
| **109**| Storage | `GET` | `/api/v1/storage/metadata/:folder/:filename` | Required | All | استرجاع البيانات الوصفية لملف مرفوع ومخزن |

---

## 2. التوثيق التفصيلي للـ Endpoints

### MODULE 01: App Bootstrap & Health

---

## [API-001] Liveness Probe (فحص جاهزية السيرفر)

### الوظيفة
الـ API دي وظيفتها يتصل بيها تطبيق Flutter في بداية التشغيل أو لما يحس إن النت رجع، علشان يتأكد إن السيرفر قايم وبيرد، ويقيس سرعة استجابة الاتصال (Latency).

### Method
`GET`

### Endpoint
`/api/v1/health/live`

### Authentication
`Public` (بدون توكن)

### Role
متاح للجميع

### Permission
لا يوجد

### Headers
```http
Accept: application/json
```

### Path Parameters
لا يوجد

### Query Parameters
لا يوجد

### Request Body
لا يوجد

### Response Body
```json
{
  "status": "ok",
  "uptimeSeconds": 14250,
  "timestamp": "2026-09-07T00:00:00.000Z"
}
```

---

## [API-002] Public Bootstrap Settings (إعدادات النظام العامة)

### الوظيفة
الـ API دي بيطلبها التطبيق أول ما يفتح علشان يجيب البيانات العامة اللي مش محتاجة تسجيل دخول، زي اسم الفندق، اللوجو، المنطقة الزمنية، رقم إصدار التطبيق الأدنى المطلوب للتحديث الإجباري، وسياسات الحضور العامة.

### Method
`GET`

### Endpoint
`/api/v1/settings/public`

### Authentication
`Public`

### Role
متاح للجميع

### Permission
لا يوجد

### Headers
```http
Accept: application/json
```

### Path Parameters
لا يوجد

### Query Parameters
لا يوجد

### Request Body
لا يوجد

### Response Body
```json
{
  "hotelName": "Grand Nile Headquarters & Resort",
  "logoUrl": "http://localhost:3000/uploads/branding/logo.png",
  "defaultTimezone": "Africa/Cairo",
  "minAppVersion": "1.0.0",
  "enforceGeofence": true,
  "supportEmail": "support@hotel.com"
}
```

---

### MODULE 02: Authentication & Security

---

## [API-003] Login User (تسجيل الدخول بالبريد وكلمة المرور)

### الوظيفة
الـ API دي الموظف بيكتب فيها الإيميل وكلمة السر بتاعته علشان يدخل التطبيق. السيرفر بيشيك عليهم، ولو صح بيرجع له الـ `accessToken` (صلاحيته 15 دقيقة) والـ `refreshToken` (صلاحيته 7 أيام) وبيانات حسابه وحالة الـ Onboarding.

### Method
`POST`

### Endpoint
`/api/v1/auth/login`

### Authentication
`Public`

### Role
متاح للجميع

### Permission
لا يوجد

### Headers
```http
Content-Type: application/json
Accept: application/json
```

### Path Parameters
لا يوجد

### Query Parameters
لا يوجد

### Request Body
```json
{
  "email": "employee.active@example.test",
  "password": "Test@123456"
}
```

### Response Body (Status: 200 OK)
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "7a8b9c0d-1e2f-4a5b-8c9d-0e1f2a3b4c5d",
  "expiresIn": 900,
  "user": {
    "id": "usr_99887766-aaaa-bbbb-cccc-112233445566",
    "email": "employee.active@example.test",
    "role": "EMPLOYEE",
    "status": "ACTIVE",
    "isOnboarded": true,
    "employeeProfileId": "emp_11223344-aaaa-bbbb-cccc-998877665544"
  }
}
```

---

## [API-004] Google OAuth Sign-In (تسجيل الدخول السريع بحساب Google)

### الوظيفة
الـ API دي بتستخدم لما الموظف يختار "تسجيل الدخول باستخدام Google" داخل تطبيق Flutter؛ بيبعت الـ `idToken` اللي استلمه من Google SDK، والسيرفر بيتحقق منه ويرجع له التوكنات الرسمية الخاصة بالنظام مع توضيح هل حسابه مكتمل ولا محتاج يكمل بيانات الـ Onboarding.

### Method
`POST`

### Endpoint
`/api/v1/auth/google`

### Authentication
`Public`

### Role
متاح للجميع

### Permission
لا يوجد

### Headers
```http
Content-Type: application/json
Accept: application/json
```

### Path Parameters
لا يوجد

### Query Parameters
لا يوجد

### Request Body
```json
{
  "idToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6ImFiY2RlZiJ9..."
}
```

### Response Body (Status: 200 OK)
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "3b2a1c0d-4e5f-6a7b-8c9d-0e1f2a3b4c5d",
  "expiresIn": 900,
  "user": {
    "id": "usr_google_123456",
    "email": "employee.google@example.test",
    "role": "EMPLOYEE",
    "status": "ACTIVE",
    "isOnboarded": true,
    "employeeProfileId": "emp_google_654321"
  }
}
```

---

## [API-005] Refresh Access Token (تجديد التوكن التلقائي)

### الوظيفة
الـ API دي بتشتغل في الـ Background في تطبيق Flutter أول ما الـ `accessToken` ينتهي (بعد 15 دقيقة) وتطلع رسالة 401 Unauthorized؛ التطبيق بيبعت الـ `refreshToken` للسيرفر، فالسيرفر يديله `accessToken` جديد تماماً من غير ما يخرج الموظف لشاشة تسجيل الدخول.

### Method
`POST`

### Endpoint
`/api/v1/auth/refresh`

### Authentication
`Public`

### Role
متاح للجميع

### Permission
لا يوجد

### Headers
```http
Content-Type: application/json
Accept: application/json
```

### Path Parameters
لا يوجد

### Query Parameters
لا يوجد

### Request Body
```json
{
  "refreshToken": "7a8b9c0d-1e2f-4a5b-8c9d-0e1f2a3b4c5d"
}
```

### Response Body (Status: 200 OK)
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "new-rotated-refresh-token-uuid",
  "expiresIn": 900
}
```

---

## [API-006] Logout (تسجيل الخروج الآمن)

### الوظيفة
الـ API دي لما الموظف يضغط على "تسجيل الخروج" في البروفايل، بتبعت الـ `refreshToken` للسيرفر علشان يحرقه ويبطله تماماً في الـ Database وRedis، ويمنع استخدامه مرة تانية.

### Method
`POST`

### Endpoint
`/api/v1/auth/logout`

### Authentication
`Required` (Bearer Token)

### Role
أي مستخدم مسجل

### Permission
لا يوجد

### Headers
```http
Authorization: Bearer {{accessToken}}
Content-Type: application/json
Accept: application/json
```

### Request Body
```json
{
  "refreshToken": "7a8b9c0d-1e2f-4a5b-8c9d-0e1f2a3b4c5d"
}
```

### Response Body (Status: 200 OK)
```json
{
  "message": "Logged out successfully"
}
```

---

## [API-007] Change Password (تغيير كلمة المرور)

### الوظيفة
الـ API دي بتسمح للموظف يغير كلمة المرور بتاعته من داخل إعدادات الأمان في التطبيق، وبتشترط إدخال كلمة المرور الحالية للتأكد من هويته، مع كلمة المرور الجديدة وتأكيدها.

### Method
`POST`

### Endpoint
`/api/v1/auth/change-password`

### Authentication
`Required` (Bearer Token)

### Role
أي موظف مسجل

### Permission
لا يوجد

### Headers
```http
Authorization: Bearer {{accessToken}}
Content-Type: application/json
Accept: application/json
```

### Request Body
```json
{
  "currentPassword": "OldPassword@123",
  "newPassword": "NewStrongPassword@2026",
  "confirmPassword": "NewStrongPassword@2026"
}
```

### Response Body (Status: 200 OK)
```json
{
  "message": "Password changed successfully"
}
```

---

## [API-008] Get Current User (استرجاع بيانات الحساب الحالي)

### الوظيفة
الـ API دي بتجيب تفاصيل الحساب الحالي للمستخدم، بريده، دوره الوظيفي، حالته في النظام، وما إذا كان قد أتم تهيئة الحساب بالكامل أم لا.

### Method
`GET`

### Endpoint
`/api/v1/auth/me`

### Authentication
`Required` (Bearer Token)

### Role
أي مستخدم مسجل

### Headers
```http
Authorization: Bearer {{accessToken}}
Accept: application/json
```

### Response Body (Status: 200 OK)
```json
{
  "id": "usr_99887766-aaaa-bbbb-cccc-112233445566",
  "email": "employee.active@example.test",
  "role": "EMPLOYEE",
  "status": "ACTIVE",
  "isOnboarded": true,
  "employeeProfileId": "emp_11223344-aaaa-bbbb-cccc-998877665544"
}
```

---

### MODULE 03: Profile & Onboarding

---

## [API-009] Get My Complete Profile (استعراض الملف الشخصي والوظيفي الكامل)

### الوظيفة
الـ API دي بتجيب كل تفاصيل الموظف في شاشة الـ Profile: اسمه، رقمه القومي، رقم تليفونه، وظيفته، قسمه، فرعه، تاريخ تعيينه، صورته الشخصية، ومديره المباشر.

### Method
`GET`

### Endpoint
`/api/v1/employees/me`

### Authentication
`Required` (Bearer Token)

### Role
`EMPLOYEE`, `SUPERVISOR`, `HR_MANAGER`, `HR_ADMIN`, `SUPER_ADMIN`

### Headers
```http
Authorization: Bearer {{accessToken}}
Accept: application/json
```

### Response Body (Status: 200 OK)
```json
{
  "id": "emp_11223344-aaaa-bbbb-cccc-998877665544",
  "employeeNumber": "EMP-2026-0042",
  "firstName": "أحمد",
  "lastName": "محمود",
  "nationalId": "29501011234567",
  "phone": "+201001234567",
  "jobTitle": "موظف استقبال أول (Senior Receptionist)",
  "department": "Front Office",
  "gender": "MALE",
  "avatarUrl": "http://localhost:3000/uploads/avatars/emp_42.jpg",
  "hireDate": "2025-01-15T00:00:00.000Z",
  "workplace": {
    "id": "wkp_main_resort_uuid",
    "name": "Grand Nile Resort - Main Building",
    "code": "GNR-MB"
  },
  "manager": {
    "id": "emp_manager_uuid",
    "name": "طارق سامي",
    "jobTitle": "Front Office Manager"
  }
}
```

---

## [API-010] Complete Onboarding Profile (استكمال الملف الشخصي الأولي)

### الوظيفة
الـ API دي بيستخدمها الموظف الجديد أول ما يسجل دخول لأول مرة لو حسابه لسه `isOnboarded: false`؛ بيكتب فيها اسمه المؤكد، رقمه القومي، رقم هاتفه، جنسه، ومكان عمله.

### Method
`PATCH`

### Endpoint
`/api/v1/employees/me/profile`

### Authentication
`Required` (Bearer Token)

### Role
`EMPLOYEE` والمستخدمين الجدد

### Headers
```http
Authorization: Bearer {{accessToken}}
Content-Type: application/json
```

### Request Body
```json
{
  "firstName": "طارق",
  "lastName": "زيد",
  "nationalId": "1098765432",
  "phone": "+966500000003",
  "jobTitle": "Software Engineer",
  "department": "Engineering",
  "workplaceId": "uuid-workplace-id",
  "gender": "MALE"
}
```

### Response Body (Status: 200 OK)
```json
{
  "id": "emp_11223344-aaaa-bbbb-cccc-998877665544",
  "isOnboarded": true,
  "message": "Profile completed successfully"
}
```

---

## [API-011] Get My Workplace & Geofence (جلب موقع عمل الموظف وإحداثيات البصمة)

### الوظيفة
الـ API دي مهمة جداً لتطبيق Flutter قبل عمل Check-in؛ بتجيب إحداثيات الفرع اللي الموظف متسكن عليه (`latitude`, `longitude`) ونصف قطر النطاق الجغرافي (`radius` بالمتر) علشان التطبيق يعرف يرسم دائرة الـ Geofence على الخريطة ويحدد هل الموظف جوه الفندق ولا براه.

### Method
`GET`

### Endpoint
`/api/v1/employees/me/workplace`

### Authentication
`Required` (Bearer Token)

### Role
`EMPLOYEE` وكل الأدوار

### Headers
```http
Authorization: Bearer {{accessToken}}
Accept: application/json
```

### Response Body (Status: 200 OK)
```json
{
  "id": "wkp_8877-aaaa-bbbb-cccc-dddd",
  "name": "Grand Nile Headquarters & Resort",
  "code": "GNH-HQ",
  "latitude": 30.0444,
  "longitude": 31.2357,
  "radius": 150,
  "address": "Nile Corniche, Garden City, Cairo",
  "timezone": "Africa/Cairo",
  "wifiBssidList": ["00:14:22:01:23:45", "a4:b2:39:10:20:30"],
  "bluetoothBeacons": []
}
```

---

## [API-012] Get My Shift Schedule (استعراض جدول ورديات الموظف)

### الوظيفة
الـ API دي بتجيب مواعيد عمل الموظف الرسمية المعتمدة على السيرفر: الوردية بتبدأ الساعة كام وبتخلص الساعة كام، فترة السماح قبل التأخير (Grace Period بالدقائق)، وهل اليوم ده يوم عمل ولا عطلة أسبوعية.

### Method
`GET`

### Endpoint
`/api/v1/employees/me/schedule`

### Authentication
`Required` (Bearer Token)

### Role
`EMPLOYEE` وكل الأدوار

### Headers
```http
Authorization: Bearer {{accessToken}}
Accept: application/json
```

### Response Body (Status: 200 OK)
```json
{
  "scheduleId": "sch_morning_shift_uuid",
  "shiftName": "Morning Shift (الوردية الصباحية)",
  "startTime": "08:00",
  "endTime": "16:00",
  "gracePeriodMinutes": 15,
  "workingDays": ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY"],
  "serverTime": "2026-09-07T08:05:00.000Z",
  "isTodayWorkDay": true
}
```

---

### MODULE 04: Workplaces & Geofences

---

## [API-013] List Workplaces (استعراض قائمة مواقع وفروع الفندق)

### الوظيفة
الـ API دي بتجيب قائمة الفروع ومواقع العمل النشطة في الفندق، علشان تظهر للموظف لو محتاج يختار موقع معين أو يبحث عن مكان الفرع الثاني.

### Method
`GET`

### Endpoint
`/api/v1/workplaces`

### Authentication
`Required` (Bearer Token)

### Role
`EMPLOYEE`, `SUPERVISOR`, `HR_MANAGER`, `HR_ADMIN`, `SUPER_ADMIN`

### Headers
```http
Authorization: Bearer {{accessToken}}
```

### Response Body (Status: 200 OK)
```json
[
  {
    "id": "wkp_1",
    "name": "Grand Nile Resort - Cairo",
    "code": "GNR-CAI",
    "latitude": 30.0444,
    "longitude": 31.2357,
    "radius": 150,
    "isActive": true
  },
  {
    "id": "wkp_2",
    "name": "Red Sea Beach Resort - Hurghada",
    "code": "RSB-HRG",
    "latitude": 27.2579,
    "longitude": 33.8116,
    "radius": 300,
    "isActive": true
  }
]
```

---

## [API-014] Get Workplace Details (تفاصيل موقع عمل ونطاقه الجغرافي)

### الوظيفة
الـ API دي بتجيب تفاصيل فرع أو مبنى معين في الفندق مع إحداثيات الـ Geofence الدقيقة وشبكات الواي فاي التابعة له.

### Method
`GET`

### Endpoint
`/api/v1/workplaces/:id`

### Authentication
`Required` (Bearer Token)

### Role
`EMPLOYEE`, `SUPERVISOR`, `HR_MANAGER`, `HR_ADMIN`, `SUPER_ADMIN`

### Path Parameters
- `id` (string, Required): معرف موقع العمل (UUID).

### Response Body (Status: 200 OK)
```json
{
  "id": "wkp_1",
  "name": "Grand Nile Resort - Cairo",
  "code": "GNR-CAI",
  "latitude": 30.0444,
  "longitude": 31.2357,
  "radius": 150,
  "address": "Nile Corniche, Cairo",
  "isActive": true
}
```

---

### MODULE 05: Schedules & Shifts

---

## [API-015] List Shift Schedules (استعراض قوالب الورديات النشطة)

### الوظيفة
الـ API دي بتعرض جدول الورديات المعتمدة في الفندق ومواعيدها وتفاصيلها.

### Method
`GET`

### Endpoint
`/api/v1/schedules`

### Authentication
`Required` (Bearer Token)

### Role
`EMPLOYEE`, `SUPERVISOR`, `HR_MANAGER`, `HR_ADMIN`, `SUPER_ADMIN`

### Headers
```http
Authorization: Bearer {{accessToken}}
```

### Response Body (Status: 200 OK)
```json
[
  {
    "id": "sch_1",
    "name": "وردية صباحية (Morning)",
    "startTime": "08:00",
    "endTime": "16:00",
    "gracePeriod": 15,
    "isActive": true
  },
  {
    "id": "sch_2",
    "name": "وردية مسائية (Evening)",
    "startTime": "16:00",
    "endTime": "00:00",
    "gracePeriod": 15,
    "isActive": true
  },
  {
    "id": "sch_3",
    "name": "وردية ليلية (Night)",
    "startTime": "00:00",
    "endTime": "08:00",
    "gracePeriod": 15,
    "isActive": true
  }
]
```

---

## [API-016] Get Shift Schedule Details (تفاصيل وردية محددة)

### الوظيفة
الـ API دي بتجيب تفاصيل وردية معينة بالـ ID وساعات العمل المقررة بها.

### Method
`GET`

### Endpoint
`/api/v1/schedules/:id`

### Authentication
`Required` (Bearer Token)

### Role
`EMPLOYEE`, `SUPERVISOR`, `HR_MANAGER`, `HR_ADMIN`, `SUPER_ADMIN`

### Path Parameters
- `id` (string, Required): معرف الوردية (UUID).

---

### MODULE 06: Attendance & Smart Punch

---

## [API-017] Employee Check-In (تسجيل الحضور الذكي بالبصمة والـ GPS)

### الوظيفة
دي أهم API في تطبيق الموظف؛ لما الموظف يضغط "تسجيل حضور" (Check-In)، التطبيق بياخد إحداثيات الـ GPS الحالية، ودقة الإشارة (`accuracy`)، وحالة فحص البصمة (`biometricVerified`)، وإشارات الأمان (فحص هل الموظف عامل Fake GPS أو مشغل VPN أو عامل Root/Jailbreak). السيرفر بيفحص وجود الموظف داخل دائرة الـ Geofence، ولو تمام بيسجل الحضور ويحسب إذا كان في الميعاد أو متأخر كم دقيقة.

### Method
`POST`

### Endpoint
`/api/v1/attendance/check-in`

### Authentication
`Required` (Bearer Token)

### Role
`EMPLOYEE` وكل الأدوار

### Headers
```http
Authorization: Bearer {{accessToken}}
Content-Type: application/json
Accept: application/json
```

### Request Body (`CheckInDto`)
```json
{
  "latitude": 30.0444,
  "longitude": 31.2357,
  "accuracy": 12.5,
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "method": "GPS",
  "biometricVerified": true,
  "isMockLocation": false,
  "isVpn": false,
  "isJailbroken": false,
  "wifiBssid": "00:14:22:01:23:45",
  "notes": "حضور الوردية الصباحية"
}
```

### Response Body (Status: 201 Created)
```json
{
  "id": "att_record_uuid_12345",
  "employeeId": "emp_11223344-aaaa-bbbb-cccc-998877665544",
  "date": "2026-09-07T00:00:00.000Z",
  "checkInTime": "2026-09-07T08:02:15.000Z",
  "status": "PRESENT",
  "isLate": false,
  "lateMinutes": 0,
  "workplaceName": "Grand Nile Headquarters & Resort",
  "distanceFromGeofenceMeters": 18.4,
  "message": "تم تسجيل حضورك بنجاح! يوم سعيد وموفق."
}
```

---

## [API-018] Employee Check-Out (تسجيل الانصراف)

### الوظيفة
الـ API دي بيستخدمها الموظف في نهاية ورديته لتسجيل الانصراف (Check-Out)؛ بيبعت إحداثيات موقعه، والسيرفر بيقفل جلسة الحضور ويحسب إجمالي ساعات العمل الفعلية، وإذا كان فيه ساعات إضافية (Overtime) أو انصراف مبكر.

### Method
`POST`

### Endpoint
`/api/v1/attendance/check-out`

### Authentication
`Required` (Bearer Token)

### Role
`EMPLOYEE` وكل الأدوار

### Headers
```http
Authorization: Bearer {{accessToken}}
Content-Type: application/json
```

### Request Body (`CheckOutDto`)
```json
{
  "latitude": 30.0444,
  "longitude": 31.2357,
  "accuracy": 15.0,
  "requestId": "550e8400-e29b-41d4-a716-446655440001",
  "method": "GPS",
  "biometricVerified": true,
  "isMockLocation": false,
  "isVpn": false,
  "isJailbroken": false,
  "notes": "تم إنهاء أعمال الوردية الصباحية بنجاح"
}
```

### Response Body (Status: 200 OK)
```json
{
  "id": "att_record_uuid_12345",
  "checkOutTime": "2026-09-07T16:05:30.000Z",
  "totalWorkMinutes": 483,
  "overtimeMinutes": 5,
  "earlyDepartureMinutes": 0,
  "status": "COMPLETED",
  "message": "تم تسجيل انصرافك بنجاح. شكراً لجهودك اليوم!"
}
```

---

## [API-019] Get Today Attendance Status (حالة الحضور والانصراف لليوم)

### الوظيفة
الـ API دي أول ما شاشة الـ Home تفتح في تطبيق Flutter، بيطلبها علشان يعرف حالة الموظف النهاردة: هل هو مسجل حضور بالفعل؟ الساعة كام؟ ولا لسه ما سجلش؟ وهل سجل انصراف؟ وعداد الوقت شغال كام دقيقة لحد دلوقتي.

### Method
`GET`

### Endpoint
`/api/v1/attendance/today`

### Authentication
`Required` (Bearer Token)

### Role
`EMPLOYEE` وكل الأدوار

### Headers
```http
Authorization: Bearer {{accessToken}}
```

### Response Body (Status: 200 OK)
```json
{
  "hasCheckedIn": true,
  "hasCheckedOut": false,
  "checkInTime": "2026-09-07T08:02:15.000Z",
  "checkOutTime": null,
  "currentStatus": "PRESENT",
  "shift": {
    "name": "الوردية الصباحية",
    "startTime": "08:00",
    "endTime": "16:00"
  },
  "elapsedMinutes": 245
}
```

---

## [API-020] Get My Attendance History (سجل حضور الموظف التاريخي)

### الوظيفة
الـ API دي بتعرض سجل حضور وانصراف الموظف على مدار الأيام والشهور السابقة في شاشة التقويم أو سجل الحضور، مع إمكانية الفلترة بالشهر أو بين تاريخين.

### Method
`GET`

### Endpoint
`/api/v1/attendance/me` (أو الـ Alias: `/api/v1/attendance/history`)

### Authentication
`Required` (Bearer Token)

### Role
`EMPLOYEE` وكل الأدوار

### Query Parameters
- `page` (number, Optional, default: 1)
- `limit` (number, Optional, default: 20)
- `startDate` (string, Optional, YYYY-MM-DD): بداية فترة البحث.
- `endDate` (string, Optional, YYYY-MM-DD): نهاية فترة البحث.
- `month` (number, Optional, 1-12): رقم الشهر.
- `year` (number, Optional, e.g. 2026): السنة.

### Response Body (Status: 200 OK)
```json
{
  "data": [
    {
      "id": "att_1",
      "date": "2026-09-06",
      "checkIn": "08:01:10",
      "checkOut": "16:02:00",
      "status": "PRESENT",
      "lateMinutes": 0,
      "totalHours": 8.01
    },
    {
      "id": "att_2",
      "date": "2026-09-05",
      "checkIn": "08:25:00",
      "checkOut": "16:00:00",
      "status": "LATE",
      "lateMinutes": 25,
      "totalHours": 7.58
    }
  ],
  "meta": {
    "total": 24,
    "page": 1,
    "limit": 20
  }
}
```

---

### MODULE 07: Requests & Leaves

---

## [API-021] Submit Employee Request (تقديم طلب إجازة أو إذن أو عذر)

### الوظيفة
الـ API دي بيستخدمها الموظف لتقديم أي نوع من الطلبات الرسمية، زي: إجازة سنوية (`ANNUAL_LEAVE`)، إجازة مرضية (`SICK_LEAVE`)، إذن خروج ساعي (`PERMISSION`)، عذر تأخير (`LATE_EXCUSE`)، انصراف مبكر (`EARLY_LEAVE`)، عمل عن بُعد (`REMOTE_WORK`)، أو طلب عام (`GENERAL_REQUEST`). الطلب بيدخل تلقائياً في مسار الاعتمادات (Workflow Engine).

### Method
`POST`

### Endpoint
`/api/v1/requests`

### Authentication
`Required` (Bearer Token)

### Role
`EMPLOYEE` وكل الأدوار

### Headers
```http
Authorization: Bearer {{accessToken}}
Content-Type: application/json
```

### Request Body (`CreateRequestDto`)
```json
{
  "type": "ANNUAL_LEAVE",
  "startDate": "2026-09-15",
  "endDate": "2026-09-18",
  "startTime": null,
  "endTime": null,
  "reason": "إجازة سنوية اعتيادية للراحة مع العائلة",
  "attachmentUrl": "http://localhost:3000/uploads/requests/doc_1.pdf",
  "idempotencyKey": "req_uuid_v4_random_id"
}
```

> **أنواع الطلبات المدعومة في الـ `type` (من Prisma Enum):**
> `ANNUAL_LEAVE`, `SICK_LEAVE`, `UNPAID_LEAVE`, `EMERGENCY_LEAVE`, `OFFICIAL_LEAVE`, `PERMISSION`, `LATE_EXCUSE`, `EARLY_LEAVE`, `HALF_DAY`, `REMOTE_WORK`, `OVERTIME`, `DOCUMENT_REQUEST`, `RESIGNATION`, `GENERAL_REQUEST`.

### Response Body (Status: 201 Created)
```json
{
  "id": "req_uuid_9988-7766",
  "type": "ANNUAL_LEAVE",
  "status": "PENDING",
  "startDate": "2026-09-15T00:00:00.000Z",
  "endDate": "2026-09-18T00:00:00.000Z",
  "totalDays": 4,
  "reason": "إجازة سنوية اعتيادية للراحة مع العائلة",
  "currentApproverRole": "DIRECT_MANAGER",
  "createdAt": "2026-09-07T00:15:00.000Z"
}
```

---

## [API-022] Get My Submitted Requests (استعراض طلباتي السابقة)

### الوظيفة
الـ API دي بتجيب للموظف كل الطلبات اللي قدمها قبل كده (إجازات، أذونات، إلخ) وحالة كل طلب (معلق `PENDING`، معتمد `APPROVED`، مرفوض `REJECTED`، أو ملغي `CANCELLED`).

### Method
`GET`

### Endpoint
`/api/v1/requests/me` (أو الـ Alias: `/api/v1/requests/my-requests`)

### Authentication
`Required` (Bearer Token)

### Role
`EMPLOYEE` وكل الأدوار

### Query Parameters
- `type` (string, Optional): فلترة بنوع الطلب.
- `status` (string, Optional): `PENDING`, `APPROVED`, `REJECTED`, `CANCELLED`.
- `page` (number, Optional, default: 1)
- `limit` (number, Optional, default: 10)

### Response Body (Status: 200 OK)
```json
{
  "data": [
    {
      "id": "req_uuid_9988-7766",
      "type": "ANNUAL_LEAVE",
      "status": "PENDING",
      "startDate": "2026-09-15",
      "endDate": "2026-09-18",
      "totalDays": 4,
      "reason": "إجازة سنوية اعتيادية",
      "createdAt": "2026-09-07T00:15:00.000Z"
    }
  ],
  "meta": { "total": 1, "page": 1, "limit": 10 }
}
```

---

## [API-023] Get My Leave Balances (أرصدة الإجازات السنوية للموظف)

### الوظيفة
الـ API دي بتعرض للموظف في شاشة تقديم الإجازات رصيد إجازاته الحالي للسنة الحالية: الإجمالي المتاح، المستهلك، والمتبقي (مثلاً: رصيد سنوي 21 يوم، استهلك 5، المتبقي 16).

### Method
`GET`

### Endpoint
`/api/v1/requests/leave-balances/me`

### Authentication
`Required` (Bearer Token)

### Role
`EMPLOYEE` وكل الأدوار

### Query Parameters
- `year` (number, Optional, default: السنة الحالية مثلاً 2026)

### Response Body (Status: 200 OK)
```json
{
  "year": 2026,
  "annualLeave": {
    "allocatedDays": 21,
    "usedDays": 5,
    "remainingDays": 16
  },
  "sickLeave": {
    "allocatedDays": 14,
    "usedDays": 2,
    "remainingDays": 12
  },
  "emergencyLeave": {
    "allocatedDays": 6,
    "usedDays": 1,
    "remainingDays": 5
  }
}
```

---

## [API-024] Get Request Details & History (تفاصيل طلب معين ومسار الموافقات)

### الوظيفة
الـ API دي بتفتح شاشة تفاصيل طلب معين؛ بتعرض بيانات الطلب والسبب، وتاريخ الموافقة، ومين المدير اللي وافق أو رفض وملاحظات الاعتماد (Reviewer Notes). محمية برمجياً بحيث لا يراها إلا صاحب الطلب أو المسؤولين (IDOR Protected).

### Method
`GET`

### Endpoint
`/api/v1/requests/:id`

### Authentication
`Required` (Bearer Token)

### Path Parameters
- `id` (string, Required): معرف الطلب (UUID).

---

## [API-025] Cancel Pending Request (إلغاء طلب معلق)

### الوظيفة
الـ API دي بتسمح للموظف بإلغاء طلبه لو كان لسه في حالة `PENDING` ولم يتم اتخاذ قرار بشأنه من قِبل مديره بعد.

### Method
`POST` (أو `PATCH`)

### Endpoint
`/api/v1/requests/:id/cancel`

### Authentication
`Required` (Bearer Token)

### Path Parameters
- `id` (string, Required): معرف الطلب المراد إلغاؤه.

### Request Body (Optional)
```json
{
  "reason": "تم إلغاء السفر لظروف طارئة"
}
```

### Response Body (Status: 200 OK)
```json
{
  "id": "req_uuid_9988-7766",
  "status": "CANCELLED",
  "message": "تم إلغاء الطلب بنجاح واسترجاع الأيام لرصيدك"
}
```

---

### MODULE 08: Payroll, Advances & Payslips

---

## [API-026] Get My Salary Profile (استعراض مفردات وبدلات الراتب الحالي)

### الوظيفة
الـ API دي بتعرض للموظف في شاشة الراتب هيكله المالي: الراتب الأساسي (Basic Salary)، بدل السكن، بدل الانتقال، وأي بدلات ثابتة معتمدة له.

### Method
`GET`

### Endpoint
`/api/v1/payroll/salary/me`

### Authentication
`Required` (Bearer Token)

### Role
`EMPLOYEE` وكل الأدوار

### Headers
```http
Authorization: Bearer {{accessToken}}
```

### Response Body (Status: 200 OK)
```json
{
  "basicSalary": 6000.00,
  "housingAllowance": 1500.00,
  "transportAllowance": 800.00,
  "otherAllowances": 500.00,
  "grossSalary": 8800.00,
  "currency": "EGP",
  "effectiveFrom": "2026-01-01"
}
```

---

## [API-027] Request Salary Advance (طلب سلفة مالية على الراتب)

### الوظيفة
الـ API دي بيستخدمها الموظف لطلب سلفة على الراتب؛ بيحدد المبلغ المطلوب، وعدد شهور السداد (أقساط من 1 إلى 12 شهر)، وسبب طلب السلفة، وبتروح الطلبات للـ HR والمالية للاعتماد.

### Method
`POST`

### Endpoint
`/api/v1/payroll/advances`

### Authentication
`Required` (Bearer Token)

### Role
`EMPLOYEE` وكل الأدوار

### Headers
```http
Authorization: Bearer {{accessToken}}
Content-Type: application/json
```

### Request Body (`RequestAdvanceDto`)
```json
{
  "amount": 3000,
  "requestedInstallments": 3,
  "reason": "مصاريف علاجية طارئة ومستلزمات منزلية",
  "idempotencyKey": "adv_random_uuid_12345"
}
```

### Response Body (Status: 201 Created)
```json
{
  "id": "adv_uuid_123456",
  "amount": 3000,
  "requestedInstallments": 3,
  "status": "PENDING",
  "reason": "مصاريف علاجية طارئة ومستلزمات منزلية",
  "createdAt": "2026-09-07T00:20:00.000Z",
  "message": "تم تقديم طلب السلفة بنجاح وهو قيد المراجعة الإدارية"
}
```

---

## [API-028] Get My Advances (استعراض سلف الموظف وجدول الأقساط)

### الوظيفة
الـ API دي بتعرض للموظف كل طلبات السلف السابقة والحالية، وحالتها، وجدول الأقساط الشهرية المسددة والمتبقية وتواريخ استحقاقها.

### Method
`GET`

### Endpoint
`/api/v1/payroll/advances/me` (أو الـ Alias: `/api/v1/payroll/advances/my`)

### Authentication
`Required` (Bearer Token)

### Role
`EMPLOYEE` وكل الأدوار

### Query Parameters
- `status` (string, Optional): `PENDING`, `APPROVED`, `ACTIVE`, `PAID`, `REJECTED`
- `page` (number, Optional, default: 1)
- `limit` (number, Optional, default: 10)

### Response Body (Status: 200 OK)
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
      "createdAt": "2026-08-01T00:00:00.000Z",
      "installments": [
        { "month": "2026-08", "amount": 1000, "status": "PAID" },
        { "month": "2026-09", "amount": 1000, "status": "PENDING" },
        { "month": "2026-10", "amount": 1000, "status": "PENDING" }
      ]
    }
  ]
}
```

---

## [API-029] Get Advance Details (تفاصيل سلفة معينة)

### الوظيفة
الـ API دي بتجيب تفاصيل سلفة محددة بالـ ID مع جدول سداد أقساطها تفصيلياً (محمية للمالك فقط).

### Method
`GET`

### Endpoint
`/api/v1/payroll/advances/:id`

### Path Parameters
- `id` (string, Required): معرف السلفة (UUID).

---

## [API-030] Get My Deductions (استعراض الجزاءات والاستقطاعات)

### الوظيفة
الـ API دي بتعرض للموظف أي استقطاعات مالية أو جزاءات تم تطبيقها عليه وتاريخها والسبب المكتوب لها.

### Method
`GET`

### Endpoint
`/api/v1/payroll/deductions/me` (أو الـ Alias: `/api/v1/payroll/deductions/my`)

### Authentication
`Required` (Bearer Token)

### Query Parameters
- `page` (number, Optional, default: 1)
- `limit` (number, Optional, default: 20)

### Response Body (Status: 200 OK)
```json
{
  "data": [
    {
      "id": "ded_1",
      "amount": 150.00,
      "type": "LATE_PENALTY",
      "reason": "تأخير متكرر عن الوردية الصباحية 45 دقيقة",
      "effectiveDate": "2026-08-20"
    }
  ]
}
```

---

## [API-031] Get My Monthly Payslips (استعراض مسيرات الرواتب الشهرية)

### الوظيفة
الـ API دي بتعرض للموظف أرشيف قسائم الرواتب الشهرية الرسمية المعتمدة (Payslips) مع صافي الراتب لكل شهر.

### Method
`GET`

### Endpoint
`/api/v1/payroll/me`

### Authentication
`Required` (Bearer Token)

### Query Parameters
- `year` (number, Optional): سنة المسير.
- `page` (number, Optional, default: 1)

### Response Body (Status: 200 OK)
```json
{
  "data": [
    {
      "id": "pay_rec_august_2026",
      "periodName": "مسير شهر أغسطس 2026",
      "month": 8,
      "year": 2026,
      "grossSalary": 8800.00,
      "totalDeductions": 1150.00,
      "netSalary": 7650.00,
      "status": "FINALIZED",
      "disbursedAt": "2026-08-28T00:00:00.000Z"
    }
  ]
}
```

---

## [API-032] Get Payslip Itemized Details (تفاصيل قسيمة راتب محددة)

### الوظيفة
الـ API دي بتعرض قسيمة الراتب بالتفصيل الممل (Itemized Breakdown): كم ساعات الإضافي، كم استقطاع التأمينات، كم خصم قسط السلفة، وبنود البدلات بالتفصيل لطباعتها أو حفظها PDF.

### Method
`GET`

### Endpoint
`/api/v1/payroll/records/:id`

### Path Parameters
- `id` (string, Required): معرف سجل قسيمة الراتب.

---

### MODULE 09: Tasks & Checklist Management

---

## [API-033] Get My Tasks (استعراض مهام الموظف)

### الوظيفة
الـ API دي بتجيب كل المهام المسندة للموظف في الفندق (تنظيف غرف، صيانة مرافق، استقبال وفد، إلخ) أو المهام اللي هو مكلف بيها، مع الفلترة بالحالة والأولوية وتاريخ الاستحقاق.

### Method
`GET`

### Endpoint
`/api/v1/tasks/my`

### Authentication
`Required` (Bearer Token)

### Role
`EMPLOYEE` وكل الأدوار

### Query Parameters
- `status` (string, Optional): `TODO`, `ACCEPTED`, `IN_PROGRESS`, `BLOCKED`, `PENDING_REVIEW`, `COMPLETED`, `OVERDUE`, `CANCELLED`.
- `priority` (string, Optional): `LOW`, `MEDIUM`, `HIGH`, `URGENT`.
- `dueDate` (string, Optional, YYYY-MM-DD): تاريخ الاستحقاق.
- `search` (string, Optional): بحث في عنوان المهمة أو وصفها.
- `page` (number, Optional, default: 1)
- `limit` (number, Optional, default: 20)

### Response Body (Status: 200 OK)
```json
{
  "data": [
    {
      "id": "tsk_room_cleaning_101",
      "title": "فحص وتجهيز الجناح الملكي 504 للنزيل VIP",
      "description": "يرجى التأكد من نظافة الغرفة وتغيير المفارش ووضع باقة الترحيب",
      "priority": "HIGH",
      "status": "IN_PROGRESS",
      "dueDate": "2026-09-07T14:00:00.000Z",
      "progress": 60,
      "checklistCount": 5,
      "completedChecklistCount": 3,
      "assignedToId": "emp_11223344",
      "createdAt": "2026-09-07T08:00:00.000Z"
    }
  ],
  "meta": { "total": 1, "page": 1, "limit": 20 }
}
```

---

## [API-034] Get Task Details (تفاصيل المهمة وقائمة الفحص والمرفقات)

### الوظيفة
الـ API دي بتفتح شاشة تفاصيل المهمة كاملة: الوصف، بنود قائمة التحقق (Checklist)، الملاحظات، المرفقات، والتعليقات المتبادلة مع المشرف.

### Method
`GET`

### Endpoint
`/api/v1/tasks/:id`

### Authentication
`Required` (Bearer Token)

### Path Parameters
- `id` (string, Required): معرف المهمة (UUID).

---

## [API-035] Update Task Metadata & Progress (تحديث نسبة إنجاز المهمة)

### الوظيفة
الـ API دي بتسمح للموظف يحدث نسبة إنجاز المهمة يدوياً (`progress` من 0 إلى 100) أو يضيف ملاحظات إضافية.

### Method
`PATCH`

### Endpoint
`/api/v1/tasks/:id`

### Request Body (`UpdateTaskDto`)
```json
{
  "progress": 75,
  "description": "تم الانتهاء من فحص التكييف والميني بار وجاري الترتيب النهائي"
}
```

---

## [API-036] Accept Task (قبول الموظف للمهمة)

### الوظيفة
الـ API دي لما المشرف يسند مهمة للموظف، الموظف يضغط "قبول المهمة" علشان تتحول حالتها من `TODO` إلى `ACCEPTED` ويعرف المشرف إنه استلم التكليف وبدأ يرتب وقته.

### Method
`POST`

### Endpoint
`/api/v1/tasks/:id/accept`

### Authentication
`Required` (Bearer Token)

### Path Parameters
- `id` (string, Required): معرف المهمة.

### Request Body
لا يوجد Body مطلوب.

### Response Body (Status: 200 OK)
```json
{
  "id": "tsk_room_cleaning_101",
  "status": "ACCEPTED",
  "message": "تم قبول المهمة بنجاح"
}
```

---

## [API-037] Update Task Status (تحديث حالة المهمة التشغيلية)

### الوظيفة
الـ API دي بيستخدمها الموظف لنقل المهمة بين الحالات المختلفة: بدأ الشغل فيها (`IN_PROGRESS`)، واجه مشكلة أو عطل (`BLOCKED` مع كتابة السبب)، خلصها بالكامل (`COMPLETED`).

### Method
`POST`

### Endpoint
`/api/v1/tasks/:id/status`

### Request Body (`UpdateTaskStatusDto`)
```json
{
  "status": "COMPLETED",
  "reason": "تم إنهاء كافة متطلبات الجناح وتجهيزه بالكامل"
}
```

---

## [API-038] Add Task Checklist Item (إضافة عنصر فحص للمهمة)

### الوظيفة
الـ API دي بتمكن الموظف من إضافة نقطة فحص فرعية داخل المهمة ليتابع خطوات إنجازه بنداً بنداً.

### Method
`POST`

### Endpoint
`/api/v1/tasks/:id/checklist`

### Request Body (`AddChecklistItemDto`)
```json
{
  "title": "التأكد من تشغيل التكييف على درجة 22 مئوية",
  "orderIndex": 1
}
```

---

## [API-039] Toggle Checklist Item (تعليم بند فحص كمكتمل)

### الوظيفة
الـ API دي لما الموظف يعمل Checkbox على عنصر في القائمة، بتحدث حالته لـ `isCompleted: true`، والسيرفر بيحسب نسبة إنجاز المهمة العامة تلقائياً بناءً على عدد البنود المكتملة.

### Method
`PATCH`

### Endpoint
`/api/v1/tasks/:id/checklist/:itemId`

### Path Parameters
- `id` (string, Required): معرف المهمة.
- `itemId` (string, Required): معرف بند الفحص.

### Request Body (`UpdateChecklistItemDto`)
```json
{
  "isCompleted": true
}
```

---

## [API-040] Delete Checklist Item (حذف بند فحص)

### Method: `DELETE`
### Endpoint: `/api/v1/tasks/:id/checklist/:itemId`

---

## [API-041] Add Task Comment (إضافة تعليق أو تحديث على المهمة)

### Method: `POST`
### Endpoint: `/api/v1/tasks/:id/comments`
### Request Body:
```json
{
  "content": "تم الانتهاء من صيانة الستائر بواسطة الفني"
}
```

---

## [API-042] List Task Comments (استعراض تعليقات المهمة)

### Method: `GET`
### Endpoint: `/api/v1/tasks/:id/comments`

---

## [API-043] Add Task Attachment (إرفاق صورة أو مستند يثبت إنجاز المهمة)

### Method: `POST`
### Endpoint: `/api/v1/tasks/:id/attachments`
### Request Body:
```json
{
  "fileUrl": "http://localhost:3000/uploads/tasks/suite_504_ready.jpg",
  "filename": "suite_504_ready.jpg",
  "fileSize": 1048576,
  "mimeType": "image/jpeg"
}
```

---

## [API-044] List Task Attachments (استعراض مرفقات المهمة)

### Method: `GET`
### Endpoint: `/api/v1/tasks/:id/attachments`

---

## [API-045] Get Task History (السجل التدقيقي لتغييرات المهمة)

### Method: `GET`
### Endpoint: `/api/v1/tasks/:id/history`

---

### MODULE 10: Push Notifications & In-App Alerts

---

## [API-046] Register Device FCM Token (تسجيل رمز إشعارات Firebase)

### الوظيفة
الـ API دي تطبيق Flutter بيستدعيها أول ما الموظف يسجل دخول علشان يبعت رمز الـ Firebase FCM الخاص بجهازه، ونظام التشغيل (Android أو iOS) وموديل الموبايل، علشان الباك إند يقدر يبعتله Push Notifications لما يحصل أي حدث (موافقة على إجازة، مهمة جديدة، نزول راتب، إعلان طوارئ).

### Method
`POST`

### Endpoint
`/api/v1/notifications/device-token`

### Authentication
`Required` (Bearer Token)

### Request Body (`RegisterDeviceTokenDto`)
```json
{
  "fcmToken": "f7d8e9a0b1c2d3e4f5_firebase_device_token_sample",
  "platform": "ANDROID",
  "deviceId": "samsung_sm_g998b_uuid_123"
}
```

### Response Body (Status: 201 Created)
```json
{
  "message": "Device token registered successfully"
}
```

---

## [API-047] Unregister Device Token (إلغاء رمز الإشعارات عند الخروج)

### Method: `DELETE`
### Endpoint: `/api/v1/notifications/device-token/:fcmToken`

---

## [API-048] List My In-App Notifications (استعراض التنبيهات والإشعارات الواردة)

### الوظيفة
الـ API دي بتجيب قائمة الإشعارات الواردة للموظف في شاشة التنبيهات (Notification Center) مع تمييز الإشعارات المقروءة وغير المقروءة.

### Method
`GET`

### Endpoint
`/api/v1/notifications` (أو الـ Alias: `/api/v1/notifications/my`)

### Query Parameters
- `isRead` (boolean, Optional): `true` أو `false`.
- `type` (string, Optional): نوع الإشعار.
- `priority` (string, Optional): `LOW`, `NORMAL`, `HIGH`, `URGENT`.
- `page` (number, Optional, default: 1)
- `limit` (number, Optional, default: 20)

### Response Body (Status: 200 OK)
```json
{
  "data": [
    {
      "id": "notif_123",
      "title": "تمت الموافقة على طلب الإجازة",
      "body": "اعتمد مديرك المباشر طلب الإجازة السنوية من 15 إلى 18 سبتمبر",
      "type": "REQUEST_APPROVED",
      "priority": "HIGH",
      "isRead": false,
      "createdAt": "2026-09-07T00:10:00.000Z",
      "data": { "requestId": "req_uuid_9988-7766" }
    }
  ],
  "meta": { "total": 1, "page": 1, "limit": 20 }
}
```

---

## [API-049] Get Unread Notifications Count (عدد الإشعارات غير المقروءة)

### الوظيفة
الـ API دي بتجيب رقم سريع (مثلاً: 3) علشان يظهر على أيقونة الجرس في شريط التطبيق العلوي (Badge Count).

### Method
`GET`

### Endpoint
`/api/v1/notifications/unread-count`

### Response Body (Status: 200 OK)
```json
{
  "unreadCount": 3
}
```

---

## [API-050] Mark Notification as Read (تحديد إشعار كمقروء)

### Method: `POST` (أو `PATCH`)
### Endpoint: `/api/v1/notifications/:id/read`
### Path Parameters: `id` (معرف الإشعار).

---

## [API-051] Mark All Notifications as Read (تحديد كل الإشعارات كمقروءة)

### Method: `POST` (أو `PATCH`)
### Endpoint: `/api/v1/notifications/read-all`

---

## [API-052] Get & Update Notification Preferences (تفضيلات الإشعارات)

### Method: `GET` & `PATCH`
### Endpoint: `/api/v1/notifications/preferences`
### PATCH Body (`UpdateNotificationPreferencesDto`):
```json
{
  "attendanceNotifications": true,
  "requestNotifications": true,
  "payrollNotifications": true,
  "advanceNotifications": true,
  "announcementNotifications": true,
  "messageNotifications": true,
  "taskNotifications": true,
  "emailNotifications": false,
  "pushNotifications": true
}
```

---

### MODULE 11: HR Announcements

---

## [API-053] List Announcements (استعراض التعميمات والإعلانات الإدارية)

### الوظيفة
الـ API دي بتجيب للموظف كل الإعلانات الإدارية، وتنبيهات الطوارئ، وتعاميم إدارة الفندق الموجهة للشركة ككل أو لقسمه بالتحديد.

### Method
`GET`

### Endpoint
`/api/v1/announcements`

### Response Body (Status: 200 OK)
```json
{
  "data": [
    {
      "id": "ann_101",
      "title": "تحديث سياسة الزي الرسمي والضيافة لموسم الشتاء 2026",
      "summary": "يرجى من جميع موظفي المكاتب الأمامية والمطاعم الالتزام بالزي الجديد...",
      "priority": "HIGH",
      "publishedAt": "2026-09-01T10:00:00.000Z",
      "isReadByMe": true
    }
  ]
}
```

---

## [API-054] Get Announcement Details (تفاصيل الإعلان)

### Method: `GET`
### Endpoint: `/api/v1/announcements/:id`
*(ملاحظة: استدعاء هذه الـ API يسجل قراءة الموظف للإعلان تلقائياً).*

---

## [API-055] Acknowledge Announcement (إقرار قراءة الإعلان)

### Method: `POST`
### Endpoint: `/api/v1/announcements/:id/read`

---

### MODULE 12: Internal Messaging & Chat

---

## [API-056] Start 1-on-1 Conversation (بدء محادثة مباشرة)

### الوظيفة
الـ API دي بتسمح للموظف يبدأ شات مباشر وفوري مع أي موظف تاني أو مسؤول الـ HR أو مشرفه، مع إرسال الرسالة الافتتاحية والمرفقات.

### Method
`POST`

### Endpoint
`/api/v1/messages/conversations`

### Request Body (`CreateConversationDto`)
```json
{
  "participantUserId": "usr_hr_representative_uuid",
  "title": "استفسار بخصوص قيد مسير الرواتب",
  "content": "مساء الخير أستاذ أحمد، كنت حابب استفسر عن بدل السكن الخاص بشهر أغسطس",
  "attachmentUrl": null
}
```

---

## [API-057] Create Group Chat (إنشاء محادثة جماعية)

### Method: `POST`
### Endpoint: `/api/v1/messages/groups`
### Request Body:
```json
{
  "title": "فريق خدمة الغرف - الوردية الصباحية",
  "participantUserIds": ["usr_emp_1", "usr_emp_2", "usr_supervisor_1"],
  "initialMessage": "أهلاً بالجميع، القناة دي لمتابعة طلبات النزلاء الخاصة بالوردية"
}
```

---

## [API-058] List My Conversations (استعراض قائمة المحادثات)

### Method: `GET`
### Endpoint: `/api/v1/messages/conversations`
### Response Body:
```json
[
  {
    "id": "conv_1",
    "title": "استفسار HR",
    "isGroup": false,
    "lastMessage": {
      "content": "تمت مراجعة طلبك وسيتم إيداع الفرق قريباً",
      "createdAt": "2026-09-06T15:30:00.000Z"
    },
    "unreadCount": 1
  }
]
```

---

## [API-059] Get Total Unread Messages Count (إجمالي الرسائل غير المقروءة)

### Method: `GET`
### Endpoint: `/api/v1/messages/unread-count`
### Response Body: `{"unreadCount": 2}`

---

## [API-060] Get Conversation Messages (أرشيف رسائل محادثة معينة)

### Method: `GET`
### Endpoint: `/api/v1/messages/conversations/:id`
### Query Parameters:
- `page`, `limit`, `before` (Cursor timestamp for pagination).

---

## [API-061] Send Message in Conversation (إرسال رسالة في محادثة)

### Method: `POST`
### Endpoint: `/api/v1/messages/conversations/:id/messages`
### Request Body (`SendMessageDto`):
```json
{
  "content": "شكراً جزيلاً لسرعة الرد والاهتمام.",
  "attachmentUrl": null
}
```

---

## [API-062] Mark Conversation as Read (تعليم رسائل المحادثة كمقروءة)

### Method: `POST`
### Endpoint: `/api/v1/messages/conversations/:id/read`

---

## [API-063] Delete Message (حذف رسالة مرسلة)

### Method: `DELETE`
### Endpoint: `/api/v1/messages/:id`

---

### MODULE 13: Service Requests

---

## [API-064] Create Service Request (إنشاء طلب خدمة فندقي)

### الوظيفة
الـ API دي بيستخدمها موظف الفندق (موظف استقبال، مشرف، أو هاوس كيبنج) لطلب خدمة تشغيلية محددة لقسم تاني (زي صيانة سريعة، تنظيف طارئ، إمداد بمستلزمات، فحص فني لغرفة نزيل) مع تحديد الأولوية والغرفة والموعد المطلوب.

### Method
`POST`

### Endpoint
`/api/v1/service-requests`

### Request Body (`CreateServiceRequestDto`)
```json
{
  "title": "تسريب مياه في صنبور حمام الغرفة 304",
  "description": "نزيل الغرفة اشتكى من وجود تسريب مياه مستمر في حوض الحمام",
  "category": "MAINTENANCE",
  "priority": "HIGH",
  "departmentId": "dept_engineering_uuid",
  "location": "الطابق الثالث - الغرفة 304",
  "dueDate": "2026-09-07T12:00:00Z"
}
```

---

## [API-065] List Service Requests (استعراض طلبات الخدمة)

### Method: `GET`
### Endpoint: `/api/v1/service-requests`
### Query Parameters:
- `status`, `priority`, `category`, `departmentId`, `page`, `limit`.

---

## [API-066] Get Service Request Details (تفاصيل طلب الخدمة)

### Method: `GET`
### Endpoint: `/api/v1/service-requests/:id`

---

## [API-067] Start Service Request (بدء الفني في العمل)

### Method: `PATCH`
### Endpoint: `/api/v1/service-requests/:id/start`
*(ينقل حالة الطلب تلقائياً إلى `IN_PROGRESS`).*

---

## [API-068] Complete Service Request (إنهاء العمل على طلب الخدمة)

### Method: `PATCH`
### Endpoint: `/api/v1/service-requests/:id/complete`
### Request Body:
```json
{
  "status": "COMPLETED",
  "resolutionNotes": "تم استبدال الجلدة التالفة والصنبور يعمل بكفاءة تامة"
}
```

---

## [API-069] Review & Sign-Off Service Request (اعتماد جودة الخدمة)

### Method: `POST`
### Endpoint: `/api/v1/service-requests/:id/review`
### Request Body:
```json
{
  "decision": "ACCEPT",
  "feedback": "تم الإصلاح بجودة ممتازة وبسرعة فائقة",
  "rating": 5
}
```

---

## [API-070] Cancel Service Request (إلغاء طلب الخدمة من قِبل صاحبه)

### Method: `PATCH`
### Endpoint: `/api/v1/service-requests/:id/cancel`
### Request Body: `{"reason": "النزيل غادر الغرفة وتم تسويتها"}`

---

## [API-071] Add Comment on Service Request (إضافة ملاحظة على طلب الخدمة)

### Method: `POST`
### Endpoint: `/api/v1/service-requests/:id/comments`
### Request Body: `{"comment": "الفني في الطريق للغرفة الآن"}`

---

### MODULE 14: Shift Handover

---

## [API-072] Create Shift Handover (تدوين محضر تسليم الوردية)

### الوظيفة
الـ API دي أساسية لضمان استمرارية تشغيل الفندق على مدار الـ 24 ساعة؛ مشرف أو موظف الوردية الصباحية بيسجل محضر التسليم للوردية المسائية: ملخص أحداث الوردية، الغرف المفتوحة، المهام التي لم تكتمل، وأي بلاغات أو تنبيهات مهمة.

### Method
`POST`

### Endpoint
`/api/v1/handover`

### Request Body (`CreateHandoverDto`)
```json
{
  "shiftDate": "2026-09-07",
  "shiftName": "Morning Shift (الوردية الصباحية)",
  "departmentId": "dept_front_office_uuid",
  "receivedById": "emp_evening_supervisor_uuid",
  "summary": "تم إنهاء إجراءات تسكين 45 نزيل، يتبقى 3 غرف تحت الصيانة سيتم تسليمها للوردية المسائية",
  "notes": "يرجى الانتباه لوفد السفارة القادم في تمام الساعة 18:00",
  "includeOpenTasks": true,
  "items": [
    {
      "title": "متابعة صيانة تكييف جناح 502",
      "description": "فني الصيانة يعمل حالياً ومن المتوقع انتهاؤه الساعة 17:00",
      "category": "MAINTENANCE",
      "priority": "HIGH",
      "requiresAction": true
    }
  ]
}
```

---

## [API-073] List Shift Handovers (استعراض محاضر تسليم الورديات)

### Method: `GET`
### Endpoint: `/api/v1/handover`

---

## [API-074] Get Shift Handover Details (تفاصيل محضر وردية محدد)

### Method: `GET`
### Endpoint: `/api/v1/handover/:id`

---

## [API-075] Acknowledge Shift Handover (إقرار واستلام الوردية الجديدة)

### الوظيفة
الـ API دي بيستخدمها موظف الوردية المستلمة ليوقع إلكترونياً على استلام الوردية والتعهد بمتابعة المهام المفتوحة (`ACKNOWLEDGED` أو `FLAGGED`).

### Method
`PATCH`

### Endpoint
`/api/v1/handover/:id/acknowledge`

### Request Body (`AcknowledgeHandoverDto`)
```json
{
  "decision": "ACKNOWLEDGED",
  "notes": "تم استلام الوردية ومراجعة الغرف والمهام وجاري المتابعة"
}
```

---

## [API-076] Add Item to Handover (إضافة بند أو مهمة جديدة لمحضر الوردية)

### Method: `POST`
### Endpoint: `/api/v1/handover/:id/items`
### Request Body:
```json
{
  "title": "طلب سرير إضافي لغرفة 208",
  "category": "GUEST_REQUEST",
  "priority": "MEDIUM",
  "requiresAction": true
}
```

---

### MODULE 15: Employee Self-Reports

---

## [API-077] Get Employee Self-Report (تقرير أداء وحضور الموظف الذاتي)

### الوظيفة
الـ API دي بتجيب إحصائيات دقيقة ورسوم بيانية للموظف في شاشة التقارير الشخصية: نسبة التزامه بالحضور، إجمالي دقائق التأخير، الأيام اللي غاب فيها، عدد طلباته المعتمدة، والسلف القائمة.

### Method
`GET`

### Endpoint
`/api/v1/reports/me`

### Authentication
`Required` (Bearer Token)

### Query Parameters
- `startDate` (string, Optional, YYYY-MM-DD)
- `endDate` (string, Optional, YYYY-MM-DD)

### Response Body (Status: 200 OK)
```json
{
  "attendanceRate": 96.5,
  "presentDays": 22,
  "absentDays": 0,
  "lateDays": 1,
  "totalLateMinutes": 15,
  "totalWorkHours": 176.5,
  "approvedLeavesCount": 2,
  "activeAdvancesCount": 1,
  "completedTasksCount": 38,
  "overdueTasksCount": 0
}
```

---

### MODULE 16: Incidents & Safety Reporting

---

## [API-078] Report Incident (الإبلاغ عن حادث أمني أو خطر سلامة)

### الوظيفة
الـ API دي بتسمح لأي موظف في الفندق بالإبلاغ الفوري عن أي حادث أمني، حريق، إصابة عمل، أو خطر يهدد سلامة النزلاء مع رفع صور الإثبات فورياً.

### Method
`POST`

### Endpoint
`/api/v1/incidents`

### Request Body (`CreateIncidentDto`)
```json
{
  "title": "تجمع مياه بالقرب من مصاعد اللوبي الرئيسي",
  "description": "لوحظ وجود تسريب مياه مما قد يسبب انزلاق للنزلاء، تم وضع لافتة تحذيرية مؤقتة",
  "type": "SAFETY",
  "severity": "MEDIUM",
  "location": "اللوبي الرئيسي بجوار المصاعد الشرقية",
  "incidentDate": "2026-09-07T09:30:00.000Z",
  "departmentId": "dept_security_uuid",
  "evidenceUrls": [
    "http://localhost:3000/uploads/incidents/water_leak_lobby.jpg"
  ]
}
```

---

## [API-079] List Incidents (استعراض سجل البلاغات)

### Method: `GET`
### Endpoint: `/api/v1/incidents`

---

## [API-080] Get Incident Details (تفاصيل البلاغ والإجراءات التصحيحية)

### Method: `GET`
### Endpoint: `/api/v1/incidents/:id`

---

### MODULE 17: Maintenance Requests

---

## [API-081] Create Maintenance Request (تسجيل بلاغ صيانة مرفق أو جهاز)

### Method: `POST`
### Endpoint: `/api/v1/maintenance/requests`
### Request Body (`CreateMaintenanceRequestDto`):
```json
{
  "title": "عطل في كارت فتح الباب لغرفة 412",
  "description": "الكارت الإلكتروني لا يقرأ والقفل يصدر وميض أحمر مستمر",
  "type": "CORRECTIVE",
  "priority": "HIGH",
  "departmentId": "dept_engineering_uuid",
  "scheduledDate": "2026-09-07T11:00:00.000Z"
}
```

---

## [API-082] List Maintenance Requests (استعراض طلبات الصيانة)

### Method: `GET`
### Endpoint: `/api/v1/maintenance/requests`

---

## [API-083] Get Maintenance Request Details (تفاصيل طلب الصيانة)

### Method: `GET`
### Endpoint: `/api/v1/maintenance/requests/:id`

---

### MODULE 18: Lost & Found

---

## [API-084] Register Found Item (تسجيل غرض مفقود عُثر عليه)

### الوظيفة
الـ API دي بيستخدمها موظفو الهاوس كيبنج أو الأمن عند العثور على أي متعلقات خاصة بالنزلاء؛ لتسجيل اسم الغرض، وصفه، مكان وزمان العثور عليه، ومكان حفظه بالخزينة.

### Method
`POST`

### Endpoint
`/api/v1/lost-found`

### Request Body (`CreateLostFoundItemDto`)
```json
{
  "itemName": "ساعة يد رولكس فضية",
  "description": "ساعة يد رجالية بإطار فضي وميناء أزرق وجدت على منضدة الغرفة",
  "category": "JEWELRY",
  "locationFound": "الغرفة 602 - بعد مغادرة النزيل",
  "foundDate": "2026-09-07T10:15:00.000Z",
  "storageLocation": "خزينة الأمانات المركزية - صندوق رقم 12",
  "images": [
    "http://localhost:3000/uploads/lostfound/rolex_watch.jpg"
  ]
}
```

---

## [API-085] List Lost & Found Items (استعراض الأمانات والمفقودات)

### Method: `GET`
### Endpoint: `/api/v1/lost-found`

---

## [API-086] Get Lost & Found Item Details (تفاصيل الأمانة المسجلة)

### Method: `GET`
### Endpoint: `/api/v1/lost-found/:id`

---

### MODULE 19: Employee Documents

---

## [API-087] List Accessible Documents (استعراض المستندات والوثائق المصرح بها)

### الوظيفة
الـ API دي بتجيب للموظف الوثائق اللي تخصه أو السياسات العامة المصرح له برؤيتها، زي: عقد العمل، اللائحة الداخلية للفندق، دليل السلامة، ونماذج الموارد البشرية.

### Method
`GET`

### Endpoint
`/api/v1/documents`

---

## [API-088] Get Document Details & Download Link (تفاصيل المستند ورابط التحميل)

### Method: `GET`
### Endpoint: `/api/v1/documents/:id`

---

### MODULE 20: Performance Goals & Reviews

---

## [API-089] List My Performance Goals (استعراض أهداف الأداء الوظيفي)

### Method: `GET`
### Endpoint: `/api/v1/performance/goals`

---

## [API-090] Update Goal Progress (تحديث تقدم إنجاز هدف وظيفي)

### Method: `PATCH`
### Endpoint: `/api/v1/performance/goals/:id/progress`
### Request Body:
```json
{
  "currentValue": 85,
  "notes": "تم تحقيق 85% من المستهدف الشهري لتسجيل النزلاء الجدد"
}
```

---

## [API-091] List My Performance Reviews (استعراض تقييمات الأداء)

### Method: `GET`
### Endpoint: `/api/v1/performance/reviews`

---

## [API-092] Acknowledge Performance Review (إقرار مناقشة تقييم الأداء)

### Method: `POST`
### Endpoint: `/api/v1/performance/reviews/:id/acknowledge`

---

### MODULE 21: Training & Certificates

---

## [API-093] List Training Courses (استعراض الدورات التدريبية المتاحة)

### Method: `GET`
### Endpoint: `/api/v1/training/courses`

---

## [API-094] List Training Sessions (مواعيد المحاضرات والورش التدريبية)

### Method: `GET`
### Endpoint: `/api/v1/training/sessions`

---

## [API-095] List My Certificates (استعراض وتنزيل شهادات التدريب المكتسبة)

### Method: `GET`
### Endpoint: `/api/v1/training/certificates`

---

### MODULE 22: Sessions & Active Devices

---

## [API-096] Register Active Device Session (تسجيل جلسة هاتف الموظف)

### الوظيفة
الـ API دي بتسجل جهاز الموظف في الباك إند: نوع الموبايل (iPhone أو Samsung)، إصدار النظام، وإصدار تطبيق الموظفين، علشان يقدر يشوف كل الأجهزة اللي فاتح منها حسابه.

### Method
`POST`

### Endpoint
`/api/v1/sessions/register`

### Request Body (`RegisterDeviceSessionDto`)
```json
{
  "sessionToken": "session_token_from_jwt_login",
  "devicePlatform": "ANDROID",
  "deviceModel": "Samsung Galaxy S23 Ultra",
  "osVersion": "Android 14",
  "appVersion": "1.0.0"
}
```

---

## [API-097] List My Active Devices (استعراض الهواتف والجلسات النشطة)

### Method: `GET`
### Endpoint: `/api/v1/sessions/my-devices`
### Response Body:
```json
[
  {
    "id": "sess_1",
    "deviceModel": "Samsung Galaxy S23 Ultra",
    "devicePlatform": "ANDROID",
    "lastActiveAt": "2026-09-07T00:25:00.000Z",
    "isCurrent": true
  }
]
```

---

## [API-098] Terminate Device Session (تسجيل خروج عن بعد من هاتف محدد)

### Method: `DELETE`
### Endpoint: `/api/v1/sessions/:id`

---

## [API-099] Terminate All Other Sessions (تسجيل الخروج من كل الهواتف الأخرى)

### Method: `DELETE`
### Endpoint: `/api/v1/sessions/other/:currentSessionId`

---

### MODULE 23: Offline Sync Engine

---

## [API-100] Push Offline Sync Batch (المزامنة الشاملة لعمليات الموبايل غير المتصلة)

### الوظيفة
الـ API دي عصب العمل بدون اتصال بالإنترنت في تطبيق Flutter (Offline Mode)؛ لما الموظف يسجل بصمة حضور، أو ينهي مهمة، أو يقدم طلب في مكان مفيهوش تغطية شبكة، التطبيق بيحفظ العمليات دي في الـ Local SQLite Queue. أول ما النت يرجع، التطبيق بيبعت الحزمة دي كلها للسيرفر علشان تتنفذ بالترتيب مع تجنب التعارض (Idempotency).

### Method
`POST`

### Endpoint
`/api/v1/sync` (أو الـ Alias: `/api/v1/sync/batch`)

### Authentication
`Required` (Bearer Token)

### Request Body (`PushSyncBatchDto`)
```json
{
  "items": [
    {
      "clientActionId": "act-9876-uuid-v4-001",
      "entityType": "Attendance",
      "action": "CHECK_IN",
      "clientTimestamp": "2026-09-07T08:00:15.000Z",
      "payload": {
        "latitude": 30.0444,
        "longitude": 31.2357,
        "accuracy": 14.0,
        "method": "GPS",
        "biometricVerified": true
      }
    },
    {
      "clientActionId": "act-9876-uuid-v4-002",
      "entityType": "Task",
      "action": "UPDATE_STATUS",
      "entityId": "tsk_room_cleaning_101",
      "clientTimestamp": "2026-09-07T08:45:00.000Z",
      "payload": {
        "status": "COMPLETED"
      }
    }
  ],
  "syncCursor": "2026-09-07T07:00:00.000Z"
}
```

### Response Body (Status: 200 OK)
```json
{
  "processed": 2,
  "failed": 0,
  "conflicts": 0,
  "results": [
    {
      "clientActionId": "act-9876-uuid-v4-001",
      "status": "PROCESSED",
      "serverId": "att_record_uuid_12345"
    },
    {
      "clientActionId": "act-9876-uuid-v4-002",
      "status": "PROCESSED",
      "serverId": "tsk_room_cleaning_101"
    }
  ],
  "newSyncCursor": "2026-09-07T09:00:00.000Z"
}
```

---

## [API-101] Get Server Delta Changes (جلب تحديثات السيرفر الجديدة)

### الوظيفة
الـ API دي بتجيب للموبايل كل التعديلات اللي حصلت في السيرفر منذ آخر توقيت مزامنة (`cursor`) علشان يحدّث قاعدة بيانات الهاتف محلياً دون تحميل البيانات كاملة من الصفر.

### Method
`GET`

### Endpoint
`/api/v1/sync/changes`

### Query Parameters
- `cursor` (string, Optional, ISO-8601 Timestamp): توقيت آخر مزامنة ناجحة.

---

## [API-102] Get My Sync Queue Status (متابعة طابور المزامنة)

### Method: `GET`
### Endpoint: `/api/v1/sync/queue`

---

## [API-103] Retry Sync Item (إعادة محاولة مزامنة بند معلق)

### Method: `POST`
### Endpoint: `/api/v1/sync/retry/:id`

---

## [API-104] Resolve Sync Conflict (حل تعارض في المزامنة)

### Method: `POST`
### Endpoint: `/api/v1/sync/resolve-conflict/:id`
### Request Body:
```json
{
  "resolution": "CLIENT_WINS"
}
```

---

### MODULE 24: File Storage & Attachments

---

## [API-105] Upload Base64 File (رفع ملف أو صورة مرفقة)

### الوظيفة
الـ API دي بيستخدمها تطبيق Flutter لرفع أي ملف أو صورة (صورة بروفايل، صورة إثبات عطل صيانة، مرفق طلب إجازة، محضر حادث، صورة أمانة مفقودة)؛ بيبعت الملف بصيغة Base64، والسيرفر بيخزنه في مجلد التخزين الآمن ويرجع له رابط مباشر (`fileUrl`) يمكن استخدامه فوراً في أي API تانية.

### Method
`POST`

### Endpoint
`/api/v1/storage/upload`

### Authentication
`Required` (Bearer Token)

### Request Body (`UploadFileDto`)
```json
{
  "originalName": "medical_report.pdf",
  "mimeType": "application/pdf",
  "base64Content": "data:application/pdf;base64,JVBERi0xLjQKJcTl8uXr...",
  "folder": "requests"
}
```

> **المجلدات المعتمدة في `folder`:**
> `avatars`, `requests`, `tasks`, `maintenance`, `incidents`, `handover`, `lostfound`, `documents`.

### Response Body (Status: 201 Created)
```json
{
  "fileId": "file_uuid_9988_7766",
  "originalName": "medical_report.pdf",
  "storedFilename": "1725667200000-medical_report.pdf",
  "fileUrl": "http://localhost:3000/uploads/requests/1725667200000-medical_report.pdf",
  "mimeType": "application/pdf",
  "fileSize": 204850,
  "checksumSha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "uploadedAt": "2026-09-07T00:30:00.000Z"
}
```

---

## [API-106] Get File Metadata (البيانات الوصفية لملف مخزن)

### Method: `GET`
### Endpoint: `/api/v1/storage/metadata/:folder/:filename`

---

## 3. ADMIN / HR ONLY Endpoints

> [!IMPORTANT]
> **تنبيه حاسم لمطوري تطبيق الموبايل (Flutter Developers):**
> الـ Endpoints التالية تم استخراجها والتحقق منها برمجياً في الكود، لكنها **محظورة تماماً على دور الموظف (`Role.EMPLOYEE`)** وتتطلب صلاحيات إدارية عليا (`Role.SUPER_ADMIN`, `Role.HR_ADMIN`, `Role.HR_MANAGER`). تم تصنيفها وعزلها في هذا القسم لتوضيح الحدود المعمارية، ويجب **عدم محاولة ربطها أو استدعائها من تطبيق الموظفين العاديين**.

### 1. إدارة الموظفين والهيكل التنظيمي (Employees & Org Management)
- `POST /api/v1/employees`: إنشاء ملف موظف وحساب مستخدم جديد من لوحة الـ HR.
- `GET /api/v1/employees`: تصفح واستعراض قائمة الموظفين وسجلاتهم في الشركة.
- `GET /api/v1/employees/:id`: استعراض الملف الإداري الكامل لموظف محدد.
- `PATCH /api/v1/employees/:id`: تعديل بيانات الموظف، راتبه، قسمه، ومسماه الوظيفي.
- `DELETE /api/v1/employees/:id`: حذف أو إيقاف حساب موظف نهائياً.
- `POST /api/v1/organization`: إنشاء مؤسسة مركزية أو فندق جديد.
- `POST /api/v1/organization/branches`: إضافة فرع فندقي جديد.
- `POST /api/v1/organization/departments`: إنشاء أقسام وشُعب جديدة.
- `POST /api/v1/organization/positions`: إنشاء وتعديل المسميات الوظيفية.

### 2. تعديلات الحضور والانصراف اليدوية (HR Manual Attendance)
- `POST /api/v1/attendance/manual`: تسجيل أو تعديل حركة حضور وانصراف يدوياً لموظف مع ذكر السبب الإلزامي للتدقيق.
- `GET /api/v1/attendance/records`: استعراض تقارير الحضور الشاملة للفندق والبحث في سجلات جميع الموظفين.
- `GET /api/v1/attendance/employee/:employeeId`: استعراض سجلات الحضور الخاصة بموظف معين.
- `GET /api/v1/attendance/workplace/:workplaceId`: متابعة حضور موظفي فرع معين.
- `GET /api/v1/attendance/department/:department`: متابعة حضور قسم معين.

### 3. اعتمادات الطلبات وتخصيص الأرصدة (Request Approvals & Balances)
- `GET /api/v1/requests`: طابور الطلبات الواردة لجميع موظفي الفندق للبت فيها.
- `POST /api/v1/requests/:id/approve`: موافقة الـ HR أو المشرف على طلب إجازة أو إذن وتحديث الأرصدة تلقائياً.
- `POST /api/v1/requests/:id/reject`: رفض طلب الموظف مع إلزامية كتابة سبب الرفض.
- `POST /api/v1/requests/leave-balances`: تخصيص وتعيين رصيد إجازات سنوية جديد لموظف.
- `PATCH /api/v1/requests/leave-balances/:id`: تعديل يدوي في رصيد الإجازات المستهلكة أو المتاحة.

### 4. مسيرات الرواتب واحتساب الأجور (Payroll Engine & Advances Approval)
- `POST /api/v1/payroll/salary`: إعداد وتعديل الراتب الأساسي والبدلات لموظف مع حفظ تاريخ التعديلات (Versioning).
- `POST /api/v1/payroll/periods`: إنشاء دورة مسير رواتب شهرية جديدة.
- `POST /api/v1/payroll/periods/:id/calculate`: تشغيل محرك الاحتساب الآلي لرواتب الشهر وحساب الخصومات والتأمينات.
- `POST /api/v1/payroll/periods/:id/finalize`: إغلاق واعتماد مسير الرواتب نهائياً وتجميد التعديلات.
- `POST /api/v1/payroll/advances/:id/approve`: اعتماد صرف السلفة المالية وجدولة أقساطها الشهرية.
- `POST /api/v1/payroll/advances/:id/reject`: رفض طلب السلفة وتوضيح السبب.
- `POST /api/v1/payroll/advances/installments/:installmentId/pay`: إثبات سداد قسط سلفة يدوياً.
- `POST /api/v1/payroll/deductions`: توقيع جزاء مالي أو استقطاع إداري على موظف.
- `POST /api/v1/payroll/records/:id/adjust`: إجراء تسوية مالية بعد إغلاق المسير.

### 5. إدارة المهام والإسناد الإداري (Task Creation & Assignment)
- `POST /api/v1/tasks`: إنشاء مهمة عمل جديدة وتحديد أولويتها وتاريخ استحقاقها.
- `POST /api/v1/tasks/:id/assign`: إسناد أو إعادة إسناد المهمة لموظف محدد أو قسم.
- `DELETE /api/v1/tasks/:id`: إلغاء أو حذف مهمة نهائياً من النظام.

### 6. نشر الإعلانات وتعميمات الإدارة (Announcements Publishing)
- `POST /api/v1/announcements`: صياغة إعلان أو تعميم إداري جديد وتحديد الأقسام المستهدفة.
- `POST /api/v1/announcements/:id/publish`: نشر الإعلان وبدء إرسال الـ Push Notifications للموظفين فورياً.
- `POST /api/v1/announcements/:id/cancel`: إلغاء نشر الإعلان أو حذفه.

### 7. إعدادات النظام ومحرك سير العمل (System, Workflows & RBAC)
- `GET / POST / PUT / DELETE /api/v1/settings`: إدارة الإعدادات المركزية والمتقدمة للنظام.
- `GET / POST / PUT /api/v1/settings/flags`: إدارة ميزات النظام (Feature Flags) وتفعيلها تدريجياً.
- `GET / POST / PUT /api/v1/workflows`: تعريف وتعديل قوالب مسارات الموافقات المتعددة (Workflow Templates).
- `GET / POST /api/v1/roles`: تعريف وتعديل الأدوار الوظيفية في النظام.
- `GET /api/v1/permissions`: مصفوفة الصلاحيات التفصيلية للأزرار والشاشات.
- `GET /api/v1/audit-logs`: سجل الرقابة والتدقيق الأمني لجميع حركات النظام.
- `GET /api/v1/dashboard`: لوحة مؤشرات الأداء التنفيذية (BI & Executive KPI Dashboard).
- `POST /api/v1/backup`: إدارة وإنشاء النسخ الاحتياطية لقاعدة البيانات والملفات.
- `GET / POST /api/v1/recruitment`: نظام استقطاب وتعيين الموظفين الجدد (ATS & Interviews).
- `GET / POST /api/v1/onboarding`: مسارات تهيئة وتسكين الموظفين الجدد.
- `GET / POST /api/v1/assets`: سجل الأصول والمعدات الفندقية وحساب إهلاكها.
- `GET / POST /api/v1/inventory`: حركة المخازن والأصناف والتسويات الجردية.
- `GET / POST /api/v1/procurement`: أوامر الشراء والتعامل مع الموردين ومناقصات الفندق.
- `GET / POST /api/v1/finance`: الحسابات العامة، قيود اليومية، والتقارير المالية.
- `GET / POST /api/v1/budget`: الموازنات التقديرية ومراقبة انحرافات الإنفاق.

---

## 4. إرشادات التكامل التقني لتطبيق Flutter (Integration Best Practices)

1. **إدارة الـ Tokens وتجديدها (Token Refresh Interceptor):**
   - قم بحفظ `accessToken` في التخزين الآمن للجهاز (`flutter_secure_storage`).
   - عند استقبال رمز الاستجابة `401 Unauthorized`، قم بتجميد الطلبات الأخرى، ونفّذ طلب `POST /api/v1/auth/refresh` لتجديد التوكن.
   - في حال فشل التجديد (مثلاً انتهاء صلاحية الـ 7 أيام للـ Refresh Token)، وجّه الموظف لشاشة تسجيل الدخول وأفرغ الذاكرة الآمنة.

2. **تسجيل الحضور بالـ GPS والنطاق الجغرافي (Geofencing Engine):**
   - استدعِ `GET /api/v1/employees/me/workplace` أولاً للحصول على إحداثيات الفرع ونصف القطر بالمتر.
   - تحقق من أن دقة الـ GPS (`accuracy`) أقل من أو تساوي 50 متراً قبل إرسال الطلب، فالقراءات غير الدقيقة يتم رفضها من قِبل الباك إند.
   - لا تحاول تزييف الموقع الجغرافي، حيث يقوم الباك إند بفحص إشارات `isMockLocation` و`isVpn` و`isJailbroken` وتسجيلها في تقارير الأمان.

3. **العمل دون اتصال والمزامنة (Offline Queue & Delta Sync):**
   - خزّن حركات الحضور وتحديثات المهام في قاعدة بيانات SQLite محلية عند انقطاع الإنترنت.
   - عند عودة الاتصال، ارفع العمليات دفعة واحدة عبر `POST /api/v1/sync` مع تمرير `clientActionId` عشوائي وفريد لكل حركة لمنع تكرار القيد.
   - قم بجلب تحديثات السيرفر عبر `GET /api/v1/sync/changes?cursor={{lastSyncTime}}`.

4. **رفع الصور والمستندات (Base64 File Upload):**
   - حوّل الصورة أو الملف إلى نص Base64 ثم أرسله عبر `POST /api/v1/storage/upload`.
   - التقط الرابط الراجع في حقل `fileUrl` ومرره في حقول `attachmentUrl` أو `evidenceUrls` أو `avatarUrl` في الطلبات المختلفة.
