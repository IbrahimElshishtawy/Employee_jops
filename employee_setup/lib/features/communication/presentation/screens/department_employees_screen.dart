import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/departments_provider.dart';
import '../providers/contacts_provider.dart';
import '../widgets/employee_contact_card.dart';
import '../widgets/communication_empty_state.dart';
import '../widgets/communication_error_state.dart';

class DepartmentEmployeesScreen extends ConsumerStatefulWidget {
  final String departmentId;

  const DepartmentEmployeesScreen({
    super.key,
    required this.departmentId,
  });

  @override
  ConsumerState<DepartmentEmployeesScreen> createState() =>
      _DepartmentEmployeesScreenState();
}

class _DepartmentEmployeesScreenState
    extends ConsumerState<DepartmentEmployeesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    final deptAsync = ref.watch(departmentByIdProvider(widget.departmentId));
    final contactsAsync =
        ref.watch(departmentContactsProvider(widget.departmentId));

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
        title: deptAsync.when(
          data: (dept) => Text(
            isArabic
                ? 'موظفو ${dept?.nameAr ?? widget.departmentId}'
                : '${dept?.nameEn ?? widget.departmentId} Employees',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          loading: () => Text(
            isArabic ? 'جاري التحميل...' : 'Loading...',
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          error: (_, _) => Text(
            widget.departmentId,
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
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
        child: Column(
          children: [
            // Top action & search bar
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              child: Column(
                children: [
                  // Department Request Shortcut Button
                  AppButton(
                    label: isArabic
                        ? 'إنشاء طلب تشغيلي لهذا القسم'
                        : 'Create Department Request',
                    icon: Icons.add_task_rounded,
                    onPressed: () {
                      context.push(
                        '${AppRoutes.newDepartmentRequest}?deptId=${widget.departmentId}',
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Search TextField
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.backgroundLight,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim().toLowerCase();
                              });
                            },
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                            decoration: InputDecoration(
                              hintText: isArabic
                                  ? 'البحث بالاسم أو المسمى الوظيفي...'
                                  : 'Search by name or title...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textSecondaryLight,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Employee List
            Expanded(
              child: contactsAsync.when(
                data: (contacts) {
                  final filtered = contacts.where((c) {
                    if (_searchQuery.isEmpty) return true;
                    final name = c.fullName.toLowerCase();
                    final titleAr = c.jobTitleAr.toLowerCase();
                    final titleEn = c.jobTitleEn.toLowerCase();
                    return name.contains(_searchQuery) ||
                        titleAr.contains(_searchQuery) ||
                        titleEn.contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return CommunicationEmptyState(
                      title: isArabic
                          ? 'لا يوجد موظفون متاحون'
                          : 'No authorized contacts found',
                      message: isArabic
                          ? 'لا تتوفر جهات اتصال مصرح بها في هذا القسم حالياً.'
                          : 'No authorized employees found in this department currently.',
                      icon: Icons.person_off_outlined,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final contact = filtered[index];
                      return EmployeeContactCard(
                        contact: contact,
                        onTap: () {
                          context.push(
                            '/communication/employee/${contact.id}',
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (err, _) => CommunicationErrorState(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(
                    departmentContactsProvider(widget.departmentId),
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
