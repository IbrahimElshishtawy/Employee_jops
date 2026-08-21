import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../domain/entities/report_entities.dart';

/// Modal dialog for generating and exporting report files
class ReportExportDialog extends StatefulWidget {
  final String reportTitle;
  final String reportType;
  final ReportFilter activeFilter;
  final Future<String> Function(String reportType, ReportFilter filter, String format) onExport;

  const ReportExportDialog({
    super.key,
    required this.reportTitle,
    required this.reportType,
    required this.activeFilter,
    required this.onExport,
  });

  @override
  State<ReportExportDialog> createState() => _ReportExportDialogState();
}

class _ReportExportDialogState extends State<ReportExportDialog> {
  String _selectedFormat = 'CSV';
  bool _isExporting = false;
  String? _downloadUrl;
  String? _errorMessage;

  final List<Map<String, dynamic>> _formats = [
    {
      'key': 'CSV',
      'label': 'Comma Separated Values (.csv)',
      'icon': Icons.table_chart_outlined,
      'desc': 'Optimized for Excel, Google Sheets, and raw data ingestion',
    },
    {
      'key': 'PDF',
      'label': 'Portable Document Format (.pdf)',
      'icon': Icons.picture_as_pdf_outlined,
      'desc': 'Formal executive layout with branding and compliance summary',
    },
    {
      'key': 'XLSX',
      'label': 'Microsoft Excel Workbook (.xlsx)',
      'icon': Icons.grid_on_outlined,
      'desc': 'Multi-sheet workbook with formulas and styled pivot tables',
    },
  ];

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
      _errorMessage = null;
      _downloadUrl = null;
    });

    try {
      final url = await widget.onExport(
        widget.reportType,
        widget.activeFilter,
        _selectedFormat,
      );
      if (mounted) {
        setState(() {
          _isExporting = false;
          _downloadUrl = url;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _errorMessage = e.toString();
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
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
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
                    child: const Icon(Icons.file_download_outlined, color: AppColors.primaryLight, size: 22),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Export ${widget.reportTitle}', style: AppTypography.heading3),
                        Text(
                          'Filter: ${widget.activeFilter.datePreset.label}${widget.activeFilter.department != null ? " • ${widget.activeFilter.department}" : ""}',
                          style: AppTypography.captionOf(context),
                        ),
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

              if (_downloadUrl != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.successBgDark : AppColors.successBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          Text('Report Generated Successfully!', style: AppTypography.bodyBold.copyWith(color: AppColors.success)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'File ready: $_downloadUrl',
                        style: AppTypography.captionOf(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),
              ],

              // Format Selectors
              Text('Select Export Format', style: AppTypography.captionOf(context)),
              const SizedBox(height: 8),
              ..._formats.map((f) {
                final isSelected = _selectedFormat == f['key'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isSelected
                        ? AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 0.08)
                        : Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      side: BorderSide(
                        color: isSelected ? AppColors.primaryLight : AppColors.border(context),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        f['icon'] as IconData,
                        color: isSelected ? AppColors.primaryLight : AppColors.textSecondary(context),
                      ),
                      title: Text(f['label'] as String, style: AppTypography.bodyBold),
                      subtitle: Text(f['desc'] as String, style: AppTypography.captionOf(context)),
                      trailing: Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? AppColors.primaryLight : AppColors.textSecondary(context),
                        size: 20,
                      ),
                      onTap: () => setState(() => _selectedFormat = f['key'] as String),
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppDimensions.space16),

              // Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  HrButton(
                    label: _downloadUrl != null ? 'Close' : 'Cancel',
                    variant: HrButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  if (_downloadUrl == null)
                    HrButton(
                      label: 'Generate & Download',
                      variant: HrButtonVariant.primary,
                      icon: Icons.download,
                      isLoading: _isExporting,
                      onPressed: _handleExport,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
