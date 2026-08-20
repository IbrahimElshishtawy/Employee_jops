import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/filters/filter_bar.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/tables/hr_data_table.dart';
import '../../domain/entities/deduction_entity.dart';

/// Deductions Management Screen
class DeductionsListScreen extends StatefulWidget {
  final DeductionsRepository repository;

  const DeductionsListScreen({super.key, required this.repository});

  @override
  State<DeductionsListScreen> createState() => _DeductionsListScreenState();
}

class _DeductionsListScreenState extends State<DeductionsListScreen> {
  List<DeductionEntity> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeductions();
  }

  Future<void> _loadDeductions() async {
    setState(() => _isLoading = true);
    final res = await widget.repository.getDeductions(1, 10);
    setState(() {
      _items = res.items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterBar(
          searchHint: 'Search deductions by employee, reason...',
          onRefresh: _loadDeductions,
          filterActions: [
            HrButton(
              label: 'New Deduction',
              icon: Icons.add,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space20),
        HrDataTable<DeductionEntity>(
          isLoading: _isLoading,
          items: _items,
          totalItems: _items.length,
          columns: [
            HrColumn<DeductionEntity>(
              title: 'Employee',
              cellBuilder: (d) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(d.employeeName, style: AppTypography.bodyBold),
                  Text(d.employeeCode, style: AppTypography.caption),
                ],
              ),
            ),
            HrColumn<DeductionEntity>(
              title: 'Type',
              cellBuilder: (d) => Text(d.type.label, style: AppTypography.bodyMedium),
            ),
            HrColumn<DeductionEntity>(
              title: 'Amount',
              cellBuilder: (d) => Text(
                '-\$${d.amount.toStringAsFixed(2)}',
                style: AppTypography.bodyBold.copyWith(color: AppColors.danger),
              ),
            ),
            HrColumn<DeductionEntity>(
              title: 'Date',
              cellBuilder: (d) => Text(DateFormatter.toDisplayDate(d.date), style: AppTypography.body),
            ),
            HrColumn<DeductionEntity>(
              title: 'Reason',
              cellBuilder: (d) => Text(d.reason, style: AppTypography.body, overflow: TextOverflow.ellipsis),
            ),
            HrColumn<DeductionEntity>(
              title: 'Created By',
              cellBuilder: (d) => Text(d.createdBy, style: AppTypography.captionBold),
            ),
          ],
        ),
      ],
    );
  }
}
