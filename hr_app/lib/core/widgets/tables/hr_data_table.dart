import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';
import '../feedback/empty_state_view.dart';
import '../feedback/error_state_view.dart';
import '../feedback/loading_state_view.dart';
import 'table_pagination.dart';

/// Column descriptor for HrDataTable
class HrColumn<T> {
  final String title;
  final Widget Function(T item) cellBuilder;
  final double? width;
  final bool isSortable;
  final String? sortKey;

  const HrColumn({
    required this.title,
    required this.cellBuilder,
    this.width,
    this.isSortable = false,
    this.sortKey,
  });
}

/// Advanced reusable administrative Data Table
class HrDataTable<T> extends StatelessWidget {
  final List<HrColumn<T>> columns;
  final List<T> items;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String emptyMessage;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int>? onPageChanged;
  final String? sortedColumnKey;
  final bool isAscending;
  final void Function(String sortKey, bool isAscending)? onSort;
  final void Function(T item)? onRowTap;

  const HrDataTable({
    super.key,
    required this.columns,
    required this.items,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.emptyMessage = 'No records available',
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.pageSize = 10,
    this.onPageChanged,
    this.sortedColumnKey,
    this.isAscending = true,
    this.onSort,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Card(
        child: SizedBox(
          height: 300,
          child: const LoadingStateView(),
        ),
      );
    }

    if (errorMessage != null) {
      return Card(
        child: SizedBox(
          height: 300,
          child: ErrorStateView(
            message: errorMessage!,
            onRetry: onRetry,
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return Card(
        child: SizedBox(
          height: 300,
          child: EmptyStateView(
            subtitle: emptyMessage,
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.sizeOf(context).width - 320,
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.surfaceDark
                      : const Color(0xFFF8FAFC),
                ),
                headingTextStyle: AppTypography.captionBold.copyWith(
                  color: AppColors.textSecondaryLight,
                  letterSpacing: 0.5,
                ),
                dataTextStyle: AppTypography.body,
                columnSpacing: AppDimensions.space24,
                horizontalMargin: AppDimensions.space20,
                columns: columns.map((col) {
                  return DataColumn(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(col.title.toUpperCase()),
                        if (col.isSortable && col.sortKey != null) ...[
                          const SizedBox(width: 4),
                          Icon(
                            sortedColumnKey == col.sortKey
                                ? (isAscending ? Icons.arrow_upward : Icons.arrow_downward)
                                : Icons.unfold_more,
                            size: 14,
                            color: sortedColumnKey == col.sortKey
                                ? AppColors.primaryLight
                                : AppColors.textMutedLight,
                          ),
                        ],
                      ],
                    ),
                    onSort: col.isSortable && col.sortKey != null && onSort != null
                        ? (_, asc) => onSort!(col.sortKey!, asc)
                        : null,
                  );
                }).toList(),
                rows: items.map((item) {
                  return DataRow(
                    onSelectChanged: onRowTap != null ? (_) => onRowTap!(item) : null,
                    cells: columns.map((col) {
                      return DataCell(col.cellBuilder(item));
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
          if (onPageChanged != null && totalItems > 0)
            TablePagination(
              currentPage: currentPage,
              totalPages: totalPages,
              totalItems: totalItems,
              pageSize: pageSize,
              onPageChanged: onPageChanged!,
            ),
        ],
      ),
    );
  }
}
