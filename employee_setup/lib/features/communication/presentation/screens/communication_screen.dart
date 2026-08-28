import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_routes.dart';
import '../providers/departments_provider.dart';
import '../providers/conversations_provider.dart';
import '../providers/department_requests_provider.dart';
import '../widgets/communication_header.dart';
import '../widgets/active_requests_card.dart';
import '../widgets/department_grid.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/request_card.dart';
import '../widgets/communication_empty_state.dart';
import '../widgets/communication_error_state.dart';

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

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
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

                // 2. Active Requests Banner
                ActiveRequestsCard(
                  activeCount: activeCount,
                  onTap: () {
                    context.push(AppRoutes.myDepartmentRequests);
                  },
                ),
                if (activeCount > 0) const SizedBox(height: 20),

                // 3. Departments Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isArabic ? 'أقسام الفندق' : 'Hotel Departments',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      isArabic ? 'اختر للبدء' : 'Select to start',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                departmentsAsync.when(
                  data: (departments) => DepartmentGrid(
                    departments: departments,
                    onDepartmentSelected: (dept) {
                      context.push('/communication/department/${dept.id}');
                    },
                  ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => CommunicationErrorState(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(departmentsListProvider),
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Conversations Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isArabic ? 'محادثاتي الأخيرة' : 'My Conversations',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                conversationsAsync.when(
                  data: (conversations) {
                    if (conversations.isEmpty) {
                      return CommunicationEmptyState(
                        title: isArabic ? 'لا توجد محادثات نشطة' : 'No active conversations',
                        message: isArabic
                            ? 'اختر قسماً للتواصل مع أحد الزملاء وبدء المحادثة.'
                            : 'Select a department to start chatting with colleagues.',
                        icon: Icons.chat_bubble_outline_rounded,
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: conversations.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final conv = conversations[index];
                        return ConversationTile(
                          conversation: conv,
                          onTap: () {
                            context.push('/communication/chat/${conv.id}');
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => CommunicationErrorState(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(conversationsListProvider),
                  ),
                ),

                const SizedBox(height: 24),

                // 5. My Recent Requests Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isArabic ? 'طلباتي التشغيلية' : 'My Department Requests',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.push(AppRoutes.myDepartmentRequests);
                      },
                      child: Text(
                        isArabic ? 'عرض الكل' : 'View All',
                        style: const TextStyle(
                          fontSize: 13,
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
                        title: isArabic ? 'لا توجد طلبات سابقة' : 'No requests yet',
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
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final req = recentRequests[index];
                        return RequestCard(
                          request: req,
                          onTap: () {
                            context.push('/communication/request/${req.id}');
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => CommunicationErrorState(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(myDepartmentRequestsProvider),
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
