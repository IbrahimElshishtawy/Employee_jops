import 'package:flutter/material.dart';

/// AppLocalizations handles bilingual support (Arabic RTL default, English LTR ready).
/// It provides structured key lookups with full type-safety and fallback support.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('ar'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [Locale('ar'), Locale('en')];

  bool get isArabic => locale.languageCode == 'ar';

  late Map<String, String> _localizedStrings;

  Future<bool> load() async {
    _localizedStrings =
        _translations[locale.languageCode] ?? _translations['ar']!;
    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? _translations['ar']?[key] ?? key;
  }

  // Common Key Accessors
  String get appTitle => translate('app.title');
  String get welcome => translate('home.welcome');
  String get morningGreeting => translate('home.greeting_morning');
  String get eveningGreeting => translate('home.greeting_evening');

  // Navigation
  String get navHome => translate('nav.home');
  String get navRequests => translate('nav.requests');
  String get navCommunication => translate('nav.communication');
  String get navNotifications => translate('nav.notifications');
  String get navProfile => translate('nav.profile');

  // Communication
  String get communicationTitle => translate('communication.title');
  String get communicationDepartments => translate('communication.departments');
  String get communicationMyConversations => translate('communication.my_conversations');
  String get communicationMyRequests => translate('communication.my_requests');
  String get communicationStartChat => translate('communication.start_chat');
  String get communicationCreateRequest => translate('communication.create_request');
  String get communicationActiveRequests => translate('communication.active_requests');

  // Attendance
  String get attendanceTitle => translate('attendance.title');
  String get checkIn => translate('attendance.check_in');
  String get checkOut => translate('attendance.check_out');
  String get checkedIn => translate('attendance.checked_in');
  String get checkedOut => translate('attendance.checked_out');
  String get notCheckedIn => translate('attendance.not_checked_in');
  String get insideRange => translate('attendance.inside_range');
  String get outsideRange => translate('attendance.outside_range');
  String get distanceToOffice => translate('attendance.distance_to_office');
  String get checkInTime => translate('attendance.check_in_time');
  String get checkOutTime => translate('attendance.check_out_time');
  String get pendingHrVerification =>
      translate('attendance.pending_hr_verification');
  String get offlineModeNotice => translate('attendance.offline_notice');
  String get attendanceCompleted => translate('attendance.completed_btn');
  String get verifyIdentity => translate('attendance.verify_identity');
  String get biometricDesc => translate('attendance.biometric_desc');
  String get updateLocation => translate('attendance.update_location');
  String get allowLocationPermission => translate('attendance.allow_location_permission');
  String get openSettings => translate('attendance.open_location_settings');
  String get syncNow => translate('attendance.sync_now');
  String get timelineTitle => translate('attendance.timeline_title');
  String get currentlyWorking => translate('attendance.status_currently_working');
  String get workdayCompleted => translate('attendance.status_workday_completed');

  // Requests
  String get requestsTitle => translate('requests.title');
  String get advancesTitle => translate('requests.advances');
  String get permissionsTitle => translate('requests.permissions');
  String get vacationsTitle => translate('requests.vacations');
  String get newRequest => translate('requests.new');
  String get requestHistory => translate('requests.history');

  // Onboarding
  String get onboardingStep1Title => translate('onboarding.step1_title');
  String get onboardingStep1Subtitle => translate('onboarding.step1_subtitle');
  String get onboardingStep2Title => translate('onboarding.step2_title');
  String get onboardingStep2Subtitle => translate('onboarding.step2_subtitle');
  String get onboardingStep3Title => translate('onboarding.step3_title');
  String get onboardingStep3Subtitle => translate('onboarding.step3_subtitle');
  String get onboardingFullName => translate('onboarding.full_name');
  String get onboardingEmail => translate('onboarding.email');
  String get onboardingNationalId => translate('onboarding.national_id');
  String get onboardingPhone => translate('onboarding.phone');
  String get onboardingJobTitle => translate('onboarding.job_title');
  String get onboardingDepartment => translate('onboarding.department');
  String get onboardingRegion => translate('onboarding.region');
  String get onboardingManager => translate('onboarding.manager');
  String get onboardingWorkLocation => translate('onboarding.work_location');
  String get onboardingHrContact => translate('onboarding.hr_contact');
  String get onboardingNext => translate('onboarding.next');
  String get onboardingComplete => translate('onboarding.complete');
  String get onboardingBack => translate('onboarding.back');
  String get onboardingVerifiedByGoogle =>
      translate('onboarding.verified_by_google');
  String get onboardingVerified => translate('onboarding.verified');
  String get onboardingBiometricTitle =>
      translate('onboarding.biometric_title');
  String get onboardingBiometricSubtitle =>
      translate('onboarding.biometric_subtitle');
  String get onboardingEnableBiometric =>
      translate('onboarding.enable_biometric');
  String get onboardingSkipBiometric => translate('onboarding.skip_biometric');
  String get onboardingHrCall => translate('onboarding.hr_call');
  String get onboardingHrContactEmail =>
      translate('onboarding.hr_contact_email');
  String get onboardingHrContacting => translate('onboarding.hr_contacting');
  String get onboardingLocationAccessTitle =>
      translate('onboarding.location_access_title');
  String get onboardingLocationAccessDesc =>
      translate('onboarding.location_access_desc');
  String get onboardingLocationPermissionEnabled =>
      translate('onboarding.location_permission_enabled');
  String get onboardingLocationPermissionRequired =>
      translate('onboarding.location_permission_required');
  String get onboardingAllowLocation =>
      translate('onboarding.allow_location');
  String get onboardingWorkplaceAssigned =>
      translate('onboarding.workplace_assigned');
  String get onboardingHrSupportTitle =>
      translate('onboarding.hr_support_title');
  String get onboardingRequiredFieldsError =>
      translate('onboarding.required_fields_error');

  // General & Buttons
  String get save => translate('common.save');
  String get cancel => translate('common.cancel');
  String get retry => translate('common.retry');
  String get submit => translate('common.submit');
  String get success => translate('common.success');
  String get error => translate('common.error');
  String get settings => translate('common.settings');
  String get logout => translate('auth.logout');

  static final Map<String, Map<String, String>> _translations = {
    'ar': {
      // App
      'app.title': 'CyberWise IE',

      // Navigation
      'nav.home': 'الرئيسية',
      'nav.requests': 'الطلبات',
      'nav.communication': 'التواصل',
      'nav.notifications': 'التنبيهات',
      'nav.profile': 'حسابي',

      // Communication
      'communication.title': 'التواصل والعمليات',
      'communication.departments': 'أقسام الفندق',
      'communication.my_conversations': 'محادثاتي الأخيرة',
      'communication.my_requests': 'طلباتي التشغيلية',
      'communication.start_chat': 'بدء محادثة',
      'communication.create_request': 'إنشاء طلب',
      'communication.active_requests': 'الطلبات النشطة',
      'communication.select_department': 'اختر القسم',
      'communication.department_employees': 'موظفو القسم',
      'communication.request_details': 'تفاصيل الطلب',
      'communication.new_request': 'طلب تشغيلي جديد',
      'communication.priority': 'مستوى الأولوية',
      'communication.priority_low': 'منخفض',
      'communication.priority_normal': 'عادي',
      'communication.priority_high': 'عالي',
      'communication.status_pending': 'قيد الانتظار',
      'communication.status_accepted': 'تم القبول',
      'communication.status_in_progress': 'جاري التنفيذ',
      'communication.status_completed': 'مكتمل',
      'communication.status_rejected': 'مرفوض',
      'communication.status_cancelled': 'ملغي',
      'communication.action_accept': 'قبول الطلب',
      'communication.action_reject': 'رفض الطلب',
      'communication.action_start': 'بدء التنفيذ',
      'communication.action_complete': 'إتمام وإغلاق الطلب',

      // Auth
      'auth.welcome_title': 'مرحبًا بك في CyberWise IE',
      'auth.welcome_back': 'مرحبًا بك مجددًا',
      'auth.welcome_subtitle':
          'بوابتك الرقمية لإدارة الحضور والطلبات وخدمات الموظفين بكل سهولة وأمان.',
      'auth.sign_in_subtitle':
          'سجّل الدخول للوصول إلى حسابك الوظيفي وإدارة مهامك.',
      'auth.sign_in_google': 'تسجيل الدخول باستخدام Google',
      'auth.continue_google': 'المتابعة باستخدام Google',
      'auth.signing_in': 'جاري تسجيل الدخول...',
      'auth.secure_access': 'دخول آمن ومشفّر للموظفين',
      'auth.error_generic': 'تعذر تسجيل الدخول، يرجى المحاولة مرة أخرى.',
      'auth.logout': 'تسجيل الخروج',
      'auth.logout_confirm': 'هل أنت متأكد من رغبتك في تسجيل الخروج؟',

      // Home
      'home.greeting_morning': 'صباح الخير',
      'home.greeting_evening': 'مساء الخير',
      'home.welcome': 'أهلاً بك',
      'home.today_status': 'حالة اليوم',
      'home.quick_actions': 'الوصول السريع',
      'home.recent_activity': 'النشاط الأخير',
      'home.view_all': 'عرض الكل',

      // Attendance
      'attendance.title': 'الحضور والانصراف',
      'attendance.status': 'حالة الحضور',
      'attendance.status_not_checked_in': 'لم يتم تسجيل الحضور اليوم',
      'attendance.status_currently_working': 'على رأس العمل',
      'attendance.status_workday_completed': 'تم إكمال يوم العمل بنجاح',
      'attendance.status_offline_pending': 'محفوظ محليًا (في انتظار المزامنة)',
      'attendance.check_in': 'تسجيل الحضور',
      'attendance.check_out': 'تسجيل الانصراف',
      'attendance.checked_in': 'تم تسجيل الحضور',
      'attendance.checked_out': 'تم تسجيل الانصراف',
      'attendance.not_checked_in': 'لم يتم تسجيل الحضور اليوم',
      'attendance.completed_btn': 'تم إكمال الحضور والانصراف',
      'attendance.inside_range': 'داخل نطاق الشركة',
      'attendance.outside_range': 'أنت خارج نطاق تسجيل الحضور',
      'attendance.outside_range_desc':
          'يجب أن تكون داخل نطاق الشركة بمسافة لا تتجاوز 4 أمتار لتسجيل الحضور.',
      'attendance.inside_allowed_zone': 'أنت داخل نطاق تسجيل الحضور المصرح به (أقل من 4 أمتار)',
      'attendance.outside_allowed_zone': 'أنت خارج نطاق تسجيل الحضور المصرح به (الحد الأقصى 4 أمتار)',
      'attendance.distance_to_office': 'أنت على بعد {dist} من موقع العمل',
      'attendance.distance_label': 'المسافة',
      'attendance.allowed_radius_label': 'النطاق المسموح',
      'attendance.workplace_zone': 'مقر العمل المعتمد',
      'attendance.update_location': 'تحديث الموقع الجغرافي',
      'attendance.updating_location': 'جاري تحديث الموقع...',
      'attendance.allow_location_permission': 'السماح بالوصول للموقع',
      'attendance.open_location_settings': 'فتح الإعدادات',
      'attendance.verify_identity': 'أكّد هويتك للمتابعة',
      'attendance.action_completed': 'تم إكمال حضور اليوم',
      'attendance.check_in_time': 'وقت الدخول',
      'attendance.check_out_time': 'وقت الانصراف',
      'attendance.pending_hr_verification': 'في انتظار مراجعة الـ HR',
      'attendance.offline_notice': 'تم الحفظ محليًا - سيتم المزامنة عند توفر الاتصال',
      'attendance.offline_alert': 'تم تسجيل الحضور محليًا لعدم توفر اتصال بالإنترنت.',
      'attendance.accuracy_label': 'دقة الـ GPS',
      'attendance.work_schedule_title': 'جدول الدوام ومواعيد العمل',
      'attendance.grace_period_label': 'فترة السماح',
      'attendance.shift_hours_label': 'ساعات الدوام',
      'attendance.header_subtitle': 'تسجيل الحضور والانصراف الذكي',
      'attendance.permission_required_title': 'إذن الموقع الجغرافي مطلوب',
      'attendance.permission_required_desc': 'يلزم تفعيل إذن الموقع للتحقق من وجودك في مقر العمل.',
      'attendance.gps_disabled_alert': 'خدمة تحديد المواقع (GPS) معطلة. يرجى تفعيلها للمتابعة.',
      'attendance.mock_location_alert': 'تم رصد استخدام موقع وهمي (Mock Location). تم رفض العملية لأسباب أمنية.',
      'attendance.low_accuracy_title': 'دقة الموقع غير كافية',
      'attendance.low_accuracy_desc': 'إشارة الـ GPS ضعيفة حالياً. يرجى الانتقال إلى مكان مكشوف وإعادة المحاولة.',
      'attendance.biometric_desc': 'يتم توثيق هويتك بأمان عبر نظام حماية الهاتف (بصمة الإصبع أو Face ID) دون تخزين أي بيانات بيومترية.',
      'attendance.biometric_ready': 'جاهز للمصادقة',
      'attendance.biometric_verifying': 'جاري التحقق...',
      'attendance.biometric_failed': 'فشلت المصادقة',
      'attendance.biometric_unavailable': 'غير متوفر',
      'attendance.offline_badge': 'وضع بدون اتصال',
      'attendance.history': 'سجل الحضور الأخير',
      'attendance.timeline_title': 'الجدول الزمني لليوم',
      'attendance.timeline_checkin': 'تسجيل الحضور',
      'attendance.timeline_checkout': 'تسجيل الانصراف',
      'attendance.timeline_working': 'جلسة العمل الحالية',
      'attendance.device_integrity_title': 'أمان الجهاز والتطبيق',
      'attendance.device_integrity_ok': 'الجهاز موثوق ومحمي',
      'attendance.device_integrity_failed': 'تعذر التحقق من أمان الجهاز.',
      'attendance.vpn_detected_notice': 'تم رصد شبكة VPN نشطة (إشارة أمنية)',
      'attendance.vpn_not_detected': 'الاتصال مباشر',
      'attendance.server_verification': 'التوثيق المركزي',
      'attendance.server_verified_note': 'الخادم هو المرجع النهائي لاعتماد الحضور والانصراف',
      'attendance.mock_location_detected_msg': 'لا يمكن تسجيل الحضور باستخدام موقع غير موثوق.',
      'attendance.location_service_disabled_msg': 'يرجى تفعيل خدمة الموقع',
      'attendance.location_service_required_msg': 'يجب تفعيل الموقع لتسجيل الحضور.',
      'attendance.overlay_detected_alert':
          'يوجد تطبيق آخر قد يظهر فوق التطبيق.\nيرجى إغلاقه ثم المحاولة مرة أخرى.',
      'attendance.location_permission_denied_msg': 'يرجى السماح للتطبيق باستخدام موقعك',
      'attendance.location_low_accuracy_msg': 'دقة الموقع غير كافية',
      'attendance.outside_workplace_msg': 'أنت خارج نطاق موقع العمل',
      'attendance.location_unavailable_msg': 'تعذر تحديد موقعك، حاول مرة أخرى',
      'common.test_mode': 'وضع تجريبي',
      'common.device_test_data': 'بيانات اختبار الجهاز (DEVICE_TEST_DATA)',

      // Requests Hub
      'requests.title': 'مركز الطلبات',
      'requests.advances': 'السُلف والتقارير',
      'requests.permissions': 'الاستئذان',
      'requests.vacations': 'الإجازات',
      'requests.new': 'طلب جديد',
      'requests.history': 'طلبات سابقة',
      'requests.all': 'الكل',
      'requests.empty': 'لا توجد طلبات حتى الآن',
      'requests.filter': 'تصفية حسب الحالة',

      // Advances
      'advances.title': 'السُلف المالية',
      'advances.new': 'طلب سُلفة جديدة',
      'advances.amount': 'المبلغ المطلوب',
      'advances.reason': 'سبب السلفة',
      'advances.details': 'تفاصيل إضافية',
      'advances.installments': 'عدد أقساط السداد',
      'advances.expense_report': 'تقرير المصروفات',
      'advances.submit_report': 'تقديم تقرير المصروفات',
      'advances.attachment': 'المرفقات / الفواتير',
      'advances.report_required': 'مطلوب تقديم تقرير',
      'advances.report_submitted': 'تم تقديم التقرير',

      // Permissions
      'permissions.title': 'أذونات الاستئذان',
      'permissions.new': 'طلب إذن جديد',
      'permissions.type': 'نوع الاستئذان',
      'permissions.type_delay': 'تأخير صباحي',
      'permissions.type_early_leave': 'انصراف مبكر',
      'permissions.type_absence': 'غياب يوم',
      'permissions.type_half_day': 'نصف يوم عمل',
      'permissions.date': 'تاريخ الإذن',
      'permissions.time': 'الوقت / المدة',
      'permissions.reason': 'السبب',

      // Vacations
      'vacations.title': 'الإجازات',
      'vacations.new': 'طلب إجازة جديدة',
      'vacations.type': 'نوع الإجازة',
      'vacations.type_annual': 'إجازة سنوية',
      'vacations.type_sick': 'إجازة مرضية',
      'vacations.type_casual': 'إجازة عارضة',
      'vacations.type_unpaid': 'إجازة بدون راتب',
      'vacations.from_date': 'من تاريخ',
      'vacations.to_date': 'إلى تاريخ',
      'vacations.days_count': 'عدد الأيام',
      'vacations.reason': 'سبب الإجازة',
      'vacations.attachment': 'مرفق (تقرير طبي إن وجد)',

      // Statuses
      'status.pending': 'قيد المراجعة',
      'status.approved': 'تمت الموافقة',
      'status.rejected': 'مرفوض',
      'status.paid': 'تم الصرف',
      'status.cancelled': 'ملغي',
      'status.completed': 'مكتمل',

      // Notifications
      'notifications.title': 'التنبيهات',
      'notifications.empty': 'لا توجد تنبيهات جديدة',
      'notifications.mark_all_read': 'تعيين الكل كمقروء',
      'notifications.category_advances': 'تنبيهات السُلف',
      'notifications.category_permissions': 'تنبيهات الاستئذان',
      'notifications.category_vacations': 'تنبيهات الإجازات',
      'notifications.category_attendance': 'تنبيهات الحضور',
      'notifications.category_system': 'تنبيهات النظام',

      // Profile
      'profile.title': 'الملف الشخصي',
      'profile.employee_id': 'الرقم الوظيفي',
      'profile.department': 'القسم',
      'profile.job_title': 'المسمى الوظيفي',
      'profile.email': 'البريد الإلكتروني',
      'profile.settings': 'الإعدادات',
      'profile.help': 'المساعدة والدعم',
      'profile.privacy': 'سياسة الخصوصية',
      'profile.about': 'عن التطبيق',

      // Settings
      'settings.title': 'الإعدادات',
      'settings.account': 'الحساب',
      'settings.appearance': 'المظهر والسمات',
      'settings.theme': 'وضع السمة',
      'settings.theme_system': 'تلقائي (حسب النظام)',
      'settings.theme_light': 'الوضع الفاتح (Light)',
      'settings.theme_dark': 'الوضع الداكن (Dark)',
      'settings.language': 'اللغة (Language)',
      'settings.language_ar': 'العربية (Arabic)',
      'settings.language_en': 'الإنجليزية (English)',
      'settings.developer_demo': 'أدوات المطور والمحاكاة (Demo Controls)',
      'settings.demo_desc':
          'تحكم في الموقع الجغرافي، البصمة، والاتصال لتجربة جميع السيناريوهات.',

      // Demo Controls
      'demo.title': 'لوحة المحاكاة والتجربة',
      'demo.location_heading': 'محاكاة الموقع الجغرافي (GPS Location)',
      'demo.location_inside': 'داخل النطاق (أقل من 4 أمتار)',
      'demo.location_outside': 'خارج النطاق (أكثر من 4 أمتار)',
      'demo.location_denied': 'تم رفض إذن الوصول للموقع',
      'demo.biometric_heading': 'محاكاة المصادقة البيومترية (Biometrics)',
      'demo.biometric_success': 'بصمة ناجحة',
      'demo.biometric_failed': 'فشل مطابقة البصمة',
      'demo.biometric_cancelled': 'إلغاء من قبل المستخدم',
      'demo.network_heading': 'حالة الاتصال (Network Connection)',
      'demo.network_online': 'متصل بالإنترنت (Online)',
      'demo.network_offline': 'غير متصل (Offline - وضع الحفظ المؤقت)',
      'demo.reset_data': 'إعادة ضبط البيانات الافتراضية',
      'demo.data_reset_success': 'تمت استعادة البيانات الافتراضية بنجاح',

      // Onboarding Phase 01
      'onboarding.step1_title': 'البيانات الأساسية',
      'onboarding.step1_subtitle': 'تأكد من اسمك ورقم هاتفك للمتابعة.',
      'onboarding.step2_title': 'المسمى الوظيفي والقسم',
      'onboarding.step2_subtitle': 'اختر مسماك الوظيفي والقسم التابع له.',
      'onboarding.step3_title': 'مراجعة وتأكيد البيانات',
      'onboarding.step3_subtitle': 'يرجى مراجعة كافة بياناتك قبل إتمام إنشاء الحساب.',
      'onboarding.review_your_info': 'مراجعة معلوماتك',
      'onboarding.full_name': 'الاسم الكامل',
      'onboarding.email': 'البريد الإلكتروني',
      'onboarding.national_id': 'رقم البطاقة / الهوية',
      'onboarding.phone': 'رقم الهاتف',
      'onboarding.job_title': 'المسمى الوظيفي',
      'onboarding.department': 'القسم / الإدارة',
      'onboarding.region': 'الفرع / المنطقة',
      'onboarding.manager': 'المدير المباشر',
      'onboarding.work_location': 'مقر العمل المعتمد',
      'onboarding.hr_contact': 'مسؤول الموارد البشرية (HR)',
      'onboarding.next': 'التالي',
      'onboarding.continue_action': 'متابعة',
      'onboarding.confirm_continue': 'تأكيد ومتابعة',
      'onboarding.edit_action': 'تعديل',
      'onboarding.complete': 'إكمال الإعداد',
      'onboarding.complete_setup': 'إكمال الإعداد والبدء',
      'onboarding.back': 'رجوع',
      'onboarding.verified_by_google': 'تم التحقق عبر Google',
      'onboarding.verified': 'موثق',
      'onboarding.email_readonly_note': 'البريد الإلكتروني مرتبط بحساب Google ولا يمكن تعديله',
      'onboarding.name_required': 'الاسم الكامل مطلوب',
      'onboarding.phone_required': 'رقم الهاتف مطلوب',
      'onboarding.phone_invalid': 'يرجى إدخال رقم هاتف صحيح (10 إلى 15 رقم)',
      'onboarding.job_required': 'من فضلك اختر المسمى الوظيفي',
      'onboarding.department_required': 'من فضلك اختر القسم',
      'onboarding.profile_completed_success': 'تم إكمال الملف الشخصي بنجاح',
      'onboarding.biometric_title': 'تفعيل المصادقة البيومترية',
      'onboarding.biometric_subtitle': 'أمّن تسجيل حضورك ببصمة الإصبع أو الوجه',
      'onboarding.enable_biometric': 'تفعيل البصمة',
      'onboarding.skip_biometric': 'تخطي الآن',
      'onboarding.hr_call': 'اتصال بـ HR',
      'onboarding.hr_contact_email': 'مراسلة HR',
      'onboarding.hr_contacting': 'جاري التواصل مع HR...',
      'onboarding.location_access_title': 'إذن الوصول للموقع الجغرافي',
      'onboarding.location_access_desc':
          'يلزم إذن الموقع للتحقق من الحضور بمقر عملك المعتمد (نطاق 4 أمتار).',
      'onboarding.location_permission_enabled': 'تم تفعيل إذن الموقع بنجاح',
      'onboarding.location_permission_required': 'إذن الموقع مطلوب للمتابعة',
      'onboarding.allow_location': 'السماح بالموقع',
      'onboarding.workplace_assigned': 'مقر العمل المعتمد',
      'onboarding.hr_support_title': 'دعم الموارد البشرية (HR)',
      'onboarding.select_job_title': 'اختر المسمى الوظيفي',
      'onboarding.select_department': 'اختر القسم',
      'onboarding.select_region': 'اختر المنطقة',
      'onboarding.select_manager': 'اختر المدير المباشر',
      'onboarding.search_placeholder': 'بحث...',
      'onboarding.required_fields_error':
          'يرجى ملء جميع الحقول المطلوبة للمتابعة.',

      // Common
      'common.save': 'حفظ',
      'common.cancel': 'إلغاء',
      'common.retry': 'إعادة المحاولة',
      'common.submit': 'إرسال الطلب',
      'common.success': 'تم بنجاح',
      'common.error': 'حدث خطأ',
      'common.settings': 'الإعدادات',
      'common.confirm': 'تأكيد',
      'common.back': 'رجوع',
      'common.egp': 'جنيه',
      'common.days': 'أيام',
      'common.day': 'يوم',
      'common.hours': 'ساعات',
      'common.meters': 'أمتار',
      'common.meter': 'متر',
      'common.loading': 'جاري التحميل...',
      'common.no_data': 'لا توجد بيانات متاحة',

      // Location Tracking & Work Session
      'tracking.title': 'تتبع موقع العمل',
      'tracking.active_foreground': 'نشط (في الواجهة)',
      'tracking.active_background': 'نشط (في الخلفية)',
      'tracking.stopped': 'متوقف',
      'tracking.starting': 'جاري البدء...',
      'tracking.paused': 'متوقف مؤقتاً',
      'tracking.error': 'تنبيه في التتبع',
      'tracking.reason_checkout': 'انتهت جلسة العمل اليومية',
      'tracking.reason_logout': 'تم تسجيل الخروج',
      'tracking.permission_required': 'يلزم منح إذن الموقع',
      'tracking.background_permission_desc': 'يسمح بتتبع الموقع أثناء الدوام عند تصغير التطبيق',
      'tracking.gps_disabled_desc': 'يرجى تفعيل خدمة الموقع (GPS) من إعدادات الجهاز',
      'tracking.offline_queued': 'سجلات معلقة للمزامنة',
      'tracking.sync_success': 'تمت مزامنة السجلات بنجاح',
      'tracking.syncing': 'جاري المزامنة مع الخادم...',
      'tracking.last_update': 'آخر تحديث للموقع:',

      // Device Session & Info
      'session.device_session': 'جلسة الجهاز المعتمدة',
      'session.active': 'نشطة',
      'session.inactive': 'غير نشطة',
      'session.push_token': 'رمز الإشعارات (FCM)',
      'session.work_session': 'جلسة الدوام الحالية',

      // About Application
      'about.title': 'عن التطبيق',
      'about.subtitle': 'منصة إدارة الموظفين والموارد البشرية',
      'about.version': 'الإصدار',
      'about.build': 'رقم البناء',
      'about.section_app': 'عن التطبيق',
      'about.app_description':
          'تطبيق الموظف هو منصة داخلية متكاملة تساعد الموظفين على تسجيل الحضور والانصراف، وتقديم ومتابعة الطلبات، وتلقي الإشعارات، والتواصل مع قسم الموارد البشرية بكل سهولة وأمان.',
      'about.section_features': 'الميزات الرئيسية',
      'about.feature_attendance': 'تسجيل الحضور والانصراف',
      'about.feature_attendance_desc':
          'تسجيل الحضور والانصراف الجغرافي والبيومتري مع متابعة السجل وساعات العمل.',
      'about.feature_requests': 'طلبات الموظفين',
      'about.feature_requests_desc':
          'تقديم ومتابعة طلبات الإجازات، الاستئذان، والسُلف المالية بكل يسر.',
      'about.feature_communication': 'التواصل مع الموارد البشرية',
      'about.feature_communication_desc':
          'التواصل المباشر مع ممثلي HR والإدارات وتقديم الاستفسارات ومتابعتها.',
      'about.feature_notifications': 'التنبيهات والإشعارات',
      'about.feature_notifications_desc':
          'تلقي التنبيهات الفورية بحالة الطلبات والتعاميم وتذكيرات الدوام.',
      'about.feature_profile': 'الملف الشخصي والبيانات',
      'about.feature_profile_desc':
          'عرض وإدارة البيانات الوظيفية والشخصية وإعدادات الأمان للجهاز.',
      'about.section_support': 'الدعم والمساعدة',
      'about.help_center': 'مركز المساعدة',
      'about.help_center_desc': 'الأسئلة الشائعة ودليل استخدام المنظومة',
      'about.contact_support': 'التواصل مع الدعم الفني',
      'about.contact_support_desc': 'التواصل مع مسؤولي النظام وقسم الدعم',
      'about.report_problem': 'الإبلاغ عن مشكلة',
      'about.report_problem_desc': 'إرسال ملاحظة تقنية أو بلاغ عن خلل فني',
      'about.section_legal': 'الشؤون القانونية والسياسات',
      'about.privacy_policy': 'سياسة الخصوصية',
      'about.privacy_policy_desc': 'معايير حماية البيانات والخصوصية المعتمدة',
      'about.terms_of_use': 'شروط الاستخدام',
      'about.terms_of_use_desc': 'سياسات وقواعد استخدام النظام الداخلي',
      'about.open_source_licenses': 'تراخيص المصادر المفتوحة',
      'about.open_source_licenses_desc': 'حزم ومكتبات البرمجيات مفتوحة المصدر',
      'about.section_company': 'الشركة',
      'about.company_name': 'اسم الشركة',
      'about.company_website': 'الموقع الإلكتروني',
      'about.company_email': 'البريد المؤسسي',
      'about.all_rights_reserved': 'جميع الحقوق محفوظة.',
      'about.privacy_dialog_title': 'سياسة الخصوصية وأمان البيانات',
      'about.privacy_dialog_content':
      // Privacy Policy
      'privacy.title': 'سياسة الخصوصية',
      'privacy.subtitle': 'تعرف على كيفية جمع واستخدام وحماية وإدارة بياناتك داخل المنظومة.',
      'privacy.last_updated': 'آخر تحديث: 31 أغسطس 2026',
      'privacy.sec_intro_title': '1. المقدمة ونطاق التطبيق',
      'privacy.sec_intro_body':
          'يُعد تطبيق الموظف منصة عمل داخلية متكاملة مخصصة لموظفي المؤسسة المعتمدين، بهدف تسهيل وإدارة الخدمات الذاتية اليومية مثل تسجيل الحضور والانصراف، تقديم الطلبات الإدارية والمالية، استقبال التنبيهات الرسمية، والتواصل المباشر مع إدارة الموارد البشرية.',
      'privacy.sec_collected_title': '2. البيانات التي نقوم بمعالجتها',
      'privacy.sec_collected_account':
          'بيانات الحساب الوظيفي: تشمل الاسم، الرقم الوظيفي، رقم الهاتف، البريد الإلكتروني المعتمد، المسمى الوظيفي، والقسم التابع له.',
      'privacy.sec_collected_attendance':
          'بيانات الحضور والانصراف: تشمل توقيتات تسجيل الحضور والانصراف الدقيقة، سجل الساعات اليومي، وحالة التحقق من التواجد بمقر العمل المعتمد.',
      'privacy.sec_collected_device':
          'البيانات الفنية للجهاز: تشمل نوع ونظام تشغيل الجهاز، إصدار التطبيق، ورمز الجلسة الموثقة لضمان أمان الحساب ومنع الاختراق.',
      'privacy.sec_location_title': '3. معالجة بيانات الموقع الجغرافي (GPS)',
      'privacy.sec_location_body':
          'يتم طلب إذن الموقع الجغرافي حصرياً عند قيام الموظف بتسجيل الحضور أو الانصراف للتحقق من تواجده الفعلي ضمن النطاق الجغرافي المعتمد لمقر العمل. لا يقوم التطبيق بتتبع الموظف خارج أوقات العمل أو لأي أغراض أخرى غير معتمدة.',
      'privacy.sec_usage_title': '4. أغراض استخدام البيانات',
      'privacy.sec_usage_body':
          'تُستخدم البيانات للتحقق من هوية الموظف، اعتماد سجلات الدوام الرسمية، معالجة طلبات الإجازات والاستئذان والسُلف، إرسال التنبيهات الإدارية الهامة، وتأمين النظام من أي محاولات وصول غير مصرح بها.',
      'privacy.sec_security_title': '5. أمن وحماية البيانات',
      'privacy.sec_security_body':
          'تخضع جميع البيانات لمعايير أمنية صارمة تشمل التشفير، المصادقة الثنائية والبيومترية، وإدارة الصلاحيات المقيدة، مع حفظ السجلات الحساسة محلياً بشكل مشفر لمنع أي وصول غير مرخص.',
      'privacy.sec_sharing_title': '6. سرية ومشاركة البيانات',
      'privacy.sec_sharing_body':
          'بيانات الموظف سرية للغاية وتُستخدم حصرياً داخل الأنظمة المعتمدة للمؤسسة، ولا يتم بيعها أو مشاركتها أو الإفصاح عنها لأي جهات تجارية أو خارجية.',
      'privacy.sec_retention_title': '7. مدة الاحتفاظ بالبيانات',
      'privacy.sec_retention_body':
          'يتم الاحتفاظ بالبيانات وسجلات الدوام طوال فترة العمل بالمؤسسة ووفقاً لمتطلبات اللوائح الإدارية والسياسات التنظيمية لحفظ السجلات الرسمية.',
      'privacy.sec_rights_title': '8. حقوق الموظف والتواصل',
      'privacy.sec_rights_body':
          'يحق للموظف مراجعة وتحديث بياناته الشخصية وطلب تصحيح أي معلومات غير دقيقة من خلال التواصل المباشر مع إدارة الموارد البشرية عبر القنوات المعتمدة بالتطبيق.',

      // Help Center
      'help.title': 'مركز المساعدة',
      'help.header_title': 'كيف يمكننا مساعدتك اليوم؟',
      'help.header_subtitle': 'ابحث في الأسئلة الشائعة أو اختر القسم المناسب للإجابة الفورية',
      'help.search_placeholder': 'ابحث عن إجابة أو موضوع في الأسئلة الشائعة...',
      'help.all_categories': 'الكل',
      'help.cat_attendance': 'الحضور والانصراف',
      'help.cat_account': 'الحساب والملف',
      'help.cat_requests': 'طلبات الموظفين',
      'help.cat_communication': 'التواصل مع HR',
      'help.cat_notifications': 'التنبيهات',
      'help.cat_security': 'الأمان والدخول',
      'help.no_results_title': 'لم يتم العثور على نتائج تطابق بحثك',
      'help.no_results_desc': 'جرب البحث بكلمات أخرى أو تواصل مع فريق الدعم الفني مباشرة.',
      'help.still_need_help': 'لم تجد إجابة لاستفسارك؟',
      'help.contact_support_cta': 'تواصل مع فريق الدعم الفني',

      // Support
      'support.title': 'الدعم الفني والمساعدة',
      'support.header_title': 'نحن هنا لمساعدتك',
      'support.header_subtitle': 'أرسل بلاغاً أو تواصل مباشرة مع فريق الموارد البشرية والدعم التقني',
      'support.direct_chat_title': 'محادثة فورية مع الموارد البشرية',
      'support.direct_chat_desc': 'تواصل مباشرة مع مسؤولي وممثلي الأقسام',
      'support.official_email_title': 'البريد المعتمد لقسم الدعم',
      'support.report_tab': 'تقديم بلاغ أو مشكلة',
      'support.history_tab': 'سجل بلاغاتي السابقة',
      'support.problem_type': 'نوع المشكلة أو الاستفسار',
      'support.problem_type_hint': 'اختر نوع المشكلة',
      'support.type_login': 'مشكلة في تسجيل الدخول أو المصادقة',
      'support.type_attendance': 'مشكلة في تسجيل الحضور أو إشارة GPS',
      'support.type_profile': 'مشكلة في البيانات أو الملف الشخصي',
      'support.type_requests': 'مشكلة في تقديم أو متابعة الطلبات',
      'support.type_notifications': 'مشكلة في استلام التنبيهات والإشعارات',
      'support.type_app_error': 'خطأ تقني أو توقف مفاجئ في التطبيق',
      'support.type_other': 'استفسار أو مشكلة أخرى',
      'support.subject': 'عنوان البلاغ',
      'support.subject_hint': 'اكتب ملخصاً موجزاً للمشكلة...',
      'support.subject_required': 'يرجى إدخال عنوان للبلاغ (3 أحرف على الأقل)',
      'support.description': 'تفاصيل المشكلة',
      'support.description_hint': 'اشرح ما حدث بالتفصيل والخطوات لنتمكن من مساعدتك سريعاً...',
      'support.description_required': 'يرجى كتابة تفاصيل المشكلة (10 أحرف على الأقل)',
      'support.attachment': 'مرفقات توضيحية (اختياري)',
      'support.attachment_hint': 'إرفاق لقطة شاشة توضيحية',
      'support.attachment_added': 'تم إرفاق لقطة الشاشة بنجاح',
      'support.submit_report': 'إرسال البلاغ إلى الدعم',
      'support.submitting': 'جاري إرسال البلاغ...',
      'support.submit_success_title': 'تم استلام بلاغك بنجاح',
      'support.submit_success_msg': 'تم تسجيل بلاغك في النظام وسيقوم الفريق الفني بمراجعته والتواصل معك.',
      'support.no_reports_title': 'لا توجد بلاغات سابقة',
      'support.no_reports_desc': 'عند قيامك بإرسال أي بلاغ فني سيظهر هنا لمتابعة حالته وتحديثاته.',
      'support.ticket_id': 'رقم البلاغ:',
      'support.ticket_status': 'الحالة:',
      'support.status_open': 'جديد',
      'support.status_in_progress': 'قيد المعالجة',
      'support.status_resolved': 'تم الحل',
      'support.status_closed': 'مغلق',
      'support.view_ticket_details': 'تفاصيل التذكرة',
    },
    'en': {
      // App
      'app.title': 'CyberWise IE',

      // Navigation
      'nav.home': 'Home',
      'nav.requests': 'Requests',
      'nav.communication': 'Communication',
      'nav.notifications': 'Notifications',
      'nav.profile': 'Profile',

      // Communication
      'communication.title': 'Communication & Operations',
      'communication.departments': 'Hotel Departments',
      'communication.my_conversations': 'My Conversations',
      'communication.my_requests': 'My Department Requests',
      'communication.start_chat': 'Start Chat',
      'communication.create_request': 'Create Request',
      'communication.active_requests': 'Active Requests',
      'communication.select_department': 'Select Department',
      'communication.department_employees': 'Department Employees',
      'communication.request_details': 'Request Details',
      'communication.new_request': 'New Department Request',
      'communication.priority': 'Priority Level',
      'communication.priority_low': 'Low',
      'communication.priority_normal': 'Normal',
      'communication.priority_high': 'High',
      'communication.status_pending': 'Pending',
      'communication.status_accepted': 'Accepted',
      'communication.status_in_progress': 'In Progress',
      'communication.status_completed': 'Completed',
      'communication.status_rejected': 'Rejected',
      'communication.status_cancelled': 'Cancelled',
      'communication.action_accept': 'Accept Request',
      'communication.action_reject': 'Reject Request',
      'communication.action_start': 'Start Progress',
      'communication.action_complete': 'Complete Request',

      // Auth
      'auth.welcome_title': 'Welcome to CyberWise IE',
      'auth.welcome_back': 'Welcome Back',
      'auth.welcome_subtitle':
          'Your enterprise portal for attendance, requests, and HR services with maximum simplicity.',
      'auth.sign_in_subtitle':
          'Sign in to access your employee account.',
      'auth.sign_in_google': 'Sign in with Google',
      'auth.continue_google': 'Continue with Google',
      'auth.signing_in': 'Signing in...',
      'auth.secure_access': 'Secure employee access',
      'auth.error_generic': 'Unable to sign in. Please try again.',
      'auth.logout': 'Sign Out',
      'auth.logout_confirm': 'Are you sure you want to sign out?',

      // Home
      'home.greeting_morning': 'Good morning',
      'home.greeting_evening': 'Good evening',
      'home.welcome': 'Welcome',
      'home.today_status': 'Today\'s Status',
      'home.quick_actions': 'Quick Actions',
      'home.recent_activity': 'Recent Activity',
      'home.view_all': 'View all',

      // Attendance
      'attendance.title': 'Attendance',
      'attendance.status': 'Attendance Status',
      'attendance.status_not_checked_in': 'Not checked in today',
      'attendance.status_currently_working': 'Currently Working',
      'attendance.status_workday_completed': 'Workday Completed',
      'attendance.status_offline_pending': 'Saved Offline (Pending Sync)',
      'attendance.check_in': 'Check In',
      'attendance.check_out': 'Check Out',
      'attendance.checked_in': 'Checked In',
      'attendance.checked_out': 'Checked Out',
      'attendance.not_checked_in': 'Not checked in today',
      'attendance.completed_btn': 'Attendance Completed',
      'attendance.inside_range': 'Inside Office Geofence',
      'attendance.outside_range': 'Outside Attendance Geofence',
      'attendance.outside_range_desc':
          'You must be within 4 meters of the workplace location to log attendance.',
      'attendance.inside_allowed_zone': 'You are inside the attendance zone (< 4 meters)',
      'attendance.outside_allowed_zone': 'You are outside the attendance zone (Max allowed 4 meters)',
      'attendance.distance_to_office': 'You are {dist} away from workplace',
      'attendance.distance_label': 'Distance',
      'attendance.allowed_radius_label': 'Allowed Radius',
      'attendance.accuracy_label': 'GPS Accuracy',
      'attendance.work_schedule_title': 'Work Schedule',
      'attendance.grace_period_label': 'Grace Period',
      'attendance.shift_hours_label': 'Shift Hours',
      'attendance.header_subtitle': 'Smart Attendance Verification',
      'attendance.permission_required_title': 'Location Permission Required',
      'attendance.permission_required_desc': 'Location permission is required to verify physical presence at workplace.',
      'attendance.gps_disabled_alert': 'GPS location service is disabled. Please enable it to continue.',
      'attendance.mock_location_alert': 'Mock location detected. Attendance rejected for security.',
      'attendance.low_accuracy_title': 'Location Accuracy Too Low',
      'attendance.low_accuracy_desc': 'GPS signal is weak. Please move to an open area and try again.',
      'attendance.workplace_zone': 'Approved Workplace',
      'attendance.update_location': 'Update Location',
      'attendance.updating_location': 'Updating location...',
      'attendance.allow_location_permission': 'Allow Location',
      'attendance.open_location_settings': 'Open Settings',
      'attendance.verify_identity': 'Verify Your Identity',
      'attendance.biometric_desc': 'Use your fingerprint or Face ID to confirm attendance securely.',
      'attendance.biometric_ready': 'Biometric Ready',
      'attendance.biometric_verifying': 'Verifying biometrics...',
      'attendance.biometric_failed': 'Biometric verification failed',
      'attendance.biometric_try_again': 'Try Again',
      'attendance.biometric_unavailable': 'Biometrics unavailable on this device',
      'attendance.check_in_time': 'Check-in Time',
      'attendance.check_out_time': 'Check-out Time',
      'attendance.working_hours': 'Working Hours',
      'attendance.checking_location': 'Verifying GPS location...',
      'attendance.authenticating_biometric': 'Please verify fingerprint or face...',
      'attendance.submitting': 'Recording attendance...',
      'attendance.success_msg': 'Check-in recorded successfully!',
      'attendance.checkout_success_msg': 'Check-out recorded successfully!',
      'attendance.pending_hr_verification': 'Pending HR Verification',
      'attendance.offline_notice': 'Saved locally - will sync when online',
      'attendance.offline_alert': 'Attendance saved offline and will sync automatically later.',
      'attendance.offline_badge': 'Offline Mode',
      'attendance.sync_now': 'Sync Records Now',
      'attendance.syncing': 'Syncing...',
      'attendance.synced_success': 'All records synced successfully',
      'attendance.history': 'Recent Attendance Logs',
      'attendance.timeline_title': 'Today\'s Timeline',
      'attendance.timeline_checkin': 'Check-In',
      'attendance.timeline_checkout': 'Check-Out',
      'attendance.timeline_working': 'Active Working Session',
      'attendance.device_integrity_title': 'Device & App Integrity',
      'attendance.device_integrity_ok': 'Device Verified & Secured',
      'attendance.device_integrity_failed': 'Unable to verify device security.',
      'attendance.vpn_detected_notice': 'VPN detected (security risk signal)',
      'attendance.vpn_not_detected': 'Direct Network Connection',
      'attendance.server_verification': 'Central Verification',
      'attendance.server_verified_note': 'The server makes the final decision on attendance verification',
      'attendance.mock_location_detected_msg': 'Attendance cannot be logged using an untrusted location.',
      'attendance.location_service_disabled_msg': 'Please enable location services',
      'attendance.location_service_required_msg': 'Location service must be enabled to register attendance.',
      'attendance.overlay_detected_alert':
          'Another application may be displaying over the app.\nPlease close it and try again.',
      'attendance.location_permission_denied_msg': 'Please allow location permission for the app',
      'attendance.location_low_accuracy_msg': 'Location accuracy is insufficient',
      'attendance.outside_workplace_msg': 'You are outside the workplace zone',
      'attendance.location_unavailable_msg': 'Could not determine your location, please try again',
      'attendance.checkout_confirm_title': 'Confirm Check-Out',
      'attendance.checkout_confirm_msg': 'Are you sure you want to check out and complete today\'s workday?',
      'attendance.security_note': 'Attendance is securely verified using precise GPS geofencing and OS biometric authentication.',
      'common.test_mode': 'TEST MODE',
      'common.device_test_data': 'Device Test Data (DEVICE_TEST_DATA)',

      // Requests Hub
      'requests.title': 'Requests Center',
      'requests.advances': 'Advances & Expenses',
      'requests.permissions': 'Permissions',
      'requests.vacations': 'Vacations',
      'requests.new': 'New Request',
      'requests.history': 'Past Requests',
      'requests.all': 'All',
      'requests.empty': 'No requests found',
      'requests.filter': 'Filter by status',

      // Advances
      'advances.title': 'Financial Advances',
      'advances.new': 'New Advance Request',
      'advances.amount': 'Requested Amount',
      'advances.reason': 'Advance Reason',
      'advances.details': 'Additional Details',
      'advances.installments': 'Installments Count',
      'advances.expense_report': 'Expense Report',
      'advances.submit_report': 'Submit Expense Report',
      'advances.attachment': 'Attachments / Receipts',
      'advances.report_required': 'Report Required',
      'advances.report_submitted': 'Report Submitted',

      // Permissions
      'permissions.title': 'Permission Requests',
      'permissions.new': 'New Permission',
      'permissions.type': 'Permission Type',
      'permissions.type_delay': 'Morning Delay',
      'permissions.type_early_leave': 'Early Departure',
      'permissions.type_absence': 'One Day Absence',
      'permissions.type_half_day': 'Half Day',
      'permissions.date': 'Permission Date',
      'permissions.time': 'Time / Duration',
      'permissions.reason': 'Reason',

      // Vacations
      'vacations.title': 'Vacations',
      'vacations.new': 'New Vacation Request',
      'vacations.type': 'Vacation Type',
      'vacations.type_annual': 'Annual Leave',
      'vacations.type_sick': 'Sick Leave',
      'vacations.type_casual': 'Casual Leave',
      'vacations.type_unpaid': 'Unpaid Leave',
      'vacations.from_date': 'From Date',
      'vacations.to_date': 'To Date',
      'vacations.days_count': 'Total Days',
      'vacations.reason': 'Reason',
      'vacations.attachment': 'Attachment (Medical report if any)',

      // Statuses
      'status.pending': 'Pending Review',
      'status.approved': 'Approved',
      'status.rejected': 'Rejected',
      'status.paid': 'Paid',
      'status.cancelled': 'Cancelled',
      'status.completed': 'Completed',

      // Notifications
      'notifications.title': 'Notifications',
      'notifications.empty': 'No notifications yet',
      'notifications.mark_all_read': 'Mark all as read',
      'notifications.category_hr': 'HR Messages',
      'notifications.category_requests': 'Request Updates',
      'notifications.category_deductions': 'Deductions & Payroll',
      'notifications.category_attendance': 'Attendance Alerts',
      'notifications.category_system': 'System Alerts',

      // Profile
      'profile.title': 'Profile',
      'profile.employee_id': 'Employee ID',
      'profile.department': 'Department',
      'profile.job_title': 'Job Title',
      'profile.email': 'Email',
      'profile.settings': 'Settings',
      'profile.help': 'Help & Support',
      'profile.privacy': 'Privacy Policy',
      'profile.about': 'About App',

      // Settings
      'settings.title': 'Settings',
      'settings.account': 'Account',
      'settings.appearance': 'Appearance',
      'settings.theme': 'Theme Mode',
      'settings.theme_system': 'System Default',
      'settings.theme_light': 'Light Mode',
      'settings.theme_dark': 'Dark Mode',
      'settings.language': 'Language',
      'settings.language_ar': 'Arabic (العربية)',
      'settings.language_en': 'English (الإنجليزية)',
      'settings.developer_demo': 'Developer & Demo Controls',
      'settings.demo_desc':
          'Control GPS simulation, biometrics, and offline connectivity for testing.',

      // Demo Controls
      'demo.title': 'Demo & Simulation Controls',
      'demo.location_heading': 'GPS Location Simulation',
      'demo.location_inside': 'Inside Geofence (< 4 meters)',
      'demo.location_outside': 'Outside Geofence (> 4 meters)',
      'demo.location_denied': 'Location Permission Denied',
      'demo.biometric_heading': 'Biometrics Simulation',
      'demo.biometric_success': 'Authentication Success',
      'demo.biometric_failed': 'Biometric Mismatch / Failed',
      'demo.biometric_cancelled': 'Cancelled by User',
      'demo.network_heading': 'Connectivity Simulation',
      'demo.network_online': 'Online Mode',
      'demo.network_offline': 'Offline Mode (Local Queue)',
      'demo.reset_data': 'Reset to Default Mock Data',
      'demo.data_reset_success': 'Mock data has been reset to defaults',

      // Onboarding Phase 01
      'onboarding.step1_title': 'Basic Information',
      'onboarding.step1_subtitle':
          'Confirm your name and enter your phone number to continue.',
      'onboarding.step2_title': 'Job & Department',
      'onboarding.step2_subtitle': 'Select your job title and department.',
      'onboarding.step3_title': 'Review & Confirm',
      'onboarding.step3_subtitle':
          'Please review all your information before completing your account.',
      'onboarding.review_your_info': 'Review Your Information',
      'onboarding.full_name': 'Full Name',
      'onboarding.email': 'Email',
      'onboarding.national_id': 'National ID / Civil ID',
      'onboarding.phone': 'Phone Number',
      'onboarding.job_title': 'Job Title',
      'onboarding.department': 'Department',
      'onboarding.region': 'Region',
      'onboarding.manager': 'Direct Manager',
      'onboarding.work_location': 'Assigned Workplace',
      'onboarding.hr_contact': 'HR Support',
      'onboarding.next': 'Continue',
      'onboarding.continue_action': 'Continue',
      'onboarding.confirm_continue': 'Confirm & Continue',
      'onboarding.edit_action': 'Edit',
      'onboarding.complete': 'Complete Setup',
      'onboarding.complete_setup': 'Complete Setup',
      'onboarding.back': 'Back',
      'onboarding.verified_by_google': 'Verified by Google',
      'onboarding.verified': 'Verified',
      'onboarding.email_readonly_note': 'Email is linked to your Google account and cannot be edited',
      'onboarding.name_required': 'Full name is required',
      'onboarding.phone_required': 'Phone number is required',
      'onboarding.phone_invalid': 'Please enter a valid phone number (10 to 15 digits)',
      'onboarding.job_required': 'Please select a job title',
      'onboarding.department_required': 'Please select a department',
      'onboarding.profile_completed_success': 'Profile completed successfully',
      'onboarding.biometric_title': 'Enable Biometric Authentication',
      'onboarding.biometric_subtitle':
          'Secure your attendance with fingerprint or face recognition',
      'onboarding.enable_biometric': 'Enable Biometric',
      'onboarding.skip_biometric': 'Skip for Now',
      'onboarding.hr_call': 'Call HR',
      'onboarding.hr_contact_email': 'Email HR',
      'onboarding.hr_contacting': 'Connecting with HR...',
      'onboarding.location_access_title': 'Location Access',
      'onboarding.location_access_desc': 'Your location is required to verify attendance at your assigned workplace (4m radius).',
      'onboarding.location_permission_enabled': 'Location permission enabled',
      'onboarding.location_permission_required': 'Location permission required',
      'onboarding.allow_location': 'Allow Location',
      'onboarding.workplace_assigned': 'Workplace assigned',
      'onboarding.hr_support_title': 'HR Support',
      'onboarding.select_job_title': 'Select job title',
      'onboarding.select_department': 'Select department',
      'onboarding.select_region': 'Select Region',
      'onboarding.select_manager': 'Select Direct Manager',
      'onboarding.search_placeholder': 'Search...',
      'onboarding.required_fields_error': 'Please fill in all required fields to continue.',

      // Common
      'common.save': 'Save',
      'common.cancel': 'Cancel',
      'common.retry': 'Retry',
      'common.submit': 'Submit Request',
      'common.success': 'Success',
      'common.error': 'Error',
      'common.settings': 'Settings',
      'common.confirm': 'Confirm',
      'common.back': 'Back',
      'common.egp': 'EGP',
      'common.days': 'days',
      'common.day': 'day',
      'common.hours': 'hours',
      'common.meters': 'meters',
      'common.meter': 'meter',
      'common.loading': 'Loading...',
      'common.no_data': 'No data available',

      // Location Tracking & Work Session
      'tracking.title': 'Work Location Tracking',
      'tracking.active_foreground': 'Active (Foreground)',
      'tracking.active_background': 'Active (Background)',
      'tracking.stopped': 'Stopped',
      'tracking.starting': 'Starting...',
      'tracking.paused': 'Paused',
      'tracking.error': 'Tracking Alert',
      'tracking.reason_checkout': 'Work session ended',
      'tracking.reason_logout': 'Logged out',
      'tracking.permission_required': 'Location permission required',
      'tracking.background_permission_desc': 'Allows location tracking during work hours when app is minimized',
      'tracking.gps_disabled_desc': 'Please enable GPS/Location service from device settings',
      'tracking.offline_queued': 'Pending offline records',
      'tracking.sync_success': 'Records synced successfully',
      'tracking.syncing': 'Syncing with server...',
      'tracking.last_update': 'Last location update:',

      // Device Session & Info
      'session.device_session': 'Verified Device Session',
      'session.active': 'Active',
      'session.inactive': 'Inactive',
      'session.push_token': 'Push Token (FCM)',
      'session.work_session': 'Current Work Session',

      // About Application
      'about.title': 'About App',
      'about.subtitle': 'Employee Management & HR Platform',
      'about.version': 'Version',
      'about.build': 'Build',
      'about.section_app': 'About the Application',
      'about.app_description':
          'The Employee App is an internal platform that helps employees manage attendance, requests, notifications, and communication with the Human Resources department in a simple and secure way.',
      'about.section_features': 'Main Features',
      'about.feature_attendance': 'Attendance',
      'about.feature_attendance_desc':
          'Track employee check-in and check-out and view attendance history.',
      'about.feature_requests': 'Employee Requests',
      'about.feature_requests_desc':
          'Submit and track permission, late, and absence requests.',
      'about.feature_communication': 'HR Communication',
      'about.feature_communication_desc':
          'Communicate with the Human Resources department.',
      'about.feature_notifications': 'Notifications',
      'about.feature_notifications_desc':
          'Receive important employee and HR notifications.',
      'about.feature_profile': 'Profile',
      'about.feature_profile_desc':
          'View and manage employee profile information.',
      'about.section_support': 'Support & Help',
      'about.help_center': 'Help Center',
      'about.help_center_desc': 'Frequently asked questions and guides',
      'about.contact_support': 'Contact Support',
      'about.contact_support_desc': 'Reach out to system administrators and HR',
      'about.report_problem': 'Report a Problem',
      'about.report_problem_desc': 'Submit technical issues or bug reports',
      'about.section_legal': 'Legal',
      'about.privacy_policy': 'Privacy Policy',
      'about.privacy_policy_desc': 'Data protection standards and privacy',
      'about.terms_of_use': 'Terms of Use',
      'about.terms_of_use_desc': 'Internal policy guidelines and terms',
      'about.open_source_licenses': 'Open Source Licenses',
      'about.open_source_licenses_desc': 'Third-party open-source software notices',
      'about.section_company': 'Company',
      'about.company_name': 'Company Name',
      'about.company_website': 'Website',
      'about.company_email': 'Corporate Email',
      'about.all_rights_reserved': 'All rights reserved.',
      'about.privacy_dialog_title': 'Privacy & Security Policy',
      'about.privacy_dialog_content':
          'This application is dedicated to safeguarding employee privacy and personal data. All attendance records and employee requests are securely encrypted according to corporate security standards.',
      'about.terms_dialog_title': 'Terms of Use',
      'about.terms_dialog_content':
          'This application is an enterprise tool intended strictly for authorized employees. Unauthorized access, tampering with telemetry, or attempting spoofing is strictly prohibited.',
      // Privacy Policy
      'privacy.title': 'Privacy Policy',
      'privacy.subtitle': 'Learn how we collect, use, protect, and manage your information.',
      'privacy.last_updated': 'Last Updated: August 31, 2026',
      'privacy.sec_intro_title': '1. Introduction & Scope',
      'privacy.sec_intro_body':
          'The Employee App is an internal corporate platform designated for authorized employees to manage daily self-service tasks such as attendance, administrative and financial requests, official notifications, and HR communication.',
      'privacy.sec_collected_title': '2. Information We Process',
      'privacy.sec_collected_account':
          'Account Information: Includes full name, employee ID, phone number, corporate email, job title, and assigned department.',
      'privacy.sec_collected_attendance':
          'Attendance Information: Includes exact check-in/out timestamps, daily working hour logs, and workplace verification status.',
      'privacy.sec_collected_device':
          'Technical Device Information: Includes device model, operating system, application version, and verified session identifiers for account security.',
      'privacy.sec_location_title': '3. Location Data Processing (GPS)',
      'privacy.sec_location_body':
          'Location permission is requested exclusively during attendance check-in/out verification to validate physical presence within the authorized workplace geofence. The application does not track employees outside designated work procedures.',
      'privacy.sec_usage_title': '4. How We Use Information',
      'privacy.sec_usage_body':
          'Information is utilized to verify identity, record official attendance logs, process leave and advance requests, dispatch critical organizational notifications, and safeguard systems against unauthorized access.',
      'privacy.sec_security_title': '5. Data Security & Protection',
      'privacy.sec_security_body':
          'All information is protected by stringent enterprise safeguards including encryption, biometric authentication, role-based access controls, and secure local storage to prevent unauthorized exposure.',
      'privacy.sec_sharing_title': '6. Data Confidentiality & Sharing',
      'privacy.sec_sharing_body':
          'Employee data is strictly confidential and processed solely within authorized corporate systems. It is never sold, shared, or disclosed to unauthorized third parties.',
      'privacy.sec_retention_title': '7. Data Retention',
      'privacy.sec_retention_body':
          'Data and attendance records are retained throughout employment duration in accordance with organizational policies and regulatory record-keeping standards.',
      'privacy.sec_rights_title': '8. Employee Rights & Inquiries',
      'privacy.sec_rights_body':
          'Employees may review and request corrections of personal records by contacting the Human Resources department via internal application channels.',

      // Help Center
      'help.title': 'Help Center',
      'help.header_title': 'How can we help you today?',
      'help.header_subtitle': 'Search frequently asked questions or select a category for instant answers',
      'help.search_placeholder': 'Search help articles & FAQs...',
      'help.all_categories': 'All',
      'help.cat_attendance': 'Attendance',
      'help.cat_account': 'Account & Profile',
      'help.cat_requests': 'Requests',
      'help.cat_communication': 'HR Communication',
      'help.cat_notifications': 'Notifications',
      'help.cat_security': 'Security & Login',
      'help.no_results_title': 'No matching results found',
      'help.no_results_desc': 'Try searching with different keywords or contact technical support directly.',
      'help.still_need_help': 'Still need help?',
      'help.contact_support_cta': 'Contact Support Team',

      // Support
      'support.title': 'Support & Help',
      'support.header_title': "We're here to help you",
      'support.header_subtitle': 'Submit a report or contact the HR and technical support team directly',
      'support.direct_chat_title': 'Instant HR Chat',
      'support.direct_chat_desc': 'Chat directly with department representatives',
      'support.official_email_title': 'Official Support Email',
      'support.report_tab': 'Report a Problem',
      'support.history_tab': 'My Reports',
      'support.problem_type': 'Problem Type',
      'support.problem_type_hint': 'Select problem type',
      'support.type_login': 'Login & Authentication Issue',
      'support.type_attendance': 'Attendance or Location Issue',
      'support.type_profile': 'Profile or Data Issue',
      'support.type_requests': 'Requests Issue',
      'support.type_notifications': 'Notification Issue',
      'support.type_app_error': 'Application Error / Crash',
      'support.type_other': 'Other Inquiries',
      'support.subject': 'Subject',
      'support.subject_hint': 'Brief summary of the issue...',
      'support.subject_required': 'Subject is required (at least 3 characters)',
      'support.description': 'Problem Description',
      'support.description_hint': 'Describe what happened in detail so we can assist you quickly...',
      'support.description_required': 'Please enter problem details (at least 10 characters)',
      'support.attachment': 'Attachment (Optional)',
      'support.attachment_hint': 'Attach screenshot or supporting document',
      'support.attachment_added': 'File attached successfully',
      'support.submit_report': 'Submit Report',
      'support.submitting': 'Submitting report...',
      'support.submit_success_title': 'Report Submitted Successfully',
      'support.submit_success_msg': 'Your report has been logged and the technical team will review and contact you.',
      'support.no_reports_title': 'No Previous Reports',
      'support.no_reports_desc': 'When you submit a support ticket, its status and updates will appear here.',
      'support.ticket_id': 'Ticket ID:',
      'support.ticket_status': 'Status:',
      'support.status_open': 'Open',
      'support.status_in_progress': 'In Progress',
      'support.status_resolved': 'Resolved',
      'support.status_closed': 'Closed',
      'support.view_ticket_details': 'View Ticket Details',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['ar', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
