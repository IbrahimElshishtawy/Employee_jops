import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../domain/entities/department_request.dart';
import '../providers/department_requests_provider.dart';
import '../widgets/request_card.dart';
import '../widgets/communication_empty_state.dart';
import '../widgets/communication_error_state.dart';
import '../widgets/communication_skeletons.dart';

class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    final requestsAsync = ref.watch(myDepartmentRequestsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isArabic ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isArabic ? 'طلباتي التشغيلية' : 'Department Requests',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor:
              isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(text: isArabic ? 'الكل' : 'All'),
            Tab(text: isArabic ? 'النشطة' : 'Active'),
            Tab(text: isArabic ? 'المكتملة' : 'Completed'),
            Tab(text: isArabic ? 'المرفوضة' : 'Rejected'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          context.push(AppRoutes.newDepartmentRequest);
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(
          isArabic ? 'طلب جديد' : 'New Request',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: requestsAsync.when(
          data: (requests) {
            final allRequests = requests;
            final activeRequests =
                requests.where((r) => r.status.isActive).toList();
            final completedRequests = requests
                .where((r) => r.status == DepartmentRequestStatus.completed)
                .toList();
            final rejectedRequests = requests
                .where((r) => r.status == DepartmentRequestStatus.rejected)
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsList(allRequests, isArabic),
                _buildRequestsList(activeRequests, isArabic),
                _buildRequestsList(completedRequests, isArabic),
                _buildRequestsList(rejectedRequests, isArabic),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: RequestListSkeleton(itemCount: 4),
          ),
          error: (err, _) => CommunicationErrorState(
            message: err.toString(),
            onRetry: () => ref.invalidate(myDepartmentRequestsProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList(List<DepartmentRequest> list, bool isArabic) {
    if (list.isEmpty) {
      return CommunicationEmptyState(
        title: isArabic ? 'لا توجد طلبات هنا' : 'No requests here',
        message: isArabic
            ? 'لم يتم العثور على أي طلبات في هذه القائمة.'
            : 'No department requests found in this category.',
        icon: Icons.assignment_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final req = list[index];
        return RequestCard(
          request: req,
          onTap: () {
            context.push('/communication/request/${req.id}');
          },
        );
      },
    );
  }
}
