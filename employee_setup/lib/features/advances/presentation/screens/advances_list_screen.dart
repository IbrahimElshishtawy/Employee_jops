import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/request_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/advance_request.dart';

class AdvancesListScreen extends ConsumerWidget {
  const AdvancesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(advancesListProvider);

    return Scaffold(
      appBar: AppHeader(
        title: context.tr('advances.title'),
        subtitle: 'Ù‚Ø§Ø¦Ù…Ø© Ø§Ù„Ø³ÙÙ„Ù ÙˆØ§Ù„Ø¹Ù‡Ø¯ Ø§Ù„Ù…Ø§Ù„ÙŠØ© ÙˆØªÙ‚Ø§Ø±ÙŠØ± Ø§Ù„Ù…ØµØ±ÙˆÙØ§Øª',
      ),
      body: listAsync.when(
        data: (advances) {
          if (advances.isEmpty) {
            return EmptyState(
              title: 'Ù„Ø§ ØªÙˆØ¬Ø¯ Ø³ÙÙ„Ù Ù…Ø§Ù„ÙŠØ© Ø­Ø§Ù„ÙŠØ©',
              subtitle: 'ÙŠÙ…ÙƒÙ†Ùƒ Ø¥Ù†Ø´Ø§Ø¡ Ø·Ù„Ø¨ Ø³ÙÙ„ÙØ© Ø£Ùˆ Ø¹Ù‡Ø¯Ø© Ø¬Ø¯ÙŠØ¯Ø© Ø¨ÙƒÙ„ Ø¨Ø³Ø§Ø·Ø©',
              actionLabel: context.tr('advances.new'),
              onAction: () => context.push('/requests/advances/new'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(advancesListProvider),
            child: ListView.separated(
              padding: AppDimensions.pagePadding,
              itemCount: advances.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final adv = advances[index];
                BadgeStatus statusBadge;
                String statusLabel;

                switch (adv.status) {
                  case AdvanceStatus.pending:
                    statusBadge = BadgeStatus.pending;
                    statusLabel = 'Ù‚ÙŠØ¯ Ø§Ù„Ù…Ø±Ø§Ø¬Ø¹Ø©';
                    break;
                  case AdvanceStatus.approved:
                    statusBadge = BadgeStatus.approved;
                    statusLabel = 'ØªÙ…Øª Ø§Ù„Ù…ÙˆØ§ÙÙ‚Ø©';
                    break;
                  case AdvanceStatus.paid:
                    statusBadge = BadgeStatus.paid;
                    statusLabel = 'ØªÙ… Ø§Ù„ØµØ±Ù';
                    break;
                  case AdvanceStatus.rejected:
                    statusBadge = BadgeStatus.rejected;
                    statusLabel = 'Ù…Ø±ÙÙˆØ¶';
                    break;
                  case AdvanceStatus.reportRequired:
                    statusBadge = BadgeStatus.pending;
                    statusLabel = 'Ù…Ø·Ù„ÙˆØ¨ ØªÙ‚Ø±ÙŠØ± Ù…ØµØ±ÙˆÙØ§Øª';
                    break;
                  case AdvanceStatus.reportSubmitted:
                    statusBadge = BadgeStatus.completed;
                    statusLabel = 'ØªÙ… ØªÙ‚Ø¯ÙŠÙ… Ø§Ù„ØªÙ‚Ø±ÙŠØ±';
                    break;
                }

                return RequestCard(
                  title: 'Ø³ÙÙ„ÙØ© Ù…Ø§Ù„ÙŠØ©: ${adv.amount.toInt()} Ø¬Ù†ÙŠÙ‡',
                  subtitle: adv.reason,
                  date: adv.createdAt,
                  badgeStatus: statusBadge,
                  statusLabel: statusLabel,
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: () => context.push('/requests/advances/${adv.id}'),
                );
              },
            ),
          );
        },
        loading: () => const LoadingState(message: 'Ø¬Ø§Ø±ÙŠ ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø³ÙÙ„Ù...'),
        error: (err, _) => Center(child: Text('Ø®Ø·Ø£: $err')),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AppButton.primary(
            label: context.tr('advances.new'),
            icon: Icons.add_rounded,
            onPressed: () => context.push('/requests/advances/new'),
          ),
        ),
      ),
    );
  }
}
