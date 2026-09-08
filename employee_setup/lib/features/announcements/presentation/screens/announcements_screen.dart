import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../data/repositories/announcements_repository.dart';
import '../../domain/models/announcement_model.dart';

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AnnouncementsRepository(client);
});

final announcementsListProvider =
    FutureProvider.autoDispose<List<AnnouncementModel>>((ref) async {
  final repo = ref.watch(announcementsRepositoryProvider);
  return repo.getAnnouncements();
});

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final isRtl = context.isRtl;
    final announcementsAsync = ref.watch(announcementsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'التعميمات والإعلانات الإدارية' : 'HR Announcements'),
      ),
      body: announcementsAsync.when(
        data: (announcements) {
          if (announcements.isEmpty) {
            return Center(
              child: Text(isRtl ? 'لا توجد تعميمات جديدة' : 'No announcements'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(announcementsListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: announcements.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final ann = announcements[index];
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ann.category,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('yyyy-MM-dd').format(ann.publishedAt),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          ann.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ann.content,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                        if (ann.requiresAcknowledgment && !ann.isAcknowledged) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.check_circle_outline, size: 16),
                              label: Text(isRtl ? 'إقرار بالقراءة والفهم' : 'Acknowledge'),
                              onPressed: () async {
                                final success = await ref
                                    .read(announcementsRepositoryProvider)
                                    .acknowledgeAnnouncement(ann.id);
                                if (success) {
                                  ref.invalidate(announcementsListProvider);
                                }
                              },
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
