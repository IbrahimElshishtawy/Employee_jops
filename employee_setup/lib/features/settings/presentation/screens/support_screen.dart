import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/mock/seeds/onboarding_catalog.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_badge.dart';

class _SupportTicketItem {
  final String id;
  final String problemType;
  final String subject;
  final String description;
  final DateTime createdAt;
  final BadgeStatus status;
  final String statusText;
  final bool hasAttachment;

  const _SupportTicketItem({
    required this.id,
    required this.problemType,
    required this.subject,
    required this.description,
    required this.createdAt,
    required this.status,
    required this.statusText,
    this.hasAttachment = false,
  });
}

/// Comprehensive Support & Issue Reporting screen.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedProblemType;
  bool _hasAttachment = false;
  bool _isSubmitting = false;

  final List<_SupportTicketItem> _tickets = [
    _SupportTicketItem(
      id: 'TCK-2026-042',
      problemType: 'مشكلة في تسجيل الحضور أو إشارة GPS',
      subject: 'تأخر التقاط إشارة GPS داخل المكتب',
      description: 'أحياناً يستغرق فحص الموقع الجغرافي وقتاً طويلاً عند الدخول من البوابة الشرقية.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      status: BadgeStatus.completed,
      statusText: 'تم الحل',
      hasAttachment: true,
    ),
    _SupportTicketItem(
      id: 'TCK-2026-089',
      problemType: 'مشكلة في تقديم أو متابعة الطلبات',
      subject: 'طلب تعديل رصيد الإجازات السنوية',
      description: 'تم تقديم طلب إجازة ولم يظهر تحديث الرصيد المتبقي مباشرة في الواجهة.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: BadgeStatus.pending,
      statusText: 'قيد المعالجة',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProblemType == null) {
      context.showSnackBar(context.tr('support.problem_type_hint'), isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final newTicketId = 'TCK-2026-${100 + _tickets.length + 1}';
    final newTicket = _SupportTicketItem(
      id: newTicketId,
      problemType: _selectedProblemType!,
      subject: _subjectController.text.trim(),
      description: _descriptionController.text.trim(),
      createdAt: DateTime.now(),
      status: BadgeStatus.pending,
      statusText: context.tr('support.status_open'),
      hasAttachment: _hasAttachment,
    );

    setState(() {
      _tickets.insert(0, newTicket);
      _isSubmitting = false;
      _subjectController.clear();
      _descriptionController.clear();
      _selectedProblemType = null;
      _hasAttachment = false;
    });

    _showSuccessDialog(newTicketId);
  }

  void _showSuccessDialog(String ticketId) {
    final isDark = context.isDark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr('support.submit_success_title'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('support.submit_success_msg'),
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    context.tr('support.ticket_id'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ticketId,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _tabController.animateTo(1); // Switch to My Reports tab
            },
            child: Text(
              context.tr('support.history_tab'),
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              context.tr('common.back'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppHeader(
        title: context.tr('support.title'),
        subtitle: context.tr('support.header_subtitle'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick Communication Channels Banner
            _buildQuickChannelsBanner(context, isDark),

            // Tab Bar
            Container(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor:
                    isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    text: context.tr('support.report_tab'),
                  ),
                  Tab(
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    text: '${context.tr('support.history_tab')} (${_tickets.length})',
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Report Problem Form
                  _buildReportForm(context, isDark),

                  // Tab 2: My Reports / Ticket History
                  _buildTicketHistory(context, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChannelsBanner(BuildContext context, bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
              onTap: () => context.push(AppRoutes.departments),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.forum_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('support.direct_chat_title'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          context.tr('support.direct_chat_desc'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
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
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.email_outlined, color: Color(0xFF0EA5E9), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('support.official_email_title'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          OnboardingCatalog.hrContact.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportForm(BuildContext context, bool isDark) {
    final problemTypes = [
      context.tr('support.type_login'),
      context.tr('support.type_attendance'),
      context.tr('support.type_profile'),
      context.tr('support.type_requests'),
      context.tr('support.type_notifications'),
      context.tr('support.type_app_error'),
      context.tr('support.type_other'),
    ];

    return SingleChildScrollView(
      padding: AppDimensions.pagePadding,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Problem Type Dropdown Card
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('support.problem_type'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedProblemType,
                        hint: Text(
                          context.tr('support.problem_type_hint'),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                        dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                        items: problemTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedProblemType = val),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Subject Input Field
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('support.subject'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _subjectController,
                    hintText: context.tr('support.subject_hint'),
                    prefixIcon: const Icon(Icons.title_rounded, size: 20),
                    validator: (val) {
                      if (val == null || val.trim().length < 3) {
                        return context.tr('support.subject_required');
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Description Multiline Field
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('support.description'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _descriptionController,
                    hintText: context.tr('support.description_hint'),
                    maxLines: 4,
                    validator: (val) {
                      if (val == null || val.trim().length < 10) {
                        return context.tr('support.description_required');
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Attachment Option Card
            AppCard(
              padding: const EdgeInsets.all(16),
              onTap: () {
                setState(() => _hasAttachment = !_hasAttachment);
                context.showSnackBar(
                  _hasAttachment
                      ? context.tr('support.attachment_added')
                      : (context.isArabic ? 'تمت إزالة المرفق' : 'Attachment removed'),
                );
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _hasAttachment
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _hasAttachment ? Icons.check_circle_rounded : Icons.attach_file_rounded,
                      color: _hasAttachment ? AppColors.success : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('support.attachment'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _hasAttachment
                              ? 'screenshot_diagnostic_log.png (1.2 MB)'
                              : context.tr('support.attachment_hint'),
                          style: TextStyle(
                            fontSize: 11,
                            color: _hasAttachment
                                ? AppColors.success
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _hasAttachment ? Icons.delete_outline_rounded : Icons.add_photo_alternate_outlined,
                    size: 20,
                    color: _hasAttachment ? Colors.redAccent : AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            AppButton(
              label: context.tr('support.submit_report'),
              icon: Icons.send_rounded,
              isLoading: _isSubmitting,
              onPressed: _submitReport,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketHistory(BuildContext context, bool isDark) {
    if (_tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.inbox_rounded, size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('support.no_reports_title'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('support.no_reports_desc'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: AppDimensions.pagePadding,
      itemCount: _tickets.length,
      itemBuilder: (context, index) {
        final ticket = _tickets[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            onTap: () => _showTicketDetailsDialog(context, ticket),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ticket.id,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    StatusBadge(
                      label: ticket.statusText,
                      status: ticket.status,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  ticket.subject,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ticket.problemType,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ticket.createdAt.year}-${ticket.createdAt.month.toString().padLeft(2, '0')}-${ticket.createdAt.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                    if (ticket.hasAttachment)
                      Row(
                        children: [
                          Icon(
                            Icons.attach_file_rounded,
                            size: 14,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            context.isArabic ? 'مرفق' : 'Attachment',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTicketDetailsDialog(BuildContext context, _SupportTicketItem ticket) {
    final isDark = context.isDark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                ticket.id,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
            StatusBadge(
              label: ticket.statusText,
              status: ticket.status,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.subject,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ticket.problemType,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const Divider(height: 20),
            Text(
              ticket.description,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              context.tr('common.back'),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
