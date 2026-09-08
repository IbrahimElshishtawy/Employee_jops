import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../data/repositories/incidents_repository.dart';
import '../../domain/models/incident_model.dart';

final incidentsRepositoryProvider = Provider<IncidentsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return IncidentsRepository(client);
});

final incidentsListProvider =
    FutureProvider.autoDispose<List<IncidentReport>>((ref) async {
  final repo = ref.watch(incidentsRepositoryProvider);
  return repo.getIncidents();
});

class IncidentsScreen extends ConsumerWidget {
  const IncidentsScreen({super.key});

  void _showNewIncidentDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locController = TextEditingController();
    String severity = 'MEDIUM';
    final isRtl = context.isRtl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isRtl ? 'الإبلاغ عن حادث أو خطر سلامة' : 'Report Hazard / Incident',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: isRtl ? 'عنوان البلاغ' : 'Incident Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locController,
                decoration: InputDecoration(
                  labelText: isRtl ? 'مكان الحادث / الموقع' : 'Location',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: isRtl ? 'تفاصيل البلاغ والملاحظات' : 'Details',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  await ref.read(incidentsRepositoryProvider).createIncident(
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        severity: severity,
                        location: locController.text.trim().isNotEmpty
                            ? locController.text.trim()
                            : 'Hotel Facility',
                      );
                  ref.invalidate(incidentsListProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isRtl ? 'إرسال البلاغ فوراً' : 'Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final isRtl = context.isRtl;
    final incidentsAsync = ref.watch(incidentsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'بلاغات السلامة والحوادث' : 'Safety & Incidents'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert_rounded),
        label: Text(isRtl ? 'بلاغ جديد' : 'Report Hazard'),
        onPressed: () => _showNewIncidentDialog(context, ref),
      ),
      body: incidentsAsync.when(
        data: (incidents) {
          if (incidents.isEmpty) {
            return Center(
              child: Text(isRtl ? 'لا توجد بلاغات مسجلة' : 'No safety incidents reported'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(incidentsListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: incidents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final inc = incidents[index];
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                inc.severity,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('yyyy-MM-dd HH:mm').format(inc.reportedAt),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          inc.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(inc.location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          inc.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
                          ),
                        ),
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
