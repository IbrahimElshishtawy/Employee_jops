import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../data/repositories/handover_repository.dart';
import '../../domain/models/handover_model.dart';

final handoverRepositoryProvider = Provider<HandoverRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return HandoverRepository(client);
});

final handoverListProvider =
    FutureProvider.autoDispose<List<HandoverReport>>((ref) async {
  final repo = ref.watch(handoverRepositoryProvider);
  return repo.getHandovers();
});

class HandoverListScreen extends ConsumerWidget {
  const HandoverListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final isRtl = context.isRtl;
    final handoversAsync = ref.watch(handoverListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'تسليم واستلام الورديات' : 'Shift Handover'),
      ),
      body: handoversAsync.when(
        data: (handovers) {
          if (handovers.isEmpty) {
            return Center(
              child: Text(isRtl ? 'لا توجد محاضر تسليم مسجلة' : 'No handover reports'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(handoverListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: handovers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final report = handovers[index];
                return Card(
                  elevation: 0,
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              report.shiftName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('HH:mm - yyyy/MM/dd').format(report.handoverTime),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${isRtl ? "المُسَلِّم:" : "Outgoing:"} ${report.outgoingEmployeeName}',
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                        Text(
                          '${isRtl ? "المُسْتَلِم:" : "Incoming:"} ${report.incomingEmployeeName}',
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                        if (report.notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            report.notes,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                        if (report.pendingItems.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          Text(
                            isRtl ? 'المهام المعلقة للوردية التالية:' : 'Pending items for next shift:',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          for (final item in report.pendingItems)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, size: 16, color: Colors.orange),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(item.description, style: const TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        if (!report.isAcknowledged) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check, size: 16),
                              label: Text(isRtl ? 'إقرار باستلام الوردية' : 'Acknowledge Handover'),
                              onPressed: () async {
                                final success = await ref
                                    .read(handoverRepositoryProvider)
                                    .acknowledgeHandover(report.id);
                                if (success) {
                                  ref.invalidate(handoverListProvider);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
