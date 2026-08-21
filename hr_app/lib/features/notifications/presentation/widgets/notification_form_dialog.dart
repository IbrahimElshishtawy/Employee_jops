import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/validator.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/forms/hr_text_field.dart';
import '../../domain/entities/notification_entity.dart';

/// Modal dialog for composing and scheduling HR announcements and broadcasts
class NotificationFormDialog extends StatefulWidget {
  final Future<bool> Function(NotificationItemEntity notification) onSend;

  const NotificationFormDialog({super.key, required this.onSend});

  @override
  State<NotificationFormDialog> createState() => _NotificationFormDialogState();
}

class _NotificationFormDialogState extends State<NotificationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  NotificationType _type = NotificationType.companyAnnouncement;
  NotificationSeverity _severity = NotificationSeverity.info;
  NotificationTargetType _targetType = NotificationTargetType.allEmployees;
  String _department = 'Engineering';
  String _workplace = 'CyberWise HQ Cairo';
  bool _isScheduled = false;
  final DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  int get _calculatedTargetCount {
    switch (_targetType) {
      case NotificationTargetType.allEmployees:
        return 48;
      case NotificationTargetType.department:
        return _department == 'Engineering' ? 22 : 12;
      case NotificationTargetType.workplace:
        return _workplace.contains('HQ') ? 34 : 14;
      case NotificationTargetType.specificEmployees:
        return 1;
    }
  }

  String get _targetName {
    switch (_targetType) {
      case NotificationTargetType.allEmployees:
        return 'All Workforce (48 Employees)';
      case NotificationTargetType.department:
        return 'Department: $_department';
      case NotificationTargetType.workplace:
        return 'Workplace: $_workplace';
      case NotificationTargetType.specificEmployees:
        return 'Selected Staff';
    }
  }

  void _confirmAndSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Mass Broadcast Confirmation Dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
        title: Row(
          children: [
            const Icon(Icons.campaign_outlined, color: AppColors.primaryLight),
            const SizedBox(width: 8),
            const Text('Confirm Broadcast Dispatch', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to dispatch this notification to $_calculatedTargetCount employees ($_targetName).',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              _isScheduled
                  ? 'Scheduled for dispatch on: ${_scheduledDate.year}-${_scheduledDate.month.toString().padLeft(2, '0')}-${_scheduledDate.day.toString().padLeft(2, '0')}'
                  : 'This push broadcast will be delivered immediately to employee mobile devices.',
              style: AppTypography.captionOf(context),
            ),
          ],
        ),
        actions: [
          HrButton(
            label: 'Cancel',
            variant: HrButtonVariant.outline,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          HrButton(
            label: _isScheduled ? 'Schedule Broadcast' : 'Send Immediately',
            variant: HrButtonVariant.primary,
            onPressed: () {
              Navigator.of(ctx).pop();
              _dispatchNotification();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _dispatchNotification() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final entity = NotificationItemEntity(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      type: _type,
      severity: _severity,
      targetType: _targetType,
      targetName: _targetName,
      targetCount: _calculatedTargetCount,
      createdBy: 'HR Manager',
      createdAt: DateTime.now(),
      scheduledAt: _isScheduled ? _scheduledDate : null,
      sentAt: _isScheduled ? null : DateTime.now(),
      status: _isScheduled ? NotificationStatus.scheduled : NotificationStatus.sent,
      readCount: 0,
      isRead: false,
    );

    final success = await widget.onSend(entity);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to broadcast notification.';
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
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                        child: const Icon(Icons.campaign_outlined, color: AppColors.primaryLight, size: 22),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Compose HR Announcement', style: AppTypography.heading3),
                            Text('Broadcast push alerts and company notices to staff', style: AppTypography.captionOf(context)),
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

                  // Title
                  HrTextField(
                    label: 'Announcement Title',
                    hint: 'e.g. Company-Wide Holiday Announcement',
                    controller: _titleController,
                    validator: (v) => Validator.requiredField(v, 'Title is required'),
                  ),
                  const SizedBox(height: AppDimensions.space12),

                  // Message
                  HrTextField(
                    label: 'Message Body',
                    hint: 'Enter notification description and details...',
                    controller: _messageController,
                    maxLines: 3,
                    validator: (v) => Validator.requiredField(v, 'Message body is required'),
                  ),
                  const SizedBox(height: AppDimensions.space12),

                  // Type & Severity
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Announcement Category', style: AppTypography.captionOf(context)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<NotificationType>(
                              initialValue: _type,
                              isExpanded: true,
                              decoration: InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSmall)),
                              ),
                              items: NotificationType.values.map((t) {
                                return DropdownMenuItem(value: t, child: Text(t.label, overflow: TextOverflow.ellipsis));
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _type = v);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Severity Level', style: AppTypography.captionOf(context)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<NotificationSeverity>(
                              initialValue: _severity,
                              isExpanded: true,
                              decoration: InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSmall)),
                              ),
                              items: [
                                DropdownMenuItem(value: NotificationSeverity.info, child: Text('Info')),
                                DropdownMenuItem(value: NotificationSeverity.warning, child: Text('Warning')),
                                DropdownMenuItem(value: NotificationSeverity.success, child: Text('Success')),
                                DropdownMenuItem(value: NotificationSeverity.danger, child: Text('Urgent')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _severity = v);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Recipient Target Type
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Target Audience', style: AppTypography.captionOf(context)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: NotificationTargetType.values.map((target) {
                          final isSelected = _targetType == target;
                          return ChoiceChip(
                            label: Text(target.label),
                            selected: isSelected,
                            selectedColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.3 : 0.15),
                            onSelected: (selected) {
                              if (selected) setState(() => _targetType = target);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space12),

                  // Dynamic Target Selector based on targetType
                  if (_targetType == NotificationTargetType.department) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Department', style: AppTypography.captionOf(context)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _department,
                          isExpanded: true,
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSmall)),
                          ),
                          items: ['Engineering', 'Operations', 'Human Resources', 'Finance', 'Marketing', 'Administration']
                              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _department = v);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space12),
                  ] else if (_targetType == NotificationTargetType.workplace) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Workplace', style: AppTypography.captionOf(context)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _workplace,
                          isExpanded: true,
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSmall)),
                          ),
                          items: ['CyberWise HQ Cairo', 'CyberWise Alexandria Hub', 'Smart Village Data Center']
                              .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _workplace = v);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space12),
                  ],

                  // Timing: Send Now vs Schedule
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Schedule for Later', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                              _isScheduled
                                  ? 'Dispatch date: ${_scheduledDate.year}-${_scheduledDate.month.toString().padLeft(2, '0')}-${_scheduledDate.day.toString().padLeft(2, '0')}'
                                  : 'Dispatch immediately upon confirmation',
                              style: AppTypography.captionOf(context),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isScheduled,
                        activeThumbColor: AppColors.primaryLight,
                        onChanged: (v) => setState(() => _isScheduled = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Action Buttons
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
                        label: _isScheduled ? 'Schedule Broadcast' : 'Send Broadcast',
                        variant: HrButtonVariant.primary,
                        icon: _isScheduled ? Icons.alarm : Icons.send,
                        isLoading: _isSubmitting,
                        onPressed: _confirmAndSubmit,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
