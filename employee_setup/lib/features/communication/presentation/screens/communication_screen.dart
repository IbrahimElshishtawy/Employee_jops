import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../providers/departments_provider.dart';
import '../providers/conversations_provider.dart';
import '../providers/department_requests_provider.dart';
import '../widgets/communication_header.dart';
import '../widgets/active_requests_card.dart';
import '../widgets/department_card.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/request_card.dart';
import '../widgets/communication_empty_state.dart';
import '../widgets/communication_error_state.dart';
import '../widgets/communication_skeletons.dart';

class CommunicationScreen extends ConsumerWidget {
  const CommunicationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    final departmentsAsync = ref.watch(departmentsListProvider);
    final conversationsAsync = ref.watch(conversationsListProvider);
    final requestsAsync = ref.watch(myDepartmentRequestsProvider);
    final activeCount = ref.watch(activeDepartmentRequestsCountProvider);

    final isInitialLoading = departmentsAsync.isLoading &&
        conversationsAsync.isLoading &&
        requestsAsync.isLoading;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: isInitialLoading
            ? const CommunicationMainScreenSkeleton()
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(departmentsListProvider);
                  ref.invalidate(conversationsListProvider);
                  ref.invalidate(myDepartmentRequestsProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Header
                      CommunicationHeader(
                        onHistoryTap: () {
                          context.push(AppRoutes.myDepartmentRequests);
                        },
                      ),
                      const SizedBox(height: 16),

                      // 2. Main Entry Action Hub (3 Dedicated Action Cards)
                      Row(
                        children: [
                          // Card A: Departments Directory
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                context.push(AppRoutes.departments);
                              },
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusMedium),
                              child: AppCard(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 12),
                                backgroundColor: isDark
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : AppColors.primaryLight,
                                borderColor:
                                    AppColors.primary.withValues(alpha: 0.3),
                                borderRadius: AppDimensions.radiusMedium,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.corporate_fare_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isArabic ? 'دليل الأقسام' : 'Departments',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isArabic ? '15 قسماً' : '15 Depts',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Card B: Dedicated Conversations Page
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                context.push(AppRoutes.conversations);
                              },
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusMedium),
                              child: AppCard(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 12),
                                backgroundColor: isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceLight,
                                borderColor: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                                borderRadius: AppDimensions.radiusMedium,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AppColors.success
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.forum_rounded,
                                        color: AppColors.success,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isArabic ? 'المحادثات' : 'Messages',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isArabic ? 'محادثات الزملاء' : 'Colleagues',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Card C: Create Operational Request
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                context.push(AppRoutes.newDepartmentRequest);
                              },
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusMedium),
                              child: AppCard(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 12),
                                backgroundColor: isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceLight,
                                borderColor: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                                borderRadius: AppDimensions.radiusMedium,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AppColors.info
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.add_task_rounded,
                                        color: AppColors.info,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isArabic ? 'طلب تشغيلي' : 'New Request',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isArabic ? 'إرسال طلب' : 'Dispatch',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 3. Active Requests Banner (if any)
                      if (activeCount > 0) ...[
                        ActiveRequestsCard(
                          activeCount: activeCount,
                          onTap: () {
                            context.push(AppRoutes.myDepartmentRequests);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 4. Quick Access Departments (Top 4)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isArabic ? 'أقسام الفندق' : 'Hotel Departments',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              context.push(AppRoutes.departments);
                            },
                            icon: Icon(
                              isArabic
                                  ? Icons.arrow_back_ios_new_rounded
                                  : Icons.arrow_forward_ios_rounded,
                              size: 12,
                            ),
                            label: Text(
                              isArabic ? 'عرض كل الأقسام (15)' : 'View All (15)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                       SizedBox(height: 8),

                      departmentsAsync.when(
                        data: (departments) {
                          final quickDepts = departments.take(4).toList();
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 2.3,
                            ),
                            itemCount: quickDepts.length,
                            itemBuilder: (context, index) {
                              final dept = quickDepts[index];
                              return DepartmentCard(
                                department: dept,
                                onTap: () {
                                  context.push(
                                      '/communication/department/${dept.id}');
                                },
                              );
                            },
                          );
                        },
                        loading: () =>
                            const DepartmentGridSkeleton(itemCount: 4),
                        error: (err, _) => CommunicationErrorState(
                          message: err.toString(),
                          onRetry: () =>
                              ref.invalidate(departmentsListProvider),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 5. My Conversations Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isArabic ? 'محادثاتي الأخيرة' : 'My Conversations',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.push(AppRoutes.conversations);
                            },
                            child: Text(
                              isArabic ? 'عرض الكل' : 'View All',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      conversationsAsync.when(
                        data: (conversations) {
                          if (conversations.isEmpty) {
                            return CommunicationEmptyState(
                              title: isArabic
                                  ? 'لا توجد محادثات نشطة'
                                  : 'No active conversations',
                              message: isArabic
                                  ? 'اختر قسماً للتواصل مع أحد الزملاء وبدء المحادثة.'
                                  : 'Select a department to start chatting with colleagues.',
                              icon: Icons.chat_bubble_outline_rounded,
                            );
                          }
                          final recentConvs = conversations.take(3).toList();
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: recentConvs.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final conv = recentConvs[index];
                              return ConversationTile(
                                conversation: conv,
                                onTap: () {
                                  context.push(
                                      '/communication/chat/${conv.id}');
                                },
                              );
                            },
                          );
                        },
                        loading: () =>
                            const ConversationListSkeleton(itemCount: 3),
                        error: (err, _) => CommunicationErrorState(
                          message: err.toString(),
                          onRetry: () =>
                              ref.invalidate(conversationsListProvider),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 6. My Recent Requests Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isArabic
                                ? 'طلباتي التشغيلية'
                                : 'My Department Requests',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.push(AppRoutes.myDepartmentRequests);
                            },
                            child: Text(
                              isArabic ? 'عرض الكل' : 'View All',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      requestsAsync.when(
                        data: (requests) {
                          if (requests.isEmpty) {
                            return CommunicationEmptyState(
                              title: isArabic
                                  ? 'لا توجد طلبات سابقة'
                                  : 'No requests yet',
                              message: isArabic
                                  ? 'يمكنك إنشاء طلب تشغيلي لأي قسم عند الحاجة.'
                                  : 'You can create operational requests for any department.',
                              icon: Icons.assignment_outlined,
                            );
                          }
                          final recentRequests = requests.take(3).toList();
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: recentRequests.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final req = recentRequests[index];
                              return RequestCard(
                                request: req,
                                onTap: () {
                                  context.push(
                                      '/communication/request/${req.id}');
                                },
                              );
                            },
                          );
                        },
                        loading: () =>
                            const RequestListSkeleton(itemCount: 3),
                        error: (err, _) => CommunicationErrorState(
                          message: err.toString(),
                          onRetry: () =>
                              ref.invalidate(myDepartmentRequestsProvider),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
