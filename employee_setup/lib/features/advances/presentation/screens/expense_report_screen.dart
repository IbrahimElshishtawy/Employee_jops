import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/expense_report.dart';

class ExpenseReportScreen extends ConsumerStatefulWidget {
  final String advanceId;

  const ExpenseReportScreen({super.key, required this.advanceId});

  @override
  ConsumerState<ExpenseReportScreen> createState() => _ExpenseReportScreenState();
}

class _ExpenseReportScreenState extends ConsumerState<ExpenseReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  final List<ExpenseItem> _items = [];
  bool _isSubmitting = false;

  void _addItem() {
    if (_descController.text.trim().isEmpty || _amountController.text.trim().isEmpty) {
      context.showSnackBar('ÙŠØ±Ø¬Ù‰ Ø¥Ø¯Ø®Ø§Ù„ ÙˆØµÙ ÙˆÙ…Ø¨Ù„Øº Ø§Ù„Ø¨Ù†Ø¯ Ø£ÙˆÙ„Ø§Ù‹', isError: true);
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      context.showSnackBar('ÙŠØ±Ø¬Ù‰ Ø¥Ø¯Ø®Ø§Ù„ Ù…Ø¨Ù„Øº ØµØ­ÙŠØ­', isError: true);
      return;
    }

    setState(() {
      _items.add(
        ExpenseItem(
          id: const Uuid().v4(),
          description: _descController.text.trim(),
          amount: amount,
          date: DateTime.now(),
          invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        ),
      );
      _descController.clear();
      _amountController.clear();
    });
  }

  Future<void> _submitReport() async {
    if (_items.isEmpty) {
      context.showSnackBar('ÙŠØ±Ø¬Ù‰ Ø¥Ø¶Ø§ÙØ© Ø¨Ù†Ø¯ Ù…ØµØ±ÙˆÙØ§Øª ÙˆØ§Ø­Ø¯ Ø¹Ù„Ù‰ Ø§Ù„Ø£Ù‚Ù„', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final total = _items.fold<double>(0, (sum, item) => sum + item.amount);
    final emp = ref.read(currentEmployeeProvider);
    final empId = emp?.id ?? AppConstants.mockEmployeeId;

    final report = ExpenseReport(
      id: const Uuid().v4(),
      advanceId: widget.advanceId,
      employeeId: empId,
      totalAmount: total,
      items: _items,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      submittedAt: DateTime.now(),
    );

    await ref.read(advancesRepositoryProvider).submitExpenseReport(report);
    ref.invalidate(advancesListProvider);
    ref.invalidate(allRequestsProvider);

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    context.showSnackBar('ØªÙ… ØªÙ‚Ø¯ÙŠÙ… ØªÙ‚Ø±ÙŠØ± Ø§Ù„Ù…ØµØ±ÙˆÙØ§Øª Ø¨Ù†Ø¬Ø§Ø­');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final total = _items.fold<double>(0, (sum, item) => sum + item.amount);

    return Scaffold(
      appBar: AppHeader(
        title: context.tr('advances.expense_report'),
        subtitle: 'ØªØ³ÙˆÙŠØ© Ø¨Ù†ÙˆØ¯ ÙˆÙÙˆØ§ØªÙŠØ± Ø§Ù„Ø³ÙÙ„ÙØ© Ø§Ù„Ù…Ø§Ù„ÙŠØ©',
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add Item Form
              Text(
                'Ø¥Ø¶Ø§ÙØ© Ø¨Ù†Ø¯ Ù…ØµØ±ÙˆÙ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    AppTextField(
                      label: 'Ø¨ÙŠØ§Ù† Ø§Ù„Ù…ØµØ±ÙˆÙ / Ø§Ù„Ø¨Ù†Ø¯',
                      hintText: 'Ù…Ø«Ø§Ù„: ÙØ§ØªÙˆØ±Ø© Ø­Ø¬Ø² ÙÙ†Ø¯Ù‚ØŒ ØªØ°Ø§ÙƒØ± Ù‚Ø·Ø§Ø±...',
                      controller: _descController,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Ø§Ù„Ù…Ø¨Ù„Øº (Ø¬Ù†ÙŠÙ‡)',
                      hintText: 'Ù…Ø«Ø§Ù„: 750',
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    AppButton.secondary(
                      label: 'Ø¥Ø¶Ø§ÙØ© Ø§Ù„Ø¨Ù†Ø¯ Ù„Ù„ØªÙ‚Ø±ÙŠØ±',
                      icon: Icons.add_circle_outline_rounded,
                      onPressed: _addItem,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Items List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ø¨Ù†ÙˆØ¯ Ø§Ù„ØªÙ‚Ø±ÙŠØ± (${_items.length})',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    'Ø§Ù„Ø¥Ø¬Ù…Ø§Ù„ÙŠ: ${total.toStringAsFixed(2)} Ø¬.Ù…',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceVariantLight,
                    borderRadius: AppDimensions.borderRadiusMedium,
                  ),
                  child: Center(
                    child: Text(
                      'Ù„Ù… ØªÙ‚Ù… Ø¨Ø¥Ø¶Ø§ÙØ© Ø¨Ù†ÙˆØ¯ Ù…ØµØ±ÙˆÙØ§Øª Ø¨Ø¹Ø¯',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ø±Ù‚Ù… Ø§Ù„ÙØ§ØªÙˆØ±Ø©: ${item.invoiceNumber ?? "--"}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${item.amount.toInt()} Ø¬.Ù…',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                            onPressed: () => setState(() => _items.removeAt(index)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),

              // Notes
              AppTextField(
                label: 'Ù…Ù„Ø§Ø­Ø¸Ø§Øª Ø¥Ø¶Ø§ÙÙŠØ© Ø¹Ù„Ù‰ Ø§Ù„ØªÙ‚Ø±ÙŠØ±',
                hintText: 'Ø£ÙŠ ØªÙØ§ØµÙŠÙ„ ØªØ±ØºØ¨ ÙÙŠ Ø¥ÙŠØ¶Ø§Ø­Ù‡Ø§ Ù„Ù„Ù…Ø¯ÙŠØ± Ø§Ù„Ù…Ø§Ù„ÙŠ...',
                controller: _notesController,
                maxLines: 2,
              ),
              const SizedBox(height: 28),

              // Submit Button
              AppButton.primary(
                label: 'Ø§Ø¹ØªÙ…Ø§Ø¯ ÙˆØ¥Ø±Ø³Ø§Ù„ ØªÙ‚Ø±ÙŠØ± Ø§Ù„Ù…ØµØ±ÙˆÙØ§Øª',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submitReport,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

