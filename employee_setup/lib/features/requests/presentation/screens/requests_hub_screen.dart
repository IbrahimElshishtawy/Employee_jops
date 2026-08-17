import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/request_card.dart';
import '../../domain/models/unified_request.dart';

class RequestsHubScreen extends ConsumerStatefulWidget {
  const RequestsHubScreen({super.key});

  @override
  ConsumerState<RequestsHubScreen> createState() => _RequestsHubScreenState();
}

class _RequestsHubScreenState extends ConsumerState<RequestsHubScreen> {
  int _selectedFilterIndex =
      0; // 0: All, 1: Advances, 2: Permissions, 3: Vacations

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(allRequestsProvider);
    final isDark = context.isDark;

    return Scaffold(
      appBar: AppHeader(
        title: context.tr('requests.title'),
        subtitle: 'إدارة السُلف، أذونات الاستئذان، والإجازات',
        showBackButton: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allRequestsProvider);
          ref.invalidate(advancesListProvider);
          ref.invalidate(permissionsListProvider);
          ref.invalidate(vacationsListProvider);
        },
        child: SingleChildScrollView(
          padding: AppDimensions.pagePadding,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Categories Hub Cards
              Row(
                children: [
                  Expanded(
                    child: _buildCategoryCard(
                      title: context.tr('requests.advances'),
                      icon: Icons.account_balance_wallet_outlined,
                      color: const Color(0xFF10B981),
                      onTap: () => context.push('/requests/advances'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCategoryCard(
                      title: context.tr('requests.permissions'),
                      icon: Icons.timer_outlined,
                      color: const Color(0xFF3B82F6),
                      onTap: () => context.push('/requests/permissions'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCategoryCard(
                      title: context.tr('requests.vacations'),
                      icon: Icons.beach_access_outlined,
                      color: const Color(0xFFF59E0B),
                      onTap: () => context.push('/requests/vacations'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(0, context.tr('requests.all')),
                    const SizedBox(width: 8),
                    _buildFilterChip(1, context.tr('requests.advances')),
                    const SizedBox(width: 8),
                    _buildFilterChip(2, context.tr('requests.permissions')),
                    const SizedBox(width: 8),
                    _buildFilterChip(3, context.tr('requests.vacations')),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Request History Feed
              Text(
                context.tr('requests.history'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 12),

              () {
                final items = requestsAsync;
                final filtered = items.where((item) {
                  if (_selectedFilterIndex == 1) {
                    return item.category == RequestCategory.advance;
                  }
                  if (_selectedFilterIndex == 2) {
                    return item.category == RequestCategory.permission;
                  }
                  if (_selectedFilterIndex == 3) {
                    return item.category == RequestCategory.vacation;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    title: 'لا توجد طلبات في هذا القسم',
                    subtitle:
                        'اضغط على أحد الأقسام أعلاه لإنشاء طلب جديد بكل سهولة',
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final req = filtered[index];
                    return RequestCard(
                      title: req.title,
                      subtitle: req.subtitle,
                      date: req.date,
                      badgeStatus: req.badgeStatus,
                      statusLabel: req.statusLabel,
                      onTap: () {
                        if (req.category == RequestCategory.advance) {
                          context.push('/requests/advances/${req.id}');
                        } else if (req.category == RequestCategory.permission) {
                          context.push('/requests/permissions/${req.id}');
                        } else {
                          context.push('/requests/vacations/${req.id}');
                        }
                      },
                    );
                  },
                );
              }(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    final isDark = context.isDark;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilterIndex = index),
      selectedColor: AppColors.primary,
      backgroundColor: isDark
          ? AppColors.surfaceDark
          : AppColors.surfaceVariantLight,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? Colors.white
            : (isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      showCheckmark: false,
    );
  }
}
