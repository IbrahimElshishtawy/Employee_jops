import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/request_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/vacation_request.dart';

class VacationsListScreen extends ConsumerWidget {
  const VacationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(vacationsListProvider);

    return Scaffold(
      appBar: AppHeader(
        title: context.tr('vacations.title'),
        subtitle: 'Ø§Ù„Ø¥Ø¬Ø§Ø²Ø§Øª Ø§Ù„Ø³Ù†ÙˆÙŠØ©ØŒ Ø§Ù„Ù…Ø±Ø¶ÙŠØ©ØŒ ÙˆØ§Ù„Ø¹Ø§Ø±Ø¶Ø©',
      ),
      body: listAsync.when(
        data: (vacations) {
          if (vacations.isEmpty) {
            return EmptyState(
              title: 'Ù„Ø§ ØªÙˆØ¬Ø¯ Ø·Ù„Ø¨Ø§Øª Ø¥Ø¬Ø§Ø²Ø© Ø³Ø§Ø¨Ù‚Ø©',
              subtitle: 'ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ù„ØªØ®Ø·ÙŠØ· Ù„Ø¥Ø¬Ø§Ø²ØªÙƒ Ø§Ù„Ù‚Ø§Ø¯Ù…Ø© ÙˆØªÙ‚Ø¯ÙŠÙ… Ø·Ù„Ø¨ Ø¬Ø¯ÙŠØ¯',
              actionLabel: context.tr('vacations.new'),
              onAction: () => context.push('/requests/vacations/new'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(vacationsListProvider),
            child: ListView.separated(
              padding: AppDimensions.pagePadding,
              itemCount: vacations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final vac = vacations[index];
                BadgeStatus badge;
                String label;

                switch (vac.status) {
                  case VacationStatus.pending:
                    badge = BadgeStatus.pending;
                    label = 'Ù‚ÙŠØ¯ Ø§Ù„Ù…Ø±Ø§Ø¬Ø¹Ø©';
                    break;
                  case VacationStatus.approved:
                    badge = BadgeStatus.approved;
                    label = 'ØªÙ…Øª Ø§Ù„Ù…ÙˆØ§ÙÙ‚Ø©';
                    break;
                  case VacationStatus.rejected:
                    badge = BadgeStatus.rejected;
                    label = 'Ù…Ø±ÙÙˆØ¶';
                    break;
                  case VacationStatus.cancelled:
                    badge = BadgeStatus.cancelled;
                    label = 'Ù…Ù„ØºÙŠ';
                    break;
                }

                String typeName;
                switch (vac.type) {
                  case VacationType.annual:
                    typeName = 'Ø¥Ø¬Ø§Ø²Ø© Ø³Ù†ÙˆÙŠØ© (${vac.daysCount} Ø£ÙŠØ§Ù…)';
                    break;
                  case VacationType.sick:
                    typeName = 'Ø¥Ø¬Ø§Ø²Ø© Ù…Ø±Ø¶ÙŠØ© (${vac.daysCount} Ø£ÙŠØ§Ù…)';
                    break;
                  case VacationType.casual:
                    typeName = 'Ø¥Ø¬Ø§Ø²Ø© Ø¹Ø§Ø±Ø¶Ø© (${vac.daysCount} ÙŠÙˆÙ…)';
                    break;
                  case VacationType.unpaid:
                    typeName = 'Ø¥Ø¬Ø§Ø²Ø© Ø¨Ø¯ÙˆÙ† Ø±Ø§ØªØ¨';
                    break;
                }

                return RequestCard(
                  title: typeName,
                  subtitle: '${vac.fromDate.toFormattedShortDate()} Ø¥Ù„Ù‰ ${vac.toDate.toFormattedShortDate()} â€¢ ${vac.reason}',
                  date: vac.createdAt,
                  badgeStatus: badge,
                  statusLabel: label,
                  icon: Icons.beach_access_outlined,
                  onTap: () => context.push('/requests/vacations/${vac.id}'),
                );
              },
            ),
          );
        },
        loading: () => const LoadingState(message: 'Ø¬Ø§Ø±ÙŠ ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø¥Ø¬Ø§Ø²Ø§Øª...'),
        error: (err, _) => Center(child: Text('Ø®Ø·Ø£: $err')),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AppButton.primary(
            label: context.tr('vacations.new'),
            icon: Icons.add_rounded,
            onPressed: () => context.push('/requests/vacations/new'),
          ),
        ),
      ),
    );
  }
}
