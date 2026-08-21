import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Comprehensive Localization Dictionary and Formatters for CyberWise IE HR Portal
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  bool get isArabic => locale.languageCode == 'ar';

  // ==========================================
  // 1. DICTIONARIES
  // ==========================================

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General
      'app_title': 'CyberWise IE',
      'hr_portal': 'HR Management Dashboard',
      'welcome': 'Welcome',
      'admin': 'Administrator',
      'role': 'Role',
      'status': 'Status',
      'actions': 'Actions',
      'details': 'Details',
      'search_placeholder': 'Search by name, code, department...',
      'filter': 'Filter',
      'export': 'Export',
      'refresh': 'Refresh',
      'add_new': 'Add New',
      'create': 'Create',
      'save': 'Save',
      'save_changes': 'Save Changes',
      'cancel': 'Cancel',
      'close': 'Close',
      'delete': 'Delete',
      'edit': 'Edit',
      'approve': 'Approve',
      'reject': 'Reject',
      'confirm': 'Confirm',
      'submit': 'Submit',
      'apply': 'Apply',
      'view': 'View',
      'send': 'Send',
      'all': 'All',
      'clear': 'Clear',
      'back': 'Back',
      'next': 'Next',
      'loading': 'Loading data...',
      'no_data': 'No records found matching criteria.',
      'error_generic': 'An unexpected error occurred. Please try again.',
      'success_generic': 'Operation completed successfully.',
      'immutable_badge': 'IMMUTABLE RECORD',
      'verified_badge': 'VERIFIED',

      // Navigation
      'nav_dashboard': 'Executive Dashboard',
      'nav_employees': 'Employees Directory',
      'nav_workplaces': 'Workplaces & Geofences',
      'nav_attendance': 'Attendance & Live Punch',
      'nav_requests': 'Requests & Approvals',
      'nav_advances': 'Salary Advances',
      'nav_deductions': 'Payroll Deductions',
      'nav_schedules': 'Work Schedules & Shifts',
      'nav_reports': 'Reports & Analytics',
      'nav_notifications': 'HR Notifications',
      'nav_messages': 'Direct HR Messages',
      'nav_audit_logs': 'Audit Logs & Trail',
      'nav_settings': 'System Settings',
      'nav_logout': 'Sign Out',

      // Auth
      'auth_login_title': 'HR Portal Login',
      'auth_login_subtitle': 'Sign in with your authorized CyberWise credentials',
      'auth_email': 'Work Email Address',
      'auth_password': 'Password',
      'auth_sign_in': 'Sign In to Portal',
      'auth_forgot_password': 'Forgot Password?',
      'auth_logging_in': 'Authenticating...',
      'auth_mock_note': 'Test Environment: Mock credentials enabled',

      // Employees
      'emp_total': 'Total Workforce',
      'emp_active': 'Active Employees',
      'emp_on_leave': 'On Leave',
      'emp_suspended': 'Suspended',
      'emp_name': 'Employee Name',
      'emp_code': 'Employee Code',
      'emp_department': 'Department',
      'emp_job_title': 'Job Title',
      'emp_workplace': 'Assigned Workplace',
      'emp_schedule': 'Assigned Schedule',
      'emp_phone': 'Phone Number',
      'emp_email': 'Email Address',
      'emp_national_id': 'National ID',
      'emp_basic_salary': 'Basic Monthly Salary',
      'emp_hire_date': 'Hire Date',
      'emp_create_title': 'Register New Employee',
      'emp_edit_title': 'Edit Employee Profile',
      'emp_assign_title': 'Assign Workplace & Schedule',

      // Workplaces
      'wp_title': 'Workplaces & Geofencing',
      'wp_name': 'Workplace Name',
      'wp_address': 'Physical Address',
      'wp_radius': 'Geofence Radius (Meters)',
      'wp_coordinates': 'GPS Coordinates',
      'wp_assigned_staff': 'Assigned Employees',
      'wp_active_status': 'Operational Status',

      // Attendance
      'att_live_feed': 'Live Attendance Feed',
      'att_check_in': 'Check-In',
      'att_check_out': 'Check-Out',
      'att_punch_time': 'Punch Timestamp',
      'att_gps_accuracy': 'GPS Accuracy',
      'att_distance': 'Distance to Geofence',
      'att_status_present': 'Present on Time',
      'att_status_late': 'Late Arrival',
      'att_status_absent': 'Absent',
      'att_status_early_leave': 'Early Departure',
      'att_manual_correction': 'Manual Punch Adjustment',
      'att_offline_review': 'Offline Punch Queue',

      // Requests
      'req_title': 'Workforce Requests & Approvals',
      'req_leave': 'Leave Request',
      'req_permission': 'Permission Request',
      'req_advance': 'Salary Advance Request',
      'req_attendance_corr': 'Attendance Correction',
      'req_review_title': 'Review Request',
      'req_reason_mandatory': 'Rejection reason is required',
      'req_status_pending': 'Pending Review',
      'req_status_approved': 'Approved',
      'req_status_rejected': 'Rejected',

      // Advances
      'adv_title': 'Salary Advances Management',
      'adv_amount': 'Advance Principal',
      'adv_installments': 'Monthly Installments',
      'adv_remaining': 'Outstanding Balance',
      'adv_cap_info': 'Advance Cap: Max 50% of Basic Salary',

      // Deductions
      'ded_title': 'Payroll Deductions Management',
      'ded_reason': 'Deduction Reason',
      'ded_period': 'Payroll Period',
      'ded_type_penalty': 'Disciplinary Penalty',
      'ded_type_advance': 'Advance Installment',

      // Schedules
      'sch_title': 'Work Schedules & Shift Management',
      'sch_shift_window': 'Shift Working Window',
      'sch_grace_period': 'Grace Window (Minutes)',
      'sch_working_days': 'Operational Days',

      // Reports
      'rep_title': 'Reports & Workforce Analytics',
      'rep_attendance_rate': 'Overall Attendance Rate',
      'rep_punctuality': 'Punctuality Index',
      'rep_export_csv': 'Export CSV',
      'rep_export_pdf': 'Export PDF',
      'rep_export_xlsx': 'Export Excel',

      // Notifications
      'notif_title': 'HR Announcements & Broadcasts',
      'notif_new': 'Compose Announcement',
      'notif_target_all': 'All Employees',
      'notif_target_dept': 'Specific Department',
      'notif_target_wp': 'Specific Workplace',
      'notif_confirm_send': 'Broadcast Safety Confirmation',

      // Messages
      'msg_title': 'HR Direct Messages & Inquiries',
      'msg_new_conversation': 'New Direct Message',
      'msg_unread': 'Unread Inquiries',
      'msg_resolved': 'Resolved Threads',
      'msg_type_message': 'Type your response...',

      // Audit Logs
      'aud_title': 'System Audit Logs & Security Trail',
      'aud_total': 'Total Logs',
      'aud_security_events': 'Security Events',
      'aud_admin_actions': 'Admin Actions',
      'aud_failed_ops': 'Failed Operations',
      'aud_metadata': 'Event Structured Metadata Payload',

      // Settings
      'set_title': 'HR Portal Settings & System Policies',
      'set_general': 'General & Company',
      'set_attendance_policy': 'Attendance Policy',
      'set_notifications': 'Notifications',
      'set_security': 'Security & Sessions',
      'set_appearance': 'Appearance & Theme',
      'set_language': 'Language & Regional',
      'set_language_desc': 'Select your preferred dashboard language (English / العربية).',
    },
    'ar': {
      // General
      'app_title': 'سايبر وايز IE',
      'hr_portal': 'لوحة تحكم إدارة الموارد البشرية',
      'welcome': 'مرحبًا',
      'admin': 'مدير النظام',
      'role': 'الدور الوظيفي',
      'status': 'الحالة',
      'actions': 'الإجراءات',
      'details': 'التفاصيل',
      'search_placeholder': 'البحث بالاسم، الكود، القسم...',
      'filter': 'تصفية',
      'export': 'تصدير',
      'refresh': 'تحديث',
      'add_new': 'إضافة جديد',
      'create': 'إنشاء',
      'save': 'حفظ',
      'save_changes': 'حفظ التغييرات',
      'cancel': 'إلغاء',
      'close': 'إغلاق',
      'delete': 'حذف',
      'edit': 'تعديل',
      'approve': 'اعتماد',
      'reject': 'رفض',
      'confirm': 'تأكيد',
      'submit': 'إرسال',
      'apply': 'تطبيق',
      'view': 'عرض',
      'send': 'إرسال',
      'all': 'الكل',
      'clear': 'مسح',
      'back': 'رجوع',
      'next': 'التالي',
      'loading': 'جاري تحميل البيانات...',
      'no_data': 'لم يتم العثور على سجلات تطابق البحث.',
      'error_generic': 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.',
      'success_generic': 'تمت العملية بنجاح.',
      'immutable_badge': 'سجل غير قابل للتعديل',
      'verified_badge': 'تم التحقق',

      // Navigation
      'nav_dashboard': 'لوحة المعلومات الرئيسية',
      'nav_employees': 'سجل الموظفين',
      'nav_workplaces': 'أماكن العمل والنطاقات الجغرافية',
      'nav_attendance': 'سجل الحضور والبصمة الحية',
      'nav_requests': 'الطلبات والموافقات',
      'nav_advances': 'السلف المالية',
      'nav_deductions': 'الخصومات والجزاءات',
      'nav_schedules': 'جداول ومواعيد العمل',
      'nav_reports': 'التقارير والإحصائيات',
      'nav_notifications': 'إشعارات وتنبيهات HR',
      'nav_messages': 'المراسلات الداخلية المباشرة',
      'nav_audit_logs': 'سجل التدقيق والأمان',
      'nav_settings': 'إعدادات النظام والسياسات',
      'nav_logout': 'تسجيل الخروج',

      // Auth
      'auth_login_title': 'تسجيل دخول لوحة الموارد البشرية',
      'auth_login_subtitle': 'قم بتسجيل الدخول باستخدام بيانات الاعتماد المصرح بها',
      'auth_email': 'البريد الإلكتروني للعمل',
      'auth_password': 'كلمة المرور',
      'auth_sign_in': 'تسجيل الدخول',
      'auth_forgot_password': 'هل نسيت كلمة المرور؟',
      'auth_logging_in': 'جاري التحقق من الهوية...',
      'auth_mock_note': 'بيئة تجريبية: الحسابات التجريبية مفعلة',

      // Employees
      'emp_total': 'إجمالي القوى العاملة',
      'emp_active': 'الموظفون النشطون',
      'emp_on_leave': 'في إجازة',
      'emp_suspended': 'موقوف عن العمل',
      'emp_name': 'اسم الموظف',
      'emp_code': 'كود الموظف',
      'emp_department': 'القسم',
      'emp_job_title': 'المسمى الوظيفي',
      'emp_workplace': 'مكان العمل المعين',
      'emp_schedule': 'جدول العمل المعين',
      'emp_phone': 'رقم الهاتف',
      'emp_email': 'البريد الإلكتروني',
      'emp_national_id': 'الرقم القومي',
      'emp_basic_salary': 'الراتب الأساسي الشهري',
      'emp_hire_date': 'تاريخ التعيين',
      'emp_create_title': 'تسجيل موظف جديد',
      'emp_edit_title': 'تعديل بيانات الموظف',
      'emp_assign_title': 'تعيين مكان وجدول العمل',

      // Workplaces
      'wp_title': 'أماكن العمل والنطاق الجغرافي',
      'wp_name': 'اسم مكان العمل',
      'wp_address': 'العنوان الفعلي',
      'wp_radius': 'نصف قطر النطاق الجغرافي (أمتار)',
      'wp_coordinates': 'إحداثيات الموقع GPS',
      'wp_assigned_staff': 'الموظفون المعينون',
      'wp_active_status': 'الحالة التشغيلية',

      // Attendance
      'att_live_feed': 'سجل الحضور الحي',
      'att_check_in': 'تسجيل الدخول',
      'att_check_out': 'تسجيل الخروج',
      'att_punch_time': 'وقت البصمة',
      'att_gps_accuracy': 'دقة نظام GPS',
      'att_distance': 'المسافة عن النطاق الجغرافي',
      'att_status_present': 'حاضر في الموعد',
      'att_status_late': 'تأخير',
      'att_status_absent': 'غياب',
      'att_status_early_leave': 'انصراف مبكر',
      'att_manual_correction': 'تعديل بصمة يدوي',
      'att_offline_review': 'قائمة المراجعة بدون اتصال',

      // Requests
      'req_title': 'طلبات الموظفين والموافقات',
      'req_leave': 'طلب إجازة',
      'req_permission': 'طلب إذن مغادرة',
      'req_advance': 'طلب سلفة مالية',
      'req_attendance_corr': 'طلب تصحيح بصمة',
      'req_review_title': 'مراجعة الطلب',
      'req_reason_mandatory': 'سبب الرفض إلزامي',
      'req_status_pending': 'قيد الانتظار',
      'req_status_approved': 'تمت الموافقة',
      'req_status_rejected': 'مرفوض',

      // Advances
      'adv_title': 'إدارة السلف المالية',
      'adv_amount': 'مبلغ السلفة',
      'adv_installments': 'عدد الأقساط الشهرية',
      'adv_remaining': 'المبلغ المتبقي',
      'adv_cap_info': 'الحد الأقصى للسلفة: 50% من الراتب الأساسي',

      // Deductions
      'ded_title': 'إدارة الخصومات والجزاءات',
      'ded_reason': 'سبب الخصم',
      'ded_period': 'فترة الرواتب',
      'ded_type_penalty': 'جزاء تأديبي',
      'ded_type_advance': 'قسط سلفة مالية',

      // Schedules
      'sch_title': 'إدارة جداول ومواعيد العمل',
      'sch_shift_window': 'فترة الوردية',
      'sch_grace_period': 'فترة السماح (دقائق)',
      'sch_working_days': 'أيام العمل الأسبوعية',

      // Reports
      'rep_title': 'التقارير والإحصائيات التحليلية',
      'rep_attendance_rate': 'معدل الحضور العام',
      'rep_punctuality': 'مؤشر الانضباط والمواعيد',
      'rep_export_csv': 'تصدير CSV',
      'rep_export_pdf': 'تصدير PDF',
      'rep_export_xlsx': 'تصدير Excel',

      // Notifications
      'notif_title': 'إشعارات وتنبيهات الموارد البشرية',
      'notif_new': 'إنشاء إعلان جديد',
      'notif_target_all': 'جميع الموظفين',
      'notif_target_dept': 'قسم محدد',
      'notif_target_wp': 'مكان عمل محدد',
      'notif_confirm_send': 'تأكيد أمان الإرسال الجماعي',

      // Messages
      'msg_title': 'المراسلات الداخلية المباشرة',
      'msg_new_conversation': 'محادثة مباشرة جديدة',
      'msg_unread': 'استفسارات غير مقروءة',
      'msg_resolved': 'محادثات مكتملة',
      'msg_type_message': 'اكتب ردك هنا...',

      // Audit Logs
      'aud_title': 'سجل التدقيق والأمان الإداري',
      'aud_total': 'إجمالي السجلات',
      'aud_security_events': 'أحداث الأمان',
      'aud_admin_actions': 'قرارات الإدارة',
      'aud_failed_ops': 'العمليات المرفوضة',
      'aud_metadata': 'بيانات الحدث المنظمة (Payload)',

      // Settings
      'set_title': 'إعدادات النظام وسياسات العمل',
      'set_general': 'بيانات الشركة والعامة',
      'set_attendance_policy': 'سياسة الحضور والانصراف',
      'set_notifications': 'قواعد التنبيهات',
      'set_security': 'الأمان والجلسات',
      'set_appearance': 'المظهر والطابع المرئي',
      'set_language': 'اللغة والإعدادات الإقليمية',
      'set_language_desc': 'اختر لغة لوحة التحكم المفضلة لديك (English / العربية).',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  String get(String key) => translate(key);

  // ==========================================
  // 2. ENUM & STATUS TRANSLATORS
  // ==========================================

  String translateStatus(String raw) {
    final s = raw.toUpperCase().trim();
    if (isArabic) {
      switch (s) {
        case 'ACTIVE':
          return 'نشط';
        case 'INACTIVE':
          return 'غير نشط';
        case 'SUSPENDED':
          return 'موقوف';
        case 'PENDING':
          return 'قيد الانتظار';
        case 'APPROVED':
          return 'معتمد';
        case 'REJECTED':
          return 'مرفوض';
        case 'CANCELLED':
          return 'ملغي';
        case 'PAID':
          return 'تم السداد';
        case 'OPEN':
          return 'مفتوح';
        case 'RESOLVED':
          return 'تم الحل';
        case 'SENT':
          return 'تم الإرسال';
        case 'SCHEDULED':
          return 'مجدول';
        case 'SUCCESS':
          return 'ناجح';
        case 'FAILURE':
          return 'فشل';
        case 'WARNING':
          return 'تحذير';
        default:
          return raw;
      }
    }
    switch (s) {
      case 'ACTIVE':
        return 'Active';
      case 'INACTIVE':
        return 'Inactive';
      case 'SUSPENDED':
        return 'Suspended';
      case 'PENDING':
        return 'Pending';
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      case 'CANCELLED':
        return 'Cancelled';
      case 'PAID':
        return 'Paid';
      case 'OPEN':
        return 'Open';
      case 'RESOLVED':
        return 'Resolved';
      case 'SENT':
        return 'Sent';
      case 'SCHEDULED':
        return 'Scheduled';
      case 'SUCCESS':
        return 'Success';
      case 'FAILURE':
        return 'Failure';
      case 'WARNING':
        return 'Warning';
      default:
        return raw;
    }
  }

  String translateRole(String role) {
    final r = role.toUpperCase();
    if (isArabic) {
      switch (r) {
        case 'SUPER_ADMIN':
          return 'المدير العام (Super Admin)';
        case 'HR_ADMIN':
          return 'مدير الموارد البشرية (HR Admin)';
        case 'HR_MANAGER':
          return 'مسؤول HR (HR Manager)';
        case 'SUPERVISOR':
          return 'مشرف مباشر (Supervisor)';
        case 'EMPLOYEE':
          return 'موظف (Employee)';
        default:
          return role;
      }
    }
    switch (r) {
      case 'SUPER_ADMIN':
        return 'Super Administrator';
      case 'HR_ADMIN':
        return 'HR Administrator';
      case 'HR_MANAGER':
        return 'HR Manager';
      case 'SUPERVISOR':
        return 'Supervisor';
      case 'EMPLOYEE':
        return 'Employee';
      default:
        return role;
    }
  }

  // ==========================================
  // 3. NUMBER, CURRENCY & DATE FORMATTERS
  // ==========================================

  String formatCurrency(num amount, {String currencyCode = 'EGP'}) {
    final formatter = NumberFormat.currency(
      locale: locale.languageCode,
      symbol: isArabic ? 'ج.م' : 'EGP',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String formatNumber(num value) {
    final formatter = NumberFormat.decimalPattern(locale.languageCode);
    return formatter.format(value);
  }

  String formatDate(DateTime date) {
    try {
      final formatter = DateFormat.yMMMMd(locale.languageCode);
      return formatter.format(date);
    } catch (_) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  String formatDateTime(DateTime date) {
    try {
      final formatter = DateFormat.yMMMd(locale.languageCode).add_jm();
      return formatter.format(date);
    } catch (_) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    await initializeDateFormatting(locale.languageCode);
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
