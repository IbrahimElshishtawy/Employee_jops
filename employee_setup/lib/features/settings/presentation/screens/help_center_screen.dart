import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../widgets/help_faq_item.dart';

class _FaqData {
  final String categoryKey;
  final String questionAr;
  final String questionEn;
  final String answerAr;
  final String answerEn;
  final IconData icon;
  final Color iconColor;

  const _FaqData({
    required this.categoryKey,
    required this.questionAr,
    required this.questionEn,
    required this.answerAr,
    required this.answerEn,
    required this.icon,
    required this.iconColor,
  });
}

/// Help Center Screen with live local search, category filters, and accordion FAQs.
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryKey = 'all';
  String _searchQuery = '';

  static const List<_FaqData> _allFaqs = [
    // 1. Attendance
    _FaqData(
      categoryKey: 'attendance',
      questionAr: 'كيف أسجل الحضور والانصراف اليومي؟',
      questionEn: 'How do I check in and check out daily?',
      answerAr:
          'من الواجهة الرئيسية، اضغط على زر "تسجيل الحضور" أو "تسجيل الانصراف". سيقوم النظام بالتحقق من إحداثيات GPS لتأكيد تواجدك داخل مقر العمل، ثم إجراء المصادقة البيومترية لتأكيد العملية فوراً.',
      answerEn:
          'From the Home screen, tap "Check In" or "Check Out". The app verifies your GPS location within the authorized workplace geofence, followed by biometric verification to confirm the record.',
      icon: Icons.timer_rounded,
      iconColor: AppColors.primary,
    ),
    _FaqData(
      categoryKey: 'attendance',
      questionAr: 'لماذا لا أستطيع تسجيل الحضور وتظهر رسالة خارج النطاق؟',
      questionEn: 'Why am I unable to check in and see an "Out of Range" alert?',
      answerAr:
          'يحدث ذلك عندما تكون إشارة GPS غير دقيقة، أو إذا كنت خارج نطاق مقر العمل المعتمد (الحد الأقصى المصرح به 4 أمتار). تأكد من تفعيل خدمة الموقع والتواجد في مكان مكشوف للحصول على إشارة دقيقة.',
      answerEn:
          'This occurs if GPS accuracy is low or if you are outside the authorized workplace geofence (maximum allowed radius is 4 meters). Ensure GPS is enabled with high accuracy.',
      icon: Icons.location_off_rounded,
      iconColor: Color(0xFFEF4444),
    ),
    _FaqData(
      categoryKey: 'attendance',
      questionAr: 'أين يمكنني مراجعة سجل الحضور وساعات العمل السابقة؟',
      questionEn: 'Where can I view my previous attendance history and work hours?',
      answerAr:
          'يمكنك الانتقال إلى شاشة "سجل الحضور" عبر بطاقة الحضور في الصفحة الرئيسية، حيث ستجد جدولاً تفصيلياً بأوقات الدخول والخروج اليومية وساعات العمل المحتسبة.',
      answerEn:
          'You can navigate to "Attendance History" from the attendance card on the Home screen to view a detailed breakdown of daily check-ins, check-outs, and logged hours.',
      icon: Icons.history_rounded,
      iconColor: Color(0xFF0EA5E9),
    ),

    // 2. Account & Profile
    _FaqData(
      categoryKey: 'account',
      questionAr: 'كيف أقوم بتحديث بيانات ملفي الشخصي؟',
      questionEn: 'How do I update my profile information?',
      answerAr:
          'من القائمة السفلية اختر "الملف الشخصي"، حيث يمكنك استعراض بياناتك الوظيفية، رقم الهاتف، وإعدادات الأمان. لتعديل البيانات الأساسية يرجى تقديم طلب إداري لقسم الموارد البشرية.',
      answerEn:
          'Select "Profile" from the bottom navigation bar to review your employment data, phone number, and security settings. For major data updates, submit a request to HR.',
      icon: Icons.person_outline_rounded,
      iconColor: Color(0xFF10B981),
    ),
    _FaqData(
      categoryKey: 'account',
      questionAr: 'كيف أسجل الخروج من التطبيق؟',
      questionEn: 'How do I log out of the application?',
      answerAr:
          'اذهب إلى شاشة "الملف الشخصي" ثم اضغط على زر "تسجيل الخروج" في أسفل الصفحة وأكّد العملية. سيتطلب تسجيل الدخول مرة أخرى التحقق من حساب Google المعتمد.',
      answerEn:
          'Go to the "Profile" screen, scroll to the bottom and tap "Log Out", then confirm. Signing back in will require authentication with your authorized Google account.',
      icon: Icons.logout_rounded,
      iconColor: Color(0xFF64748B),
    ),

    // 3. Requests
    _FaqData(
      categoryKey: 'requests',
      questionAr: 'كيف أقدم طلب إجازة أو إذن استئذان أو سُلفة مالية؟',
      questionEn: 'How do I submit a vacation, permission, or financial advance request?',
      answerAr:
          'من القائمة السفلية اختر تبويب "الطلبات"، ثم اختر نوع الطلب المطلوب (سُلف، أذونات، إجازات)، واملأ النموذج المخصص بالبيانات والتواريخ والسبب ثم اضغط "إرسال الطلب".',
      answerEn:
          'From the bottom navigation, tap the "Requests" tab, select the request category (Advances, Permissions, Vacations), fill in the required dates and justification, and submit.',
      icon: Icons.assignment_rounded,
      iconColor: Color(0xFF8B5CF6),
    ),
    _FaqData(
      categoryKey: 'requests',
      questionAr: 'كيف أتابع حالة الطلب وقرار الموارد البشرية؟',
      questionEn: 'How do I track my request status and HR approval?',
      answerAr:
          'في شاشة "الطلبات"، يمكنك الضغط على أي طلب سابق للاطلاع على تفاصيله الكاملة، وسلسلة المراجعة الإدارية، وتاريخ الاعتماد أو الرفض مع الملاحظات المرفقة.',
      answerEn:
          'In the "Requests" hub, tap any submitted request to view its complete audit trail, management review status, and attached approval notes.',
      icon: Icons.track_changes_rounded,
      iconColor: Color(0xFFF59E0B),
    ),

    // 4. HR Communication
    _FaqData(
      categoryKey: 'communication',
      questionAr: 'كيف أتواصل مباشرة مع قسم الموارد البشرية أو الإدارات؟',
      questionEn: 'How do I communicate with the HR department or other teams?',
      answerAr:
          'من تبويب "التواصل"، يمكنك استعراض قائمة الأقسام، وبدء محادثة كتابية مباشرة مع مسؤولي وموظفي الموارد البشرية، أو إرسال طلب رسمي موجه لقسم محدد.',
      answerEn:
          'From the "Communication" tab, browse department directories, initiate direct text chats with HR representatives, or submit formal department inquiries.',
      icon: Icons.forum_rounded,
      iconColor: Color(0xFF0EA5E9),
    ),

    // 5. Notifications
    _FaqData(
      categoryKey: 'notifications',
      questionAr: 'لماذا لا تصلني إشعارات التطبيق الفورية؟',
      questionEn: 'Why am I not receiving instant push notifications?',
      answerAr:
          'تأكد من منح إذن الإشعارات للتطبيق من إعدادات الهاتف، وتأكد من اتصال الهاتف بالإنترنت وعدم تفعيل وضع توفير الطاقة الفائق الذي قد يعطل الإشعارات في الخلفية.',
      answerEn:
          'Ensure notification permissions are enabled in your device settings, verify active internet connectivity, and check that extreme battery saver mode is disabled.',
      icon: Icons.notifications_active_rounded,
      iconColor: Color(0xFFF59E0B),
    ),

    // 6. Security & Login
    _FaqData(
      categoryKey: 'security',
      questionAr: 'لماذا يُطلب استخدام البصمة البيومترية لتسجيل الحضور؟',
      questionEn: 'Why is biometric authentication required for attendance?',
      answerAr:
          'تُستخدم البصمة لتأكيد الهوية الشخصية للموظف ومنع تسجيل الحضور نيابة عن الغير، مما يضمن أعلى درجات الموثوقية والعدالة والنزاهة المؤسسية.',
      answerEn:
          'Biometrics ensure positive identity verification and prevent proxy check-ins, upholding organizational integrity and security compliance.',
      icon: Icons.fingerprint_rounded,
      iconColor: Color(0xFF10B981),
    ),
    _FaqData(
      categoryKey: 'security',
      questionAr: 'ماذا أفعل في حال الاشتباه في محاولة دخول غير مصرح بها؟',
      questionEn: 'What should I do if I suspect unauthorized account activity?',
      answerAr:
          'قم بتسجيل الخروج فوراً، وتأمين حساب Google الخاص بك بتغيير كلمة المرور، ثم تواصل مع فريق أمن المعلومات والدعم الفني عبر شاشة الدعم للإبلاغ الفوري.',
      answerEn:
          'Log out immediately, secure your Google corporate account with a password update, and report the incident to IT Support via the Support screen.',
      icon: Icons.security_rounded,
      iconColor: Color(0xFFEF4444),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_FaqData> _getFilteredFaqs(bool isArabic) {
    return _allFaqs.where((faq) {
      // Category filter
      if (_selectedCategoryKey != 'all' && faq.categoryKey != _selectedCategoryKey) {
        return false;
      }

      // Search query filter
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();

      final question = isArabic ? faq.questionAr.toLowerCase() : faq.questionEn.toLowerCase();
      final answer = isArabic ? faq.answerAr.toLowerCase() : faq.answerEn.toLowerCase();

      return question.contains(q) || answer.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isArabic = context.isArabic;
    final filteredFaqs = _getFilteredFaqs(isArabic);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppHeader(
        title: context.tr('help.title'),
        subtitle: context.tr('help.header_subtitle'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Search & Category Filter Header
            _buildSearchAndFilterHeader(context, isDark),

            // FAQs List
            Expanded(
              child: filteredFaqs.isEmpty
                  ? _buildEmptyState(context, isDark)
                  : ListView.builder(
                      padding: AppDimensions.pagePadding,
                      itemCount: filteredFaqs.length + 1,
                      itemBuilder: (context, index) {
                        if (index == filteredFaqs.length) {
                          // Bottom Support CTA
                          return _buildSupportCtaCard(context, isDark);
                        }

                        final faq = filteredFaqs[index];
                        final categoryLabel = _getCategoryLabel(context, faq.categoryKey);
                        final question = isArabic ? faq.questionAr : faq.questionEn;
                        final answer = isArabic ? faq.answerAr : faq.answerEn;

                        return HelpFaqItem(
                          category: categoryLabel,
                          question: question,
                          answer: answer,
                          icon: faq.icon,
                          iconColor: faq.iconColor,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterHeader(BuildContext context, bool isDark) {
    final categories = [
      {'key': 'all', 'label': context.tr('help.all_categories')},
      {'key': 'attendance', 'label': context.tr('help.cat_attendance')},
      {'key': 'account', 'label': context.tr('help.cat_account')},
      {'key': 'requests', 'label': context.tr('help.cat_requests')},
      {'key': 'communication', 'label': context.tr('help.cat_communication')},
      {'key': 'notifications', 'label': context.tr('help.cat_notifications')},
      {'key': 'security', 'label': context.tr('help.cat_security')},
    ];

    return Container(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input Bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: context.tr('help.search_placeholder'),
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Categories Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategoryKey == cat['key'];
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8.0),
                  child: FilterChip(
                    label: Text(cat['label']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryKey = cat['key']!;
                      });
                    },
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                    backgroundColor:
                        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                    selectedColor: AppColors.primary,
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('help.no_results_title'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('help.no_results_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: context.isArabic ? 'إعادة ضبط البحث' : 'Clear Search',
              variant: AppButtonVariant.outline,
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedCategoryKey = 'all';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCtaCard(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('help.still_need_help'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.isArabic
                            ? 'فريق الدعم الفني جاهز لمساعدتك وحل المشكلات.'
                            : 'Our technical support team is ready to assist you.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppButton(
              label: context.tr('help.contact_support_cta'),
              icon: Icons.arrow_forward_rounded,
              onPressed: () => context.push(AppRoutes.support),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(BuildContext context, String key) {
    switch (key) {
      case 'attendance':
        return context.tr('help.cat_attendance');
      case 'account':
        return context.tr('help.cat_account');
      case 'requests':
        return context.tr('help.cat_requests');
      case 'communication':
        return context.tr('help.cat_communication');
      case 'notifications':
        return context.tr('help.cat_notifications');
      case 'security':
        return context.tr('help.cat_security');
      default:
        return context.tr('help.all_categories');
    }
  }
}
