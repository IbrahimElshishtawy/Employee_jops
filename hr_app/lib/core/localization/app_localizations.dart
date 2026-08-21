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

      // Dashboard
      'dash_welcome': 'Welcome to CyberWise IE HR Portal',
      'dash_welcome_sub': 'Monitor workforce operations, attendance, leaves, and approvals in real-time.',
      'dash_new_employee': 'New Employee',
      'dash_total_workforce': 'Total Workforce',
      'dash_active_roster': 'Active roster',
      'dash_present_today': 'Present Today',
      'dash_on_time': 'on-time',
      'dash_late_arrivals': 'Late Arrivals',
      'dash_today_records': 'Today records',
      'dash_absent': 'Absent',
      'dash_absent_sub': 'Unexcused / Leave',
      'dash_pending_requests': 'Pending Requests',
      'dash_requires_action': 'Requires action',
      'dash_pending_advances': 'Pending Advances',
      'dash_salary_requests': 'Salary requests',
      'dash_checkins_today': 'Today Check-ins',
      'dash_clockin_logs': 'Clock-in logs',
      'dash_checkouts_today': 'Today Check-outs',
      'dash_clockout_logs': 'Clock-out logs',
      'dash_chart_title': 'Daily Attendance Distribution',
      'dash_chart_sub': 'Live status breakdown across all registered company workplaces',
      'dash_present_count': 'Present',
      'dash_late_count': 'Late',
      'dash_absent_count': 'Absent',

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
      'emp_joined_date': 'Joined Date',
      'emp_dept_role': 'Department & Role',
      'emp_create_title': 'Register New Employee',
      'emp_edit_title': 'Edit Employee Profile',
      'emp_assign_title': 'Assign Workplace & Schedule',
      'emp_directory_subtitle': 'Manage employee profiles, assignments, attendance logs, and operational records',
      'emp_add_btn': 'Add Employee',
      'emp_all_departments': 'All Departments',
      'emp_all_workplaces': 'All Workplaces',
      'emp_all_statuses': 'All Statuses',
      'emp_view_profile': 'View Full Profile',
      'emp_edit': 'Edit Employee',
      'emp_assign': 'Assign Workplace / Schedule',
      'emp_status_management': 'Status Management',
      'emp_activate': 'Activate',
      'emp_suspend': 'Suspend',
      'emp_deactivate': 'Deactivate',
      'emp_confirm_status_change': 'Confirm Status Change',
      'emp_confirm_status_msg': 'Are you sure you want to change the status of this employee?',

      // Workplaces
      'wp_title': 'Workplaces & Geofencing',
      'wp_total': 'Total Workplaces',
      'wp_active_geofences': 'Active Geofences',
      'wp_polygon_boundaries': 'Polygon Boundaries',
      'wp_circle_radii': 'Circle Radii',
      'wp_name': 'Workplace Name',
      'wp_address': 'Physical Address',
      'wp_radius': 'Geofence Radius (Meters)',
      'wp_coordinates': 'GPS Coordinates',
      'wp_assigned_staff': 'Assigned Employees',
      'wp_active_status': 'Operational Status',
      'wp_add_btn': 'Add Workplace',
      'wp_name_loc': 'Workplace Name & Location',
      'wp_geofence_model': 'Geofence Model',
      'wp_boundary_specs': 'Boundary Specs',
      'wp_preview_btn': 'Preview & Test Boundary',
      'wp_assign_staff': 'Assign Staff',
      'wp_edit': 'Edit Geofence',
      'wp_delete': 'Delete Workplace',
      'wp_all_types': 'All Geofence Types',
      'wp_active_only': 'Active Only',
      'wp_inactive_only': 'Inactive Only',

      // Attendance
      'att_title': 'Attendance Control Center',
      'att_subtitle': 'Monitor employee punches, GPS accuracy, geofence compliance, and security signals',
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
      'att_manual_correction': 'Manual Correction',
      'att_export_report': 'Export Report',
      'att_offline_review': 'Offline Punch Queue',
      'att_early_dep': 'Early Departures',
      'att_offline_pending': 'Offline Pending',
      'att_security_flags': 'Security Flags',
      'att_date_filter': 'Date Filter:',
      'att_all_security': 'All Security States',
      'att_date_shift': 'Date & Shift',
      'att_sec_integrity': 'Security & Integrity',
      'att_view_telemetry': 'View Full Telemetry & Timeline',
      'att_review_offline': 'Review Offline Submission',
      'att_verified_secure': 'Verified Secure',
      'att_security_flagged': 'Security Flagged',

      // Requests
      'req_title': 'Employee Requests & Approvals',
      'req_subtitle': 'Review and process employee leave, permissions, late arrivals, and absence requests',
      'req_leave': 'Leave Request',
      'req_permission': 'Permission Request',
      'req_advance': 'Salary Advance Request',
      'req_attendance_corr': 'Attendance Correction',
      'req_review_title': 'Review Request',
      'req_reason_mandatory': 'Rejection reason is required',
      'req_status_pending': 'Pending Review',
      'req_status_approved': 'Approved',
      'req_status_rejected': 'Rejected',
      'req_status_cancelled': 'Cancelled',
      'req_all_types': 'All Request Types',
      'req_period_time': 'Period / Time',
      'req_reason_just': 'Reason Justification',
      'req_submitted_at': 'Submitted At',
      'req_approve_btn': 'Approve Request',
      'req_reject_btn': 'Reject Request',

      // Advances
      'adv_title': 'Salary Advances Management',
      'adv_subtitle': 'Review employee advance requests, monitor installment schedules, and track outstanding balances',
      'adv_amount': 'Advance Amount',
      'adv_installments': 'Monthly Installments',
      'adv_remaining': 'Remaining Balance',
      'adv_cap_info': 'Maximum advance limit: 50% of basic salary',
      'adv_active_disbursed': 'Active Disbursed',
      'adv_approved_volume': 'Approved Volume',
      'adv_outstanding_balance': 'Outstanding Balance',
      'adv_all_statuses': 'All Advance Statuses',
      'adv_req_vs_app': 'Requested vs Approved',
      'adv_installments_col': 'Installments',
      'adv_remaining_col': 'Remaining Balance',
      'adv_request_date': 'Request Date',
      'adv_view_schedule': 'View Details & Schedule',
      'adv_approve_btn': 'Approve Advance',
      'adv_reject_btn': 'Reject Advance',

      // Deductions
      'ded_title': 'Payroll Deductions Management',
      'ded_subtitle': 'Track scheduled salary deductions, advance installment recoveries, and attendance adjustments',
      'ded_reason': 'Deduction Reason',
      'ded_period': 'Payroll Period',
      'ded_type_penalty': 'Disciplinary Penalty',
      'ded_type_advance': 'Advance Installment',
      'ded_new_btn': 'New Deduction',
      'ded_scheduled_ded': 'Scheduled Deductions',
      'ded_applied_payroll': 'Applied in Payroll',
      'ded_advance_rec': 'Advance Recoveries',
      'ded_workforce_pen': 'Workforce Penalties',
      'ded_all_types': 'All Deduction Types',
      'ded_cancel_btn': 'Cancel / Waive',

      // Schedules
      'sch_title': 'Work Schedules & Shift Management',
      'sch_subtitle': 'Define operational working hours, grace periods, and working day configurations for workforce attendance',
      'sch_shift_window': 'Shift Window',
      'sch_grace_period': 'Grace Period (Mins)',
      'sch_working_days': 'Working Days',
      'sch_new_btn': 'New Schedule',
      'sch_active_shifts': 'Active Shifts',
      'sch_total_schedules': 'Total Schedules',
      'sch_assigned_workforce': 'Assigned Workforce',
      'sch_inactive_shifts': 'Inactive Shifts',
      'sch_all_working_days': 'All Working Days',
      'sch_name_col': 'Schedule Name',
      'sch_working_hours': 'Working Hours',
      'sch_view_details': 'View Details & Rules',
      'sch_edit': 'Edit Schedule',

      // Reports
      'rep_title': 'Executive Reports & Workforce Analytics',
      'rep_subtitle': 'Aggregated workforce attendance, punctuality trends, late arrival audits, and financial summaries',
      'rep_attendance_rate': 'Attendance Rate',
      'rep_punctuality': 'Punctuality Index',
      'rep_late_incidents': 'Late Arrivals Count',
      'rep_export_pdf': 'Export PDF Report',
      'rep_export_excel': 'Export Excel Sheet',
      'rep_export_btn': 'Export Report',
      'rep_late_arrivals': 'Late Arrivals',
      'rep_absences': 'Absences',
      'rep_pending_requests': 'Pending Requests',
      'rep_total_advances': 'Salary Advances',
      'rep_total_deductions': 'Total Deductions',
      'rep_presence_breakdown': 'Today\'s Workforce Presence Breakdown',
      'rep_on_time': 'On-Time',
      'rep_late': 'Late',
      'rep_absent': 'Absent',
      'rep_present_headcount': 'Present Headcount',
      'rep_early_checkouts': 'Early Checkouts',
      'rep_scheduled_start': 'Scheduled Start',
      'rep_actual_checkin': 'Actual Check-in',
      'rep_late_duration': 'Late Duration',
      'rep_permission_status': 'Permission Status',
      'rep_excused': 'Excused',
      'rep_unexcused': 'Unexcused',
      'rep_disbursed_advances': 'Disbursed Salary Advances',
      'rep_collected_deductions': 'Collected Deductions',
      'rep_net_recovery': 'Net Recovery Balance',

      // Notifications
      'notif_title': 'HR Notifications & Announcements Management',
      'notif_subtitle': 'Broadcast company notices, manage system alerts, and track push delivery status to employee devices',
      'notif_new': 'New Announcement',
      'notif_broadcast': 'Dispatch Broadcast',
      'notif_unread_only': 'Unread Only',
      'notif_mark_all_read': 'Mark All Read',
      'notif_total': 'Total Notifications',
      'notif_sent': 'Sent Broadcasts',
      'notif_scheduled': 'Scheduled',
      'notif_unread': 'Unread Alerts',
      'notif_all_categories': 'All Categories',
      'notif_title_col': 'Notification Title & Message',
      'notif_category_col': 'Category',
      'notif_target_col': 'Target Audience',
      'notif_date_col': 'Date & Time',
      'notif_read_count': 'Read Count',
      'notif_target_all': 'All Employees',
      'notif_target_dept': 'Specific Department',
      'notif_target_wp': 'Specific Workplace',
      'notif_confirm_send': 'Broadcast Safety Confirmation',

      // Messages
      'msg_title': 'HR Internal Communications & Direct Messages',
      'msg_subtitle': 'Direct two-way messaging with employees, inquiry resolution, and staff assistance',
      'msg_new_thread': 'New Conversation',
      'msg_resolved': 'Inquiry Resolved',
      'msg_reopen': 'Reopen Inquiry',
      'msg_type_placeholder': 'Type your message... (Press Enter)',
      'msg_new_btn': 'New Direct Message',
      'msg_total_conv': 'Total Conversations',
      'msg_unread_inquiries': 'Unread Inquiries',
      'msg_unread_messages': 'Unread Messages',
      'msg_resolved_threads': 'Resolved Threads',
      'msg_no_conversations': 'No conversations found.',
      'msg_select_conversation': 'Select a conversation from the list to view message history and reply.',
      'msg_type_hint': 'Type your message...',

      // Audit Logs
      'aud_title': 'System Audit Logs & Security Trail',
      'aud_subtitle': 'Immutable, tamper-evident audit records of all administrative HR decisions and security events',
      'aud_tamper_evident': 'TAMPER-EVIDENT READ-ONLY',
      'aud_total': 'Total Logs',
      'aud_security_events': 'Security Events',
      'aud_admin_actions': 'Admin Actions',
      'aud_failed_ops': 'Failed Operations',
      'aud_all_categories': 'All Categories',
      'aud_timestamp': 'Timestamp',
      'aud_actor': 'Actor (User)',
      'aud_action_performed': 'Action Performed',
      'aud_target_entity': 'Target Entity',
      'aud_ip_address': 'IP Address',
      'aud_result': 'Result',
      'aud_inspect': 'Inspect Audit Record & Metadata',
      'aud_metadata': 'Structured Event Payload (Metadata)',

      // Settings
      'set_title': 'HR Portal Settings & System Policies',
      'set_subtitle': 'System runtime configuration, organization parameters, attendance rules, and security controls',
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
      'nav_reports': 'التقارير والتحليلات',
      'nav_notifications': 'الإشعارات والتنبيهات',
      'nav_messages': 'الرسائل والمراسلات الداخلية',
      'nav_audit_logs': 'سجل التدقيق والأمان',
      'nav_settings': 'إعدادات النظام',
      'nav_logout': 'تسجيل الخروج',

      // Dashboard
      'dash_welcome': 'مرحبًا بك في منصة سايبر وايز لإدارة الموارد البشرية',
      'dash_welcome_sub': 'متابعة العمليات والقوى العاملة والحضور والانصراف والإجازات في الوقت الفعلي.',
      'dash_new_employee': 'موظف جديد',
      'dash_total_workforce': 'إجمالي القوى العاملة',
      'dash_active_roster': 'الكادر الفعال',
      'dash_present_today': 'الحاضرون اليوم',
      'dash_on_time': 'في الموعد المحدد',
      'dash_late_arrivals': 'المتأخرون عن العمل',
      'dash_today_records': 'سجلات اليوم',
      'dash_absent': 'الغياب اليوم',
      'dash_absent_sub': 'غير مبرر / إجازة',
      'dash_pending_requests': 'الطلبات المعلقة',
      'dash_requires_action': 'تتطلب إجراءات مراجعة',
      'dash_pending_advances': 'السلف المعلقة',
      'dash_salary_requests': 'طلبات السلف المالية',
      'dash_checkins_today': 'تسجيلات الحضور',
      'dash_clockin_logs': 'سجلات الدخول اليوم',
      'dash_checkouts_today': 'تسجيلات الانصراف',
      'dash_clockout_logs': 'سجلات الخروج اليوم',
      'dash_chart_title': 'توزيع نسب الحضور اليومي',
      'dash_chart_sub': 'توزيع مباشر لحالات الحضور في جميع مواقع العمل المسجلة',
      'dash_present_count': 'حاضر',
      'dash_late_count': 'متأخر',
      'dash_absent_count': 'غائب',

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
      'emp_joined_date': 'تاريخ الانضمام',
      'emp_dept_role': 'القسم والمسمى الوظيفي',
      'emp_create_title': 'تسجيل موظف جديد',
      'emp_edit_title': 'تعديل بيانات الموظف',
      'emp_assign_title': 'تعيين مكان وجدول العمل',
      'emp_directory_subtitle': 'إدارة ملفات الموظفين والتكليفات وسجلات الحضور والعمليات التشغيلية',
      'emp_add_btn': 'إضافة موظف',
      'emp_all_departments': 'جميع الأقسام',
      'emp_all_workplaces': 'جميع أماكن العمل',
      'emp_all_statuses': 'جميع الحالات',
      'emp_view_profile': 'عرض الملف التعريفي',
      'emp_edit': 'تعديل بيانات الموظف',
      'emp_assign': 'تعيين مكان العمل / الجدول',
      'emp_status_management': 'إدارة الحالة الوظيفية',
      'emp_activate': 'تنشيط',
      'emp_suspend': 'إيقاف مؤقت',
      'emp_deactivate': 'تعطيل الحساب',
      'emp_confirm_status_change': 'تأكيد تغيير الحالة',
      'emp_confirm_status_msg': 'هل أنت متأكد من رغبتك في تغيير حالة هذا الموظف؟',

      // Workplaces
      'wp_title': 'أماكن العمل والنطاق الجغرافي',
      'wp_total': 'إجمالي أماكن العمل',
      'wp_active_geofences': 'نطاقات جغرافية نشطة',
      'wp_polygon_boundaries': 'نطاقات مضلعة متقدمة',
      'wp_circle_radii': 'نطاقات دائرية نصف قطرية',
      'wp_name': 'اسم مكان العمل',
      'wp_address': 'العنوان الفعلي',
      'wp_radius': 'نصف قطر النطاق الجغرافي (أمتار)',
      'wp_coordinates': 'إحداثيات الموقع GPS',
      'wp_assigned_staff': 'الموظفون المعينون',
      'wp_active_status': 'الحالة التشغيلية',
      'wp_add_btn': 'إضافة مكان عمل',
      'wp_name_loc': 'اسم وموقع مكان العمل',
      'wp_geofence_model': 'نوع النطاق الجغرافي',
      'wp_boundary_specs': 'المواصفات والأبعاد',
      'wp_preview_btn': 'معاينة واختبار النطاق',
      'wp_assign_staff': 'تخصيص موظفين',
      'wp_edit': 'تعديل النطاق',
      'wp_delete': 'حذف مكان العمل',
      'wp_all_types': 'جميع أنواع النطاقات',
      'wp_active_only': 'النشط فقط',
      'wp_inactive_only': 'غير النشط فقط',

      // Attendance
      'att_title': 'مركز التحكم في الحضور والانصراف',
      'att_subtitle': 'متابعة بصمات الموظفين ودقة الـ GPS ومطابقة النطاق الجغرافي والإشارات الأمنية',
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
      'att_manual_correction': 'تعديل يدوي',
      'att_export_report': 'تصدير التقرير',
      'att_offline_review': 'قائمة المراجعة بدون اتصال',
      'att_early_dep': 'انصراف مبكر',
      'att_offline_pending': 'معلقة بدون اتصال',
      'att_security_flags': 'تنبيهات أمنية',
      'att_date_filter': 'تصفية بالتاريخ:',
      'att_all_security': 'جميع الحالات الأمنية',
      'att_date_shift': 'التاريخ والوردية',
      'att_sec_integrity': 'الأمان والنزاهة',
      'att_view_telemetry': 'عرض القياسات والسجل الزمني',
      'att_review_offline': 'مراجعة البصمة غير المتصلة',
      'att_verified_secure': 'تم التحقق بأمان',
      'att_security_flagged': 'تحذير أمني',

      // Requests
      'req_title': 'طلبات الموظفين والموافقات',
      'req_subtitle': 'مراجعة ومعالجة طلبات الإجازات والأذونات والتأخيرات وتبريرات الغياب',
      'req_leave': 'طلب إجازة',
      'req_permission': 'طلب إذن مغادرة',
      'req_advance': 'طلب سلفة مالية',
      'req_attendance_corr': 'طلب تصحيح بصمة',
      'req_review_title': 'مراجعة الطلب',
      'req_reason_mandatory': 'سبب الرفض إلزامي',
      'req_status_pending': 'قيد الانتظار',
      'req_status_approved': 'تمت الموافقة',
      'req_status_rejected': 'مرفوض',
      'req_status_cancelled': 'ملغى',
      'req_all_types': 'جميع أنواع الطلبات',
      'req_period_time': 'الفترة / الوقت',
      'req_reason_just': 'السبب والمبرر',
      'req_submitted_at': 'تاريخ التقديم',
      'req_approve_btn': 'اعتماد الطلب',
      'req_reject_btn': 'رفض الطلب',

      // Advances
      'adv_title': 'إدارة السلف المالية',
      'adv_subtitle': 'مراجعة طلبات السلف ومتابعة جداول الأقساط الشهرية والأرصدة المتبقية',
      'adv_amount': 'مبلغ السلفة',
      'adv_installments': 'عدد الأقساط الشهرية',
      'adv_remaining': 'المبلغ المتبقي',
      'adv_cap_info': 'الحد الأقصى للسلفة: 50% من الراتب الأساسي',
      'adv_active_disbursed': 'سلف جارية ومصروفة',
      'adv_approved_volume': 'إجمالي السلف المعتمدة',
      'adv_outstanding_balance': 'المبلغ المتبقي للتحصيل',
      'adv_all_statuses': 'جميع حالات السلف',
      'adv_req_vs_app': 'المطلوب مقابل المعتمد',
      'adv_installments_col': 'الأقساط',
      'adv_remaining_col': 'المبلغ المتبقي',
      'adv_request_date': 'تاريخ الطلب',
      'adv_view_schedule': 'عرض التفاصيل والجدول',
      'adv_approve_btn': 'اعتماد السلفة',
      'adv_reject_btn': 'رفض السلفة',

      // Deductions
      'ded_title': 'إدارة الخصومات والجزاءات',
      'ded_subtitle': 'متابعة الخصومات المجدولة واسترداد أقساط السلف وتسويات الحضور',
      'ded_reason': 'سبب الخصم',
      'ded_period': 'فترة الرواتب',
      'ded_type_penalty': 'جزاء تأديبي',
      'ded_type_advance': 'قسط سلفة مالية',
      'ded_new_btn': 'خصم جديد',
      'ded_scheduled_ded': 'خصومات مجدولة',
      'ded_applied_payroll': 'مطبقة في الرواتب',
      'ded_advance_rec': 'استرداد سلف',
      'ded_workforce_pen': 'جزاءات الموظفين',
      'ded_all_types': 'جميع أنواع الخصومات',
      'ded_cancel_btn': 'إلغاء / إعفاء',

      // Schedules
      'sch_title': 'إدارة جداول ومواعيد العمل',
      'sch_subtitle': 'تحديد ساعات العمل الرسمية وفترات السماح وأيام العمل لتنظيم حضور الموظفين',
      'sch_shift_window': 'فترة الوردية',
      'sch_grace_period': 'فترة السماح (دقائق)',
      'sch_working_days': 'أيام العمل الأسبوعية',
      'sch_new_btn': 'جدول جديد',
      'sch_active_shifts': 'ورديات نشطة',
      'sch_total_schedules': 'إجمالي الجداول',
      'sch_assigned_workforce': 'القوى العاملة المسكنة',
      'sch_inactive_shifts': 'ورديات معطلة',
      'sch_all_working_days': 'جميع أيام العمل',
      'sch_name_col': 'اسم الجدول',
      'sch_working_hours': 'ساعات العمل',
      'sch_view_details': 'عرض التفاصيل والقواعد',
      'sch_edit': 'تعديل الجدول',

      // Reports
      'rep_title': 'التقارير التنفيذية وإحصائيات القوى العاملة',
      'rep_subtitle': 'إحصائيات مجمعة للحضور والانضباط، وتحليل التأخيرات والملخصات المالية',
      'rep_attendance_rate': 'معدل الحضور',
      'rep_punctuality': 'مؤشر الانضباط',
      'rep_late_incidents': 'عدد حالات التأخير',
      'rep_export_csv': 'تصدير CSV',
      'rep_export_pdf': 'تصدير PDF',
      'rep_export_xlsx': 'تصدير Excel',
      'rep_export_btn': 'تصدير التقرير',
      'rep_late_arrivals': 'حالات التأخير',
      'rep_absences': 'الغياب',
      'rep_pending_requests': 'طلبات معلقة',
      'rep_total_advances': 'إجمالي السلف',
      'rep_total_deductions': 'إجمالي الخصومات',
      'rep_presence_breakdown': 'تفصيل حضور القوى العاملة اليوم',
      'rep_on_time': 'في الموعد',
      'rep_late': 'متأخر',
      'rep_absent': 'غائب',
      'rep_present_headcount': 'عدد الحاضرين',
      'rep_early_checkouts': 'انصراف مبكر',
      'rep_scheduled_start': 'بداية الوردية',
      'rep_actual_checkin': 'الحضور الفعلي',
      'rep_late_duration': 'مدة التأخير',
      'rep_permission_status': 'حالة الإذن',
      'rep_excused': 'مقبول بعذر',
      'rep_unexcused': 'بدون عذر',
      'rep_disbursed_advances': 'السلف المصروفة',
      'rep_collected_deductions': 'الخصومات المحصلة',
      'rep_net_recovery': 'صافي رصيد الاسترداد',

      // Notifications
      'notif_title': 'إدارة إعلانات وإشعارات الموارد البشرية',
      'notif_subtitle': 'بث الإعلانات الرسمية، وإدارة تنبيهات النظام، ومتابعة حالة وصول الإشعارات لأجهزة الموظفين',
      'notif_new': 'إعلان جديد',
      'notif_broadcast': 'إرسال البث',
      'notif_unread_only': 'غير المقروءة فقط',
      'notif_mark_all_read': 'تحديد الكل كمقروء',
      'notif_total': 'إجمالي الإشعارات',
      'notif_sent': 'إعلانات مرسلة',
      'notif_scheduled': 'مجدولة',
      'notif_unread': 'تنبيهات غير مقروءة',
      'notif_all_categories': 'جميع التصنيفات',
      'notif_title_col': 'عنوان الإشعار والرسالة',
      'notif_category_col': 'التصنيف',
      'notif_target_col': 'الجمهور المستهدف',
      'notif_date_col': 'التاريخ والوقت',
      'notif_read_count': 'مرات القراءة',
      'notif_target_all': 'جميع الموظفين',
      'notif_target_dept': 'قسم محدد',
      'notif_target_wp': 'مكان عمل محدد',
      'notif_confirm_send': 'تأكيد أمان الإرسال الجماعي',

      // Messages
      'msg_title': 'المراسلات الداخلية والرسائل المباشرة',
      'msg_subtitle': 'مراسلة مباشرة مع الموظفين لحل الاستفسارات وتقديم الدعم',
      'msg_new_thread': 'محادثة جديدة',
      'msg_resolved': 'محادثات مكتملة',
      'msg_reopen': 'إعادة فتح الاستفسار',
      'msg_type_placeholder': 'اكتب رسالتك هنا... (اضغط Enter للإرسال)',
      'msg_new_btn': 'رسالة جديدة',
      'msg_total_conv': 'إجمالي المحادثات',
      'msg_unread_inquiries': 'استفسارات غير مقروءة',
      'msg_unread_messages': 'رسائل غير مقروءة',
      'msg_resolved_threads': 'محادثات مكتملة',
      'msg_no_conversations': 'لم يتم العثور على محادثات.',
      'msg_select_conversation': 'اختر محادثة من القائمة لعرض السجل والرد.',
      'msg_type_hint': 'اكتب رسالتك هنا...',

      // Audit Logs
      'aud_title': 'سجل التدقيق والأمان الإداري',
      'aud_subtitle': 'سجلات تدقيق غير قابلة للتعديل لجميع القرارات الإدارية وأحداث الأمان',
      'aud_tamper_evident': 'سجل محمي ضد التلاعب للقراءة فقط',
      'aud_total': 'إجمالي السجلات',
      'aud_security_events': 'أحداث الأمان',
      'aud_admin_actions': 'قرارات الإدارة',
      'aud_failed_ops': 'العمليات المرفوضة',
      'aud_all_categories': 'جميع التصنيفات',
      'aud_timestamp': 'التوقيت',
      'aud_actor': 'المستخدم (المنفذ)',
      'aud_action_performed': 'الإجراء المتخذ',
      'aud_target_entity': 'العنصر المستهدف',
      'aud_ip_address': 'عنوان IP',
      'aud_result': 'النتيجة',
      'aud_inspect': 'فحص سجل التدقيق والبيانات',
      'aud_metadata': 'بيانات الحدث المنظمة (Payload)',

      // Settings
      'set_title': 'إعدادات النظام وسياسات العمل',
      'set_subtitle': 'إعدادات تشغيل النظام، وبيانات المنشأة، وقواعد الحضور، وعناصر التحكم الأمني',
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
  String t(String key) => translate(key);

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
