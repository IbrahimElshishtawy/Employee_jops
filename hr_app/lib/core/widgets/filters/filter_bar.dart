import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../localization/app_strings.dart';
import '../forms/hr_text_field.dart';

/// Reusable top filter bar with search, filter actions, and export
class FilterBar extends StatelessWidget {
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final TextEditingController? searchController;
  final List<Widget>? filterActions;
  final VoidCallback? onExport;
  final VoidCallback? onRefresh;

  const FilterBar({
    super.key,
    this.searchHint = AppStrings.search,
    this.onSearchChanged,
    this.searchController,
    this.filterActions,
    this.onExport,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Wrap(
        spacing: AppDimensions.space12,
        runSpacing: AppDimensions.space12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 280,
            child: HrTextField(
              hint: searchHint,
              controller: searchController,
              onChanged: onSearchChanged,
              prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted(context)),
            ),
          ),
          Wrap(
            spacing: AppDimensions.space8,
            runSpacing: AppDimensions.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...?filterActions,
              if (onRefresh != null)
                IconButton(
                  tooltip: AppStrings.refresh,
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: onRefresh,
                ),
              if (onExport != null)
                OutlinedButton.icon(
                  onPressed: onExport,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text(AppStrings.export),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
