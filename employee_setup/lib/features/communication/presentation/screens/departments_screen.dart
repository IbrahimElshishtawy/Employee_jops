import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/departments_provider.dart';
import '../widgets/department_card.dart';
import '../widgets/communication_empty_state.dart';
import '../widgets/communication_error_state.dart';

class DepartmentsScreen extends ConsumerStatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  ConsumerState<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends ConsumerState<DepartmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    final departmentsAsync = ref.watch(departmentsListProvider);

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
          isArabic ? 'دليل أقسام الفندق' : 'Hotel Departments',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded, color: AppColors.primary),
            tooltip: isArabic ? 'إنشاء طلب تشغيلي' : 'New Request',
            onPressed: () {
              context.push(AppRoutes.newDepartmentRequest);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              child: AppTextField(
                controller: _searchController,
                hintText: isArabic
                    ? 'ابحث عن قسم (مثل: الأمن، الصيانة، الاستقبال...)'
                    : 'Search department (e.g. Security, IT, HR...)',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              ),
            ),

            // 2. Departments Content
            Expanded(
              child: departmentsAsync.when(
                data: (departments) {
                  final filtered = departments.where((d) {
                    if (_searchQuery.isEmpty) return true;
                    final nameAr = d.nameAr.toLowerCase();
                    final nameEn = d.nameEn.toLowerCase();
                    final id = d.id.toLowerCase();
                    return nameAr.contains(_searchQuery) ||
                        nameEn.contains(_searchQuery) ||
                        id.contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: CommunicationEmptyState(
                        title: isArabic ? 'لا توجد نتائج' : 'No departments found',
                        message: isArabic
                            ? 'لم نتمكن من العثور على قسم يطابق بحثك.'
                            : 'No department matches your search criteria.',
                        icon: Icons.search_off_rounded,
                      ),
                    );
                  }

                  final totalAvailable = departments.fold<int>(
                    0,
                    (sum, d) => sum + d.availableEmployeesCount,
                  );

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(departmentsListProvider);
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Stats Banner
                        AppCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          backgroundColor: isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.primaryLight,
                          borderColor: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: AppDimensions.radiusMedium,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.corporate_fare_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isArabic
                                          ? '${departments.length} أقسام فندقية'
                                          : '${departments.length} Hotel Departments',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isArabic
                                          ? '🟢 $totalAvailable موظف متاح للخدمة الآن'
                                          : '🟢 $totalAvailable team members online now',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.successDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // List of Departments
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 2.3,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final dept = filtered[index];
                            return DepartmentCard(
                              department: dept,
                              onTap: () {
                                context.push(
                                  '/communication/department/${dept.id}',
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (err, _) => Center(
                  child: CommunicationErrorState(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(departmentsListProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
