import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Item representation for SelectionBottomSheet
class SelectionItem {
  final String id;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? emoji;

  const SelectionItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
    this.emoji,
  });
}

/// Searchable modal bottom sheet for professional role/department/manager selection.
class SelectionBottomSheet extends StatefulWidget {
  final String title;
  final List<SelectionItem> items;
  final String? selectedId;
  final bool enableSearch;

  const SelectionBottomSheet({
    super.key,
    required this.title,
    required this.items,
    this.selectedId,
    this.enableSearch = true,
  });

  static Future<SelectionItem?> show({
    required BuildContext context,
    required String title,
    required List<SelectionItem> items,
    String? selectedId,
    bool enableSearch = true,
  }) {
    return showModalBottomSheet<SelectionItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SelectionBottomSheet(
        title: title,
        items: items,
        selectedId: selectedId,
        enableSearch: enableSearch,
      ),
    );
  }

  @override
  State<SelectionBottomSheet> createState() => _SelectionBottomSheetState();
}

class _SelectionBottomSheetState extends State<SelectionBottomSheet> {
  late TextEditingController _searchController;
  late List<SelectionItem> _filteredItems;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredItems = widget.items;
      } else {
        final q = query.toLowerCase().trim();
        _filteredItems = widget.items.where((item) {
          final titleMatch = item.title.toLowerCase().contains(q);
          final subtitleMatch = item.subtitle?.toLowerCase().contains(q) ?? false;
          return titleMatch || subtitleMatch;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Search Bar
            if (widget.enableSearch && widget.items.length > 5) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: context.tr('onboarding.search_placeholder'),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariantLight,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            const Divider(height: 1),

            // Items List
            Flexible(
              child: _filteredItems.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          context.tr('common.no_data'),
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _filteredItems.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                        color: isDark
                            ? AppColors.borderDark.withValues(alpha: 0.5)
                            : AppColors.borderLight.withValues(alpha: 0.5),
                      ),
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = item.id == widget.selectedId;

                        return InkWell(
                          onTap: () => Navigator.of(context).pop(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : Colors.transparent,
                            child: Row(
                              children: [
                                if (item.emoji != null) ...[
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.15)
                                          : (isDark
                                              ? AppColors.surfaceVariantDark
                                              : AppColors.surfaceVariantLight),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      item.emoji!,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                ] else if (item.icon != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.15)
                                          : (isDark
                                              ? AppColors.surfaceVariantDark
                                              : AppColors.surfaceVariantLight),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      item.icon,
                                      size: 18,
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? AppColors.primary
                                              : (isDark
                                                  ? Colors.white
                                                  : AppColors.textPrimaryLight),
                                        ),
                                      ),
                                      if (item.subtitle != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.subtitle!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
