// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/validator.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/forms/hr_text_field.dart';
import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/message_entity.dart';

/// Modal dialog for initiating a new direct message conversation with an employee
class NewConversationDialog extends StatefulWidget {
  final EmployeeRepository employeeRepository;
  final Future<ConversationEntity?> Function(String employeeId, String initialMessage) onStartConversation;

  const NewConversationDialog({
    super.key,
    required this.employeeRepository,
    required this.onStartConversation,
  });

  @override
  State<NewConversationDialog> createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends State<NewConversationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();

  List<EmployeeEntity> _searchResults = [];
  EmployeeEntity? _selectedEmployee;
  bool _isSearching = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _performEmployeeSearch('');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performEmployeeSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final filter = EmployeeFilter(
        searchQuery: query.trim().isEmpty ? null : query.trim(),
        pageSize: 10,
      );
      final result = await widget.employeeRepository.getEmployees(filter);
      if (mounted) {
        setState(() {
          _searchResults = result.items;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedEmployee == null) {
      setState(() => _errorMessage = 'Please select an employee to start a conversation.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final conversation = await widget.onStartConversation(
      _selectedEmployee!.id,
      _messageController.text.trim(),
    );

    if (mounted) {
      if (conversation != null) {
        Navigator.of(context).pop(conversation);
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to initiate conversation.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.space8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_outlined, color: AppColors.primaryLight, size: 22),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('New Direct Message', style: AppTypography.heading3),
                          Text('Start a direct HR conversation with an employee', style: AppTypography.captionOf(context)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space16),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.dangerBgDark : AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space12),
                ],

                // Search Employee Input
                HrTextField(
                  label: 'Search Employee',
                  hint: 'Type employee name or code (e.g. EMP-1001)...',
                  controller: _searchController,
                  prefixIcon: const Icon(Icons.search),
                  onChanged: _performEmployeeSearch,
                ),
                const SizedBox(height: AppDimensions.space8),

                // Selected Employee Preview or Search Results
                Text('Select Recipient:', style: AppTypography.captionOf(context)),
                const SizedBox(height: 6),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: _isSearching
                        ? const Center(child: CircularProgressIndicator())
                        : _searchResults.isEmpty
                            ? Center(child: Text('No employees found', style: AppTypography.captionOf(context)))
                            : ListView.separated(
                                itemCount: _searchResults.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                  final emp = _searchResults[index];
                                  final isSelected = _selectedEmployee?.id == emp.id;

                                  return Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      selected: isSelected,
                                      selectedTileColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 0.1),
                                      leading: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                                        child: Text(
                                          emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : 'E',
                                          style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      title: Text(emp.fullName, style: AppTypography.bodyBold),
                                      subtitle: Text('${emp.employeeCode} • ${emp.department} • ${emp.jobTitle}', style: AppTypography.captionOf(context)),
                                      trailing: isSelected
                                          ? const Icon(Icons.check_circle, color: AppColors.primaryLight, size: 20)
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          _selectedEmployee = emp;
                                          _errorMessage = null;
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                  ),
                ),
                const SizedBox(height: AppDimensions.space12),

                // Message Body
                HrTextField(
                  label: 'Initial Message',
                  hint: 'Write your message to the employee...',
                  controller: _messageController,
                  maxLines: 3,
                  validator: (v) => Validator.requiredField(v, 'Message is required'),
                ),
                const SizedBox(height: AppDimensions.space16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    HrButton(
                      label: 'Cancel',
                      variant: HrButtonVariant.outline,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    HrButton(
                      label: 'Send Message',
                      variant: HrButtonVariant.primary,
                      icon: Icons.send,
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
