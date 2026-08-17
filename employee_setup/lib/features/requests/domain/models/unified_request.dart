import '../../../core/widgets/status_badge.dart';
import '../../advances/domain/models/advance_request.dart';
import '../../permissions/domain/models/permission_request.dart';
import '../../vacations/domain/models/vacation_request.dart';

enum RequestCategory {
  advance,
  permission,
  vacation,
}

class UnifiedRequestItem {
  final String id;
  final RequestCategory category;
  final String title;
  final String subtitle;
  final DateTime date;
  final BadgeStatus badgeStatus;
  final String statusLabel;
  final Object originalItem;

  const UnifiedRequestItem({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.badgeStatus,
    required this.statusLabel,
    required this.originalItem,
  });

  factory UnifiedRequestItem.fromAdvance(AdvanceRequest advance, [bool isArabic = true]) {
    BadgeStatus badge;
    String label;
    switch (advance.status) {
      case AdvanceStatus.pending:
        badge = BadgeStatus.pending;
        label = isArabic ? 'قيد المراجعة' : 'Pending';
        break;
      case AdvanceStatus.approved:
        badge = BadgeStatus.approved;
        label = isArabic ? 'تمت الموافقة' : 'Approved';
        break;
      case AdvanceStatus.paid:
        badge = BadgeStatus.paid;
        label = isArabic ? 'تم الصرف' : 'Paid';
        break;
      case AdvanceStatus.rejected:
        badge = BadgeStatus.rejected;
        label = isArabic ? 'مرفوض' : 'Rejected';
        break;
      case AdvanceStatus.reportRequired:
        badge = BadgeStatus.pending;
        label = isArabic ? 'مطلوب تقرير' : 'Report Required';
        break;
      case AdvanceStatus.reportSubmitted:
        badge = BadgeStatus.completed;
        label = isArabic ? 'تم التقرير' : 'Report Submitted';
        break;
    }

    return UnifiedRequestItem(
      id: advance.id,
      category: RequestCategory.advance,
      title: isArabic ? 'طلب سُلفة مالية (${advance.amount.toInt()} ج.م)' : 'Advance Request (${advance.amount.toInt()} EGP)',
      subtitle: advance.reason,
      date: advance.createdAt,
      badgeStatus: badge,
      statusLabel: label,
      originalItem: advance,
    );
  }

  factory UnifiedRequestItem.fromPermission(PermissionRequest perm, [bool isArabic = true]) {
    BadgeStatus badge;
    String label;
    switch (perm.status) {
      case PermissionStatus.pending:
        badge = BadgeStatus.pending;
        label = isArabic ? 'قيد المراجعة' : 'Pending';
        break;
      case PermissionStatus.approved:
        badge = BadgeStatus.approved;
        label = isArabic ? 'تمت الموافقة' : 'Approved';
        break;
      case PermissionStatus.rejected:
        badge = BadgeStatus.rejected;
        label = isArabic ? 'مرفوض' : 'Rejected';
        break;
      case PermissionStatus.cancelled:
        badge = BadgeStatus.cancelled;
        label = isArabic ? 'ملغي' : 'Cancelled';
        break;
    }

    String typeLabel;
    switch (perm.type) {
      case PermissionType.morningDelay:
        typeLabel = isArabic ? 'إذن تأخير صباحي' : 'Morning Delay';
        break;
      case PermissionType.earlyLeave:
        typeLabel = isArabic ? 'إذن انصراف مبكر' : 'Early Leave';
        break;
      case PermissionType.fullDayAbsence:
        typeLabel = isArabic ? 'إذن غياب يوم' : 'Full Day Absence';
        break;
      case PermissionType.halfDay:
        typeLabel = isArabic ? 'إذن نصف يوم' : 'Half Day';
        break;
    }

    return UnifiedRequestItem(
      id: perm.id,
      category: RequestCategory.permission,
      title: typeLabel,
      subtitle: '${perm.durationOrTime} - ${perm.reason}',
      date: perm.createdAt,
      badgeStatus: badge,
      statusLabel: label,
      originalItem: perm,
    );
  }

  factory UnifiedRequestItem.fromVacation(VacationRequest vac, [bool isArabic = true]) {
    BadgeStatus badge;
    String label;
    switch (vac.status) {
      case VacationStatus.pending:
        badge = BadgeStatus.pending;
        label = isArabic ? 'قيد المراجعة' : 'Pending';
        break;
      case VacationStatus.approved:
        badge = BadgeStatus.approved;
        label = isArabic ? 'تمت الموافقة' : 'Approved';
        break;
      case VacationStatus.rejected:
        badge = BadgeStatus.rejected;
        label = isArabic ? 'مرفوض' : 'Rejected';
        break;
      case VacationStatus.cancelled:
        badge = BadgeStatus.cancelled;
        label = isArabic ? 'ملغي' : 'Cancelled';
        break;
    }

    String typeLabel;
    switch (vac.type) {
      case VacationType.annual:
        typeLabel = isArabic ? 'إجازة سنوية (${vac.daysCount} أيام)' : 'Annual Vacation (${vac.daysCount} days)';
        break;
      case VacationType.sick:
        typeLabel = isArabic ? 'إجازة مرضية (${vac.daysCount} أيام)' : 'Sick Leave (${vac.daysCount} days)';
        break;
      case VacationType.casual:
        typeLabel = isArabic ? 'إجازة عارضة (${vac.daysCount} يوم)' : 'Casual Leave (${vac.daysCount} day)';
        break;
      case VacationType.unpaid:
        typeLabel = isArabic ? 'إجازة بدون راتب' : 'Unpaid Leave';
        break;
    }

    return UnifiedRequestItem(
      id: vac.id,
      category: RequestCategory.vacation,
      title: typeLabel,
      subtitle: vac.reason,
      date: vac.createdAt,
      badgeStatus: badge,
      statusLabel: label,
      originalItem: vac,
    );
  }
}
