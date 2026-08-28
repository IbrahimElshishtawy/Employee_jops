import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/department_request.dart';
import '../providers/department_requests_provider.dart';
import '../widgets/request_status_badge.dart';
import '../widgets/communication_error_state.dart';

class RequestDetailsScreen extends ConsumerWidget {
  final String requestId;

  const RequestDetailsScreen({
    super.key,
    required this.requestId,
  });

  Color _getPriorityColor(RequestPriority priority) {
    switch (priority) {
      case RequestPriority.low:
        return const Color(0xFF10B981);
      case RequestPriority.normal:
        return const Color(0xFF3B82F6);
      case RequestPriority.high:
        return const Color(0xFFEF4444);
    }
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, bool isArabic) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'رفض الطلب' : 'Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? 'يرجى كتابة سبب رفض هذا الطلب:'
                  : 'Please specify the rejection reason:',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isArabic ? 'سبب الرفض...' : 'Reason for rejection...',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(departmentRequestActionProvider.notifier)
                  .rejectRequest(requestId, reason: reasonController.text.trim());
            },
            child: Text(isArabic ? 'تأكيد الرفض' : 'Confirm Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    final requestAsync = ref.watch(departmentRequestByIdProvider(requestId));
    final actionState = ref.watch(departmentRequestActionProvider);
    final isActionLoading = actionState.isLoading;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isArabic ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isArabic ? 'تفاصيل الطلب التشغيلي' : 'Request Details',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: requestAsync.when(
          data: (request) {
            if (request == null) {
              return Center(
                child: Text(isArabic ? 'الطلب غير موجود' : 'Request not found'),
              );
            }

            final dateFormatted = DateFormat(
              'dd MMMM yyyy, hh:mm a',
              isArabic ? 'ar' : 'en',
            ).format(request.createdAt);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & ID Header Card
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: AppDimensions.radiusLarge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '#${request.id}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            RequestStatusBadge(status: request.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          request.localizedRequestType(isArabic),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getPriorityColor(request.priority),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${isArabic ? 'الأولوية:' : 'Priority:'} ${request.priority.localizedName(isArabic)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _getPriorityColor(request.priority),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Request Meta Details Card
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: AppDimensions.radiusLarge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          icon: Icons.business_rounded,
                          label: isArabic ? 'القسم المستهدف' : 'Target Department',
                          value: request.localizedDepartment(isArabic),
                          isDark: isDark,
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          icon: Icons.person_outline_rounded,
                          label: isArabic ? 'مقدم الطلب' : 'Requester',
                          value: request.requesterName,
                          isDark: isDark,
                        ),
                        if (request.recipientName != null) ...[
                          const Divider(height: 20),
                          _buildDetailRow(
                            icon: Icons.person_pin_outlined,
                            label: isArabic ? 'الموظف المعني' : 'Assigned Member',
                            value: request.recipientName!,
                            isDark: isDark,
                          ),
                        ],
                        if (request.locationContext != null) ...[
                          const Divider(height: 20),
                          _buildDetailRow(
                            icon: Icons.location_on_outlined,
                            label: isArabic ? 'الموقع / السياق' : 'Location Context',
                            value: request.locationContext!,
                            isDark: isDark,
                          ),
                        ],
                        const Divider(height: 20),
                        _buildDetailRow(
                          icon: Icons.access_time_rounded,
                          label: isArabic ? 'وقت الإنشاء' : 'Created At',
                          value: dateFormatted,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Request Message Card
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: AppDimensions.radiusLarge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.message_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isArabic ? 'نص الطلب والتفاصيل' : 'Request Message',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          request.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textPrimaryLight,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Rejection reason notice if any
                  if (request.rejectionReason != null &&
                      request.status == DepartmentRequestStatus.rejected) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: isDark
                          ? AppColors.error.withValues(alpha: 0.15)
                          : AppColors.errorLight,
                      borderColor: AppColors.error,
                      borderRadius: AppDimensions.radiusLarge,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cancel_outlined,
                                  color: AppColors.error, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                isArabic ? 'سبب الرفض' : 'Rejection Reason',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            request.rejectionReason!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.errorDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action Buttons (Workflow Lifecycle Actions)
                  if (request.status == DepartmentRequestStatus.pending) ...[
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: isArabic ? 'قبول الطلب' : 'Accept Request',
                            icon: Icons.check_circle_rounded,
                            isLoading: isActionLoading,
                            onPressed: () {
                              ref
                                  .read(departmentRequestActionProvider.notifier)
                                  .acceptRequest(request.id);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: isArabic ? 'رفض الطلب' : 'Reject Request',
                            variant: AppButtonVariant.danger,
                            icon: Icons.cancel_rounded,
                            onPressed: () {
                              _showRejectDialog(context, ref, isArabic);
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else if (request.status == DepartmentRequestStatus.accepted) ...[
                    AppButton(
                      label: isArabic ? 'بدء التنفيذ' : 'Start Progress',
                      icon: Icons.play_arrow_rounded,
                      isLoading: isActionLoading,
                      onPressed: () {
                        ref
                            .read(departmentRequestActionProvider.notifier)
                            .startRequest(request.id);
                      },
                    ),
                  ] else if (request.status == DepartmentRequestStatus.inProgress) ...[
                    AppButton(
                      label: isArabic ? 'إتمام وإغلاق الطلب' : 'Complete Request',
                      icon: Icons.done_all_rounded,
                      isLoading: isActionLoading,
                      onPressed: () {
                        ref
                            .read(departmentRequestActionProvider.notifier)
                            .completeRequest(request.id);
                      },
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => CommunicationErrorState(
            message: err.toString(),
            onRetry: () => ref.invalidate(departmentRequestByIdProvider(requestId)),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
